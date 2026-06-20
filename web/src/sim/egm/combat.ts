/* EGM-model ability layer.
   Phase 2: rotation + damage/heal/applyStatus + DoT/HoT.
   Phase 3: effective stats (buffs/debuffs/Chill/Mark applied), shields, cleanse, and a special-mechanic
   registry (first handler: detonate-burn). CC *enforcement* lives in the engine loop (it gates actions).
   Still deferred (no-op): taunt threat (Phase 4), interrupt (enemies don't cast), and the ~44 other
   `special` mechanics. Only party members cast abilities; enemies auto-attack (engine). */
import { content } from "@/content"
import type { PlayerAbility } from "@/content"
import { Rng } from "../rng"
import type { LogKind, LogMeta } from "../types"
import { resolveHit, type Defender, type DamageType, type Hit } from "./pipeline"
import { eff, dealDamage, passiveSpecial, type Combatant, type ActiveStatus } from "./stats"
import { applyStatus, applyInline, cleanseStatuses, stacksOf, hasStatus, hotStacks, hotAmplifyFactor, type StatusTick } from "./status"

export interface CombatCtx {
  rng: Rng
  t: number
  secondsPerTurn: number
  party: Combatant[]
  mobs: Combatant[]
  emit: (kind: LogKind, text: string, meta?: LogMeta) => void
  resolveCombatant: (id: string) => Combatant | undefined
  splashPrimary?: Combatant   // the enemy struck by the current cast's direct damage (so splash/spread anchor correctly post-kill)
  outgoingMult?: number       // party→enemy damage multiplier from tactics (Kill Order on trash / Cooldowns on boss); set per stage
  partyInDanger?: boolean      // Phase F: any ally <dangerHpPct or a recent death → Composure clutch is active (set per step)
  tactics?: Record<string, number>   // K.4: the 4 dials (interrupts/positioning/cooldowns/killorder, 0..3) — drive the party AI brain
}

/* eslint-disable @typescript-eslint/no-explicit-any */
type Effect = any
type Cond = any

const livingMobs = (ctx: CombatCtx) => ctx.mobs.filter((m) => m.hp > 0)
const aliveAllies = (ctx: CombatCtx) => ctx.party.filter((p) => p.downedUntil < 0)
const injuredAllies = (ctx: CombatCtx) =>
  aliveAllies(ctx).filter((p) => p.hp < p.maxHp).sort((a, b) => a.hp / a.maxHp - b.hp / b.maxHp)

const defenderOf = (c: Combatant): Defender => {
  const e = eff(c)
  return { armour: e.armour, resist: e.resist, dodgeChance: e.dodgeChance, damageTakenPct: e.damageTakenPct }
}
const isHot = (statusId: string) => content.statuses.get(statusId)?.kind === "hot"
const isLiveStatus = (statusId: string) => {
  const def = content.statuses.get(statusId)
  return !!def && (def.kind === "dot" || def.kind === "hot" || def.kind === "cc" || (!!def.statMods && def.statMods.length > 0))
}

function condHolds(cond: Cond, caster: Combatant, target: Combatant | undefined, _ctx: CombatCtx): boolean {
  switch (cond?.type) {
    case "targetHpBelowPct": return !!target && target.hp / target.maxHp < (cond.value ?? 0) / 100
    case "selfHitSinceLastAction": return caster.hitSinceAction
    case "targetHasStatus": return !!target && (hasStatus(target, cond.status, cond.minStacks ?? 1) || target.statuses.some((s) => s.kind === cond.status))
    case "selfHasStatus": return hasStatus(caster, cond.status, cond.minStacks ?? 1)
    case "targetBand": return !!target && (cond.band === "back" ? target.position === "Back" : target.position === "Front")
    case "targetHotStacksAtLeast": return !!target && hotStacks(target) >= (cond.value ?? 1)
    case "selfWasCleansed": return false // cleanse-of-self not tracked in Phase 3
    default: return false
  }
}

function amountOf(caster: Combatant, effect: Effect, target: Combatant | undefined, ctx: CombatCtx): number {
  const e = eff(caster)
  const scaleVal = effect.scaleStat === "maxHp" ? e.maxHp : e.power
  let amt = (effect.base ?? 0) + (effect.scale ?? 0) * scaleVal
  for (const m of (effect.modifiers ?? []) as any[]) {
    if (m.perStackOf) {
      const stacks = m.onSelf ? stacksOf(caster, m.perStackOf) : target ? stacksOf(target, m.perStackOf) : 0
      amt *= 1 + (m.multiplyDamage ?? 0) * stacks
    } else if (m.when && condHolds(m.when, caster, target, ctx)) {
      amt *= m.multiplyDamage ?? 1
    }
  }
  return amt
}

function targetsFor(side: string, pattern: string, count: number | undefined, caster: Combatant, ctx: CombatCtx, band?: string): Combatant[] {
  if (side === "self") return [caster]
  if (side === "enemy") {
    let living = livingMobs(ctx)
    if (band === "front" || band === "back") {
      const pos = band === "back" ? "Back" : "Front"
      const inBand = living.filter((m) => m.position === pos)
      if (inBand.length) living = inBand   // only narrow when the band has targets, else fall back to any (ability still fires)
    }
    if (!living.length) return []
    if (pattern === "all") return living
    if (pattern === "lowest-hp") return [living.slice().sort((a, b) => a.hp - b.hp)[0]]
    if (pattern === "adjacent") return living.slice(0, 1 + (count ?? 1))
    return [decidePartyFocus(caster, living, ctx) ?? living[0]]   // K.3: single-target hits the brain's chosen focus (kill order / execute)
  }
  // ally
  if (pattern === "all" || pattern === "aura") return aliveAllies(ctx)
  return [injuredAllies(ctx)[0] ?? caster]
}

// ---- Phase 3.5: passive modifiers, on-event hooks, and special handlers ----

/** Heal `target` capped at maxHp, crediting the healer; returns the amount actually healed. */
function healInto(healer: Combatant, target: Combatant, amount: number): number {
  const h = Math.min(amount, target.maxHp - target.hp)
  if (h > 0) { target.hp += h; healer.healDone += h }
  return h
}

/** The params block of an ability's `special` effect, or undefined. */
const findSpecial = (a: PlayerAbility, mechanic: string): any =>
  (a.effects as Effect[]).find((e) => e.type === "special" && e.mechanic === mechanic)?.params

const scaledBy = (c: Combatant, base: number, scale: number, stat?: string): number =>
  base + scale * (stat === "maxHp" ? eff(c).maxHp : eff(c).power)

/** A Lifebinder's Blossom HoT "blooms" for a per-stack burst heal when it expires or is triggered (Flourish). */
function bloomBlossom(host: Combatant, status: ActiveStatus, params: any, ctx: CombatCtx): number {
  if (!params || status.stacks <= 0) return 0
  const applier = ctx.resolveCombatant(status.applierId) ?? host
  const heal = scaledBy(applier, params.bloomHealBasePerStack ?? 0, params.bloomHealScalePerStack ?? 0, params.scaleStat) * status.stacks
  const healed = healInto(applier, host, heal)
  if (healed > 0)
    ctx.emit("heal", `${applier.name}'s Blossom blooms on ${host.name} for ${Math.round(healed).toLocaleString()}`,
      { sourceId: applier.id, sourceName: applier.name, sourceSpec: applier.specId, ability: "Blossom Ward", amount: Math.round(healed), target: host.name, result: "Heal" })
  return healed
}

/** Bloom params authored on the Blossom Ward that applied this status (looked up via its caster). */
function bloomParamsFor(status: ActiveStatus, ctx: CombatCtx): any {
  const applier = ctx.resolveCombatant(status.applierId)
  const a = applier?.abilities.find((ab) => (ab.effects as Effect[]).some((e) => e.type === "special" && e.mechanic === "blossom-bloom-on-trigger-or-expire"))
  return a ? findSpecial(a, "blossom-bloom-on-trigger-or-expire") : undefined
}

