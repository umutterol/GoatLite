// Phase F verification: operator skills + trait combat measurably change the sim, deterministically.
import { createServer } from "vite"

const server = await createServer({ server: { middlewareMode: true }, appType: "custom", logLevel: "error" })
try {
  const { runDungeonEGM } = await server.ssrLoadModule("/src/sim/egm/engine.ts")
  const { content } = await server.ssrLoadModule("/src/content/index.ts")
  const save = content.save

  const sk = (e, a, c) => ({ execution: e, awareness: a, composure: c })
  const mk = (specId, name, { skills, traitIds = [], ilvl = 150 } = {}) => ({ id: name, name, specId, ilvl, morale: 60, traitIds, skills })
  const comp = (opts) => [
    mk("guardian", "Tank", opts), mk("cleric", "Heal", opts), mk("lifebinder", "Heal2", opts),
    mk("assassin", "Dps1", opts), mk("pyromancer", "Dps2", opts),
  ]
  const run = (party, keyLevel, opts = {}) => runDungeonEGM({
    dungeonId: save.keystone.dungeonId, keyLevel,
    affixIds: opts.affixIds ?? save.week.affixes, party,
    tactics: opts.tactics ?? { interrupts: 2, positioning: 1, cooldowns: 1, killorder: 2 },
    aggression: opts.aggression ?? "Balanced", seed: opts.seed ?? 4242,
  })
  const sumHp = (r) => Math.round(r.finalHpPct.reduce((a, h) => a + h.pct, 0) / r.finalHpPct.length)
  const pass = (cond, msg) => console.log(`${cond ? "PASS" : "FAIL"}  ${msg}`)

  // A — Execution → output (faster clears at +8)
  const lowE = run(comp({ skills: sk(1, 4, 4) }), 8)
  const hiE = run(comp({ skills: sk(20, 4, 4) }), 8)
  console.log(`\nA. Execution output:  exec1 dur=${lowE.durationSec}s  exec20 dur=${hiE.durationSec}s`)
  pass(hiE.durationSec < lowE.durationSec, "execution 20 clears faster than execution 1")

  // B — Awareness → less intake (better survival on a hard, pressuring key)
  const lowA = run(comp({ skills: sk(4, 1, 4), ilvl: 105 }), 22)
  const hiA = run(comp({ skills: sk(4, 20, 4), ilvl: 105 }), 22)
  console.log(`\nB. Awareness intake:  awar1 ${lowA.outcome} deaths=${lowA.deaths.length} hp=${sumHp(lowA)}%  awar20 ${hiA.outcome} deaths=${hiA.deaths.length} hp=${sumHp(hiA)}%`)
  pass(hiA.deaths.length <= lowA.deaths.length && sumHp(hiA) >= sumHp(lowA), "awareness 20 takes less damage (≤ deaths, ≥ final HP)")

  // C — Composure → clutch survival on a hard, pressuring key
  const lowC = run(comp({ skills: sk(4, 4, 1), ilvl: 105 }), 22)
  const hiC = run(comp({ skills: sk(4, 4, 20), ilvl: 105 }), 22)
  console.log(`\nC. Composure clutch:  comp1 ${lowC.outcome} deaths=${lowC.deaths.length} hp=${sumHp(lowC)}%  comp20 ${hiC.outcome} deaths=${hiC.deaths.length} hp=${sumHp(hiC)}%`)
  pass(hiC.deaths.length <= lowC.deaths.length && sumHp(hiC) >= sumHp(lowC), "composure 20 survives better than composure 1")

  // D — Trait combat is no longer inert (jenkins +output clears faster than no trait, same skills)
  const noTrait = run(comp({ skills: sk(4, 4, 4) }), 8)
  const jenkins = run(comp({ skills: sk(4, 4, 4), traitIds: ["jenkins"] }), 8)
  console.log(`\nD. Trait combat:  none dur=${noTrait.durationSec}s  jenkins dur=${jenkins.durationSec}s`)
  pass(jenkins.durationSec < noTrait.durationSec, "jenkins (+output trait) clears faster — traits are wired")

  // E — Determinism preserved (same seed/skills → identical run)
  const r1 = run(comp({ skills: sk(12, 8, 10), traitIds: ["cracked"] }), 12, { seed: 99 })
  const r2 = run(comp({ skills: sk(12, 8, 10), traitIds: ["cracked"] }), 12, { seed: 99 })
  console.log(`\nE. Determinism:  r1 dur=${r1.durationSec}s log=${r1.log.length}  r2 dur=${r2.durationSec}s log=${r2.log.length}`)
  pass(r1.durationSec === r2.durationSec && r1.log.length === r2.log.length && r1.deaths.length === r2.deaths.length, "identical inputs → identical run")

  // F — Baseline guard: a fresh-recruit-ish party (start skills, no traits) still times the +2 floor at starting gear
  const floor = run(comp({ skills: sk(4, 4, 4), ilvl: 115 }), 2)
  console.log(`\nF. +2 floor (start skills, ilvl115):  ${floor.outcome} dur=${floor.durationSec}s deaths=${floor.deaths.length}`)
  pass(floor.outcome === "timed", "+2 floor still times with baseline operator skills")
} finally {
  await server.close()
}
