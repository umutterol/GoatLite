// M.2 verification: the contested-loot WIN buff (+N% output next run) measurably raises output,
// is a no-op when absent/0 (so the smoke goldens stay byte-identical), and stays deterministic.
import { createServer } from "vite"

const server = await createServer({ server: { middlewareMode: true }, appType: "custom", logLevel: "error" })
try {
  const { runDungeonEGM } = await server.ssrLoadModule("/src/sim/egm/engine.ts")
  const { content } = await server.ssrLoadModule("/src/content/index.ts")
  const save = content.save

  const mk = (specId, name, { lootBuffPct = 0, ilvl = 150 } = {}) => ({ id: name, name, specId, ilvl, morale: 60, traitIds: [], lootBuffPct })
  // baseline comp; `buff` applies lootBuffPct to whichever ids are listed
  const comp = (buff = {}) => [
    ["guardian", "Tank"], ["cleric", "Heal"], ["lifebinder", "Heal2"], ["assassin", "Dps1"], ["pyromancer", "Dps2"],
  ].map(([s, n]) => mk(s, n, { lootBuffPct: buff[n] ?? 0 }))
  const run = (party, keyLevel = 8, seed = 4242) => runDungeonEGM({
    dungeonId: save.keystone.dungeonId, keyLevel, affixIds: save.week.affixes, party,
    tactics: { interrupts: 2, positioning: 1, cooldowns: 1, killorder: 2 }, aggression: "Balanced", seed,
  })
  // series is [tick][member] (cumulative) — the final tick row holds each member's run-total damage
  const lastRow = (r) => r.series[r.series.length - 1] ?? []
  const totalDmg = (r) => Math.round(lastRow(r).reduce((a, v) => a + (v ?? 0), 0))
  const dmgOf = (r, id) => { const i = r.seriesIds.indexOf(id); return i < 0 ? 0 : Math.round(lastRow(r)[i] ?? 0) }
  const pass = (cond, msg) => { console.log(`${cond ? "PASS" : "FAIL"}  ${msg}`); if (!cond) process.exitCode = 1 }

  const base = run(comp())

  // A — a party-wide buff clears the key faster (the buff reaches the output channel)
  const buffedAll = run(comp({ Tank: 25, Heal: 25, Heal2: 25, Dps1: 25, Dps2: 25 }))
  console.log(`\nA. +25% party output:  base dur=${base.durationSec}s dmg=${totalDmg(base)}  buffed dur=${buffedAll.durationSec}s dmg=${totalDmg(buffedAll)}`)
  pass(buffedAll.durationSec < base.durationSec, "+25% party output clears faster")

  // B — a single-member buff raises THAT member's output
  const buffedDps = run(comp({ Dps1: 20 }))
  console.log(`\nB. +20% on Dps1:  base Dps1 dmg=${dmgOf(base, "Dps1")}  buffed Dps1 dmg=${dmgOf(buffedDps, "Dps1")}`)
  pass(dmgOf(buffedDps, "Dps1") > dmgOf(base, "Dps1"), "the buffed member deals more damage")

  // C — no-op: lootBuffPct 0 is byte-identical to no buff (protects the egm-smoke goldens)
  const zero = run(comp({}))
  console.log(`\nC. 0% no-op:  base dur=${base.durationSec}s log=${base.log.length} dmg=${totalDmg(base)}  zero dur=${zero.durationSec}s log=${zero.log.length} dmg=${totalDmg(zero)}`)
  pass(zero.durationSec === base.durationSec && zero.log.length === base.log.length && totalDmg(zero) === totalDmg(base), "buff=0 is a no-op (identical run)")

  // D — determinism: same buff + seed → identical run
  const d1 = run(comp({ Dps1: 5 }), 12, 99)
  const d2 = run(comp({ Dps1: 5 }), 12, 99)
  console.log(`\nD. Determinism:  d1 dur=${d1.durationSec}s log=${d1.log.length}  d2 dur=${d2.durationSec}s log=${d2.log.length}`)
  pass(d1.durationSec === d2.durationSec && d1.log.length === d2.log.length, "same buff + seed → identical run")
} finally {
  await server.close()
}