/** React to a combatant's DoT ticks / status expiries this step (atonement-on-dot, Blossom bloom-on-expire). */
export function onStatusEvents(host: Combatant, ev: StatusTick, ctx: CombatCtx): void {
  // atonement-on-dot (Holy Fire): the Burn's caster heals their lowest ally for a % of the DoT damage.
  for (const { status, amount } of ev.dots) {
    if (amount <= 0) continue
    const caster = ctx.resolveCombatant(status.applierId)
    if (!caster || caster.team !== "party") continue
    const a = caster.abilities.find((ab) => { const p = findSpecial(ab, "atonement-on-dot"); return p && p.status === status.id })
    if (!a) continue
    const p = findSpecial(a, "atonement-on-dot")
    const tgt = injuredAllies(ctx)[0] ?? caster
    healInto(caster, tgt, (amount * (p.healPctOfDotDamage ?? 0)) / 100)   // silent (per-tick): credited to healDone
  }
  // Blossom bloom-on-expire.
  if (host.team === "party")
    for (const s of ev.expired)
      if (s.id === "blossom") bloomBlossom(host, s, bloomParamsFor(s, ctx), ctx)
}

/** Nature's Grace: an ally who drops below the HP threshold while carrying a HoT gets one instant heal per combat. */
export function emergencyHeals(ctx: CombatCtx): void {
  const healer = aliveAllies(ctx).find((p) => passiveSpecial(p, "emergency-instant-heal"))
  if (!healer) return
  const p = passiveSpecial(healer, "emergency-instant-heal") as any
  const need = (p.requiresStatusAny ?? []) as string[]
  for (const ally of aliveAllies(ctx)) {
    if (ally.emergencyHealed) continue
    if (ally.hp / ally.maxHp >= (p.triggerHpBelowPct ?? 0) / 100) continue
    if (need.length && !ally.statuses.some((s) => need.includes(s.id))) continue
    ally.emergencyHealed = true
    const healed = healInto(healer, ally, scaledBy(healer, p.healBase ?? 0, p.healScale ?? 0, p.scaleStat))
    if (healed > 0)
      ctx.emit("heal", `${healer.name}'s Nature's Grace surges into ${ally.name} for ${Math.round(healed).toLocaleString()}`,
        { sourceId: healer.id, sourceName: healer.name, sourceSpec: healer.specId, ability: "Nature's Grace", amount: Math.round(healed), target: ally.name, result: "Heal" })
  }
}

// ---- Wave 3: enemy-attack interception, reactions, empower, and per-step guard upkeep ----

/** Camouflage: consume the caster's "empower next attack" charge (×damage + guaranteed crit). */
function takeEmpower(c: Combatant): { mult: number; crit: boolean } {
  const g = c.guards
  if (g.empowerMult == null) return { mult: 1, crit: false }
  const r = { mult: g.empowerMult, crit: !!g.empowerCrit }
  g.empowerMult = undefined; g.empowerCrit = undefined
  return r
}

/** A party member deals reactive damage to an attacking enemy (Shield Wall reflect, Thorns, Earthen Stance counter). */
function reactDamage(source: Combatant, enemy: Combatant, amount: number, label: string, ctx: CombatCtx): void {
  if (amount <= 0 || enemy.hp <= 0) return
  const res = resolveHit({ amount, damageType: "Physical", critChance: 0, critMult: 1, critable: false }, defenderOf(enemy), ctx.rng)
  dealDamage(enemy, res.dealt); source.dmgDone += res.dealt
  ctx.emit("normal", `${source.name}'s ${label} hits ${enemy.name} for ${Math.round(res.dealt).toLocaleString()}`,
    { sourceId: source.id, sourceName: source.name, sourceSpec: source.specId, ability: label, amount: Math.round(res.dealt), target: enemy.name, result: "Hit" })
}

/**
 * Resolve one enemy attack against a party victim through the Wave 3 defensive pipeline:
 * immunity → parry(+counter,+heal) → dodge/crit/mitigation → block(+reflect) → redirect → damage → thorns.
 * Returns the outcome label for the (throttled) combat log.
 */
export function resolveEnemyAttack(attacker: Combatant, victim: Combatant, hit: Hit, ctx: CombatCtx): { dealt: number; outcome: string } {
  const g = victim.guards

  if ((g.immunityCharges ?? 0) > 0 && ctx.t < (g.immunityExpiresAt ?? Infinity)) { g.immunityCharges! -= 1; return { dealt: 0, outcome: "Immune" } }

  if (g.parry && ctx.t < g.parry.expiresAt && ctx.rng.chance(g.parry.chancePct / 100)) {
    reactDamage(victim, attacker, scaledBy(victim, g.parry.base, g.parry.scale, g.parry.scaleStat), "Counter", ctx)
    const ph = passiveSpecial(victim, "on-parry-heal") as any   // Inner Peace
    if (ph) healInto(victim, victim, scaledBy(victim, ph.base ?? 0, ph.scale ?? 0, ph.scaleStat))
    return { dealt: 0, outcome: "Parry" }
  }

  const res = resolveHit(hit, defenderOf(victim), ctx.rng)
  if (res.isDodge) return { dealt: 0, outcome: "Dodge" }
  const dealt = res.dealt

  if ((g.blockCharges ?? 0) > 0) {
    g.blockCharges! -= 1
    reactDamage(victim, attacker, hit.amount * ((g.blockReflectPct ?? 0) / 100), "Shield Wall", ctx)  // reflect % of the raw swing
    return { dealt: 0, outcome: "Blocked" }
  }

  if (g.redirect && ctx.t < g.redirect.expiresAt) {
    const prot = ctx.resolveCombatant(g.redirect.protectorId)
    if (prot && prot !== victim && prot.downedUntil < 0) {
      const moved = dealt * (g.redirect.redirectPct / 100) * (1 - g.redirect.reductionPct / 100)
      const stay = dealt * (1 - g.redirect.redirectPct / 100)
      if (moved > 0) dealDamage(prot, moved)
      if (stay > 0) dealDamage(victim, stay)
      thornsReflect(victim, attacker, ctx)
      return { dealt: stay, outcome: "Redirected" }   // log reflects what the victim actually took (protector's share is separate)
    }
  }

  dealDamage(victim, dealt)
  thornsReflect(victim, attacker, ctx)
  return { dealt, outcome: res.isCrit ? "Crit" : "Hit" }
}

/** Thorns Aura (guardian passive): a melee (front-band) attacker takes reflected damage when it hits the warded ally. */
function thornsReflect(victim: Combatant, attacker: Combatant, ctx: CombatCtx): void {
  const th = passiveSpecial(victim, "thorns-reflect") as any
  if (th && (th.trigger !== "melee-attacker" || attacker.position === "Front"))   // ranged (back-band) attackers don't proc Thorns
    reactDamage(victim, attacker, scaledBy(victim, th.base ?? 0, th.scale ?? 0, th.scaleStat), "Thorns", ctx)
}

/** Per-step upkeep for HP-gated passives and the Arcane Barrier shield-break detonation. */
export function tickGuards(dt: number, ctx: CombatCtx): void {
  for (const p of aliveAllies(ctx)) {
    // Inner Peace: regenerate while healthy
    const reg = passiveSpecial(p, "conditional-regen") as any
    if (reg) {
      const ratio = p.hp / p.maxHp, thr = (reg.onlyIf?.value ?? 0) / 100
      const ok = (reg.onlyIf?.type ?? "selfHpAbovePct") === "selfHpBelowPct" ? ratio < thr : ratio > thr   // honour the condition's direction
      if (ok) p.hp = Math.min(p.maxHp, p.hp + p.maxHp * ((reg.hpPctPerTurn ?? 0) / 100) * (dt / ctx.secondsPerTurn))
    }

    // Blessing of Protection: drop a timed-out immunity so the protected ally can act again
    if (p.guards.immunityExpiresAt != null && ctx.t >= p.guards.immunityExpiresAt) {
      p.guards.immunityCharges = undefined; p.guards.immuneNoAttack = undefined; p.guards.immunityExpiresAt = undefined
    }

    // Divine Insight: conditional +power aura on critically-wounded allies (maintained live)
    if (p.passive?.id === "divine-insight") {
      const buff = (p.passive.effects as Effect[]).find((e) => e.type === "buff" && e.onlyIf)
      if (buff) for (const ally of aliveAllies(ctx)) {
        const id = `${p.id}:divine-insight:${buff.stat}`
        const low = ally.hp / ally.maxHp < (buff.onlyIf.value ?? 30) / 100
        if (low) applyInline(ally, { id, kind: "buff", statMods: [{ stat: buff.stat, amountPct: buff.amountPct ?? 0 }], durationSec: 0, applierId: p.id, t: ctx.t })
        else ally.statuses = ally.statuses.filter((s) => s.id !== id)
      }
    }

    // Arcane Barrier: the first shielded ally whose shield breaks/expires detonates ONCE for the whole barrier
    const bb = p.guards.barrierBreak
    if (bb && (p.shield <= 0 || ctx.t >= p.shieldExpiresAt)) {
      const caster = ctx.resolveCombatant(bb.casterId) ?? p
      const amount = scaledBy(caster, bb.base, bb.scale, bb.scaleStat)
      const hadMobs = livingMobs(ctx).length > 0
      for (const m of livingMobs(ctx)) {
        const res = resolveHit({ amount, damageType: bb.damageType, critChance: eff(caster).crit, critMult: eff(caster).critMult, critable: true }, defenderOf(m), ctx.rng)
        dealDamage(m, res.dealt); caster.dmgDone += res.dealt
      }
      if (hadMobs)
        ctx.emit("good", `${caster.name}'s Arcane Barrier shatters, blasting the pack.`,
          { sourceId: caster.id, sourceName: caster.name, sourceSpec: caster.specId, ability: "Arcane Barrier", result: "Hit" })
      // disarm THIS caster's barrier on every ally so the party-wide shield detonates only once
      for (const a of ctx.party) if (a.guards.barrierBreak?.casterId === bb.casterId) { a.guards.barrierBreak = undefined; a.guards.ccImmuneWhileShielded = undefined }
    }
  }
}

