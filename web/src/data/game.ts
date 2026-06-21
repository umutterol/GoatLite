/* Adapter: presents the validated content registry (@/content ← /data) in the
   shapes the screens already expect. Sample run-result + rarity maps stay here
   (they are instance/UI data, not authored content). */
import { content } from "@/content"
import type { Affix as ContentAffix } from "@/content/schema"

export type Role = "Tank" | "Healer" | "DPS"
export type Rarity = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary"
export type Affix = ContentAffix

export interface Spec { id: string; name: string; className: string; role: Role; icon: string; blurb: string }
export interface Trait { name: string; rarity: Rarity; kind: "Start" | "Earned"; effect: string }
export interface KeyView {
  dungeonId: string; dungeon: string; dungeonShort: string
  level: number; timer: string; timerSec: number; best: number; rating: number
}
export interface Member {
  id: string; name: string; title: string; spec: string; ilvl: number; morale: number;
  portrait: string; traits: Trait[]; note?: string; key?: KeyView
  talents?: Record<string, string>   // nodeId → chosen optionId (B.7)
  // Phase F operator layer (skillId → value); ceilings revealed per `revealed` (hidden-but-active)
  skills?: Record<string, number>; ceilings?: Record<string, number>
  revealed?: Record<string, boolean>; skillXp?: Record<string, number>; traitIds?: string[]
  lootBuffPct?: number   // M.2: pending "+N% output next run" from winning contested loot (0 → none)
}
export interface Boss { n: number; name: string; ability: string; tests: string; icon: string }
export interface TacticCat { id: string; name: string; icon: string; starved: string }

export const SPECS: Record<string, Spec> = Object.fromEntries(
  [...content.specs.values()].map((s) => [s.id, {
    id: s.id, name: s.name, className: content.classes.get(s.classId)!.name,
    role: s.role as Role, icon: s.icon, blurb: s.blurb,
  } satisfies Spec])
)

export const ROSTER: Member[] = content.save.roster.map((m) => ({
  id: m.id, name: m.name, title: m.title, spec: m.specId, ilvl: m.ilvl, morale: m.morale,
  portrait: `/warcraftcn/${m.portrait}.webp`, note: m.note,
  traits: m.traitIds.map((tid) => {
    const t = content.traits.get(tid)!
    return { name: t.name, rarity: t.rarity, kind: t.kind === "start" ? "Start" : "Earned", effect: t.effect }
  }),
}))

const fmt = (s: number) => `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`
const ks = content.save.keystone
const ksDungeon = content.dungeons.get(ks.dungeonId)!
export const KEYSTONE = {
  dungeon: ksDungeon.name, level: ks.level, timer: fmt(ksDungeon.timerSeconds),
  best: ks.best, rating: ks.rating,
}

export const ASHVEIL_BOSSES: Boss[] = [...content.enemies.values()]
  .filter((e) => e.kind === "boss" && e.dungeonId === "ashveil-crypts")
  .sort((a, b) => (a.stage ?? 0) - (b.stage ?? 0))
  .map((e, i) => ({
    n: i + 1, name: e.name,
    ability: content.abilities.get(e.abilityId!)!.name,
    tests: content.tactics.get(e.testsTactic!)!.name,
    icon: e.icon ?? "ico-skull",
  }))

export const TACTIC_CATS: TacticCat[] = [...content.tactics.values()].map((t) => ({
  id: t.id, name: t.name, icon: t.icon, starved: t.starved,
}))

export const WEEK_AFFIXES: Affix[] = content.save.week.affixes.map((id) => content.affixes.get(id)!)

export const PROFILES: string[] = [...content.profiles.values()].map((p) => p.name)

export const CURRENCIES = {
  gold: content.save.wallet.gold ?? 0,
  emblems: content.save.wallet.emblem ?? 0,
  shards: content.save.wallet.shard ?? 0,
}

/* ---- sample run result (instance data, hand-authored) ---- */
export type LogKind = "normal" | "crit" | "dodge" | "death" | "mechanic" | "heal" | "flavor" | "good"
export interface LogLine { t: string; kind: LogKind; text: string }

