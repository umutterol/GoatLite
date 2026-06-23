// Find a survivable-but-pressured (ilvl,key) point for op-verify's awareness/composure checks in the P.5c regime.
// The old key22/ilvl105 point is now an unwinnable total-wipe (death-count becomes a misleading proxy). We want a point
// where skill=1 struggles (wipes / more deaths / less HP) but skill=20 survives better — so the monotonic assertion holds.
import { createServer } from "vite"
const server = await createServer({ server: { middlewareMode: true }, appType: "custom", logLevel: "error" })
try {
  const { runDungeonEGM } = await server.ssrLoadModule("/src/sim/egm/engine.ts")
  const { content } = await server.ssrLoadModule("/src/content/index.ts")
  const save = content.save
  const sk = (e, a, c) => ({ execution: e, awareness: a, composure: c })
  const mk = (specId, name, skills, ilvl) => ({ id: name, name, specId, ilvl, morale: 60, traitIds: [], skills })
  const comp = (skills, ilvl) => [
    mk("guardian", "T", skills, ilvl), mk("cleric", "H", skills, ilvl), mk("lifebinder", "H2", skills, ilvl),
    mk("assassin", "D1", skills, ilvl), mk("pyromancer", "D2", skills, ilvl),
  ]
  const run = (skills, ilvl, key) => runDungeonEGM({ dungeonId: save.keystone.dungeonId, keyLevel: key, affixIds: save.week.affixes, party: comp(skills, ilvl), tactics: { interrupts: 2, positioning: 1, cooldowns: 1, killorder: 2 }, aggression: "Balanced", seed: 4242 })
  const sumHp = (r) => Math.round(r.finalHpPct.reduce((a, h) => a + h.pct, 0) / r.finalHpPct.length)
  const line = (label, r) => `${label} ${r.outcome.padEnd(8)} deaths=${r.deaths.length} hp=${sumHp(r)}%`
  for (const ilvl of [105, 120]) {
    for (let k = 6; k <= 18; k += 2) {
      const a1 = run(sk(4, 1, 4), ilvl, k), a20 = run(sk(4, 20, 4), ilvl, k)
      const c1 = run(sk(4, 4, 1), ilvl, k), c20 = run(sk(4, 4, 20), ilvl, k)
      const awOk = a20.deaths.length <= a1.deaths.length && sumHp(a20) >= sumHp(a1) && (a1.deaths.length > 0 || sumHp(a1) < 100)
      const coOk = c20.deaths.length <= c1.deaths.length && sumHp(c20) >= sumHp(c1) && (c1.deaths.length > 0 || sumHp(c1) < 100)
      console.log(`ilvl${ilvl} +${String(k).padStart(2)} | AW ${awOk ? "✓" : "·"} [${line("1:", a1)} | ${line("20:", a20)}]  CO ${coOk ? "✓" : "·"} [${line("1:", c1)} | ${line("20:", c20)}]`)
    }
    console.log("")
  }
} finally {
  await server.close()
}
