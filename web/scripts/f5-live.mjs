// F.5 live check: drive guild → recruit (scout board) → character (operator panel), assert no console errors.
import { chromium } from "playwright"

const URL = process.argv[2] ?? "http://localhost:5173"
const errors = []
const browser = await chromium.launch()
const page = await browser.newPage()
page.on("console", (m) => { if (m.type() === "error") errors.push(m.text()) })
page.on("pageerror", (e) => errors.push("pageerror: " + e.message))

const log = (s) => console.log(s)
try {
  await page.goto(URL, { waitUntil: "networkidle" })
  // fresh save (v5 bump) → guild create. Found a guild via the dev store handle.
  await page.waitForFunction(() => !!window.__game, null, { timeout: 15000 })
  await page.evaluate(() => window.__game.createGuild({ name: "Scout Test", faction: "horde", region: "EU · Test", crest: "#2bb6a4", glyph: "⚔", motto: "" }))

  // --- recruit scouting board ---
  await page.waitForSelector("text=Scouting Board", { timeout: 10000 })
  const ratingHdr = await page.locator("th", { hasText: "Rating" }).count()
  const potentialHdr = await page.locator("th", { hasText: "Potential" }).count()
  const rows = await page.locator("table.runs tbody tr").count()
  const skillNames = await page.locator("text=Execution").count()
  const opSkillsHdr = await page.locator("text=Operator Skills").count()
  const stars = await page.locator("[title$='potential']").count()
  log(`recruit: rows=${rows} ratingCol=${ratingHdr} potentialCol=${potentialHdr} skillBars(Execution)=${skillNames} opSkillsHdr=${opSkillsHdr} starRatings=${stars}`)
  await page.screenshot({ path: "scripts/_shot-recruit.png", fullPage: true })

  // sign 5 + confirm via the store handle
  await page.evaluate(() => {
    const g = window.__game
    g.recruits.slice(0, 5).forEach((r) => g.toggleSignRecruit(r.id))
    g.confirmRecruits()
  })
  await page.waitForTimeout(400)

  // --- character sheet operator panel ---
  await page.locator(".nav-tab", { hasText: "Roster" }).click()
  await page.waitForSelector("table.runs tbody tr", { timeout: 8000 })
  await page.locator("table.runs tbody tr").first().click()
  await page.waitForSelector("text=Operator", { timeout: 8000 })
  const opPanel = await page.locator(".panel-title", { hasText: "Operator" }).count()
  const corShown = await page.locator("text=COR").count()
  const charSkillBars = await page.locator("text=Composure").count()
  const charStars = await page.locator("[title$='potential']").count()
  log(`character: operatorPanel=${opPanel} corLabel=${corShown} skillBars(Composure)=${charSkillBars} stars=${charStars}`)
  await page.screenshot({ path: "scripts/_shot-character.png", fullPage: true })

  log(`\nconsole errors: ${errors.length}`)
  for (const e of errors.slice(0, 12)) log("  ✗ " + e)
  const ok = errors.length === 0 && rows > 0 && ratingHdr && potentialHdr && skillNames > 0 && opPanel > 0
  log(ok ? "\nLIVE CHECK PASS" : "\nLIVE CHECK FAIL")
  process.exitCode = ok ? 0 : 1
} catch (e) {
  log("EXCEPTION: " + e.message)
  for (const er of errors.slice(0, 12)) log("  ✗ " + er)
  process.exitCode = 1
} finally {
  await browser.close()
}
