// Healer-ceiling sweep — tunes the C.10 "soft healer preference" (burst→Cleric on Stillhour, rot→Lifebinder on the Mire).
// Goal ("bring the player, not the class"): BOTH healers clear low/mid keys cleanly; the RIGHT healer's timed ceiling is
// only ~1-2 key levels above the WRONG healer's. For each dungeon × healer it sweeps keys at gear-appropriate ilvl and
// prints how many seeds time per key. Read the ceiling = highest key still timing in most seeds; the right−wrong gap = the
// class advantage (target ~1-2). Below the ceiling both should read 3/3 (clean). Tune BURST_FRAC / ROT_FRAC in engine.ts.
import { createServer } from "vite"

const server = await createServer({ server: { middlewareMode: true }, appType: "custom", logLevel: "error" })
try {
  const { runDungeonEGM } = await server.ssrLoadModule("/src/sim/egm/engine.ts")
  await server.ssrLoadModule("/src/content/index.ts")
  const mk = (id, name, specId, ilvl) => ({ id, name, specId, ilvl, morale: 60, traitIds: [] })
  const ilvlFor = (k) => 108 + 4 * k
  const dps = (ilvl) => [mk("d1", "Sythe", "assassin", ilvl), mk("d2", "Emberkin", "pyromancer", ilvl), mk("d3", "Korga", "berserker", ilvl)]
  const comp = (healerSpec, ilvl) => [mk("t", "Grymdark", "guardian", ilvl), mk("h", "Healer", healerSpec, ilvl), ...dps(ilvl)]
  const spend = { interrupts: 0, positioning: 3, cooldowns: 3, killorder: 0 } // cooldowns mitigates both burst & rot
  const seeds = [7, 13, 42]
  const run = (dungeonId, party, key, seed) => runDungeonEGM({ dungeonId, keyLevel: key, affixIds: ["fortified", "bursting"], party, tactics: spend, aggression: "Balanced", seed })
  const sweep = (dungeonId, healerSpec) => {
    const cells = []
    for (let k = 2; k <= 16; k++) {
      let timed = 0
      for (const s of seeds) if (run(dungeonId, comp(healerSpec, ilvlFor(k)), k, s).outcome === "timed") timed++
      cells.push(`+${String(k).padStart(2)}:${timed}`)
    }
    return cells.join(" ")
  }
  for (const [dungeon, right, wrong] of [["stillhour-abbey", "cleric", "lifebinder"], ["weltering-mire", "lifebinder", "cleric"]]) {
    console.log(`\n=== ${dungeon}  (right healer = ${right})  — seeds timed / ${seeds.length}, gear-appropriate ilvl ===`)
    console.log(`  ${right.padEnd(10)} (right): ${sweep(dungeon, right)}`)
    console.log(`  ${wrong.padEnd(10)} (wrong): ${sweep(dungeon, wrong)}`)
  }
} finally {
  await server.close()
}