/** Continuous outgoing-damage multiplier: attacker passive (Bloodlust) × tactic mult × B.7 talent mods. */
function passiveDamageMult(attacker: Combatant, ctx: CombatCtx): number {
  let mult = attacker.team === "party" ? (ctx.outgoingMult ?? 1) : 1   // tactics boost only party output
  if (attacker.team === "party") {   // Phase F: operator output (Execution + Awareness) + Composure clutch when in danger
    mult *= attacker.opOutputMult
    if (ctx.partyInDanger) mult *= attacker.opClutchOutMult
  }
  const ramp = passiveSpecial(attacker, "rampage-damage-bonus") as any
  if (ramp) mult *= 1 + ((ramp.perStackPct ?? 0) / 100) * stacksOf(attacker, ramp.resource ?? "rampage")
  if (passiveSpecial(attacker, "low-hp-bonus-scaling")) mult *= 1 + 0.25 * (1 - attacker.hp / Math.max(1, attacker.maxHp)) // placeholder curve — Phase 5 tuning
  // B.7 talents: flat / enemy-count / focus-HP-gated damage mods (focus target = the lead living enemy)
  if (attacker.talents.length) {
    const mobs = livingMobs(ctx)
    const focus = mobs[0]
    for (const t of attacker.talents) {
      const c = t.onlyIf
      if (c) {
        const pass =
          c.type === "targetHpBelowPct" ? (!!focus && focus.hp / focus.maxHp < c.value / 100) :
          c.type === "enemiesAtLeast"   ? mobs.length >= c.value :
          c.type === "enemiesAtMost"    ? mobs.length <= c.value :
          false   // unknown condition → fail closed (never apply an ungated bonus)
        if (!pass) continue
      }
      mult *= 1 + t.dmgPct / 100
    }
  }
  return mult
}

/** Runs after every party hit lands: lifesteal / atonement / on-crit passives / cooldown resets. */
function afterHit(attacker: Combatant, ability: PlayerAbility | null, defender: Combatant, res: { dealt: number; isCrit: boolean }, ctx: CombatCtx): void {
  if (res.dealt > 0) {
    if (ability) for (const e of ability.effects as any[]) {
      if (e.type !== "special") continue
      if (e.mechanic === "lifesteal") {
        healInto(attacker, attacker, (res.dealt * (e.params?.pct ?? 0)) / 100)
      } else if (e.mechanic === "atonement-heal") {
        const tgt = injuredAllies(ctx)[0] ?? attacker
        let pct = e.params?.healPctOfDamage ?? 0
        const amp = passiveSpecial(attacker, "atonement-amp") as any
        if (amp && tgt.hp / tgt.maxHp < (amp.onlyIf?.value ?? 30) / 100) pct *= 1 + (amp.amountPct ?? 0) / 100
        const healed = healInto(attacker, tgt, (res.dealt * pct) / 100)
        if (healed > 0) ctx.emit("heal", `${attacker.name}'s Atonement heals ${tgt.name} for ${Math.round(healed).toLocaleString()}`,
          { sourceId: attacker.id, sourceName: attacker.name, sourceSpec: attacker.specId, ability: "Atonement", amount: Math.round(healed), target: tgt.name, result: "Heal" })
      } else if (res.isCrit && e.mechanic === "reset-cooldown-on-crit" && e.params?.ability) {
        attacker.cooldowns[e.params.ability] = ctx.t
      }
    }
    if (res.isCrit) {
      const cl = passiveSpecial(attacker, "crit-lifesteal") as any
      if (cl) healInto(attacker, attacker, (attacker.maxHp * (cl.healHpPct ?? 0)) / 100)
      const cb = passiveSpecial(attacker, "on-crit-stacking-buff") as any
      if (cb?.appliesStatus) {
        const sd = content.statuses.get(cb.appliesStatus)
        applyStatus(attacker, cb.appliesStatus, { durationSec: (sd?.defaultDurationTurns ?? 2) * ctx.secondsPerTurn, stacks: 1, applierId: attacker.id, t: ctx.t })
      }
    }
  }
  if (defender.hp <= 0 && ability) for (const e of ability.effects as any[])
    if (e.type === "special" && e.mechanic === "reset-cooldown-on-kill" && e.params?.resetAbility) attacker.cooldowns[e.params.resetAbility] = ctx.t
}

function detonateBurn(caster: Combatant, ability: PlayerAbility, params: any, ctx: CombatCtx, targets: Combatant[]): void {
  const primary = targets[0]
  if (!primary) return
  const burn = primary.statuses.find((s) => s.id === (params.status ?? "burn"))
  const stacks = burn?.stacks ?? 0
  if (stacks <= 0) return
  const e = eff(caster)
  const ps = params.perStack ?? {}
  const per = (ps.base ?? 0) + (ps.scale ?? 0) * (ps.scaleStat === "maxHp" ? e.maxHp : e.power)
  const total = per * stacks * passiveDamageMult(caster, ctx)
  const dt: DamageType = params.damageType ?? "Magic"
  const res = resolveHit({ amount: total, damageType: dt, critChance: e.crit, critMult: e.critMult, critable: params.critable !== false }, defenderOf(primary), ctx.rng)
  dealDamage(primary, res.dealt); caster.dmgDone += res.dealt
  afterHit(caster, ability, primary, res, ctx)
  ctx.emit(res.isCrit ? "crit" : "normal",
    `${caster.name}'s ${ability.name} detonates ${stacks} Burn on ${primary.name} for ${Math.round(res.dealt).toLocaleString()} ${dt}.${res.isCrit ? "(Critical)" : ""}`,
    { sourceId: caster.id, sourceName: caster.name, sourceSpec: caster.specId, ability: ability.name, skillId: ability.id, amount: Math.round(res.dealt), target: primary.name, result: res.isCrit ? "Critical Strike" : "Hit" })
  if (params.consumesStacks !== false && burn) primary.statuses = primary.statuses.filter((s) => s !== burn)
  const odb = passiveSpecial(caster, "on-detonate-buff") as any   // Combustion
  if (odb && stacks >= (odb.minStacksDetonated ?? 4))
    applyInline(caster, { id: "combustion:detonate", kind: "buff", statMods: [{ stat: odb.buffStat ?? "power", amountPct: odb.buffAmountPct ?? 0 }], durationSec: (odb.buffDurationTurns ?? 2) * ctx.secondsPerTurn, applierId: caster.id, t: ctx.t })
  const splashPct = params.splashPct ?? 0
  if (splashPct > 0)
    for (const o of livingMobs(ctx).filter((m) => m !== primary).slice(0, params.splashCount ?? 1)) {
      const sres = resolveHit({ amount: (total * splashPct) / 100, damageType: dt, critChance: e.crit, critMult: e.critMult, critable: false }, defenderOf(o), ctx.rng)
      dealDamage(o, sres.dealt); caster.dmgDone += sres.dealt
    }
}

