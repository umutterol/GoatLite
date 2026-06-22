// P.4 replay-integrity check: a mid-fight summoned add must produce a VALID ReplayMob (stable unique id, spawnSec, HP
// array) on the boss stage, or the 2D replay UI breaks. Runs Hour of Bells through the Leaden Carillon and inspects the
// emitted ReplayTimeline for the summoned Bell-Wardens. Also confirms determinism (same seed → identical replay shape).
import { createServer } from "vite"
const server = await createServer({ server: { middlewareMode: true }, appType: "custom", logLevel: "error" })
try {
  const { runDungeonEGM } = await server.ssrLoadModule("/src/sim/egm/engine.ts")
  await server.ssrLoadModule("/src/content/index.ts")
  const mk = (id, name, specId) => ({ id, name, specId, ilvl: 132, morale: 60, traitIds: [] })
  const party = [mk("t","Grymdark","guardian"), mk("h","Svenrik","cleric"), mk("d1","Sythe","assassin"), mk("d2","Korga","berserker"), mk("d3","Quill","bard")]
  const run = (seed) => runDungeonEGM({ dungeonId: "hour-of-bells", keyLevel: 6, affixIds: ["fortified","bursting"], party, tactics: { interrupts: 0, positioning: 0, cooldowns: 3, killorder: 3 }, aggression: "Balanced", seed })

  const r = run(7)
  const tl = r.replay
  console.log(`replay present: ${!!tl}; stages=${tl?.stages?.length}; mobs=${tl?.mobs?.length}`)
  const carillon = tl.stages.find((s) => s.name && /Leaden Carillon/.test(s.name))
  console.log(`carillon stage idx=${carillon?.idx} kind=${carillon?.kind} mobIds=${JSON.stringify(carillon?.mobIds)}`)
  const wardenRecs = tl.mobs.filter((m) => m.name === "Bell-Warden")
  console.log(`Bell-Warden ReplayMobs: ${wardenRecs.length}`)
  // integrity asserts
  const ids = tl.mobs.map((m) => m.id)
  const dupes = ids.filter((id, i) => ids.indexOf(id) !== i)
  const allHaveHp = tl.mobs.every((m) => Array.isArray(m.hp) && m.hp.length >= 1)
  const wardenIdsMatch = wardenRecs.every((m) => carillon.mobIds.includes(m.id))
  const wardenSpawnsMidStage = wardenRecs.every((m) => typeof m.spawnSec === "number")
  console.log(`\nintegrity:`)
  console.log(`  unique mob ids: ${dupes.length === 0 ? "ok" : "FAIL dupes=" + JSON.stringify(dupes)}`)
  console.log(`  all mobs have HP arrays: ${allHaveHp ? "ok" : "FAIL"}`)
  console.log(`  warden recs are in the carillon stage's mobIds: ${wardenIdsMatch ? "ok" : "FAIL"}`)
  console.log(`  warden recs have spawnSec: ${wardenSpawnsMidStage ? "ok" : "FAIL"}`)
  console.log(`  ≥1 warden actually summoned + recorded: ${wardenRecs.length >= 1 ? "ok" : "FAIL"}`)

  // determinism: same seed → identical replay mob-id list + log length
  const r2 = run(7)
  const same = JSON.stringify(r.replay.mobs.map((m) => m.id)) === JSON.stringify(r2.replay.mobs.map((m) => m.id)) && r.log.length === r2.log.length
  console.log(`  determinism (same seed → identical replay/log): ${same ? "ok" : "FAIL"}`)
} finally {
  await server.close()
}
