import { createContext, useContext, useEffect, useMemo, useReducer, type ReactNode } from "react"
import { content } from "@/content"
import { runDungeon } from "@/sim"
import type { RunResult, Aggression } from "@/sim"
import type { Member, Trait, Affix } from "@/data/game"

const SAVE_KEY = "goatlite.save"
const SAVE_VERSION = 2
export const SLOTS = [...content.itemSlots.keys()] // weapon, helm, chest, legs, boots, trinket

export interface GearItem {
  uid: string; baseId: string; name: string; slot: string; specs: string[]; ilvl: number; rarity: string
}

/* ---- gear helpers ---- */
function rarityForKey(key: number): string {
  if (key <= 5) return "Uncommon"
  if (key <= 10) return "Rare"
  if (key <= 15) return key >= 14 ? "Epic" : "Rare"
  return "Epic"
}
const dropIlvl = (key: number) => 100 + 5 * key
function starterGear(specId: string, ilvl: number, memberId: string): Record<string, GearItem> {
  const g: Record<string, GearItem> = {}
  for (const s of SLOTS) g[s] = { uid: `starter-${memberId}-${s}`, baseId: "beta-standard-issue", name: `Worn ${content.itemSlots.get(s)!.name}`, slot: s, specs: [specId], ilvl, rarity: "Common" }
  return g
}
function memberIlvl(gear: Record<string, GearItem>): number {
  const vals = SLOTS.map((s) => gear[s]?.ilvl ?? 105)
  return Math.round(vals.reduce((a, b) => a + b, 0) / SLOTS.length)
}
function makeDrop(baseId: string, key: number, uidSeed: number): GearItem | null {
  const t = content.items.get(baseId)
  if (!t) return null
  return { uid: `${baseId}-${uidSeed.toString(36)}`, baseId, name: t.name, slot: t.slot, specs: t.specs, ilvl: dropIlvl(key), rarity: rarityForKey(key) }
}

/* ---- persistent state ---- */
interface RawMember {
  id: string; name: string; title: string; specId: string
  morale: number; portrait: string; traitIds: string[]; note?: string
  gear: Record<string, GearItem>
}
interface PersistState {
  version: number
  weekNumber: number
  keystone: { dungeonId: string; level: number; best: number; rating: number }
  wallet: { gold: number; emblem: number; shard: number }
  roster: RawMember[]
  stash: GearItem[]
  partyIds: string[]
  history: string[]
}
interface RunConfig { tactics: Record<string, number>; aggression: Aggression }
interface GameState extends PersistState {
  lastResult: RunResult | null
  lastLoot: string | null
  lastConfig: RunConfig | null
}
const DEFAULT_CONFIG: RunConfig = { tactics: { interrupts: 2, positioning: 1, cooldowns: 1, killorder: 2 }, aggression: "Balanced" }

function freshState(): GameState {
  const s = content.save
  return {
    version: SAVE_VERSION,
    weekNumber: s.week.number,
    keystone: { dungeonId: s.keystone.dungeonId, level: s.keystone.level, best: s.keystone.best, rating: s.keystone.rating },
    wallet: { gold: s.wallet.gold ?? 0, emblem: s.wallet.emblem ?? 0, shard: s.wallet.shard ?? 0 },
    roster: s.roster.map((m) => ({ id: m.id, name: m.name, title: m.title, specId: m.specId, morale: m.morale, portrait: m.portrait, traitIds: m.traitIds, note: m.note, gear: starterGear(m.specId, m.ilvl, m.id) })),
    // seed the stash with a few upgrades so gearing is immediately interesting
    stash: [makeDrop("ashveil-cleaver", 14, 101), makeDrop("cuirass-of-interred-kings", 13, 102), makeDrop("icon-of-pale-mercy", 14, 103), makeDrop("pale-mitre-of-ashveil", 13, 104), makeDrop("legplates-of-the-barrow-march", 15, 105)].filter(Boolean) as GearItem[],
    partyIds: s.roster.slice(0, 5).map((m) => m.id),
    history: [],
    lastResult: null, lastLoot: null, lastConfig: null,
  }
}

function loadState(): GameState {
  try {
    const raw = localStorage.getItem(SAVE_KEY)
    if (raw) {
      const p = JSON.parse(raw) as PersistState
      if (p.version === SAVE_VERSION) return { ...freshState(), ...p, lastResult: null, lastLoot: null, lastConfig: null }
      // version mismatch → reset (full stepwise migrator goes here later)
    }
  } catch { /* corrupt save */ }
  return freshState()
}

