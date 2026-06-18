// Combat engine cutover (Phase 5b): the app now runs the EGM-model engine (real per-hit damage,
// abilities/passives/specials, front/back bands, affixes/tactics/boss mechanics). The legacy flat-power
// engine is kept exported for rollback/comparison. RunResult shape is identical, so every consumer is unchanged.
export { runDungeonEGM as runDungeon } from "./egm/engine"
export { runDungeon as runDungeonLegacy } from "./engine"
export type { RunInput, RunResult, LogLine, ParseRow, DeathReport, Aggression, LogKind, SimPartyMember } from "./types"

import { content } from "@/content"
import type { RunInput, Aggression } from "./types"

/** Build an Ashveil run input from the current save (party = first 5 of the roster). */
export function defaultRunInput(seed: number, opts?: Partial<RunInput>): RunInput {
  const save = content.save
  return {
    dungeonId: opts?.dungeonId ?? save.keystone.dungeonId,
    keyLevel: opts?.keyLevel ?? save.keystone.level,
    affixIds: opts?.affixIds ?? save.week.affixes,
    party: opts?.party ?? save.roster.slice(0, 5).map((m) => ({
      id: m.id, name: m.name, specId: m.specId, ilvl: m.ilvl, morale: m.morale, traitIds: m.traitIds,
    })),
    tactics: opts?.tactics ?? { interrupts: 3, positioning: 1, cooldowns: 2, killorder: 0 },
    aggression: (opts?.aggression as Aggression) ?? "Yolo",
    stopAfterStage: opts?.stopAfterStage,
    seed,
  }
}
