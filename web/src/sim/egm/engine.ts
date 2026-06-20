/* GOAT Lite — EGM-model combat engine.
   Continuous-seconds timeline, front/back bands, real stat-driven attacks + the full player ability/
   passive/special set (Phases 1–4), and affixes / boss mechanics / party tactics wired (Phase 5a).
   Remaining: balance retune + UI cutover. Produces the same RunResult shape as the old engine.
   Additive: the live engine (../engine.ts) is still what the UI calls. */
import { content } from "@/content"
import { Rng } from "../rng"
import type { RunInput, RunResult, LogLine, LogKind, LogMeta, ParseRow, DeathReport } from "../types"
import { buildParty, makeEnemy, eff, dealDamage, type Combatant } from "./stats"
import { decideAction, decideEnemyTarget, executeAbility, basicAttack, applyPassiveAuras, onStatusEvents, emergencyHeals, resolveEnemyAttack, tickGuards, type CombatCtx } from "./combat"
import { tickStatuses, controlState, consumeDaze } from "./status"
import { activeAffixIds } from "../affixes"
import { DANGER_HP_FRAC, RECENT_DEATH_SEC } from "./operator"

const DT = 0.25                       // inner timestep (seconds) for the continuous timeline
const MAX_ACTIONS_PER_STEP = 8        // safety against degenerate (near-zero) attack intervals

