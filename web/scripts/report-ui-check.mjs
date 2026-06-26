// Report UI overhaul live check: party-health overlay (top-left) · timer panel (top-right) · meter (bottom-right) ·
// pull ticks on the run-player · clock/par readout · runs dropdown on the Report tab · centered loot popup at run end.
// Hard gate = zero console errors + the key DOM assertions. Screenshots are for eyeballing the new layout.
import { chromium } from "playwright"
const URL = process.argv[2] ?? "http://localhost:5173"
const errors = []
const browser = await chromium.launch()
const page = await browser.newPage()
await page.setViewportSize({ width: 1920, height: 1080 })
page.on("console", (m) => { if (m.type() === "error") errors.push(m.text()) })
page.on("pageerror", (e) => errors.push("pageerror: " + e.message))
const ok = []
const check = (cond, msg) => { ok.push({ cond: !!cond, msg }); console.log((cond ? "PASS  " : "FAIL  ") + msg) }
try {
  await page.goto(URL, { waitUntil: "networkidle" })
  await page.waitForFunction(() => !!window.__game, null, { timeout: 15000 })
  await page.evaluate(() => window.__game.createGuild({ name: "UI Test", crest: "#2bb6a4", glyph: "⚔", motto: "Ship it." }))
  await page.waitForSelector("text=Scouting Board", { timeout: 10000 })
  await page.evaluate(() => { const g = window.__game; g.recruits.slice(0, 5).forEach((r) => g.toggleSignRecruit(r.id)); g.confirmRecruits() })
  await page.waitForTimeout(300)
  await page.evaluate(() => window.__game.runKey({ tactics: { interrupts: 2, positioning: 1, cooldowns: 1, killorder: 2 }, aggression: "Balanced" }))
  await page.waitForTimeout(600)

  // overlays present inside the canvas (live meter bottom-right; the Damage/Healing toggle now sits in the meter titlebar)
  await page.waitForSelector(".meter", { timeout: 8000 })
  check(await page.locator(".meter").count() > 0, "live meter renders (bottom-right)")
  check(await page.locator(".meter .meter-titlebar").getByRole("button", { name: "Damage" }).count() > 0, "Damage/Healing toggle moved into the meter titlebar (no 'Live Meter' header)")
  // swap: event log -> right rail; guild chat -> report body
  check(await page.getByRole("button", { name: "Event Log" }).count() > 0, "event log present (right rail)")
  check(await page.getByText("Guild Chat").count() > 0, "guild chat moved into the report body")
  // run-player readout uses clock / par (e.g. 0:12 / 25:00) — a '/' followed by m:ss, not the run's final length
  const readout = (await page.locator("span.mono").allInnerTexts()).find((t) => /\d+:\d\d\/\d+:\d\d/.test(t)) ?? ""
  check(/\d+:\d\d\/\d+:\d\d/.test(readout) || (await page.locator("span.mono").allInnerTexts()).some((t) => /\/\s*\d+:\d\d/.test(t)), `time readout shows clock/par ("${readout.trim()}")`)

  // let the (gated) replay run so a pull tick or two reveals, then shoot the mid-play frame
  await page.waitForTimeout(4000)
  await page.screenshot({ path: "scripts/_shot-report-ui-midplay.png" })

  // runs dropdown lives on the Report nav tab
  await page.locator('button[aria-label="Choose run"]').click()
  await page.waitForTimeout(250)
  check(await page.getByText("Runs · click to view").count() > 0, "runs dropdown opens from the Report tab")
  await page.screenshot({ path: "scripts/_shot-report-ui-runs.png" })
  await page.keyboard.press("Escape").catch(() => {})
  await page.mouse.click(960, 540)
  await page.waitForTimeout(150)

  // reveal the run (unlock transport), crank to 4×, and wait for the centered loot popup at the end
  await page.evaluate(() => { const g = window.__game; if (g.lastResult) g.markRunWatched(g.lastResult.seed) })
  await page.waitForTimeout(200)
  await page.getByRole("button", { name: "4×" }).click().catch(() => {})
  let popup = false
  for (let i = 0; i < 40; i++) { if (await page.getByText("Run Complete").count()) { popup = true; break } await page.waitForTimeout(500) }
  check(popup, "centered loot popup ('Run Complete') appears when the run ends")
  await page.screenshot({ path: "scripts/_shot-report-ui-popup.png" })

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
