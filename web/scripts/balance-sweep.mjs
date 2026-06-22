// Season balance audit — 10 compositions x 6 dungeons x keys 2..15 x 3 seeds, each at gear-appropriate ilvl (108+4k)
// with the dungeon's INTENDED tactic spend. Reports each comp's timed ceiling per dungeon (highest key timing >=2/3
// seeds), so we can see: (1) does the intended comp+settings cap ~1-2 keys above off-meta? (2) any anomaly dungeon/comp?
// (3) the ceiling curve, to inform loot/ilvl per key. Aggression = Balanced throughout (an aggression sweep is separate).
import { createServer } from "vite"

const server = await createServer({ server: { middlewareMode: true }, appType: "custom", logLevel: "error" })
try {
  const { runDungeonEGM } = await server.ssrLoadModule("/src/sim/egm/engine.ts")
  await server.ssrLoadModule("/src/content/index.ts")
  const ilvlFor = (k) => 108 + 4 * k
  const m = (specId) => (ilvl) => ({ specId, ilvl })
  // 10 comps (1T/1H/3DPS unless noted). Tanks: guardian/crusader/mystic. Healers: cleric(burst)/lifebinder(HoT).
  // DPS: assassin(phys ST), berserker(phys cleave), bard→ARCHER(phys ranged ST — P.1b recut, spec id still 'bard'), pyromancer(magic AoE), arcanist(magic CC/AoE).
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
  // Each dungeon's intended tactic spend (6 pts / max 3).
  const DUNGEONS = [
    { id: "ashveil-crypts",   tac: { interrupts: 2, positioning: 1, cooldowns: 2, killorder: 1 } },
    { id: "bellreach-sanctum", tac: { interrupts: 3, positioning: 0, cooldowns: 3, killorder: 0 } },
    { id: "stillhour-abbey",  tac: { interrupts: 0, positioning: 3, cooldowns: 3, killorder: 0 } },
    { id: "weltering-mire",   tac: { interrupts: 0, positioning: 0, cooldowns: 3, killorder: 3 } },
    { id: "pyreward-ossuary", tac: { interrupts: 0, positioning: 3, cooldowns: 3, killorder: 0 } },
    { id: "hour-of-bells",    tac: { interrupts: 0, positioning: 0, cooldowns: 3, killorder: 3 } },
  ]
  const seeds = [7, 13, 42]
  const KEYS = []
  for (let k = 2; k <= 15; k++) KEYS.push(k)

  const timedCount = (dungeonId, specs, key, tac) => {
    let n = 0
    for (const s of seeds) {
      const r = runDungeonEGM({ dungeonId, keyLevel: key, affixIds: ["fortified", "bursting"], party: party(specs, ilvlFor(key)), tactics: tac, aggression: "Balanced", seed: s })
      if (r.outcome === "timed") n++
    }
    return n
  }

  const ceil = {} // dungeonId -> compName -> ceiling
  for (const d of DUNGEONS) {
    ceil[d.id] = {}
    console.log(`\n=== ${d.id}  tac=${JSON.stringify(d.tac)}  — timed/3 per key ===`)
    for (const [name, specs] of Object.entries(COMPS)) {
      const cells = []
      let c = 1
      for (const k of KEYS) {
        const t = timedCount(d.id, specs, k, d.tac)
        cells.push(`${t}`)
        if (t >= 2) c = k
      }
      ceil[d.id][name] = c
      console.log(`  ${name} | ${cells.join(" ")} | ceiling +${c}`)
    }
  }

  // Final matrix: comp (rows) x dungeon (cols) -> ceiling
  const dcols = DUNGEONS.map((d) => d.id.split("-")[0].slice(0, 8).padStart(8))
  console.log(`\n\n===== CEILING MATRIX (timed ceiling, +key) =====`)
  console.log(`comp            | ${dcols.join(" | ")} | avg`)
  for (const name of Object.keys(COMPS)) {
    const vals = DUNGEONS.map((d) => ceil[d.id][name])
    const avg = (vals.reduce((a, b) => a + b, 0) / vals.length).toFixed(1)
    console.log(`${name} | ${vals.map((v) => String(v).padStart(8)).join(" | ")} | ${avg}`)
  }
  // Per-dungeon best comp + spread
  console.log(`\n===== PER-DUNGEON best/worst ceiling =====`)
  for (const d of DUNGEONS) {
    const entries = Object.entries(ceil[d.id]).sort((a, b) => b[1] - a[1])
    const best = entries[0], worst = entries[entries.length - 1]
    console.log(`  ${d.id.padEnd(16)} best ${best[0].trim()} +${best[1]}  | worst ${worst[0].trim()} +${worst[1]}  | spread ${best[1] - worst[1]}`)
  }
} finally {
  await server.close()
}
