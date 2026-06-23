// P.5c per-dungeon +2 floor check. The +2 floor must reliably time at starting gear on EVERY dungeon for a
// gear-appropriate standard comp. Bellreach is the watch case (M2's Bulwark recost dropped the no-kicker Meta-Cleric),
// so we test BOTH a no-kicker standard comp AND a kicker comp (arcanist) there. Reports timed/6 per comp per dungeon
// at +2 (and +3/+4 for headroom). Reads committed tuning.
import { createServer } from "vite"

const server = await createServer({ server: { middlewareMode: true }, appType: "custom", logLevel: "error" })
try {
  const { runDungeonEGM } = await server.ssrLoadModule("/src/sim/egm/engine.ts")
  await server.ssrLoadModule("/src/content/index.ts")
  const ilvlFor = (k) => 108 + 4 * k
  const party = (specs, ilvl) => specs.map((s, i) => ({ id: `p${i}`, name: `${s}${i}`, specId: s, ilvl, morale: 60, traitIds: [] }))
  const STANDARD = ["guardian", "cleric", "assassin", "pyromancer", "berserker"]   // no reliable kicker
  const KICKER   = ["guardian", "cleric", "assassin", "pyromancer", "arcanist"]    // arcanist Counterspell
  const DUNGEONS = [
    { id: "ashveil-crypts",    tac: { interrupts: 2, positioning: 1, cooldowns: 2, killorder: 1 } },
    { id: "bellreach-sanctum", tac: { interrupts: 3, positioning: 0, cooldowns: 3, killorder: 0 } },
    { id: "stillhour-abbey",   tac: { interrupts: 0, positioning: 3, cooldowns: 3, killorder: 0 } },
    { id: "weltering-mire",    tac: { interrupts: 0, positioning: 0, cooldowns: 3, killorder: 3 } },
    { id: "pyreward-ossuary",  tac: { interrupts: 0, positioning: 3, cooldowns: 3, killorder: 0 } },
    { id: "hour-of-bells",     tac: { interrupts: 0, positioning: 0, cooldowns: 3, killorder: 3 } },
  ]
  const seeds = [7, 13, 42, 101, 202, 303]
  const timed = (dungeonId, specs, k, tac) => seeds.filter((s) => runDungeonEGM({ dungeonId, keyLevel: k, affixIds: ["fortified", "bursting"], party: party(specs, ilvlFor(k)), tactics: tac, aggression: "Balanced", seed: s }).outcome === "timed").length

  for (const k of [2, 3, 4]) {
    console.log(`\n=== +${k} floor (ilvl${ilvlFor(k)}, 6 seeds) — timed/6 ===`)
    for (const d of DUNGEONS) {
      const std = timed(d.id, STANDARD, k, d.tac)
      const kick = timed(d.id, KICKER, k, d.tac)
      const flag = std < 5 ? (kick >= 5 ? "  (std<5, kicker OK)" : "  <-- FLOOR RISK") : ""
      console.log(`  ${d.id.padEnd(18)} standard ${std}/6   kicker ${kick}/6${flag}`)
    }
  }
} finally {
  await server.close()
}
