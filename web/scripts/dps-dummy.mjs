// DPS-meta training-dummy harness. Runs each spec SOLO against a stage of N huge-HP / zero-damage front dummies and
// reads total damage output / duration = DPS, at N = 1 / 3 / 5 targets. Reuses the REAL engine loop (faithful rotation,
// majors, ramp, passives) by injecting synthetic content (cloned from validated objects) into the content Maps before
// the run. keyLevel 2 (keyScale 1; player damage is key-independent), fixed ilvl, Balanced, no affixes/tactics/talents/
// operator → an apples-to-apples raw-output measure. Single-target abilities hit the 1 front dummy; "all"/AoE hit every
// dummy, so AoE specs scale up with N while pure-ST specs stay flat — that profile IS the read.
import { createServer } from "vite"

const ILVL = Number(process.argv[2] ?? 150)
const RARITY = Number(process.argv[3] ?? 1)   // item-stats: effIlvl = ILVL × rarityMult (1.0 Common … 1.25 Epic) to show the gear spike
const SEC = Number(process.argv[4] ?? 0)      // item-stats M3: per-stat secondary RATING (haste/crit/critDmg/vers each), 0 = none
const server = await createServer({ server: { middlewareMode: true }, appType: "custom", logLevel: "error" })
try {
  const { content } = await server.ssrLoadModule("/src/content/index.ts")
  const { runDungeonEGM } = await server.ssrLoadModule("/src/sim/egm/engine.ts")

  // --- inject synthetic dummy content (clone validated objects so all required fields are present) ---
  const baseEnemy = structuredClone([...content.enemies.values()][0])
  const dummy = { ...baseEnemy, id: "dps-dummy", name: "Training Dummy", baseHp: 9_000_000, baseDamage: 0,
    armour: 0, resist: 0, band: "Front", guarding: false, shielded: false }
  delete dummy.abilityId; delete dummy.spikeProfile; delete dummy.summonsId; delete dummy.testsTactic; delete dummy.curse
  content.enemies.set("dps-dummy", dummy)

  const basePack = structuredClone([...content.packs.values()][0])
  const baseDungeon = structuredClone(content.dungeons.get("ashveil-crypts"))
  const TARGETS = [1, 3, 5]
  for (const n of TARGETS) {
    content.packs.set(`dps-pack-${n}`, { ...basePack, id: `dps-pack-${n}`, name: `Dummies x${n}`, tags: [`dps-${n}`], mobs: [{ enemyId: "dps-dummy", count: n }] })
    content.dungeons.set(`dps-${n}`, { ...baseDungeon, id: `dps-${n}`, name: `DPS Dummies x${n}`, timerSeconds: 120, slots: [{ kind: "trash", packTags: [`dps-${n}`] }] })
  }

  const SPECS = [...content.specs.values()].map((s) => ({ id: s.id, name: s.name, role: s.role }))
  const ROLE_ORDER = { Tank: 0, Healer: 1, DPS: 2 }
  const seeds = [7, 42, 101]
  const dpsOf = (specId, n) => {
    let sum = 0
    for (const seed of seeds) {
      const r = runDungeonEGM({ dungeonId: `dps-${n}`, keyLevel: 2, affixIds: [], aggression: "Balanced", seed,
        tactics: { interrupts: 0, positioning: 0, cooldowns: 0, killorder: 0 },
        party: [{ id: "m0", name: specId, specId, ilvl: ILVL, effIlvl: ILVL * RARITY, morale: 60, traitIds: [],
          secondaries: SEC ? { haste: SEC, critChance: SEC, critDamage: SEC, versatility: SEC } : undefined }] })
      const last = r.series.filter(Boolean).at(-1)
      sum += (last ? last[0] : 0) / Math.max(1, r.durationSec)
    }
    return Math.round(sum / seeds.length)
  }

  const rows = SPECS.map((s) => ({ ...s, d1: dpsOf(s.id, 1), d3: dpsOf(s.id, 3), d5: dpsOf(s.id, 5) }))
    .sort((a, b) => (ROLE_ORDER[a.role] - ROLE_ORDER[b.role]) || (b.d1 - a.d1))

  console.log(`=== DPS meta — solo spec vs N training dummies @ ilvl${ILVL} (rarityMult ${RARITY} → effIlvl ${ILVL * RARITY}), keyLevel 2, Balanced, no talents/operator (avg of ${seeds.length} seeds) ===`)
  console.log(`spec          role    |   1-tgt |   3-tgt |   5-tgt |  5T/1T (AoE scaling)`)
  for (const r of rows) {
    const scale = r.d1 > 0 ? (r.d5 / r.d1).toFixed(2) : "—"
    console.log(`${r.name.padEnd(13)} ${r.role.padEnd(6)} | ${String(r.d1).padStart(7)} | ${String(r.d3).padStart(7)} | ${String(r.d5).padStart(7)} | ${String(scale).padStart(5)}x`)
  }
} finally {
  await server.close()
}
