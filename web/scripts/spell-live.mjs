// Verify: event-log spell names are underlined+bold and hovering one pops a WoW-style spell card next to the cursor.
import { chromium } from "playwright"
const URL = process.argv[2] ?? "http://localhost:5173"
const errors = []
const browser = await chromium.launch()
const page = await browser.newPage()
page.on("console", (m) => { if (m.type() === "error") errors.push(m.text()) })
page.on("pageerror", (e) => errors.push("pageerror: " + e.message))
try {
  await page.goto(URL, { waitUntil: "networkidle" })
  await page.waitForFunction(() => !!window.__game, null, { timeout: 15000 })
  await page.evaluate(() => window.__game.createGuild({ name: "Spell Test", crest: "#2bb6a4", glyph: "⚔", motto: "" }))
  await page.waitForSelector("text=Scouting Board", { timeout: 10000 })
  await page.evaluate(() => { const g = window.__game; g.recruits.slice(0, 5).forEach((r) => g.toggleSignRecruit(r.id)); g.confirmRecruits() })
  await page.waitForTimeout(300)
  await page.evaluate(() => window.__game.runKey({ tactics: { interrupts: 2, positioning: 1, cooldowns: 1, killorder: 2 }, aggression: "Balanced" }))
  // let the replay stream a while so ability casts (underlined spells) appear
  await page.waitForTimeout(5000)
  // pause so the auto-scroll doesn't move the element out from under the cursor
  const pauseBtn = page.locator("[title='Pause']")
  if (await pauseBtn.count()) await pauseBtn.click()
  await page.waitForTimeout(250)

  const spellCount = await page.locator(".log-spell").count()
  console.log(`underlined spell names in log: ${spellCount}`)
  if (spellCount > 0) {
    const spell = page.locator(".log-spell").last()
    const text = await spell.innerText()
    await spell.hover()
    await page.waitForTimeout(350)
    const tip = page.locator("[role='tooltip']")
    const tipShown = await tip.count()
    const tipText = tipShown ? await tip.first().innerText() : ""
    console.log(`hovered spell "${text}" → tooltip shown=${tipShown}`)
    console.log("tooltip text:\n" + tipText.split("\n").map((l) => "    " + l).join("\n"))
    await page.screenshot({ path: "scripts/_shot-spell.png" })
    const pass = spellCount > 0 && tipShown > 0 && tipText.includes(text) && errors.length === 0
    console.log(`\nconsole errors: ${errors.length}`)
    errors.slice(0, 8).forEach((e) => console.log("  ✗ " + e))
    console.log(pass ? "\nSPELL TOOLTIP PASS" : "\nSPELL TOOLTIP FAIL")
    process.exitCode = pass ? 0 : 1
  } else {
    console.log("FAIL — no underlined spell names found in the log")
    process.exitCode = 1
  }
} catch (e) {
  console.log("EXCEPTION: " + e.message)
  process.exitCode = 1
} finally { await browser.close() }
