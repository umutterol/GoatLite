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
  dodgeChance: number; damageTakenPct: number
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
  // Phase F operator layer (party only; enemies carry neutral 1s)
  intakeMult: number          // live damage-taken multiplier — Awareness (static) × Composure clutch; refreshed per step by the engine
  opOutputMult: number        // static party output multiplier (Execution + Awareness output + trait output)
  opClutchOutMult: number     // output multiplier applied on top while the party is in danger (Composure)
  opIntakeStatic: number      // the static part of intakeMult (Awareness reduction + trait intake)
  opClutchIntakeMult: number  // further intake multiplier applied while in danger (Composure)
}

/** A talent's outgoing-damage modifier, optionally gated by a condition. */
export interface TalentDmg { dmgPct: number; onlyIf?: { type: string; value: number } }

/** Resolve a member's chosen talents → maxHp mult + damage modifiers + flat intake/crit deltas (defaults to balanced). */
function resolveTalents(chosen: Record<string, string> | undefined): { hpMult: number; dmg: TalentDmg[]; intakePct: number; critPct: number } {
  let hpMult = 1, intakePct = 0, critPct = 0
  const dmg: TalentDmg[] = []
  for (const node of content.talents.values()) {
    // chosen → default → first option (matches the Character-sheet picker's fallback exactly)
    const opt = (chosen?.[node.id] && node.options.find((o) => o.id === chosen[node.id])) || node.options.find((o) => o.default) || node.options[0]
    const eff = opt?.effects
    if (!eff) continue
    if (eff.maxHpPct) hpMult *= 1 + eff.maxHpPct / 100
    if (eff.dmgPct) dmg.push({ dmgPct: eff.dmgPct, onlyIf: eff.onlyIf })
    if (eff.intakePct) intakePct += eff.intakePct
    if (eff.critPct) critPct += eff.critPct
  }
  return { hpMult, dmg, intakePct, critPct }
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
    const power = c.powerPerIlvl * p.ilvl * moraleMult(p.morale) * aggressionOutput
    const haste = 0 // Phase 1: no haste source yet (gear secondaries land later)
    const attackInterval = ATTACK_INTERVAL_BASE / (1 + haste / 100)
    const tal = resolveTalents(p.talents)
    const op = resolveOperator(p.skills, p.traitIds)   // Phase F: operator skills + trait combat → multipliers
    // H.3: talent intakePct folds into the operator (uniform) intake channel
    const intakeStatic = Math.max(0.2, Math.min(2, op.intakeStatic * (1 + tal.intakePct / 100)))
    const maxHp = c.hpPerIlvl * p.ilvl * tal.hpMult * op.hpMult
    const abilities = [...content.playerAbilities.values()].filter((a) => a.specId === p.specId && a.trigger === "active")
    const passive = [...content.playerAbilities.values()].find((a) => a.specId === p.specId && a.trigger === "passive") ?? null
    return {
      id: p.id, name: p.name, specId: p.specId, team: "party",
      role, position: spec.position, profile: p.profile ?? spec.defaultProfile,
      maxHp, hp: maxHp, shield: 0, shieldExpiresAt: 0,
      power,
      attackPower: power * attackInterval,   // so pre-crit DPS ≈ power, matching the current balance
      attackInterval,
      damageType: autoDamageType(spec.classId, p.specId),
      armour: (c.armourPerIlvl ?? 0) * p.ilvl, resist: 0,
      critChance: Math.max(0, baseCrit + dialCrit + op.critBonus + tal.critPct / 100), critMult,
      dodgeChance: op.dodgeBonus, damageTakenPct: 0,
      mana: c.mana ?? 0, maxMana: c.mana ?? 0, healCost: c.healCost ?? 0,
      manaRegen: c.manaRegenPerSec ?? 0, hps: (c.hpsPerIlvl ?? 0) * p.ilvl,
      nextActionAt: 0, downedUntil: -1, dmgDone: 0, healDone: 0, deaths: 0, isBoss: false,
      abilities, passive, cooldowns: {}, statuses: [], resources: {}, hitSinceAction: false, lastActionAt: 0,
      emergencyHealed: false, guards: {}, talents: tal.dmg,
      intakeMult: intakeStatic, opOutputMult: op.outputMult, opClutchOutMult: op.clutchOutMult,
      opIntakeStatic: intakeStatic, opClutchIntakeMult: op.clutchIntakeMult,
    }
  })
}

export function makeEnemy(opts: {
  name: string; baseHp: number; baseDamage: number; isBoss: boolean
  keyScale: number; affMult: number; band?: "front" | "back"
  armour?: number; resist?: number   // C.8: damage-school defense (authored base; scaled by keyScale to track gear)
}): Combatant {
  const hp = opts.baseHp * HP_UNIT * opts.keyScale * opts.affMult
  return {
    id: "", name: opts.name, specId: "", team: "enemy",
    role: "dps", position: opts.band === "back" ? "Back" : "Front", profile: opts.band === "back" ? "caster" : "melee",
    maxHp: hp, hp, shield: 0, shieldExpiresAt: 0,
    power: 0,
    attackPower: opts.baseDamage * opts.keyScale * opts.affMult * DMG_UNIT,
    attackInterval: ENEMY_ATTACK_INTERVAL,
    damageType: "Physical",
    // C.8: armour mitigates the party's Physical, resist their Magic (ratio formula). Default 0 = unmitigated
    // (Ashveil unchanged). Scaled by keyScale so the mitigation fraction roughly tracks gear-appropriate hit sizes.
    armour: (opts.armour ?? 0) * opts.keyScale, resist: (opts.resist ?? 0) * opts.keyScale,
    critChance: 0, critMult: 1, dodgeChance: 0, damageTakenPct: 0,
    mana: 0, maxMana: 0, healCost: 0, manaRegen: 0, hps: 0,
    nextActionAt: 0, downedUntil: -1, dmgDone: 0, healDone: 0, deaths: 0, isBoss: opts.isBoss,
    abilities: [], passive: null, cooldowns: {}, statuses: [], resources: {}, hitSinceAction: false, lastActionAt: 0,
    emergencyHealed: false, guards: {}, talents: [],
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
  let power = 0, maxhp = 0, armour = 0, resist = 0, crit = 0, critmult = 0, haste = 0, vers = 0, dtaken = 0
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
    damageTakenPct: dtaken,
  }
}

/** Apply damage to a combatant — Phase F operator intake (party only) reduces it first, then shield soaks, then life.
    `bypassIntake` skips the operator multiplier for SELF-INFLICTED costs (ability HP costs aren't "incoming damage"). */
export function dealDamage(target: Combatant, amount: number, opts?: { bypassIntake?: boolean }): void {
  // Uniform Awareness/Composure intake: applies to ALL external incoming (auto-attacks, affix ticks, mechanics, redirects).
  let amt = target.team === "party" && !opts?.bypassIntake ? amount * target.intakeMult : amount
  if (target.shield > 0) { const soak = Math.min(target.shield, amt); target.shield -= soak; amt -= soak }
  target.hp -= amt
}
