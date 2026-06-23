// M6 regression probe: runs the summoning dungeon (hour-of-bells → The Leaden Carillon summons bell-wardens)
// and prints a deterministic signature (outcome/dur/deaths + summon-log count + replay mob-id list) so the
// §H summon-engine refactor can be proven byte-identical (egm-smoke's dungeon does NOT summon).
import { createServer } from "vite"
const server = await createServer({ server: { middlewareMode: true }, appType: "custom", logLevel: "error" })
try {
  const { runDungeonEGM } = await server.ssrLoadModule("/src/sim/egm/engine.ts")
  const mk = (id, name, specId) => ({ id, name, specId, ilvl: 165, morale: 60, traitIds: [] })
  const party = [mk("p1", "Grymdark", "guardian"), mk("p2", "Svenrik", "cleric"), mk("p3", "Bramblewen", "lifebinder"), mk("p4", "Sythe", "assassin"), mk("p5", "Emberkin", "pyromancer")]
  for (const key of [6, 10]) {
    const r = runDungeonEGM({ dungeonId: "hour-of-bells", keyLevel: key, affixIds: ["tyrannical", "bursting"], party, tactics: { interrupts: 1, positioning: 1, cooldowns: 1, killorder: 1 }, aggression: "Balanced", seed: 12345 })
    const summonLines = r.log.filter((l) => /ward it|warden/i.test(l.text)).length
    const mobIds = (r.replay?.stages ?? []).flatMap((s) => s.mobIds).join("|")
    console.log(`+${key}: outcome=${r.outcome} dur=${r.durationSec}s deaths=${r.deaths.length} summonLines=${summonLines}`)
    console.log(`     mobIds=${mobIds}`)
  }
} finally { await server.close() }