function applyOnMaxStacks(caster: Combatant, _ability: PlayerAbility, params: any, ctx: CombatCtx, targets: Combatant[]): void {
  if (stacksOf(caster, params.resource ?? "rampage") < (params.requiredStacks ?? 5)) return
  const durationSec = (params.durationTurns ?? 3) * ctx.secondsPerTurn
  for (const tg of targets) applyStatus(tg, params.applyStatus ?? "bleed", { durationSec, stacks: 1, applierId: caster.id, t: ctx.t })
}
function extendStatusDuration(_caster: Combatant, _ability: PlayerAbility, params: any, ctx: CombatCtx, targets: Combatant[]): void {
  const add = (params.extendTurns ?? 1) * ctx.secondsPerTurn
  for (const tg of targets) { const s = tg.statuses.find((x) => x.id === (params.status ?? "bleed")); if (s && s.expiresAt !== Infinity) s.expiresAt += add }
}
function buffNearestAlly(caster: Combatant, ability: PlayerAbility, params: any, ctx: CombatCtx, _targets: Combatant[]): void {
  const ally = aliveAllies(ctx).find((p) => p !== caster) ?? caster
  applyInline(ally, { id: `${ability.id}:${params.stat ?? "armour"}`, kind: "buff", statMods: [{ stat: params.stat ?? "armour", amountPct: params.amountPct ?? 0 }], durationSec: (params.durationTurns ?? 1) * ctx.secondsPerTurn, applierId: caster.id, t: ctx.t })
}
function cooldownReduction(caster: Combatant, _ability: PlayerAbility, params: any, ctx: CombatCtx, _targets: Combatant[]): void {
  const tgt = injuredAllies(ctx).find((p) => p !== caster) ?? aliveAllies(ctx).find((p) => p !== caster) ?? caster
  const red = (params.reduceTurns ?? 0) * ctx.secondsPerTurn
  for (const k of Object.keys(tgt.cooldowns)) tgt.cooldowns[k] = Math.max(ctx.t, tgt.cooldowns[k] - red)
}
function spreadBurn(_caster: Combatant, _ability: PlayerAbility, params: any, ctx: CombatCtx, targets: Combatant[]): void {
  const primary = ctx.splashPrimary ?? targets[0]; if (!primary) return   // anchor on the actual struck target (post-kill safe)
  const src = primary.statuses.find((s) => s.id === (params.status ?? "burn")); if (!src) return
  const rem = src.expiresAt - ctx.t
  if (rem <= 0) return   // source already expired this tick — don't spread (durationSec 0 would mean "permanent")
  for (const o of livingMobs(ctx).filter((m) => m !== primary).slice(0, params.count ?? 1))
    applyStatus(o, params.status ?? "burn", { perTick: src.perTick, durationSec: rem, stacks: src.stacks, applierId: src.applierId, t: ctx.t })
}

/** Splash: the primary takes the full damage effect; this hits the remaining struck targets at splashPct.
    (Paired with a single-target damage effect on the ability so the primary isn't double-counted.) */
function splashDamage(caster: Combatant, ability: PlayerAbility, params: any, ctx: CombatCtx, targets: Combatant[]): void {
  const primary = ctx.splashPrimary ?? livingMobs(ctx)[0]   // the actual direct-hit target (may already be dead)
  if (!primary) return
  const e = eff(caster)
  const amount = scaledBy(caster, params.base ?? 0, params.scale ?? 0, params.scaleStat) * ((params.splashPct ?? 0) / 100) * passiveDamageMult(caster, ctx)
  if (amount <= 0) return
  const dt: DamageType = params.damageType ?? "Magic"
  let pool = targets.filter((m) => m.hp > 0 && m !== primary)
  if (params.count != null) pool = pool.slice(0, params.count)
  for (const o of pool) {
    const res = resolveHit({ amount, damageType: dt, critChance: e.crit, critMult: e.critMult, critable: params.critable === true }, defenderOf(o), ctx.rng)
    dealDamage(o, res.dealt); caster.dmgDone += res.dealt
    afterHit(caster, ability, o, res, ctx)   // splash secondaries are silent (no per-target log line)
  }
}

/** Vital Surge: consume the target's HoTs, instantly healing their remaining value × burstMultiplier. */
function consumeHotsBurst(caster: Combatant, _ability: PlayerAbility, params: any, ctx: CombatCtx, _targets: Combatant[]): void {
  const consume = new Set<string>(params.consumeStatuses ?? [])
  const carries = (p: Combatant) => p.statuses.some((s) => s.kind === "hot" && consume.has(s.id))
  // prefer the most-injured ally who actually carries a consumable HoT (else the most injured)
  const tg = injuredAllies(ctx).find(carries) ?? injuredAllies(ctx)[0]
  if (!tg) return
  let total = 0
  for (const s of tg.statuses) {
    if (s.kind !== "hot" || !consume.has(s.id)) continue
    const remaining = s.expiresAt === Infinity ? 0 : Math.max(0, s.expiresAt - ctx.t)
    // remaining HoT value (incl. Nature's Grace amplification) folded into the burst; Blossom not separately bloomed
    total += s.perTick * s.stacks * remaining * hotAmplifyFactor(ctx.resolveCombatant(s.applierId), s.id, s.stacks)
  }
  tg.statuses = tg.statuses.filter((s) => !(s.kind === "hot" && consume.has(s.id)))
  const healed = healInto(caster, tg, total * (params.burstMultiplier ?? 1))
  if (healed > 0)
    ctx.emit("heal", `${caster.name} casts Vital Surge on ${tg.name} for ${Math.round(healed).toLocaleString()} Healing`,
      { sourceId: caster.id, sourceName: caster.name, sourceSpec: caster.specId, ability: "Vital Surge", amount: Math.round(healed), target: tg.name, result: "Heal" })
}

/** Flourish: detonate (bloom) the target's Blossom stacks now; if none, weave a Regrowth HoT instead. */
function triggerBlossom(caster: Combatant, _ability: PlayerAbility, params: any, ctx: CombatCtx, _targets: Combatant[]): void {
  const blossomId = params.appliesToStatus ?? "blossom"
  const carries = (p: Combatant) => p.statuses.some((s) => s.kind === "hot" && s.id === blossomId)
  // prefer the most-injured ally carrying Blossom (so we bloom it) else the most injured (Regrowth fallback)
  const tg = injuredAllies(ctx).find(carries) ?? injuredAllies(ctx)[0] ?? caster
  if (!tg) return
  const blossoms = tg.statuses.filter((s) => s.kind === "hot" && s.id === blossomId)
  if (blossoms.length) {
    for (const s of blossoms) bloomBlossom(tg, s, params, ctx)
    tg.statuses = tg.statuses.filter((s) => !blossoms.includes(s))
  } else if (params.fallbackIfNoBlossom) {
    const fb = params.fallbackIfNoBlossom
    const perTurn = scaledBy(caster, fb.magnitudeBase ?? 0, fb.magnitudeScale ?? 0, fb.magnitudeStat)
    applyStatus(tg, fb.applyStatus ?? "regrowth", { perTick: perTurn / ctx.secondsPerTurn, durationSec: (fb.durationTurns ?? 0) * ctx.secondsPerTurn, stacks: fb.stacks, applierId: caster.id, t: ctx.t })
    ctx.emit("flavor", `${caster.name} weaves ${content.statuses.get(fb.applyStatus ?? "regrowth")?.name ?? "Regrowth"} onto ${tg.name}.`,
      { sourceId: caster.id, sourceName: caster.name, sourceSpec: caster.specId, ability: "Flourish", target: tg.name, result: "Cast" })
  }
}

// ---- Wave 3 active-ability handlers (set up the transient guard states consumed by resolveEnemyAttack/tickGuards) ----

