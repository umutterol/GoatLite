// One-off: compare DPS specs head-to-head. 1 tank + 1 healer + 3x the test spec, fixed gear/key, several seeds.
// Reports avg damage per DPS + clear time + deaths — to confirm/deny "assassin seems problematic".
import { createServer } from "vite"
const server = await createServer({ server: { middlewareMode: true }, appType: "custom", logLevel: "error" })
try {
  const { runDungeonEGM } = await server.ssrLoadModule("/src/sim/egm/engine.ts")
  const { content } = await server.ssrLoadModule("/src/content/index.ts")
  const save = content.save
  const mk = (specId, name) => ({ id: name, name, specId, ilvl: 150, morale: 60, traitIds: [], skills: { execution: 4, awareness: 4, composure: 4 } })
  const DPS = ["berserker", "assassin", "bard", "pyromancer", "arcanist"]
  const SEEDS = [11, 22, 33, 44, 55, 66]
  console.log("spec       avgDpsDmg   clearSec  deaths   (1T guardian + 1H cleric + 3x spec, ilvl150 +8)")
  for (const sp of DPS) {
    const party = [mk("guardian", "T"), mk("cleric", "H"), mk(sp, "D1"), mk(sp, "D2"), mk(sp, "D3")]
    let dmg = 0, dur = 0, deaths = 0, n = 0
    for (const seed of SEEDS) {
      const r = runDungeonEGM({ dungeonId: save.keystone.dungeonId, keyLevel: 8, affixIds: save.week.affixes, party,
        tactics: { interrupts: 2, positioning: 1, cooldowns: 1, killorder: 2 }, aggression: "Balanced", seed })
      // sum the 3 DPS rows' actual parse + use total run damage proxy via series last column
      const last = r.series[r.series.length - 1] ?? []
      const dpsDmg = (last[2] ?? 0) + (last[3] ?? 0) + (last[4] ?? 0)
      dmg += dpsDmg; dur += r.durationSec; deaths += r.deaths.length; n++
    }
    console.log(`${sp.padEnd(11)} ${String(Math.round(dmg / n)).padStart(9)}   ${String(Math.round(dur / n)).padStart(6)}   ${(deaths / n).toFixed(1)}`)
  }
} finally { await server.close() }
