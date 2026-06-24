// Experiment: how does stacking Crit Chance + Crit Damage on Assassin compare to other secondary allocations?
// Same total secondary budget (1200 rating), allocated different ways, on a single training dummy (ST). Epic ilvl160.
import { createServer } from "vite"
const server = await createServer({ server: { middlewareMode: true }, appType: "custom", logLevel: "error" })
try {
  const { content } = await server.ssrLoadModule("/src/content/index.ts")
  const { runDungeonEGM } = await server.ssrLoadModule("/src/sim/egm/engine.ts")
  const base = structuredClone([...content.enemies.values()][0])
  content.enemies.set("dps-dummy", { ...base, id: "dps-dummy", name: "Dummy", baseHp: 9_000_000, baseDamage: 0, armour: 0, resist: 0, band: "Front", guarding: false, shielded: false })
  const bp = structuredClone([...content.packs.values()][0])
  content.packs.set("dps-pack-1", { ...bp, id: "dps-pack-1", name: "Dummy", tags: ["dps-1"], mobs: [{ enemyId: "dps-dummy", count: 1 }] })
  const bd = structuredClone(content.dungeons.get("ashveil-crypts"))
  content.dungeons.set("dps-1", { ...bd, id: "dps-1", name: "Dummy", timerSeconds: 120, slots: [{ kind: "trash", packTags: ["dps-1"] }] })

  const K = 20   // SECONDARY_RATING_K
  const seeds = [7, 42, 101]
  const run = (spec, sec) => {
    let sum = 0
    for (const seed of seeds) {
      const r = runDungeonEGM({ dungeonId: "dps-1", keyLevel: 2, affixIds: [], aggression: "Balanced", seed,
        tactics: { interrupts: 0, positioning: 0, cooldowns: 0, killorder: 0 },
        party: [{ id: "m0", name: spec, specId: spec, ilvl: 160, effIlvl: 160 * 1.25, morale: 60, traitIds: [], secondaries: sec }] })
      const last = r.series.filter(Boolean).at(-1)
      sum += (last ? last[0] : 0) / Math.max(1, r.durationSec)
    }
    return Math.round(sum / seeds.length)
  }
  const critStats = (s) => `crit ${(5 + (s.critChance ?? 0) / K).toFixed(0)}% @ ${(2.0 + (s.critDamage ?? 0) / K / 100).toFixed(2)}x`
  const PROFILES = [
    ["no secondaries     ", {}],
    ["even (300 ea x4)   ", { haste: 300, critChance: 300, critDamage: 300, versatility: 300 }],
    ["haste-stack (1200) ", { haste: 1200 }],
    ["versatility (1200) ", { versatility: 1200 }],
    ["CRIT-STACK 600/600 ", { critChance: 600, critDamage: 600 }],
    ["crit-chance only   ", { critChance: 1200 }],
    ["crit-damage only   ", { critDamage: 1200 }],
    ["chance-heavy 800/400", { critChance: 800, critDamage: 400 }],
  ]
  for (const spec of ["assassin", "berserker"]) {
    console.log(`\n=== ${spec.toUpperCase()} — Epic ilvl160 (effIlvl 200), single target, 1200 secondary budget ===`)
    const none = run(spec, {})
    for (const [label, sec] of PROFILES) {
      const dps = run(spec, sec)
      const dpct = none ? `${dps >= none ? "+" : ""}${Math.round((dps / none - 1) * 100)}%` : ""
      console.log(`  ${label} | ${String(dps).padStart(4)} DPS  ${dpct.padStart(5)}  | ${critStats(sec)}`)
    }
  }
} finally { await server.close() }
