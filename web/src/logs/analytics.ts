/* ============================================================
   GOAT LITE · Logs — analytics layer
   Turns the real sim RunResult + content registry into the
   Warcraft Logs / Details! meter / Raider.io view models.
   Damage rows come straight from the sim's per-tick `series`;
   healing / casts / scores are derived deterministically.
   ============================================================ */
import { content } from "@/content"
import { specColor } from "@/data/game"
import type { RunResult } from "@/sim"
import { roleOf, type RoleKey } from "@/state/game-store"

/* ---- formatting ---- */
export function fmt(n: number): string {
  if (n >= 1e9) return (n / 1e9).toFixed(2) + "B"
  if (n >= 1e6) return (n / 1e6).toFixed(1) + "M"
  if (n >= 1e3) return (n / 1e3).toFixed(1) + "k"
  return String(Math.round(n))
}
export const fmtInt = (n: number) => Math.round(n).toLocaleString("en-US")
export function mmss(sec: number): string {
  const m = Math.floor(sec / 60), s = Math.round(sec % 60)
  return m + ":" + String(s).padStart(2, "0")
}

/* ---- deterministic RNG (for derived analytics only — sim stays authoritative) ---- */
function seedFrom(str: string): number { let h = 2166136261; for (let i = 0; i < str.length; i++) { h ^= str.charCodeAt(i); h = Math.imul(h, 16777619) } return h >>> 0 }
function rng(seed: number): () => number { let s = seed >>> 0; return () => { s = (Math.imul(s, 1103515245) + 12345) & 0x7fffffff; return s / 0x7fffffff } }

/* ---- color scales ---- */
export function parseColor(p: number): string {
  if (p >= 100) return "#e5cc80"
  if (p >= 99) return "#e268a8"
  if (p >= 95) return "#ff8000"
  if (p >= 75) return "#a335ee"
  if (p >= 50) return "#0070ff"
  if (p >= 25) return "#1eff00"
  return "#9d9d9d"
}
export const parseLabel = (p: number) =>
  p >= 99 ? "Astounding" : p >= 95 ? "Legendary" : p >= 75 ? "Epic" : p >= 50 ? "Rare" : p >= 25 ? "Uncommon" : "Common"

export function scoreColor(s: number): string {
  if (s >= 3000) return "#e268a8"
  if (s >= 2700) return "#ff8000"
  if (s >= 2400) return "#a335ee"
  if (s >= 2000) return "#0070ff"
  if (s >= 1500) return "#1eff00"
  return "#9d9d9d"
}
// WoW rarity colours (Umut spec): name + icon-border + tooltip-border use these.
const QUALITY_COLOR: Record<string, string> = { Common: "#ffffff", Uncommon: "#1eff00", Rare: "#0070dd", Epic: "#a335ee", Legendary: "#ff8000" }
export const qualityColor = (q: string) => QUALITY_COLOR[q] || "#9d9d9d"

// Canonical morale colour ramp (good ≥70 · amber ≥55 · danger) + its hover explainer — shared by the scouting board,
// roster table, and the New-Run party so the thresholds never drift.
export const moraleColor = (m: number): string => (m >= 70 ? "var(--good)" : m >= 55 ? "var(--amber)" : "var(--danger)")
export const MORALE_TIP = "How willing they are to show up and grind. Wins lift it, wipes tank it — high morale sharpens performance, and below 25 they may walk."

/* ---- member class identity (real specs/classes) ---- */
export interface MC { color: string; subspec: string; klass: string; role: RoleKey }
export function mc(specId: string): MC {
  const sp = content.specs.get(specId)
  const cls = sp ? content.classes.get(sp.classId) : undefined
  return { color: specColor(specId), subspec: sp?.name ?? "?", klass: cls?.name ?? "?", role: roleOf(specId) }
}

/* ---- M+ score (deterministic from item level + guild progress) ---- */
export function memberScore(ilvl: number, best: number): number {
  return Math.round(ilvl * 11 + best * 30 + 180)
}

export const ROLE_ORDER: Record<RoleKey, number> = { tank: 0, healer: 1, dps: 2 }

/* ============================================================
   REPORT — from a real RunResult
   ============================================================ */
export interface DmgRow { id: string; name: string; specId: string; amount: number; dps: number; pct: number; parse: number; casts: number; active: number; hps?: number }
export interface FightView { id: string; name: string; type: "all" | "trash" | "boss"; start: number; end: number; deaths: number }
export interface LogEntry { tSec: number; kind: string; tag: string; color: string; who: string | null; whoName: string | null; text: string; amount: number; ability?: string; skillId?: string; target?: string; result?: string }
export interface ReportView {
  title: string; dungeonId: string; keyLevel: number; affixes: string[]
  outcome: string; upgradeLabel: string; outcomeColor: string
  time: string; par: string; deaths: number; rating: number; deltaRating: number
  duration: number
  fights: FightView[]
  damage: DmgRow[]; dmgTotal: number
  healing: DmgRow[]; healTotal: number
  log: LogEntry[]
  partyIds: string[]
}

