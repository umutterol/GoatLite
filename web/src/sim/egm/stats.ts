/* EGM-model combatant stats (Phase 1).
   Derives a real combat-stat block from the EXISTING ilvl + role model (no STR/AGI/INT added).
   `power` stays the primary scaler; the WoW-style secondaries get a real job here. */
import { content } from "@/content"
import type { PlayerAbility } from "@/content"
import type { SimPartyMember } from "../types"
import type { DamageType } from "./pipeline"
import { resolveOperator } from "./operator"

export interface StatMod { stat: string; amountPct: number }

/** Transient per-encounter "guard" states for Wave 3 peel/defensive mechanics (reset each stage). */
export interface Guards {
  immunityCharges?: number          // Blessing of Protection: negate the next N enemy attacks
  immuneNoAttack?: boolean          // ...and the protected ally cannot attack while immune
  immunityExpiresAt?: number        // ...with a time cap so an un-attacked ally isn't locked out forever
  blockCharges?: number             // Shield Wall: fully block the next N attacks
  blockReflectPct?: number          // ...reflecting this % back to the attacker
  parry?: { chancePct: number; base: number; scale: number; scaleStat?: string; damageType: DamageType; expiresAt: number }  // Earthen Stance
  redirect?: { protectorId: string; redirectPct: number; reductionPct: number; expiresAt: number }                          // Guardian's Oath / Spirit Link
  empowerMult?: number              // Camouflage: next attack × this
  empowerCrit?: boolean             // ...and is a guaranteed crit
  ccImmuneWhileShielded?: boolean   // Arcane Barrier (inert: no enemy CC source today)
  barrierBreak?: { casterId: string; base: number; scale: number; scaleStat?: string; damageType: DamageType }              // Arcane Barrier shield-break AoE
  firstCcExtended?: boolean         // Arcane Mastery: first CC the arcanist applies lasts +N turns
}

export interface ActiveStatus {
  id: string
  kind: "dot" | "hot" | "cc" | "debuff" | "buff" | "shield" | "resource"
  control?: "stun" | "silence" | "daze" | "freeze"
  stacks: number
  perTick: number        // per-second magnitude per stack (DoT damage / HoT heal); 0 for non-ticking
  statMods?: StatMod[]   // Phase 3: stat changes while active (buffs/debuffs/Mark/Chill)
  untargetable?: boolean
  expiresAt: number      // seconds; Infinity = persists
  applierId: string
}

/** Effective combat stats after active buffs/debuffs are applied. */
export interface EffStats {
  power: number; maxHp: number; armour: number; resist: number
  crit: number; critMult: number; attackInterval: number
  dodgeChance: number; damageTakenPct: number; healingTakenPct: number
}

const SIM = content.tuning.sim as Record<string, number>
export const HP_UNIT = SIM.hpUnit ?? 780
// `enemyDmgMult` is the isolated INTAKE difficulty lever (default 1 = no change). It folds into
// DMG_UNIT, which is referenced ONLY by enemy-dealt damage (enemy auto-attacks here + the 6 boss/
// affix mechanics in engine.ts) — never by player throughput (player power has no DMG_UNIT term)
// or enemy HP (HP_UNIT). So raising it makes survival bind harder without touching kill-speed.
export const ENEMY_DMG_MULT = SIM.enemyDmgMult ?? 1
export const DMG_UNIT = (SIM.dmgUnit ?? 4) * ENEMY_DMG_MULT
export const ATTACK_INTERVAL_BASE = SIM.attackIntervalBase ?? 2.0   // seconds between auto-attacks at 0 haste
export const ENEMY_ATTACK_INTERVAL = SIM.enemyAttackInterval ?? 1.0
// P.0 (Phase P) GATE 0 — the anti-generic-EHP floor. Stacked PERCENTAGE mitigation (party armour × Awareness intake ×
// DR buffs) can never cut a hit below this fraction of its pre-mitigation size (i.e. mitigation caps at a 60% reduction).
// Shields (a finite pool) and HoTs (separate healing) are deliberately NOT clamped here — they're recost in P.5.
export const INTAKE_FLOOR_FRAC = SIM.intakeFloorFrac ?? 0.4

