// P.1b live check: the Bard→Archer recut renders with no runtime breakage.
// Verifies the spec displays as "Archer" on the recruit board, the app survives a full run
// (sim + replay exercise the recut abilities), the spec-archer icon degrades cleanly to a
// placeholder (no broken image), and there are ZERO console errors. Needs a dev server.
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
  await page.evaluate(() => window.__game.createGuild({ name: "Archer Test", crest: "#2bb6a4", glyph: "➶", motto: "loose." }))
  await page.waitForTimeout(200)

  // the old support spec is GONE and the new name is present on the scouting board (128 recruits → archers exist)
  const archerCount = await page.evaluate(() => window.__game.recruits.filter((r) => r.specId === "bard").length)
  check(archerCount > 0, `recruit pool contains archer-spec recruits (${archerCount})`)
  const bodyTxt = await page.evaluate(() => document.body.innerText)
  check(/Archer/.test(bodyTxt), '"Archer" spec name renders in the UI')
  check(!/\bBard\b/.test(bodyTxt), 'no stale "Bard" label remains')

  // sign 5 (force an archer in if one is available) + run a key — exercises the recut abilities through the sim + replay
  await page.evaluate(() => {
    const g = window.__game
    const archer = g.recruits.find((r) => r.specId === "bard")
    const picks = [archer, ...g.recruits.filter((r) => r !== archer)].filter(Boolean).slice(0, 5)
    picks.forEach((r) => g.toggleSignRecruit(r.id)); g.confirmRecruits()
  })
  await page.waitForTimeout(250)
  await page.evaluate(() => window.__game.runKey({ tactics: { interrupts: 2, positioning: 1, cooldowns: 1, killorder: 2 }, aggression: "Balanced" }))
  await page.waitForTimeout(3000)
  check((await count(".log-spell")) > 0, "combat log populated (run completed without crashing)")

  // roster renders; spec-archer icon degrades to a placeholder, not a broken image
  await page.locator(".nav-tab", { hasText: "Roster" }).click().catch(() => {})
  await page.waitForTimeout(400)
  const broken = await page.evaluate(() => [...document.querySelectorAll('img[src*="/icons/"]')].filter((i) => i.naturalWidth === 0 && i.complete).length)
  check(broken === 0, "no broken icon images (spec-archer → placeholder resolves)")

  await page.screenshot({ path: "scripts/_shot-archer.png", fullPage: true })
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
