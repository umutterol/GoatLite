// P.5c full-season sweep — 10 comps × 6 dungeons → key 20 (balance-sweep extended past its +15 cap, which hid the
// easy-dungeon ceilings). Like p5c-regime.mjs it can patch tuning.sim.{enemyDmgMult,hpUnit,keyScalingPerLevel} per
// process via argv (omit → committed tuning). Reports the ceiling matrix + per-dungeon best/worst + spread, and a
// spec-diversity lens (physical-heavy vs magic-heavy vs 2-healer comps).
//
//   node scripts/p5c-sweep.mjs [enemyDmgMult] [hpUnit] [keyScalingPerLevel]
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
  const { runDungeonEGM } = await server.ssrLoadModule("/src/sim/egm/engine.ts")
  console.log(`=== P.5c sweep  enemyDmgMult=${sim.enemyDmgMult}  hpUnit=${sim.hpUnit}  keyScalingPerLevel=${sim.keyScalingPerLevel} ===`)

  const ilvlFor = (k) => 108 + 4 * k
  const COMPS = {
    "Meta-Cleric    ": ["guardian", "cleric", "assassin", "pyromancer", "berserker"],
    "Meta-Lifebinder": ["guardian", "lifebinder", "assassin", "pyromancer", "berserker"],
    "AllPhysDPS     ": ["guardian", "cleric", "assassin", "berserker", "bard"],
    "MagicHeavyDPS  ": ["guardian", "cleric", "assassin", "pyromancer", "arcanist"],
    "AoE-Stack      ": ["guardian", "cleric", "pyromancer", "arcanist", "berserker"],
    "TwoHealer      ": ["guardian", "cleric", "lifebinder", "assassin", "pyromancer"],
    "MysticTank     ": ["mystic", "cleric", "assassin", "pyromancer", "berserker"],
    "CrusaderTank   ": ["crusader", "lifebinder", "assassin", "pyromancer", "arcanist"],
    "ArcherMix      ": ["guardian", "cleric", "assassin", "pyromancer", "bard"],
    "LifebinderMagic": ["guardian", "lifebinder", "pyromancer", "arcanist", "assassin"],
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
  const ceilOf = (dungeonId, specs, tac) => {
    let c = 1
    for (let k = 2; k <= 20; k++) {
      let t = 0
      for (const s of seeds) if (runDungeonEGM({ dungeonId, keyLevel: k, affixIds: ["fortified", "bursting"], party: party(specs, ilvlFor(k)), tactics: tac, aggression: "Balanced", seed: s }).outcome === "timed") t++
      if (t >= 2) c = k
    }
    return c
  }
  const ceil = {}
  for (const d of DUNGEONS) { ceil[d.id] = {}; for (const [n, s] of Object.entries(COMPS)) ceil[d.id][n] = ceilOf(d.id, s, d.tac) }

  console.log(`\ncomp            | ${DUNGEONS.map((d) => d.id.split("-")[0].slice(0, 8).padStart(8)).join(" | ")} | avg`)
  for (const name of Object.keys(COMPS)) {
    const vals = DUNGEONS.map((d) => ceil[d.id][name])
    console.log(`${name} | ${vals.map((v) => String(v).padStart(8)).join(" | ")} | ${(vals.reduce((a, b) => a + b, 0) / vals.length).toFixed(1)}`)
  }
  console.log(`\nper-dungeon best/worst/spread:`)
  for (const d of DUNGEONS) {
    const e = Object.entries(ceil[d.id]).sort((a, b) => b[1] - a[1])
    console.log(`  ${d.id.padEnd(18)} best ${e[0][0].trim()}+${e[0][1]}  worst ${e[e.length - 1][0].trim()}+${e[e.length - 1][1]}  spread ${e[0][1] - e[e.length - 1][1]}`)
  }
} finally {
  await server.close()
}
