import { createContext, useContext, useEffect, useMemo, useReducer, type ReactNode } from "react"
import { content } from "@/content"
import { runDungeon } from "@/sim"
import type { RunResult, Aggression, SimPartyMember } from "@/sim"
import type { Member, Trait, Affix, KeyView } from "@/data/game"
import {
  freshOperatorSkills, zeroSkillMap, falseRevealMap, rollRevealMask, rollProfile, rollCeilings, rollSkills,
  corOf, potentialStars, applyGrowth, xpFromRun, GEAR_CAP_ILVL, GEAR_CAP_KEY, ABOVE_CAP_SKILL_XP,
  type SkillMap, type RevealMap, type OperatorProfile,
} from "@/data/operator"

const SAVE_KEY = "goatlite.save"
const SAVE_VERSION = 5 // bumped: per-member operator skills + ceilings + Potentials profile (Phase F)
export const SLOTS = [...content.itemSlots.keys()] // weapon, helm, chest, legs, boots, trinket

export type RoleKey = "tank" | "healer" | "dps"
export type Phase = "create" | "recruit" | "playing"

export interface GearItem {
  uid: string; baseId: string; name: string; slot: string; specs: string[]; ilvl: number; rarity: string
}
export interface GuildInfo { name: string; crest: string; glyph: string; motto: string }
export interface Recruit {
  id: string; name: string; specId: string; role: RoleKey; ilvl: number; score: number; morale: number
  traitId: string; traitName: string; traitGood: boolean; traitFlavor: string; cost: number
  // Phase F operator layer (rolled at generation; copied onto the member on sign)
  skills: SkillMap; ceilings: SkillMap; revealed: RevealMap; potentialProfile: OperatorProfile
  cor: number; stars: number   // derived display numbers: Current Operator Rating + Potential ★
}
export interface UpgradeCandidate { memberId: string; delta: number; currentIlvl: number }
export interface LootDrop extends GearItem {
  primaryStat: string; upgradeFor: string | null; upgradeAmt: number
  upgrades: UpgradeCandidate[]   // J.6: every spec-eligible party member + their current ilvl in this slot (delta>0 = upgrade)
}
export interface KeystoneChange {
  prevLevel: number; prevDungeon: string; prevTime: string; prevPar: string
  outcome: "timed" | "depleted" | "wipe"; underBy: number; upgrade: number
  level: number; dungeon: string; dungeonShort: string; timer: string; affixes: string[]
}

/* ---- guild feed (Phase M.1): the always-visible meta-layer notification stream ----
   System notifications only here (neutral game-voice, zero comedy). In-character barks land in M.3/M.4. */
export type FeedKind = "system" | "run" | "loot" | "keystone" | "operator" | "morale" | "recruit"
export type FeedTone = "neutral" | "good" | "bad" | "warn"
export interface FeedEntry {
  id: string; week: number; kind: FeedKind; tone: FeedTone; text: string
  memberId?: string                       // click → that member's character sheet
  icon?: { kind: string; id: string }     // optional GameIcon (kind is an IconKind; kept loose to avoid a UI import here)
}
type FeedPartial = Omit<FeedEntry, "id" | "week">

/* ---- gear helpers ---- */
function rarityForKey(key: number): string {
  if (key <= 5) return "Uncommon"
  if (key <= 10) return "Rare"
  if (key <= 15) return key >= 14 ? "Epic" : "Rare"
  return "Epic"
}
// Drops track the key: gear-appropriate ilvl for a key is ~108+4·key, so a drop lands a few above that —
// a real upgrade that nudges you toward the next key's requirement (timing K gears you to attempt K+1).
// Phase F: HARD gear cap — drops stop scaling at the key-12 value (ilvl 160). Past the cap, power hands off
// to the operator-skill layer (see CONFIRM_LOOT: above-cap keys grant bonus operator XP instead of higher ilvl).
const dropIlvl = (key: number) => Math.min(112 + 4 * key, GEAR_CAP_ILVL)
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
export const roleOf = (specId: string): RoleKey => (content.specs.get(specId)?.role ?? "DPS").toLowerCase() as RoleKey
export const dShort = (n: string) => n.replace(/^the\s+/i, "").split(/\s+/)[0].slice(0, 3).toUpperCase()

/* ---- per-member keystones ---- */
export interface MemberKey { dungeonId: string; level: number; best: number; rating: number }
const DUNGEON_IDS = [...content.dungeons.keys()]
/** A fresh +2 key on a random dungeon (only Ashveil is authored today, so all keys are Ashveil +2 for now). */
function freshKey(): MemberKey { return { dungeonId: pick(DUNGEON_IDS), level: 2, best: 0, rating: 0 } }
const fmtMMSS = (s: number) => `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`
/** Expand a stored key into the display shape the UI consumes. */
function shapeKey(k: MemberKey): KeyView {
  const d = content.dungeons.get(k.dungeonId) ?? [...content.dungeons.values()][0]
  return { dungeonId: k.dungeonId, dungeon: d.name, dungeonShort: dShort(d.name), level: k.level, timer: fmtMMSS(d.timerSeconds), timerSec: d.timerSeconds, best: k.best, rating: k.rating }
}
const PRIMARY_BY_CLASS: Record<string, string> = { warrior: "Strength", paladin: "Strength", rogue: "Agility", mage: "Intellect", sage: "Intellect" }
function primaryStatOf(specId: string): string {
  const cls = content.specs.get(specId)?.classId
  return (cls && PRIMARY_BY_CLASS[cls]) || "Versatility"
}

