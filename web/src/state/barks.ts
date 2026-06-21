/* M.3 — the bark engine: deterministic, no-LLM, replay-safe.
   A bark is a roster member reacting in their own personality VOICE (first-person). Voice attaches to the member's
   archetype (tone), is mood-shifted by morale, individuated by a per-character seed, and grounded in real run state
   via slot fills. Rate-limited to ~1–2 per run with a no-repeat window. Pure function → same inputs = same barks. */
import { content } from "@/content"
import { Rng } from "@/sim/rng"

export interface BarkMoment {
  event: string                 // bank key in barks.events
  speakerId: string
  speakerName: string
  specId: string
  archetype: string             // "Selfish" | "Wildcard" | "Specialist" | "Enabler" | "Leader" | "default"
  morale: number
  priority: number              // higher = more emotionally "barkable" (snub 100 … comfortable timed 20)
  slots: Record<string, string> // {item} {winner} {dungeon} {key} {margin} {self}
}
export interface Bark { speakerId: string; specId: string; speakerName: string; text: string; key: string }

const fill = (t: string, slots: Record<string, string>) => t.replace(/\{(\w+)\}/g, (_, k) => slots[k] ?? "")
const barkData = () => content.barks as unknown as {
  events: Record<string, Record<string, string[]>>
  moods?: { low: string[]; high: string[] }
}

/**
 * Pick ≤ max barks from the run's candidate moments. `recent` = the no-repeat window (recently used template keys).
 * Seeded by the run seed so it is deterministic and replay-faithful (no Math.random).
 */
export function generateBarks(moments: BarkMoment[], seed: number, recent: string[], max = 2): Bark[] {
  if (!moments.length) return []
  const { events, moods } = barkData()
  const rng = new Rng(seed >>> 0)
  // highest-emotion first; stable tiebreak so the order never depends on input ordering
  const sorted = [...moments].sort((a, b) => b.priority - a.priority || (a.speakerId < b.speakerId ? -1 : 1))
  const used = new Set(recent)
  const spoken = new Set<string>()   // at most one bark per speaker per run
  const out: Bark[] = []
  for (const m of sorted) {
    if (out.length >= max) break
    if (spoken.has(m.speakerId)) continue
    // rarity budget so the cadence stays ~1–2/run: high-emotion moments ~always bark; a low-stakes clean run
    // barks only sometimes; a second bark in one run is rarer still.
    const gate = out.length === 0 ? (m.priority >= 40 ? 1 : 0.4) : (m.priority >= 70 ? 0.5 : 0.2)
    if (gate < 1 && !rng.chance(gate)) continue
    const bank = events[m.event]
    const list = bank?.[m.archetype] ?? bank?.default ?? []
    if (!list.length) continue
    // individuation + no-repeat: start at a seeded index, walk forward past anything in the recent window
    let idx = Math.floor(rng.next() * list.length)
    for (let i = 0; i < list.length && used.has(`${m.event}:${m.archetype}:${idx}`); i++) idx = (idx + 1) % list.length
    const key = `${m.event}:${m.archetype}:${idx}`
    let text = fill(list[idx], m.slots)
    // morale → mood: an occasional banded interjection prefix
    if (moods) {
      if (m.morale < 30 && moods.low.length && rng.chance(0.5)) text = rng.pick(moods.low) + " " + text
      else if (m.morale >= 75 && moods.high.length && rng.chance(0.4)) text = rng.pick(moods.high) + " " + text
    }
    out.push({ speakerId: m.speakerId, specId: m.specId, speakerName: m.speakerName, text, key })
    used.add(key)
    spoken.add(m.speakerId)
  }
  return out
}
