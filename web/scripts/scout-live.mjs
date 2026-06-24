// Scouting-board (Recruit page) live check + screenshotter for the scout-panel redesign.
// Bootstraps to the scouting board, selects recruits, screenshots the panel, optionally opens the Talents popup,
// and gates on 0 console errors. Screenshots → scripts/_shot-scout-*.png (gitignored). Usage:
//   node scripts/scout-live.mjs [http://localhost:5177]
import { chromium } from "playwright"
const URL = process.argv[2] ?? "http://localhost:5177"
const errors = []
const ok = []
const check = (cond, msg) => { ok.push(!!cond); console.log((cond ? "PASS  " : "FAIL  ") + msg) }
const browser = await chromium.launch()
const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } })
page.on("console", (m) => { if (m.type() === "error") errors.push(m.text()) })
page.on("pageerror", (e) => errors.push("pageerror: " + e.message))
const shot = (name) => page.screenshot({ path: `scripts/_shot-scout-${name}.png` }).catch(() => {})

try {
  await page.goto(URL, { waitUntil: "networkidle" })
  await page.waitForFunction(() => !!window.__game, null, { timeout: 15000 })
  await page.evaluate(() => window.__game.newGame())
  await page.waitForTimeout(120)
  await page.evaluate(() => window.__game.createGuild({ name: "Scout Co", crest: "#2bb6a4", glyph: "⚔", motto: "scout it." }))
  await page.waitForTimeout(250)
  check(await page.evaluate(() => window.__game.phase) === "recruit", "on the scouting board (phase=recruit)")

  const rows = page.locator("table.runs tbody tr")
  const n = await rows.count()
  check(n > 0, `recruit rows present (${n})`)
  await shot("board")

  // select a few recruits, screenshot the detail panel each time (panel = the sticky right-column .panel)
  const panel = page.locator(".panel").last()
  for (const i of [0, 1, 2].filter((i) => i < n)) {
    await rows.nth(i).click().catch(() => {})
    await page.waitForTimeout(250)
    await panel.screenshot({ path: `scripts/_shot-scout-panel-${i}.png` }).catch(() => {})
  }

  // header assertions on the selected panel: a spec icon img is present, role icon present, ilvl + morale shown
  const header = await page.evaluate(() => {
    const p = [...document.querySelectorAll(".panel")].pop()
    if (!p) return null
    const imgs = [...p.querySelectorAll("img")].map((im) => im.getAttribute("src") || "")
    const txt = p.innerText
    return { imgs: imgs.slice(0, 6), hasSpec: imgs.some((s) => s.includes("/spec-")), hasRole: imgs.some((s) => s.includes("/role-")), txt }
  })
  console.log("panel imgs:", header?.imgs, "| header text:", (header?.txt || "").slice(0, 120).replace(/\n/g, " · "))
  check(!!header?.hasSpec, "panel shows a spec icon (spec-*.png)")
  check(!!header?.hasRole, "panel shows a role icon (role-*.png)")
  check(/iLvl/i.test(header?.txt || "") || /\bmrl\b/i.test(header?.txt || ""), "panel header shows iLvl / morale block")
  check(/aptitudes/i.test(header?.txt || ""), "section renamed to Aptitudes")

  // #2: the scout panel must be ONE constant height regardless of which recruit (trait/blurb length) is selected
  const heights = []
  for (let i = 0; i < n; i++) {
    await rows.nth(i).click().catch(() => {})
    await page.waitForTimeout(120)
    heights.push(await page.evaluate(() => { const p = [...document.querySelectorAll(".panel")].pop(); return p ? p.offsetHeight : -1 }))
  }
  const uniq = [...new Set(heights)]
  check(uniq.length === 1, `scout panel is a constant height across all ${n} recruits — heights: ${uniq.join(", ")}`)

  // rarity↔ilvl invariant: no lower-rarity item may out-level a higher-rarity one (across every recruit's gear)
  const violation = await page.evaluate(() => {
    const RANK = { Common: 0, Uncommon: 1, Rare: 2, Epic: 3 }
    for (const r of window.__game.recruits) {
      const items = Object.values(r.gear || {})
      for (const a of items) for (const b of items) {
        if (RANK[a.rarity] < RANK[b.rarity] && a.ilvl > b.ilvl) return `${r.name}: ${a.rarity}@${a.ilvl} out-levels ${b.rarity}@${b.ilvl}`
      }
    }
    return null
  })
  check(!violation, `rarity↔ilvl invariant holds across all recruits' gear${violation ? " — VIOLATION " + violation : ""}`)

  // Talents (added in finding #4): a 'Talents' button opens a popup grid. Only assert if present.
  const talentsBtn = page.locator("button", { hasText: /^Talents/ }).first()
  if (await talentsBtn.count()) {
    await talentsBtn.click().catch(() => {})
    await page.waitForTimeout(250)
    await shot("talents-popup")
    const cells = await page.locator("[data-talent-cell]").count().catch(() => 0)
    check(cells === 15, `talents popup shows 15 cells (5x3) — got ${cells}`)
  } else {
    console.log("(no Talents button yet — finding #4 not landed)")
  }

  console.log(`\nconsole errors: ${errors.length}`)
  errors.slice(0, 12).forEach((e) => console.log("  x " + e))
  const pass = errors.length === 0 && ok.every(Boolean)
  console.log(pass ? "\nSCOUT CHECK PASS" : "\nSCOUT CHECK FAIL")
  process.exitCode = pass ? 0 : 1
} catch (e) {
  console.log("EXCEPTION: " + e.message)
  errors.slice(0, 12).forEach((er) => console.log("  x " + er))
  process.exitCode = 1
} finally { await browser.close() }