function weekAffixIds(weekNumber: number): string[] {
  const season = [...content.seasons.values()][0]
  if (!season || !season.affixCalendar.length) return content.save.week.affixes
  const wk = season.affixCalendar[(weekNumber - 1) % season.affixCalendar.length]
  return [wk.tier1, ...wk.tier2]
}

/* ---- actions ---- */
type Action =
  | { type: "SET_PARTY"; ids: string[] }
  | { type: "TOGGLE_PARTY"; id: string }
  | { type: "EQUIP"; memberId: string; uid: string }
  | { type: "RAN_KEY"; result: RunResult; config: RunConfig }
  | { type: "FILE_REPORT" }
  | { type: "ADVANCE_WEEK" }
  | { type: "NEW_GAME" }

const MORALE_DELTA = { timed: 10, depleted: -5, wipe: -20 } as const
const clamp = (v: number, lo: number, hi: number) => Math.max(lo, Math.min(hi, v))

function reducer(state: GameState, action: Action): GameState {
  switch (action.type) {
    case "SET_PARTY":
      return { ...state, partyIds: action.ids.slice(0, 5) }
    case "TOGGLE_PARTY": {
      const has = state.partyIds.includes(action.id)
      if (has) return { ...state, partyIds: state.partyIds.filter((x) => x !== action.id) }
      if (state.partyIds.length >= 5) return state
      return { ...state, partyIds: [...state.partyIds, action.id] }
    }
    case "EQUIP": {
      const item = state.stash.find((i) => i.uid === action.uid)
      const member = state.roster.find((m) => m.id === action.memberId)
      if (!item || !member || !item.specs.includes(member.specId)) return state
      const slot = item.slot
      const old = member.gear[slot]
      const roster = state.roster.map((m) => m.id === member.id ? { ...m, gear: { ...m.gear, [slot]: item } } : m)
      const stash = state.stash.filter((i) => i.uid !== item.uid)
      if (old && old.baseId !== "beta-standard-issue") stash.push(old) // worn starter gear is discarded
      return { ...state, roster, stash }
    }
    case "RAN_KEY":
      return { ...state, lastResult: action.result, lastConfig: action.config, lastLoot: null }
    case "FILE_REPORT": {
      const r = state.lastResult
      if (!r) return state
      const md = MORALE_DELTA[r.outcome]
      const partySet = new Set(state.partyIds)
      const roster = state.roster.map((m) => partySet.has(m.id) ? { ...m, morale: clamp(m.morale + md, 0, 100) } : m)
      const level = clamp(state.keystone.level + r.keyDelta, 2, 40)
      const best = r.outcome === "timed" ? Math.max(state.keystone.best, state.keystone.level) : state.keystone.best
      const rating = r.outcome === "timed"
        ? Math.max(state.keystone.rating, Math.round(state.keystone.level * 12 + (r.timerSec - r.durationSec) / 60 * 6))
        : state.keystone.rating
      const dungeon = content.dungeons.get(state.keystone.dungeonId)
      const lootCount = r.outcome === "timed" ? 2 : r.outcome === "depleted" ? 1 : 0
      const table = dungeon?.lootTable ?? []
      const drops: GearItem[] = []
      let seed = r.seed
      for (let i = 0; i < lootCount && table.length; i++) {
        seed = (seed * 1664525 + 1013904223) >>> 0
        const d = makeDrop(table[seed % table.length], state.keystone.level, seed)
        if (d) drops.push(d)
      }
      const emblem = state.wallet.emblem + (r.outcome === "timed" ? 5 : r.outcome === "depleted" ? 2 : 0)
      const gold = state.wallet.gold + (r.outcome === "wipe" ? 0 : 200 + state.keystone.level * 40)
      const lootSummary = drops.length ? `Looted: ${drops.map((d) => `${d.name} (ilvl ${d.ilvl})`).join(", ")}` : "No loot — the run was lost."
      const histLine = `+${state.keystone.level} ${r.outcome.toUpperCase()} (${Math.floor(r.durationSec / 60)}:${String(Math.floor(r.durationSec % 60)).padStart(2, "0")}, ${r.deaths.length}d) — ${lootSummary}`
      return {
        ...state, roster,
        keystone: { ...state.keystone, level, best, rating },
        wallet: { ...state.wallet, emblem, gold },
        stash: [...drops, ...state.stash],
        history: [histLine, ...state.history].slice(0, 20),
        lastResult: null, lastLoot: lootSummary,
      }
    }
    case "ADVANCE_WEEK":
      return { ...state, weekNumber: state.weekNumber + 1 }
    case "NEW_GAME":
      return freshState()
    default:
      return state
  }
}

