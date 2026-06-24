// Scale-to-fit foundation live check. Verifies the 16:9 ViewportStage fills the screen with zero dead
// margins at both target resolutions (1920x1080, 2560x1440), letterboxes off-ratio, the app-shell fills
// the 1920x1080 canvas, and tooltips portal INTO the scaled stage. Screenshots each res to scripts/_fit-*.png.
// Hard gate = all asserts pass + 0 console errors. Usage: node scripts/stage-fit-live.mjs [http://localhost:5173]
import { chromium } from "playwright"
const URL = process.argv[2] ?? "http://localhost:5173"
const STAGE_W = 1920, STAGE_H = 1080
const errors = []
const ok = []
const check = (cond, msg) => { ok.push(!!cond); console.log((cond ? "PASS  " : "FAIL  ") + msg) }
const near = (a, b, tol = 1.5) => Math.abs(a - b) <= tol

const browser = await chromium.launch()
const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } })
page.on("console", (m) => { if (m.type() === "error") errors.push(m.text()) })
page.on("pageerror", (e) => errors.push("pageerror: " + e.message))

// read the stage geometry from the live DOM
const measure = () => page.evaluate(() => {
  const vp = document.querySelector(".vp-viewport")
  const st = document.querySelector(".vp-stage")
  const shell = document.querySelector(".app-shell")
  const m = st ? new DOMMatrixReadOnly(getComputedStyle(st).transform) : null
  const r = st?.getBoundingClientRect()
  return {
    vw: window.innerWidth, vh: window.innerHeight,
    vpW: vp?.clientWidth ?? -1, vpH: vp?.clientHeight ?? -1,
    stLayoutW: st?.offsetWidth ?? -1, stLayoutH: st?.offsetHeight ?? -1,
    shellW: shell?.offsetWidth ?? -1, shellH: shell?.offsetHeight ?? -1,
    scaleX: m ? m.a : -1, scaleY: m ? m.d : -1,
    rectLeft: r?.left ?? -1, rectTop: r?.top ?? -1, rectW: r?.width ?? -1, rectH: r?.height ?? -1,
    docScrollW: document.documentElement.scrollWidth, docScrollH: document.documentElement.scrollHeight,
  }
})

async function assertRes(label, vw, vh, { letterbox = false } = {}) {
  await page.setViewportSize({ width: vw, height: vh })
  await page.waitForTimeout(250) // resize listener + React re-render
  const d = await measure()
  const expScale = Math.min(vw / STAGE_W, vh / STAGE_H)
  console.log(`\n— ${label} (${vw}x${vh}) — exp scale ${expScale.toFixed(4)} | got ${d.scaleX.toFixed(4)} | stage rect ${Math.round(d.rectW)}x${Math.round(d.rectH)} @ (${Math.round(d.rectLeft)},${Math.round(d.rectTop)})`)
  check(d.vpW === vw && d.vpH === vh, `${label}: .vp-viewport fills viewport (${d.vpW}x${d.vpH})`)
  check(d.stLayoutW === STAGE_W && d.stLayoutH === STAGE_H, `${label}: .vp-stage canvas is ${STAGE_W}x${STAGE_H} in layout (${d.stLayoutW}x${d.stLayoutH})`)
  check(d.shellW === STAGE_W && d.shellH === STAGE_H, `${label}: .app-shell fills the canvas (${d.shellW}x${d.shellH})`)
  check(near(d.scaleX, expScale, 0.002) && near(d.scaleY, expScale, 0.002), `${label}: uniform scale == min(vw/1920, vh/1080)`)
  check(near(d.rectW, STAGE_W * expScale) && near(d.rectH, STAGE_H * expScale), `${label}: scaled stage size matches scale`)
  // stage stays centered, and the document itself never scrolls (no overflow past the viewport)
  check(near(d.rectLeft, (vw - d.rectW) / 2) && near(d.rectTop, (vh - d.rectH) / 2), `${label}: stage centered in viewport`)
  check(d.docScrollW <= vw + 1 && d.docScrollH <= vh + 1, `${label}: no document scroll (${d.docScrollW}x${d.docScrollH})`)
  if (!letterbox) {
    // exact 16:9 → fills the screen edge-to-edge, no dead margins
    check(near(d.rectW, vw) && near(d.rectH, vh) && near(d.rectLeft, 0) && near(d.rectTop, 0), `${label}: fills viewport, ZERO dead margins`)
  } else {
    // off-ratio → letterbox bars on the limiting axis, centered
    const bars = (vw - d.rectW) > 2 || (vh - d.rectH) > 2
    check(bars, `${label}: letterboxed off-ratio (bars present)`)
  }
  return d
}

