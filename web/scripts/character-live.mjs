// Character page (from roster) live check: a "Skills" panel showing ALL the spec's abilities (icons + SpellTip),
// no "Signature" panel, and the recruit-style Talents strip + popup (editable here — clicking sets the build).
// Usage: node scripts/character-live.mjs [http://localhost:5177]
import { chromium } from "playwright"
const URL = process.argv[2] ?? "http://localhost:5177"
const errors = [], ok = []
const check = (cond, msg) => { ok.push(!!cond); console.log((cond ? "PASS  " : "FAIL  ") + msg) }
const browser = await chromium.launch()
const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } })
page.on("console", (m) => { if (m.type() === "error") errors.push(m.text()) })
page.on("pageerror", (e) => errors.push("pageerror: " + e.message))
try {
  await page.goto(URL, { waitUntil: "networkidle" })
  await page.waitForFunction(() => !!window.__game, null, { timeout: 15000 })
  await page.evaluate(() => window.__game.newGame())
  await page.waitForTimeout(120)
  await page.evaluate(() => window.__game.createGuild({ name: "Char Co", crest: "#2bb6a4", glyph: "C", motto: "kit it." }))
  await page.waitForTimeout(150)
  await page.evaluate(() => { const g = window.__game; g.recruits.slice(0, 5).forEach((r) => g.toggleSignRecruit(r.id)); g.confirmRecruits() })
  await page.waitForTimeout(300)

  await page.locator(".nav-tab", { hasText: "Roster" }).click().catch(() => {})
  await page.waitForTimeout(300)
  await page.locator("table.runs tbody tr").first().click().catch(() => {})
  await page.waitForTimeout(400)
  await page.screenshot({ path: "scripts/_shot-character.png" })

  const panels = () => page.evaluate(() => [...document.querySelectorAll(".panel")].map((p) => ({ title: p.innerText.split("\n")[0], abilityIcons: [...p.querySelectorAll("img")].filter((im) => (im.getAttribute("src") || "").includes("/ability-")).length })))
  const ps = await panels()
  const skills = ps.find((p) => /^skills/i.test(p.title))
  check(!!skills, `"Skills" panel present (titles: ${ps.map((p) => p.title).join(" | ")})`)
  check(!!skills && skills.abilityIcons >= 5, `Skills panel shows the full kit as ability icons (${skills?.abilityIcons})`)
  check(!ps.some((p) => /^signature/i.test(p.title)), `old "Signature" panel is gone`)

  // talents strip (framed Panel) + editable popup
  const talentsBtn = page.locator(".panel button", { hasText: /^Talents/ }).first()
  check(await talentsBtn.count() > 0, `Talents strip + button present`)
  await talentsBtn.click().catch(() => {})
  await page.waitForTimeout(250)
  const cells = await page.locator("[data-talent-cell]").count().catch(() => 0)
  check(cells === 15, `talents popup shows the 5×3 grid (${cells} cells)`)
  // editable: clicking a cell sets a member's talent (talents start empty → a pick appears)
  const before = await page.evaluate(() => window.__game.members.reduce((s, m) => s + Object.keys(m.talents || {}).length, 0))
  await page.locator("[data-talent-cell]").nth(1).click().catch(() => {})  // a non-default option in tier 1
  await page.waitForTimeout(200)
  const after = await page.evaluate(() => window.__game.members.reduce((s, m) => s + Object.keys(m.talents || {}).length, 0))
  check(after > before, `clicking a talent sets the member's build (picks ${before} → ${after})`)

  check(errors.length === 0, `0 console errors`)
  const pass = errors.length === 0 && ok.every(Boolean)
  console.log(pass ? "\nCHARACTER CHECK PASS" : "\nCHARACTER CHECK FAIL")
  process.exitCode = pass ? 0 : 1
} catch (e) { console.log("EXCEPTION: " + e.message); process.exitCode = 1 } finally { await browser.close() }
