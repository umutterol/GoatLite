// M.2 live check (reworked): loot drama is a SNUB, not a tax. A guardian + a berserker with an ilvl gap share
// Ashveil items, so their shared drops always carry a material delta gap. We prove: awarding to the WORSE-fit
// member fires a "Loot snub" + morale hit, while awarding the BEST FIT costs nothing (drama is opt-in).
import { chromium } from "playwright"
const URL = process.argv[2] ?? "http://localhost:5173"
const errors = []
const browser = await chromium.launch()
const page = await browser.newPage()
page.on("console", (m) => { if (m.type() === "error") errors.push(m.text()) })
page.on("pageerror", (e) => errors.push("pageerror: " + e.message))
const ok = []
const check = (cond, msg) => { ok.push({ cond: !!cond, msg }); console.log((cond ? "PASS  " : "FAIL  ") + msg) }
const snubCount = async () => (await page.locator(".guild-feed .feed-item").allInnerTexts()).filter((t) => /Loot snub/i.test(t)).length
const RUN = { tactics: { interrupts: 2, positioning: 1, cooldowns: 1, killorder: 2 }, aggression: "Balanced" }

// run keys until a drop upgrades BOTH the low- and high-ilvl member with a material gap (low has the bigger claim)
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
          const before = Object.fromEntries(g.members.map((m) => [m.id, m.morale]))
          const others = (drops.filter((x) => x.uid !== d.uid)).map((x) => [x.uid, x.upgradeFor ?? "scrap"])
          return { uid: d.uid, lowDelta: ul.delta, highDelta: uh.delta, before, others }
        }
      }
      // nothing qualifying — clear by best-fit (avoids any scrap-snub noise) and retry
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
  await page.evaluate(() => window.__game.createGuild({ name: "Snub Test", crest: "#2bb6a4", glyph: "⚔", motto: "Best fit only." }))
  await page.waitForTimeout(150)

  // reroll until a guardian + berserker with an ilvl gap ≥ 6 (so every shared drop has a material delta gap)
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
      g.rerollRecruits()
      return null
    })
    await page.waitForTimeout(70)
  }
  await page.waitForSelector(".guild-feed", { timeout: 8000 })
  check(!!info, "built a guardian + berserker comp with an ilvl gap")
  if (!info) throw new Error("could not assemble the gapped comp")
  const { lowId, highId } = info   // lowId = lower ilvl = bigger upgrade (best fit); highId = smaller claim

  // ---- BAD PICK → snub ----
  const bad = await findShared(lowId, highId)
  check(!!bad, bad ? `found a shared drop (low +${bad.lowDelta} vs high +${bad.highDelta})` : "found a shared, material-gap drop")
  if (!bad) throw new Error("no qualifying shared drop")

  // UI: the loot screen marks the best fit + flags the contest
  const lootBtn = page.getByRole("button", { name: /Distribute Loot/ })
  await lootBtn.waitFor({ timeout: 8000 }); await lootBtn.click()
  await page.waitForSelector("text=Distribute Loot", { timeout: 6000 })
  check((await page.getByText("BEST FIT").count()) > 0, "loot screen tags the BEST FIT (no-drama) choice")
  check((await page.getByText(/Wanted ×/).count()) > 0, "loot screen flags the drop as Wanted by 2+")
  await page.screenshot({ path: "scripts/_shot-drama.png", fullPage: true })

  const snubBefore = await snubCount()
  await page.evaluate(({ uid, highId, others }) => {
    const g = window.__game
    const assign = Object.fromEntries(others); assign[uid] = highId   // award to the WORSE fit → snub the bigger claim
    g.confirmLoot(assign)
  }, { uid: bad.uid, highId, others: bad.others })
  await page.waitForTimeout(300)
  const afterBad = await page.evaluate(() => Object.fromEntries(window.__game.members.map((m) => [m.id, m.morale])))
  check((await snubCount()) > snubBefore, "a bad pick fires a 'Loot snub' feed line")

  // morale: the snubbed (bigger-claim) member gained less than an uninvolved teammate — when there's headroom
  const baseId = (await page.evaluate(() => window.__game.party.map((m) => m.id))).find((id) => id !== lowId && id !== highId)
  const lowDelta = afterBad[lowId] - bad.before[lowId]
  const baseDelta = afterBad[baseId] - bad.before[baseId]
  if (bad.before[lowId] < 90 && bad.before[baseId] < 90) check(lowDelta < baseDelta, `snubbed member gained less morale than a teammate (${lowDelta} < ${baseDelta})`)
  else console.log(`(morale near clamp — skipping delta assert; snub proven by the feed line)  low Δ${lowDelta} base Δ${baseDelta}`)

  // ---- BEST FIT → no drama ----
  const good = await findShared(lowId, highId)
  check(!!good, "found a second shared drop")
  if (good) {
    const snubBefore2 = await snubCount()
    await page.evaluate(({ uid, lowId, others }) => {
      const g = window.__game
      const assign = Object.fromEntries(others); assign[uid] = lowId   // award to the BEST fit (bigger claim)
      g.confirmLoot(assign)
    }, { uid: good.uid, lowId, others: good.others })
    await page.waitForTimeout(300)
    check((await snubCount()) === snubBefore2, "awarding the BEST FIT fires NO snub (drama is opt-in)")
  }

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