function shieldWallBlock(caster: Combatant, _ability: PlayerAbility, params: any, _ctx: CombatCtx, _targets: Combatant[]): void {
  caster.guards.blockCharges = params.blocks ?? 1
  caster.guards.blockReflectPct = params.reflectPct ?? 0
}
function attackImmunity(_caster: Combatant, _ability: PlayerAbility, params: any, ctx: CombatCtx, targets: Combatant[]): void {
  for (const tg of targets) {
    tg.guards.immunityCharges = params.blocks ?? 1
    tg.guards.immuneNoAttack = !!params.cannotAttackDuringImmunity
    tg.guards.immunityExpiresAt = ctx.t + (params.durationTurns ?? 3) * ctx.secondsPerTurn   // cap so an un-attacked ally isn't locked out all stage
  }
}
function redirectDamage(caster: Combatant, _ability: PlayerAbility, params: any, ctx: CombatCtx, targets: Combatant[]): void {
  // Guardian's Oath (toSelf, 100%) / Spirit Link (30%): the protected ally routes incoming damage to the caster.
  for (const tg of targets) {
    if (tg === caster) continue
    tg.guards.redirect = { protectorId: caster.id, redirectPct: params.redirectPct ?? 0, reductionPct: params.reductionPct ?? 0, expiresAt: ctx.t + (params.durationTurns ?? 0) * ctx.secondsPerTurn }
  }
}
function parryCounter(caster: Combatant, _ability: PlayerAbility, params: any, ctx: CombatCtx, _targets: Combatant[]): void {
  caster.guards.parry = { chancePct: params.parryChancePct ?? 0, base: params.counterBase ?? 0, scale: params.counterScale ?? 0, scaleStat: params.counterScaleStat, damageType: (params.counterDamageType ?? "Physical") as DamageType, expiresAt: ctx.t + (params.durationTurns ?? 0) * ctx.secondsPerTurn }
}
function empowerNextAttack(caster: Combatant, _ability: PlayerAbility, params: any, _ctx: CombatCtx, _targets: Combatant[]): void {
  caster.guards.empowerMult = params.multiplyDamage ?? 1
  caster.guards.empowerCrit = !!params.guaranteedCrit
}
function ccImmunityWhileShielded(_caster: Combatant, _ability: PlayerAbility, _params: any, _ctx: CombatCtx, targets: Combatant[]): void {
  for (const tg of targets) tg.guards.ccImmuneWhileShielded = true   // inert today (no enemy CC source); flag wired for Phase 5
}
function barrierBreakAoe(caster: Combatant, _ability: PlayerAbility, params: any, _ctx: CombatCtx, targets: Combatant[]): void {
  // Arcane Mastery (passive) empowers the break: add its bonus to the per-ally barrier-break payload.
  const mastery = passiveSpecial(caster, "barrier-break-damage") as any
  const base = (params.base ?? 0) + (mastery?.base ?? 0)
  const scale = (params.scale ?? 0) + (mastery?.scale ?? 0)
  for (const tg of targets) tg.guards.barrierBreak = { casterId: caster.id, base, scale, scaleStat: params.scaleStat, damageType: (params.damageType ?? "Magic") as DamageType }
}
function conditionalOnCleanse(caster: Combatant, _ability: PlayerAbility, params: any, ctx: CombatCtx, targets: Combatant[]): void {
  // Soothing Ballad: per ally, the preceding cleanse either removed a debuff (→ heal) or found none (→ armour buff).
  const heal = params.ifCleansed?.heal, buff = params.ifNoDebuff?.buff
  for (const tg of targets) {
    const dbi = tg.statuses.findIndex((s) => s.kind === "debuff" || s.kind === "dot" || s.kind === "cc")
    if (dbi >= 0) {
      tg.statuses.splice(dbi, 1)
      if (heal) healInto(caster, tg, scaledBy(caster, heal.base ?? 0, heal.scale ?? 0, heal.scaleStat))
    } else if (buff) {
      applyInline(tg, { id: `soothing-ballad:${buff.stat}`, kind: "buff", statMods: [{ stat: buff.stat, amountPct: buff.amountPct ?? 0 }], durationSec: (buff.durationTurns ?? 0) * ctx.secondsPerTurn, applierId: caster.id, t: ctx.t })
    }
  }
}

const SPECIALS: Record<string, (caster: Combatant, ability: PlayerAbility, params: any, ctx: CombatCtx, targets: Combatant[]) => void> = {
  "detonate-burn": detonateBurn,
  "apply-on-max-stacks": applyOnMaxStacks,
  "extend-status-duration": extendStatusDuration,
  "buff-nearest-ally": buffNearestAlly,
  "cooldown-reduction": cooldownReduction,
  "spread-burn": spreadBurn,
  "splash-damage": splashDamage,
  "consume-hots-burst-heal": consumeHotsBurst,
  "trigger-blossom-stacks": triggerBlossom,
  "shield-wall-block": shieldWallBlock,
  "attack-immunity": attackImmunity,
  "redirect-damage": redirectDamage,
  "damage-redirect": redirectDamage,
  "parry-counter": parryCounter,
  "empower-next-attack": empowerNextAttack,
  "cc-immunity-while-shielded": ccImmunityWhileShielded,
  "barrier-break-aoe": barrierBreakAoe,
  "conditional-on-cleanse": conditionalOnCleanse,
}
const DAMAGE_SPECIALS = new Set(["detonate-burn", "splash-damage"])
const HEAL_SPECIALS = new Set(["consume-hots-burst-heal", "trigger-blossom-stacks"])
// guard-setup specials produce no immediate log line — let the "uses X" cast flavor fire so the defensive cooldown is visible
const SETUP_SPECIALS = new Set(["shield-wall-block", "attack-immunity", "redirect-damage", "damage-redirect", "parry-counter", "empower-next-attack", "cc-immunity-while-shielded", "barrier-break-aoe"])

/** Apply a passive's static (unconditional) buff/aura effects as permanent statuses. Call at stage start. */
export function applyPassiveAuras(caster: Combatant, ctx: CombatCtx): void {
  const p = caster.passive
  if (!p) return
  for (const e of p.effects as any[]) {
    if (e.type !== "buff" || e.onlyIf) continue   // conditional auras (e.g. Divine Insight) deferred
    for (const tg of targetsFor(p.targeting.side, p.targeting.pattern, p.targeting.count, caster, ctx))
      applyInline(tg, { id: `${caster.id}:${p.id}:${e.stat}`, kind: "buff", statMods: [{ stat: e.stat, amountPct: e.amountPct ?? e.amount ?? 0 }], durationSec: 0, applierId: caster.id, t: ctx.t })
  }
}

/** Who a non-damaging cast (buff / shield / redirect / CC) lands on — for the "uses X on Y" log line. */
function castTargetDesc(ability: PlayerAbility, caster: Combatant, ctx: CombatCtx): { suffix: string; name?: string } {
  const t = ability.targeting
  const effs = ability.effects as Effect[]
  const partyWide = (t.side === "ally" && (t.pattern === "all" || t.pattern === "aura"))
    || effs.some((e) => (e.type === "buff" || e.type === "debuff" || e.type === "shield") && e.appliesTo === "all-allies")
  if (partyWide) return { suffix: " on the party" }
  const side = t.side === "self"
    ? (effs.some((e) => e.appliesTo === "ally" || e.appliesTo === "all-allies") ? "ally" : "self")
    : t.side
  if (side === "self") return { suffix: "" }
  const tg = targetsFor(side, t.pattern === "all" ? "all" : "single", t.count, caster, ctx, (t as { band?: string }).band)[0]
  if (tg && tg !== caster) return { suffix: ` on ${tg.name}`, name: tg.name }
  return { suffix: "" }
}

