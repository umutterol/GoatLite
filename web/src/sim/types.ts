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
  talents?: Record<string, string>   // nodeId → chosen optionId (absent → balanced defaults)
  skills?: Record<string, number>    // Phase F: operator-skill id → current value (1..20); absent → engine uses baseline
  profile?: string
  lootBuffPct?: number               // M.2: transient "+N% output next run" from winning contested loot (absent/0 → no-op)
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

/* ---- I.1: 2D-replay timeline (Phase I) ----
   Additive, deterministic, and TRANSIENT — recomputed from the ticket on open, never persisted.
   Captures the run's spatial-ish structure the text log lacks: real stage/pack timing + per-mob
   spawn/death/HP. No balance impact (pure recording of values the sim already computes). */
export interface ReplayMob {
  id: string                 // stable within a run: `s{stage}m{i}`
  name: string
  band: "front" | "back"
  isBoss: boolean
  stageIdx: number
  spawnSec: number           // whole second the mob appears (stage start)
  deathSec: number | null    // whole second it died; null if it outlived the run (wipe / called)
  hp: number[]               // HP fraction 0..1 per whole second from spawnSec (sparse-safe → forward-fill on read)
}
export interface ReplayStage {
  idx: number
  kind: "trash" | "boss"
  name: string               // pack name / boss name
  startSec: number
  endSec: number             // cleared (or run-end) whole second
  mobIds: string[]
}
export interface ReplayTimeline {
  stages: ReplayStage[]
  mobs: ReplayMob[]
  durationSec: number
}

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
  // per-tick cumulative HEALING done per party member (parallel to seriesIds), for the live HPS meter (J.5)
  healSeries: number[][]
  // per-tick HP fraction (0..1) per party member (parallel to seriesIds), for live health bars
  hpSeries: number[][]
  seriesIds: string[]
  partyMeta: { id: string; name: string; specId: string }[]
  // combat-resurrection state at run end (J.9): charges remaining + seconds until the next charge regenerates
  finalRezCharges: number
  nextRezChargeAtSec: number
  // I.1: 2D-replay timeline (EGM engine only; optional so the legacy engine's RunResult stays valid)
  replay?: ReplayTimeline
}