/* ---- recruitment generation ---- */
const SPECS_BY_ROLE: Record<RoleKey, string[]> = {
  tank: ["guardian", "crusader", "mystic"],
  healer: ["cleric", "lifebinder"],
  dps: ["berserker", "assassin", "bard", "pyromancer", "arcanist"],
}
const START_TRAITS = [...content.traits.values()].filter((t) => t.kind === "start")
const ALL_TRAITS = [...content.traits.values()]
const NAME_POOL = content.recruitment.namePool
const PORTRAITS = content.recruitment.portraitPool
const rnd = (n: number) => Math.floor(Math.random() * n)
const pick = <T,>(arr: T[]): T => arr[rnd(arr.length)]

function makeRecruit(role: RoleKey, bestIlvl: number, used: Set<string>): Recruit {
  const specId = pick(SPECS_BY_ROLE[role])
  // name (avoid collisions where possible)
  let name = pick(NAME_POOL), guard = 0
  while (used.has(name) && guard++ < 12) name = pick(NAME_POOL)
  if (used.has(name)) name = name + " " + (used.size + 1)
  used.add(name)

  const isDud = Math.random() < 0.32
  const floor = Math.max(100, Math.round(bestIlvl * 0.6))
  const ceil = Math.max(floor + 8, bestIlvl)
  const ilvl = isDud ? floor + rnd(6) : floor + Math.round((ceil - floor) * (0.55 + Math.random() * 0.45))
  const score = Math.round(ilvl * 11 + (isDud ? rnd(200) : 350 + rnd(700)))
  const morale = isDud ? 30 + rnd(26) : 62 + rnd(34)
  const cost = Math.max(20, Math.round((score / 55 + ilvl / 9) / 5) * 5)

  const pool = (isDud ? START_TRAITS.filter((t) => t.netBudget < 6) : START_TRAITS.filter((t) => t.netBudget >= 0))
  const trait = (pool.length ? pick(pool) : (START_TRAITS.length ? pick(START_TRAITS) : pick(ALL_TRAITS)))

  // Phase F: roll the hidden Potentials profile → operator ceilings → starting skills (scouting bet).
  // Duds plateau early (low veteran-frac → low current skills); standouts start closer to their ceiling.
  const profile = rollProfile([trait.id])
  const ceilings = rollCeilings(profile, [trait.id])
  const veteranFrac = isDud ? 0.1 + Math.random() * 0.2 : 0.35 + Math.random() * 0.45
  const skills = rollSkills(ceilings, veteranFrac)
  const revealed = rollRevealMask()
  return {
    id: "rec-" + Math.random().toString(36).slice(2, 9),
    name, specId, role, ilvl, score, morale,
    traitId: trait.id, traitName: trait.name, traitGood: !isDud, traitFlavor: trait.effect, cost,
    skills, ceilings, revealed, potentialProfile: profile,
    cor: corOf(skills, role), stars: potentialStars(ceilings, role),
  }
}
function generateRecruits(bestIlvl: number, opts: { balanced?: boolean } = {}): Recruit[] {
  const used = new Set<string>()
  const out: Recruit[] = []
  if (opts.balanced) {
    // interleaved so the top of the board reads as a fieldable comp (1T·1H·3D), not a wall of tanks
    const order: RoleKey[] = ["tank", "healer", "dps", "dps", "dps", "tank", "healer", "dps", "dps", "dps", "tank", "healer"]
    for (const role of order) out.push(makeRecruit(role, bestIlvl, used))
  } else {
    out.push(makeRecruit("tank", bestIlvl, used))
    out.push(makeRecruit("healer", bestIlvl, used))
    for (let i = 0; i < 7; i++) out.push(makeRecruit(pick(["tank", "healer", "dps", "dps", "dps"]) as RoleKey, bestIlvl, used))
  }
  return out
}

/* ---- persistent state ---- */
interface RawMember {
  id: string; name: string; title: string; specId: string
  morale: number; portrait: string; traitIds: string[]; note?: string
  gear: Record<string, GearItem>
  key: MemberKey                  // each member holds & levels their own keystone
  talents: Record<string, string> // B.7: nodeId → chosen optionId (empty → balanced defaults)
  // Phase F operator layer: current skills (1..20) grow toward hidden ceilings via skillXp; revealed = ceiling known
  skills: SkillMap
  ceilings: SkillMap
  skillXp: SkillMap
  revealed: RevealMap
  potentialProfile: OperatorProfile // hidden tag-weights (set the ceilings; bias earned-trait rolls in D.1)
  lootBuffPct: number               // M.2: "+N% output next run" from winning contested loot (consumed after the run)
}
interface PersistState {
  version: number
  phase: Phase
  guild: GuildInfo | null
  weekNumber: number
  selectedKeyOwnerId: string | null   // whose key the next run will use (auto-locked into the party)
  wallet: { gold: number; emblem: number; shard: number }
  roster: RawMember[]
  stash: GearItem[]
  partyIds: string[]
  recruits: Recruit[]
  signedRecruitIds: string[]
  history: RunTicket[]   // replayable record of past runs, newest first (cap 50)
  feed: FeedEntry[]      // M.1: guild-feed notification stream, oldest→newest (cap 200)
  feedSeq: number        // monotonic id counter for feed entries (stable React keys)
}
interface RunConfig { tactics: Record<string, number>; aggression: Aggression }
/** A replayable record of one run: enough to deterministically re-simulate it + a summary for the list. */
export interface RunTicket {
  id: string; when: number; ownerId: string; ownerName: string
  // re-sim inputs (RunInput)
  seed: number; dungeonId: string; keyLevel: number; affixIds: string[]
  party: SimPartyMember[]; tactics: Record<string, number>; aggression: Aggression
  // summary (header + list row, no re-sim needed)
  dungeonName: string; outcome: "timed" | "depleted" | "wipe"
  durationSec: number; timerSec: number; deaths: number; rating: number; affixNames: string[]
}
interface GameState extends PersistState {
  lastResult: RunResult | null
  lastLoot: string | null
  lastConfig: RunConfig | null
  pendingLoot: LootDrop[] | null
  lastKeystoneChange: KeystoneChange | null
  lastRunOwnerId: string | null       // which member's key the last run used (for loot/progression)
  lastRunKey: MemberKey | null        // snapshot of that key as it was at run time (for the report header)
  autoplaySeed: number | null         // the just-run's seed — its Report auto-plays once, then this is consumed
}
const DEFAULT_CONFIG: RunConfig = { tactics: { interrupts: 2, positioning: 1, cooldowns: 1, killorder: 2 }, aggression: "Balanced" }
const TRANSIENT = { lastResult: null, lastLoot: null, lastConfig: null, pendingLoot: null, lastKeystoneChange: null, lastRunOwnerId: null, lastRunKey: null, autoplaySeed: null } as const

