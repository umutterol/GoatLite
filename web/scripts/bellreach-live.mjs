// Bellreach Sanctum live probe — verifies the interrupts dungeon (C.1).
// Checks: (1) content still validates with Bellreach added, (2) the +2 floor times with the intended
// spend (Interrupts 3 + Cooldowns 3), (3) the interrupt READ is real — dropping Interrupts to 0 visibly
// degrades the run (more uninterrupted casts / deaths / slower or wiped), at the floor and at higher keys.
import { createServer } from "vite"

const server = await createServer({ server: { middlewareMode: true }, appType: "custom", logLevel: "error" })
try {
  const { runDungeonEGM } = await server.ssrLoadModule("/src/sim/egm/engine.ts")
  await server.ssrLoadModule("/src/content/index.ts") // throws here if any Bellreach cross-ref is broken
  const mk = (id, name, specId, ilvl) => ({ id, name, specId, ilvl, morale: 60, traitIds: [] })

  const run = (party, keyLevel, tactics, opts = {}) => runDungeonEGM({
    dungeonId: "bellreach-sanctum", keyLevel,
    affixIds: opts.affixIds ?? ["fortified", "bursting"], party,
    tactics, aggression: opts.aggression ?? "Balanced", seed: opts.seed ?? 7,
  })
  const linesOf = (r) => r.log.map((l) => `${l.t} [${l.kind}] ${l.text}`)
  const count = (r, re) => linesOf(r).filter((l) => re.test(l)).length

  const ilvlFor = (key) => 108 + 4 * key // gear-appropriate per key (the balance baseline; +2 floor ≈ ilvl116)
  const party = (ilvl) => [
    mk("p1", "Grymdark", "guardian", ilvl), mk("p2", "Svenrik", "cleric", ilvl),
    mk("p3", "Bramblewen", "lifebinder", ilvl), mk("p4", "Sythe", "assassin", ilvl),
    mk("p5", "Emberkin", "pyromancer", ilvl),
  ]
  const pinInterrupts = { interrupts: 3, positioning: 0, cooldowns: 3, killorder: 0 } // the intended 6/max-3 spend
  const noInterrupts  = { interrupts: 0, positioning: 3, cooldowns: 3, killorder: 0 } // same budget, wrong dial

  console.log("=== Bellreach Sanctum — interrupt read (affixes: fortified+bursting, gear-appropriate ilvl) ===")
  const fmt = (label, r) =>
    `  ${label} → ${r.outcome.padEnd(9)} dur=${r.durationSec}s timer=${r.timerSec}s deaths=${String(r.deaths.length).padStart(2)}` +
    `  | testsInterrupts=${count(r, /tests Interrupts/)} castsThrough=${count(r, /goes through/i)}`
  for (const key of [2, 7, 12, 16]) {
    const ilvl = ilvlFor(key)
    const good = run(party(ilvl), key, pinInterrupts)
    const bad = run(party(ilvl), key, noInterrupts)
    console.log(`\n+${key} @ilvl${ilvl}${key === 2 ? "  (the +2 floor — must time)" : ""}`)
    console.log(fmt("Interrupts 3 (+Cooldowns 3)", good))
    console.log(fmt("Interrupts 0 (points misspent)", bad))
  }

  console.log("\n=== Interrupt read under Yolo aggression (cast tax ×1.4 — where the dial should bite) ===")
  for (const key of [7, 9, 11]) {
    const ilvl = ilvlFor(key)
    const good = run(party(ilvl), key, pinInterrupts, { aggression: "Yolo" })
    const bad = run(party(ilvl), key, noInterrupts, { aggression: "Yolo" })
    console.log(`\n+${key} @ilvl${ilvl} (Yolo)`)
    console.log(fmt("Interrupts 3", good))
    console.log(fmt("Interrupts 0", bad))
  }
} finally {
  await server.close()
}
