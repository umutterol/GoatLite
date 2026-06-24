// Font preview: render the live UI under several candidate UI fonts (chat + items stay Pixelify). Injects each Google
// Font, overrides the --font token, screenshots the dense Roster to scripts/_shot-font-<id>.png. Usage:
//   node scripts/font-preview.mjs [http://localhost:5176]
import { chromium } from "playwright"
const URL = process.argv[2] ?? "http://localhost:5176"

// candidates with a bit of character but still legible on data tables
const FONTS = [
  { id: "space-grotesk", fam: "Space Grotesk", url: "Space+Grotesk:wght@400;500;600;700" },
  { id: "chakra-petch",  fam: "Chakra Petch",  url: "Chakra+Petch:wght@400;500;600;700" },
  { id: "rubik",         fam: "Rubik",         url: "Rubik:wght@400;500;600;700" },
  { id: "sora",          fam: "Sora",          url: "Sora:wght@400;500;600;700" },
  { id: "saira",         fam: "Saira Semi Condensed", url: "Saira+Semi+Condensed:wght@400;500;600;700" },
]

const browser = await chromium.launch()
const page = await browser.newPage({ viewport: { width: 1480, height: 620 } })
try {
  await page.goto(URL, { waitUntil: "networkidle" })
  await page.waitForFunction(() => !!window.__game, null, { timeout: 15000 })
  await page.evaluate(() => window.__game.newGame())
  await page.waitForTimeout(120)
  await page.evaluate(() => window.__game.createGuild({ name: "Font Test", crest: "#2bb6a4", glyph: "⚔", motto: "type." }))
  await page.waitForTimeout(150)
  await page.evaluate(() => { const g = window.__game; g.recruits.slice(0, 5).forEach((r) => g.toggleSignRecruit(r.id)); g.confirmRecruits() })
  await page.waitForTimeout(300)
  await page.locator(".nav-tab", { hasText: "Roster" }).click().catch(() => {})
  await page.waitForTimeout(300)

  for (const f of FONTS) {
    await page.evaluate(({ url, fam }) => {
      const l = document.createElement("link")
      l.rel = "stylesheet"; l.href = `https://fonts.googleapis.com/css2?family=${url}&display=swap`
      document.head.appendChild(l)
      document.documentElement.style.setProperty("--font", `"${fam}", system-ui, sans-serif`)
    }, f)
    await page.evaluate(() => document.fonts.ready).catch(() => {})
    await page.waitForTimeout(700)
    await page.screenshot({ path: `scripts/_shot-font-${f.id}.png`, fullPage: false })
    console.log(`shot: ${f.fam}`)
  }
  console.log("done")
} catch (e) { console.log("EXCEPTION: " + e.message) }
finally { await browser.close() }
