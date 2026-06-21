// M.2 live check: loot drama. Builds a 1T/1H/3D party with TWO same-spec DPS (so a spec-restricted drop
// upgrades both → contested), finds a contested drop, awards it through the UI, and asserts the consequences:
// the ⚔ Contested badge on the loot screen, the "Contested:" feed line, the winner's +5% buff, and the snub morale.
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
  await page.evaluate(() => window.__game.newGame())
  await page.waitForTimeout(120)
  await page.evaluate(() => window.__game.createGuild({ name: "Drama Test", crest: "#2bb6a4", glyph: "⚔", motto: "Mine." }))
  await page.waitForTimeout(150)

  // The Ashveil loot table only has guardian/cleric/berserker items (several multi-spec). A guardian + a
  // berserker share 6 of the 12 items → they contest often. Reroll until the pool has both, then field them
  // with a healer + 2 DPS. (Reroll must span separate evaluates so React re-renders between draws.)
  let setup = null
  for (let tries = 0; tries < 40 && !setup; tries++) {
    setup = await page.evaluate(() => {
      const g = window.__game
      const recs = g.recruits
      const guardian = recs.find((r) => r.specId === "guardian")
      const berserker = recs.find((r) => r.specId === "berserker")
      if (guardian && berserker) {
        const heal = recs.find((r) => r.role === "healer")
        const otherDps = recs.filter((r) => r.role === "dps" && r.id !== berserker.id).slice(0, 2)
        const party = [guardian, heal, berserker, ...otherDps].filter(Boolean)
        party.forEach((r) => g.toggleSignRecruit(r.id))
        g.confirmRecruits()
        return { ok: true }
      }
      g.rerollRecruits()
      return null
    })
    await page.waitForTimeout(70)   // let React re-render so the next draw is fresh
  }
  await page.waitForSelector(".guild-feed", { timeout: 8000 })
  check(!!setup, "built a guardian + berserker comp (share Ashveil loot-table items)")

  // run keys until a drop is contested (2+ party members would upgrade it)
  let found = null
  for (let i = 0; i < 30 && !found; i++) {
    await page.evaluate(() => window.__game.runKey({ tactics: { interrupts: 2, positioning: 1, cooldowns: 1, killorder: 2 }, aggression: "Balanced" }))
    await page.waitForTimeout(120)
    found = await page.evaluate(() => {
      const g = window.__game
      const drops = g.pendingLoot ?? []
      const d = drops.find((x) => (x.upgrades ?? []).filter((u) => u.delta > 0).length >= 2)
      if (d) {
        const ups = d.upgrades.filter((u) => u.delta > 0)
        const before = Object.fromEntries(g.members.map((m) => [m.id, m.morale]))
        return { uid: d.uid, name: d.name, winner: ups[0].memberId, loser: ups[1].memberId, before }
      }
      g.confirmLoot({})   // not contested — clear and try again
      return null
    })
  }
  check(!!found, found ? `found a contested drop: ${found.name}` : "found a contested drop within 30 runs")
  if (!found) throw new Error("no contested drop surfaced")

  // UI: open the loot screen from the report and assert the ⚔ Contested badge
  const lootBtn = page.getByRole("button", { name: /Distribute Loot/ })
  await lootBtn.waitFor({ timeout: 8000 })
  await lootBtn.click()
  await page.waitForSelector("text=Distribute Loot", { timeout: 6000 })
  const badge = await page.getByText("⚔ Contested").count()
  check(badge > 0, "loot screen shows the ⚔ Contested badge")
  await page.screenshot({ path: "scripts/_shot-drama.png", fullPage: true })

  // award the contested item to the winner, scrap the rest (deterministic, via the store)
  await page.evaluate(({ uid, winner }) => {
    const g = window.__game
    const assign = {}
    for (const d of g.pendingLoot ?? []) assign[d.uid] = d.uid === uid ? winner : "scrap"
    g.confirmLoot(assign)
  }, found)
  await page.waitForTimeout(300)   // dispatch is async — let React apply + refresh window.__game before reading
  const after = await page.evaluate(() => ({
    members: Object.fromEntries(window.__game.members.map((m) => [m.id, { morale: m.morale, buff: m.lootBuffPct }])),
  }))

  // the contested feed line fired
  const feedLines = await page.locator(".guild-feed .feed-item").allInnerTexts()
  const contestedLine = feedLines.filter((t) => /Contested:.*took.*over/i.test(t)).length
  check(contestedLine >= 1, "feed shows the 'Contested:' drama line")

  // winner got the +5% buff
  check(after.members[found.winner]?.buff === 5, `winner carries a +5% output buff (got ${after.members[found.winner]?.buff})`)

  // snub cost: the loser gained less morale than the winner this run (robust to the timed +10 and the 0..100 clamp)
  const wBefore = found.before[found.winner], lBefore = found.before[found.loser]
  const wDelta = after.members[found.winner].morale - wBefore
  const lDelta = after.members[found.loser].morale - lBefore
  if (wBefore < 90 && lBefore < 90) check(lDelta < wDelta, `loser gained less morale than the winner (loser ${lDelta} < winner ${wDelta})`)
  else console.log(`(morale near clamp — skipping delta assert; path proven by feed + buff)  winner Δ${wDelta} loser Δ${lDelta}`)

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
