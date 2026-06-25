// New Run board live check + screenshotter. Bootstraps to the playing phase, opens the New Run tab, and verifies the
// party (role icon-only + morale), aggression math, the button label, and (later) the key table. Screenshots →
// scripts/_shot-newrun-*.png (gitignored). Hard gate = asserts pass + 0 console errors. Usage:
//   node scripts/newrun-live.mjs [http://localhost:5177]
import { chromium } from "playwright"
const URL = process.argv[2] ?? "http://localhost:5177"
const errors = [], ok = []
const check = (cond, msg) => { ok.push(!!cond); console.log((cond ? "PASS  " : "FAIL  ") + msg) }
const browser = await chromium.launch()
const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } })
page.on("console", (m) => { if (m.type() === "error") errors.push(m.text()) })
page.on("pageerror", (e) => errors.push("pageerror: " + e.message))
const shot = (name) => page.screenshot({ path: `scripts/_shot-newrun-${name}.png` }).catch(() => {})

try {
  await page.goto(URL, { waitUntil: "networkidle" })
  await page.waitForFunction(() => !!window.__game, null, { timeout: 15000 })
  await page.evaluate(() => window.__game.newGame())
  await page.waitForTimeout(120)
  await page.evaluate(() => window.__game.createGuild({ name: "Run Co", crest: "#2bb6a4", glyph: "⚔", motto: "push it." }))
  await page.waitForTimeout(150)
  await page.evaluate(() => { const g = window.__game; g.recruits.slice(0, 5).forEach((r) => g.toggleSignRecruit(r.id)); g.confirmRecruits() })
  await page.waitForTimeout(300)
  check(await page.evaluate(() => window.__game.phase) === "playing", "reached playing phase")

  await page.locator(".nav-tab", { hasText: "New Run" }).click().catch(() => {})
  await page.waitForTimeout(350)
  await shot("board")

  const txt = await page.evaluate(() => document.querySelector(".app-main")?.innerText || "")
  check(/Start the Run/i.test(txt), "button reads 'Start the Run' (not Simulate/View Report)")

  // party: role icon-only (role-*.png imgs) + morale % shown
  const party = await page.evaluate(() => {
    const panels = [...document.querySelectorAll(".panel")]
    const p = panels.find((el) => /party/i.test(el.innerText.split("\n")[0]))
    if (!p) return null
    const roleImgs = [...p.querySelectorAll("img")].filter((im) => (im.getAttribute("src") || "").includes("/role-")).length
    const moraleHits = (p.innerText.match(/\d+%/g) || []).length
    return { roleImgs, moraleHits, text: p.innerText.slice(0, 160) }
  })
  check(!!party && party.roleImgs >= 1, `party rows show role icons (${party?.roleImgs})`)
  check(!!party && party.moraleHits >= 1, `party rows show morale % (${party?.moraleHits} matches)`)

  // aggression math — switch to Yolo and check the derived numbers render
  const aggroPanel = page.locator(".panel").filter({ hasText: "Aggression" })
  await aggroPanel.locator("button", { hasText: "Yolo" }).click().catch(() => {})
  await page.waitForTimeout(150)
  const aggroTxt = await aggroPanel.innerText().catch(() => "")
  check(/\+15% party output/i.test(aggroTxt) && /avoidable damage taken/i.test(aggroTxt), `aggression shows live math (Yolo) — got: ${aggroTxt.replace(/\n/g, " · ").slice(0, 140)}`)
  await aggroPanel.locator("button", { hasText: "Balanced" }).click().catch(() => {})
  await page.waitForTimeout(120)
  check(/Baseline/i.test(await aggroPanel.innerText().catch(() => "")), "Balanced shows 'Baseline — no modifiers.'")

  // key table (finding N7) — only assert if present
  const keyRows = await page.locator("[data-key-row]").count().catch(() => 0)
  if (keyRows > 0) check(keyRows >= 1, `key table present (${keyRows} rows)`)
  else console.log("(no key table yet — finding N7 not landed)")

  console.log(`\nconsole errors: ${errors.length}`)
  errors.slice(0, 12).forEach((e) => console.log("  x " + e))
  const pass = errors.length === 0 && ok.every(Boolean)
  console.log(pass ? "\nNEWRUN CHECK PASS" : "\nNEWRUN CHECK FAIL")
  process.exitCode = pass ? 0 : 1
} catch (e) {
  console.log("EXCEPTION: " + e.message)
  errors.slice(0, 12).forEach((er) => console.log("  x " + er))
  process.exitCode = 1
} finally { await browser.close() }
