/* Phase F — sim-side operator resolution.
   Turns a member's current operator skills (1..20) + trait `combat` block into the multiplier set that
   buildParty bakes onto the Combatant and the engine/combat read each hit. Deterministic (no RNG) — same
   skills → same mods, so the seeded sim stays reproducible. Per-point numbers come from tuning.operator.*. */
import { content } from "@/content"

interface OpSkillTuning {
  outputPerPt?: number; intakePerPt?: number
  clutchOutputPerPt?: number; clutchIntakePerPt?: number; variancePerPt?: number
  dangerHpPct?: number; recentDeathSec?: number
}
const OP = content.tuning.operator as unknown as { startValue: number; skills: Record<string, OpSkillTuning> }
const S = OP.skills
const START = OP.startValue ?? 4

/** Party-danger thresholds for the Composure clutch (read by the engine loop). */
export const DANGER_HP_FRAC = (S.composure?.dangerHpPct ?? 35) / 100
export const RECENT_DEATH_SEC = S.composure?.recentDeathSec ?? 8

export interface OperatorMods {
  outputMult: number        // static party output multiplier (Execution + Awareness output + trait output)
  clutchOutMult: number     // extra output while the party is in danger (Composure)
  intakeStatic: number      // static damage-taken multiplier (Awareness reduction + trait intake) — uniform
  clutchIntakeMult: number  // further intake reduction while in danger (Composure)
  dodgeBonus: number        // Composure steadiness → flat dodge (the "variance reduction" / fewer unlucky deaths)
  critBonus: number         // trait crit (as a 0..1 fraction)
  hpMult: number            // trait max-HP multiplier
}

const clamp = (v: number, lo: number, hi: number) => Math.max(lo, Math.min(hi, v))

/** Resolve a party member's operator skills + traits into combat multipliers. */
export function resolveOperator(skills: Record<string, number> | undefined, traitIds: string[]): OperatorMods {
  const exec = skills?.execution ?? START
  const awar = skills?.awareness ?? START
  const comp = skills?.composure ?? START
  const e = S.execution ?? {}, a = S.awareness ?? {}, c = S.composure ?? {}

  let traitOut = 0, traitIntake = 0, traitCrit = 0, traitHp = 0
  for (const id of traitIds) {
    const cm = content.traits.get(id)?.combat
    if (!cm) continue
    traitOut += cm.outputPct ?? 0
    traitIntake += cm.intakePct ?? 0
    traitCrit += cm.critPct ?? 0
    traitHp += cm.hpPct ?? 0
  }

  return {
    outputMult: (1 + (exec * (e.outputPerPt ?? 0) + awar * (a.outputPerPt ?? 0)) / 100) * (1 + traitOut / 100),
    clutchOutMult: 1 + (comp * (c.clutchOutputPerPt ?? 0)) / 100,
    // Awareness chosen as a UNIFORM all-incoming reduction (design decision): folded into a single damage-taken multiplier.
    intakeStatic: clamp((1 - (awar * (a.intakePerPt ?? 0)) / 100) * (1 + traitIntake / 100), 0.2, 2),
    clutchIntakeMult: clamp(1 - (comp * (c.clutchIntakePerPt ?? 0)) / 100, 0.3, 1),
    dodgeBonus: (comp * (c.variancePerPt ?? 0)) / 100,
    critBonus: traitCrit / 100,
    hpMult: 1 + traitHp / 100,
  }
}
