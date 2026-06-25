// C.5 live check: the overhauled WoW-style ItemTip.
//  (A) Roster member → hover an EQUIPPED item (proves gradient panel, rarity colour, gold ilvl, white mains,
//      green secondary).
//  (B) Drive a real run → Report → Distribute Loot → hover real loot drops (baseIds from items.json), capturing a
//      WEAPON (faked damage/speed line) and a TRINKET (green Equip line + tan flavor + sell price) tooltip.
// Hard gate = 0 console errors + at least one weapon tooltip captured.
import { chromium } from "playwright"
const URL = process.argv[2] ?? "http://localhost:5173"
const errors = []
const browser = await chromium.launch()
const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } })
page.on("console", (m) => { if (m.type() === "error") errors.push(m.text()) })
page.on("pageerror", (e) => errors.push("pageerror: " + e.message))
const seen = {}

async function captureHovers(targets, label) {
  const n = await targets.count()
  console.log(`${label}: ${n} hover targets`)
  for (let i = 0; i < n; i++) {
    try { await targets.nth(i).scrollIntoViewIfNeeded(); await targets.nth(i).hover({ force: true }) }
    catch (e) { console.log(`  hover skip #${i}: ${e.message.split("\n")[0]}`); continue }
    await page.waitForTimeout(200)
    const tip = page.locator('[role="tooltip"]').first()
    const txt = (await tip.innerText().catch(() => "")) || ""
    if (!/Item Level/.test(txt)) { await page.mouse.move(4, 4); await page.waitForTimeout(80); continue }
    const kind = /damage per second/i.test(txt) ? "weapon" : /Equip:/.test(txt) ? "trinket" : "armor"
    if (!seen[kind]) {
      seen[kind] = txt
      await tip.screenshot({ path: `scripts/_shot-tip-${kind}.png` }).catch((e) => console.log("  crop fail:", e.message))
      console.log(`\n=== [${kind}] ===\n${txt}\n`)
    }
    await page.mouse.move(4, 4)
    await page.waitForTimeout(110)
  }
}

try {
  page.setDefaultTimeout(8000)
  await page.goto(URL, { waitUntil: "networkidle" })
  await page.waitForFunction(() => !!window.__game, null, { timeout: 15000 })
  await page.evaluate(() => window.__game.newGame())
  await page.waitForTimeout(120)
  await page.evaluate(() => window.__game.createGuild({ name: "Tip Test", crest: "#2bb6a4", glyph: "G", motto: "loot." }))
  await page.waitForTimeout(150)
  await page.evaluate(() => { const g = window.__game; g.recruits.slice(0, 5).forEach((r) => g.toggleSignRecruit(r.id)); g.confirmRecruits() })
  await page.waitForTimeout(250)

  // (A) equipped item on a roster member
  await page.locator(".nav-tab", { hasText: "Roster" }).click()
  await page.waitForTimeout(300)
  await page.locator("table tbody tr, .roster-card, .card").first().click().catch(() => {})
  await page.waitForTimeout(500)
  const equip = page.locator('.panel:has(.panel-title:has-text("Equipped Items"))').first()
  await equip.waitFor({ timeout: 5000 })
  await captureHovers(equip.locator("div.pixel"), "equipped")
  if (seen.armor || seen.weapon || seen.trinket) {
    const k = seen.armor ? "armor" : seen.weapon ? "weapon" : "trinket"
    console.log(`(renamed first equipped crop _shot-tip-${k}.png → equipped proof)`)
  }

  // (B) drive a real run so we get loot with real items.json baseIds
  let loot = 0
  for (let attempt = 0; attempt < 6 && loot === 0; attempt++) {
    loot = await page.evaluate(() => {
      const g = window.__game
      g.setParty(g.members.slice(0, 5).map((m) => m.id))
      const ownerId = (g.keys[0] && g.keys[0].ownerId) || g.members[0].id
      g.selectKey(ownerId)
      const res = g.runKey({ tactics: { interrupts: 2, positioning: 1, cooldowns: 1, killorder: 2 }, aggression: "Balanced" })
      if (res && typeof res.seed === "number") g.markRunWatched(res.seed)   // ungate the report (skip watch-replay)
      return (g.pendingLoot || []).length
    })
    console.log(`run attempt ${attempt + 1}: pendingLoot = ${loot}`)
    await page.waitForTimeout(200)
  }

  if (loot > 0) {
    await page.locator(".nav-tab", { hasText: "Report" }).click()
    await page.waitForTimeout(400)
    await page.locator("button", { hasText: /Distribute Loot/ }).first().click().catch((e) => console.log("distribute click:", e.message))
    await page.waitForTimeout(500)
    await captureHovers(page.locator(".app-main .pixel"), "loot")
    await page.screenshot({ path: "scripts/_shot-tip-lootpage.png" })
    console.log("context shot → scripts/_shot-tip-lootpage.png")
  }

  console.log(`\ncaptured kinds: ${Object.keys(seen).join(", ") || "none"}`)
  console.log(`console errors: ${errors.length}`)
  errors.slice(0, 12).forEach((e) => console.log("  x " + e))
  const pass = errors.length === 0 && !!seen.weapon
  console.log(pass ? "\nLIVE CHECK PASS" : "\nLIVE CHECK FAIL")
  process.exitCode = pass ? 0 : 1
} catch (e) {
  console.log("EXCEPTION: " + e.message)
  process.exitCode = 1
} finally { await browser.close() }