export const SAMPLE_LOG: LogLine[] = [
  { t: "0:00", kind: "flavor",   text: "Keystone inserted. Ashveil Crypts +12 — Fortified, Bursting, Spiteful. The font flares." },
  { t: "0:14", kind: "good",     text: "Grymdark pulls the first pack clean. Kaelthri opens on the caster." },
  { t: "0:31", kind: "crit",     text: "Kaelthri — CRITICAL — 18,402 to the Bone Acolyte. It does not get up." },
  { t: "0:48", kind: "mechanic", text: "Bursting stacks at 3. Kill Order is holding the deaths apart." },
  { t: "1:12", kind: "dodge",    text: "Grymdark glances the Crypt Horror's cleave. Half damage. Healer exhales." },
  { t: "1:39", kind: "mechanic", text: "Embalmer Vesk begins PRESERVING FUME — interrupt assigned to Threnody…" },
  { t: "1:41", kind: "death",    text: "Threnody ignored the interrupt. The cast goes through." },
  { t: "1:42", kind: "flavor",   text: "Half the party is now coated in embalming fluid. Threnody typed \"mb\"." },
  { t: "1:58", kind: "heal",     text: "Svenrik blows a cooldown. Two absorbs land. The wipe is averted — barely." },
  { t: "2:25", kind: "mechanic", text: "Spiteful ghost spawns. It picks the lowest parse: Quillane." },
  { t: "2:33", kind: "death",    text: "Quillane is dragged into the dark. Morale −20. He is \"questioning his life choices.\"" },
  { t: "2:51", kind: "good",     text: "Dolgrun's Second Wind kicks in below 30% HP. +15% output. The pull stabilizes." },
  { t: "3:30", kind: "crit",     text: "Mournhollow detonates Burn stacks. CRITICAL — the whole pack folds at once." },
  { t: "3:34", kind: "mechanic", text: "…which spikes Bursting to 7. That was greedy." },
  { t: "4:10", kind: "good",     text: "Othrend falls. Key TIMED with 6:40 to spare. +1 keystone." },
]

export interface ParseRow { id: string; name: string; spec: string; actual: number; expected: number }
export const PARSE: ParseRow[] = [
  { id: "m3", name: "Kaelthri",    spec: "assassin",   actual: 99, expected: 92 },
  { id: "m4", name: "Mournhollow", spec: "pyromancer", actual: 86, expected: 88 },
  { id: "m6", name: "Dolgrun",     spec: "berserker",  actual: 78, expected: 74 },
  { id: "m1", name: "Grymdark",    spec: "guardian",   actual: 41, expected: 40 },
  { id: "m2", name: "Svenrik",     spec: "cleric",     actual: 33, expected: 45 },
]

/* ---- UI rarity colour maps ---- */
export const RARITY_CLASS: Record<Rarity, string> = {
  Common: "q-common", Uncommon: "q-uncommon", Rare: "q-rare", Epic: "q-epic", Legendary: "q-legendary",
}
export const RARITY_BORDER: Record<Rarity, string> = {
  Common: "border-[#9a8a63]", Uncommon: "brd-uncommon", Rare: "brd-rare", Epic: "brd-epic", Legendary: "brd-legendary",
}
export const RARITY_HEX: Record<string, string> = {
  Common: "#c8b88e", Uncommon: "#4caf3f", Rare: "#2f7fd6", Epic: "#a335ee", Legendary: "#e08a1e",
}

/* ---- WoW class colours (canonical Blizzard hex), keyed by our class names.
   Sage has no WoW analogue → Druid orange (nature theme, and distinct from the other four). ---- */
export const CLASS_COLOR: Record<string, string> = {
  Warrior: "#C69B6D", Paladin: "#F48CBA", Rogue: "#FFF468", Mage: "#3FC7EB", Sage: "#FF7C0A",
}
/** Resolve a spec id → its class colour (falls back to gilt gold). */
export function specColor(specId: string): string {
  return CLASS_COLOR[SPECS[specId]?.className] ?? "#e6c163"
}
