// M8 talent power-equality harness. For every spec, sweep each tier's 3 options (others left at default → resolveTalents
// falls back) and measure the option's POWER in a controlled comp on a trash (AoE) and a boss (single-target) dungeon.
//   DPS    → sum of the 3 spec instances' final cumulative damage (series cols 2-4).
//   Healer → the healer's final cumulative healing (healSeries col 1) + deaths, run at a STRESS key.
//   Tank   → the tank's own damage (series col 0) + comp deaths/timed, run at a STRESS key.
// Goal: within a tier, no option is DEAD (≈ a tiermate's floor with no upside in its content) or DOMINANT (higher in BOTH
// dungeons). Conditional options legitimately win in DIFFERENT content (AoE high on trash, execute high on boss) — that's fine.
import { createServer } from "vite"
const server = await createServer({ server: { middlewareMode: true }, appType: "custom", logLevel: "error" })
try {
  const { runDungeonEGM } = await server.ssrLoadModule("/src/sim/egm/engine.ts")
  const { content } = await server.ssrLoadModule("/src/content/index.ts")

  const ROLE = (s) => content.specs.get(s).role
  const ILVL = 140
  const SEEDS = [7, 13, 42]
  const TAC = { interrupts: 1, positioning: 1, cooldowns: 2, killorder: 2 }
  const KEY_DPS = 10     // 2 over gear → full clears but enough stress that clear-DURATION spreads (the real DPS signal)
  const KEY_DEF = 11     // stress key for tanks/healers → survival/healing options differentiate
  const mk = (specId, name, talents) => ({ id: name, name, specId, ilvl: ILVL, morale: 60, traitIds: [], skills: { execution: 8, awareness: 8, composure: 8 }, ...(talents ? { talents } : {}) })

  function setup(spec, build) {
    const r = ROLE(spec)
    if (r === "DPS") return { party: [mk("guardian","T"), mk("cleric","H"), mk(spec,"D1",build), mk(spec,"D2",build), mk(spec,"D3",build)], key: KEY_DPS, cols: [2,3,4], kind: "dmg" }
    if (r === "Healer") return { party: [mk("guardian","T"), mk(spec,"H",build), mk("assassin","D1"), mk("pyromancer","D2"), mk("berserker","D3")], key: KEY_DEF, cols: [1], kind: "heal" }
    return { party: [mk(spec,"T",build), mk("cleric","H"), mk("assassin","D1"), mk("pyromancer","D2"), mk("berserker","D3")], key: KEY_DEF, cols: [0], kind: "tank" }
  }

  function measure(spec, build, dungeonId) {
    const { party, key, cols, kind } = setup(spec, build)
    let dmg = 0, heal = 0, dur = 0, deaths = 0, timed = 0, n = 0
    for (const seed of SEEDS) {
      const res = runDungeonEGM({ dungeonId, keyLevel: key, affixIds: ["fortified", "bursting"], party, tactics: TAC, aggression: "Balanced", seed })
      const lastD = res.series[res.series.length - 1] ?? []
      const lastH = res.healSeries[res.healSeries.length - 1] ?? []
      dmg += cols.reduce((a, c) => a + (lastD[c] ?? 0), 0)
      heal += cols.reduce((a, c) => a + (lastH[c] ?? 0), 0)
      dur += res.durationSec; deaths += res.deaths.length; timed += res.outcome === "timed" ? 1 : 0; n++
    }
    return { dmg: Math.round(dmg / n), heal: Math.round(heal / n), dur: Math.round(dur / n), deaths: +(deaths / n).toFixed(1), timed, n, kind }
  }

  const bySpec = {}
  for (const node of content.talents.values()) { if (!node.specId) continue; (bySpec[node.specId] ??= {})[node.node] = node }

  const DUNGEONS = [["ashveil-crypts", "trash"], ["stillhour-abbey", "boss "]]
  // dur is the primary power signal (total HP is ~fixed in a timed clear, so FASTER = stronger). deaths/timed = survival.
  const cell = (o, m) => {
    const v = m.kind === "heal" ? `${String(m.dur).padStart(4)}s heal${String(m.heal).padStart(6)} d${m.deaths} ${m.timed}/${m.n}`
      : m.kind === "tank" ? `${String(m.dur).padStart(4)}s d${m.deaths} ${m.timed}/${m.n}`
      : `${String(m.dur).padStart(4)}s d${m.deaths}`
    return `${(o.name + (o.default ? "*" : "")).slice(0, 16).padEnd(16)} ${v}`
  }
  const only = process.argv[2]   // optional: a single specId to sweep
  for (const spec of Object.keys(bySpec)) {
    if (only && spec !== only) continue
    console.log(`\n=== ${spec} (${ROLE(spec)}) — key ${ROLE(spec) === "DPS" ? KEY_DPS : KEY_DEF} @ ilvl${ILVL} ===`)
    for (let t = 1; t <= 5; t++) {
      const node = bySpec[spec][t]; if (!node) continue
      console.log(` T${t} ${node.name}`)
      for (const [did, label] of DUNGEONS) {
        const cells = node.options.map((o) => cell(o, measure(spec, { [node.id]: o.id }, did)))
        console.log(`   [${label}] ${cells.join("  |  ")}`)
      }
    }
  }
} finally { await server.close() }
