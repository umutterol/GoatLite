// UI-pass live check + screenshotter (theme/icons/Raider.io rows/WoW-chat/watch-gate). Drives the live app via the
// window.__game store + nav clicks, screenshots each surface to scripts/_shot-*.png, and (Commit 5) asserts the
// watch-gate. Hard gate = 0 console errors. Usage: node scripts/ui-pass-live.mjs [http://localhost:5173]
import { chromium } from "playwright"
const URL = process.argv[2] ?? "http://localhost:5173"
const errors = []
const browser = await chromium.launch()
const page = await browser.newPage({ viewport: { width: 1480, height: 900 } })
page.on("console", (m) => { if (m.type() === "error") errors.push(m.text()) })
page.on("pageerror", (e) => errors.push("pageerror: " + e.message))
const ok = []
const check = (cond, msg) => { ok.push({ cond: !!cond, msg }); console.log((cond ? "PASS  " : "FAIL  ") + msg) }
const tab = async (label) => { await page.locator(".nav-tab", { hasText: label }).click().catch(() => {}); await page.waitForTimeout(350) }
const shot = (name) => page.screenshot({ path: `scripts/_shot-${name}.png`, fullPage: true }).catch(() => {})

try {
  await page.goto(URL, { waitUntil: "networkidle" })
  await page.waitForFunction(() => !!window.__game, null, { timeout: 15000 })
  await page.evaluate(() => window.__game.newGame())
  await page.waitForTimeout(120)
  await page.evaluate(() => window.__game.createGuild({ name: "Flat Pixel", crest: "#2bb6a4", glyph: "⚔", motto: "ship it." }))
  await page.waitForTimeout(150)
  // opening draft → sign 5, confirm (lands on New Run, phase=playing)
  await page.evaluate(() => { const g = window.__game; g.recruits.slice(0, 5).forEach((r) => g.toggleSignRecruit(r.id)); g.confirmRecruits() })
  await page.waitForTimeout(300)
  check(await page.evaluate(() => window.__game.phase) === "playing", "reached playing phase")

  // ---- font sanity: UI reverted to IBM Plex Sans; Pixelify is scoped to the chat (+ item display) ----
  const bodyFam = await page.evaluate(() => getComputedStyle(document.body).fontFamily)
  check(/IBM Plex Sans/i.test(bodyFam) && !/pixelify/i.test(bodyFam), `body font = IBM Plex Sans, not Pixelify (got: ${bodyFam})`)
  const chatFam = await page.evaluate(() => { const el = document.querySelector(".guild-feed"); return el ? getComputedStyle(el).fontFamily : "" })
  check(/pixelify/i.test(chatFam), `chat (.guild-feed) font = Pixelify (got: ${chatFam})`)

  // ---- no CSS gradients anywhere in the live DOM (flat-colors gate) ----
  const grad = await page.evaluate(() => {
    let n = 0
    for (const el of document.querySelectorAll("*")) {
      const bg = getComputedStyle(el).backgroundImage
      if (bg && bg.includes("gradient")) n++
    }
    return n
  })
  check(grad === 0, `0 gradient backgrounds in the live DOM (found ${grad})`)

  await shot("setup")
  await tab("Roster"); await shot("roster")
  // open first roster member's character sheet
  await page.locator("table.runs tbody tr").first().click().catch(() => {})
  await page.waitForTimeout(400); await shot("character")
  await tab("Recruit"); await shot("recruit")

  // ---- run a key → report (autoplay) ----
  await tab("New Run")
  await page.locator("button", { hasText: "Simulate Run" }).click().catch(() => {})
  await page.waitForTimeout(900)
  await shot("report-gated")
  // guild feed (WoW chat) is the right aside while playing
  await page.locator(".guild-feed, aside").first().screenshot({ path: "scripts/_shot-feed.png" }).catch(() => {})

  // ---- C5 watch-gate: results hidden + transport locked until the replay plays out ----
  const distSel = "button:has-text('Distribute Loot'), button:has-text('Continue → Keystone')"
  check(await page.locator("button:has-text('Watch the run to reveal')").count() === 1, "gated: 'Watch the run…' button shown")
  check(await page.locator(distSel).count() === 0, "gated: loot/continue button hidden")
  const speedBtn = page.locator(".seg-group button:has-text('4×')").first()
  check(await speedBtn.isDisabled().catch(() => false), "gated: speed dial (4×) locked")
  check(await page.locator("input[type=range]").first().isDisabled().catch(() => false), "gated: scrubber locked")
  // the deferred feed line must NOT have leaked the outcome yet (no 'Timed/Depleted/Wiped in' line)
  check(!/\b(Timed|Depleted|Wiped) in \d/.test(await page.locator(".guild-feed").innerText().catch(() => "")), "gated: outcome not yet in the chat feed")

  // let the forced 1× watch play out (RATE 40 → ~35-50s real), then results reveal + feed flushes
  await page.locator(distSel).first().waitFor({ timeout: 80000 }).catch(() => {})
  check(await page.locator(distSel).count() === 1, "revealed: Distribute/Continue appears after the replay finished")
  check(/\b(Timed|Depleted|Wiped) in \d/.test(await page.locator(".guild-feed").innerText().catch(() => "")), "revealed: outcome line flushed to the chat feed")
  await shot("report-revealed")

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
