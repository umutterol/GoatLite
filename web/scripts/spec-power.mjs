// P.5b spec-power probe — measure the magic>>physical imbalance. For each of the 5 DPS specs, run a controlled
// 1T/1H/3x[spec] comp and read its ceiling on a TRASH-heavy dungeon (Ashveil — AoE-favoring) vs a BOSS-spike dungeon
// (Stillhour — single-target). The gap across specs = the imbalance to close (target ~1-2 keys). Physical = berserker /
// assassin / archer(bard); Magic = pyromancer / arcanist. Identifies whether magic wins on trash (AoE), bosses, or both.
import { createServer } from "vite"
const server = await createServer({ server: { middlewareMode: true }, appType: "custom", logLevel: "error" })
try {
  const { runDungeonEGM } = await server.ssrLoadModule("/src/sim/egm/engine.ts")
  await server.ssrLoadModule("/src/content/index.ts")
  const mk = (id, name, specId, ilvl) => ({ id, name, specId, ilvl, morale: 60, traitIds: [] })
  const ilvlFor = (k) => 108 + 4 * k
  const comp = (spec, ilvl) => [mk("t","Grymdark","guardian",ilvl), mk("h","Svenrik","cleric",ilvl), mk("d1",spec+"1",spec,ilvl), mk("d2",spec+"2",spec,ilvl), mk("d3",spec+"3",spec,ilvl)]
  const SPECS = [["berserker","phys"],["assassin","phys"],["bard","phys(archer)"],["pyromancer","magic"],["arcanist","magic"]]
  const seeds = [7, 13, 42]
  // neutral tactics so the dungeon mechanic isn't the binding constraint (we want raw DPS-clear)
  const tac = { interrupts: 1, positioning: 1, cooldowns: 2, killorder: 2 }
  const run = (dungeonId, spec, key, seed) => runDungeonEGM({ dungeonId, keyLevel: key, affixIds: ["fortified","bursting"], party: comp(spec, ilvlFor(key)), tactics: tac, aggression: "Balanced", seed })
  const ceil = (dungeonId, spec) => { let c = 1; for (let k = 2; k <= 22; k++) { let t = 0; for (const s of seeds) if (run(dungeonId, spec, k, s).outcome === "timed") t++; if (t >= 2) c = k } return c }

  for (const dungeon of ["ashveil-crypts", "stillhour-abbey"]) {
    console.log(`\n=== ${dungeon}  (1T/1H/3x[spec], neutral tactics, seeds timed/3) ===`)
    const res = SPECS.map(([s, kind]) => ({ s, kind, c: ceil(dungeon, s) }))
    for (const r of res) console.log(`  ${r.s.padEnd(11)} (${r.kind.padEnd(11)}): +${r.c}`)
    const cs = res.map((r) => r.c)
    console.log(`  >> spread ${Math.max(...cs) - Math.min(...cs)}  | magic avg ${(res.filter(r=>r.kind==="magic").reduce((a,r)=>a+r.c,0)/2).toFixed(1)} vs phys avg ${(res.filter(r=>r.kind.startsWith("phys")).reduce((a,r)=>a+r.c,0)/3).toFixed(1)}`)
  }
} finally {
  await server.close()
}
