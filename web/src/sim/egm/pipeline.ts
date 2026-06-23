/* EGM-model damage pipeline (Phase 1).
   One hit, resolved for real: dodge → crit → type mitigation → damage-taken amplifier.
   Pure functions only (no content import) so the math is unit-testable in isolation. */
import { Rng } from "../rng"

export type DamageType = "Physical" | "Magic"

export interface Defender {
  armour: number          // mitigates Physical (ratio formula for party; school wall for enemies)
  resist: number          // mitigates Magic (ratio formula for party; school wall for enemies)
  dodgeChance: number     // 0..1
  damageTakenPct: number  // additive %, from Mark etc. (Phase 3); 0 by default
  wall?: boolean          // P.0: enemy defenders use the hit-size-INDEPENDENT school wall (a flat off-school tax); party armour keeps the ratio formula
}

export interface Hit {
  amount: number          // pre-mitigation raw damage (already stat-scaled)
  damageType: DamageType
  critChance: number      // 0..1
  critMult: number        // e.g. 2.0
  critable: boolean
}

export interface HitResult {
  dealt: number
  isCrit: boolean
  isDodge: boolean
  mitigated: number       // amount removed by armour/resist
  damageType: DamageType
}

/** Ratio mitigation — the same shape the current tank model uses: big hits punch through, chip is absorbed, cap 90%.
    Used for PARTY armour (enemy→party). 0 defense → 0 (Ashveil byte-identical). */
export function mitigationFraction(defenseValue: number, incoming: number): number {
  if (defenseValue <= 0 || incoming <= 0) return 0
  const ratio = defenseValue / incoming
  return Math.min(0.9, ratio / (ratio + 10))
}

/* P.0 (Phase P) — the damage-SCHOOL wall for ENEMY defenders (party→enemy). Hit-size-INDEPENDENT, unlike the ratio
   formula above: the ratio's `incoming` denominator made big core hits sail through (armour 250 mitigated a 1000-dmg
   hit only ~2.4%), so there was no real school check. This taxes a wrong-school core a flat fraction on EVERY hit. 0
   defense → 0, so Ashveil (armour/resist 0) stays byte-identical. K/CAP are tuned in P.1 against the sweep to land the
   off-school tax at +3–5 keys; they start conservative here (structural change only — P.0 doesn't chase magnitudes). */
// P.5c-M4 note: softening K (tried 200/300) was REVERTED. The Ossuary ceiling is low (~+6) in the timer-bound regime,
// but softening the wall INVERTS the read — physical (mitigated) still out-clears magic because the magic≪physical
// spec imbalance (see M3) is larger than the wall's mitigation gap, so a softer wall just lets strong physical win the
// armour wall (nonsensical). K=155 is the only setting where the read points the right direction (magic ≥ physical,
// weakly). Fully restoring the "bring magic" tax needs a pyromancer single-target buff (a follow-up magic-spec pass),
// not a wall tweak. Left at 155.
export const SCHOOL_WALL_K = 155
export const SCHOOL_WALL_CAP = 0.65
export function schoolWallFraction(defenseValue: number): number {
  if (defenseValue <= 0) return 0
  return Math.min(SCHOOL_WALL_CAP, defenseValue / (defenseValue + SCHOOL_WALL_K))
}

export function resolveHit(hit: Hit, def: Defender, rng: Rng): HitResult {
  if (def.dodgeChance > 0 && rng.chance(def.dodgeChance)) {
    return { dealt: 0, isCrit: false, isDodge: true, mitigated: 0, damageType: hit.damageType }
  }
  let dmg = hit.amount
  let isCrit = false
  if (hit.critable && hit.critChance > 0 && rng.chance(hit.critChance)) { isCrit = true; dmg *= hit.critMult }

  const pre = dmg
  const defense = hit.damageType === "Physical" ? def.armour : def.resist
  dmg *= 1 - (def.wall ? schoolWallFraction(defense) : mitigationFraction(defense, pre))
  if (def.damageTakenPct) dmg *= 1 + def.damageTakenPct / 100

  return { dealt: dmg, isCrit, isDodge: false, mitigated: pre - dmg, damageType: hit.damageType }
}