const LOG_KIND: Record<string, { tag: string; color: string }> = {
  crit: { tag: "CRIT", color: "#f0a52e" },
  dodge: { tag: "DODGE", color: "#56a8ff" },
  death: { tag: "DEATH", color: "#e0444e" },
  mechanic: { tag: "MECH", color: "#a98ce0" },
  heal: { tag: "HEAL", color: "#4ec77b" },
  good: { tag: "KILL", color: "#2bb6a4" },
  flavor: { tag: "PULL", color: "#9aa0ad" },
  normal: { tag: "", color: "#8b8e99" },
}

/** Build the WCL fight rail from the dungeon's 8 stages, weighting boss windows longer. */
function buildFights(dungeonId: string, duration: number, deaths: { tSec: number }[]): FightView[] {
  const dungeon = content.dungeons.get(dungeonId)
  const slots = dungeon?.slots ?? []
  const weights = slots.map((s) => (s.kind === "boss" ? 1.5 : 1.0))
  const totalW = weights.reduce((a, b) => a + b, 0) || 1
  let t = 0
  const stages: FightView[] = slots.map((s, i) => {
    const start = t
    const end = i === slots.length - 1 ? duration : Math.round(start + (weights[i] / totalW) * duration)
    t = end
    const name = s.kind === "boss" && s.boss
      ? (content.enemies.get(s.boss)?.name ?? `Boss ${s.stage}`)
      : packNameFor(s.packTags ?? [], i)
    const d = deaths.filter((x) => x.tSec >= start && x.tSec < end).length
    return { id: "f" + s.stage, name, type: s.kind, start, end, deaths: d }
  })
  return [{ id: "all", name: "All Pulls", type: "all", start: 0, end: duration, deaths: deaths.length }, ...stages]
}
function packNameFor(tags: string[], i: number): string {
  const matches = [...content.packs.values()].filter((p) => p.tags.some((t) => tags.includes(t)))
  if (matches.length) return matches[i % matches.length].name
  return `Trash Pull ${Math.ceil((i + 1) / 2)}`
}

/** Per-member damage totals straight from the sim's cumulative series, sliced to a window. */
function damageWindow(result: RunResult, start: number, end: number): DmgRow[] {
  const ids = result.seriesIds
  const last = result.series.length - 1
  const i0 = Math.max(0, Math.min(last, start))
  const i1 = Math.max(0, Math.min(last, end - 1))
  const dur = Math.max(1, end - start)
  const parseById = new Map(result.parse.map((p) => [p.id, p.actual]))
  const rows: DmgRow[] = ids.map((id, col) => {
    const a0 = result.series[i0]?.[col] ?? 0
    const a1 = result.series[i1]?.[col] ?? 0
    const amount = Math.max(0, a1 - a0)
    const meta = result.partyMeta.find((m) => m.id === id)
    const specId = meta?.specId ?? "berserker"
    const r = rng(seedFrom("casts-" + id))
    const role = roleOf(specId)
    const casts = Math.round((dur / (role === "healer" ? 3 : role === "tank" ? 2.6 : 2.1)) * (0.85 + r() * 0.3))
    const active = 86 + Math.round(r() * 13)
    return { id, name: meta?.name ?? id, specId, amount, dps: Math.round(amount / dur), pct: 0, parse: parseById.get(id) ?? 50, casts, active }
  })
  const total = rows.reduce((s, d) => s + d.amount, 0) || 1
  rows.forEach((d) => (d.pct = (d.amount / total) * 100))
  rows.sort((a, b) => b.amount - a.amount)
  return rows
}

/** Per-member healing totals straight from the sim's cumulative healSeries, sliced to a window (J.5 — real heal data). */
function healingWindow(result: RunResult, start: number, end: number): DmgRow[] {
  const ids = result.seriesIds
  const heal = result.healSeries ?? []
  const last = Math.max(0, heal.length - 1)
  const i0 = Math.max(0, Math.min(last, start))
  const i1 = Math.max(0, Math.min(last, end - 1))
  const dur = Math.max(1, end - start)
  const rows: DmgRow[] = ids.map((id, col) => {
    const a0 = heal[i0]?.[col] ?? 0
    const a1 = heal[i1]?.[col] ?? 0
    const amount = Math.max(0, a1 - a0)
    const meta = result.partyMeta.find((m) => m.id === id)
    const specId = meta?.specId ?? "berserker"
    return { id, name: meta?.name ?? id, specId, amount, dps: 0, hps: Math.round(amount / dur), pct: 0, parse: 50, casts: 0, active: 0 }
  })
  const total = rows.reduce((s, d) => s + d.amount, 0) || 1
  rows.forEach((d) => (d.pct = (d.amount / total) * 100))
  rows.sort((a, b) => b.amount - a.amount)
  return rows
}

