// M7b live check: the per-spec talent picker renders 5 tiers × 3 options on the Character sheet,
// picking an option persists to the member, and tooltips/labels show seconds (never "turn"). Hard gate = 0 console errors.
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
  await page.evaluate(() => window.__game.createGuild({ name: "Talent Test", crest: "#2bb6a4", glyph: "⚔", motto: "spec." }))
  await page.waitForTimeout(150)
  await page.evaluate(() => { const g = window.__game; g.recruits.slice(0, 5).forEach((r) => g.toggleSignRecruit(r.id)); g.confirmRecruits() })
  await page.waitForTimeout(250)

  // open the first roster member's Character sheet
  await page.locator(".nav-tab", { hasText: "Roster" }).click()
  await page.waitForTimeout(300)
  await page.locator(".roster-card, [data-roster-card], .card").first().click().catch(() => {})
  await page.waitForTimeout(400)
  // fall back: some layouts open the char sheet from a table row
  if (!(await count('.panel:has(.panel-title:has-text("Talents"))'))) {
    await page.locator("table.runs tbody tr").first().click().catch(() => {})
    await page.waitForTimeout(400)
  }

  const talents = page.locator('.panel:has(.panel-title:has-text("Talents"))').first()
  check(await talents.count() > 0, "Talents panel renders on the Character sheet")

  // 5 tier headers (.eyebrow) and 15 option buttons (5 tiers × 3)
  const tiers = await talents.locator(".eyebrow").count()
  const opts = await talents.locator("button").count()
  check(tiers === 5, `5 per-spec tiers shown (got ${tiers})`)
  check(opts === 15, `15 options shown (5×3) (got ${opts})`)

  // the panel text must be seconds-clean (never "turn")
  const panelText = (await talents.innerText().catch(() => "")) || ""
  check(!/\bturns?\b/i.test(panelText), "talent text uses seconds, never 'turn'")

  // picking an option persists to the open member's talents map (read the whole roster — we don't know which member the sheet shows)
  const rosterTalents = () => page.evaluate(() => (window.__game.members ?? []).map((m) => JSON.stringify(m.talents ?? {})).join("|"))
  const before = await rosterTalents()
  // click the FIRST option of the first tier (every spec's tier-1 default is option index 2, so index 0 is always a real change)
  await talents.locator("button").nth(0).click().catch(() => {})
  await page.waitForTimeout(250)
  const after = await rosterTalents()
  check(before !== after, `talent pick persists to the open member (changed: ${before !== after})`)

  // Signature card cooldown label shows seconds (Ns CD), not "~60s" hardcode artifact / "turn"
  const sig = page.locator('.panel:has(.panel-title:has-text("Signature"))').first()
  if (await sig.count()) {
    const sigText = await sig.innerText().catch(() => "")
    check(/\d+s CD|No CD/.test(sigText) && !/\bturns?\b/i.test(sigText), `Signature shows seconds CD (got "${sigText.split("\n")[0] ?? ""}")`)
  }

  await page.screenshot({ path: "scripts/_shot-talents.png", fullPage: true })

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