export type Role = "tank" | "healer" | "dps"
const ROLE: Record<string, Role> = { Tank: "tank", Healer: "healer", DPS: "dps" }

export interface Combatant {
  id: string; name: string; specId: string
  team: "party" | "enemy"
  role: Role; position: "Front" | "Back"
  profile: string             // Phase K: behaviour profile id (spec defaultProfile / per-member override; enemy = melee|caster). Drives the AI brain
  maxHp: number; hp: number; shield: number; shieldExpiresAt: number
  power: number               // primary scaler (party); parse basis
  attackPower: number         // raw damage per auto-attack, pre crit/mitigation
  attackInterval: number      // seconds between auto-attacks
  damageType: DamageType
  armour: number; resist: number
  critChance: number; critMult: number
  dodgeChance: number
  damageTakenPct: number
  // healer
  mana: number; maxMana: number; healCost: number; manaRegen: number; hps: number
  // runtime
  nextActionAt: number
  downedUntil: number
  dmgDone: number; healDone: number; deaths: number
  isBoss: boolean
  guarding?: boolean          // P.4: this enemy shields its `shielded` allies while it lives (kill it first)
  shielded?: boolean          // P.4: near-immune (damageTakenPct set by the engine) while a `guarding` ally lives
  pendingCast?: { name: string; fireAt: number } | null   // P.2: a dangerous enemy cast in flight (whole-sec fireAt); null/undefined = not casting. Cleared by an interrupt/CC.
  // Phase 2: ability layer
  abilities: PlayerAbility[]            // active abilities for the rotation (party only)
  passive: PlayerAbility | null         // the spec's passive ability (Phase 3.5)
  cooldowns: Record<string, number>     // abilityId -> ready-at time (sec)
  statuses: ActiveStatus[]
  resources: Record<string, number>     // e.g. { rampage: 3 }
  hitSinceAction: boolean               // for the "if hit since last action" condition (Revenge)
  lastActionAt: number
  emergencyHealed: boolean              // Nature's Grace emergency heal — once per combat per ally (Phase 3.5)
  guards: Guards                        // Wave 3 transient peel/defensive states (reset per stage)
  talents: TalentDmg[]                  // B.7 talent damage modifiers (maxHp already baked into maxHp at build)
  talentCondIntake: TalentCondMod[]     // §A: onlyIf-gated damage-taken mods (defender; refreshed per step by the engine)
  talentCondCrit: TalentCondMod[]       // §A: onlyIf-gated crit-chance mods (attacker; evaluated per hit)
  talentEventRiders: EventRider[]       // §E (M3a): on hit/crit/kill action riders (applyStatus/adjustCooldown/refundResource/heal)
  talentAtonement?: { disableAbilityId?: string; partyWhenLowestAllyBelowPct?: number }   // §D (M4): atonement disable / party-swap config
  // Phase F operator layer (party only; enemies carry neutral 1s)
  intakeMult: number          // live damage-taken multiplier — Awareness (static) × Composure clutch; refreshed per step by the engine
  opOutputMult: number        // static party output multiplier (Execution + Awareness output + trait output)
  opClutchOutMult: number     // output multiplier applied on top while the party is in danger (Composure)
  opIntakeStatic: number      // the static part of intakeMult (Awareness reduction + trait intake)
  opClutchIntakeMult: number  // further intake multiplier applied while in danger (Composure)
}

/** A talent's outgoing-damage modifier, optionally gated by a condition. */
export interface TalentDmg { dmgPct: number; onlyIf?: { type: string; value?: number; resource?: string; status?: string; minStacks?: number; band?: string } }

/** A talent's onlyIf-gated intake or crit modifier (`pct` = intakePct or critPct, %), evaluated at runtime via condHolds. */
export interface TalentCondMod { pct: number; onlyIf?: { type: string; value?: number; resource?: string; status?: string; minStacks?: number; band?: string } }

/** §B (M2): a talent's ability-override (structural; the closed shape is enforced by Zod in schema.ts / AbilityOverrideSchema). */
export type AbilityOverride = { kind: string; abilityId: string; [k: string]: any }

