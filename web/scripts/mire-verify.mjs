// P.3 final verification at the shipped tuning (data/tuning.json: rotFrac 0.04, curseBase 0.06). Confirms with 5 seeds:
// (1) the Mire tool tax (lifebinder right vs cleric wrong) lands in +3..+5 and is curse-dominated; (2) Stillhour is the
// control (no curse → healers ~equal); (3) the mechanism — lifebinder dispels (stacks stay low → times) where the cleric
// can't (stacks max out → wipes); (4) the +2 floor times for both.
import { createServer } from "vite"
const server = await createServer({ server: { middlewareMode: true }, appType: "custom", logLevel: "error" })
try {
  const { runDungeonEGM } = await server.ssrLoadModule("/src/sim/egm/engine.ts")
  await server.ssrLoadModule("/src/content/index.ts")
  const mk = (id, name, specId, ilvl) => ({ id, name, specId, ilvl, morale: 60, traitIds: [] })
  const ilvlFor = (k) => 108 + 4 * k
  const dps = (ilvl) => [mk("d1", "Sythe", "assassin", ilvl), mk("d2", "Emberkin", "pyromancer", ilvl), mk("d3", "Korga", "berserker", ilvl)]
  const comp = (h, ilvl) => [mk("t", "Grymdark", "guardian", ilvl), mk("h", "Healer", h, ilvl), ...dps(ilvl)]
  const spend = { interrupts: 0, positioning: 3, cooldowns: 3, killorder: 0 }
  const seeds = [7, 13, 42, 101, 2024]
  const run = (dungeonId, h, key, seed) => runDungeonEGM({ dungeonId, keyLevel: key, affixIds: ["fortified", "bursting"], party: comp(h, ilvlFor(key)), tactics: spend, aggression: "Balanced", seed })
  const ceil = (dungeonId, h) => { let c = 1, row = []; for (let k = 2; k <= 26; k++) { let t = 0; for (const s of seeds) if (run(dungeonId, h, k, s).outcome === "timed") t++; if (t >= 3) c = k; row.push(`+${String(k).padStart(2)}:${t}`) } return { c, row: row.join(" ") } }
  const maxStack = (r) => { let m = 0; for (const l of r.log) { const x = /creeps deeper \((\d+) stack/.exec(l.text); if (x) m = Math.max(m, +x[1]) } return m }

  for (const [d, label] of [["weltering-mire", "MIRE (P4 curse — right=lifebinder)"], ["stillhour-abbey", "STILLHOUR (control — no curse)"]]) {
    const lb = ceil(d, "lifebinder"), cl = ceil(d, "cleric")
    console.log(`\n=== ${label}  — seeds timed/${seeds.length}, gear-appropriate ilvl ===`)
    console.log(`  lifebinder: ${lb.row}   ceiling +${lb.c}`)
    console.log(`  cleric    : ${cl.row}   ceiling +${cl.c}`)
    console.log(`  >> ${d === "weltering-mire" ? "tool tax" : "control gap"} = +${lb.c - cl.c}`)
  }

  console.log("\n=== Mechanism (weltering-mire) — curse stacks reached + outcome ===")
  for (const k of [16, 18, 20]) for (const h of ["lifebinder", "cleric"]) {
    const r = run("weltering-mire", h, k, 7)
    console.log(`  +${k} ${h.padEnd(10)} → ${r.outcome.padEnd(9)} dur=${r.durationSec}s deaths=${r.deaths.length} maxCurseStacks=${maxStack(r)}`)
  }
} finally {
  await server.close()
}