function freshState(): GameState {
  return {
    version: SAVE_VERSION,
    phase: "create",
    guild: null,
    weekNumber: 1,
    selectedKeyOwnerId: null,
    wallet: { gold: 0, emblem: 600, shard: 0 }, // recruiting budget for the opening draft
    roster: [],
    stash: [],
    partyIds: [],
    recruits: generateRecruits(128, { balanced: true }), // opening draft: geared to make a sensible +2 comp timeable
    signedRecruitIds: [],
    history: [],
    feed: [],
    feedSeq: 0,
    ...TRANSIENT,
  }
}

function loadState(): GameState {
  try {
    const raw = localStorage.getItem(SAVE_KEY)
    if (raw) {
      const p = JSON.parse(raw) as PersistState
      if (p.version === SAVE_VERSION) {
        const merged = { ...freshState(), ...p, ...TRANSIENT }
        // defensive: guarantee every member has a key + talents + the Phase F operator block so engine/UI never deref undefined
        merged.roster = merged.roster.map((m) => ({
          ...m, key: m.key ?? freshKey(), talents: m.talents ?? {},
          skills: m.skills ?? freshOperatorSkills(), ceilings: m.ceilings ?? freshOperatorSkills(),
          skillXp: m.skillXp ?? zeroSkillMap(), revealed: m.revealed ?? falseRevealMap(), potentialProfile: m.potentialProfile ?? {},
          lootBuffPct: m.lootBuffPct ?? 0,   // M.2: additive field, sanitized on load (no SAVE_VERSION bump → no roster wipe)
        }))
        // history changed shape (string[] → RunTicket[]) — drop any legacy/malformed entries so replay can't crash
        merged.history = ((merged.history as unknown[]) ?? []).filter((t): t is RunTicket =>
          !!t && typeof t === "object" && typeof (t as RunTicket).seed === "number" && Array.isArray((t as RunTicket).party) && typeof (t as RunTicket).aggression === "string")
        // M.1: guild feed is additive (no SAVE_VERSION bump) — pre-M saves load with an empty feed
        merged.feed = Array.isArray(merged.feed) ? merged.feed : []
        merged.feedSeq = typeof merged.feedSeq === "number" ? merged.feedSeq : 0
        return merged
      }
      // version mismatch → reset (full stepwise migrator goes here later)
    }
  } catch { /* corrupt save */ }
  return freshState()
}

/** The member whose key is queued (selected, else first party member, else first roster member). */
function keyOwner(state: GameState): RawMember | undefined {
  return state.roster.find((m) => m.id === state.selectedKeyOwnerId)
    ?? state.roster.find((m) => state.partyIds.includes(m.id))
    ?? state.roster[0]
}

function weekAffixIds(weekNumber: number): string[] {
  const season = [...content.seasons.values()][0]
  if (!season || !season.affixCalendar.length) return content.save.week.affixes
  const wk = season.affixCalendar[(weekNumber - 1) % season.affixCalendar.length]
  return [wk.tier1, ...wk.tier2]
}

const bestRosterIlvl = (roster: RawMember[]) => roster.length ? Math.max(...roster.map((m) => memberIlvl(m.gear))) : 112

/* ---- actions ---- */
type Action =
  | { type: "CREATE_GUILD"; info: GuildInfo }
  | { type: "TOGGLE_SIGN"; id: string }
  | { type: "CONFIRM_RECRUITS" }
  | { type: "REROLL_RECRUITS" }
  | { type: "SET_PARTY"; ids: string[] }
  | { type: "TOGGLE_PARTY"; id: string }
  | { type: "SELECT_KEY"; ownerId: string }
  | { type: "CONSUME_AUTOPLAY" }
  | { type: "SET_TALENT"; memberId: string; nodeId: string; optionId: string }
  | { type: "EQUIP"; memberId: string; uid: string }
  | { type: "RAN_KEY"; result: RunResult; config: RunConfig; ownerId: string; runKey: MemberKey; ticket: RunTicket }
  | { type: "CONFIRM_LOOT"; assignments: Record<string, string> }
  | { type: "FILE_REPORT" }
  | { type: "ADVANCE_WEEK" }
  | { type: "NEW_GAME" }

const MORALE_DELTA = { timed: 10, depleted: -5, wipe: -20 } as const
const SHARDS_PER_SCRAP = 8
const clamp = (v: number, lo: number, hi: number) => Math.max(lo, Math.min(hi, v))
const mmss = (s: number) => `${Math.floor(s / 60)}:${String(Math.round(s % 60)).padStart(2, "0")}`

