// Cluster-J live check: guild(no faction/realm) → run a key → report (battle-res, healing meter, enemy names,
// tooltips, de-glow) → loot (per-upgrade arrows). Hard gate = zero console errors + the key assertions.
import { chromium } from "playwright"
const URL = process.argv[2] ?? "http://localhost:5173"
const errors = []
const browser = await chromium.launch()
const page = await browser.newPage()
page.on("console", (m) => { if (m.type() === "error") errors.push(m.text()) })
page.on("pageerror", (e) => errors.push("pageerror: " + e.message))
const ok = []
const check = (cond, msg) => { ok.push({ cond: !!cond, msg }); console.log((cond ? "PASS  " : "FAIL  ") + msg) }
try {
  await page.goto(URL, { waitUntil: "networkidle" })
  await page.waitForFunction(() => !!window.__game, null, { timeout: 15000 })

  // J.1: guild create has no Faction/Realm panels
  const factionPanels = await page.locator(".panel-title", { hasText: "Faction" }).count()
  const realmPanels = await page.locator(".panel-title", { hasText: "Realm" }).count()
  check(factionPanels === 0 && realmPanels === 0, "J.1 guild create has no Faction/Realm panels")

  await page.evaluate(() => window.__game.createGuild({ name: "J Test", crest: "#2bb6a4", glyph: "⚔", motto: "Ship it." }))
  await page.waitForSelector("text=Scouting Board", { timeout: 10000 })
  await page.evaluate(() => { const g = window.__game; g.recruits.slice(0, 5).forEach((r) => g.toggleSignRecruit(r.id)); g.confirmRecruits() })
  await page.waitForTimeout(300)
  // run a key directly through the store, then land on the report
  await page.evaluate(() => window.__game.runKey({ tactics: { interrupts: 2, positioning: 1, cooldowns: 1, killorder: 2 }, aggression: "Balanced" }))
  await page.waitForTimeout(600)

  // J.9: report header shows Combat Rez, not Rating
  const hasRez = await page.locator("text=Combat Rez").count()
  const hasRating = await page.getByText("Rating", { exact: true }).count()
  check(hasRez > 0 && hasRating === 0, "J.9 report shows 'Combat Rez' (Rating removed)")

  // let the replay run a bit so the log + meters populate
  await page.waitForTimeout(2500)

  // J.4: enemy attacker names appear in the event log (Ashveil mobs)
  const enemyLine = await page.getByText(/Bone Acolyte|Crypt Horror|Grave Digger/).count()
  check(enemyLine > 0, "J.4 enemy attacker names render in the log")

  // J.5: healing meter moves — switch to Healing and confirm a healer shows a non-zero rate
  await page.getByRole("button", { name: "Healing" }).click()
  await page.waitForTimeout(300)
  const meterText = await page.locator(".meter-content").allInnerTexts()
  const healMoved = meterText.some((t) => /[1-9]/.test(t))
  check(healMoved, "J.5 healing meter shows non-zero values")

  await page.screenshot({ path: "scripts/_shot-report.png", fullPage: true })

  // J.6: loot screen — per-candidate upgrade arrows + current→new
  const lootBtn = page.getByRole("button", { name: /Distribute Loot/ })
  if (await lootBtn.count()) {
    await lootBtn.click()
    await page.waitForSelector("text=Distribute Loot", { timeout: 6000 })
    const arrows = await page.getByText("▲").count()
    const compare = await page.getByText(/→ \d/).count()
    check(arrows > 0 || compare > 0, "J.6 loot shows upgrade arrows / current→new ilvl")
    await page.screenshot({ path: "scripts/_shot-loot.png", fullPage: true })
  } else {
    console.log("(no loot to distribute this run — skipping J.6 visual)")
  }

  // J.10: hover a spec icon on the roster → a content tooltip appears
  await page.locator(".nav-tab", { hasText: "Roster" }).click()
  await page.waitForSelector("table.runs tbody tr", { timeout: 6000 })
  await page.locator("table.runs tbody tr [role='img']").first().hover()
  await page.waitForTimeout(300)
  const tipCount = await page.locator("[role='tooltip']").count()
  check(tipCount > 0, "J.10 hovering a spec icon shows a tooltip")

  console.log(`\nconsole errors: ${errors.length}`)
  errors.slice(0, 12).forEach((e) => console.log("  ✗ " + e))
  const pass = errors.length === 0 && ok.every((o) => o.cond)
  console.log(pass ? "\nLIVE CHECK PASS" : "\nLIVE CHECK FAIL")
  process.exitCode = pass ? 0 : 1
} catch (e) {
  console.log("EXCEPTION: " + e.message)
  errors.slice(0, 12).forEach((er) => console.log("  ✗ " + er))
  process.exitCode = 1
} finally { await browser.close() }
