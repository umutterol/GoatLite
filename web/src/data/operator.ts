/* Phase F — operator-skill helpers (the post-gear-cap power axis).
   Non-sim side: ceiling/profile rolling at recruitment, auto-growth toward the ceiling, Current Operator
   Rating (COR) + fuzzy Potential ★, reveal masks, and the XP curve. All numbers come from tuning.operator.*.
   These run off Math.random (recruitment & progression are NOT part of the deterministic sim).
   The sim-side multiplier resolution lives separately in `web/src/sim/egm/operator.ts`. */
import { content } from "@/content"
import type { Trait } from "@/content"

export type RoleKey = "tank" | "healer" | "dps"
export type SkillMap = Record<string, number>
export type RevealMap = Record<string, boolean>
/** Hidden Potentials: potential-tag id → weight 0..1 (the GDD's tag-weight profile that sets the ceilings). */
export type OperatorProfile = Record<string, number>

interface OperatorTuning {
  scaleMax: number
  startValue: number
  skills: Record<string, { outputPerPt?: number; intakePerPt?: number; clutchOutputPerPt?: number; clutchIntakePerPt?: number; variancePerPt?: number; dangerHpPct?: number; recentDeathSec?: number }>
  ceiling: { base: number; perTagWeight: number; min: number; max: number; byTag: Record<string, string[]> }
  xp: { perPointBase: number; perPointCurve: number; runBase: number; keyMult: number; outcomeMult: Record<string, number>; roleWeight: Record<RoleKey, Record<string, number>> }
  cor: { roleWeight: Record<RoleKey, Record<string, number>> }
  reveal: { atRecruitPct: number; onEarnedTraitPct: number }
  gearCapKey: number; gearCapIlvl: number; aboveCapSkillXp: number
}

export const OP_TUNING = content.tuning.operator as unknown as OperatorTuning
export const OP_SKILL_IDS: string[] = [...content.operatorSkills.keys()]
export const SCALE_MAX = OP_TUNING.scaleMax
export const GEAR_CAP_ILVL = OP_TUNING.gearCapIlvl
export const GEAR_CAP_KEY = OP_TUNING.gearCapKey
export const ABOVE_CAP_SKILL_XP = OP_TUNING.aboveCapSkillXp ?? 0

export const roleKeyOf = (specId: string): RoleKey =>
  (content.specs.get(specId)?.role ?? "DPS").toLowerCase() as RoleKey

const r = () => Math.random()
const clamp = (v: number, lo: number, hi: number) => Math.max(lo, Math.min(hi, v))
const traitOf = (id: string): Trait | undefined => content.traits.get(id)

/** A blank operator block (used as the backfill default + before a real roll). */
export function freshOperatorSkills(): SkillMap {
  return Object.fromEntries(OP_SKILL_IDS.map((id) => [id, OP_TUNING.startValue]))
}
export function zeroSkillMap(): SkillMap {
  return Object.fromEntries(OP_SKILL_IDS.map((id) => [id, 0]))
}
export function falseRevealMap(): RevealMap {
  return Object.fromEntries(OP_SKILL_IDS.map((id) => [id, false]))
}

/* ---- recruitment: roll the hidden Potentials profile, then the ceilings, then current skills ---- */

/** A hidden tag-weight profile: a light random baseline + a lift from the recruit's trait tags + 1–2 signature spikes. */
export function rollProfile(traitIds: string[]): OperatorProfile {
  const tags = [...content.potentials.keys()]
  const traitTags = new Set(traitIds.flatMap((id) => traitOf(id)?.tags ?? []))
  const profile: OperatorProfile = {}
  for (const tag of tags) profile[tag] = clamp(0.15 + r() * 0.35 + (traitTags.has(tag) ? 0.4 : 0), 0, 1)
  // 1–2 "signature" strengths so most bots have a couple of standout ceilings
  const spikes = 1 + (r() < 0.5 ? 1 : 0)
  for (let i = 0; i < spikes; i++) {
    const tag = tags[Math.floor(r() * tags.length)]
    profile[tag] = clamp(profile[tag] + 0.35 + r() * 0.2, 0, 1)
  }
  return profile
}

/** Roll a hidden Ceiling (1..scaleMax) per operator skill from the profile + class baseline + trait growth deltas. */
export function rollCeilings(profile: OperatorProfile, traitIds: string[]): SkillMap {
  const { base, perTagWeight, min, max, byTag } = OP_TUNING.ceiling
  const out: SkillMap = {}
  for (const skill of OP_SKILL_IDS) {
    const tags = byTag[skill] ?? []
    const weights = tags.map((t) => profile[t] ?? 0)
    const avg = weights.length ? weights.reduce((a, b) => a + b, 0) / weights.length : 0
    const peak = weights.length ? Math.max(...weights) : 0
    let val = base + perTagWeight * (0.6 * avg + 0.4 * peak) + (r() * 2 - 1)
    for (const id of traitIds) { const g = traitOf(id)?.growth; if (g?.skill === skill && g.ceilingDelta) val += g.ceilingDelta }
    out[skill] = Math.round(clamp(val, min, max))
  }
  return out
}

