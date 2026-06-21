// M.3 live check: barks render in the guild feed (speaker in spec colour + italic line), and a loot SNUB
// produces a flagship bark from the snubbed member. Reuses the gapped guardian+berserker comp from M.2.
import { chromium } from "playwright"
const URL = process.argv[2] ?? "http://localhost:5173"
const errors = []
const browser = await chromium.launch()
const page = await browser.newPage()
page.on("console", (m) => { if (m.type() === "error") errors.push(m.text()) })
page.on("pageerror", (e) => errors.push("pageerror: " + e.message))
const ok = []
const check = (cond, msg) => { ok.push({ cond: !!cond, msg }); console.log((cond ? "PASS  " : "FAIL  ") + msg) }
const barkCount = () => page.locator(".guild-feed .feed-item.bark").count()
const RUN = { tactics: { interrupts: 2, positioning: 1, cooldowns: 1, killorder: 2 }, aggression: "Balanced" }

async function findShared(lowId, highId) {
  for (let i = 0; i < 30; i++) {
    await page.evaluate((cfg) => window.__game.runKey(cfg), RUN)
    await page.waitForTimeout(120)
    const r = await page.evaluate(({ lowId, highId }) => {
      const g = window.__game
      const drops = g.pendingLoot ?? []
      for (const d of drops) {
        const ul = (d.upgrades || []).find((u) => u.memberId === lowId && u.delta > 0)
        const uh = (d.upgrades || []).find((u) => u.memberId === highId && u.delta > 0)
        if (ul && uh && ul.delta - uh.delta >= 5) {
          const others = drops.filter((x) => x.uid !== d.uid).map((x) => [x.uid, x.upgradeFor ?? "scrap"])
          return { uid: d.uid, name: d.name, others }
        }
      }
      g.confirmLoot(Object.fromEntries(drops.map((x) => [x.uid, x.upgradeFor ?? "scrap"])))
      return null
    }, { lowId, highId })
    if (r) return r
  }
  return null
}

try {
  await page.goto(URL, { waitUntil: "networkidle" })
  await page.waitForFunction(() => !!window.__game, null, { timeout: 15000 })
  await page.evaluate(() => window.__game.newGame())
  await page.waitForTimeout(120)
  await page.evaluate(() => window.__game.createGuild({ name: "Bark Test", crest: "#2bb6a4", glyph: "⚔", motto: "speak." }))
  await page.waitForTimeout(150)

  let info = null
  for (let tries = 0; tries < 60 && !info; tries++) {
    info = await page.evaluate(() => {
      const g = window.__game
      const recs = g.recruits
      const guardian = recs.find((r) => r.specId === "guardian")
      const berserker = recs.find((r) => r.specId === "berserker")
      if (guardian && berserker && Math.abs(guardian.ilvl - berserker.ilvl) >= 6) {
        const heal = recs.find((r) => r.role === "healer")
        const otherDps = recs.filter((r) => r.role === "dps" && r.id !== berserker.id).slice(0, 2);
        [guardian, heal, berserker, ...otherDps].filter(Boolean).forEach((r) => g.toggleSignRecruit(r.id))
        g.confirmRecruits()
        const gLow = guardian.ilvl < berserker.ilvl
        return { lowId: "m-" + (gLow ? guardian.id : berserker.id), highId: "m-" + (gLow ? berserker.id : guardian.id) }
      }
      g.rerollRecruits(); return null
    })
    await page.waitForTimeout(70)
  }
  await page.waitForSelector(".guild-feed", { timeout: 8000 })
  check(!!info, "built a guardian + berserker comp with an ilvl gap")
  if (!info) throw new Error("no gapped comp")
  const { lowId, highId } = info
  const lowName = await page.evaluate((id) => window.__game.members.find((m) => m.id === id)?.name, lowId)

  const bad = await findShared(lowId, highId)
  check(!!bad, bad ? `found a shared drop: ${bad.name}` : "found a shared drop")
  if (!bad) throw new Error("no shared drop")

  const before = await barkCount()
  await page.evaluate(({ uid, highId, others }) => {
    const g = window.__game
    const assign = Object.fromEntries(others); assign[uid] = highId   // award the worse fit → snub the bigger claim
    g.confirmLoot(assign)
  }, { uid: bad.uid, highId, others: bad.others })
  await page.waitForTimeout(300)

  const after = await barkCount()
  check(after > before, `the snub produced a bark (${before} → ${after})`)
  const speakers = await page.locator(".guild-feed .feed-item.bark .feed-bark-name").allInnerTexts()
  check(speakers.includes(lowName), `the snubbed member (${lowName}) speaks in their own voice`)
  check((await page.locator(".guild-feed .feed-item.bark .feed-bark-text").count()) > 0, "barks render italic, speaker-attributed (distinct from system lines)")
  const barkTexts = await page.locator(".guild-feed .feed-item.bark .feed-bark-text").allInnerTexts()
  await page.screenshot({ path: "scripts/_shot-barks.png", fullPage: true })

  console.log("\nbarks so far:")
  barkTexts.slice(-6).forEach((t) => console.log("  💬 " + t.replace(/\s+/g, " ").trim()))
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
