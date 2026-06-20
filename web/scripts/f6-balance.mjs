// F.6 balance: measure the operator "runway" — how many extra key levels maxed operators buy over fresh recruits
// at the gear cap, and confirm fresh recruits still time the +2 floor at starting gear.
import { createServer } from "vite"

const server = await createServer({ server: { middlewareMode: true }, appType: "custom", logLevel: "error" })
try {
  const { runDungeonEGM } = await server.ssrLoadModule("/src/sim/egm/engine.ts")
  const { content } = await server.ssrLoadModule("/src/content/index.ts")
  const save = content.save

  const sk = (e, a, c) => ({ execution: e, awareness: a, composure: c })
  const mk = (specId, name, skills, ilvl) => ({ id: name, name, specId, ilvl, morale: 60, traitIds: [], skills })
  const comp = (skills, ilvl) => [
    mk("guardian", "Tank", skills, ilvl), mk("cleric", "Heal", skills, ilvl), mk("lifebinder", "Heal2", skills, ilvl),
    mk("assassin", "Dps1", skills, ilvl), mk("pyromancer", "Dps2", skills, ilvl),
  ]
  const run = (skills, ilvl, key, seed) => runDungeonEGM({
    dungeonId: save.keystone.dungeonId, keyLevel: key, affixIds: save.week.affixes, party: comp(skills, ilvl),
    tactics: { interrupts: 2, positioning: 1, cooldowns: 1, killorder: 2 }, aggression: "Balanced", seed,
  })
  const SEEDS = [101, 202, 303, 404, 505, 606]
  const timedRate = (skills, ilvl, key) => SEEDS.filter((s) => run(skills, ilvl, key, s).outcome === "timed").length / SEEDS.length
  // highest key timed by >= 4/6 seeds
  const ceiling = (skills, ilvl) => {
    let best = 0
    for (let k = 2; k <= 24; k++) { if (timedRate(skills, ilvl, k) >= 0.66) best = k; else if (k > best + 2) break }
    return best
  }

  // 1) +2 floor at starting gear with fresh-recruit skills
  const floorRate = timedRate(sk(4, 4, 4), 115, 2)
  console.log(`+2 floor (ilvl115, fresh 4/4/4): timed ${floorRate * 6}/6`)

  // 2) operator runway at the gear cap (ilvl 160)
  const ILVL = 160
  const fresh = ceiling(sk(4, 4, 4), ILVL)
  const mid = ceiling(sk(12, 12, 12), ILVL)
  const max = ceiling(sk(20, 20, 20), ILVL)
  console.log(`\nKey ceiling @ ilvl${ILVL} (>=4/6 timed):`)
  console.log(`  fresh  (4/4/4)  → +${fresh}`)
  console.log(`  mid    (12/12/12) → +${mid}`)
  console.log(`  maxed  (20/20/20) → +${max}`)
  console.log(`  operator runway: +${max - fresh} key levels (target: a few, not a landslide)`)

  // 3) per-key timed rates around the cap for the curve shape
  console.log(`\nTimed rate by key @ ilvl${ILVL}:`)
  for (let k = Math.max(2, fresh - 1); k <= max + 2; k++)
    console.log(`  +${String(k).padStart(2)}  fresh ${(timedRate(sk(4,4,4), ILVL, k)*6)|0}/6   maxed ${(timedRate(sk(20,20,20), ILVL, k)*6)|0}/6`)
} finally {
  await server.close()
}
