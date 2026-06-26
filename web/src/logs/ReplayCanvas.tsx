/* Phase I (v2) — faked-spatial 2D replay arena, modeled on EGM's combat playback.
   Our web sim is band-based (no x/y), so positions here are DERIVED deterministically (team → front/back column,
   role/index spread, seeded jitter) and given a gentle idle bob — the dots are cosmetic, the sim is untouched.
   Combatants render as portrait/glyph dots with HP bars on a dungeon-tinted arena; attacks fire as targeting
   lines + ranged projectiles + melee swipes + impact bursts + arcing pop-in damage numbers, all derived from the
   existing event log (windowed, gated to playback so scrubbing shows a static frame). Deterministic + scrub-safe.
   HUD overlays ride in as four regions: party health (top-left), timer panel (top-right), live meter
   (bottom-right), and an end-of-run popup (centered) for loot/continue. */
import { useEffect, useLayoutEffect, useMemo, useRef, useState, type CSSProperties, type ReactNode } from "react"
import { content } from "@/content"
import type { Member } from "@/data/game"
import type { RunResult, ReplayMob } from "@/sim"
import { roleOf } from "@/state/game-store"
import { hpAt, mc } from "./analytics"
import { Icon } from "./components"

const H = 640                 // canvas height (px) — arena tall enough for pack-to-pack travel to read (−20% from 800)
const ARENA_TOP = 130         // arena starts BELOW the top HUD band (party frame top-left + timer panel top-right) so combat never renders under them
const ARENA_BOT = H - 16
const ARENA_H = ARENA_BOT - ARENA_TOP

/* deterministic 0..1 hash (positions/jitter/idle-phase are stable per id → scrub-safe) */
function hashF(s: string): number { let h = 2166136261; for (let i = 0; i < s.length; i++) { h ^= s.charCodeAt(i); h = Math.imul(h, 16777619) } return (h >>> 0) / 4294967295 }
function hue(s: string): number { let h = 0; for (let i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) >>> 0; return h % 360 }
const clamp = (v: number, lo: number, hi: number) => Math.max(lo, Math.min(hi, v))
const lerp = (a: number, b: number, t: number) => a + (b - a) * t
interface V { x: number; y: number }
const unit = (x: number, y: number): V => { const m = Math.hypot(x, y) || 1; return { x: x / m, y: y / m } }

/* HP fraction of a replay mob at a whole second — forward-fills sparse samples, 0 once dead */
function mobHpFrac(m: ReplayMob, sec: number): number {
  if (m.deathSec !== null && sec >= m.deathSec) return 0
  const i = sec - m.spawnSec
  if (i < 0) return 1
  for (let k = Math.min(i, m.hp.length - 1); k >= 0; k--) { const v = m.hp[k]; if (v !== undefined) return v }
  return 1
}

interface Dot {
  key: string; team: "party" | "enemy"; name: string; specId?: string; portrait?: string
  isBoss: boolean; isTank?: boolean; ranged: boolean; frac: number; dead: boolean
}

