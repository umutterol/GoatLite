/* Affix key-level gating (WoW M+ style): affixes don't apply at the low floor — they unlock as the key climbs.
   Tier-2 (rotating: bursting/raging/volcanic/…) unlock first; tier-1 (Fortified/Tyrannical, the boss/trash-HP
   affixes) unlock later. Single source of truth shared by the engine and the UI so they never disagree. */
import { content } from "@/content"

const SIM = content.tuning.sim as Record<string, number>
const TIER2_FROM = SIM.affixTier2FromKey ?? 4
const TIER1_FROM = SIM.affixTier1FromKey ?? 7

/** The key level at which this affix turns on. */
export function affixUnlockKey(affixId: string): number {
  return (content.affixes.get(affixId)?.tier ?? 2) === 1 ? TIER1_FROM : TIER2_FROM
}

/** The affixes actually in effect for a run at `keyLevel` (the rest are still locked). */
export function activeAffixIds(affixIds: string[], keyLevel: number): string[] {
  return affixIds.filter((id) => keyLevel >= affixUnlockKey(id))
}
