// P.5c regime-shift experiment harness.
// Patches tuning.sim.{enemyDmgMult,hpUnit,keyScalingPerLevel} BEFORE the engine module evaluates
// (engine/stats read SIM constants at import time), so each PROCESS tests one candidate triple without
// editing tuning.json. Run several in parallel (background) to sweep candidates.
//
//   node scripts/p5c-regime.mjs [enemyDmgMult] [hpUnit] [keyScalingPerLevel]
//   (omit any arg → keep the live tuning.json value)
//
// Reports, for the 4 diagnostic comps across all 6 dungeons (keys 2..20, gear-appropriate ilvl):
//   - per-dungeon timed ceiling per comp + spread (max-min)
//   - the CEILING MATRIX + per-comp avg (generic-EHP comps should NOT top the no-util comp)
//   - the +2 floor (all 4 comps, 3 seeds, timed/3 — must stay 3/3)
import { createServer } from "vite"

const arg = (i) => (process.argv[i + 2] !== undefined ? Number(process.argv[i + 2]) : undefined)
const EDM = arg(0), HPU = arg(1), KSL = arg(2)

const server = await createServer({ server: { middlewareMode: true }, appType: "custom", logLevel: "error" })
try {
  const { content } = await server.ssrLoadModule("/src/content/index.ts")
  const sim = content.tuning.sim
  if (EDM !== undefined) sim.enemyDmgMult = EDM
  if (HPU !== undefined) sim.hpUnit = HPU
  if (KSL !== undefined) sim.keyScalingPerLevel = KSL
  // engine/stats evaluate SIM constants at first import → must load AFTER the patch
  const { runDungeonEGM } = await server.ssrLoadModule("/src/sim/egm/engine.ts")

  console.log(`=== P.5c regime  enemyDmgMult=${sim.enemyDmgMult}  hpUnit=${sim.hpUnit}  keyScalingPerLevel=${sim.keyScalingPerLevel} ===`)

  const ilvlFor = (k) => 108 + 4 * k
  const COMPS = {
    "Meta-Cleric(no-util)": ["guardian", "cleric", "assassin", "pyromancer", "berserker"],
    "MagicHeavy(dps-util)": ["guardian", "cleric", "assassin", "pyromancer", "arcanist"],
    "TwoHealer           ": ["guardian", "cleric", "lifebinder", "assassin", "pyromancer"],
    "CrusaderTank(max-ut)": ["crusader", "lifebinder", "assassin", "pyromancer", "arcanist"],
  }
  const party = (specs, ilvl) => specs.map((s, i) => ({ id: `p${i}`, name: `${s}${i}`, specId: s, ilvl, morale: 60, traitIds: [] }))
  const DUNGEONS = [
    { id: "ashveil-crypts",    tac: { interrupts: 2, positioning: 1, cooldowns: 2, killorder: 1 } },
    { id: "bellreach-sanctum", tac: { interrupts: 3, positioning: 0, cooldowns: 3, killorder: 0 } },
    { id: "stillhour-abbey",   tac: { interrupts: 0, positioning: 3, cooldowns: 3, killorder: 0 } },
    { id: "weltering-mire",    tac: { interrupts: 0, positioning: 0, cooldowns: 3, killorder: 3 } },
    { id: "pyreward-ossuary",  tac: { interrupts: 0, positioning: 3, cooldowns: 3, killorder: 0 } },
    { id: "hour-of-bells",     tac: { interrupts: 0, positioning: 0, cooldowns: 3, killorder: 3 } },
  ]
  const seeds = [7, 42]
  const timedCount = (dungeonId, specs, k, tac, ss = seeds) => {
    let n = 0
    for (const s of ss) if (runDungeonEGM({ dungeonId, keyLevel: k, affixIds: ["fortified", "bursting"], party: party(specs, ilvlFor(k)), tactics: tac, aggression: "Balanced", seed: s }).outcome === "timed") n++
    return n
  }
  const ceilOf = (dungeonId, specs, tac) => {
    let c = 1
    for (let k = 2; k <= 20; k++) if (timedCount(dungeonId, specs, k, tac) >= 2) c = k
    return c
  }

  const ceil = {}
  for (const d of DUNGEONS) {
    ceil[d.id] = {}
    for (const [name, specs] of Object.entries(COMPS)) ceil[d.id][name] = ceilOf(d.id, specs, d.tac)
  }

  console.log(`\ncomp                 | ${DUNGEONS.map((d) => d.id.split("-")[0].slice(0, 8).padStart(8)).join(" | ")} | avg`)
  for (const name of Object.keys(COMPS)) {
    const vals = DUNGEONS.map((d) => ceil[d.id][name])
    const avg = (vals.reduce((a, b) => a + b, 0) / vals.length).toFixed(1)
    console.log(`${name} | ${vals.map((v) => String(v).padStart(8)).join(" | ")} | ${avg}`)
  }
  console.log(`\nper-dungeon spread (max-min ceiling across the 4 comps):`)
  for (const d of DUNGEONS) {
    const vals = Object.values(ceil[d.id])
    console.log(`  ${d.id.padEnd(18)} spread=${Math.max(...vals) - Math.min(...vals)}   [${Object.entries(ceil[d.id]).map(([n, c]) => `${n.trim()}+${c}`).join("  ")}]`)
  }

  // +2 floor — all 4 comps must time at starting gear (3 seeds)
  console.log(`\n+2 floor (gear-appropriate ilvl${ilvlFor(2)}, 3 seeds):`)
  for (const [name, specs] of Object.entries(COMPS)) {
    const t = timedCount("ashveil-crypts", specs, 2, DUNGEONS[0].tac, [7, 13, 42])
    console.log(`  ${name} ${t}/3 ${t === 3 ? "" : "  <-- FLOOR RISK"}`)
  }
} finally {
  await server.close()
}
