/* GOAT Lite — deterministic event-level tick simulation (GDD Simulation Spec, 1s ticks).
   Runs a dungeon key to a RunResult. Pure given (input, content). */
import { content } from "@/content"
import type { Skill } from "@/content"
import { Rng } from "./rng"
import type { RunInput, RunResult, LogLine, LogKind, LogMeta, ParseRow, DeathReport } from "./types"

type Role = "tank" | "healer" | "dps"

interface Combatant {
  id: string; name: string; specId: string; role: Role; ilvl: number
  maxHp: number; hp: number
  basePower: number            // per-tick output (morale + aggression already applied)
  armour: number               // tanks only
  hps: number                  // healers only
  mana: number; maxMana: number; healCost: number; manaRegen: number
  downedUntil: number          // tick index; -1 = up
  dmgDone: number; healDone: number; deaths: number
}

interface Mob { hp: number; maxHp: number; damage: number; isBoss: boolean; abilityId?: string; name: string }

const SIM = content.tuning.sim as Record<string, number>
const HP_UNIT = SIM.hpUnit ?? 780
const DMG_UNIT = SIM.dmgUnit ?? 4
const ROLE: Record<string, Role> = { Tank: "tank", Healer: "healer", DPS: "dps" }

function moraleMult(m: number): number {
  if (m >= 90) return 1.05
  if (m >= 50) return 1.0
  return 0.7 + (Math.max(0, m) / 50) * 0.3
}

function buildParty(input: RunInput): Combatant[] {
  const rm = content.tuning.roleModel as Record<string, Record<string, number>>
  const aggro = (content.tuning.aggression as Record<string, { output: number }>)[input.aggression].output
  return input.party.map((p) => {
    const spec = content.specs.get(p.specId)!
    const role = ROLE[spec.role]
    const c = rm[role]
    const power = c.powerPerIlvl * p.ilvl * moraleMult(p.morale) * aggro
    return {
      id: p.id, name: p.name, specId: p.specId, role, ilvl: p.ilvl,
      maxHp: c.hpPerIlvl * p.ilvl, hp: c.hpPerIlvl * p.ilvl,
      basePower: power,
      armour: (c.armourPerIlvl ?? 0) * p.ilvl,
      hps: (c.hpsPerIlvl ?? 0) * p.ilvl,
      mana: c.mana ?? 0, maxMana: c.mana ?? 0, healCost: c.healCost ?? 0, manaRegen: c.manaRegenPerSec ?? 0,
      downedUntil: -1, dmgDone: 0, healDone: 0, deaths: 0,
    }
  })
}

function pickLine(kind: LogKind, subs: Record<string, string>, affixId?: string): string | null {
  const tpls = [...content.logTemplates.values()].filter(
    (t) => t.kind === kind && (affixId ? t.affixId === affixId : !t.affixId)
  )
  if (!tpls.length) return null
  // deterministic-ish pick by subs hash is overkill; caller passes rng-picked line index via subs._i
  const idx = subs._i ? parseInt(subs._i, 10) % tpls.length : 0
  let line = tpls[idx].lines[(subs._j ? parseInt(subs._j, 10) : 0) % tpls[idx].lines.length]
  for (const [k, v] of Object.entries(subs)) line = line.replaceAll(`{${k}}`, v)
  return line.replace(/\{[a-z]+\}/g, "").trim()
}

