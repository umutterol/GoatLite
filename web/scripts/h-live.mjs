// Phase H live check: a major fires with a ✦ MAJOR accent in the log, and the Character sheet shows a Signature card.
import { chromium } from "playwright"
const URL = process.argv[2] ?? "http://localhost:5173"
const errors = []
const browser = await chromium.launch()
const page = await browser.newPage()
page.on("console", (m) => { if (m.type() === "error") errors.push(m.text()) })
page.on("pageerror", (e) => errors.push("pageerror: " + e.message))
const ok = []
const check = (c, m) => { ok.push(!!c); console.log((c ? "PASS  " : "FAIL  ") + m) }
try {
  await page.goto(URL, { waitUntil: "networkidle" })
  await page.waitForFunction(() => !!window.__game, null, { timeout: 15000 })
  await page.evaluate(() => window.__game.createGuild({ name: "H Test", crest: "#2bb6a4", glyph: "⚔", motto: "" }))
  await page.waitForSelector("text=Scouting Board", { timeout: 10000 })
  await page.evaluate(() => { const g = window.__game; g.recruits.slice(0, 5).forEach((r) => g.toggleSignRecruit(r.id)); g.confirmRecruits() })
  await page.waitForTimeout(300)
  await page.evaluate(() => window.__game.runKey({ tactics: { interrupts: 2, positioning: 1, cooldowns: 1, killorder: 2 }, aggression: "Balanced" }))
  await page.waitForTimeout(5000)

  // H.2: gold ✦ MAJOR lines in the replay log
  const majorLines = await page.getByText("✦ MAJOR").count()
  check(majorLines > 0, `replay log has ✦ MAJOR lines (${majorLines})`)
  // a major spell name should also be an underlined LogSpell with a tooltip
  const majorNames = await page.getByText(/Bulwark Banner|Sacred Bastion|Unmoving Mountain|Light's Salvation|Blossoming Tide|Reckless Frenzy|Killing Edge|Rallying Crescendo|Emberstorm|Nullifying Surge/).count()
  check(majorNames > 0, `major spell names render in the log (${majorNames})`)

  // H.2: Character-sheet Signature card
  await page.locator(".nav-tab", { hasText: "Roster" }).click()
  await page.waitForSelector("table.runs tbody tr", { timeout: 6000 })
  await page.locator("table.runs tbody tr").first().click()
  await page.waitForSelector("text=Operator", { timeout: 6000 })
  const sig = await page.locator(".panel-title", { hasText: "Signature" }).count()
  check(sig > 0, "Character sheet shows a Signature card")
  // H.3: all 5 talent nodes now show in the picker
  const talentNodes = await page.locator(".eyebrow", { hasText: /Tempo|Defensive|Affix|Survival|Single/ }).count()
  check(talentNodes >= 3, `talent picker shows nodes 3-5 too (${talentNodes} node headers)`)

  console.log(`\nconsole errors: ${errors.length}`)
  errors.slice(0, 10).forEach((e) => console.log("  ✗ " + e))
  const pass = errors.length === 0 && ok.every(Boolean)
  console.log(pass ? "\nH LIVE CHECK PASS" : "\nH LIVE CHECK FAIL")
  process.exitCode = pass ? 0 : 1
} catch (e) { console.log("EXCEPTION: " + e.message); process.exitCode = 1 } finally { await browser.close() }
