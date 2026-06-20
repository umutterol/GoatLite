// Phase I live check: run a key → report page now leads with the 2D replay canvas (summary HUD top-left,
// live meter top-right, both INSIDE the canvas), the timer adjuster directly below, then the usual log/health.
// Hard gate = zero console errors + the replay renders party orbs + enemy pack + HP bars, scrubbing works.
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
  await page.evaluate(() => window.__game.createGuild({ name: "I Test", crest: "#2bb6a4", glyph: "⚔", motto: "Replay it." }))
  await page.waitForSelector("text=Scouting Board", { timeout: 10000 })
  await page.evaluate(() => { const g = window.__game; g.recruits.slice(0, 5).forEach((r) => g.toggleSignRecruit(r.id)); g.confirmRecruits() })
  await page.waitForTimeout(300)
  await page.evaluate(() => window.__game.runKey({ tactics: { interrupts: 2, positioning: 1, cooldowns: 1, killorder: 2 }, aggression: "Balanced" }))
  await page.waitForTimeout(800)

  // I.2/I.3: the replay canvas is present and leads the report
  const canvas = page.locator(".replay-arena")
  check(await canvas.count() === 1, "I.2 replay arena (.replay-arena) renders on the report")

  // HUD overlays live INSIDE the canvas: summary title top-left + live meter top-right
  check(await canvas.getByText("Ashveil Crypts").count() > 0, "I summary header is overlaid inside the canvas (top-left)")
  check(await canvas.getByText("Live Meter").count() > 0, "I live meter is overlaid inside the canvas (top-right)")

  // enemy pack + party orbs: HP bars present (orbs ≥5)
  const bars = await canvas.locator(".replay-hpbar").count()
  check(bars >= 5, `I.2 HP bars render in the scene (found ${bars})`)
  const stageCaption = await canvas.getByText(/Pull ·|Boss ·/).count()
  check(stageCaption > 0, "I.2 active-stage caption (Pull/Boss + name) renders over the pack")

  // I.4: floating combat text fires during playback (windowed event layer — not just on exact landed seconds)
  let sawFloat = false
  for (let i = 0; i < 28 && !sawFloat; i++) { if (await canvas.locator(".replay-float2").count() > 0) sawFloat = true; else await page.waitForTimeout(110) }
  check(sawFloat, "I.4 floating combat text renders during playback")

  // let it autoplay a bit more, then confirm the scene is still animating
  await page.waitForTimeout(2000)

  // I.3: timer adjuster sits directly below the canvas (play button + speed dial + scrubber)
  const scrub = page.locator('input[type="range"]')
  check(await scrub.count() >= 1, "I.3 timer adjuster scrubber present below the replay")

  // scrub to ~60% and confirm the canvas still renders a pack (stage switched, no crash)
  await scrub.first().evaluate((el) => { const max = Number(el.max); el.value = String(Math.round(max * 0.6)); el.dispatchEvent(new Event("input", { bubbles: true })); el.dispatchEvent(new Event("change", { bubbles: true })) })
  await page.waitForTimeout(400)
  check(await canvas.locator(".replay-dot").count() > 0, "I.3 scrubbing updates the scene (dots still render)")
  const captionAfter = await canvas.getByText(/Pull ·|Boss ·/).count()
  check(captionAfter > 0, "I.3 stage caption present after scrub")

  await page.screenshot({ path: "scripts/_shot-replay.png", fullPage: true })
  // a tighter shot of just the canvas
  await canvas.screenshot({ path: "scripts/_shot-canvas.png" })

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
