/* GOAT Lite — EGM-model combat engine.
   Continuous-seconds timeline, front/back bands, real stat-driven attacks + the full player ability/
   passive/special set (Phases 1–4), and affixes / boss mechanics / party tactics wired (Phase 5a).
   Remaining: balance retune + UI cutover. Produces the same RunResult shape as the old engine.
   Additive: the live engine (../engine.ts) is still what the UI calls. */
import { content } from "@/content"
import { Rng } from "../rng"
import type { RunInput, RunResult, LogLine, LogKind, LogMeta, ParseRow, DeathReport, ReplayStage, ReplayMob, ReplayTimeline } from "../types"
import { buildParty, makeEnemy, eff, dealDamage, type Combatant } from "./stats"
import { decideAction, decideEnemyTarget, executeAbility, basicAttack, applyPassiveAuras, onStatusEvents, emergencyHeals, resolveEnemyAttack, tickGuards, type CombatCtx } from "./combat"
import { tickStatuses, controlState, consumeDaze, applyStatus } from "./status"
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
  // P.2 — enemy cast scheduler (Bellreach P1 "kick-or-wipe"; only bosses whose ability is flagged interruptible).
  const CAST_EVERY = SIM.castEverySec ?? 12            // a fresh dangerous cast begins every N whole seconds
  const CAST_BASE = SIM.castPayloadBase ?? 16          // base party-wide payload (× keyScale × DMG_UNIT × aggroIntake), matches the old interrupt tick
  const CAST_STACK_GROWTH = SIM.castStackGrowth ?? 0.5 // each UNINTERRUPTED cast amplifies the next by this (stacks → wipe)
  const CAST_FALLBACK_BASE = SIM.castFallbackBase ?? 0.1   // demoted Interrupts dial: weak auto-kick chance with no real interrupter
  const CAST_FALLBACK_PER_PT = SIM.castFallbackPerPt ?? 0.1 // ...+ per dial point (capped) — far weaker than a kicker spec
  // C.10 spike-profile knobs (soft "bring the ideal healer" shape levers). burst (single lowest non-tank /6s) favors the
  // Cleric; rot (each non-tank /3s) favors the HoT. P.3 moved these into tuning so the Mire rot can be softened to a true
  // secondary spice (its post-P.0 edge ran hot) while the curse below carries the real typed-dispel read.
  const BURST_FRAC = SIM.burstFrac ?? 0.06             // per-hit fraction of the victim's maxHp (Stillhour)
  const ROT_FRAC = SIM.rotFrac ?? 0.06                 // per-tick fraction of each non-tank's maxHp (Mire)
  // P.3 — spreading curse (Mire P4; only bosses whose ability is flagged `curse:"<type>"`). THIS is the Mire's real read:
  // a stacking Nature curse that ticks per stack (escalates past flat HPS) and ONLY a Nature dispel (Lifebinder) resets.
  const CURSE_EVERY = SIM.curseEverySec ?? 6           // the boss adds a curse stack every N whole seconds
  const CURSE_BASE = SIM.curseBase ?? 0.3              // per-stack per-second curse tick (× keyScale × DMG_UNIT × aggroIntake) — keyScale-scaled like the other mechanics so it's mild at the +2 floor but ramps at high keys (long fights → more stacks AND bigger ticks)
  const CURSE_DURATION = SIM.curseDurationSec ?? 30    // curse persistence (refreshed each application; long enough not to self-expire between stacks)

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
  const DMG_UNIT = (SIM.dmgUnit ?? 4) * (SIM.enemyDmgMult ?? 1)   // enemyDmgMult: isolated intake lever (see stats.ts); scales boss/affix mechanic damage too
  const hasPeel = input.party.some((p) => (p.profile ?? content.specs.get(p.specId)?.defaultProfile) === "peel")
  let burstStacks = 0   // Bursting affix DoT stacks (persist across stages, decay over time)

  const log: LogLine[] = []
  const deaths: DeathReport[] = []
  const series: number[][] = []
  const healSeries: number[][] = []
  const hpSeries: number[][] = []
  const seriesIds = party.map((p) => p.id)
  const partyMeta = party.map((p) => ({ id: p.id, name: p.name, specId: p.specId }))
  // I.1: 2D-replay accumulators (additive recording — no RNG/combat values consumed)
  const replayStages: ReplayStage[] = []
  const replayMobs: ReplayMob[] = []
  let activeStage: { rec: ReplayStage; mobs: { c: Combatant; rec: ReplayMob }[] } | null = null
  const hpFrac = (c: Combatant) => (c.hp > 0 ? Math.max(0, Math.min(1, c.hp / c.maxHp)) : 0)
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
      // I.1: sample the active stage's mob HP (+ capture death-second) on the same whole-second cadence
      if (activeStage) for (const { c, rec } of activeStage.mobs) {
        rec.hp[nextSnapSec - rec.spawnSec] = hpFrac(c)
        if (c.hp <= 0 && rec.deathSec === null) rec.deathSec = nextSnapSec
      }
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
    let bossTest = "", bossName = "The boss", bossAbil = "its mechanic", bossSpike = ""
    let bossCastable = false, bossTelegraph = 2.5   // P.2: this boss runs the real cast scheduler + its kick window (whole sec)
    let castStacks = 0                              // P.2: uninterrupted-cast escalation for this stage (resets per boss)
    let bossCurse = ""                              // P.3: dispel type the boss applies as a spreading curse ("" = none)
    let curseStatusId = ""                          // P.3: the actual status id for that curse type (data-driven, not hardcoded)
    let stageName = "Trash"

    if (isBoss) {
      const b = content.enemies.get(slot.boss!)!
      bossTest = b.testsTactic ?? ""
      bossName = b.name
      stageName = b.name
      const bAbil = content.abilities.get(b.abilityId ?? "")
      bossAbil = bAbil?.name ?? "its mechanic"
      bossCastable = !!bAbil?.interruptible   // P.2: opt-in real cast (Bellreach only); others keep the abstract dial
      bossTelegraph = bAbil?.telegraph ?? 2.5
      bossCurse = bAbil?.curse ?? ""          // P.3: opt-in spreading curse (Mire only)
      // Resolve the curse status from its TYPE (the dot whose dispel matches) — so `curse:"Nature"` finds creeping-rot and
      // a future `curse:"Magic"` would auto-wire its own status (or no-op safely) rather than misfiring the Nature one.
      curseStatusId = bossCurse ? ([...content.statuses.values()].find((s) => s.dispel === bossCurse && s.kind === "dot")?.id ?? "") : ""
      bossSpike = b.spikeProfile ?? ""
      mobs.push(makeEnemy({ name: b.name, baseHp: b.baseHp, baseDamage: b.baseDamage, isBoss: true, keyScale, affMult, band: b.band, armour: b.armour, resist: b.resist }))
      const tested = content.tactics.get(bossTest)?.name
      emit("good", `${b.name} engages. ${bossAbil} incoming${tested ? ` — tests ${tested}` : ""}.`)
    } else {
      const pack = [...content.packs.values()].find((p) => (slot.packTags ?? []).some((tag) => p.tags.includes(tag))) ?? [...content.packs.values()][0]
      stageName = pack.name
      for (const m of pack.mobs) {
        const e = content.enemies.get(m.enemyId)!
        for (let i = 0; i < m.count; i++) mobs.push(makeEnemy({ name: e.name, baseHp: e.baseHp, baseDamage: e.baseDamage, isBoss: false, keyScale, affMult, band: e.band, armour: e.armour, resist: e.resist }))
      }
    }

    // reset action clocks to "now" so attack cadence is per-stage; clear carried-over shields & per-encounter flags
    // P.3: also clear any enemy-applied curse (any dispel-typed status) so it doesn't compound dungeon-wide — fresh ramp per boss.
    for (const p of party) { p.nextActionAt = t; p.shield = 0; p.emergencyHealed = false; p.guards = {}; p.statuses = p.statuses.filter((s) => !content.statuses.get(s.id)?.dispel) }
    for (const m of mobs) m.nextActionAt = t

    const stageStartT = t
    // I.1: open a replay stage record + per-mob trackers (deterministic; pure recording)
    const stageRec: ReplayStage = { idx: stageIdx, kind: isBoss ? "boss" : "trash", name: stageName, startSec: Math.floor(t), endSec: Math.floor(t), mobIds: [] }
    const stageMobs = mobs.map((m, i) => {
      const rec: ReplayMob = { id: `s${stageIdx}m${i}`, name: m.name, band: m.position === "Back" ? "back" : "front", isBoss: m.isBoss, stageIdx, spawnSec: Math.floor(t), deathSec: null, hp: [hpFrac(m)] }
      stageRec.mobIds.push(rec.id)
      return { c: m, rec }
    })
    replayStages.push(stageRec)
    for (const sm of stageMobs) replayMobs.push(sm.rec)
    activeStage = { rec: stageRec, mobs: stageMobs }
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
      tactics: tac,   // K.4: the dials drive the brain (Kill Order → kill priority, Cooldowns → defensive timing)
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

        if (isBoss && mobs.some((m) => m.isBoss && m.hp > 0)) {   // boss signature (skip if boss already dead this step)
          const bn = bossName, abil = bossAbil
          const m = (target: string, result: string): LogMeta => ({ sourceName: bn, ability: abil, target, result })
          // P.3: spreading curse (Mire P4) — independent of the rot/cast branch. Adds a stack to the whole party on its
          // cadence; the DoT ticks per stack (escalates past flat HPS), and ONLY a matching-type dispel (Nature →
          // Lifebinder's Unbinding Word) resets it. Cleric's Magic/Curse dispel can't, so a no-Lifebinder comp drowns.
          if (curseStatusId && since % CURSE_EVERY === 0) {
            const cb = mobs.find((mm) => mm.isBoss && mm.hp > 0)
            if (cb) {
              for (const pp of aliveParty()) applyStatus(pp, curseStatusId, { stacks: 1, perTick: CURSE_BASE * keyScale * DMG_UNIT * aggroIntake, durationSec: CURSE_DURATION, applierId: cb.id, t })
              const stk = aliveParty()[0]?.statuses.find((s) => s.id === curseStatusId)?.stacks ?? 0
              emit("mechanic", `${bn}'s ${abil} — the rot-curse creeps deeper (${stk} stack${stk === 1 ? "" : "s"}; dispel ${bossCurse}).`, m("party", "Curse stack"))
            }
          }
          if (bossSpike === "burst") {
            // C.10: a SOFT "bring the triage healer" lever ("player not class" — small by design). A single hit on the
            // lowest-HP non-tank every 6s. Gentle enough that both healers clear low/mid keys cleanly; near the ceiling
            // (where general intake has eaten the healer's spare throughput) the Cleric's instant recovery / pre-applied
            // absorb extends the timed ceiling ~1-2 keys over a slow HoT. testsTactic stays "cooldowns" so the dial
            // mitigates; opt-in (enemy.spikeProfile) so Ashveil's cooldowns boss is untouched. (BURST_FRAC tunes the gap.)
            if (since % 6 === 0) {
              const v = aliveParty().filter((pp) => pp.role !== "tank").sort((a, b) => a.hp / a.maxHp - b.hp / b.maxHp)[0] ?? aliveParty()[0]
              if (v) {
                dealDamage(v, BURST_FRAC * v.maxHp * aggroIntake * (1 - 0.12 * (tac.cooldowns ?? 0)))
                emit("mechanic", `${bn}'s ${abil} falls on ${v.name} — top them fast. Cooldowns ${tac.cooldowns ?? 0}.`, m(v.name, "Burst spike"))
              }
            }
          } else if (bossSpike === "rot") {
            // C.10 inverse: a SOFT "bring the rolling-HoT healer" lever. A flat tick on each non-tank every 3s. Gentle
            // enough that both healers clear low/mid keys cleanly; near the ceiling the all-ally HoT (covering many
            // targets at once) extends the timed ceiling ~1-2 keys over a single-target burst healer. (ROT_FRAC tunes it.)
            if (since % 3 === 0) {
              for (const pp of aliveParty()) if (pp.role !== "tank") dealDamage(pp, ROT_FRAC * pp.maxHp * aggroIntake * (1 - 0.12 * (tac.cooldowns ?? 0)))
              emit("mechanic", `${bn}'s ${abil} — the rot rises across the party. Cooldowns ${tac.cooldowns ?? 0}.`, m("party", "Rot tick"))
            }
          } else if (bossCastable) {
            // P.2: REAL kick-or-wipe cast. Begins on the cadence; if the telegraph window elapses uninterrupted, a
            // STACKING party-wide payload lands. A real interrupter spec OR a landed stun/silence/freeze cancels the
            // pending cast (combat.cancelEnemyCast); the demoted Interrupts dial is only a weak auto-kick backstop.
            const boss = mobs.find((mm) => mm.isBoss && mm.hp > 0)
            if (boss && !boss.pendingCast && since % CAST_EVERY === 0) {
              boss.pendingCast = { name: abil, fireAt: since + Math.max(1, Math.round(bossTelegraph)) }
              emit("mechanic", `${bn} begins ${abil} — interrupt it!`, m("party", "Cast begins"))
            } else if (boss && boss.pendingCast && since >= boss.pendingCast.fireAt) {
              if (rng.chance(Math.min(0.6, CAST_FALLBACK_BASE + CAST_FALLBACK_PER_PT * (tac.interrupts ?? 0)))) {
                emit("good", `${abil} is interrupted on automation. Interrupts ${tac.interrupts ?? 0}.`, m("party", "Cast interrupted (dial)"))
              } else {
                const payload = CAST_BASE * keyScale * DMG_UNIT * aggroIntake * (1 + castStacks * CAST_STACK_GROWTH)
                for (const pp of aliveParty()) dealDamage(pp, payload)
                castStacks++
                emit("mechanic", `${bn}'s ${abil} goes off — the party craters (peal ${castStacks}). Interrupts ${tac.interrupts ?? 0}.`, m("party", "Cast not interrupted"))
              }
              boss.pendingCast = null
            }
          } else if (since % 12 === 0) {
            if (bossTest === "interrupts") {
              if (!rng.chance(Math.min(0.95, 0.2 + 0.25 * (tac.interrupts ?? 0)))) {
                for (const pp of aliveParty()) dealDamage(pp, 16 * keyScale * DMG_UNIT * aggroIntake)
                emit("mechanic", `${bn}'s ${abil} goes through — the party is hurting. Interrupts ${tac.interrupts ?? 0}.`, m("party", "Cast not interrupted"))
              }
            } else if (bossTest === "positioning") {
              if (rng.chance(Math.max(0.06, 0.6 - 0.18 * (tac.positioning ?? 0)) * aggroIntake)) {
                const v = rand(); if (v) { dealDamage(v, 18 * keyScale * DMG_UNIT * aggroIntake); emit("mechanic", `${bn} drops ${abil} — ${v.name} is caught in it. Positioning ${tac.positioning ?? 0}.`, m(v.name, "Stood in fire")) }
              }
            } else if (bossTest === "cooldowns") {
              for (const pp of aliveParty()) dealDamage(pp, 14 * keyScale * DMG_UNIT * aggroIntake * (1 - 0.12 * (tac.cooldowns ?? 0)))
              emit("mechanic", `${bn} enters ${abil} — a damage spike. Cooldowns ${tac.cooldowns ?? 0}.`, m("party", "Damage spike"))
            } else if (bossTest === "killorder") {
              const tk = aliveParty().find((pp) => pp.role === "tank") ?? aliveParty()[0]
              if (tk) { dealDamage(tk, 14 * keyScale * DMG_UNIT * (1 - 0.25 * (tac.killorder ?? 0))); emit("mechanic", `${bn}'s ${abil} summons diggers. Kill Order ${tac.killorder ?? 0}.`, m(tk.name, "Adds spawned")) }
            }
          }
        }

        if (!isBoss && since % 10 === 0) {   // avoidable trash affixes (Positioning roll)
          const hitChance = Math.max(0.06, 0.6 - 0.18 * (tac.positioning ?? 0)) * aggroIntake
          // KNOWN ASYMMETRY (pre-existing): Volcanic per-hit damage is NOT scaled by aggroIntake — aggression changes how
          // OFTEN you eat it (hitChance above), not how hard — unlike Spiteful/Positioning, which scale both. Fine at
          // enemyDmgMult=2.0 (the +2 floor + curve were verified with this behaviour); revisit in the next balance pass.
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

    // I.1: close the replay stage — final HP sample + death-second for anything still tracked
    stageRec.endSec = Math.floor(t)
    for (const { c, rec } of stageMobs) {
      const idx = Math.floor(t) - rec.spawnSec
      if (idx >= 0) rec.hp[idx] = hpFrac(c)
      if (c.hp <= 0 && rec.deathSec === null) rec.deathSec = Math.floor(t)
    }
    activeStage = null

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

  const replay: ReplayTimeline = { stages: replayStages, mobs: replayMobs, durationSec: duration }

  return {
    seed: input.seed, outcome, durationSec: duration, timerSec, keyDelta, log, parse, deaths, finalHpPct,
    series, healSeries, hpSeries, seriesIds, partyMeta,
    finalRezCharges: rezCharges, nextRezChargeAtSec: Math.max(0, Math.round(nextRezChargeAt - t)),
    replay,
  }
}
