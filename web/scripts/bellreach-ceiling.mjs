// P.2 Bellreach kick-or-wipe read (Class-Tools P1). Goal: bringing a real INTERRUPTER (arcanist Counterspell / mystic
// Zen Strike) tops Bellreach; a no-kicker core eats the stacking dangerous cast and falls +3-5 keys. Ashveil is the
// control (no cast scheduler → any gap there is spec-power, subtract it out). Same tank+healer+2 DPS; the 5th seat (or
// the tank for the mystic case) swaps the kicker in/out.
import { createServer } from "vite"
const server = await createServer({ server: { middlewareMode: true }, appType: "custom", logLevel: "error" })
try {
  const { runDungeonEGM } = await server.ssrLoadModule("/src/sim/egm/engine.ts")
  await server.ssrLoadModule("/src/content/index.ts")
  const mk = (id, name, specId, ilvl) => ({ id, name, specId, ilvl, morale: 60, traitIds: [] })
  const ilvlFor = (k) => 108 + 4 * k
  // 1T + 1H + 2 fixed DPS, then the 5th seat decides the kick. arcanist=ranged kick, berserker=no kick.
  const core = (ilvl) => [mk("t", "Grymdark", "guardian", ilvl), mk("h", "Svenrik", "cleric", ilvl), mk("d1", "Sythe", "assassin", ilvl), mk("d2", "Emberkin", "pyromancer", ilvl)]
  const COMPS = {
    "no-kicker (berserker)": (ilvl) => [...core(ilvl), mk("d3", "Korga", "berserker", ilvl)],
    "arcanist kicker      ": (ilvl) => [...core(ilvl), mk("d3", "Wisp", "arcanist", ilvl)],
    "mystic kicker (tank) ": (ilvl) => [mk("t", "Stone", "mystic", ilvl), mk("h", "Svenrik", "cleric", ilvl), mk("d1", "Sythe", "assassin", ilvl), mk("d2", "Emberkin", "pyromancer", ilvl), mk("d3", "Korga", "berserker", ilvl)],
  }
  const spend = { interrupts: 3, positioning: 0, cooldowns: 3, killorder: 0 }   // Bellreach's intended spend
  const seeds = [7, 13, 42]
  const sweep = (dungeonId, party) => {
    const cells = []
    for (let k = 2; k <= 18; k++) {
      let timed = 0
      for (const s of seeds) if (runDungeonEGM({ dungeonId, keyLevel: k, affixIds: ["fortified", "bursting"], party: party(ilvlFor(k)), tactics: spend, aggression: "Balanced", seed: s }).outcome === "timed") timed++
      cells.push(`+${String(k).padStart(2)}:${timed}`)
    }
    return cells.join(" ")
  }
  for (const [dungeon, label] of [["bellreach-sanctum", "BELLREACH (kick-or-wipe)"], ["ashveil-crypts", "ASHVEIL (control: dial-pure, no real cast)"]]) {
    console.log(`\n=== ${dungeon}  — ${label}  — seeds timed / ${seeds.length}, gear-appropriate ilvl ===`)
    for (const [name, party] of Object.entries(COMPS)) console.log(`  ${name}: ${sweep(dungeon, party)}`)
  }
} finally {
  await server.close()
}