export function ReplayCanvas({ result, clock, playing, members, dungeonId, hudTopLeft, hudTopRight, hudBottomRight, centerPopup }: {
  result: RunResult; clock: number; playing: boolean; members: Member[]; dungeonId: string
  hudTopLeft?: ReactNode; hudTopRight?: ReactNode; hudBottomRight?: ReactNode; centerPopup?: ReactNode
}) {
  const bg = hue(dungeonId)
  const sec = Math.floor(clock)
  const tl = result.replay

  // measure width so line/projectile endpoints can use pixels (x is otherwise %-based)
  const wrapRef = useRef<HTMLDivElement>(null)
  const [W, setW] = useState(0)
  useLayoutEffect(() => {
    const el = wrapRef.current; if (!el) return
    const ro = new ResizeObserver(() => setW(el.clientWidth)); ro.observe(el); setW(el.clientWidth)
    return () => ro.disconnect()
  }, [])

  // ---- active stage + its enemy pack ----
  const stage = useMemo(() => {
    if (!tl?.stages.length) return null
    let s = tl.stages[0]; for (const st of tl.stages) if (sec >= st.startSec) s = st; return s
  }, [tl, sec])
  const stageMobs = tl && stage ? tl.mobs.filter((m) => m.stageIdx === stage.idx) : []

  // ---- party dots (positions come from the path/formation below; role → melee/caster + tank) ----
  const hp = hpAt(result, clock)
  const partyDots = useMemo<Array<Dot & { pid: string }>>(() =>
    result.partyMeta.map((pm) => ({
      key: "p:" + pm.id, pid: pm.id, team: "party" as const, name: pm.name, specId: pm.specId,
      isBoss: false, isTank: roleOf(pm.specId) === "tank", ranged: (content.specs.get(pm.specId)?.position ?? "Front") === "Back",
      frac: 1, dead: false, portrait: members.find((m) => m.id === pm.id)?.portrait,
    })), [result, members])

  // ---- enemy dots from the active stage (back band → caster/ranged; boss = its own dot) ----
  const enemyDots: Dot[] = useMemo(() => {
    const dots: Dot[] = stageMobs.filter((m) => !m.isBoss).map((m) => ({
      key: "e:" + m.id, team: "enemy" as const, name: m.name, isBoss: false, ranged: m.band === "back", frac: 1, dead: false,
    }))
    const boss = stageMobs.find((m) => m.isBoss)
    if (boss) dots.push({ key: "e:" + boss.id, team: "enemy", name: boss.name, isBoss: true, ranged: false, frac: 1, dead: false })
    return dots
  }, [stage?.idx, tl]) // eslint-disable-line react-hooks/exhaustive-deps

  // ---- movement: a faked TRAVELING PATH through the dungeon (the sim has no positions; purely cosmetic) ----
  // The party does NOT reset between packs — it walks a continuous path: START → station(pack 1) → station(pack 2) → …
  // Each pack spawns at a deterministic point ANYWHERE in the arena; the party's "station" for it is a standoff short
  // of the pack on the approach side. During a stage's first seconds the party MARCHES from the previous station to
  // this one while the pack's enemies CONVERGE onto the tank; then it holds and brawls. The formation is built along
  // the engagement axis (party behind the tank, casters tight; enemies pile pack-side), so it faces whichever way the
  // next pack is. Deterministic (seeded) → scrub-safe; the CSS `.replay-dot` transition smooths it frame-to-frame.
  const seed = String(result.seed)
  const rawFrac = (d: Dot) => d.team === "party" ? (hp[d.key.slice(2)] ?? 1) : mobHpFrac(stageMobs.find((m) => "e:" + m.id === d.key)!, sec)
  const START: V = { x: 0.12, y: 0.5 }, STANDOFF = 0.13
  const path = useMemo(() => {
    const stations = new Map<number, V>(), packs = new Map<number, V>(), prevs = new Map<number, V>()
    let prev = START
    for (const st of (tl?.stages ?? [])) {
      // pack centres stay central (away from the bottom-right meter widget + the edges) — the place() clamp is a backstop
      const c: V = { x: lerp(0.30, 0.70, hashF(seed + ":" + st.idx + ":x")), y: lerp(0.28, 0.72, hashF(seed + ":" + st.idx + ":y")) }
      const u = unit(prev.x - c.x, prev.y - c.y)
      const station: V = { x: c.x + u.x * STANDOFF, y: c.y + u.y * STANDOFF }
      packs.set(st.idx, c); stations.set(st.idx, station); prevs.set(st.idx, prev); prev = station
    }
    return { stations, packs, prevs }
  }, [tl, seed]) // eslint-disable-line react-hooks/exhaustive-deps

  const stageStart = stage?.startSec ?? 0
  const TRAVEL = 14                                    // sim-seconds to march to the next pack (slow → visible)
  const eng = clamp((clock - stageStart) / TRAVEL, 0, 1)
  const A: V = (stage && path.stations.get(stage.idx)) || { x: 0.5, y: 0.5 }     // party station for this pack
  const P: V = (stage && path.packs.get(stage.idx)) || { x: 0.7, y: 0.5 }        // pack center (anywhere)
  const prevA: V = (stage && path.prevs.get(stage.idx)) || START
  const anchor: V = { x: lerp(prevA.x, A.x, eng), y: lerp(prevA.y, A.y, eng) }    // tank position mid-march
  const ax_ = unit(P.x - anchor.x, P.y - anchor.y)     // pack-ward axis from the marching anchor
  const fx_ = unit(P.x - A.x, P.y - A.y)               // final axis (enemies converge around the tank's destination)
  const perp: V = { x: -ax_.y, y: ax_.x }, fperp: V = { x: -fx_.y, y: fx_.x }
  const enemyMelee = enemyDots.filter((d) => !d.isBoss && !d.ranged)
  const enemyCasters = enemyDots.filter((d) => !d.isBoss && d.ranged)
  const partyMeleeDps = partyDots.filter((d) => !d.ranged && !d.isTank)
  const partyCasters = partyDots.filter((d) => d.ranged)
  const sOff = (list: Dot[], d: Dot, gap: number) => { const n = Math.max(1, list.length), i = Math.max(0, list.indexOf(d)); return (i - (n - 1) / 2) * gap }

  // absolute target (arena units) this frame: party marches in formation around the tank; enemies lerp from their
  // spawn (a perp line at the pack) onto the tank as the party arrives.
  const targetPos = (d: Dot): V => {
    if (d.team === "party") {
      if (d.isTank) return anchor
      if (d.ranged) { const o = sOff(partyCasters, d, 0.045); return { x: anchor.x - ax_.x * 0.085 + perp.x * o, y: anchor.y - ax_.y * 0.085 + perp.y * o } }   // casters tight, behind the tank
      const o = sOff(partyMeleeDps, d, 0.06); return { x: anchor.x - ax_.x * 0.028 + perp.x * o, y: anchor.y - ax_.y * 0.028 + perp.y * o }
    }
    let conv: V
    if (d.isBoss) conv = { x: A.x + fx_.x * 0.12, y: A.y + fx_.y * 0.12 }
    else if (d.ranged) { const o = sOff(enemyCasters, d, 0.05); conv = { x: A.x + fx_.x * 0.17 + fperp.x * o, y: A.y + fx_.y * 0.17 + fperp.y * o } }
    else { const o = sOff(enemyMelee, d, 0.055); conv = { x: A.x + fx_.x * 0.05 + fperp.x * o, y: A.y + fx_.y * 0.05 + fperp.y * o } }   // pile onto the tank
    const so = d.isBoss ? 0 : sOff(d.ranged ? enemyCasters : enemyMelee, d, 0.05)
    const spawn: V = { x: P.x + fperp.x * so, y: P.y + fperp.y * so }
    return { x: lerp(spawn.x, conv.x, eng), y: lerp(spawn.y, conv.y, eng) }   // spawn at the pack → converge on the tank
  }

  // Positions are clock-driven (the march/converge) → the .12s CSS transition interpolates them into smooth travel.
  // The gentle idle wobble is intentionally NOT done here: the playback clock jumps ~5 sim-sec/tick, so any
  // clock-based sinusoid aliases into jitter. Idle is a real-time CSS animation (`.replay-idle`) instead.
  const place = (d: Dot) => {
    const t = targetPos(d), frac = rawFrac(d)
    let ax = clamp(t.x, 0.03, 0.97); const ay = clamp(t.y, 0.06, 0.94)
    // keep combat clear of the bottom-right meter widget: nudge any dot that would land under it back to its left edge
    if (ax > 0.72 && ay > 0.55) ax = 0.72
    return { ...d, frac, dead: frac <= 0.001, px: ax * W, py: ARENA_TOP + ay * ARENA_H, axPct: ax * 100 }
  }
  // P.4: a summoned add (e.g. a guard) spawns mid-stage, so hide its dot until its spawn second — otherwise every add the
  // boss WILL summon would crowd the arena at full HP from t=0. Normal mobs spawn at stage start → always shown (unchanged).
  const spawnedNow = (d: Dot) => { if (d.team !== "enemy") return true; const m = stageMobs.find((mm) => "e:" + mm.id === d.key); return !m || sec >= m.spawnSec }
  const dots = [...partyDots.map(place), ...enemyDots.map(place)].filter(spawnedNow)
  type D = typeof dots[number]
  const partyById = new Map<string, D>(), partyByName = new Map<string, D>(), enemyById = new Map<string, D>()
  const enemyByName = new Map<string, D[]>()
  for (const d of dots) {
    if (d.team === "party") { partyById.set(d.key.slice(2), d); partyByName.set(d.name, d) }
    else { enemyById.set(d.key, d); const a = enemyByName.get(d.name); if (a) a.push(d); else enemyByName.set(d.name, [d]) }
  }
  // A pack is N copies of one enemy name, and the log carries names (not per-instance ids), so we can't tell same-
  // named mobs apart. Anchor an enemy-TARGET VFX to the LOWEST-HP living dot of that name — the one whose bar is
  // actually draining, so floating numbers land on the mob being focused — and a SOURCE to the first living one.
  const enemyTargetDot = (name: string): D | undefined => {
    const a = enemyByName.get(name); if (!a?.length) return undefined
    const pool = a.filter((d) => !d.dead); return (pool.length ? pool : a).reduce((lo, d) => (d.frac < lo.frac ? d : lo))
  }
  const enemySourceDot = (name: string): D | undefined => { const a = enemyByName.get(name); return a?.find((d) => !d.dead) ?? a?.[0] }
  const resolveTarget = (name: string): D | undefined => partyByName.get(name) ?? enemyTargetDot(name)

  // ---- event layer (windowed; gated to playback so a scrubbed frame is static) ----
  const MAX_WIN = 6
  const prevSecRef = useRef(-1)
  const from = Math.max(clock < prevSecRef.current ? sec - 1 : prevSecRef.current, sec - MAX_WIN)
  useEffect(() => { prevSecRef.current = sec })
  const inWin = (s: number | null | undefined): boolean => playing && s != null && s > from && s <= sec

  type Shot = { key: string; sx: number; sy: number; tx: number; ty: number; ranged: boolean; color: string }
  type FloatN = { key: string; x: number; y: number; color: string; txt: string; big: boolean }
  type ImpactN = { key: string; x: number; y: number; color: string }
  const shots: Shot[] = [], floats: FloatN[] = [], impacts: ImpactN[] = []
  const lunge = new Map<string, { x: number; y: number }>()   // melee attacker key → jab vector toward its target

  const hits = result.log
    .filter((e) => inWin(e.tSec) && (e.meta?.amount ?? 0) > 0)
    .sort((a, b) => (b.meta!.amount ?? 0) - (a.meta!.amount ?? 0))
    .slice(0, 8)
  hits.forEach((e, j) => {
    const amt = e.meta!.amount ?? 0
    const tgt = e.meta?.target ? resolveTarget(e.meta.target) : undefined
    const isHeal = e.kind === "heal", isCrit = e.kind === "crit"
    const fromPlayer = !!e.meta?.sourceId
    const color = isHeal ? "var(--good)" : isCrit ? "var(--amber)" : tgt?.team === "party" ? "var(--danger)" : "#ffe1e1"
    if (tgt) {
      floats.push({ key: `${e.tSec}:f${j}`, x: tgt.px, y: tgt.py - 14, color, txt: (isHeal ? "+" : "") + amt.toLocaleString(), big: isCrit })
      // a shot needs a source dot AND a measured arena (px endpoints)
      const src = fromPlayer ? partyById.get(e.meta!.sourceId!) : (e.meta?.sourceName ? enemySourceDot(e.meta.sourceName) : undefined)
      if (src && W > 0 && !isHeal && src !== tgt) {
        const sc = src.team === "party" ? "rgba(120,220,160,.75)" : "rgba(230,120,120,.7)"
        shots.push({ key: `${e.tSec}:s${j}`, sx: src.px, sy: src.py, tx: tgt.px, ty: tgt.py, ranged: src.ranged, color: sc })
        impacts.push({ key: `${e.tSec}:i${j}`, x: tgt.px, y: tgt.py, color: tgt.team === "party" ? "rgba(224,68,78,.6)" : "rgba(240,165,46,.6)" })
        if (!src.ranged) lunge.set(src.key, { x: tgt.px - src.px, y: tgt.py - src.py })   // melee jabs toward its target this beat
      }
    }
  })

  const flashes = result.log.filter((e) => e.kind === "mechanic" && inWin(e.tSec)).slice(0, 2).map((e, j) => {
    const s = e.meta?.sourceName ?? ""
    const tint = s === "Volcanic" ? "hsla(28,90%,55%,1)" : s === "Sanguine" ? "hsla(348,80%,55%,1)" : "hsla(276,70%,62%,1)"
    return { key: `${e.tSec}:m${j}`, tint, label: e.meta?.ability ?? "Mechanic" }
  })
  const deaths = [
    ...result.deaths.filter((d) => inWin(d.tSec)).map((d, j) => ({ key: `${d.tSec}:pd${j}`, dot: partyByName.get(d.name), big: true })),
    // resolve each enemy death by its precise per-mob id (active stage) so same-named mobs each flash their OWN
    // skull; a previous-stage boundary kill falls back to the name-based dot.
    ...(tl?.mobs ?? []).filter((m) => inWin(m.deathSec)).slice(0, 6).map((m, j) => ({ key: `${m.deathSec}:ed${j}`, dot: enemyById.get("e:" + m.id) ?? enemyTargetDot(m.name), big: false })),
  ].filter((d) => d.dot)

  return (
    <div ref={wrapRef} className="panel replay-arena" style={{
      position: "relative", height: H, overflow: "hidden", padding: 0,
      background: `hsl(${bg} 26% 9%)`,
    }}>
      {/* abstract floor (placeholder for real dungeon art) */}
      <div style={{ position: "absolute", left: "6%", right: "6%", top: ARENA_TOP + ARENA_H * 0.5, height: 1, background: `hsl(${bg} 35% 38% / .3)` }} />
      <div style={{ position: "absolute", left: 0, right: 0, bottom: 0, height: 120, background: `hsl(${bg} 32% 5% / .55)` }} />

      {/* HUD overlays: party health (top-left) · timer panel (top-right) · meter (bottom-right) · loot popup (centered) */}
      {hudTopLeft ? <div style={{ position: "absolute", top: 10, left: 12, zIndex: 6, maxWidth: "46%" }}>{hudTopLeft}</div> : null}
      {hudTopRight ? <div style={{ position: "absolute", top: 10, right: 12, zIndex: 6, width: 290, maxWidth: "44%" }}>{hudTopRight}</div> : null}
      {hudBottomRight ? <div style={{ position: "absolute", bottom: 12, right: 12, zIndex: 6, width: 290, maxWidth: "44%" }}>{hudBottomRight}</div> : null}
      {centerPopup ? (
        <div style={{ position: "absolute", inset: 0, zIndex: 10, display: "flex", alignItems: "center", justifyContent: "center", background: "rgba(6,7,10,.45)", backdropFilter: "blur(2px)" }}>{centerPopup}</div>
      ) : null}

      {/* SVG layer: targeting lines / melee swipes (px geometry) */}
      {W > 0 ? (
        <svg width={W} height={H} style={{ position: "absolute", inset: 0, pointerEvents: "none", zIndex: 2 }}>
          {shots.map((s) => (
            <line key={s.key} className="replay-shot" x1={s.sx} y1={s.sy} x2={s.tx} y2={s.ty}
              stroke={s.color} strokeWidth={s.ranged ? 1 : 2.5} strokeDasharray={s.ranged ? "3 4" : undefined} strokeLinecap="round" />
          ))}
        </svg>
      ) : null}

      {/* dots */}
      <div style={{ position: "absolute", inset: 0, zIndex: 3 }}>
        {dots.map((d) => <DotView key={d.key} d={d} lunge={lunge.get(d.key)} playing={playing} />)}
      </div>

      {/* projectiles / impacts / floats / death bursts / flashes */}
      <div style={{ position: "absolute", inset: 0, pointerEvents: "none", zIndex: 5 }}>
        {flashes.map((f) => (
          <div key={f.key} className="replay-flash" style={{ background: f.tint.replace(",1)", ",.16)") }}>
            <span style={{ position: "absolute", top: ARENA_TOP, left: "62%", transform: "translateX(-50%)", color: f.tint, fontWeight: 800, fontSize: 12, letterSpacing: ".06em", textTransform: "uppercase", textShadow: "0 1px 4px #000" }}>{f.label}</span>
          </div>
        ))}
        {shots.filter((s) => s.ranged).map((s) => (
          <span key={s.key + "p"} className="replay-proj" style={{ left: s.sx, top: s.sy, "--dx": `${s.tx - s.sx}px`, "--dy": `${s.ty - s.sy}px`, "--dur": "0.3s" } as CSSProperties}>
            <i style={{ width: 7, height: 7, borderRadius: "50%", background: s.color, boxShadow: `0 0 6px ${s.color}` }} />
          </span>
        ))}
        {impacts.map((im) => <span key={im.key} className="replay-impact" style={{ left: im.x, top: im.y, width: 26, height: 26, border: `2px solid ${im.color}` }} />)}
        {floats.map((f) => <span key={f.key} className="replay-float2" style={{ left: f.x, top: f.y, color: f.color, fontSize: f.big ? 18 : 14 }}>{f.txt}</span>)}
        {deaths.map((d) => <span key={d.key} className="replay-die" style={{ left: d.dot!.px, top: d.dot!.py }}><Icon name="skull" size={d.big ? 26 : 18} color="var(--danger)" /></span>)}
      </div>
    </div>
  )
}