/* deterministic loot for a finished run (player distributes it on the Loot screen) */
function computeLoot(state: GameState, r: RunResult, runKeyState: MemberKey): LootDrop[] {
  const lootCount = r.outcome === "timed" ? 2 : r.outcome === "depleted" ? 1 : 0
  const dungeon = content.dungeons.get(runKeyState.dungeonId)
  const table = dungeon?.lootTable ?? []
  if (!lootCount || !table.length) return []
  const party = state.partyIds.map((id) => state.roster.find((m) => m.id === id)).filter(Boolean) as RawMember[]
  const drops: LootDrop[] = []
  let seed = r.seed >>> 0
  for (let i = 0; i < lootCount; i++) {
    seed = (seed * 1664525 + 1013904223) >>> 0
    const base = makeDrop(table[seed % table.length], runKeyState.level, seed)
    if (!base) continue
    // J.6: record EVERY spec-eligible member's current ilvl + delta (for the loot screen comparison), and the best upgrade
    let upgradeFor: string | null = null, upgradeAmt = 0
    const upgrades: UpgradeCandidate[] = []
    for (const m of party) {
      if (!base.specs.includes(m.specId)) continue
      const cur = m.gear[base.slot]?.ilvl ?? 105
      const delta = base.ilvl - cur
      upgrades.push({ memberId: m.id, delta, currentIlvl: cur })
      if (delta > upgradeAmt) { upgradeAmt = delta; upgradeFor = m.id }
    }
    drops.push({ ...base, primaryStat: primaryStatOf(base.specs[0] ?? "guardian"), upgradeFor, upgradeAmt, upgrades })
  }
  return drops
}

/* ---- guild-feed emit (M.1) ---- */
const FEED_CAP = 200
const LOW_MORALE = 25
const specIcon = (specId: string | undefined): { kind: string; id: string } | undefined =>
  specId ? { kind: "spec", id: specId } : undefined
/** Append neutral system notifications to the feed. Stamps a stable id from a persisted counter + the current week. */
function pushFeed(s: PersistState, ...entries: FeedPartial[]): { feed: FeedEntry[]; feedSeq: number } {
  if (!entries.length) return { feed: s.feed, feedSeq: s.feedSeq }
  let seq = s.feedSeq
  const made: FeedEntry[] = entries.map((e) => ({ ...e, id: `f${seq++}`, week: s.weekNumber }))
  return { feed: [...s.feed, ...made].slice(-FEED_CAP), feedSeq: seq }
}

/* ---- loot drama (M.2): personality-gated contested-item consequences ---- */
const LOOT_WIN_BUFF = 5    // winner: +5% output next run (GDD canon)
const CHILL_TRAITS = new Set(["boomer", "casual-andy"])   // these shrug a snub off (not an archetype — explicit ids)
const isSelfish = (traitIds: string[]) => traitIds.some((t) => content.traits.get(t)?.archetype === "Selfish")
const isChill = (traitIds: string[]) => traitIds.some((t) => CHILL_TRAITS.has(t))
/** Morale hit a member takes for losing a contested roll, gated by personality. Base = the dormant `lost-loot` event (−5). */
function lootLossMorale(traitIds: string[]): number {
  const base = content.moraleEvents.get("lost-loot")?.delta ?? -5   // wires the previously-dormant event
  if (isSelfish(traitIds)) return base - 3   // Loot Goblin / Solo Player / Cocky / Rival contest loudly + lose more (−8)
  if (isChill(traitIds)) return Math.ceil(base / 2)   // Boomer / Casual Andy shrug (−2)
  return base   // everyone else: the canon −5
}

