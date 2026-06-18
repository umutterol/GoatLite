/* Public types for the GOAT Lite simulation engine. */

export type Aggression = "Safe" | "Balanced" | "Yolo"
export type LogKind = "normal" | "crit" | "dodge" | "death" | "mechanic" | "heal" | "flavor" | "good"

export interface SimPartyMember {
  id: string
  name: string
  specId: string
  ilvl: number
  morale: number
  traitIds: string[]
  profile?: string
}

export interface RunInput {
  dungeonId: string
  keyLevel: number
  affixIds: string[]
  party: SimPartyMember[]          // exactly 5
  tactics: Record<string, number>  // interrupts / positioning / cooldowns / killorder, 0..3
  aggression: Aggression
  seed: number
  stopAfterStage?: number           // "Call the run" — bank loot, take the deplete after this stage
}

export interface LogMeta {
  sourceId?: string; sourceName?: string; sourceSpec?: string
  ability?: string; skillId?: string; amount?: number; target?: string; result?: string
}
export interface LogLine { t: string; tSec: number; kind: LogKind; text: string; meta?: LogMeta }
export interface ParseRow { id: string; name: string; spec: string; actual: number; expected: number }
export interface DeathReport { tSec: number; t: string; name: string; cause: string }

export interface RunResult {
  seed: number
  outcome: "timed" | "depleted" | "wipe"
  durationSec: number
  timerSec: number
  keyDelta: number                 // +1 timed, -1 depleted/wipe
  log: LogLine[]
  parse: ParseRow[]
  deaths: DeathReport[]
  finalHpPct: { id: string; name: string; pct: number; dead: boolean }[]
  // per-tick cumulative damage per party member (parallel to seriesIds), for the live DPS meter
  series: number[][]
  // per-tick HP fraction (0..1) per party member (parallel to seriesIds), for live health bars
  hpSeries: number[][]
  seriesIds: string[]
  partyMeta: { id: string; name: string; specId: string }[]
}
