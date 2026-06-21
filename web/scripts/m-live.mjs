// Phase M.1 live check: the always-visible Guild Feed + the system-notification stream.
// Drives the store (window.__game) through guild → recruit → run → loot and asserts the feed panel
// renders the neutral notifications (founding, joins, run filed, loot dropped, keystone change).
// Hard gate = zero console errors + every assertion green.
import { chromium } from "playwright"
const URL = process.argv[2] ?? "http://localhost:5173"
const errors = []
const browser = await chromium.launch()
const page = await browser.newPage()
page.on("console", (m) => { if (m.type() === "error") errors.push(m.text()) })
page.on("pageerror", (e) => errors.push("pageerror: " + e.message))
const ok = []
const check = (cond, msg) => { ok.push({ cond: !!cond, msg }); console.log((cond ? "PASS  " : "FAIL  ") + msg) }
const feedText = () => page.locator(".guild-feed .feed-item").allInnerTexts()

try {
  await page.goto(URL, { waitUntil: "networkidle" })
  await page.waitForFunction(() => !!window.__game, null, { timeout: 15000 })

  // reset to a clean save so the feed starts empty
  await page.evaluate(() => window.__game.newGame())
  await page.waitForTimeout(150)

  // onboarding: the feed is NOT shown during create/recruit (only when playing)
  await page.evaluate(() => window.__game.createGuild({ name: "Feed Test", crest: "#2bb6a4", glyph: "⚔", motto: "Log it." }))
  await page.waitForTimeout(200)
  const feedDuringOnboard = await page.locator(".guild-feed").count()
  check(feedDuringOnboard === 0, "feed hidden during onboarding (recruit phase)")

  // sign 5 + confirm → enters play; the panel should now be visible with founding + join lines
  await page.evaluate(() => { const g = window.__game; g.recruits.slice(0, 5).forEach((r) => g.toggleSignRecruit(r.id)); g.confirmRecruits() })
  await page.waitForSelector(".guild-feed", { timeout: 8000 })
  check(true, "feed panel visible once playing")

  let items = await feedText()
  const founding = items.filter((t) => /founded/i.test(t)).length
  const joins = items.filter((t) => /joined the guild/i.test(t)).length
  check(founding >= 1, "feed shows the guild-founding line")
  check(joins >= 5, `feed shows a join line per new member (got ${joins})`)
  const beforeRun = items.length

  // run a key, then distribute the loot through the store
  await page.evaluate(() => window.__game.runKey({ tactics: { interrupts: 2, positioning: 1, cooldowns: 1, killorder: 2 }, aggression: "Balanced" }))
  await page.waitForTimeout(500)
  items = await feedText()
  const runLine = items.filter((t) => /(Timed|Depleted|Wiped) in \d/i.test(t)).length
  check(runLine >= 1, "feed shows the run-filed line (outcome + time)")

  await page.evaluate(() => {
    const g = window.__game
    const drops = g.pendingLoot ?? []
    const assign = {}
    for (const d of drops) assign[d.uid] = d.upgradeFor ?? d.upgrades?.[0]?.memberId ?? "scrap"
    g.confirmLoot(assign)
  })
  await page.waitForTimeout(400)
  items = await feedText()
  const keystoneLine = items.filter((t) => /keystone (upgraded|depleted)/i.test(t)).length
  check(keystoneLine >= 1, "feed shows the keystone change after loot")
  check(items.length > beforeRun, `feed grew after the run (${beforeRun} → ${items.length})`)

  // a member-tagged line is clickable → navigates to the character sheet
  const clickable = page.locator(".guild-feed .feed-item.clickable").last()
  check((await clickable.count()) > 0, "feed has clickable member-tagged entries")
  await clickable.click()
  await page.waitForTimeout(300)
  const onChar = await page.locator(".page-scroll").count()
  check(onChar > 0, "clicking a feed entry navigates (character sheet)")

  await page.screenshot({ path: "scripts/_shot-feed.png", fullPage: true })

  console.log(`\nfeed lines: ${items.length}`)
  items.slice(-10).forEach((t) => console.log("  · " + t.replace(/\s+/g, " ").trim()))
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
