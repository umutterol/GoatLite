// Pyreward Ossuary school-ceiling sweep (C.8 / C.1). Goal ("bring the player, not the class"): an all-one-school DPS
// core clears the Ossuary's low/mid keys, but a MIXED-school core (which isn't fully mitigated on any boss) extends the
// timed ceiling ~1-2 keys. Compares an all-physical DPS core vs a mixed core, on the Ossuary AND on Ashveil (the control:
// no armour/resist, so any ceiling gap there is spec-power confound, not the school wall — subtract it out).
import { createServer } from "vite"

const server = await createServer({ server: { middlewareMode: true }, appType: "custom", logLevel: "error" })
try {
  const { runDungeonEGM } = await server.ssrLoadModule("/src/sim/egm/engine.ts")
  await server.ssrLoadModule("/src/content/index.ts")
  const mk = (id, name, specId, ilvl) => ({ id, name, specId, ilvl, morale: 60, traitIds: [] })
  const ilvlFor = (k) => 108 + 4 * k
  const base = (ilvl) => [mk("t", "Grymdark", "guardian", ilvl), mk("h", "Bramblewen", "lifebinder", ilvl)]
  const physDps = (ilvl) => [mk("d1", "Sythe", "assassin", ilvl), mk("d2", "Korga", "berserker", ilvl), mk("d3", "Lyra", "bard", ilvl)]        // 3 Physical
  const mixedDps = (ilvl) => [mk("d1", "Sythe", "assassin", ilvl), mk("d2", "Emberkin", "pyromancer", ilvl), mk("d3", "Wisp", "arcanist", ilvl)] // 1 Phys + 2 Magic
  const comp = (which, ilvl) => [...base(ilvl), ...(which === "mixed" ? mixedDps(ilvl) : physDps(ilvl))]
  const spend = { interrupts: 0, positioning: 3, cooldowns: 3, killorder: 0 }
  const seeds = [7, 13, 42]
  const run = (dungeonId, party, key, seed) => runDungeonEGM({ dungeonId, keyLevel: key, affixIds: ["fortified", "bursting"], party, tactics: spend, aggression: "Balanced", seed })
  const sweep = (dungeonId, which) => {
    const cells = []
    for (let k = 2; k <= 14; k++) {
      let timed = 0
      for (const s of seeds) if (run(dungeonId, comp(which, ilvlFor(k)), k, s).outcome === "timed") timed++
      cells.push(`+${String(k).padStart(2)}:${timed}`)
    }
    return cells.join(" ")
  }
  for (const [dungeon, label] of [["pyreward-ossuary", "OSSUARY (school wall)"], ["ashveil-crypts", "ASHVEIL (control: no armour)"]]) {
    console.log(`\n=== ${dungeon}  — ${label}  — seeds timed / ${seeds.length}, gear-appropriate ilvl ===`)
    console.log(`  mixed-school : ${sweep(dungeon, "mixed")}`)
    console.log(`  all-physical : ${sweep(dungeon, "phys")}`)
  }
} finally {
  await server.close()
}
