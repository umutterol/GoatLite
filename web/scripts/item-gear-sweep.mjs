// item-stats M5 — geared-season sweep. Observe the rarity gear-spike the way the GAME does it: a real full 6-slot
// gear set per member (rollItemStats → effIlvl=Σmainstat/MAIN_K + summed secondary ratings), exactly the path
// game-store uses for the run party (gearEffectiveIlvl/gearSecondaries, line ~752). The ONLY variable swept is RARITY
// (Common→Uncommon→Rare→Epic) at a fixed nominal ilvl, so every delta is the pure rarity spike (effIlvl ×1.0…×1.25 +
// 0/1/2/2 secondaries). Balanced, no talents/operator/affixes-on-A — isolates gear. Deterministic (seeded).
//
//   Part A  per-spec DPS spike on N=1/3/5 training dummies (raw output) — which playstyles spike hardest, any runaway?
//   Part B  per-comp timed key-ceiling at each rarity on 3 discriminating dungeons — how many extra keys does a full
//           set of each rarity buy (the "season spike" in keys)?
//
// Usage: node scripts/item-gear-sweep.mjs [ilvl=160]      (160 = the gear cap GEAR_CAP_ILVL — the endgame set)
import { createServer } from "vite"

const ILVL = Number(process.argv[2] ?? 160)
const RARITIES = ["Common", "Uncommon", "Rare", "Epic"]
const server = await createServer({ server: { middlewareMode: true }, appType: "custom", logLevel: "error" })
try {
  const { content } = await server.ssrLoadModule("/src/content/index.ts")
  const { runDungeonEGM } = await server.ssrLoadModule("/src/sim/egm/engine.ts")
  const { rollItemStats, gearEffectiveIlvl, gearSecondaries, SLOT_WEIGHT, RARITY_MULT } =
    await server.ssrLoadModule("/src/state/item-stats.ts")
  const SLOTS = Object.keys(SLOT_WEIGHT) // the 6 paper-doll slots (weights sum to 1.0)

  // Faithful full-set gearing: build a real rollItemStats item per slot, then summarise exactly like the store.
  // gearSeed varies the per-item uid → a different (still realistic) random secondary split, so we can average out
  // the lumpiness of a single draw and report a representative central spike.
  const gearFor = (rarity, gearSeed) => {
    const items = SLOTS.map((slot) => rollItemStats({ uid: `m5-${slot}-${rarity}-${gearSeed}`, slot, ilvl: ILVL, rarity }, "Strength"))
    return { effIlvl: gearEffectiveIlvl(items), secondaries: gearSecondaries(items) }
  }
  const sumSec = (s) => s.haste + s.critChance + s.critDamage + s.versatility

  // ---- show the gear summaries up front so the spike is legible ----
  console.log(`=== item-stats M5 geared-season sweep @ nominal ilvl ${ILVL} (rarity is the only variable) ===`)
  console.log(`\nFull 6-slot set per rarity (effIlvl + summed secondary ratings; avg of 3 gear draws):`)
  for (const r of RARITIES) {
    let eff = 0; const tot = { haste: 0, critChance: 0, critDamage: 0, versatility: 0 }
    for (let gs = 0; gs < 3; gs++) { const g = gearFor(r, gs); eff += g.effIlvl; for (const k in tot) tot[k] += g.secondaries[k] }
    eff /= 3; for (const k in tot) tot[k] = Math.round(tot[k] / 3)
    console.log(`  ${r.padEnd(9)} effIlvl ${eff.toFixed(1)} (×${RARITY_MULT[r]})  | Σsec ${Math.round(sumSec(tot))}  [H ${tot.haste} · CC ${tot.critChance} · CD ${tot.critDamage} · V ${tot.versatility}]`)
  }

  // ===================== Part A — per-spec DPS spike on dummies =====================
  const baseEnemy = structuredClone([...content.enemies.values()][0])
  const dummy = { ...baseEnemy, id: "dps-dummy", name: "Training Dummy", baseHp: 9_000_000, baseDamage: 0,
    armour: 0, resist: 0, band: "Front", guarding: false, shielded: false }
  delete dummy.abilityId; delete dummy.spikeProfile; delete dummy.summonsId; delete dummy.testsTactic; delete dummy.curse
  content.enemies.set("dps-dummy", dummy)
  const basePack = structuredClone([...content.packs.values()][0])
  const baseDungeon = structuredClone(content.dungeons.get("ashveil-crypts"))
  for (const n of [1, 3, 5]) {
    content.packs.set(`dps-pack-${n}`, { ...basePack, id: `dps-pack-${n}`, name: `Dummies x${n}`, tags: [`dps-${n}`], mobs: [{ enemyId: "dps-dummy", count: n }] })
    content.dungeons.set(`dps-${n}`, { ...baseDungeon, id: `dps-${n}`, name: `DPS x${n}`, timerSeconds: 120, slots: [{ kind: "trash", packTags: [`dps-${n}`] }] })
  }
  const SPECS = [...content.specs.values()].map((s) => ({ id: s.id, name: s.name, role: s.role }))
  const seedsA = [7, 42, 101]
  const gearSeedsA = [0, 1]
  const dpsOf = (specId, n, rarity) => {
    let sum = 0, cnt = 0
    for (const gs of gearSeedsA) {
      const { effIlvl, secondaries } = gearFor(rarity, gs)
      for (const seed of seedsA) {
        const r = runDungeonEGM({ dungeonId: `dps-${n}`, keyLevel: 2, affixIds: [], aggression: "Balanced", seed,
          tactics: { interrupts: 0, positioning: 0, cooldowns: 0, killorder: 0 },
          party: [{ id: "m0", name: specId, specId, ilvl: ILVL, effIlvl, secondaries, morale: 60, traitIds: [] }] })
        const last = r.series.filter(Boolean).at(-1)
        sum += (last ? last[0] : 0) / Math.max(1, r.durationSec); cnt++
      }
    }
    return Math.round(sum / cnt)
  }
  const ROLE_ORDER = { Tank: 0, Healer: 1, DPS: 2 }
  console.log(`\n\n===== PART A — per-spec single-target DPS by rarity (avg ${gearSeedsA.length}×${seedsA.length} runs) =====`)
  console.log(`spec          role   |  Common |   Uncom |    Rare |    Epic | Epic/Common`)
  const aRows = SPECS.map((s) => {
    const d = Object.fromEntries(RARITIES.map((r) => [r, dpsOf(s.id, 1, r)]))
    return { ...s, d, spike: d.Common ? d.Epic / d.Common : 0 }
  }).sort((a, b) => (ROLE_ORDER[a.role] - ROLE_ORDER[b.role]) || (b.d.Epic - a.d.Epic))
  for (const r of aRows) {
    const pct = r.spike ? `+${Math.round((r.spike - 1) * 100)}%` : "—"
    console.log(`${r.name.padEnd(13)} ${r.role.padEnd(6)} | ${RARITIES.map((x) => String(r.d[x]).padStart(7)).join(" | ")} | ${pct.padStart(6)}`)
  }
  const dpsSpikes = aRows.filter((r) => r.role === "DPS" && r.spike).map((r) => r.spike)
  if (dpsSpikes.length) {
    const lo = Math.min(...dpsSpikes), hi = Math.max(...dpsSpikes), avg = dpsSpikes.reduce((a, b) => a + b, 0) / dpsSpikes.length
    console.log(`\n  DPS-spec ST Epic/Common spike: range +${Math.round((lo - 1) * 100)}%..+${Math.round((hi - 1) * 100)}%, mean +${Math.round((avg - 1) * 100)}%`)
  }

  // ===================== Part B — per-comp timed key-ceiling by rarity =====================
  const ilvlFor = () => ILVL  // fixed nominal ilvl; rarity is the only lever
  const COMPS = {
    "Meta (no-util) ": ["guardian", "cleric", "assassin", "pyromancer", "berserker"],
    "MagicHeavy util": ["guardian", "cleric", "assassin", "pyromancer", "arcanist"],
    "CrusaderTank   ": ["crusader", "lifebinder", "assassin", "pyromancer", "arcanist"],
  }
  const DUNGEONS = [
    { id: "ashveil-crypts",    tac: { interrupts: 2, positioning: 1, cooldowns: 2, killorder: 1 } },
    { id: "bellreach-sanctum", tac: { interrupts: 3, positioning: 0, cooldowns: 3, killorder: 0 } },
    { id: "pyreward-ossuary",  tac: { interrupts: 0, positioning: 3, cooldowns: 3, killorder: 0 } },
  ]
  const seedsB = [7, 42]
  const party = (specs, rarity) => specs.map((s, i) => {
    const { effIlvl, secondaries } = gearFor(rarity, i)  // per-member gear seed = member index (realistic split)
    return { id: `p${i}`, name: `${s}${i}`, specId: s, ilvl: ilvlFor(), effIlvl, secondaries, morale: 60, traitIds: [] }
  })
  const ceilOf = (dungeonId, specs, tac, rarity) => {
    let c = 1
    for (let k = 2; k <= 22; k++) {
      let timed = 0
      for (const s of seedsB) if (runDungeonEGM({ dungeonId, keyLevel: k, affixIds: ["fortified", "bursting"], party: party(specs, rarity), tactics: tac, aggression: "Balanced", seed: s }).outcome === "timed") timed++
      if (timed >= 2) c = k
    }
    return c
  }
  console.log(`\n\n===== PART B — timed key-ceiling by rarity (fixed ilvl ${ILVL}, ${seedsB.length} seeds, fort+bursting) =====`)
  const spikeRows = []
  for (const d of DUNGEONS) {
    console.log(`\n  ${d.id}`)
    for (const [name, specs] of Object.entries(COMPS)) {
      const ceil = Object.fromEntries(RARITIES.map((r) => [r, ceilOf(d.id, specs, d.tac, r)]))
      const spike = ceil.Epic - ceil.Common
      spikeRows.push(spike)
      console.log(`    ${name} | ${RARITIES.map((r) => `${r[0]}+${String(ceil[r]).padStart(2)}`).join("  ")}  | Epic−Common = +${spike} keys`)
    }
  }
  if (spikeRows.length) {
    const lo = Math.min(...spikeRows), hi = Math.max(...spikeRows), avg = (spikeRows.reduce((a, b) => a + b, 0) / spikeRows.length).toFixed(1)
    console.log(`\n  Key-ceiling Epic−Common spike: range +${lo}..+${hi} keys, mean +${avg} keys`)
  }
} finally {
  await server.close()
}