export function executeAbility(caster: Combatant, ability: PlayerAbility, ctx: CombatCtx): void {
  caster.cooldowns[ability.id] = ctx.t + ability.cooldownTurns * ctx.secondsPerTurn
  const a = ability as any
  const effects = ability.effects as Effect[]
  let logged = false
  ctx.splashPrimary = undefined   // captured below from the first damage effect, for splash/spread anchoring
  const emp = effects.some((e) => e.type === "damage") && livingMobs(ctx).length > 0 ? takeEmpower(caster) : { mult: 1, crit: false }   // Camouflage (only spend on a cast that can land)

  for (const effect of effects) {
    if (effect.type === "damage") {
      const e = eff(caster)
      const mult = passiveDamageMult(caster, ctx) * emp.mult
      // per-effect targeting override (splash abilities make the direct hit single; a splash special spreads the rest)
      const pat = effect.pattern ?? ability.targeting.pattern
      const cnt = effect.count ?? ability.targeting.count
      const dmgTargets = targetsFor(ability.targeting.side, pat, cnt, caster, ctx, effect.band ?? (ability.targeting as any).band)
      if (!ctx.splashPrimary) ctx.splashPrimary = dmgTargets[0]   // first damage effect's primary anchors later splash/spread
      for (const tg of dmgTargets) {
        const res = resolveHit(
          { amount: amountOf(caster, effect, tg, ctx) * mult, damageType: (effect.damageType ?? "Physical") as DamageType, critChance: emp.crit ? 1 : e.crit, critMult: e.critMult, critable: effect.critable !== false },
          defenderOf(tg), ctx.rng,
        )
        dealDamage(tg, res.dealt); caster.dmgDone += res.dealt
        const amt = Math.round(res.dealt)
        ctx.emit(res.isCrit ? "crit" : "normal",
          `${caster.name}'s ${ability.name} hits ${tg.name} for ${amt.toLocaleString()} ${res.damageType}.${res.isCrit ? "(Critical)" : ""}`,
          { sourceId: caster.id, sourceName: caster.name, sourceSpec: caster.specId, ability: ability.name, skillId: ability.id, amount: amt, target: tg.name, result: res.isCrit ? "Critical Strike" : "Hit" })
        afterHit(caster, ability, tg, res, ctx)
        logged = true
      }
    } else if (effect.type === "heal") {
      const targets = effect.target === "self" ? [caster]
        : effect.target === "lowest-hp-ally" || effect.target === "lowest-hp" ? [injuredAllies(ctx)[0] ?? caster]
        : targetsFor("ally", ability.targeting.pattern, ability.targeting.count, caster, ctx)
      const oth = findSpecial(ability, "overheal-to-shield")   // Flash Heal: route wasted healing into a shield
      for (const tg of targets) {
        const raw = amountOf(caster, effect, tg, ctx)
        const heal = Math.min(raw, tg.maxHp - tg.hp)
        if (heal > 0) {
          tg.hp += heal; caster.healDone += heal
          // WoW-style overhealing: a big heal landing on a near-full target shows the effective heal + the wasted surplus,
          // so e.g. Greater Heal reads "heals X for 68 (164 Overhealing)" instead of looking weaker than a Flash Heal.
          const over = Math.round(raw) - Math.round(heal)
          ctx.emit("heal", `${caster.name}'s ${ability.name} heals ${tg.name} for ${Math.round(heal).toLocaleString()}.${over >= 1 ? ` (${over.toLocaleString()} Overhealing)` : ""}`,
            { sourceId: caster.id, sourceName: caster.name, sourceSpec: caster.specId, ability: ability.name, skillId: ability.id, amount: Math.round(heal), target: tg.name, result: "Heal" })
          logged = true
        }
        if (oth) {
          const shield = (raw - heal) * ((oth.overhealPct ?? 0) / 100)
          if (shield > 0) {
            tg.shield = Math.max(tg.shield, shield)
            tg.shieldExpiresAt = ctx.t + (oth.durationTurns ?? 2) * ctx.secondsPerTurn
            logged = true
          }
        }
      }
    } else if (effect.type === "applyStatus") {
      const def = content.statuses.get(effect.status)
      const dotHot = def && (def.kind === "dot" || def.kind === "hot")
      const perTurn = (effect.magnitudeBase ?? 0) + (effect.magnitudeScale ?? 0) * (effect.magnitudeStat === "maxHp" ? eff(caster).maxHp : eff(caster).power)
      let perTick = dotHot ? perTurn / ctx.secondsPerTurn : 0
      if (perTick > 0 && def?.kind === "dot") {            // Combustion: amplify Burn DoTs this caster applies
        const amp = passiveSpecial(caster, "burn-amplify") as any
        if (amp && amp.status === effect.status) perTick *= 1 + (amp.amountPct ?? 0) / 100
      }
      let durationSec = (effect.durationTurns ?? def?.defaultDurationTurns ?? 0) * ctx.secondsPerTurn
      // Arcane Mastery: the arcanist's FIRST crowd-control application lasts +N turns (consumed only if it actually lands)
      let willExtendCc = false
      if (def?.kind === "cc") {
        const ext = passiveSpecial(caster, "first-cc-duration-extension") as any
        if (ext && !caster.guards.firstCcExtended) { durationSec += (ext.addTurns ?? 0) * ctx.secondsPerTurn; willExtendCc = true }
      }
      let applied = false
      for (const tg of targetsFor(ability.targeting.side, ability.targeting.pattern, ability.targeting.count, caster, ctx, (ability.targeting as any).band)) {
        if (effect.onlyIf && !condHolds(effect.onlyIf, caster, tg, ctx)) continue
        if (effect.chancePct != null && !ctx.rng.chance(effect.chancePct / 100)) continue
        applyStatus(tg, effect.status, { perTick, durationSec, stacks: effect.stacks, applierId: caster.id, t: ctx.t })
        applied = true
      }
      if (applied && willExtendCc) caster.guards.firstCcExtended = true   // only burn the bonus on a CC that landed
      // Inner Peace: applying a Stun heals the party (once per cast)
      if (applied && def?.control === "stun") {
        const sh = passiveSpecial(caster, "on-stun-heal-allies") as any
        if (sh) { const amt = scaledBy(caster, sh.base ?? 0, sh.scale ?? 0, sh.scaleStat); for (const al of aliveAllies(ctx)) healInto(caster, al, amt) }
      }
    } else if (effect.type === "buff" || effect.type === "debuff") {
      const side = effect.appliesTo === "self" ? "self" : effect.appliesTo === "all-allies" ? "ally" : ability.targeting.side
      const pattern = effect.appliesTo === "all-allies" ? "all" : ability.targeting.pattern
      const durationSec = (effect.durationTurns ?? 0) * ctx.secondsPerTurn
      const statMods = [{ stat: effect.stat, amountPct: effect.amountPct ?? effect.amount ?? 0 }]
      for (const tg of targetsFor(side, pattern, ability.targeting.count, caster, ctx)) {
        if (effect.onlyIf && !condHolds(effect.onlyIf, caster, tg, ctx)) continue   // honour conditional buffs/debuffs
        applyInline(tg, { id: `${ability.id}:${effect.stat}`, kind: effect.type, statMods, durationSec, applierId: caster.id, t: ctx.t })
      }
    } else if (effect.type === "shield") {
      const e = eff(caster)
      const base = (effect.base ?? 0) + (effect.scale ?? 0) * (effect.scaleStat === "maxHp" ? e.maxHp : e.power)
      const durationSec = (effect.durationTurns ?? 0) * ctx.secondsPerTurn
      const amp = passiveSpecial(caster, "shield-amp") as any   // Stalwart Defender
      for (const tg of targetsFor(ability.targeting.side, ability.targeting.pattern, ability.targeting.count, caster, ctx)) {
        let amt = base
        if (amp) amt *= 1 + ((tg.hp / tg.maxHp < (amp.lowHpBelowPct ?? 30) / 100 ? amp.lowHpAmountPct : amp.amountPct) ?? 0) / 100
        tg.shield = Math.max(tg.shield, amt)        // strongest shield wins — no unbounded stacking from recasts
        tg.shieldExpiresAt = ctx.t + durationSec
      }
    } else if (effect.type === "cleanse") {
      const n = effect.count ?? 1
      for (const tg of targetsFor("ally", ability.targeting.pattern, ability.targeting.count, caster, ctx)) cleanseStatuses(tg, n)
    }
    // taunt / interrupt / unimplemented specials: no-op (deferred)
  }

  // special mechanics (first batch implemented; the rest are no-ops)
  if (effects.some((e) => e.type === "special" && SPECIALS[e.mechanic])) {
    // targets follow the ability's own side (enemy specials get enemies; ally specials like Vital Surge get allies)
    const specialTargets = targetsFor(ability.targeting.side, ability.targeting.pattern, ability.targeting.count, caster, ctx, (ability.targeting as any).band)
    for (const effect of effects)
      if (effect.type === "special" && SPECIALS[effect.mechanic]) {
        SPECIALS[effect.mechanic](caster, ability, effect.params ?? {}, ctx, specialTargets)
        if (!SETUP_SPECIALS.has(effect.mechanic)) logged = true   // guard-setup abilities fall through to a "uses X" cast line
      }
  }

  if (a.generates?.resource) {
    const cap = content.statuses.get(a.generates.resource)?.maxStacks ?? Infinity
    caster.resources[a.generates.resource] = Math.min(cap, (caster.resources[a.generates.resource] ?? 0) + (a.generates.stacks ?? 1))
  }
  if (a.resourceCost?.hpPct) dealDamage(caster, caster.maxHp * (a.resourceCost.hpPct / 100), { bypassIntake: true })   // a deliberate HP cost isn't "incoming damage" — Awareness/Composure must not discount it

  // Inspiring Presence: when the bard casts a song, their own passive heals the whole party.
  const songHeal = (ability.tags ?? []).includes("song") ? (passiveSpecial(caster, "song-heal-on-cast") as any) : null
  if (songHeal?.heal) {
    const per = scaledBy(caster, songHeal.heal.base ?? 0, songHeal.heal.scale ?? 0, songHeal.heal.scaleStat)
    let total = 0
    for (const ally of aliveAllies(ctx)) total += healInto(caster, ally, per)
    if (total > 0)
      ctx.emit("heal", `${caster.name}'s Inspiring Presence washes over the party (${Math.round(per).toLocaleString()} each)`,
        { sourceId: caster.id, sourceName: caster.name, sourceSpec: caster.specId, ability: "Inspiring Presence", amount: Math.round(per), result: "Heal" })
  }

  if (!logged) {
    const ct = castTargetDesc(ability, caster, ctx)   // name the friendly target (Guardian's Oath on Velmora, etc.)
    ctx.emit("flavor", `${caster.name} uses ${ability.name}${ct.suffix}.`,
      { sourceId: caster.id, sourceName: caster.name, sourceSpec: caster.specId, ability: ability.name, skillId: ability.id, target: ct.name, result: "Cast" })
  }
}

