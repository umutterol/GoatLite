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
  // sign a LARGE roster (multiple waves) so the party fills (5 slots) AND there's a bench to test
  for (let i = 0; i < 3; i++) {
    await page.evaluate(() => { const g = window.__game; g.recruits.forEach((r) => g.toggleSignRecruit(r.id)); g.confirmRecruits() })
    await page.waitForTimeout(250)
  }
  check(await page.evaluate(() => window.__game.phase) === "playing", "reached playing phase")
  check(await page.evaluate(() => window.__game.members.length) > 5, `roster > 5 so there's a bench (${await page.evaluate(() => window.__game.members.length)})`)

  await page.locator(".nav-tab", { hasText: "New Run" }).click().catch(() => {})
  await page.waitForTimeout(350)
  await shot("board")

  const txt = await page.evaluate(() => document.querySelector(".app-main")?.innerText || "")
  check(/Start the Run/i.test(txt), "button reads 'Start the Run' (not Simulate/View Report)")

  // party: 5 square slots + a sortable/filterable bench (role icons + morale on bench rows)
  const slots = await page.locator("[data-party-slot]").count().catch(() => 0)
  check(slots === 5, `party shows exactly 5 square slots (${slots})`)
  const benchRows = await page.locator("[data-bench-row]").count().catch(() => 0)
  check(benchRows >= 1, `bench lists guild members (${benchRows} rows)`)
  const benchInfo = await page.evaluate(() => {
    const rows = [...document.querySelectorAll("[data-bench-row]")]
    const roleImgs = rows.flatMap((r) => [...r.querySelectorAll("img")]).filter((im) => (im.getAttribute("src") || "").includes("/role-")).length
    const morale = rows.map((r) => r.innerText).join(" ").match(/\d+%/g)?.length ?? 0
    return { roleImgs, morale }
  })
  check(benchInfo.roleImgs >= 1, `bench rows show role icons (${benchInfo.roleImgs})`)
  check(benchInfo.morale >= 1, `bench rows show morale % (${benchInfo.morale})`)
  // role filter: click "Tank" → every visible bench row is a tank (role icon = role-tank.png)
  await page.locator(".panel .seg-group button", { hasText: /^Tank$/ }).first().click().catch(() => {})
  await page.waitForTimeout(150)
  const tankOnly = await page.evaluate(() => {
    const rows = [...document.querySelectorAll("[data-bench-row]")]
    if (!rows.length) return true // 0 tanks on bench is a valid filter result
    return rows.every((r) => [...r.querySelectorAll("img")].some((im) => (im.getAttribute("src") || "").includes("/role-tank")))
  })
  check(tankOnly, "role filter (Tank) shows only tanks on the bench")
  await page.locator(".panel .seg-group button", { hasText: /^All$/ }).first().click().catch(() => {})
  await page.waitForTimeout(120)
  await shot("party")

  // aggression — 3 cards, each carries its own live math (Safe -10% / Balanced baseline / Yolo +15%)
  const aggroPanel = page.locator(".panel").filter({ hasText: "Aggression" })
  const aggroTxt = await aggroPanel.innerText().catch(() => "")
  check(/\+15% out/i.test(aggroTxt) && /-10% out/i.test(aggroTxt) && /baseline/i.test(aggroTxt),
    `aggression cards each show their math — ${aggroTxt.replace(/\n/g, " · ").slice(0, 160)}`)
  await aggroPanel.locator("button", { hasText: "Yolo" }).click().catch(() => {})  // selection still works (no crash)
  await page.waitForTimeout(120)

  // key table (finding N7) — only assert if present
  const keyRows = await page.locator("[data-key-row]").count().catch(() => 0)
  if (keyRows > 0) {
    check(keyRows >= 1, `key table present (${keyRows} rows)`)
    // N9: hovering the (purple, Epic) key name pops the KeyTip — exercise its render (it only mounts on hover)
    await page.locator("[data-key-row] span", { hasText: /Keystone/ }).first().hover().catch(() => {})
    await page.waitForTimeout(200)
    const keyTip = await page.evaluate(() => {
      const t = document.querySelector('[role="tooltip"]')
      return t ? t.innerText.slice(0, 120) : null
    })
    check(!!keyTip && /Keystone/i.test(keyTip), `KeyTip renders on hover — ${keyTip ? keyTip.replace(/\n/g, " · ") : "none"}`)
    await shot("keytip")
  } else console.log("(no key table yet — finding N7 not landed)")

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
