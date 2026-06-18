/* EGM-model damage pipeline (Phase 1).
   One hit, resolved for real: dodge → crit → type mitigation → damage-taken amplifier.
   Pure functions only (no content import) so the math is unit-testable in isolation. */
import { Rng } from "../rng"

export type DamageType = "Physical" | "Magic"

export interface Defender {
  armour: number          // mitigates Physical (ratio formula)
  resist: number          // mitigates Magic (ratio formula)
  dodgeChance: number     // 0..1
  damageTakenPct: number  // additive %, from Mark etc. (Phase 3); 0 by default
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

/** Ratio mitigation — the same shape the current tank model uses: big hits punch through, chip is absorbed, cap 90%. */
export function mitigationFraction(defenseValue: number, incoming: number): number {
  if (defenseValue <= 0 || incoming <= 0) return 0
  const ratio = defenseValue / incoming
  return Math.min(0.9, ratio / (ratio + 10))
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
  dmg *= 1 - mitigationFraction(defense, pre)
  if (def.damageTakenPct) dmg *= 1 + def.damageTakenPct / 100

  return { dealt: dmg, isCrit, isDodge: false, mitigated: pre - dmg, damageType: hit.damageType }
}