/** §E (M3a): a talent's event rider (structural; closed shape enforced by Zod in schema.ts / EventRiderSchema). */
export type EventRider = { trigger: string; ability?: string; chancePct?: number; applyStatus?: any; adjustCooldown?: any; refundResource?: any; heal?: any }

/** §B (M2): apply a member's talent ability-overrides to CLONES of the targeted abilities (never mutate shared content).
    Returns the same arrays untouched when there are no overrides (byte-identical default). Exported for the M2 probe. */
export function applyAbilityOverrides(abilities: PlayerAbility[], passive: PlayerAbility | null, overrides: AbilityOverride[] | undefined): { abilities: PlayerAbility[]; passive: PlayerAbility | null } {
  if (!overrides || !overrides.length) return { abilities, passive }
  const cloned = new Map<string, PlayerAbility>()
  const getClone = (id: string): any | undefined => {
    if (cloned.has(id)) return cloned.get(id)
    const orig = abilities.find((a) => a.id === id) ?? (passive?.id === id ? passive : undefined)
    if (!orig) return undefined
    const c = structuredClone(orig) as PlayerAbility
    cloned.set(id, c)
    return c
  }
  for (const ov of overrides) {
    const a = getClone(ov.abilityId)
    if (!a) continue   // unknown ability (the cross-ref validator should have caught this) → skip
    applyOneOverride(a, ov)
  }
  if (!cloned.size) return { abilities, passive }
  return {
    abilities: abilities.map((a) => cloned.get(a.id) ?? a),
    passive: passive ? (cloned.get(passive.id) ?? passive) : null,
  }
}

function applyOneOverride(a: any, ov: AbilityOverride): void {
  switch (ov.kind) {
    case "cooldown": a.cooldownTurns = ov.cooldownTurns; break
    case "targeting":
      if (ov.pattern != null) a.targeting.pattern = ov.pattern
      if (ov.count != null) a.targeting.count = ov.count
      if (ov.band != null) a.targeting.band = ov.band
      break
    case "param": {
      const e = (a.effects as any[]).find((x) => x.type === "special" && x.mechanic === ov.mechanic)
      if (e) { e.params = e.params ?? {}; e.params[ov.key] = ov.value }
      break
    }
    case "scalar": {
      const e = (a.effects as any[]).find((x) => x.type === ov.effectType)
      if (e) e[ov.field] = ov.value
      break
    }
    case "addModifier": {
      const e = (a.effects as any[]).find((x) => x.type === "damage")
      if (e) { e.modifiers = e.modifiers ?? []; e.modifiers.push({ when: ov.when, multiplyDamage: ov.multiplyDamage }) }
      break
    }
  }
}

/** Resolve a member's chosen talents → maxHp mult, damage mods, UNCONDITIONAL intake/crit deltas, AND onlyIf-gated
    conditional intake/crit mods (evaluated at runtime via condHolds). Defaults to the balanced pick. */
