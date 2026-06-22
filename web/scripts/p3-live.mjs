// P.3 live check: the dispel-typing content (new Lifebinder ability "Unbinding Word", the creeping-rot status, the
// mass-dispel description change) loads and renders without breaking the app. Boots, creates a guild, signs a comp
// (preferring a Lifebinder), runs a key (engine + replay exercise the new content path), opens a character sheet, and
// asserts ZERO console errors + no broken icons. Needs a dev server (default :5174).
import { chromium } from "playwright"
const URL = process.argv[2] ?? "http://localhost:5174"
const errors = []
const browser = await chromium.launch()
const page = await browser.newPage()
page.on("console", (m) => { if (m.type() === "error") errors.push(m.text()) })
page.on("pageerror", (e) => errors.push("pageerror: " + e.message))
const ok = []
const check = (cond, msg) => { ok.push(!!cond); console.log((cond ? "PASS  " : "FAIL  ") + msg) }

try {
  await page.goto(URL, { waitUntil: "networkidle" })
  await page.waitForFunction(() => !!window.__game, null, { timeout: 15000 })
  await page.evaluate(() => window.__game.newGame())
  await page.waitForTimeout(120)
  await page.evaluate(() => window.__game.createGuild({ name: "Mire Test", crest: "#3a7d44", glyph: "S", motto: "drain it." }))
  await page.waitForTimeout(200)

  // sign a comp; prefer a Lifebinder so Unbinding Word is on a real roster member (best-effort — random pool)
  const lbSigned = await page.evaluate(() => {
    const g = window.__game
    const lb = g.recruits.find((r) => r.specId === "lifebinder")
    const picks = [lb, ...g.recruits.filter((r) => r !== lb)].filter(Boolean).slice(0, 5)
    picks.forEach((r) => g.toggleSignRecruit(r.id)); g.confirmRecruits()
    return !!lb
  })
  console.log(lbSigned ? "info  Lifebinder present in comp" : "info  no Lifebinder in random pool (still exercises run + sheet)")
  await page.waitForTimeout(250)

  // run a key — exercises the engine + replay with the P.3 content loaded
  await page.evaluate(() => window.__game.runKey({ tactics: { interrupts: 0, positioning: 0, cooldowns: 3, killorder: 3 }, aggression: "Balanced" }))
  await page.waitForTimeout(3000)
  check((await page.locator(".log-spell").count()) > 0, "combat log populated (run completed without crashing)")

  // open the roster + a character sheet (exercises ability/spell rendering with the new content)
  await page.locator(".nav-tab", { hasText: "Roster" }).click().catch(() => {})
  await page.waitForTimeout(400)
  await page.locator(".roster-card, [class*=roster] [class*=card]").first().click().catch(() => {})
  await page.waitForTimeout(400)
  const broken = await page.evaluate(() => [...document.querySelectorAll('img[src*="/icons/"]')].filter((i) => i.naturalWidth === 0 && i.complete).length)
  check(broken === 0, "no broken icon images")

  await page.screenshot({ path: "scripts/_shot-p3.png", fullPage: true })
  console.log(`\nconsole errors: ${errors.length}`)
  errors.slice(0, 12).forEach((e) => console.log("  x " + e))
  const pass = errors.length === 0 && ok.every(Boolean)
  console.log(pass ? "\nLIVE CHECK PASS" : "\nLIVE CHECK FAIL")
  process.exitCode = pass ? 0 : 1
} catch (e) {
  console.log("EXCEPTION: " + e.message)
  console.log(`console errors so far: ${errors.length}`)
  errors.slice(0, 12).forEach((er) => console.log("  x " + er))
  process.exitCode = 1
} finally { await browser.close() }
