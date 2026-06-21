// M.3 verification: the bark engine is deterministic, state-grounded, personality-routed, no-repeat, rate-limited.
import { createServer } from "vite"
const server = await createServer({ server: { middlewareMode: true }, appType: "custom", logLevel: "error" })
try {
  const { generateBarks } = await server.ssrLoadModule("/src/state/barks.ts")
  const pass = (c, m) => { console.log(`${c ? "PASS" : "FAIL"}  ${m}`); if (!c) process.exitCode = 1 }
  const snub = (over = {}) => ({
    event: "loot-snub-loser", speakerId: "m1", speakerName: "Dolgrun", specId: "guardian", archetype: "Selfish",
    morale: 60, priority: 100, slots: { item: "Faceguard of Interred Kings", winner: "Svenrik", self: "Dolgrun" }, ...over,
  })

  // A — determinism: same seed + inputs → identical bark
  const a = generateBarks([snub()], 123, []), b = generateBarks([snub()], 123, [])
  pass(a.length === 1 && b.length === 1 && a[0].text === b[0].text, "same seed → identical bark")
  console.log(`   e.g. "${a[0].text}"`)

  // B — state-grounded: the real item + winner are filled in (earnest item name preserved)
  pass(a[0].text.includes("Faceguard of Interred Kings") && a[0].text.includes("Svenrik"), "slots filled (earnest item + winner)")

  // C — variety across seeds (individuation)
  const texts = new Set(Array.from({ length: 24 }, (_, i) => generateBarks([snub()], i * 7 + 1, [])[0]?.text))
  pass(texts.size >= 3, `seeds yield variety (${texts.size} distinct of 24)`)

  // D — archetype routing: Selfish and default are distinct voices
  const sel = new Set(Array.from({ length: 24 }, (_, i) => generateBarks([snub({ archetype: "Selfish" })], i + 1, [])[0]?.text))
  const def = new Set(Array.from({ length: 24 }, (_, i) => generateBarks([snub({ archetype: "default" })], i + 1, [])[0]?.text))
  pass(![...sel].some((t) => def.has(t)), "Selfish ≠ default voice (personality routing)")

  // E — no-repeat window skips a recently-used template
  const first = generateBarks([snub()], 5, [])[0]
  const second = generateBarks([snub()], 5, [first.key])[0]
  pass(second && second.key !== first.key, "no-repeat window skips a recent template")

  // F — rate limit: ≤ 2 barks per run even with many moments
  const many = generateBarks([
    snub({ priority: 100 }),
    { event: "wipe", speakerId: "m2", speakerName: "X", specId: "berserker", archetype: "Wildcard", morale: 50, priority: 90, slots: { dungeon: "Ashveil Crypts", key: "8" } },
    { event: "timed", speakerId: "m3", speakerName: "Y", specId: "cleric", archetype: "Enabler", morale: 50, priority: 20, slots: { dungeon: "Ashveil Crypts", key: "8" } },
  ], 9, [])
  pass(many.length >= 1 && many.length <= 2, `rate-limited to 1–2 barks/run (got ${many.length})`)

  // G — morale mood: a low-morale speaker sometimes gets a banded interjection prefix
  const lowMoods = new Set(Array.from({ length: 30 }, (_, i) => generateBarks([snub({ morale: 10 })], i * 3 + 1, [])[0]?.text))
  const anyMood = [...lowMoods].some((t) => /^(ugh|whatever|of course|cool|sigh|naturally)\./i.test(t))
  pass(anyMood, "low morale sometimes prepends a mood interjection")
} finally { await server.close() }