function resolveTalents(chosen: Record<string, string> | undefined, specId?: string): { hpMult: number; dmg: TalentDmg[]; intakePct: number; critPct: number; condIntake: TalentCondMod[]; condCrit: TalentCondMod[]; abilityOverrides: AbilityOverride[]; eventRiders: EventRider[]; atonement: { disableAbilityId?: string; partyWhenLowestAllyBelowPct?: number } | undefined } {
  let hpMult = 1, intakePct = 0, critPct = 0
  const dmg: TalentDmg[] = [], condIntake: TalentCondMod[] = [], condCrit: TalentCondMod[] = [], abilityOverrides: AbilityOverride[] = [], eventRiders: EventRider[] = []
  let atonement: { disableAbilityId?: string; partyWhenLowestAllyBelowPct?: number } | undefined
  for (const node of content.talents.values()) {
    if (node.specId && node.specId !== specId) continue   // M7: a per-spec node applies only to its spec (global nodes have no specId)
    // chosen → default → first option (matches the Character-sheet picker's fallback exactly)
    const opt = (chosen?.[node.id] && node.options.find((o) => o.id === chosen[node.id])) || node.options.find((o) => o.default) || node.options[0]
    const eff = opt?.effects
    if (!eff) continue
    if (eff.maxHpPct) hpMult *= 1 + eff.maxHpPct / 100
    if (eff.dmgPct) dmg.push({ dmgPct: eff.dmgPct, onlyIf: eff.onlyIf })
    // §A: an onlyIf-gated intake/crit becomes a runtime conditional mod; unconditional ones keep the build-time fold (byte-identical).
    if (eff.intakePct) { if (eff.onlyIf) condIntake.push({ pct: eff.intakePct, onlyIf: eff.onlyIf }); else intakePct += eff.intakePct }
    if (eff.critPct) { if (eff.onlyIf) condCrit.push({ pct: eff.critPct, onlyIf: eff.onlyIf }); else critPct += eff.critPct }
    if (eff.abilityOverrides) abilityOverrides.push(...(eff.abilityOverrides as AbilityOverride[]))   // §B (M2)
    if (eff.eventRiders) eventRiders.push(...(eff.eventRiders as EventRider[]))   // §E (M3a)
    if (eff.atonement) atonement = { ...(atonement ?? {}), ...eff.atonement }   // §D (M4): merge across chosen options
  }
  return { hpMult, dmg, intakePct, critPct, condIntake, condCrit, abilityOverrides, eventRiders, atonement }
}

export function moraleMult(m: number): number {
  if (m >= 90) return 1.05
  if (m >= 50) return 1.0
  return 0.7 + (Math.max(0, m) / 50) * 0.3
}

// Auto-attack damage type per spec (Phase 1 flavour; enemies carry no resist yet, so this is cosmetic until gear).
const MAGIC_CLASSES = new Set(["mage", "paladin"])
function autoDamageType(classId: string, specId: string): DamageType {
  if (specId === "lifebinder") return "Magic"
  return MAGIC_CLASSES.has(classId) ? "Magic" : "Physical"
}

export function buildParty(party: SimPartyMember[], aggressionOutput: number, dialCrit: number): Combatant[] {
  const rm = content.tuning.roleModel as Record<string, Record<string, number>>
  const hq = content.tuning.hitQuality as Record<string, unknown>
  const baseCrit = (hq.baseCrit as number) ?? 0.05
  const critMult = ((hq.critMultiplier as number[]) ?? [1.5, 2.0])[1] ?? 2.0

  return party.map((p) => {
    const spec = content.specs.get(p.specId)!
    const role = ROLE[spec.role]
    const c = rm[role]
    // item-stats M2: power/HP/armour scale off the gear-derived effective ilvl (Σ mainStat/MAIN_K, rarity+slot-weighted).
    // Absent (harnesses set raw ilvl) → falls back to plain ilvl → byte-identical. Rarity's spike rides here.
    const il = p.effIlvl ?? p.ilvl
    const power = c.powerPerIlvl * il * moraleMult(p.morale) * aggressionOutput
    const haste = 0 // M3 wires Haste from p.secondaries here
    const attackInterval = ATTACK_INTERVAL_BASE / (1 + haste / 100)
    const tal = resolveTalents(p.talents, p.specId)   // M7: filter to global + this spec's nodes
    const op = resolveOperator(p.skills, p.traitIds)   // Phase F: operator skills + trait combat → multipliers
    // H.3: talent intakePct folds into the operator (uniform) intake channel
    const intakeStatic = Math.max(0.2, Math.min(2, op.intakeStatic * (1 + tal.intakePct / 100)))
    const maxHp = c.hpPerIlvl * il * tal.hpMult * op.hpMult
    const baseAbilities = [...content.playerAbilities.values()].filter((a) => a.specId === p.specId && a.trigger === "active")
    const basePassive = [...content.playerAbilities.values()].find((a) => a.specId === p.specId && a.trigger === "passive") ?? null
    const { abilities, passive } = applyAbilityOverrides(baseAbilities, basePassive, tal.abilityOverrides)   // §B (M2)
    return {
      id: p.id, name: p.name, specId: p.specId, team: "party",
      role, position: spec.position, profile: p.profile ?? spec.defaultProfile,
      maxHp, hp: maxHp, shield: 0, shieldExpiresAt: 0,
      power,
      attackPower: power * attackInterval,   // so pre-crit DPS ≈ power, matching the current balance
      attackInterval,
      damageType: autoDamageType(spec.classId, p.specId),
      armour: (c.armourPerIlvl ?? 0) * il, resist: 0,
      critChance: Math.max(0, baseCrit + dialCrit + op.critBonus + tal.critPct / 100), critMult,
      dodgeChance: op.dodgeBonus, damageTakenPct: 0,
      mana: c.mana ?? 0, maxMana: c.mana ?? 0, healCost: c.healCost ?? 0,
      manaRegen: c.manaRegenPerSec ?? 0, hps: (c.hpsPerIlvl ?? 0) * il,
      nextActionAt: 0, downedUntil: -1, dmgDone: 0, healDone: 0, deaths: 0, isBoss: false,
      abilities, passive, cooldowns: {}, statuses: [], resources: {}, hitSinceAction: false, lastActionAt: 0,
      emergencyHealed: false, guards: {}, talents: tal.dmg, talentCondIntake: tal.condIntake, talentCondCrit: tal.condCrit, talentEventRiders: tal.eventRiders, talentAtonement: tal.atonement,
      intakeMult: intakeStatic, opOutputMult: op.outputMult, opClutchOutMult: op.clutchOutMult,
      opIntakeStatic: intakeStatic, opClutchIntakeMult: op.clutchIntakeMult,
    }
  })
}

