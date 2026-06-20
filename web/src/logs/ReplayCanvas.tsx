/* Phase I (v2) — faked-spatial 2D replay arena, modeled on EGM's combat playback.
   Our web sim is band-based (no x/y), so positions here are DERIVED deterministically (team → front/back column,
   role/index spread, seeded jitter) and given a gentle idle bob — the dots are cosmetic, the sim is untouched.
   Combatants render as portrait/glyph dots with HP bars on a dungeon-tinted arena; attacks fire as targeting
   lines + ranged projectiles + melee swipes + impact bursts + arcing pop-in damage numbers, all derived from the
   existing event log (windowed, gated to playback so scrubbing shows a static frame). Deterministic + scrub-safe.
   The summary header + live meter ride in as hudLeft/hudRight overlays. */
import { useEffect, useLayoutEffect, useMemo, useRef, useState, type CSSProperties, type ReactNode } from "react"
import { content } from "@/content"
import type { Member } from "@/data/game"
import type { RunResult, ReplayMob } from "@/sim"
import { roleOf } from "@/state/game-store"
import { hpAt, mc } from "./analytics"
import { Icon } from "./components"

const H = 800                 // canvas height (px) — tall arena so the pack-to-pack travel + scrum read clearly
const ARENA_TOP = 90          // arena starts below the HUD band (summary / meter overlays)
const ARENA_BOT = H - 16
const ARENA_H = ARENA_BOT - ARENA_TOP

/* deterministic 0..1 hash (positions/jitter/idle-phase are stable per id → scrub-safe) */
function hashF(s: string): number { let h = 2166136261; for (let i = 0; i < s.length; i++) { h ^= s.charCodeAt(i); h = Math.imul(h, 16777619) } return (h >>> 0) / 4294967295 }
function hue(s: string): number { let h = 0; for (let i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) >>> 0; return h % 360 }
const clamp = (v: number, lo: number, hi: number) => Math.max(lo, Math.min(hi, v))
const spreadY = (i: number, n: number) => (n <= 1 ? 0.5 : 0.18 + (i / (n - 1)) * 0.64)

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
  ax: number; ay: number        // home position in arena units [0,1]
}