function reducer(state: GameState, action: Action): GameState {
  switch (action.type) {
    case "CREATE_GUILD": {
      const base: GameState = { ...freshState(), phase: "recruit", guild: action.info }
      return { ...base, ...pushFeed(base, { kind: "system", tone: "neutral", text: `${action.info.name} founded. Assemble a roster from the scouting board.` }) }
    }
    case "TOGGLE_SIGN": {
      const rec = state.recruits.find((r) => r.id === action.id)
      if (!rec) return state
      const signed = state.signedRecruitIds.includes(action.id)
      if (signed) return { ...state, signedRecruitIds: state.signedRecruitIds.filter((x) => x !== action.id), wallet: { ...state.wallet, emblem: state.wallet.emblem + rec.cost } }
      if (state.wallet.emblem < rec.cost) return state
      if (state.roster.length + state.signedRecruitIds.length >= content.recruitment.rosterCap) return state
      return { ...state, signedRecruitIds: [...state.signedRecruitIds, action.id], wallet: { ...state.wallet, emblem: state.wallet.emblem - rec.cost } }
    }
    case "CONFIRM_RECRUITS": {
      const signed = state.signedRecruitIds.map((id) => state.recruits.find((r) => r.id === id)).filter(Boolean) as Recruit[]
      if (!signed.length) return state
      const newMembers: RawMember[] = signed.map((rec) => ({
        id: "m-" + rec.id, name: rec.name, title: "", specId: rec.specId, morale: rec.morale,
        portrait: pick(PORTRAITS), traitIds: [rec.traitId], gear: starterGear(rec.specId, rec.ilvl, "m-" + rec.id),
        key: freshKey(),   // every recruit arrives holding their own random +2 key
        talents: {},       // starts on balanced defaults; player tunes per member
        // Phase F: carry over the scouted operator skills/ceilings; XP starts empty and grows with play
        skills: rec.skills, ceilings: rec.ceilings, skillXp: zeroSkillMap(),
        revealed: rec.revealed, potentialProfile: rec.potentialProfile,
        lootBuffPct: 0,
      }))
      const roster = [...state.roster, ...newMembers]
      // fill the party up to 5 (keeps existing party, adds the new signs)
      const partyIds = [...state.partyIds]
      for (const m of newMembers) { if (partyIds.length >= 5) break; if (!partyIds.includes(m.id)) partyIds.push(m.id) }
      const phase: Phase = state.phase === "recruit" ? "playing" : state.phase
      // entering play for the first time → queue the first party member's key
      const selectedKeyOwnerId = state.selectedKeyOwnerId ?? partyIds[0] ?? roster[0]?.id ?? null
      return {
        ...state, roster, partyIds, phase, selectedKeyOwnerId,
        recruits: generateRecruits(bestRosterIlvl(roster)),
        signedRecruitIds: [],
        ...pushFeed(state, ...newMembers.map((m): FeedPartial => ({
          kind: "recruit", tone: "good", memberId: m.id, icon: specIcon(m.specId),
          text: `${m.name} the ${content.specs.get(m.specId)?.name ?? m.specId} joined the guild.`,
        }))),
      }
    }
    case "REROLL_RECRUITS": {
      // refund anything currently signed, then draw a fresh pool
      const refund = state.signedRecruitIds.reduce((s, id) => s + (state.recruits.find((r) => r.id === id)?.cost ?? 0), 0)
      return {
        ...state,
        wallet: { ...state.wallet, emblem: state.wallet.emblem + refund },
        recruits: generateRecruits(bestRosterIlvl(state.roster), { balanced: state.phase === "recruit" }),
        signedRecruitIds: [],
      }
    }
    case "SET_PARTY": {
      // always keep the key owner in the party (locked)
      let ids = action.ids.slice(0, 5)
      const owner = state.selectedKeyOwnerId
      if (owner && !ids.includes(owner)) ids = [owner, ...ids].slice(0, 5)
      return { ...state, partyIds: ids }
    }
    case "TOGGLE_PARTY": {
      if (action.id === state.selectedKeyOwnerId) return state   // key owner is locked into the party
      const has = state.partyIds.includes(action.id)
      if (has) return { ...state, partyIds: state.partyIds.filter((x) => x !== action.id) }
      if (state.partyIds.length >= 5) return state
      return { ...state, partyIds: [...state.partyIds, action.id] }
    }
    case "SELECT_KEY": {
      if (!state.roster.some((m) => m.id === action.ownerId)) return state
      // force the new owner into the party (locked); if full, bump the last non-owner to make room
      let partyIds = state.partyIds.filter((id) => id !== action.ownerId)
      if (partyIds.length >= 5) partyIds = partyIds.slice(0, 4)
      partyIds = [action.ownerId, ...partyIds]
      return { ...state, selectedKeyOwnerId: action.ownerId, partyIds }
    }
    case "SET_TALENT":
      return { ...state, roster: state.roster.map((m) => m.id === action.memberId ? { ...m, talents: { ...m.talents, [action.nodeId]: action.optionId } } : m) }
    case "EQUIP": {
      const item = state.stash.find((i) => i.uid === action.uid)
      const member = state.roster.find((m) => m.id === action.memberId)
      if (!item || !member || !item.specs.includes(member.specId)) return state
      const slot = item.slot
      const old = member.gear[slot]
      const roster = state.roster.map((m) => m.id === member.id ? { ...m, gear: { ...m.gear, [slot]: item } } : m)
      const stash = state.stash.filter((i) => i.uid !== item.uid)
      if (old && old.baseId !== "beta-standard-issue") stash.push(old)
      return { ...state, roster, stash }
    }
    case "RAN_KEY": {
      const drops = computeLoot(state, action.result, action.runKey)
      const t = action.ticket
      const outWord = t.outcome === "timed" ? "Timed" : t.outcome === "depleted" ? "Depleted" : "Wiped"
      const tone: FeedTone = t.outcome === "timed" ? "good" : t.outcome === "wipe" ? "bad" : "warn"
      const deaths = t.deaths === 1 ? "1 death" : `${t.deaths} deaths`
      const runLines: FeedPartial[] = [{
        kind: "run", tone, memberId: t.ownerId || undefined, icon: specIcon(state.roster.find((m) => m.id === t.ownerId)?.specId),
        text: `${t.ownerName}'s +${t.keyLevel} ${t.dungeonName} — ${outWord} in ${mmss(t.durationSec)}, ${deaths}.`,
      }]
      if (drops.length) runLines.push({ kind: "loot", tone: "neutral", text: `${drops.length === 1 ? "1 item" : `${drops.length} items`} dropped — awaiting distribution.` })
      return {
        ...state, lastResult: action.result, lastConfig: action.config,
        lastRunOwnerId: action.ownerId, lastRunKey: action.runKey, autoplaySeed: action.result.seed,
        lastLoot: null, pendingLoot: drops,
        history: [action.ticket, ...state.history].slice(0, 50),   // record every run for the Reports list
        ...pushFeed(state, ...runLines),
      }
    }
    case "CONSUME_AUTOPLAY":
      return state.autoplaySeed == null ? state : { ...state, autoplaySeed: null }
    case "CONFIRM_LOOT": {
      const r = state.lastResult
      if (!r) return state
      const drops = state.pendingLoot ?? []
      const feed: FeedPartial[] = []   // M.1: collected as we resolve loot/morale/keystone/growth below
      const lootLossByMember: Record<string, number> = {}   // M.2: contested-roll morale penalties (folded into morale below)
      const lootWinners = new Set<string>()                  // M.2: members who won a contested item → +5% output next run
      let roster = state.roster.map((m) => ({ ...m, gear: { ...m.gear } }))
      const stash = [...state.stash]
      let shardsGained = 0
      for (const d of drops) {
        const a = action.assignments[d.uid]
        if (!a || a === "scrap") { shardsGained += SHARDS_PER_SCRAP; continue }
        const member = roster.find((m) => m.id === a)
        if (member && d.specs.includes(member.specId)) {
          const old = member.gear[d.slot]
          member.gear[d.slot] = { uid: d.uid, baseId: d.baseId, name: d.name, slot: d.slot, specs: d.specs, ilvl: d.ilvl, rarity: d.rarity }
          if (old && old.baseId !== "beta-standard-issue") stash.push(old)
          // M.2 loot drama: contested when 2+ party members would upgrade AND the winner is one of them
          const upgraders = d.upgrades.filter((u) => u.delta > 0)
          const contested = upgraders.length >= 2 && upgraders.some((u) => u.memberId === member.id)
          if (contested) {
            lootWinners.add(member.id)   // winner → +5% next run (applied below; consumed after the next run)
            const loserNames: string[] = []
            for (const u of upgraders) {
              if (u.memberId === member.id) continue
              const lm = roster.find((x) => x.id === u.memberId)
              if (!lm) continue
              lootLossByMember[lm.id] = (lootLossByMember[lm.id] ?? 0) + lootLossMorale(lm.traitIds)   // personality-gated snub
              loserNames.push(lm.name)
            }
            feed.push({ kind: "loot", tone: "warn", memberId: member.id, icon: specIcon(member.specId), text: `Contested: ${member.name} took ${d.name} over ${loserNames.join(", ")} (+${LOOT_WIN_BUFF}% next run).` })
          } else {
            feed.push({ kind: "loot", tone: "good", memberId: member.id, icon: specIcon(member.specId), text: `${member.name} equipped ${d.name} (ilvl ${d.ilvl}).` })
          }
        } else {
          stash.push({ uid: d.uid, baseId: d.baseId, name: d.name, slot: d.slot, specs: d.specs, ilvl: d.ilvl, rarity: d.rarity })
        }
      }
      // morale
      const partySet = new Set(state.partyIds)
      roster = roster.map((m) => {
        if (!partySet.has(m.id)) return m
        // M.2: a contested-loot snub stacks on top of the outcome morale delta (personality-gated above)
        const nm = clamp(m.morale + MORALE_DELTA[r.outcome] + (lootLossByMember[m.id] ?? 0), 0, 100)
        // M.1: warn only when a member CROSSES below the low-morale line this run (no spam while they sit low)
        if (m.morale >= LOW_MORALE && nm < LOW_MORALE) feed.push({ kind: "morale", tone: "warn", memberId: m.id, icon: specIcon(m.specId), text: `${m.name}'s morale fell to ${nm}. At risk of leaving the guild.` })
        return { ...m, morale: nm }
      })

      // keystone progression (margin-based) — applied to the KEY OWNER's own key
      const ownerId = state.lastRunOwnerId
      const ranKey = state.lastRunKey ?? roster.find((m) => m.id === ownerId)?.key ?? freshKey()
      const oldLevel = ranKey.level
      const frac = (r.timerSec - r.durationSec) / r.timerSec
      const upgrade = r.outcome !== "timed" ? -1 : frac >= 0.40 ? 3 : frac >= 0.20 ? 2 : 1
      const newLevel = clamp(oldLevel + upgrade, 2, 40)
      const best = r.outcome === "timed" ? Math.max(ranKey.best, oldLevel) : ranKey.best
      const rating = r.outcome === "timed"
        ? Math.max(ranKey.rating, Math.round(best * 95 + oldLevel * 12 + Math.max(0, r.timerSec - r.durationSec) / 60 * 6))
        : ranKey.rating
      const newKey: MemberKey = { dungeonId: ranKey.dungeonId, level: newLevel, best, rating }
      roster = roster.map((m) => m.id === ownerId ? { ...m, key: newKey } : m)
      {
        const owner = roster.find((m) => m.id === ownerId)
        const short = dShort(content.dungeons.get(ranKey.dungeonId)?.name ?? "")
        if (owner && upgrade > 0) feed.push({ kind: "keystone", tone: "good", memberId: owner.id, icon: specIcon(owner.specId), text: `${owner.name}'s keystone upgraded to +${newLevel} ${short}.` })
        else if (owner) feed.push({ kind: "keystone", tone: "bad", memberId: owner.id, icon: specIcon(owner.specId), text: `${owner.name}'s keystone depleted to +${newLevel} ${short}.` })
      }

      // Phase F: post-run operator growth — each participant earns skill XP toward their hidden ceilings (auto-growth).
      // Above the gear cap, the upgrade that would have been higher ilvl is converted into extra operator XP (the handoff).
      const xpGain = xpFromRun(oldLevel, r.outcome) + (oldLevel > GEAR_CAP_KEY ? ABOVE_CAP_SKILL_XP * (oldLevel - GEAR_CAP_KEY) : 0)
      roster = roster.map((m) => {
        if (!partySet.has(m.id)) return m
        const g = applyGrowth(m.skills, m.ceilings, m.skillXp, roleOf(m.specId), m.traitIds, xpGain)
        // M.1: surface an operator level-up when a skill's integer level ticks up this run
        for (const k of Object.keys(g.skills)) {
          if (Math.floor(g.skills[k]) > Math.floor(m.skills[k] ?? 0))
            feed.push({ kind: "operator", tone: "good", memberId: m.id, icon: specIcon(m.specId), text: `${m.name}'s ${content.operatorSkills.get(k)?.name ?? k} rose to ${Math.floor(g.skills[k])}.` })
        }
        return { ...m, skills: g.skills, skillXp: g.skillXp }
      })

      // M.2: the loot-win buff is a ONE-run boost — clear it for everyone who just ran (consumed), then set it on this run's winners
      roster = roster.map((m) => {
        if (!partySet.has(m.id)) return m
        const won = lootWinners.has(m.id)
        if (!won && m.lootBuffPct === 0) return m
        return { ...m, lootBuffPct: won ? LOOT_WIN_BUFF : 0 }
      })

      const emblem = state.wallet.emblem + (r.outcome === "timed" ? 5 : r.outcome === "depleted" ? 2 : 0)
      const gold = state.wallet.gold + (r.outcome === "wipe" ? 0 : 200 + oldLevel * 40)
      const weekNumber = state.weekNumber + 1
      const dungeon = content.dungeons.get(ranKey.dungeonId)!
      const affixes = weekAffixIds(weekNumber).map((id) => content.affixes.get(id)?.name ?? id)
      const lootSummary = drops.length ? `${drops.length} drop(s) distributed` : "no loot"
      const change: KeystoneChange = {
        prevLevel: oldLevel, prevDungeon: dungeon.name, prevTime: mmss(r.durationSec), prevPar: mmss(r.timerSec),
        outcome: r.outcome, underBy: Math.round(r.timerSec - r.durationSec), upgrade,
        level: newLevel, dungeon: dungeon.name, dungeonShort: dShort(dungeon.name), timer: mmss(dungeon.timerSeconds), affixes,
      }
      return {
        ...state, roster, stash,
        wallet: { ...state.wallet, emblem, gold, shard: state.wallet.shard + shardsGained },
        weekNumber,
        lastResult: null, pendingLoot: null, lastLoot: lootSummary, lastKeystoneChange: change,
        ...pushFeed(state, ...feed),
      }
    }
    case "FILE_REPORT": {
      // legacy all-in-one (retained for the old screens); new flow uses CONFIRM_LOOT
      const r = state.lastResult
      if (!r) return state
      const md = MORALE_DELTA[r.outcome]
      const ownerId = state.lastRunOwnerId
      const ranKey = state.lastRunKey ?? state.roster.find((m) => m.id === ownerId)?.key ?? freshKey()
      const partySet = new Set(state.partyIds)
      const level = clamp(ranKey.level + r.keyDelta, 2, 40)
      const best = r.outcome === "timed" ? Math.max(ranKey.best, ranKey.level) : ranKey.best
      const rating = r.outcome === "timed"   // same formula as CONFIRM_LOOT (best*95 base) so both paths agree
        ? Math.max(ranKey.rating, Math.round(best * 95 + ranKey.level * 12 + Math.max(0, r.timerSec - r.durationSec) / 60 * 6))
        : ranKey.rating
      const newKey: MemberKey = { dungeonId: ranKey.dungeonId, level, best, rating }
      const roster = state.roster.map((m) => ({
        ...m,
        morale: partySet.has(m.id) ? clamp(m.morale + md, 0, 100) : m.morale,
        key: m.id === ownerId ? newKey : m.key,
      }))
      const drops = (state.pendingLoot ?? []).map((d) => ({ uid: d.uid, baseId: d.baseId, name: d.name, slot: d.slot, specs: d.specs, ilvl: d.ilvl, rarity: d.rarity }))
      const emblem = state.wallet.emblem + (r.outcome === "timed" ? 5 : r.outcome === "depleted" ? 2 : 0)
      const gold = state.wallet.gold + (r.outcome === "wipe" ? 0 : 200 + ranKey.level * 40)
      return {
        ...state, roster,
        wallet: { ...state.wallet, emblem, gold },
        stash: [...drops, ...state.stash],
        lastResult: null, pendingLoot: null, lastLoot: drops.length ? "Looted." : "No loot.",
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
    portrait: `/warcraftcn/${m.portrait}.webp`, note: m.note, key: m.key ? shapeKey(m.key) : undefined, talents: m.talents ?? {},
    skills: m.skills, ceilings: m.ceilings, revealed: m.revealed, skillXp: m.skillXp, traitIds: m.traitIds, lootBuffPct: m.lootBuffPct ?? 0,
    traits: m.traitIds.map((tid) => {
      const t = content.traits.get(tid)
      if (!t) return { name: tid, rarity: "Common", kind: "Start", effect: "" } as Trait
      return { name: t.name, rarity: t.rarity, kind: t.kind === "start" ? "Start" : "Earned", effect: t.effect } as Trait
    }),
  }
}
interface GameApi {
  phase: Phase
  guild: GuildInfo | null
  members: Member[]
  party: Member[]
  partyIds: string[]
  keystone: KeyView   // compat: the currently-selected/queued key (shaped) — used by topnav & legacy screens
  keys: (KeyView & { ownerId: string; ownerName: string; spec: string })[]   // every member's key, for the picker
  selectedKeyOwnerId: string | null
  lastRunKey: KeyView | null          // the key as it was at the last run's start (report header)
  wallet: { gold: number; emblems: number; shards: number }
  weekNumber: number
  weekAffixes: Affix[]
  stash: GearItem[]
  recruits: Recruit[]
  signedRecruitIds: string[]
  lastResult: RunResult | null
  lastLoot: string | null
  pendingLoot: LootDrop[] | null
  lastKeystoneChange: KeystoneChange | null
  autoplaySeed: number | null
  consumeAutoplay: () => void
  history: RunTicket[]
  feed: FeedEntry[]
  replayTicket: (t: RunTicket) => RunResult
  gearFor: (id: string) => Record<string, GearItem>
  // flow
  createGuild: (info: GuildInfo) => void
  toggleSignRecruit: (id: string) => void
  confirmRecruits: () => void
  rerollRecruits: () => void
  equip: (memberId: string, uid: string) => void
  togglePartyMember: (id: string) => void
  setParty: (ids: string[]) => void
  selectKey: (ownerId: string) => void
  setTalent: (memberId: string, nodeId: string, optionId: string) => void
  runKey: (cfg: RunConfig) => RunResult
  rerun: () => RunResult
  confirmLoot: (assignments: Record<string, string>) => void
  fileReport: () => void
  advanceWeek: () => void
  newGame: () => void
}

const GameContext = createContext<GameApi | null>(null)

export function GameProvider({ children }: { children: ReactNode }) {
  const [state, dispatch] = useReducer(reducer, undefined, loadState)

  useEffect(() => {
    const persist: Record<string, unknown> = { ...state }
    for (const k of Object.keys(TRANSIENT)) delete persist[k]   // never persist transient run/UI state
    try { localStorage.setItem(SAVE_KEY, JSON.stringify(persist)) } catch { /* quota */ }
  }, [state])

  const api = useMemo<GameApi>(() => {
    const affIds = weekAffixIds(state.weekNumber)
    const owner = keyOwner(state)
    const ownerKey: MemberKey = owner?.key ?? freshKey()
    const doRun = (cfg: RunConfig): RunResult => {
      const o = keyOwner(state)
      const runKeyState: MemberKey = o?.key ?? freshKey()
      const party: SimPartyMember[] = state.partyIds
        .map((id) => state.roster.find((m) => m.id === id))
        .filter(Boolean)
        .map((m) => ({ id: m!.id, name: m!.name, specId: m!.specId, ilvl: memberIlvl(m!.gear), morale: m!.morale, traitIds: m!.traitIds, talents: m!.talents, skills: m!.skills, lootBuffPct: m!.lootBuffPct }))
      const seed = Math.floor(Math.random() * 0xffffffff)
      const result = runDungeon({ dungeonId: runKeyState.dungeonId, keyLevel: runKeyState.level, affixIds: affIds, party, tactics: cfg.tactics, aggression: cfg.aggression, seed })
      const dgn = content.dungeons.get(runKeyState.dungeonId)
      const ticket: RunTicket = {
        id: `run-${seed.toString(36)}-${Date.now().toString(36)}`, when: Date.now(),
        ownerId: o?.id ?? "", ownerName: o?.name ?? "—",
        seed, dungeonId: runKeyState.dungeonId, keyLevel: runKeyState.level, affixIds: affIds,
        party, tactics: cfg.tactics, aggression: cfg.aggression,
        dungeonName: dgn?.name ?? runKeyState.dungeonId, outcome: result.outcome,
        durationSec: result.durationSec, timerSec: result.timerSec, deaths: result.deaths.length,
        rating: runKeyState.rating, affixNames: affIds.map((id) => content.affixes.get(id)?.name ?? id),
      }
      dispatch({ type: "RAN_KEY", result, config: cfg, ownerId: o?.id ?? "", runKey: runKeyState, ticket })
      return result
    }
    const replayTicket = (t: RunTicket): RunResult =>
      runDungeon({ dungeonId: t.dungeonId, keyLevel: t.keyLevel, affixIds: t.affixIds, party: t.party, tactics: t.tactics, aggression: t.aggression, seed: t.seed })
    return {
      phase: state.phase,
      guild: state.guild,
      members: state.roster.map(shapeMember),
      party: state.partyIds.map((id) => state.roster.find((m) => m.id === id)).filter(Boolean).map((m) => shapeMember(m as RawMember)),
      partyIds: state.partyIds,
      keystone: shapeKey(ownerKey),
      keys: state.roster.map((m) => ({ ownerId: m.id, ownerName: m.name, spec: m.specId, ...shapeKey(m.key) })),
      selectedKeyOwnerId: state.selectedKeyOwnerId,
      lastRunKey: state.lastRunKey ? shapeKey(state.lastRunKey) : null,
      wallet: { gold: state.wallet.gold, emblems: state.wallet.emblem, shards: state.wallet.shard },
      weekNumber: state.weekNumber,
      weekAffixes: affIds.map((id) => content.affixes.get(id)).filter(Boolean) as Affix[],
      stash: state.stash,
      recruits: state.recruits,
      signedRecruitIds: state.signedRecruitIds,
      lastResult: state.lastResult,
      lastLoot: state.lastLoot,
      pendingLoot: state.pendingLoot,
      lastKeystoneChange: state.lastKeystoneChange,
      autoplaySeed: state.autoplaySeed,
      consumeAutoplay: () => dispatch({ type: "CONSUME_AUTOPLAY" }),
      history: state.history,
      feed: state.feed,
      replayTicket,
      gearFor: (id) => state.roster.find((m) => m.id === id)?.gear ?? {},
      createGuild: (info) => dispatch({ type: "CREATE_GUILD", info }),
      toggleSignRecruit: (id) => dispatch({ type: "TOGGLE_SIGN", id }),
      confirmRecruits: () => dispatch({ type: "CONFIRM_RECRUITS" }),
      rerollRecruits: () => dispatch({ type: "REROLL_RECRUITS" }),
      equip: (memberId, uid) => dispatch({ type: "EQUIP", memberId, uid }),
      togglePartyMember: (id) => dispatch({ type: "TOGGLE_PARTY", id }),
      setParty: (ids) => dispatch({ type: "SET_PARTY", ids }),
      selectKey: (ownerId) => dispatch({ type: "SELECT_KEY", ownerId }),
      setTalent: (memberId, nodeId, optionId) => dispatch({ type: "SET_TALENT", memberId, nodeId, optionId }),
      runKey: doRun,
      rerun: () => doRun(state.lastConfig ?? DEFAULT_CONFIG),
      confirmLoot: (assignments) => dispatch({ type: "CONFIRM_LOOT", assignments }),
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
