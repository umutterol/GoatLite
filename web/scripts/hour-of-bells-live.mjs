// The Hour of Bells live probe (C.1) — the cooldowns-DIAL gauntlet (a player decision, not a class requirement).
// Checks: (1) content validates with the dungeon added, (2) the +2 floor times, (3) how much the Cooldowns dial moves
// the ceiling — sweeps a Cooldowns-3 spend vs a misspent (Cooldowns-0) spend. Like Bellreach, the abstract cooldowns
// spike is soft, so expect the dial to shift duration/ceiling modestly (sharpens with the C.9 lethality pass).
import { createServer } from "vite"

const server = await createServer({ server: { middlewareMode: true }, appType: "custom", logLevel: "error" })
try {
  const { runDungeonEGM } = await server.ssrLoadModule("/src/sim/egm/engine.ts")
  await server.ssrLoadModule("/src/content/index.ts") // throws if any Hour of Bells cross-ref is broken
  const mk = (id, name, specId, ilvl) => ({ id, name, specId, ilvl, morale: 60, traitIds: [] })
  const ilvlFor = (k) => 108 + 4 * k
  const party = (ilvl) => [
    mk("t", "Grymdark", "guardian", ilvl), mk("h", "Svenrik", "cleric", ilvl),
    mk("d1", "Sythe", "assassin", ilvl), mk("d2", "Emberkin", "pyromancer", ilvl), mk("d3", "Korga", "berserker", ilvl),
  ]
  const cd3 = { interrupts: 0, positioning: 0, cooldowns: 3, killorder: 3 } // mitigate the tolls + speed trash
  const cd0 = { interrupts: 3, positioning: 3, cooldowns: 0, killorder: 0 } // points away from the tolls
  const seeds = [7, 13, 42]
  const run = (tactics, key, seed) => runDungeonEGM({ dungeonId: "hour-of-bells", keyLevel: key, affixIds: ["fortified", "bursting"], party: ilvlFor(key) && party(ilvlFor(key)), tactics, aggression: "Balanced", seed })
  const linesOf = (r) => r.log.map((l) => `${l.t} [${l.kind}] ${l.text}`)
  const count = (r, re) => linesOf(r).filter((l) => re.test(l)).length

  const r0 = run(cd3, 2, 7)
  console.log(`=== The Hour of Bells — +2 floor (Cooldowns 3): ${r0.outcome} dur=${r0.durationSec}s timer=${r0.timerSec}s deaths=${r0.deaths.length} | tolls(spikes)=${count(r0, /damage spike/)} ===`)

  console.log("\n=== Cooldowns-dial ceiling sweep (seeds timed / 3, gear-appropriate ilvl) ===")
  const sweep = (tactics) => {
    const cells = []
    for (let k = 2; k <= 14; k++) {
      let timed = 0
      for (const s of seeds) if (run(tactics, k, s).outcome === "timed") timed++
      cells.push(`+${String(k).padStart(2)}:${timed}`)
    }
    return cells.join(" ")
  }
  console.log(`  Cooldowns 3 : ${sweep(cd3)}`)
  console.log(`  Cooldowns 0 : ${sweep(cd0)}`)
} finally {
  await server.close()
}
