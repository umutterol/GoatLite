import { createServer } from "vite"

const server = await createServer({ server: { middlewareMode: true }, appType: "custom", logLevel: "error" })
try {
  const { runDungeonEGM } = await server.ssrLoadModule("/src/sim/egm/engine.ts")
  const { content } = await server.ssrLoadModule("/src/content/index.ts")
  const save = content.save

  const AFFIXES = ["fortified", "bursting", "spiteful"]
  const KEY = 14
  const ILVL = Number(process.env.ILVL ?? 115)
  const MORALE = Number(process.env.MORALE ?? 60)
  const mk = (id, name, specId) => ({ id, name, specId, ilvl: ILVL, morale: MORALE, traitIds: [] })
  const party = () => [
    mk("p1", "Mystic", "mystic"), mk("p2", "Lifebinder", "lifebinder"),
    mk("p3", "Bard", "bard"), mk("p4", "Pyromancer", "pyromancer"), mk("p5", "Assassin", "assassin"),
  ]
  const SEEDS = [12345, 7, 99, 2024, 31337]
  const run = (tac, aggr, seed) => runDungeonEGM({
    dungeonId: save.keystone.dungeonId, keyLevel: KEY, affixIds: AFFIXES, party: party(),
    tactics: { interrupts: tac, positioning: tac, cooldowns: tac, killorder: tac },
    aggression: aggr, seed,
  })

  console.log(`+${KEY} ${AFFIXES.join("/")}  ilvl${ILVL} morale${MORALE}  timer=${run(1,"Balanced",7).timerSec}s  (avg of ${SEEDS.length} seeds)`)
  console.log("tactics | aggr     | outcome           | avgDur  avgOver  avgDeaths")
  for (const tac of [0, 1, 2, 3]) for (const aggr of ["Safe", "Balanced", "Yolo"]) {
    const res = SEEDS.map((s) => run(tac, aggr, s))
    const timed = res.filter((r) => r.outcome === "timed").length
    const dep = res.filter((r) => r.outcome === "depleted").length
    const avgDur = Math.round(res.reduce((a, r) => a + r.durationSec, 0) / res.length)
    const avgOver = Math.round(res.reduce((a, r) => a + Math.max(0, r.durationSec - r.timerSec), 0) / res.length)
    const avgDeaths = (res.reduce((a, r) => a + r.deaths.length, 0) / res.length).toFixed(1)
    const mark = dep > 0 ? "  <-- depleted" : ""
    console.log(`   ${tac}    | ${aggr.padEnd(8)} | ${timed} timed / ${dep} depl | ${String(avgDur).padStart(5)}  +${String(avgOver).padStart(3)}s    ${avgDeaths}${mark}`)
  }
} finally {
  await server.close()
}
