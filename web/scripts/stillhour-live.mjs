// Stillhour Abbey live probe — verifies the burst-triage / spike-healing dungeon (C.1).
// Checks: (1) content still validates with Stillhour added, (2) the +2 floor times, (3) the spike READ:
// the spike bosses fire (tests Positioning/Cooldowns + spike events), and we contrast a burst Cleric vs a
// rolling-HoT Lifebinder healer, plus the spike-survival dial spend (Positioning+Cooldowns) vs points misspent.
// NB: like Bellreach, the abstract toll is soft at the +2 floor, so the read is expected to be log-visible
// (spike events + deaths-on-beats at higher keys) before the C.9 lethality pass sharpens it into a hard wall.
import { createServer } from "vite"

const server = await createServer({ server: { middlewareMode: true }, appType: "custom", logLevel: "error" })
try {
  const { runDungeonEGM } = await server.ssrLoadModule("/src/sim/egm/engine.ts")
  await server.ssrLoadModule("/src/content/index.ts") // throws here if any Stillhour cross-ref is broken
  const mk = (id, name, specId, ilvl) => ({ id, name, specId, ilvl, morale: 60, traitIds: [] })

  const run = (party, keyLevel, tactics, opts = {}) => runDungeonEGM({
    dungeonId: "stillhour-abbey", keyLevel,
    affixIds: opts.affixIds ?? ["fortified", "bursting"], party,
    tactics, aggression: opts.aggression ?? "Balanced", seed: opts.seed ?? 7,
  })
  const linesOf = (r) => r.log.map((l) => `${l.t} [${l.kind}] ${l.text}`)
  const count = (r, re) => linesOf(r).filter((l) => re.test(l)).length

  const ilvlFor = (key) => 108 + 4 * key
  const dps = (ilvl) => [mk("d1", "Sythe", "assassin", ilvl), mk("d2", "Emberkin", "pyromancer", ilvl), mk("d3", "Korga", "berserker", ilvl)]
  const clericComp = (ilvl) => [mk("t", "Grymdark", "guardian", ilvl), mk("h", "Svenrik", "cleric", ilvl), ...dps(ilvl)]      // burst triage
  const hotComp    = (ilvl) => [mk("t", "Grymdark", "guardian", ilvl), mk("h", "Bramblewen", "lifebinder", ilvl), ...dps(ilvl)] // rolling HoTs

  const spikeSpend = { interrupts: 0, positioning: 3, cooldowns: 3, killorder: 0 } // dodge single-victim + blunt party-wide toll
  const misspent   = { interrupts: 3, positioning: 0, cooldowns: 0, killorder: 3 } // points away from the spikes

  const fmt = (label, r) =>
    `  ${label.padEnd(26)} → ${r.outcome.padEnd(9)} dur=${r.durationSec}s deaths=${String(r.deaths.length).padStart(2)}` +
    `  | spikeEvents=${count(r, /damage spike|caught in it|falls on/)} testsCD\/Pos=${count(r, /tests (Cooldowns|Positioning)/)}`

  console.log("=== Stillhour Abbey — spike-heal read (fortified+bursting, gear-appropriate ilvl) ===")
  for (const key of [2, 7, 12]) {
    const ilvl = ilvlFor(key)
    console.log(`\n+${key} @ilvl${ilvl}${key === 2 ? "  (the +2 floor — must time)" : ""}`)
    console.log(fmt("Cleric (burst) + CD/Pos 3", run(clericComp(ilvl), key, spikeSpend)))
    console.log(fmt("Lifebinder (HoT) + CD/Pos 3", run(hotComp(ilvl), key, spikeSpend)))
    console.log(fmt("Cleric, spikes ignored", run(clericComp(ilvl), key, misspent)))
  }

  console.log("\n=== +2 floor robustness across seeds (Cleric must reliably time; Lifebinder should struggle) ===")
  for (const seed of [7, 13, 42, 99, 2024]) {
    const ilvl = ilvlFor(2)
    const c = run(clericComp(ilvl), 2, spikeSpend, { seed })
    const l = run(hotComp(ilvl), 2, spikeSpend, { seed })
    console.log(`  seed ${String(seed).padStart(4)} → Cleric ${c.outcome.padEnd(7)}(d${String(c.deaths.length).padStart(2)})   Lifebinder ${l.outcome.padEnd(7)}(d${String(l.deaths.length).padStart(2)})`)
  }
} finally {
  await server.close()
}