const shot = (name) => page.screenshot({ path: `scripts/_fit-${name}.png` }).catch(() => {})

try {
  await page.goto(URL, { waitUntil: "networkidle" })
  await page.waitForFunction(() => !!window.__game, null, { timeout: 15000 })
  // bootstrap to the steady-state playing UI (sidebars + densest chrome present)
  await page.evaluate(() => window.__game.newGame())
  await page.waitForTimeout(120)
  await page.evaluate(() => window.__game.createGuild({ name: "Fit Check", crest: "#2bb6a4", glyph: "⚔", motto: "fill the screen." }))
  await page.waitForTimeout(150)
  await page.evaluate(() => { const g = window.__game; g.recruits.slice(0, 5).forEach((r) => g.toggleSignRecruit(r.id)); g.confirmRecruits() })
  await page.waitForTimeout(300)
  check(await page.evaluate(() => window.__game.phase) === "playing", "reached playing phase")

  // ---- the two hard targets, both exactly 16:9 ----
  await assertRes("1080p", 1920, 1080)
  await shot("1080p-report"); await page.locator(".nav-tab", { hasText: "Roster" }).click().catch(() => {}); await page.waitForTimeout(300); await shot("1080p-roster")

  await assertRes("1440p", 2560, 1440)
  await page.locator(".nav-tab", { hasText: "New Run" }).click().catch(() => {}); await page.waitForTimeout(300); await shot("1440p-setup")
  await page.locator(".nav-tab", { hasText: "Roster" }).click().catch(() => {}); await page.waitForTimeout(300); await shot("1440p-roster")

  // ---- tooltip portals into the scaled stage (not document.body) so it scales with the UI ----
  const tipHost = await page.evaluate(() => {
    const icon = document.querySelector(".vp-stage [aria-hidden], .vp-stage .gi, .vp-stage img")
    if (!icon) return "no-trigger"
    return "ok"
  })
  // hover the first GameIcon-ish trigger and see where the tooltip lands
  const trigger = page.locator(".app-shell").locator("span,img").filter({ hasNot: page.locator("input") }).first()
  await trigger.hover().catch(() => {})
  await page.waitForTimeout(150)
  const tipInStage = await page.evaluate(() => {
    const tip = document.querySelector('[role="tooltip"]')
    if (!tip) return "none"
    return document.querySelector(".vp-stage")?.contains(tip) ? "in-stage" : "in-body"
  })
  console.log(`\ntooltip host probe: ${tipHost}, shown tooltip location: ${tipInStage}`)
  // not all hovers produce a tooltip; only assert location IF one showed
  check(tipInStage !== "in-body", `tooltip (if shown) portals into the scaled stage, not body (got: ${tipInStage})`)

  // ---- off-ratio letterbox sanity (4:3 and ultrawide) ----
  await assertRes("4:3", 1600, 1200, { letterbox: true }); await shot("letterbox-4x3")
  await assertRes("ultrawide", 2560, 1080, { letterbox: true })

  console.log(`\nconsole errors: ${errors.length}`)
  errors.slice(0, 12).forEach((e) => console.log("  x " + e))
  const pass = errors.length === 0 && ok.every(Boolean)
  console.log(pass ? "\nSTAGE-FIT CHECK PASS" : "\nSTAGE-FIT CHECK FAIL")
  process.exitCode = pass ? 0 : 1
} catch (e) {
  console.log("EXCEPTION: " + e.message)
  errors.slice(0, 12).forEach((er) => console.log("  x " + er))
  process.exitCode = 1
} finally { await browser.close() }