/** Fallback when no ability is usable (e.g. a silenced unit, or a healer with nobody hurt): a plain auto-attack. */
export function basicAttack(caster: Combatant, ctx: CombatCtx): void {
  const target = decidePartyFocus(caster, livingMobs(ctx), ctx)   // K.3: auto-attack the brain's focus
  if (!target) return
  const e = eff(caster)
  const emp = takeEmpower(caster)   // Camouflage: empower the auto-attack out of stealth
  const res = resolveHit(
    { amount: e.power * caster.attackInterval * passiveDamageMult(caster, ctx) * emp.mult, damageType: caster.damageType, critChance: emp.crit ? 1 : e.crit, critMult: e.critMult, critable: true },
    defenderOf(target), ctx.rng,
  )
  dealDamage(target, res.dealt); caster.dmgDone += res.dealt
  afterHit(caster, null, target, res, ctx)
  const amt = Math.round(res.dealt)
  ctx.emit(res.isCrit ? "crit" : "normal",
    `${caster.name}'s melee swing hits ${target.name} for ${amt.toLocaleString()} ${caster.damageType}.${res.isCrit ? "(Critical)" : ""}`,
    { sourceId: caster.id, sourceName: caster.name, sourceSpec: caster.specId, ability: "Attack", amount: amt, target: target.name, result: res.isCrit ? "Critical Strike" : "Hit" })
}

/** Does this ability do anything observable right now? */
function hasLiveEffect(a: PlayerAbility): boolean {
  return (a.effects as Effect[]).some((e) =>
    e.type === "damage" || e.type === "heal" || e.type === "buff" || e.type === "debuff" ||
    e.type === "shield" || e.type === "cleanse" ||
    (e.type === "applyStatus" && isLiveStatus(e.status)) ||
    (e.type === "special" && !!SPECIALS[e.mechanic]))
}

function usable(a: PlayerAbility, _caster: Combatant, ctx: CombatCtx): boolean {
  if (!hasLiveEffect(a)) return false
  const effects = a.effects as Effect[]
  const heals = effects.some((e) => e.type === "heal" || (e.type === "applyStatus" && isHot(e.status)) || (e.type === "special" && HEAL_SPECIALS.has(e.mechanic)))
  const dmg = effects.some((e) => e.type === "damage") || effects.some((e) => e.type === "special" && DAMAGE_SPECIALS.has(e.mechanic))
  // a proactive payload (shield/cleanse, or a defensive setup-special like parry/redirect) has value at full HP — don't treat it as a pure heal
  const proactive = effects.some((e) => e.type === "shield" || e.type === "cleanse" || (e.type === "special" && SETUP_SPECIALS.has(e.mechanic)))
  if (heals && !dmg && !proactive && injuredAllies(ctx).length === 0) return false   // skip ONLY pure heals when nobody's hurt (Zen Mode parry / Hotfix shield still fire)
  if (dmg && livingMobs(ctx).length === 0) return false
  if (a.targeting.side === "enemy" && livingMobs(ctx).length === 0) return false
  // a status-consuming special (e.g. detonate-burn) is pointless if no living enemy carries that status
  const detonate = effects.find((e) => e.type === "special" && e.mechanic === "detonate-burn")
  if (detonate && !effects.some((e) => e.type === "damage")) {   // gate PURE detonates (Ignite); a major like Prod Incident does plain AoE too, so it fires regardless of Burn
    const sid = detonate.params?.status ?? "burn"
    if (!livingMobs(ctx).some((m) => m.statuses.some((s) => s.id === sid && s.stacks > 0))) return false
  }
  // Vital Surge is wasted unless an injured ally actually carries a consumable HoT
  const consume = effects.find((e) => e.type === "special" && e.mechanic === "consume-hots-burst-heal")
  if (consume) {
    const cs = new Set<string>(consume.params?.consumeStatuses ?? [])
    if (!injuredAllies(ctx).some((p) => p.statuses.some((s) => s.kind === "hot" && cs.has(s.id)))) return false
  }
  return true
}

const catWeight = (a: PlayerAbility) => (a.category === "Damage" || a.category === "Healing" ? 2 : 1)

/** Pick the highest-priority ready & usable ability, or null to fall back to a basic attack. */
export function selectAbility(caster: Combatant, ctx: CombatCtx): PlayerAbility | null {
  const ready = caster.abilities.filter((a) => (caster.cooldowns[a.id] ?? 0) <= ctx.t && usable(a, caster, ctx))
  if (!ready.length) return null
  ready.sort((a, b) => b.cooldownTurns - a.cooldownTurns || catWeight(b) - catWeight(a))
  return ready[0]
}

/* ============================================================
   Phase K — the shared AI "brain" (one model for players AND enemies).
   K.1 is a PURE-REFACTOR SCAFFOLD: the single decision points exist (`decideAction`, `decideEnemyTarget`) and walk an
   ordered behaviour list resolved from the actor's profile, but every profile currently maps to the defaults that
   reproduce today's play byte-identically. K.2+ add real behaviours; K.5 reads machine-readable `behaviours` off the
   profile data. Behaviours are pure functions of state + the seeded RNG (determinism).
   ============================================================ */
const isMajor = (a: PlayerAbility) => (a.tags ?? []).includes("major")
/** Ready + usable abilities matching a filter, in the engine's priority order (longest CD, then category weight). */
function readyUsable(caster: Combatant, ctx: CombatCtx, filter: (a: PlayerAbility) => boolean): PlayerAbility[] {
  return caster.abilities
    .filter((a) => filter(a) && (caster.cooldowns[a.id] ?? 0) <= ctx.t && usable(a, caster, ctx))
    .sort((a, b) => b.cooldownTurns - a.cooldownTurns || catWeight(b) - catWeight(a))
}
/** Defensive major (walls / absorbs / raid heals → hold for danger) vs offensive (damage / output → fire in damage windows). */
function majorKind(a: PlayerAbility): "defensive" | "offensive" {
  const effs = a.effects as Effect[]
  const def = effs.some((e) => e.type === "shield" || e.type === "heal"
    || (e.type === "applyStatus" && isHot(e.status))                                  // K.6: HoT-only majors (Blossoming Tide) are defensive — hold for danger
    || (e.type === "special" && HEAL_SPECIALS.has(e.mechanic))
    || (e.type === "buff" && ["damageTaken", "armour", "resist"].includes(e.stat))
    || (e.type === "special" && ["parry-counter", "redirect-damage", "damage-redirect", "attack-immunity"].includes(e.mechanic)))
  const off = effs.some((e) => e.type === "damage"
    || (e.type === "buff" && ["power", "haste", "crit", "critMult"].includes(e.stat))
    || (e.type === "special" && e.mechanic === "detonate-burn"))
  return def && !off ? "defensive" : "offensive"
}