/* one combatant: portrait/glyph dot + name + HP bar; dead → grayed + skull; melee jabs toward its target via `lunge` */
function DotView({ d, lunge, playing }: { d: Dot & { px: number; py: number; axPct: number; frac: number; dead: boolean }; lunge?: { x: number; y: number }; playing?: boolean }) {
  const info = d.specId ? mc(d.specId) : null
  const size = d.isBoss ? 50 : d.team === "party" ? 38 : 30
  const pct = Math.round(d.frac * 100)
  const ring = d.team === "party" ? (info?.color ?? "#6cc") : d.isBoss ? "var(--amber)" : "#7a2f33"
  const barColor = d.dead ? "#3a3d48"
    : d.team === "party" ? (d.frac > 0.5 ? "var(--good)" : d.frac > 0.25 ? "var(--amber)" : "var(--danger)")
    : "#e0626b"
  const m = lunge && !d.dead ? (Math.hypot(lunge.x, lunge.y) || 1) : 1
  const lx = lunge && !d.dead ? (lunge.x / m) * 11 : 0, ly = lunge && !d.dead ? (lunge.y / m) * 11 : 0
  return (
    <div className="replay-dot" style={{ left: d.axPct + "%", top: d.py, width: Math.max(size, 54), opacity: d.dead ? 0.45 : 1, transform: `translate(-50%,-50%) translate(${lx.toFixed(1)}px,${ly.toFixed(1)}px)` }}>
      <div className="replay-idle" style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 3, animationDelay: `-${(hashF(d.key) * 2.6).toFixed(2)}s`, animationPlayState: playing ? undefined : "paused" }}>
        <span aria-label={`${d.name} ${pct}%`} style={{
          position: "relative", width: size, height: size, borderRadius: d.isBoss ? 13 : "50%", flex: "none",
          border: `2px solid ${ring}`, overflow: "hidden", background: d.team === "party" ? (info?.color ?? "#244") : d.isBoss ? "#3a1e12" : "#3a1619",
          filter: d.dead ? "grayscale(1) brightness(.6)" : "none", display: "flex", alignItems: "center", justifyContent: "center",
          boxShadow: d.dead ? "none" : `0 2px 8px rgba(0,0,0,.45)`,
        }}>
          {d.team === "party" && d.portrait
            ? <img src={d.portrait} alt="" style={{ width: "100%", height: "100%", objectFit: "cover" }} />
            : <span style={{ color: d.team === "party" ? "#0c0d11" : d.isBoss ? "var(--amber)" : "#d77b7b", fontWeight: 800, fontSize: d.isBoss ? 18 : 13 }}>{d.name[0]}</span>}
          {d.dead ? <span style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center" }}><Icon name="skull" size={d.isBoss ? 24 : 15} color="#e0444e" /></span> : null}
        </span>
        {d.isBoss ? <span style={{ fontSize: 10.5, fontWeight: 700, color: "var(--amber)", whiteSpace: "nowrap", textShadow: "0 1px 3px #000" }}>{d.name}</span> : null}
        <div style={{ height: 4, width: size + 6, borderRadius: 3, background: "rgba(0,0,0,.55)", overflow: "hidden" }}>
          <div className="replay-hpbar" style={{ height: "100%", width: pct + "%", background: barColor, borderRadius: 3 }} />
        </div>
      </div>
    </div>
  )
}