export function runDungeonEGM(input: RunInput): RunResult {
  const rng = new Rng(input.seed)
  const SIM = content.tuning.sim as Record<string, number>
  const HP_KEY = SIM.keyScalingPerLevel ?? 1.05
  const AFFX = SIM.affixMultiplier ?? 1.3
  const ENRAGE_AFTER = SIM.softEnrageAfterSeconds ?? 90
  const ENRAGE_STEP = SIM.softEnrageStepSeconds ?? 5
  const ENRAGE_PER = SIM.softEnragePerStep ?? 0.05
  const SECONDS_PER_TURN = SIM.secondsPerTurn ?? 3
  const DEATH_PENALTY = SIM.deathPenaltySec ?? 5   // timer seconds added per death (GDD default 5; tunable)
  const REZ_REGEN_SEC = SIM.rezRegenSec ?? 300     // a combat-rez charge regenerates every N seconds (5 min)
  const REZ_START = SIM.rezStartCharges ?? 1       // party starts the run with this many rez charges

  const aggr = (content.tuning.aggression as Record<string, { output: number; avoidableIntake: number }>)[input.aggression]
  const hq = content.tuning.hitQuality as Record<string, unknown>
  const dialCrit = ((hq.dialCrit as Record<string, number>) ?? {})[input.aggression] ?? 0

  const party = buildParty(input.party, aggr.output, dialCrit)
  const dungeon = content.dungeons.get(input.dungeonId)!
  const aff = new Set(activeAffixIds(input.affixIds, input.keyLevel))   // WoW-style: low keys run with fewer/no affixes
  const keyScale = Math.pow(HP_KEY, input.keyLevel - 2)
  const timerSec = dungeon.timerSeconds

  // affix / tactics wiring (Phase 5a)
  const tac = input.tactics
  const aggroIntake = aggr.avoidableIntake
  const DMG_UNIT = SIM.dmgUnit ?? 4
  const hasPeel = input.party.some((p) => (p.profile ?? content.specs.get(p.specId)?.defaultProfile) === "peel")
  let burstStacks = 0   // Bursting affix DoT stacks (persist across stages, decay over time)

  const log: LogLine[] = []
  const deaths: DeathReport[] = []
  const series: number[][] = []
  const healSeries: number[][] = []
  const hpSeries: number[][] = []
  const seriesIds = party.map((p) => p.id)
  const partyMeta = party.map((p) => ({ id: p.id, name: p.name, specId: p.specId }))
  series[0] = party.map(() => 0)
  healSeries[0] = party.map(() => 0)
  hpSeries[0] = party.map(() => 1)

  let t = 0
  let deathPenalty = 0
  let lastDeathT = -Infinity                 // Phase F: time of the most recent party death (drives the Composure clutch window)
  let rezCharges = REZ_START                 // shared combat-rez pool; a dead member only revives by spending one
  let nextRezChargeAt = REZ_REGEN_SEC        // run-level (persists across stages); next charge regenerates at this time
  let nextSnapSec = 1
  let wiped = false
  let called = false

  const fmt = (s: number) => `${Math.floor(s / 60)}:${String(Math.floor(s % 60)).padStart(2, "0")}`
  const emit = (kind: LogKind, text: string, meta?: LogMeta) => { if (text) log.push({ t: fmt(t), tSec: Math.floor(t), kind, text, meta }) }
  const aliveParty = () => party.filter((p) => p.downedUntil < 0)

  const snapshot = () => {
    while (Math.floor(t) >= nextSnapSec) {
      series[nextSnapSec] = party.map((p) => Math.round(p.dmgDone))
      healSeries[nextSnapSec] = party.map((p) => Math.round(p.healDone))
      hpSeries[nextSnapSec] = party.map((p) => (p.downedUntil >= 0 ? 0 : Math.max(0, Math.min(1, p.hp / p.maxHp))))
      nextSnapSec++
    }
  }

  const affNames = input.affixIds.map((a) => content.affixes.get(a)?.name ?? a).join(", ")
  emit("flavor", `Keystone inserted. ${dungeon.name} +${input.keyLevel} — ${affNames}. The font flares.`)

  let stageIdx = 0
  for (const slot of dungeon.slots) {
    if (wiped || called) break
    stageIdx += 1
    const isBoss = slot.kind === "boss"
    const affMult = isBoss ? (aff.has("tyrannical") ? AFFX : 1) : (aff.has("fortified") ? AFFX : 1)
    const mobs: Combatant[] = []
    let bossTest = "", bossName = "The boss", bossAbil = "its mechanic"

    if (isBoss) {
      const b = content.enemies.get(slot.boss!)!
      bossTest = b.testsTactic ?? ""
      bossName = b.name
      bossAbil = content.abilities.get(b.abilityId ?? "")?.name ?? "its mechanic"
      mobs.push(makeEnemy({ name: b.name, baseHp: b.baseHp, baseDamage: b.baseDamage, isBoss: true, keyScale, affMult, band: b.band }))
      const tested = content.tactics.get(bossTest)?.name
      emit("good", `${b.name} engages. ${bossAbil} incoming${tested ? ` — tests ${tested}` : ""}.`)
    } else {
      const pack = [...content.packs.values()].find((p) => (slot.packTags ?? []).some((tag) => p.tags.includes(tag))) ?? [...content.packs.values()][0]
      for (const m of pack.mobs) {
        const e = content.enemies.get(m.enemyId)!
        for (let i = 0; i < m.count; i++) mobs.push(makeEnemy({ name: e.name, baseHp: e.baseHp, baseDamage: e.baseDamage, isBoss: false, keyScale, affMult, band: e.band }))
      }
    }

    // reset action clocks to "now" so attack cadence is per-stage; clear carried-over shields & per-encounter flags
    for (const p of party) { p.nextActionAt = t; p.shield = 0; p.emergencyHealed = false; p.guards = {} }
    for (const m of mobs) m.nextActionAt = t

    const stageStartT = t
    let lastEnemyEmitSec = -1
    let lastEventSec = Math.floor(t)   // absolute whole-second cursor (one affix tick per real second)
    let stageSec = 0                   // whole seconds elapsed since stage start (exact cadence, no fractional drift)
    const handledDeaths = new Set<Combatant>()
    let guard = 0
    const ctx: CombatCtx = {
      rng, t, secondsPerTurn: SECONDS_PER_TURN, party, mobs,
      emit, resolveCombatant: (id) => party.find((p) => p.id === id),
      // Kill Order boosts trash DPS; Cooldowns boosts boss burn (party→enemy output)
      outgoingMult: 1 + (isBoss ? 0.04 * (tac.cooldowns ?? 0) : 0.06 * (tac.killorder ?? 0)),
      partyInDanger: false,
    }
    for (const p of aliveParty()) applyPassiveAuras(p, ctx)   // refresh permanent passive auras at stage start

    while (mobs.some((m) => m.hp > 0) && !wiped) {
      t += DT
      if (++guard > (timerSec * 3) / DT) break

      // --- combat resurrection: charges gate revives (no more rez-spamming) ---
      if (t >= nextRezChargeAt) { rezCharges += 1; nextRezChargeAt += REZ_REGEN_SEC }
      // a dead member (downedUntil === Infinity = awaiting) spends a charge to begin a 10s resurrection
      for (const p of party) if (p.downedUntil === Infinity && rezCharges > 0) {
        rezCharges -= 1; p.downedUntil = t + 10
        emit("good", `${p.name} is being resurrected (${rezCharges} rez charge${rezCharges === 1 ? "" : "s"} left).`,
          { sourceId: p.id, sourceName: p.name, sourceSpec: p.specId, ability: "Combat Resurrection", result: "Rez" })
      }
      // finish a scheduled resurrection
      for (const p of party) if (p.downedUntil >= 0 && t >= p.downedUntil) { p.downedUntil = -1; p.hp = p.maxHp * 0.4 }

      const enrage = t - stageStartT > ENRAGE_AFTER ? 1 + ENRAGE_PER * Math.floor((t - stageStartT - ENRAGE_AFTER) / ENRAGE_STEP) : 1
      const livingMobs = () => mobs.filter((m) => m.hp > 0)

      // --- Phase F: refresh the Composure clutch state for this step (any ally hurt or a recent death) ---
      const inDanger = aliveParty().some((p) => p.hp / p.maxHp < DANGER_HP_FRAC) || (t - lastDeathT < RECENT_DEATH_SEC)
      ctx.partyInDanger = inDanger
      for (const p of party) p.intakeMult = p.opIntakeStatic * (inDanger ? p.opClutchIntakeMult : 1)

      // --- party actions: cast the best ready ability, else a basic attack (gated by crowd control) ---
      ctx.t = t
      for (const p of aliveParty()) {
        let acted = 0
        while (t >= p.nextActionAt && acted < MAX_ACTIONS_PER_STEP) {
          p.nextActionAt += eff(p).attackInterval
          acted++
          const cc = controlState(p)
          if (cc.blocked) continue                    // stunned / frozen: lose the action
          if (cc.dazed) { consumeDaze(p); continue }   // daze: lose one action, then it clears
          if ((p.guards.immunityCharges ?? 0) > 0 && p.guards.immuneNoAttack && t < (p.guards.immunityExpiresAt ?? Infinity)) continue  // Blessing of Protection: immune but can't act
          const ability = cc.silenced ? null : decideAction(p, ctx)  // silence: basic attack only
          if (ability) executeAbility(p, ability, ctx)
          else basicAttack(p, ctx)
          p.hitSinceAction = false
          p.lastActionAt = t
          if (p.role !== "healer" && !mobs.some((m) => m.hp > 0)) break
        }
      }

      // --- on-death affix triggers (trash that just died) ---
      for (const m of mobs) if (m.hp <= 0 && !handledDeaths.has(m)) {
        handledDeaths.add(m)
        if (m.isBoss) continue
        if (aff.has("bursting")) burstStacks += Math.max(0, 1 - 0.2 * (tac.killorder ?? 0))   // Kill Order keeps Bursting stacks low
        if (aff.has("bolstering")) {                                                // survivors grow; Kill Order's even-kill plan minimizes it
          const buff = 0.15 * Math.max(0, 1 - 0.33 * (tac.killorder ?? 0))
          for (const s of mobs) if (s.hp > 0 && !s.isBoss) { s.attackPower *= 1 + buff; s.hp *= 1 + buff; s.maxHp *= 1 + buff }
        }
        if (aff.has("spiteful")) {                                                  // a ghost chases the squishiest; Peel/tank pickup halves it
          const lowest = aliveParty().slice().sort((a, b) => a.power - b.power)[0]
          if (lowest) dealDamage(lowest, 9 * keyScale * DMG_UNIT * aggroIntake * (hasPeel ? 0.5 : 1))
        }
      }

      // --- enemy actions (K.3: target via the brain — melee→tank, caster→squishy; mitigated by armour) ---
      for (const m of livingMobs()) {
        let acted = 0
        while (t >= m.nextActionAt && acted < MAX_ACTIONS_PER_STEP) {
          let interval = eff(m).attackInterval   // Chill (−haste) slows enemies
          if (aff.has("raging") && !m.isBoss && m.hp < 0.3 * m.maxHp) interval /= 1 + 0.25 * (1 - 0.1 * (tac.cooldowns ?? 0))   // Raging: enraged trash (sub-30%, never bosses) gains up to +25% haste — attacks faster; Cooldowns blunts it
          m.nextActionAt += interval
          acted++
          const cc = controlState(m)
          if (cc.blocked) continue                   // mob stunned / frozen (Leg Sweep, Frost Nova, Meteor)
          if (cc.dazed) { consumeDaze(m); continue }
          const victim = decideEnemyTarget(m, ctx)
          if (!victim) break
          const amount = m.attackPower * enrage   // Raging no longer spikes per-hit damage — it grants haste (handled at the attack-interval step above)
          const r = resolveEnemyAttack(m, victim, { amount, damageType: m.damageType, critChance: 0, critMult: 1, critable: false }, ctx)
          if (r.dealt > 0) victim.hitSinceAction = true   // Revenge-style procs only off attacks that actually land
          if (Math.floor(t) > lastEnemyEmitSec) {
            lastEnemyEmitSec = Math.floor(t)
            const dmg = `${Math.round(r.dealt).toLocaleString()} ${m.damageType}`
            const msg =
              r.outcome === "Immune"     ? `${victim.name} shrugs off ${m.name}'s attack` :
              r.outcome === "Parry"      ? `${victim.name} parries ${m.name}` :
              r.outcome === "Blocked"    ? `${victim.name} blocks ${m.name}` :
              r.outcome === "Dodge"      ? `${victim.name} dodges ${m.name}` :
              r.outcome === "Redirected" ? `${m.name}'s melee swing hits ${victim.name} for ${dmg}. (redirected)` :
                                           `${m.name}'s melee swing hits ${victim.name} for ${dmg}.`
            emit("normal", msg, { sourceName: m.name, ability: "Strike", amount: Math.round(r.dealt), target: victim.name, result: r.outcome })
          }
        }
      }

      // --- affix & boss mechanics, fired on whole-second boundaries (tactics mitigate; damage soaks shields) ---
      while (lastEventSec < Math.floor(t)) {
        lastEventSec++
        const since = ++stageSec
        const rand = () => aliveParty()[rng.int(0, Math.max(0, aliveParty().length - 1))]

        if (burstStacks > 0) {   // Bursting: party DoT per stack per second
          for (const p of aliveParty()) dealDamage(p, burstStacks * 0.007 * p.maxHp * aggroIntake)
          burstStacks = Math.max(0, burstStacks - 0.3)
        }

        if (isBoss && since % 12 === 0 && mobs.some((m) => m.isBoss && m.hp > 0)) {   // boss signature (skip if boss already dead this step)
          const bn = bossName, abil = bossAbil
          const m = (target: string, result: string): LogMeta => ({ sourceName: bn, ability: abil, target, result })
          if (bossTest === "interrupts") {
            if (!rng.chance(Math.min(0.95, 0.2 + 0.25 * (tac.interrupts ?? 0)))) {
              for (const pp of aliveParty()) dealDamage(pp, 16 * keyScale * DMG_UNIT * aggroIntake)
              emit("mechanic", `${bn}'s ${abil} goes through — the party is hurting. Interrupts ${tac.interrupts ?? 0}.`, m("party", "Cast not interrupted"))
            }
          } else if (bossTest === "positioning") {
            if (rng.chance(Math.max(0.06, 0.6 - 0.18 * (tac.positioning ?? 0)) * aggroIntake)) {
              const v = rand(); if (v) { dealDamage(v, 18 * keyScale * DMG_UNIT * aggroIntake); emit("mechanic", `${bn} drops ${abil} — ${v.name} is caught in it. Positioning ${tac.positioning ?? 0}.`, m(v.name, "Stood in fire")) }
          } } else if (bossTest === "cooldowns") {
            for (const pp of aliveParty()) dealDamage(pp, 14 * keyScale * DMG_UNIT * aggroIntake * (1 - 0.12 * (tac.cooldowns ?? 0)))
            emit("mechanic", `${bn} enters ${abil} — a damage spike. Cooldowns ${tac.cooldowns ?? 0}.`, m("party", "Damage spike"))
          } else if (bossTest === "killorder") {
            const tk = aliveParty().find((pp) => pp.role === "tank") ?? aliveParty()[0]
            if (tk) { dealDamage(tk, 14 * keyScale * DMG_UNIT * (1 - 0.25 * (tac.killorder ?? 0))); emit("mechanic", `${bn}'s ${abil} summons diggers. Kill Order ${tac.killorder ?? 0}.`, m(tk.name, "Adds spawned")) }
          }
        }

        if (!isBoss && since % 10 === 0) {   // avoidable trash affixes (Positioning roll)
          const hitChance = Math.max(0.06, 0.6 - 0.18 * (tac.positioning ?? 0)) * aggroIntake
          if (aff.has("volcanic") && rng.chance(hitChance)) {
            const v = rand(); if (v) { dealDamage(v, 40 * keyScale * DMG_UNIT); emit("mechanic", `${v.name} eats a Volcanic eruption. Positioning ${tac.positioning ?? 0}.`, { sourceName: "Volcanic", ability: "Volcanic Plume", target: v.name, result: "Avoidable" }) }
          }
          if (aff.has("sanguine") && rng.chance(hitChance)) {
            for (const m of mobs) if (m.hp > 0 && !m.isBoss) m.hp = Math.min(m.maxHp, m.hp + 0.05 * m.maxHp)
            emit("mechanic", `The pack sits in its Sanguine pool, healing. Positioning ${tac.positioning ?? 0}.`, { sourceName: "Sanguine", ability: "Sanguine Ichor", target: "the pack", result: "Enemy healed" })
          }
        }
      }

      // --- DoT / HoT ticks + shield expiry; status events drive atonement-on-dot / Blossom bloom ---
      for (const m of mobs) if (m.hp > 0) onStatusEvents(m, tickStatuses(m, DT, t, ctx.resolveCombatant), ctx)
      for (const p of party) if (p.downedUntil < 0) {
        onStatusEvents(p, tickStatuses(p, DT, t, ctx.resolveCombatant), ctx)
        if (p.shield > 0 && t >= p.shieldExpiresAt) p.shield = 0
      }
      emergencyHeals(ctx)   // Nature's Grace: rescue an ally who dropped below threshold this step
      tickGuards(DT, ctx)   // Wave 3: regen / Divine Insight aura / Arcane Barrier shield-break detonation

      // --- deaths & wipe ---
      for (const p of party) if (p.downedUntil < 0 && p.hp <= 0) {
        p.downedUntil = Infinity; p.deaths += 1; deathPenalty += DEATH_PENALTY; lastDeathT = t   // dead → awaiting a rez charge (Infinity); revived only when one is spent
        const cause = isBoss ? "boss damage" : aff.has("bursting") ? "Bursting" : aff.has("spiteful") ? "Spiteful ghost" : "trash damage"
        deaths.push({ tSec: Math.floor(t), t: fmt(t), name: p.name, cause })
        const noRez = rezCharges <= 0 && t < nextRezChargeAt
        emit("death", `${p.name} dies (${cause})${noRez ? " — no rez charge available" : ""}.`,
          { sourceId: p.id, sourceName: p.name, sourceSpec: p.specId, ability: cause, result: "Death" })
      }

      snapshot()
      // all members down simultaneously (dead or mid-rez) = auto-fail the run
      if (party.every((p) => p.downedUntil >= 0)) { wiped = true; break }
    }

    if (!wiped) emit("good", isBoss ? `${mobs[0].name} falls.` : `Pack cleared. Onward.`)
    if (!wiped && input.stopAfterStage && stageIdx >= input.stopAfterStage) {
      called = true
      emit("flavor", `You call the run after stage ${stageIdx} — bank the loot, take the deplete.`)
    }
  }

  snapshot()
  const duration = Math.floor(t) + deathPenalty
  let outcome: RunResult["outcome"]
  let keyDelta: number
  if (wiped) { outcome = "wipe"; keyDelta = -1; emit("death", `Party wipe. The run is lost — and so is the loot.`) }
  else if (called) { outcome = "depleted"; keyDelta = -1; emit("flavor", `Run called — depleted, but the loot is banked.`) }
  else if (duration <= timerSec) { outcome = "timed"; keyDelta = 1; emit("good", `Key TIMED with ${fmt(timerSec - duration)} to spare. +1 keystone.`) }
  else { outcome = "depleted"; keyDelta = -1; emit("flavor", `Over time by ${fmt(duration - timerSec)}. Depleted — keystone drops a level.`) }

  const ticks = Math.max(1, Math.floor(t))
  const theo = party.map((p) => p.power * ticks)
  const maxTheo = Math.max(...theo, 1)
  const parse: ParseRow[] = party.map((p, i) => ({
    id: p.id, name: p.name, spec: p.specId,
    actual: Math.round(Math.min(99, (p.dmgDone / maxTheo) * 95)),
    expected: Math.round(Math.min(99, (theo[i] / maxTheo) * 95)),
  })).sort((a, b) => b.actual - a.actual)

  const finalHpPct = party.map((p) => ({ id: p.id, name: p.name, pct: Math.max(0, Math.round((p.hp / p.maxHp) * 100)), dead: p.downedUntil >= 0 }))

  return {
    seed: input.seed, outcome, durationSec: duration, timerSec, keyDelta, log, parse, deaths, finalHpPct,
    series, healSeries, hpSeries, seriesIds, partyMeta,
    finalRezCharges: rezCharges, nextRezChargeAtSec: Math.max(0, Math.round(nextRezChargeAt - t)),
  }
}