export function runDungeon(input: RunInput): RunResult {
  const rng = new Rng(input.seed)
  const party = buildParty(input)
  const dungeon = content.dungeons.get(input.dungeonId)!
  const aff = new Set(input.affixIds)
  const tac = input.tactics
  const aggroIntake = (content.tuning.aggression as Record<string, { avoidableIntake: number }>)[input.aggression].avoidableIntake
  const keyScale = Math.pow(SIM.keyScalingPerLevel ?? 1.05, input.keyLevel - 2)
  const AFFX = SIM.affixMultiplier ?? 1.3
  const timerSec = dungeon.timerSeconds

  const log: LogLine[] = []
  const deaths: DeathReport[] = []
  const series: number[][] = []                                   // per-tick cumulative damage per party member
  const seriesIds = party.map((p) => p.id)
  const partyMeta = party.map((p) => ({ id: p.id, name: p.name, specId: p.specId }))
  series[0] = party.map(() => 0)
  // original-GOAT skill names grouped per spec by category. Names ONLY drive the replay/tooltips;
  // the turn-based formulas/CDs are reference metadata and never feed the 1s-tick sim.
  const skillsBySpec = new Map<string, { dmg: Skill[]; heal: Skill[] }>()
  for (const sk of content.skills.values()) {
    const e = skillsBySpec.get(sk.specId) ?? { dmg: [], heal: [] }
    if (sk.category === "Damage") e.dmg.push(sk)
    else if (sk.category === "Healing") e.heal.push(sk)
    skillsBySpec.set(sk.specId, e)
  }
  // deterministic, RNG-free pick (indexed by tick) so the sim stream — and thus balance — is unchanged
  const pickSkill = (specId: string, kind: "dmg" | "heal"): { id?: string; name: string } => {
    const pool = skillsBySpec.get(specId)?.[kind] ?? []
    if (pool.length) { const sk = pool[(t + (kind === "heal" ? 1 : 0)) % pool.length]; return { id: sk.id, name: sk.name } }
    return { name: content.specs.get(specId)?.name ?? "attack" }
  }
  let t = 0
  let deathPenalty = 0
  const fmt = (s: number) => `${Math.floor(s / 60)}:${String(Math.floor(s % 60)).padStart(2, "0")}`
  const emit = (kind: LogKind, text: string, meta?: LogMeta) => { if (text) log.push({ t: fmt(t), tSec: t, kind, text, meta }) }

  const aliveParty = () => party.filter((p) => p.downedUntil < 0)
  const partyPower = (boss: boolean) => {
    let mult = 1
    if (!boss) mult += 0.06 * (tac.killorder ?? 0)         // Kill Order: trash DPS
    if (boss) mult += 0.04 * (tac.cooldowns ?? 0)          // Cooldowns: boss burn
    mult *= 1 + 0.05 * (content.tuning.hitQuality as Record<string, number>).baseCrit * 15 // avg crit folded in (small)
    return aliveParty().reduce((s, p) => s + p.basePower, 0) * mult
  }

  const dungeonName = dungeon.name
  const affNames = input.affixIds.map((a) => content.affixes.get(a)?.name ?? a).join(", ")
  emit("flavor", `Keystone inserted. ${dungeonName} +${input.keyLevel} — ${affNames}. The font flares.`)

  let burstStacks = 0
  let wiped = false
  let called = false
  const hasPeel = input.party.some((p) => (p.profile ?? content.specs.get(p.specId)?.defaultProfile) === "peel")
  const ENRAGE_AFTER = SIM.softEnrageAfterSeconds ?? 90
  const ENRAGE_STEP = SIM.softEnrageStepSeconds ?? 5
  const ENRAGE_PER = SIM.softEnragePerStep ?? 0.05

  let stageIdx = 0
  for (const slot of dungeon.slots) {
    if (wiped || called) break
    stageIdx += 1
    const isBoss = slot.kind === "boss"
    const mobs: Mob[] = []
    let bossTest = ""
    const affMult = isBoss ? (aff.has("tyrannical") ? AFFX : 1) : (aff.has("fortified") ? AFFX : 1)
    if (isBoss) {
      const b = content.enemies.get(slot.boss!)!
      bossTest = b.testsTactic ?? ""
      mobs.push({ hp: b.baseHp * HP_UNIT * keyScale * affMult, maxHp: b.baseHp * HP_UNIT * keyScale * affMult, damage: b.baseDamage, isBoss: true, abilityId: b.abilityId, name: b.name })
      emit("good", `${b.name} engages. ${content.abilities.get(b.abilityId!)?.name ?? ""} incoming — tests ${content.tactics.get(b.testsTactic!)?.name}.`)
    } else {
      const pack = [...content.packs.values()].find((p) => (slot.packTags ?? []).some((tag) => p.tags.includes(tag))) ?? [...content.packs.values()][0]
      for (const m of pack.mobs) {
        const e = content.enemies.get(m.enemyId)!
        for (let i = 0; i < m.count; i++) mobs.push({ hp: e.baseHp * HP_UNIT * keyScale * affMult, maxHp: e.baseHp * HP_UNIT * keyScale * affMult, damage: e.baseDamage, isBoss: false, name: e.name })
      }
    }

    const stageStartT = t
    let stageGuard = 0
    while (mobs.some((m) => m.hp > 0) && !wiped) {
      t += 1
      if (++stageGuard > timerSec * 3) break  // stall safety

      // revive downed
      for (const p of party) if (p.downedUntil >= 0 && t >= p.downedUntil) { p.downedUntil = -1; p.hp = p.maxHp * 0.4 }

      // --- party damage: focus fire (Kill Order sequences deaths) ---
      let dps = partyPower(isBoss)
      // distribute: focus the lowest-index living mob (sequential). Low Kill Order → spread (deaths cluster).
      const focus = tac.killorder >= 2 || isBoss
      const living = mobs.filter((m) => m.hp > 0)
      if (focus) {
        let rem = dps
        for (const m of living) { const d = Math.min(m.hp, rem); m.hp -= d; rem -= d; if (rem <= 0) break }
      } else {
        const per = dps / living.length
        for (const m of living) m.hp -= per
      }
      // attribute damage for parse, then snapshot the cumulative series (for the live DPS meter)
      for (const p of aliveParty()) p.dmgDone += p.basePower
      series[t] = party.map((p) => Math.round(p.dmgDone))

      // --- on mob deaths: affix on-death triggers ---
      for (const m of living) if (m.hp <= 0) {
        if (aff.has("bursting") && !m.isBoss) { burstStacks += 1 }
        if (aff.has("bolstering") && !m.isBoss) {  // survivors gain HP/damage; Kill Order's even-kill plan minimizes it
          const buff = 0.15 * Math.max(0, 1 - 0.33 * (tac.killorder ?? 0))
          for (const s of mobs) if (s.hp > 0 && !s.isBoss) { s.damage *= 1 + buff; s.hp *= 1 + buff; s.maxHp *= 1 + buff }
        }
        if (aff.has("spiteful") && !m.isBoss) {
          const lowest = aliveParty().sort((a, b) => a.basePower - b.basePower)[0]
          if (lowest) lowest.hp -= 9 * keyScale * DMG_UNIT * aggroIntake * (hasPeel ? 0.5 : 1)  // Peel profile / tank pickup
        }
      }

      // --- Bursting party DoT (~1% party HP per stack per second; Kill Order keeps stacks low) ---
      if (burstStacks > 0) {
        for (const p of aliveParty()) p.hp -= burstStacks * 0.007 * p.maxHp * aggroIntake
        if (rng.chance(0.04 * burstStacks)) emit("mechanic", pickLine("mechanic", { n: String(Math.round(burstStacks)), actor: party[0].name, _i: String(rng.int(0, 9)), _j: String(rng.int(0, 9)) }, "bursting") ?? `Bursting at ${Math.round(burstStacks)} stacks.`,
          { sourceName: "Bursting", ability: "Burst", amount: Math.round(burstStacks), target: "party", result: "DoT tick" })
        burstStacks = Math.max(0, burstStacks - 0.3)
      }

      // --- mob melee → tank (ratio armour, per-mob; soft-enrage + Raging) ---
      const enrage = t - stageStartT > ENRAGE_AFTER ? 1 + ENRAGE_PER * Math.floor((t - stageStartT - ENRAGE_AFTER) / ENRAGE_STEP) : 1
      const tank = aliveParty().find((p) => p.role === "tank") ?? aliveParty()[0]
      if (tank) {
        let taken = 0
        for (const m of mobs) if (m.hp > 0) {
          let hit = m.damage * keyScale * affMult * DMG_UNIT * enrage
          if (aff.has("raging") && m.hp < 0.3 * m.maxHp) hit *= 1.5 * (1 - 0.1 * (tac.cooldowns ?? 0))  // enraged spike; Cooldowns absorbs
          const ratio = tank.armour / Math.max(1, hit)
          const reduction = Math.min(0.9, ratio / (ratio + 10))
          taken += hit * (1 - reduction)
        }
        tank.hp -= taken
      }

      // --- boss signature mechanic, gated by the tactic that boss audits ---
      if (isBoss && t % 12 === 0) {
        const boss = mobs.find((m) => m.isBoss)
        const bn = boss?.name ?? "The boss"
        const abil = content.abilities.get(boss?.abilityId ?? "")?.name ?? "its mechanic"
        if (bossTest === "interrupts") {
          if (!rng.chance(Math.min(0.95, 0.2 + 0.25 * (tac.interrupts ?? 0)))) {
            for (const pp of aliveParty()) pp.hp -= 16 * keyScale * DMG_UNIT * aggroIntake
            emit("mechanic", `${bn}'s ${abil} goes through — the party is hurting. Interrupts ${tac.interrupts ?? 0}.`,
              { sourceName: bn, ability: abil, target: "party", result: "Cast not interrupted" })
          }
        } else if (bossTest === "positioning") {
          if (rng.chance(Math.max(0.06, 0.6 - 0.18 * (tac.positioning ?? 0)) * aggroIntake)) {
            const v = aliveParty()[rng.int(0, Math.max(0, aliveParty().length - 1))]
            if (v) { v.hp -= 18 * keyScale * DMG_UNIT * aggroIntake; if (rng.chance(0.5)) emit("mechanic", `${bn} drops ${abil} — ${v.name} is standing in it. Positioning ${tac.positioning ?? 0}.`,
              { sourceName: bn, ability: abil, target: v.name, result: "Stood in fire" }) }
          }
        } else if (bossTest === "cooldowns") {
          for (const pp of aliveParty()) pp.hp -= 14 * keyScale * DMG_UNIT * aggroIntake * (1 - 0.12 * (tac.cooldowns ?? 0))
          if (rng.chance(0.3)) emit("mechanic", `${bn} enters ${abil} — a damage spike. Cooldowns ${tac.cooldowns ?? 0}.`,
            { sourceName: bn, ability: abil, target: "party", result: "Damage spike" })
        } else if (bossTest === "killorder") {
          const tk = aliveParty().find((pp) => pp.role === "tank") ?? aliveParty()[0]
          if (tk) tk.hp -= 14 * keyScale * DMG_UNIT * (1 - 0.25 * (tac.killorder ?? 0))
          if (rng.chance(0.25)) emit("mechanic", `${bn}'s ${abil} summons diggers. Kill Order ${tac.killorder ?? 0}.`,
            { sourceName: bn, ability: abil, target: tk?.name ?? "tank", result: "Adds spawned" })
        }
      }

      // --- avoidable affix events (Positioning roll): Volcanic damages, Sanguine heals the pack (time loss) ---
      if (!isBoss && t % 10 === 0) {
        const hitChance = Math.max(0.06, 0.6 - 0.18 * (tac.positioning ?? 0)) * aggroIntake
        if (aff.has("volcanic") && rng.chance(hitChance)) {
          const victim = aliveParty()[rng.int(0, Math.max(0, aliveParty().length - 1))]
          if (victim) { victim.hp -= 40 * keyScale * DMG_UNIT; if (rng.chance(0.3)) emit("mechanic", `${victim.name} eats a Volcanic eruption. Positioning ${tac.positioning ?? 0}.`,
            { sourceName: "Volcanic", ability: "Volcanic Plume", target: victim.name, result: "Avoidable" }) }
        }
        if (aff.has("sanguine") && rng.chance(hitChance)) {
          for (const m of mobs) if (m.hp > 0 && !m.isBoss) m.hp = Math.min(m.maxHp, m.hp + 0.05 * m.maxHp)
          if (rng.chance(0.25)) emit("mechanic", `The pack sits in its Sanguine pool, healing. Positioning ${tac.positioning ?? 0}.`,
            { sourceName: "Sanguine", ability: "Sanguine Ichor", target: "the pack", result: "Enemy healed" })
        }
      }

      // --- healers (each heals the lowest-HP injured ally if mana allows) ---
      for (const healer of aliveParty().filter((p) => p.role === "healer")) {
        if (healer.mana >= healer.healCost) {
          const target = aliveParty().filter((p) => p.hp < p.maxHp).sort((a, b) => a.hp / a.maxHp - b.hp / b.maxHp)[0]
          if (target) {
            const heal = Math.min(healer.hps, target.maxHp - target.hp)
            target.hp += heal; healer.healDone += heal; healer.mana -= healer.healCost
          }
        }
        healer.mana = Math.min(healer.maxMana, healer.mana + healer.manaRegen)
      }
      const oom = aliveParty().find((p) => p.role === "healer" && p.mana < p.healCost)
      if (oom && t % 20 === 0 && rng.chance(0.4)) emit("heal", pickLine("heal", { actor: oom.name, _i: "2", _j: String(rng.int(0, 9)) }) ?? `${oom.name} is out of mana.`,
        { sourceId: oom.id, sourceName: oom.name, sourceSpec: oom.specId, ability: "Mana", result: "Out of mana" })

      // --- Warcraft-Logs-style damage events: "<actor> damages <enemy> with <skill> for <N> Damage" ---
      // RNG-free (indexed by tick) so the seeded sim stream — and thus balance — is unchanged.
      // Attackers = DPS + tank (the tank chips in; healers get their own "heals" events below).
      if (t % 4 === 0) {
        const attackers = aliveParty().filter((p) => p.role !== "healer")
        const targetMob = mobs.find((m) => m.hp > 0)
        if (attackers.length && targetMob) {
          const step = Math.floor(t / 4)
          const a = attackers[step % attackers.length]
          const isCrit = step % 3 === 0
          const amt = Math.round(a.basePower * (8 + (step % 6)) * (isCrit ? 2.4 : 1))
          const spell = pickSkill(a.specId, "dmg")
          emit(isCrit ? "crit" : "normal",
            `${a.name} damages ${targetMob.name} with ${spell.name} for ${amt.toLocaleString()} Damage${isCrit ? " (Critical)" : ""}`,
            { sourceId: a.id, sourceName: a.name, sourceSpec: a.specId, ability: spell.name, skillId: spell.id, amount: amt, target: targetMob.name, result: isCrit ? "Critical Strike" : "Hit" })
        }
      }
      // --- healer heal events: "<healer> heals <ally> with <skill> for <N> Healing" (only when someone is hurt) ---
      if (t % 5 === 0) {
        const healers = aliveParty().filter((p) => p.role === "healer")
        const injured = aliveParty().filter((p) => p.hp < p.maxHp).sort((x, y) => x.hp / x.maxHp - y.hp / y.maxHp)
        if (healers.length && injured.length) {
          const step = Math.floor(t / 5)
          const h = healers[step % healers.length]
          const tgt = injured[0]
          const skill = pickSkill(h.specId, "heal")
          const amt = Math.round(h.hps * (6 + (step % 5)))
          emit("heal", `${h.name} heals ${tgt.name} with ${skill.name} for ${amt.toLocaleString()} Healing`,
            { sourceId: h.id, sourceName: h.name, sourceSpec: h.specId, ability: skill.name, skillId: skill.id, amount: amt, target: tgt.name, result: "Heal" })
        }
      }
      if (rng.chance(0.01)) { const tk = aliveParty().find((p) => p.role === "tank"); if (tk) emit("dodge", pickLine("dodge", { actor: tk.name, _i: String(rng.int(0, 9)), _j: String(rng.int(0, 9)) }) ?? `${tk.name} glances a blow.`, { sourceId: tk.id, sourceName: tk.name, sourceSpec: tk.specId, ability: "Parry", result: "Avoided" }) }

      // --- deaths & wipe ---
      for (const p of party) if (p.downedUntil < 0 && p.hp <= 0) {
        p.downedUntil = t + 10; p.deaths += 1; deathPenalty += 5
        const cause = isBoss ? "boss damage" : (aff.has("bursting") ? "Bursting" : aff.has("spiteful") ? "Spiteful ghost" : "trash damage")
        deaths.push({ tSec: t, t: fmt(t), name: p.name, cause })
        emit("death", pickLine("death", { actor: p.name, _i: String(rng.int(0, 9)), _j: String(rng.int(0, 9)) }) ?? `${p.name} dies (${cause}).`,
          { sourceId: p.id, sourceName: p.name, sourceSpec: p.specId, ability: cause, result: "Death" })
      }
      if (party.every((p) => p.downedUntil >= 0)) { wiped = true; break }
    }

    if (!wiped) emit("good", isBoss ? `${mobs[0].name} falls.` : `Pack cleared. Onward.`)
    if (!wiped && input.stopAfterStage && stageIdx >= input.stopAfterStage) {
      called = true
      emit("flavor", `You call the run after stage ${stageIdx} — bank the loot, take the deplete.`)
    }
  }

  const duration = t + deathPenalty
  let outcome: RunResult["outcome"]
  let keyDelta: number
  if (wiped) { outcome = "wipe"; keyDelta = -1; emit("death", `Party wipe. The run is lost — and so is the loot.`) }
  else if (called) { outcome = "depleted"; keyDelta = -1; emit("flavor", `Run called — depleted, but the loot is banked.`) }
  else if (duration <= timerSec) { outcome = "timed"; keyDelta = 1; emit("good", `Key TIMED with ${fmt(timerSec - duration)} to spare. +1 keystone.`) }
  else { outcome = "depleted"; keyDelta = -1; emit("flavor", `Over time by ${fmt(duration - timerSec)}. Depleted — keystone drops a level.`) }

  // parse: 0..~95 normalized to top theoretical output
  const ticks = Math.max(1, t)
  const theo = party.map((p) => p.basePower * ticks)
  const maxTheo = Math.max(...theo, 1)
  const parse: ParseRow[] = party.map((p, i) => ({
    id: p.id, name: p.name, spec: p.specId,
    actual: Math.round(Math.min(99, (p.dmgDone / maxTheo) * 95)),
    expected: Math.round(Math.min(99, (theo[i] / maxTheo) * 95)),
  })).sort((a, b) => b.actual - a.actual)

  const finalHpPct = party.map((p) => ({ id: p.id, name: p.name, pct: Math.max(0, Math.round((p.hp / p.maxHp) * 100)), dead: p.downedUntil >= 0 }))

  return { seed: input.seed, outcome, durationSec: duration, timerSec, keyDelta, log, parse, deaths, finalHpPct, series, seriesIds, partyMeta }
}