export function buildReport(
  result: RunResult,
  keystone: { dungeonId: string; dungeon: string; level: number; rating: number },
  affixNames: string[],
): ReportView {
  const duration = Math.round(result.durationSec)
  const fights = buildFights(keystone.dungeonId, duration, result.deaths)
  const damage = damageWindow(result, 0, duration)
  const dmgTotal = damage.reduce((s, d) => s + d.amount, 0)
  const healing = healingWindow(result, 0, duration)
  const healTotal = healing.reduce((s, h) => s + h.amount, 0)
  const log: LogEntry[] = result.log.map((e) => {
    const k = LOG_KIND[e.kind] ?? LOG_KIND.normal
    return { tSec: e.tSec, kind: e.kind, tag: k.tag, color: k.color, who: e.meta?.sourceId ?? null, whoName: e.meta?.sourceName ?? null, text: e.text, amount: e.meta?.amount ?? 0, ability: e.meta?.ability, skillId: e.meta?.skillId, target: e.meta?.target, result: e.meta?.result }
  })
  const upgrade = result.outcome === "timed"
    ? (() => { const f = (result.timerSec - result.durationSec) / result.timerSec; return f >= 0.4 ? "+3" : f >= 0.2 ? "+2" : "+1" })()
    : ""
  const outcome = result.outcome === "timed" ? "TIMED" : result.outcome === "depleted" ? "DEPLETED" : "WIPE"
  return {
    title: keystone.dungeon, dungeonId: keystone.dungeonId, keyLevel: keystone.level, affixes: affixNames,
    outcome, upgradeLabel: upgrade, outcomeColor: result.outcome === "timed" ? "var(--good)" : result.outcome === "depleted" ? "var(--amber)" : "var(--danger)",
    time: mmss(duration), par: mmss(result.timerSec), deaths: result.deaths.length,
    rating: keystone.rating, deltaRating: result.outcome === "timed" ? Math.max(1, result.keyDelta) : 0,
    duration,
    fights, damage, dmgTotal, healing, healTotal, log, partyIds: result.seriesIds,
  }
}

/** Re-scope the damage table to a selected pull (real series slice). */
export function damageForFight(result: RunResult, fights: FightView[], fightId: string): { rows: DmgRow[]; total: number; dur: number; fight: FightView } {
  const f = fights.find((x) => x.id === fightId) ?? fights[0]
  const rows = damageWindow(result, f.start, f.end)
  const total = rows.reduce((s, d) => s + d.amount, 0)
  return { rows, total, dur: Math.max(1, f.end - f.start), fight: f }
}

/* ---- playback (clock-driven) views: cumulative up to the current second ---- */
export function liveDamage(result: RunResult, clockSec: number): { rows: DmgRow[]; total: number; dur: number } {
  const dur = Math.max(1, Math.floor(clockSec))
  const idx = Math.max(0, Math.min(result.series.length - 1, Math.floor(clockSec)))
  const rows = damageWindow(result, 0, idx + 1)
  const total = rows.reduce((s, d) => s + d.amount, 0)
  return { rows, total, dur }
}
export function liveHealing(result: RunResult, clockSec: number): { rows: DmgRow[]; total: number; dur: number } {
  const dur = Math.max(1, Math.floor(clockSec))
  const idx = Math.max(0, Math.min(result.healSeries.length - 1, Math.floor(clockSec)))
  const rows = healingWindow(result, 0, idx + 1)
  const total = rows.reduce((s, d) => s + d.amount, 0)
  return { rows, total, dur }
}
/** HP fraction (0..1) per member id at the given playback second. */
export function hpAt(result: RunResult, clockSec: number): Record<string, number> {
  const idx = Math.max(0, Math.min(result.hpSeries.length - 1, Math.floor(clockSec)))
  let row = result.hpSeries[idx]
  for (let i = idx; i >= 0 && !row; i--) row = result.hpSeries[i]
  const out: Record<string, number> = {}
  result.seriesIds.forEach((id, c) => { out[id] = row ? (row[c] ?? 1) : 1 })
  return out
}

/* ============================================================
   CHARACTER — best runs (real authored dungeons) + equipment (real gear)
   ============================================================ */
export interface RunRow { dungeon: string; short: string; key: number; time: string; upgrades: number; score: number; timed: boolean }
export function bestRunsFor(memberIlvl: number, best: number, seasonDungeonIds: string[]): RunRow[] {
  const r = rng(seedFrom("runs-" + memberIlvl + "-" + best))
  return seasonDungeonIds.map((id) => {
    const d = content.dungeons.get(id)
    const name = d?.name ?? id
    const timer = d?.timerSeconds ?? 1500
    const key = Math.max(2, best || 2)
    const timeFrac = 0.7 + r() * 0.35
    const sec = Math.round(timer * Math.min(timeFrac, 1.15))
    const upgrades = timeFrac <= 0.62 ? 3 : timeFrac <= 0.8 ? 2 : timeFrac < 1.0 ? 1 : 0
    const score = Math.round((150 + key * 8 + upgrades * 5) * (0.95 + r() * 0.1))
    return { dungeon: name, short: shortOf(name), key, time: mmss(sec), upgrades, score, timed: upgrades > 0 }
  })
}
const shortOf = (n: string) => n.replace(/^the\s+/i, "").split(/\s+/)[0].slice(0, 3).toUpperCase()
