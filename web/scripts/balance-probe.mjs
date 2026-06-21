// Fast balance-iteration probe — 4 diagnostic comps x 3 discriminating dungeons. Reports each comp's timed ceiling and
// the spread (max-min). Goal of the balance pass: shrink the spread from ~7-12 keys to ~2-3, with the no-utility comp
// only ~1-2 below the rest. Re-run after each tuning change. (Full audit = balance-sweep.mjs.)
import { createServer } from "vite"

const server = await createServer({ server: { middlewareMode: true }, appType: "custom", logLevel: "error" })
try {
  const { runDungeonEGM } = await server.ssrLoadModule("/src/sim/egm/engine.ts")
  await server.ssrLoadModule("/src/content/index.ts")
  const ilvlFor = (k) => 108 + 4 * k
  const COMPS = {
    "Meta-Cleric (no-util)": ["guardian", "cleric", "assassin", "pyromancer", "berserker"],
    "MagicHeavy (dps-util) ": ["guardian", "cleric", "assassin", "pyromancer", "arcanist"],
    "TwoHealer             ": ["guardian", "cleric", "lifebinder", "assassin", "pyromancer"],
    "CrusaderTank (max-util)": ["crusader", "lifebinder", "assassin", "pyromancer", "arcanist"],
  }
  const party = (specs, ilvl) => specs.map((s, i) => ({ id: `p${i}`, name: `${s}${i}`, specId: s, ilvl, morale: 60, traitIds: [] }))
  const DUNGEONS = [
    { id: "ashveil-crypts",   tac: { interrupts: 2, positioning: 1, cooldowns: 2, killorder: 1 } },
    { id: "bellreach-sanctum", tac: { interrupts: 3, positioning: 0, cooldowns: 3, killorder: 0 } },
    { id: "pyreward-ossuary", tac: { interrupts: 0, positioning: 3, cooldowns: 3, killorder: 0 } },
  ]
  const seeds = [7, 42]
  const ceilOf = (dungeonId, specs, tac) => {
    let c = 1
    for (let k = 2; k <= 20; k++) {
      let timed = 0
      for (const s of seeds) if (runDungeonEGM({ dungeonId, keyLevel: k, affixIds: ["fortified", "bursting"], party: party(specs, ilvlFor(k)), tactics: tac, aggression: "Balanced", seed: s }).outcome === "timed") timed++
      if (timed >= 2) c = k
    }
    return c
  }
  for (const d of DUNGEONS) {
    const row = {}
    for (const [name, specs] of Object.entries(COMPS)) row[name] = ceilOf(d.id, specs, d.tac)
    const vals = Object.values(row)
    const spread = Math.max(...vals) - Math.min(...vals)
    console.log(`\n${d.id.padEnd(17)} spread=${spread}`)
    for (const [name, c] of Object.entries(row)) console.log(`   ${name} +${c}`)
  }
} finally {
  await server.close()
}
