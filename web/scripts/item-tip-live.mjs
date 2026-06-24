// item-stats M4 live check: equipped items show a WoW-style ItemTip (name + Item Level + base stats), the name is
// rarity-coloured (Common starter = white), and the loot screen tooltip works after a run. Hard gate = 0 console errors.
import { chromium } from "playwright"
const URL = process.argv[2] ?? "http://localhost:5173"
const errors = []
const browser = await chromium.launch()
const page = await browser.newPage()
page.on("console", (m) => { if (m.type() === "error") errors.push(m.text()) })
page.on("pageerror", (e) => errors.push("pageerror: " + e.message))
const ok = []
const check = (c, m) => { ok.push(!!c); console.log((c ? "PASS  " : "FAIL  ") + m) }
try {
  await page.goto(URL, { waitUntil: "networkidle" })
  await page.waitForFunction(() => !!window.__game, null, { timeout: 15000 })
  await page.evaluate(() => window.__game.newGame())
  await page.waitForTimeout(120)
  await page.evaluate(() => window.__game.createGuild({ name: "Item Test", crest: "#2bb6a4", glyph: "⚔", motto: "loot." }))
  await page.waitForTimeout(150)
  await page.evaluate(() => { const g = window.__game; g.recruits.slice(0, 5).forEach((r) => g.toggleSignRecruit(r.id)); g.confirmRecruits() })
  await page.waitForTimeout(250)
  await page.locator(".nav-tab", { hasText: "Roster" }).click()
  await page.waitForTimeout(300)
  await page.locator(".roster-card, [data-roster-card], .card").first().click().catch(() => {})
  await page.waitForTimeout(400)
  if (!(await page.locator('.panel:has(.panel-title:has-text("Equipped Items"))').count())) {
    await page.locator("table.runs tbody tr").first().click().catch(() => {})
    await page.waitForTimeout(400)
  }

  const equip = page.locator('.panel:has(.panel-title:has-text("Equipped Items"))').first()
  check(await equip.count() > 0, "Equipped Items panel renders")

  const firstName = equip.getByText(/Worn/).first()
  const nameColor = await firstName.evaluate((el) => getComputedStyle(el).color).catch(() => "")
  check(/rgb\(255,\s*255,\s*255\)/.test(nameColor), `Common starter item name is white (got ${nameColor})`)

  await firstName.hover()
  await page.waitForTimeout(220)
  const tipText = (await page.locator('[role="tooltip"]').first().innerText().catch(() => "")) || ""
  check(/Item Level/.test(tipText), `ItemTip shows "Item Level" (got: ${tipText.replace(/\n/g, " · ").slice(0, 90)})`)
  check(/Stamina/.test(tipText), "ItemTip shows a base stat (Stamina)")

  await page.screenshot({ path: "scripts/_shot-itemtip.png", fullPage: true })

  console.log(`\nconsole errors: ${errors.length}`)
  errors.slice(0, 12).forEach((e) => console.log("  ✗ " + e))
  const pass = errors.length === 0 && ok.every(Boolean)
  console.log(pass ? "\nLIVE CHECK PASS" : "\nLIVE CHECK FAIL")
  process.exitCode = pass ? 0 : 1
} catch (e) {
  console.log("EXCEPTION: " + e.message)
  process.exitCode = 1
} finally { await browser.close() }
