// Vite-SSR smoke test for the EGM engine — Wave 2/3 (healer/peel) + Phase 4 (bands) + Phase 5a (affixes/tactics).
import { createServer } from "vite"

const server = await createServer({ server: { middlewareMode: true }, appType: "custom", logLevel: "error" })
try {
  const { runDungeonEGM } = await server.ssrLoadModule("/src/sim/egm/engine.ts")
  const { content } = await server.ssrLoadModule("/src/content/index.ts")
  const save = content.save
  const mk = (id, name, specId) => ({ id, name, specId, ilvl: 165, morale: 60, traitIds: [] })

  const run = (party, keyLevel, opts = {}) => runDungeonEGM({
    dungeonId: save.keystone.dungeonId, keyLevel,
    affixIds: opts.affixIds ?? save.week.affixes, party,
    tactics: opts.tactics ?? { interrupts: 1, positioning: 1, cooldowns: 1, killorder: 1 },
    aggression: opts.aggression ?? "Balanced", seed: opts.seed ?? 12345,
  })
  const linesOf = (r) => r.log.map((l) => `${l.t} [${l.kind}] ${l.text}`)
  const probe = (label, r, probes) => {
    const lines = linesOf(r)
    console.log(`\n### ${label}: ${r.outcome} dur=${r.durationSec}s timer=${r.timerSec}s deaths=${r.deaths.length}`)
    for (const [name, re] of Object.entries(probes)) { const n = lines.filter((l) => re.test(l)).length; console.log(`${n ? "OK " : "-- "} ${name}: ${n}`) }
  }

  const balanced = [mk("p1","Grymdark","guardian"), mk("p2","Svenrik","cleric"), mk("p3","Bramblewen","lifebinder"), mk("p4","Sythe","assassin"), mk("p5","Emberkin","pyromancer")]

  // --- Phase 5a: affixes & boss mechanics fire, gated by tactics ---
  probe("Affixes: Volcanic+Sanguine+Raging +8", run(balanced, 8, { affixIds: ["volcanic","sanguine","raging"] }), {
    "Volcanic eruption": /Volcanic eruption/, "Sanguine pool heal": /Sanguine pool/,
    "boss tests tactic": /tests (Interrupts|Positioning|Cooldowns|Kill Order)/,
    "boss mechanic fires": /goes through|damage spike|summons diggers|caught in it/,
  })
  probe("Affixes: week (Fortified/Bursting/Spiteful) +8", run(balanced, 8), {
    "boss tests tactic": /tests (Interrupts|Positioning|Cooldowns|Kill Order)/,
    "boss mechanic fires": /goes through|damage spike|summons diggers|caught in it/,
    "Bursting/Spiteful death cause": /dies .*(Bursting|Spiteful)/,
  })

  // --- Tactics matter: all-3 vs all-0 (same party/seed/affixes) ---
  console.log("\n=== Tactics comparison (week affixes, +14, seed 7) ===")
  for (const [name, tactics] of [["all-3", { interrupts: 3, positioning: 3, cooldowns: 3, killorder: 3 }], ["all-0", { interrupts: 0, positioning: 0, cooldowns: 0, killorder: 0 }]]) {
    const r = run(balanced, 14, { tactics, seed: 7 })
    console.log(`  ${name.padEnd(6)} → ${r.outcome.padEnd(9)} dur=${r.durationSec}s deaths=${r.deaths.length}`)
  }
} finally {
  await server.close()
}
