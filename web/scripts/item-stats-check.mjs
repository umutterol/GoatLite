// item-stats M1 probe — show the deterministic stat blocks rollItemStats produces.
import { createServer } from "vite"
const server = await createServer({ server: { middlewareMode: true }, appType: "custom", logLevel: "error" })
try {
  const { rollItemStats } = await server.ssrLoadModule("/src/state/item-stats.ts")
  const show = (uid, slot, ilvl, rarity, mainType) => {
    const s = rollItemStats({ uid, slot, ilvl, rarity }, mainType)
    const sec = s.secondaries.map((x) => `${x.stat} +${x.value}`).join(" · ") || "—"
    console.log(`  ${rarity.padEnd(9)} ilvl${ilvl} ${slot.padEnd(7)} | ${mainType} +${String(s.mainStat).padStart(3)} · Stamina +${String(s.stamina).padStart(3)} | ${sec}`)
  }
  console.log("=== Item stat blocks (deterministic from uid) ===")
  console.log("\nSame chest, ilvl 150, across rarities — the rarity spike on main/stam + secondary count:")
  for (const r of ["Common", "Uncommon", "Rare", "Epic"]) show(`demo-chest-${r}`, "chest", 150, r, "Agility")
  console.log("\nGear-appropriate progression (ilvl AND rarity climb with key):")
  show("d1", "chest", 108, "Common", "Strength")
  show("d2", "chest", 124, "Uncommon", "Strength")
  show("d3", "chest", 144, "Rare", "Strength")
  show("d4", "chest", 160, "Epic", "Strength")
  console.log("\nSlot weights at Epic ilvl 160 (weapon is the biggest stat stick):")
  for (const s of ["weapon", "chest", "legs", "helm", "boots", "trinket"]) show(`w-${s}`, s, 160, "Epic", "Intellect")

  console.log("\nSAME item (Epic chest ilvl160), 5 different DROPS → random secondaries each (players hunt the roll):")
  for (let i = 1; i <= 5; i++) {
    const s = rollItemStats({ uid: `breastplate-of-the-pale-vigil-${i}`, slot: "chest", ilvl: 160, rarity: "Epic" }, "Strength")
    console.log(`  drop #${i}: ${s.secondaries.map((x) => `${x.stat} +${x.value}`).join(" · ")}`)
  }
} finally { await server.close() }
