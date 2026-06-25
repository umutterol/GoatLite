// Verify the per-wearer primary-stat LABEL: every member's equipped gear should show that member's spec stat
// (healers/casters → Intellect, plate melee → Strength, leather physical → Agility). Power is unaffected (cosmetic).
// Usage: node scripts/item-stat-label-check.mjs [http://localhost:5177]
import { chromium } from "playwright"
const URL = process.argv[2] ?? "http://localhost:5177"
const EXPECT = {
  guardian: "Strength", berserker: "Strength", crusader: "Strength",
  assassin: "Agility", bard: "Agility", mystic: "Agility",
  cleric: "Intellect", lifebinder: "Intellect", pyromancer: "Intellect", arcanist: "Intellect",
}
const errors = [], ok = []
const check = (cond, msg) => { ok.push(!!cond); console.log((cond ? "PASS  " : "FAIL  ") + msg) }
const browser = await chromium.launch()
const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } })
page.on("pageerror", (e) => errors.push("pageerror: " + e.message))
try {
  await page.goto(URL, { waitUntil: "networkidle" })
  await page.waitForFunction(() => !!window.__game, null, { timeout: 15000 })
  await page.evaluate(() => window.__game.newGame())
  await page.waitForTimeout(120)
  await page.evaluate(() => window.__game.createGuild({ name: "Stat Co", crest: "#2bb6a4", glyph: "S", motto: "right stat." }))
  await page.waitForTimeout(150)
  for (let i = 0; i < 4; i++) { await page.evaluate(() => { const g = window.__game; g.recruits.forEach((r) => g.toggleSignRecruit(r.id)); g.confirmRecruits() }); await page.waitForTimeout(200) }

  const res = await page.evaluate((EXPECT) => {
    const bad = [], specsSeen = new Set()
    for (const m of window.__game.members) {
      specsSeen.add(m.spec)
      const want = EXPECT[m.spec] || "?"
      for (const it of Object.values(m.gear || {})) {
        if (it.mainStatType !== want) bad.push(`${m.name}/${m.spec}: ${it.slot}=${it.mainStatType} (want ${want})`)
      }
    }
    return { bad, specs: [...specsSeen], n: window.__game.members.length }
  }, EXPECT)

  console.log(`roster: ${res.n} members; specs present: ${res.specs.join(", ")}`)
  check(res.bad.length === 0, `every member's equipped gear shows their spec's stat${res.bad.length ? " — " + res.bad.slice(0, 6).join(" · ") : ""}`)
  // the interesting specs (the ones that were wrong before): assert they're exercised if present
  for (const sp of ["cleric", "mystic", "lifebinder"]) {
    if (res.specs.includes(sp)) check(true, `tested ${sp} (→ ${EXPECT[sp]})`)
    else console.log(`(no ${sp} in this roster — not exercised this run)`)
  }
  check(errors.length === 0, `0 page errors`)
  const pass = errors.length === 0 && ok.every(Boolean)
  console.log(pass ? "\nLABEL CHECK PASS" : "\nLABEL CHECK FAIL")
  process.exitCode = pass ? 0 : 1
} catch (e) { console.log("EXCEPTION: " + e.message); process.exitCode = 1 } finally { await browser.close() }