export function ReplayCanvas({ result, clock, playing, members, dungeonId, hudLeft, hudRight }: {
  result: RunResult; clock: number; playing: boolean; members: Member[]; dungeonId: string; hudLeft?: ReactNode; hudRight?: ReactNode
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

  // ---- party dots: front column (melee, incl. tank) vs back column (casters/healer) ----
  const hp = hpAt(result, clock)
  const partyDots = useMemo<Array<Dot & { pid: string }>>(() => {
    const meta = result.partyMeta.map((pm) => ({
      pid: pm.id, name: pm.name, specId: pm.specId, role: roleOf(pm.specId),
      back: (content.specs.get(pm.specId)?.position ?? "Front") === "Back",
      portrait: members.find((m) => m.id === pm.id)?.portrait,
    }))
    const front = meta.filter((m) => !m.back), back = meta.filter((m) => m.back)
    const place = (list: typeof meta, x: number) => list.map((m, i) => ({
      key: "p:" + m.pid, pid: m.pid, team: "party" as const, name: m.name, specId: m.specId, portrait: m.portrait,
      isBoss: false, isTank: m.role === "tank", ranged: m.back, frac: 1, dead: false, ax: x, ay: spreadY(i, list.length),
    }))
    return [...place(front, 0.24), ...place(back, 0.08)]
  }, [result, members])

  // ---- enemy dots from the active stage (boss centered; trash split front/back like the bands) ----
  const enemyDots: Dot[] = useMemo(() => {
    const boss = stageMobs.find((m) => m.isBoss)
    const ef = stageMobs.filter((m) => !m.isBoss && m.band === "front")
    const eb = stageMobs.filter((m) => !m.isBoss && m.band === "back")
    const place = (list: ReplayMob[], x: number) => list.map((m, i) => ({
      key: "e:" + m.id, team: "enemy" as const, name: m.name, isBoss: false, ranged: m.band === "back",
      frac: 1, dead: false, ax: x, ay: spreadY(i, list.length),
    }))
    // spawn FAR RIGHT (away from the party) so the party visibly travels across to engage → "pack to pack" feel
    const dots: Dot[] = [...place(ef, 0.80), ...place(eb, 0.93)]
    if (boss) dots.push({ key: "e:" + boss.id, team: "enemy", name: boss.name, isBoss: true, ranged: false, frac: 1, dead: false, ax: 0.74, ay: 0.5 })
    return dots
  }, [stage?.idx, tl]) // eslint-disable-line react-hooks/exhaustive-deps

  // ---- movement: fake EGM-style engagement (the sim has no positions, so this is purely cosmetic) ----
  // Both sides leave their start columns and CLOSE into a central melee scrum: the TANK anchors the contact line,
  // **enemy melee pile onto the tank**, party melee-dps join around it; **ranged hold back and KITE (strafe)** so
  // they're not static. `eng` ramps over the stage's first seconds (the charge-in); a melee press-sway + a
  // per-attack lunge (below) keep the scrum churning. The CSS `.replay-dot` transition smooths it frame-to-frame.
  const rawFrac = (d: Dot) => d.team === "party" ? (hp[d.key.slice(2)] ?? 1) : mobHpFrac(stageMobs.find((m) => "e:" + m.id === d.key)!, sec)
  const stageStart = stage?.startSec ?? 0
  // SLOW ramp (vs the old 2.5) so the cross-arena travel to the new pack is actually visible at playback speed
  const eng = clamp((clock - stageStart) / 16, 0, 1)
  const SCRUM_Y = 0.5
  const enemyMelee = enemyDots.filter((d) => !d.isBoss && !d.ranged)
  const partyMeleeDps = partyDots.filter((d) => !d.ranged && !d.isTank)
  const spread = (list: Dot[], d: Dot, gap: number) => { const n = Math.max(1, list.length), i = Math.max(0, list.indexOf(d)); return clamp(SCRUM_Y + (i - (n - 1) / 2) * gap, 0.12, 0.88) }
  // the contact/scrum forms on the RIGHT (where the pack stands): the party travels across to it, enemies converge onto the tank
  const engaged = (d: Dot): { ex: number; ey: number } => {
    if (d.team === "party") {
      if (d.ranged) return { ex: 0.30, ey: d.ay }
      if (d.isTank) return { ex: 0.50, ey: SCRUM_Y }
      return { ex: 0.45, ey: spread(partyMeleeDps, d, 0.10) }
    }
    if (d.isBoss) return { ex: 0.66, ey: SCRUM_Y }
    if (d.ranged) return { ex: 0.84, ey: d.ay }
    return { ex: 0.58, ey: spread(enemyMelee, d, 0.085) }   // enemy melee converge onto the tank at the contact line
  }
  // on the first frame of a new pack, snap the (persistent) party dots to their start column instead of sliding them
  // back from the previous pack's contact — so each stage reads as "enter, then charge the pack", not "retreat".
  const prevStageRef = useRef(-1)
  const stageChanged = stage != null && stage.idx !== prevStageRef.current
  useEffect(() => { if (stage) prevStageRef.current = stage.idx })

  const place = (d: Dot) => {
    const frac = rawFrac(d)
    const ph = hashF(d.key) * 6.283, ph2 = hashF(d.key + "z") * 6.283
    const jx = (hashF(d.key + "x") - 0.5) * 0.03, jy = (hashF(d.key + "y") - 0.5) * 0.05
    const { ex, ey } = engaged(d)
    let ax = (d.ax + jx) * (1 - eng) + (ex + jx) * eng
    let ay = (d.ay + jy) * (1 - eng) + (ey + jy) * eng
    if (d.ranged) { ax += Math.sin(clock * 0.33 + ph) * 0.03 * eng; ay += Math.cos(clock * 0.27 + ph2) * 0.045 * eng }  // ranged kite/strafe
    else if (!d.isBoss) ax += Math.sin(clock * 0.5 + ph) * 0.012 * eng                                                  // melee press into the contact
    ax = clamp(ax + Math.cos(clock * 0.9 + ph) * 0.004, 0.04, 0.96)   // idle bob
    ay = clamp(ay + Math.sin(clock * 0.8 + ph) * 0.007, 0.08, 0.92)
    return { ...d, frac, dead: frac <= 0.001, px: ax * W, py: ARENA_TOP + ay * ARENA_H, axPct: ax * 100 }
  }
  const dots = [...partyDots.map(place), ...enemyDots.map(place)]
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
      background: `radial-gradient(130% 95% at 50% -10%, hsl(${bg} 22% 15%), hsl(${bg} 30% 6%) 72%)`,
    }}>
      {/* abstract floor (placeholder for real dungeon art) */}
      <div style={{ position: "absolute", left: "6%", right: "6%", top: ARENA_TOP + ARENA_H * 0.5, height: 1, background: `linear-gradient(90deg, transparent, hsl(${bg} 35% 42% / .35), transparent)` }} />
      <div style={{ position: "absolute", left: 0, right: 0, bottom: 0, height: 120, background: `linear-gradient(180deg, transparent, hsl(${bg} 32% 5%))` }} />

      {/* HUD overlays */}
      {hudLeft ? <div style={{ position: "absolute", top: 10, left: 12, zIndex: 6, maxWidth: "50%" }}>{hudLeft}</div> : null}
      {hudRight ? <div style={{ position: "absolute", top: 10, right: 12, zIndex: 6, width: 286, maxWidth: "42%" }}>{hudRight}</div> : null}
      {stage ? <div className="eyebrow" style={{ position: "absolute", top: 64, left: 0, right: 0, textAlign: "center", zIndex: 3, color: stage.kind === "boss" ? "var(--amber)" : "var(--faint)", fontSize: 10.5 }}>{stage.kind === "boss" ? "Boss" : "Pull"} · {stage.name}</div> : null}

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
        {dots.map((d) => <DotView key={d.key} d={d} lunge={lunge.get(d.key)} snap={stageChanged} />)}
      </div>

      {/* projectiles / impacts / floats / death bursts / flashes */}
      <div style={{ position: "absolute", inset: 0, pointerEvents: "none", zIndex: 5 }}>
        {flashes.map((f) => (
          <div key={f.key} className="replay-flash" style={{ background: `radial-gradient(120% 90% at 70% 50%, ${f.tint.replace(",1)", ",.3)")}, transparent 60%)` }}>
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
function DotView({ d, lunge, snap }: { d: Dot & { px: number; py: number; axPct: number; frac: number; dead: boolean }; lunge?: { x: number; y: number }; snap?: boolean }) {
  const info = d.specId ? mc(d.specId) : null
  const size = d.isBoss ? 50 : d.team === "party" ? 38 : 30
  const pct = Math.round(d.frac * 100)
  const ring = d.team === "party" ? (info?.color ?? "#6cc") : d.isBoss ? "var(--amber)" : "#7a2f33"
  const barColor = d.dead ? "#3a3d48"
    : d.team === "party" ? (d.frac > 0.5 ? "var(--good)" : d.frac > 0.25 ? "var(--amber)" : "var(--danger)")
    : "linear-gradient(90deg,#e0626b,#f0a52e)"
  const m = lunge && !d.dead ? (Math.hypot(lunge.x, lunge.y) || 1) : 1
  const lx = lunge && !d.dead ? (lunge.x / m) * 11 : 0, ly = lunge && !d.dead ? (lunge.y / m) * 11 : 0
  return (
    <div className="replay-dot" style={{ left: d.axPct + "%", top: d.py, width: Math.max(size, 54), opacity: d.dead ? 0.45 : 1, transform: `translate(-50%,-50%) translate(${lx.toFixed(1)}px,${ly.toFixed(1)}px)`, transition: snap ? "none" : undefined }}>
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 3 }}>
        <span aria-label={`${d.name} ${pct}%`} style={{
          position: "relative", width: size, height: size, borderRadius: d.isBoss ? 13 : "50%", flex: "none",
          border: `2px solid ${ring}`, overflow: "hidden", background: d.team === "party" ? (info?.color ?? "#244") : d.isBoss ? "radial-gradient(circle at 40% 30%,#5a2e1a,#1c0e0c)" : "radial-gradient(circle at 40% 30%,#5b2226,#210d0f)",
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