export function makeEnemy(opts: {
  name: string; baseHp: number; baseDamage: number; isBoss: boolean
  keyScale: number; affMult: number; band?: "front" | "back"
  armour?: number; resist?: number   // C.8: damage-school defense (authored base; scaled by keyScale to track gear)
  guarding?: boolean; shielded?: boolean   // P.4: bodyguard / guarded kill-priority pair
}): Combatant {
  const hp = opts.baseHp * HP_UNIT * opts.keyScale * opts.affMult
  return {
    id: "", name: opts.name, specId: "", team: "enemy",
    // P.0: bosses tank-and-spank (focusTank), never dive — the dive (focusSquishy) is for back-band TRASH casters only.
    // (The old `band===back ? caster` rule made 10 back-band bosses auto-attack the squishy back-line — a correctness bug
    // the C.11 audit blamed for the survival-dominance regime; intentional dives still go through spikeProfile/abilities.)
    role: "dps", position: opts.band === "back" ? "Back" : "Front", profile: opts.isBoss ? "melee" : (opts.band === "back" ? "caster" : "melee"),
    maxHp: hp, hp, shield: 0, shieldExpiresAt: 0,
    power: 0,
    attackPower: opts.baseDamage * opts.keyScale * opts.affMult * DMG_UNIT,
    attackInterval: ENEMY_ATTACK_INTERVAL,
    damageType: "Physical",
    // C.8/P.0: armour mitigates the party's Physical, resist their Magic (school wall). Default 0 = unmitigated (Ashveil
    // unchanged). NOT scaled by keyScale anymore — the wall is hit-size-independent (see pipeline.schoolWallFraction), so a
    // flat base gives a STABLE off-school tax % across keys (the old keyScale coupling drifted the tax up with key level).
    armour: opts.armour ?? 0, resist: opts.resist ?? 0,
    critChance: 0, critMult: 1, dodgeChance: 0, damageTakenPct: 0,
    mana: 0, maxMana: 0, healCost: 0, manaRegen: 0, hps: 0,
    nextActionAt: 0, downedUntil: -1, dmgDone: 0, healDone: 0, deaths: 0, isBoss: opts.isBoss,
    guarding: opts.guarding, shielded: opts.shielded,
    abilities: [], passive: null, cooldowns: {}, statuses: [], resources: {}, hitSinceAction: false, lastActionAt: 0,
    emergencyHealed: false, guards: {}, talents: [], talentCondIntake: [], talentCondCrit: [], talentEventRiders: [],
    intakeMult: 1, opOutputMult: 1, opClutchOutMult: 1, opIntakeStatic: 1, opClutchIntakeMult: 1,   // enemies: neutral operator layer
  }
}