/** Roll starting current skills. `veteranFrac` (0..1) pushes a recruit closer to their ceiling (a win-now veteran). */
export function rollSkills(ceilings: SkillMap, veteranFrac = 0): SkillMap {
  const out: SkillMap = {}
  for (const skill of OP_SKILL_IDS) {
    const ceil = ceilings[skill] ?? OP_TUNING.startValue
    const frac = clamp(0.2 + veteranFrac * 0.6 + (r() * 0.2 - 0.1), 0, 1)
    out[skill] = clamp(Math.round(OP_TUNING.startValue + (ceil - OP_TUNING.startValue) * frac), 1, ceil)
  }
  return out
}

/** At recruitment, each skill's ceiling is revealed with probability reveal.atRecruitPct (hidden-but-active per GDD canon). */
export function rollRevealMask(): RevealMap {
  const out: RevealMap = {}
  for (const skill of OP_SKILL_IDS) out[skill] = r() < OP_TUNING.reveal.atRecruitPct
  return out
}

/* ---- ratings ---- */

/** Current Operator Rating: 0..100, role-weighted across the 3 current skills. "How good now." */
export function corOf(skills: SkillMap, role: RoleKey): number {
  const w = OP_TUNING.cor.roleWeight[role] ?? OP_TUNING.cor.roleWeight.dps
  let sum = 0
  for (const skill of OP_SKILL_IDS) sum += (w[skill] ?? 0) * ((skills[skill] ?? 0) / SCALE_MAX)
  return Math.round(100 * sum)
}

/** Potential ★ (0..5, half-star steps) derived from the (mostly hidden) ceilings, role-weighted. "How good they can get." */
export function potentialStars(ceilings: SkillMap, role: RoleKey): number {
  const w = OP_TUNING.cor.roleWeight[role] ?? OP_TUNING.cor.roleWeight.dps
  let sum = 0
  for (const skill of OP_SKILL_IDS) sum += (w[skill] ?? 0) * ((ceilings[skill] ?? 0) / SCALE_MAX)
  return clamp(Math.round(sum * 5 * 2) / 2, 0.5, 5)
}

/* ---- growth (auto toward the ceiling) ---- */

/** XP needed to advance a skill from `level` to `level+1` (rises with level → asymptotic approach to the ceiling). */
export const xpPerPoint = (level: number): number =>
  Math.round(OP_TUNING.xp.perPointBase * Math.pow(OP_TUNING.xp.perPointCurve, level))

/** Skill XP a single run grants (shared by each participant): scales with key level and outcome. */
export function xpFromRun(keyLevel: number, outcome: "timed" | "depleted" | "wipe"): number {
  const { runBase, keyMult, outcomeMult } = OP_TUNING.xp
  return runBase * (outcomeMult[outcome] ?? 0) * (1 + keyLevel * keyMult)
}

/** Grow a member's skills toward their ceilings from `xp`, weighted by role + trait growthMult. Pure (returns new maps). */
export function applyGrowth(
  skills: SkillMap, ceilings: SkillMap, skillXp: SkillMap, role: RoleKey, traitIds: string[], xp: number,
): { skills: SkillMap; skillXp: SkillMap } {
  const roleW = OP_TUNING.xp.roleWeight[role] ?? OP_TUNING.xp.roleWeight.dps
  const growthMult: Record<string, number> = {}
  for (const id of traitIds) { const g = traitOf(id)?.growth; if (g?.growthMult) growthMult[g.skill] = (growthMult[g.skill] ?? 1) * g.growthMult }
  // share of the run's XP per skill (only skills still below their ceiling earn)
  const shares: Record<string, number> = {}
  let total = 0
  for (const skill of OP_SKILL_IDS) {
    const room = (ceilings[skill] ?? 0) - (skills[skill] ?? 0)
    shares[skill] = room > 0 ? (roleW[skill] ?? 1) * (growthMult[skill] ?? 1) : 0
    total += shares[skill]
  }
  const nextSkills: SkillMap = { ...skills }
  const nextXp: SkillMap = { ...skillXp }
  if (total <= 0) return { skills: nextSkills, skillXp: nextXp }
  for (const skill of OP_SKILL_IDS) {
    if (shares[skill] <= 0) continue
    let pool = (nextXp[skill] ?? 0) + xp * (shares[skill] / total)
    let lvl = nextSkills[skill] ?? 0
    const ceil = ceilings[skill] ?? 0
    while (lvl < ceil && pool >= xpPerPoint(lvl)) { pool -= xpPerPoint(lvl); lvl++ }
    nextSkills[skill] = lvl
    nextXp[skill] = lvl >= ceil ? 0 : pool
  }
  return { skills: nextSkills, skillXp: nextXp }
}
