/* Item stat-block model (item-stats phase). PURE — no React/content deps — so it's reused by the store (drop
   generation + on-load backfill), the sim (power/HP/secondary source, M2/M3), and headless probes.
   Model: ilvl + slot set the budget; RARITY multiplies the WHOLE block (incl. main stat — an Epic out-powers a
   Common at the same ilvl) AND gates how many secondaries roll. Secondaries are RATINGS (the sim converts rating→%
   in M3). Generation is deterministic from the item uid, so an existing save backfills to the same block every load. */
import { Rng, seedFromString } from "@/sim/rng"

export type SecondaryStat = "Haste" | "Crit Chance" | "Crit Damage" | "Versatility"
export interface ItemSecondary { stat: SecondaryStat; value: number }
export interface ItemStats {
  mainStat: number          // → power (via the M2 conversion, role-scaled); label is cosmetic
  mainStatType: string      // "Strength" | "Agility" | "Intellect" (the item's flavour primary)
  stamina: number           // → max HP
  secondaries: ItemSecondary[]
}

export const RARITY_MULT: Record<string, number> = { Common: 1.0, Uncommon: 1.06, Rare: 1.12, Epic: 1.25 }
export const SECONDARY_COUNT: Record<string, number> = { Common: 0, Uncommon: 1, Rare: 2, Epic: 2 }
// per-slot share of the budget (sums to 1 across the 6-slot paper-doll). Weapon is the biggest stat stick.
export const SLOT_WEIGHT: Record<string, number> = { weapon: 0.28, chest: 0.18, legs: 0.18, helm: 0.12, boots: 0.12, trinket: 0.12 }
export const SECONDARY_POOL: SecondaryStat[] = ["Haste", "Crit Chance", "Crit Damage", "Versatility"]
// Display scalars. The sim's power/HP conversion (M2) divides Σ(mainStat) by MAIN_K (and Σ(stamina) by STAM_K) so a
// Common gear-appropriate set reproduces today's ilvl→power/HP — the spike then rides purely on rarity/over-gearing.
export const MAIN_K = 1.8, STAM_K = 2.7, SEC_K = 0.6

/** Deterministic per-item stat block from its uid/slot/ilvl/rarity. `mainStatType` is resolved by the caller
    (it needs the content spec→class map); pass the flavour label only. */
export function rollItemStats(item: { uid: string; slot: string; ilvl: number; rarity: string }, mainStatType: string): ItemStats {
  const w = SLOT_WEIGHT[item.slot] ?? 0.12
  const rm = RARITY_MULT[item.rarity] ?? 1.0
  const rng = new Rng(seedFromString(item.uid))
  const pool = [...SECONDARY_POOL]
  const secondaries: ItemSecondary[] = []
  const n = SECONDARY_COUNT[item.rarity] ?? 0
  for (let i = 0; i < n && pool.length > 0; i++) {
    const [stat] = pool.splice(rng.int(0, pool.length - 1), 1)
    secondaries.push({ stat, value: Math.round(SEC_K * item.ilvl * rm) })
  }
  return {
    mainStat: Math.round(MAIN_K * item.ilvl * w * rm),
    mainStatType,
    stamina: Math.round(STAM_K * item.ilvl * w * rm),
    secondaries,
  }
}

/* ---- gear → sim summary (M2/M3). The sim sources power/HP/armour from `effIlvl` and secondaries from the summed
   ratings; a full Common set reproduces its plain ilvl (no spike), rarity multiplies effIlvl up (the spike). ---- */
export interface SecondaryTotals { haste: number; critChance: number; critDamage: number; versatility: number }
const SEC_KEY: Record<string, keyof SecondaryTotals> = { "Haste": "haste", "Crit Chance": "critChance", "Crit Damage": "critDamage", "Versatility": "versatility" }

/** Effective ilvl = Σ(mainStat)/MAIN_K (rarity + slot weighted). A Common full set → its plain ilvl; an Epic set → ×1.25. */
export function gearEffectiveIlvl(items: Pick<ItemStats, "mainStat">[]): number {
  return items.reduce((a, it) => a + (it?.mainStat ?? 0), 0) / MAIN_K
}
/** Summed secondary RATINGS across equipped gear (rating→% conversion happens in the sim, M3). */
export function gearSecondaries(items: Pick<ItemStats, "secondaries">[]): SecondaryTotals {
  const t: SecondaryTotals = { haste: 0, critChance: 0, critDamage: 0, versatility: 0 }
  for (const it of items) for (const s of it?.secondaries ?? []) { const k = SEC_KEY[s.stat]; if (k) t[k] += s.value }
  return t
}