/** Params of a passive ability's special mechanic, or undefined if this combatant's passive lacks it. */
export function passiveSpecial(c: Combatant, mechanic: string): Record<string, unknown> | undefined {
  if (!c.passive) return undefined
  const e = (c.passive.effects as { type: string; mechanic?: string; params?: Record<string, unknown> }[])
    .find((x) => x.type === "special" && x.mechanic === mechanic)
  return e?.params
}

/** Effective stats = base stats with all active buff/debuff/Chill/Mark stat-mods applied. */
export function eff(c: Combatant): EffStats {
  let power = 0, maxhp = 0, armour = 0, resist = 0, crit = 0, critmult = 0, haste = 0, vers = 0, dtaken = 0, healrecv = 0
  for (const s of c.statuses) {
    if (!s.statMods) continue
    for (const m of s.statMods) {
      switch (m.stat) {
        case "power": power += m.amountPct; break
        case "maxHp": maxhp += m.amountPct; break
        case "armour": armour += m.amountPct; break
        case "resist": resist += m.amountPct; break
        case "crit": crit += m.amountPct; break
        case "critMult": critmult += m.amountPct; break
        case "haste": haste += m.amountPct; break
        case "versatility": vers += m.amountPct; break
        case "damageTaken": dtaken += m.amountPct; break
        case "healingReceived": healrecv += m.amountPct; break   // §C (M3b): anti-heal channel
      }
    }
  }
  return {
    power: c.power * (1 + power / 100),
    maxHp: c.maxHp * (1 + maxhp / 100),
    armour: c.armour * (1 + armour / 100),
    resist: c.resist * (1 + resist / 100),
    crit: Math.max(0, c.critChance + crit / 100),       // crit mods are percentage points
    critMult: c.critMult * (1 + critmult / 100),
    attackInterval: c.attackInterval / (1 + haste / 100), // +haste shortens, Chill (−haste) lengthens
    dodgeChance: Math.min(0.6, Math.max(0, c.dodgeChance + vers / 100)),
    // P.4: include the base field (always 0 for party/normal enemies → byte-identical) so the engine can set a flat
    // damage-taken delta directly on a combatant (the guarded enemy's near-immunity) without authoring a status.
    damageTakenPct: dtaken + c.damageTakenPct,
    healingTakenPct: healrecv,   // §C (M3b): anti-heal — "healingReceived" statMods cut incoming healing on this combatant (0 → unchanged)
  }
}

/** Apply damage to a combatant — Phase F operator intake (party only) reduces it first, then shield soaks, then life.
    `bypassIntake` skips the operator multiplier for SELF-INFLICTED costs (ability HP costs aren't "incoming damage"). */
export function dealDamage(target: Combatant, amount: number, opts?: { bypassIntake?: boolean; preMitigation?: number }): void {
  // Uniform Awareness/Composure intake: applies to ALL external incoming (auto-attacks, affix ticks, mechanics, redirects).
  const external = target.team === "party" && !opts?.bypassIntake
  let amt = external ? amount * target.intakeMult : amount
  // P.0 GATE 0: floor the COMBINED percentage reduction (armour/resist mitigation already folded into `amount` + the
  // intake mult applied just above) at INTAKE_FLOOR_FRAC of the pre-mitigation hit. `preMitigation` is the raw pre-armour
  // swing for auto-attacks; for affix/boss ticks it defaults to `amount` (their only reduction is the intake mult). The
  // clamp is a MIN, so amplified hits (Mark/damageTaken+) are untouched — it only catches over-stacked mitigation. Then
  // shields (a finite pool, intentionally NOT floored) soak what's left.
  if (external) amt = Math.max(amt, INTAKE_FLOOR_FRAC * (opts?.preMitigation ?? amount))
  if (target.shield > 0) { const soak = Math.min(target.shield, amt); target.shield -= soak; amt -= soak }
  target.hp -= amt
}