/* ---- UI shaping ---- */
function shapeMember(m: RawMember): Member {
  return {
    id: m.id, name: m.name, title: m.title, spec: m.specId, ilvl: memberIlvl(m.gear), morale: m.morale,
    portrait: `/warcraftcn/${m.portrait}.webp`, note: m.note,
    traits: m.traitIds.map((tid) => {
      const t = content.traits.get(tid)!
      return { name: t.name, rarity: t.rarity, kind: t.kind === "start" ? "Start" : "Earned", effect: t.effect } as Trait
    }),
  }
}
const fmtTimer = (s: number) => `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`

interface GameApi {
  members: Member[]
  party: Member[]
  partyIds: string[]
  keystone: { dungeon: string; level: number; timer: string; best: number; rating: number }
  wallet: { gold: number; emblems: number; shards: number }
  weekNumber: number
  weekAffixes: Affix[]
  stash: GearItem[]
  lastResult: RunResult | null
  lastLoot: string | null
  history: string[]
  gearFor: (id: string) => Record<string, GearItem>
  equip: (memberId: string, uid: string) => void
  togglePartyMember: (id: string) => void
  setParty: (ids: string[]) => void
  runKey: (cfg: RunConfig) => RunResult
  rerun: () => RunResult
  fileReport: () => void
  advanceWeek: () => void
  newGame: () => void
}

const GameContext = createContext<GameApi | null>(null)

export function GameProvider({ children }: { children: ReactNode }) {
  const [state, dispatch] = useReducer(reducer, undefined, loadState)

  useEffect(() => {
    const { lastResult: _lr, lastLoot: _ll, lastConfig: _lc, ...persist } = state
    void _lr; void _ll; void _lc
    try { localStorage.setItem(SAVE_KEY, JSON.stringify(persist)) } catch { /* quota */ }
  }, [state])

  const api = useMemo<GameApi>(() => {
    const dungeon = content.dungeons.get(state.keystone.dungeonId)!
    const affIds = weekAffixIds(state.weekNumber)
    const doRun = (cfg: RunConfig): RunResult => {
      const party = state.partyIds
        .map((id) => state.roster.find((m) => m.id === id))
        .filter(Boolean)
        .map((m) => ({ id: m!.id, name: m!.name, specId: m!.specId, ilvl: memberIlvl(m!.gear), morale: m!.morale, traitIds: m!.traitIds }))
      const result = runDungeon({
        dungeonId: state.keystone.dungeonId, keyLevel: state.keystone.level,
        affixIds: affIds, party, tactics: cfg.tactics, aggression: cfg.aggression,
        seed: Math.floor(Math.random() * 0xffffffff),
      })
      dispatch({ type: "RAN_KEY", result, config: cfg })
      return result
    }
    return {
      members: state.roster.map(shapeMember),
      party: state.partyIds.map((id) => state.roster.find((m) => m.id === id)).filter(Boolean).map((m) => shapeMember(m as RawMember)),
      partyIds: state.partyIds,
      keystone: { dungeon: dungeon.name, level: state.keystone.level, timer: fmtTimer(dungeon.timerSeconds), best: state.keystone.best, rating: state.keystone.rating },
      wallet: { gold: state.wallet.gold, emblems: state.wallet.emblem, shards: state.wallet.shard },
      weekNumber: state.weekNumber,
      weekAffixes: affIds.map((id) => content.affixes.get(id)).filter(Boolean) as Affix[],
      stash: state.stash,
      lastResult: state.lastResult,
      lastLoot: state.lastLoot,
      history: state.history,
      gearFor: (id) => state.roster.find((m) => m.id === id)?.gear ?? {},
      equip: (memberId, uid) => dispatch({ type: "EQUIP", memberId, uid }),
      togglePartyMember: (id) => dispatch({ type: "TOGGLE_PARTY", id }),
      setParty: (ids) => dispatch({ type: "SET_PARTY", ids }),
      runKey: doRun,
      rerun: () => doRun(state.lastConfig ?? DEFAULT_CONFIG),
      fileReport: () => dispatch({ type: "FILE_REPORT" }),
      advanceWeek: () => dispatch({ type: "ADVANCE_WEEK" }),
      newGame: () => dispatch({ type: "NEW_GAME" }),
    }
  }, [state])

  useEffect(() => { if (import.meta.env.DEV) (window as unknown as { __game: GameApi }).__game = api }, [api])

  return <GameContext.Provider value={api}>{children}</GameContext.Provider>
}

export function useGame(): GameApi {
  const ctx = useContext(GameContext)
  if (!ctx) throw new Error("useGame must be used within GameProvider")
  return ctx
}