type ActionBehaviour = (actor: Combatant, ctx: CombatCtx) => PlayerAbility | null
const ACTION_BEHAVIOURS: Record<string, ActionBehaviour> = {
  // K.2: hold the spec's signature major for a meaningful window instead of dumping it on cooldown. Defensive majors
  // (walls/absorbs/raid heals) wait for danger or a boss; offensive majors fire on a boss or a big pack (≥3 enemies).
  holdForWindow: (caster, ctx) => {
    const major = readyUsable(caster, ctx, isMajor)[0]
    if (!major) return null
    const boss = ctx.mobs.some((m) => m.isBoss && m.hp > 0)
    const cd = ctx.tactics?.cooldowns ?? 0   // K.4: high Cooldowns → defensives fire more proactively (also pre-empt big packs)
    return majorKind(major) === "defensive"
      ? (ctx.partyInDanger || boss || (cd >= 2 && livingMobs(ctx).length >= 3) ? major : null)
      : (boss || livingMobs(ctx).length >= 3 ? major : null)
  },
  // K.2: healer triage — cast the direct heal SIZED to the most-injured ally so a light scratch doesn't eat a Greater
  // Heal (which would mostly overheal). Skips near-full allies (do damage instead). HoTs/major/damage flow elsewhere.
  triageHeal: (caster, ctx) => {
    if (caster.role !== "healer") return null
    const hurt = injuredAllies(ctx)[0]
    if (!hurt || hurt.hp / hurt.maxHp >= 0.85) return null
    // K.6: recognise HoT/special heals, not just plain "heal" effects — the Lifebinder heals ENTIRELY through HoTs, so the
    // old `e.type === "heal"` filter left triage dead for that spec. Mirror usable()'s heal detection.
    const isHeal = (e: Effect) => e.type === "heal" || (e.type === "applyStatus" && isHot(e.status)) || (e.type === "special" && HEAL_SPECIALS.has(e.mechanic))
    const heals = readyUsable(caster, ctx, (a) => !isMajor(a) && (a.effects as Effect[]).some(isHeal))
    if (!heals.length) return null
    // estimate an ability's total heal so triage can size it to the injury (direct heal, HoT tick×duration, or burst special)
    const sizeOf = (a: PlayerAbility) => (a.effects as Effect[]).reduce((s, e) => {
      if (e.type === "heal") return s + (e.base ?? 0) + (e.scale ?? 0) * 100
      if (e.type === "applyStatus" && isHot(e.status)) return s + ((e.magnitudeBase ?? 0) + (e.magnitudeScale ?? 0) * 100) * (e.durationTurns ?? 1)
      if (e.type === "special" && HEAL_SPECIALS.has(e.mechanic)) { const p = e.params ?? {}; return s + ((p.bloomHealBasePerStack ?? p.healBase ?? 60) + (p.bloomHealScalePerStack ?? p.healScale ?? 0) * 100) * (p.burstMultiplier ?? 1) }
      return s
    }, 0)
    const bySize = [...heals].sort((a, b) => sizeOf(b) - sizeOf(a))   // biggest first
    return (1 - hurt.hp / hurt.maxHp) >= 0.4 ? bySize[0] : bySize[bySize.length - 1]   // big injury → biggest heal; light → smallest
  },
  // K.2: pop a defensive cooldown (shield / parry / redirect / immunity) when this actor itself drops low.
  emergencyDefensive: (caster, ctx) => {
    if (caster.hp / caster.maxHp >= 0.4 + 0.05 * (ctx.tactics?.cooldowns ?? 0)) return null   // K.4: high Cooldowns → pop defensives earlier
    const DEF = new Set(["shield-wall-block", "parry-counter", "redirect-damage", "damage-redirect", "attack-immunity"])
    return readyUsable(caster, ctx, (a) => !isMajor(a) && (a.effects as Effect[]).some((e) => e.type === "shield" || (e.type === "special" && DEF.has(e.mechanic))))[0] ?? null
  },
  // the spec's normal rotation, EXCLUDING majors (the major is decided by holdForWindow) — the previous longest-CD-first pick
  dumpRotation: (caster, ctx) => readyUsable(caster, ctx, (a) => !isMajor(a))[0] ?? null,
}

/* ---- K.3: target-selection behaviours (shared — pick one combatant from a candidate pool; stable/deterministic) ---- */
type TargetBehaviour = (candidates: Combatant[], actor: Combatant, ctx: CombatCtx) => Combatant | undefined
const TARGET_BEHAVIOURS: Record<string, TargetBehaviour> = {
  // kill priority (K.4: gated by the Kill Order dial): back-band casters first, then lowest HP — stable so the party focus-fires together
  focusByPriority: (c, _actor, ctx) => {
    if (!c.length) return undefined
    if ((ctx.tactics?.killorder ?? 0) <= 0) return c[0]   // no Kill Order assigned → just hit the lead (no caster priority)
    return [...c].sort((a, b) => (a.position === "Back" ? 0 : 1) - (b.position === "Back" ? 0 : 1) || a.hp - b.hp)[0]
  },
  focusLowestHp: (c) => (c.length ? [...c].sort((a, b) => a.hp - b.hp)[0] : undefined),     // executioner: snipe almost-dead mobs
  focusHighestHp: (c) => (c.length ? [...c].sort((a, b) => b.hp - a.hp)[0] : undefined),     // tunnel-vision tank: hold the biggest
  focusLead: (c) => c[0],
  focusTank: (c) => c.find((p) => p.role === "tank") ?? c[0],                                 // melee/adds smash the tank
  focusSquishy: (c) => {                                                                       // casters dive the squishiest non-tank (back line first)
    const nonTank = c.filter((p) => p.role !== "tank")
    return [...(nonTank.length ? nonTank : c)].sort((a, b) => (a.position === "Back" ? 0 : 1) - (b.position === "Back" ? 0 : 1) || a.maxHp - b.maxHp)[0]
  },
}

/** Resolve an actor's ordered behaviour lists. K.5: targeting comes from machine-readable `behavior-profiles.json` data
    (the role provides the action base since profiles span roles; the profile overrides targeting + optionally the action). */
function brainOf(actor: Combatant): { action: string[]; targetEnemy: string[]; targetAlly: string[] } {
  const prof = content.profiles.get(actor.profile)
  if (actor.team !== "party") {
    return { action: [], targetEnemy: [], targetAlly: prof?.targetAlly ?? ["focusTank"] }   // enemy: melee→tank, caster→squishy (from data)
  }
  const roleAction = actor.role === "healer" ? ["holdForWindow", "triageHeal", "dumpRotation"]
    : actor.role === "tank" ? ["holdForWindow", "emergencyDefensive", "dumpRotation"]
    : ["holdForWindow", "dumpRotation"]
  return { action: prof?.action ?? roleAction, targetEnemy: prof?.targetEnemy ?? ["focusByPriority"], targetAlly: [] }
}

/** Brain — which ability the actor casts this turn (null → basic attack). The single action decision point. */
export function decideAction(actor: Combatant, ctx: CombatCtx): PlayerAbility | null {
  for (const id of brainOf(actor).action) { const a = ACTION_BEHAVIOURS[id]?.(actor, ctx); if (a) return a }
  return null
}

/** Brain — a party member's chosen ENEMY focus among `candidates` (the band-narrowed living mobs). Drives single-target picks. */
export function decidePartyFocus(actor: Combatant, candidates: Combatant[], ctx: CombatCtx): Combatant | undefined {
  if (!candidates.length) return undefined
  for (const id of brainOf(actor).targetEnemy) { const t = TARGET_BEHAVIOURS[id]?.(candidates, actor, ctx); if (t) return t }
  return candidates[0]
}

/** Brain — who an enemy attacks (K.3: profile-driven — melee → tank, caster → squishy). */
export function decideEnemyTarget(enemy: Combatant, ctx: CombatCtx): Combatant | undefined {
  const alive = ctx.party.filter((p) => p.downedUntil < 0)
  if (!alive.length) return undefined
  for (const id of brainOf(enemy).targetAlly) { const t = TARGET_BEHAVIOURS[id]?.(alive, enemy, ctx); if (t) return t }
  return alive[0]
}
