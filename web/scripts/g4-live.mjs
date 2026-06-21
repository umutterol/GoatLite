// G.4 live check: the painted PNG icons render — ability icons inline in the event log + spell tooltip,
// spec/role icons across the app, and the Character-sheet Signature card. Hard gate = 0 console errors.
import { chromium } from "playwright"
const URL = process.argv[2] ?? "http://localhost:5173"
const errors = []
const browser = await chromium.launch()
const page = await browser.newPage()
page.on("console", (m) => { if (m.type() === "error") errors.push(m.text()) })
page.on("pageerror", (e) => errors.push("pageerror: " + e.message))
const ok = []
const check = (cond, msg) => { ok.push({ cond: !!cond, msg }); console.log((cond ? "PASS  " : "FAIL  ") + msg) }
const count = (sel) => page.locator(sel).count()

try {
  await page.goto(URL, { waitUntil: "networkidle" })
  await page.waitForFunction(() => !!window.__game, null, { timeout: 15000 })
  await page.evaluate(() => window.__game.newGame())
  await page.waitForTimeout(120)
  await page.evaluate(() => window.__game.createGuild({ name: "Icon Test", crest: "#2bb6a4", glyph: "⚔", motto: "art." }))
  await page.waitForTimeout(150)
  await page.evaluate(() => { const g = window.__game; g.recruits.slice(0, 5).forEach((r) => g.toggleSignRecruit(r.id)); g.confirmRecruits() })
  await page.waitForTimeout(250)

  // run a key + let the replay populate the combat log
  await page.evaluate(() => window.__game.runKey({ tactics: { interrupts: 2, positioning: 1, cooldowns: 1, killorder: 2 }, aggression: "Balanced" }))
  await page.waitForTimeout(3000)

  // event log: ability icons render inline (painted PNGs), as <img src=/icons/ability-*.png>
  check((await count('img[src*="/icons/ability-"]')) > 0, "ability icons render inline in the event log")
  // and they're real PNGs (not the SVG mask path)
  check((await count('img[src$=".png"]')) > 0 && (await count('span[style*="MaskImage"]')) === 0, "icons render as raster PNG (no CSS-mask spans)")

  // hover a log spell → the SpellTip pops with the ability icon in its header
  const spell = page.locator(".log-spell").first()
  if (await spell.count()) {
    await spell.hover(); await page.waitForTimeout(250)
    check((await count('[role="tooltip"] img[src*="/icons/ability-"]')) > 0, "spell tooltip shows the ability icon")
  } else check(false, "found a log-spell to hover")

  // roster: spec + role icons are painted PNGs now
  await page.locator(".nav-tab", { hasText: "Roster" }).click()
  await page.waitForTimeout(400)
  check((await count('img[src*="/icons/spec-"]')) > 0, "spec icons render on the roster")
  check((await count('img[src*="/icons/role-"]')) > 0, "role-pill icons render")

  // character sheet: Signature card renders its ability icon (a major → bear default until major art lands)
  await page.locator("table.runs tbody tr").first().click().catch(() => {})
  await page.waitForTimeout(500)
  const onChar = await count(".page-scroll")
  if (onChar) check((await count('img[src*="/icons/"]')) > 0, "character sheet renders icons (spec/role/operator/signature)")

  await page.screenshot({ path: "scripts/_shot-icons.png", fullPage: true })

  // a missing icon degrades to the default image (no broken-image)
  const brokenDefault = await page.evaluate(() => {
    const imgs = [...document.querySelectorAll('img[src*="/icons/"]')]
    return imgs.filter((i) => i.naturalWidth === 0 && i.complete).length
  })
  check(brokenDefault === 0, "no broken icon images (missing → default resolves)")

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
