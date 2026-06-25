// One-off: screenshot the New Run board with a LARGE roster to reproduce the "tables overflow one screen" problem.
import { chromium } from "playwright"
const URL = process.argv[2] ?? "http://localhost:5177"
const browser = await chromium.launch()
const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } })
await page.goto(URL, { waitUntil: "networkidle" })
await page.waitForFunction(() => !!window.__game, null, { timeout: 15000 })
await page.evaluate(() => window.__game.newGame())
await page.waitForTimeout(120)
await page.evaluate(() => window.__game.createGuild({ name: "Big Guild", crest: "#2bb6a4", glyph: "G", motto: "more goats." }))
await page.waitForTimeout(150)
// opening draft + a couple more waves to grow the roster well past 5
for (let i = 0; i < 4; i++) {
  await page.evaluate(() => { const g = window.__game; g.recruits.forEach((r) => g.toggleSignRecruit(r.id)); g.confirmRecruits() })
  await page.waitForTimeout(250)
}
const n = await page.evaluate(() => window.__game.members.length)
console.log("members:", n, "keys:", await page.evaluate(() => window.__game.keys.length))
await page.locator(".nav-tab", { hasText: "New Run" }).click().catch(() => {})
await page.waitForTimeout(450)
await page.screenshot({ path: "scripts/_shot-newrun-overflow.png" })
console.log("shot → scripts/_shot-newrun-overflow.png")
await browser.close()
