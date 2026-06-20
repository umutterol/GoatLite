/* Phase I — 2D "abstract packs" replay canvas.
   One dungeon-tinted backdrop; the party as portrait orbs on the left, the active stage's enemies as a
   pack of tokens on the right split into front/back rows. HP bars drain, packs slide in stage-by-stage,
   floating combat text + boss-mechanic flashes + death bursts fire off the deterministic event log.
   Driven purely by the playback `clock` (seconds) — no internal timers; scrub-safe. The summary header
   and live meter ride in as `hudLeft` / `hudRight` overlays (per the report layout). */
import { useEffect, useMemo, useRef, type ReactNode } from "react"
import type { Member } from "@/data/game"
import type { RunResult, ReplayMob } from "@/sim"
import { roleOf } from "@/state/game-store"
import { hpAt, mc, ROLE_ORDER } from "./analytics"
import { Icon } from "./components"

const H = 400                 // canvas height (px) — fixed so float anchors can use pixel math
const BODY_TOP = 84           // enemy area / general scene top (clears the short meter title band)
const BODY_BOT = H - 16
const BODY_H = BODY_BOT - BODY_TOP
const PARTY_TOP = 132         // party column starts lower-left, clearing the taller summary HUD card
const PARTY_H = BODY_BOT - PARTY_TOP

/* dungeon → a stable hue for the abstract backdrop (swapped for real art later) */
function hashHue(s: string): number { let h = 0; for (let i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) >>> 0; return h % 360 }

/* HP fraction (0..1) of a replay mob at a whole second — forward-fills sparse samples, 0 once dead */
function mobHpFrac(m: ReplayMob, sec: number): number {
  if (m.deathSec !== null && sec >= m.deathSec) return 0
  const i = sec - m.spawnSec
  if (i < 0) return 1
  for (let k = Math.min(i, m.hp.length - 1); k >= 0; k--) { const v = m.hp[k]; if (v !== undefined) return v }
  return 1
}

interface Float { key: string; x: string; y: number; color: string; txt: string; big: boolean }
interface Burst { key: string; x: string; y: number; side: "party" | "enemy" }
interface Flash { key: string; tint: string; label: string }

export function ReplayCanvas({ result, clock, playing, members, dungeonId, hudLeft, hudRight }: {
  result: RunResult; clock: number; playing: boolean; members: Member[]; dungeonId: string; hudLeft?: ReactNode; hudRight?: ReactNode
}) {
  const hue = hashHue(dungeonId)
  const sec = Math.floor(clock)
  const tl = result.replay

  // party orbs (role-sorted, live HP from the per-second series)
  const hp = hpAt(result, clock)
  const orbs = useMemo(() =>
    result.partyMeta
      .map((pm) => ({ id: pm.id, name: pm.name, specId: pm.specId, role: roleOf(pm.specId), portrait: members.find((m) => m.id === pm.id)?.portrait }))
      .sort((a, b) => ROLE_ORDER[a.role] - ROLE_ORDER[b.role]),
    [result, members])
  const orbY = (i: number) => PARTY_TOP + ((i + 0.5) / Math.max(1, orbs.length)) * PARTY_H
  // float/burst anchors are keyed by member NAME (the log carries target names, not ids). Two party members with
  // the exact same display name would anchor to one orb — cosmetic only (misplaced flourish); a faithful fix would
  // add LogMeta.targetId, deferred to avoid churning the balance-critical combat emit sites for a nit.
  const orbIdx = new Map(orbs.map((o, i) => [o.name, i]))

  // active stage = the latest one whose window has started; its mobs split into front/back rows
  const stage = useMemo(() => {
    if (!tl?.stages.length) return null
    let s = tl.stages[0]
    for (const st of tl.stages) if (sec >= st.startSec) s = st
    return s
  }, [tl, sec])
  const mobs = tl && stage ? tl.mobs.filter((m) => m.stageIdx === stage.idx) : []
  const boss = mobs.find((m) => m.isBoss)
  const back = mobs.filter((m) => !m.isBoss && m.band === "back")
  const front = mobs.filter((m) => !m.isBoss && m.band === "front")

  // event-driven layer: collect everything in the window of whole seconds newly crossed since the last render.
  // The playback clock jumps ~5 sim-sec per tick (more at higher speeds), so an `=== sec` gate would drop most
  // events; instead we cover (from, sec]. The ref is advanced in an effect (StrictMode-safe). Transient flourish
  // (floats/flashes/bursts) only plays while PLAYING — a paused/scrubbed frame shows the static scene, not a
  // burst of replayed numbers — which also caps any pile-up from a big jump (MAX_WIN is a further safety).
  const MAX_WIN = 6
  const prevSecRef = useRef(-1)
  const from = Math.max(clock < prevSecRef.current ? sec - 1 : prevSecRef.current, sec - MAX_WIN)
  useEffect(() => { prevSecRef.current = sec })
  const inWin = (s: number | null | undefined): boolean => playing && s != null && s > from && s <= sec

  const floats: Float[] = result.log
    .filter((e) => inWin(e.tSec) && (e.meta?.amount ?? 0) > 0)
    .sort((a, b) => (b.meta!.amount ?? 0) - (a.meta!.amount ?? 0))
    .slice(0, 7)
    .map((e, j) => {
      const amt = e.meta!.amount ?? 0
      const pIdx = e.meta?.target ? orbIdx.get(e.meta.target) : undefined
      const isHeal = e.kind === "heal"
      const isCrit = e.kind === "crit"
      const fromPlayer = !!e.meta?.sourceId            // a party member dealt it (→ enemy)
      const onParty = pIdx !== undefined
      const color = isHeal ? "var(--good)" : isCrit ? "var(--amber)" : onParty && !fromPlayer ? "var(--danger)" : "#ffe3e3"
      const x = onParty ? "16%" : "70%"
      const y = onParty ? orbY(pIdx!) - 16 : BODY_TOP + BODY_H * (j % 2 ? 0.62 : 0.34) + ((j * 23) % 18) - 9
      return { key: `${e.tSec}:${j}`, x, y, color, txt: (isHeal ? "+" : "") + amt.toLocaleString(), big: isCrit }
    })

  const flashes: Flash[] = result.log
    .filter((e) => e.kind === "mechanic" && inWin(e.tSec))
    .slice(0, 2)
    .map((e, j) => {
      const src = e.meta?.sourceName ?? ""
      const tint = src === "Volcanic" ? "hsla(28,90%,55%,1)" : src === "Sanguine" ? "hsla(348,80%,55%,1)" : "hsla(276,70%,62%,1)"
      return { key: `${e.tSec}:mech:${j}`, tint, label: e.meta?.ability ?? "Mechanic" }
    })

  const bursts: Burst[] = [
    ...result.deaths.filter((d) => inWin(d.tSec)).map((d, j) => {
      const i = orbIdx.get(d.name)
      return { key: `${d.tSec}:pd:${j}`, x: "16%", y: i !== undefined ? orbY(i) : PARTY_TOP + PARTY_H / 2, side: "party" as const }
    }),
    // enemy bursts read the FULL timeline (not just the active stage) so a boundary-killed mob — whose stage has
    // already flipped at its death second — still flashes its skull (the active-stage filter would hide it).
    ...(tl?.mobs ?? []).filter((m) => inWin(m.deathSec)).slice(0, 6).map((m, j) => (
      { key: `${m.deathSec}:ed:${m.id}`, x: `${64 + (j % 3) * 9}%`, y: BODY_TOP + BODY_H * (m.band === "back" ? 0.34 : 0.62), side: "enemy" as const }
    )),
  ]

  return (
    <div className="panel replay-stage" style={{
      position: "relative", height: H, overflow: "hidden", padding: 0,
      background: `radial-gradient(130% 95% at 50% -10%, hsl(${hue} 22% 16%), hsl(${hue} 28% 7%) 72%)`,
    }}>
      {/* abstract floor + depth (placeholder for real dungeon art) */}
      <div style={{ position: "absolute", left: 0, right: 0, bottom: 52, height: 1, background: `linear-gradient(90deg, transparent, hsl(${hue} 35% 42% / .45), transparent)` }} />
      <div style={{ position: "absolute", left: 0, right: 0, bottom: 0, height: 66, background: `linear-gradient(180deg, transparent, hsl(${hue} 32% 5%))` }} />

      {/* HUD overlays (summary top-left, live meter top-right) */}
      {hudLeft ? <div style={{ position: "absolute", top: 10, left: 12, zIndex: 4, maxWidth: "52%" }}>{hudLeft}</div> : null}
      {hudRight ? <div style={{ position: "absolute", top: 10, right: 12, zIndex: 4, width: 290, maxWidth: "44%" }}>{hudRight}</div> : null}

      {/* ---- scene: party column (left) + enemy pack (right) ---- */}
      <div style={{ position: "absolute", left: 0, right: 0, top: BODY_TOP, height: BODY_H }}>
        {/* party orbs (lower-left band, below the summary HUD card) */}
        <div style={{ position: "absolute", left: 14, top: PARTY_TOP - BODY_TOP, bottom: 0, width: 168, display: "flex", flexDirection: "column", justifyContent: "space-around" }}>
          {orbs.map((o) => <Orb key={o.id} o={o} frac={hp[o.id] ?? 1} />)}
        </div>

        {/* enemy pack */}
        <div className="replay-pack" key={stage?.idx ?? 0} style={{ position: "absolute", left: 200, right: 16, top: 0, bottom: 0, display: "flex", flexDirection: "column", justifyContent: "center", gap: 12 }}>
          {stage ? (
            <div className="eyebrow" style={{ textAlign: "center", color: stage.kind === "boss" ? "var(--amber)" : "var(--faint)", fontSize: 10.5 }}>
              {stage.kind === "boss" ? "Boss" : "Pull"} · {stage.name}
            </div>
          ) : null}
          {boss ? (
            <div style={{ display: "flex", justifyContent: "center" }}>
              <EnemyToken m={boss} frac={mobHpFrac(boss, sec)} />
            </div>
          ) : (
            <>
              <Row mobs={back} sec={sec} label="Back" />
              <Row mobs={front} sec={sec} label="Front" />
            </>
          )}
        </div>
      </div>

      {/* ---- event layer: floats / flashes / death bursts ---- */}
      <div style={{ position: "absolute", inset: 0, pointerEvents: "none", zIndex: 5 }}>
        {flashes.map((f) => (
          <div key={f.key} className="replay-flash" style={{ background: `radial-gradient(120% 90% at 78% 50%, ${f.tint.replace(",1)", ",.32)")}, transparent 60%)` }}>
            <span style={{ position: "absolute", top: BODY_TOP + 6, left: "70%", transform: "translateX(-50%)", color: f.tint, fontWeight: 800, fontSize: 12, letterSpacing: ".06em", textTransform: "uppercase", textShadow: "0 1px 4px #000" }}>{f.label}</span>
          </div>
        ))}
        {floats.map((f) => (
          <span key={f.key} className="replay-float" style={{ left: f.x, top: f.y, color: f.color, fontSize: f.big ? 17 : 14 }}>{f.txt}</span>
        ))}
        {bursts.map((b) => (
          <span key={b.key} className="replay-die" style={{ left: b.x, top: b.y }}>
            <Icon name="skull" size={b.side === "party" ? 26 : 20} color="var(--danger)" />
          </span>
        ))}
      </div>
    </div>
  )
}

/* a party portrait orb with a draining HP bar */
function Orb({ o, frac }: { o: { name: string; specId: string; portrait?: string }; frac: number }) {
  const info = mc(o.specId)
  const down = frac <= 0.001
  const pct = Math.round(frac * 100)
  const barColor = down ? "#3a3d48" : frac > 0.5 ? "var(--good)" : frac > 0.25 ? "var(--amber)" : "var(--danger)"
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 9 }}>
      <span aria-label={`${o.name} ${pct}%`} style={{ position: "relative", width: 40, height: 40, borderRadius: 10, flex: "none", border: `2px solid ${info.color}`, overflow: "hidden", background: info.color, filter: down ? "grayscale(1) brightness(.55)" : "none" }}>
        {o.portrait
          ? <img src={o.portrait} alt="" style={{ width: "100%", height: "100%", objectFit: "cover" }} />
          : <span style={{ display: "flex", width: "100%", height: "100%", alignItems: "center", justifyContent: "center", color: "#0c0d11", fontWeight: 700 }}>{o.name[0]}</span>}
        {down ? <span style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center" }}><Icon name="skull" size={18} color="#e0444e" /></span> : null}
      </span>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline", gap: 6 }}>
          <span style={{ color: info.color, fontWeight: 700, fontSize: 12, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{o.name}</span>
          <span className="mono" style={{ fontSize: 10.5, color: down ? "var(--danger)" : "var(--faint)", flex: "none" }}>{down ? "DOWN" : pct + "%"}</span>
        </div>
        <div style={{ height: 6, borderRadius: 4, background: "rgba(0,0,0,.45)", marginTop: 3, overflow: "hidden" }}>
          <div className="replay-hpbar" style={{ height: "100%", width: pct + "%", background: barColor, borderRadius: 4 }} />
        </div>
      </div>
    </div>
  )
}

/* a horizontal row of enemy tokens (one band) */
function Row({ mobs, sec, label }: { mobs: ReplayMob[]; sec: number; label: string }) {
  if (!mobs.length) return null
  return (
    <div style={{ display: "flex", justifyContent: "center", alignItems: "flex-start", gap: 10, flexWrap: "wrap" }}>
      <span className="eyebrow" style={{ fontSize: 9, color: "var(--faint)", alignSelf: "center", width: 30, textAlign: "right", flex: "none" }}>{label}</span>
      {mobs.map((m) => <EnemyToken key={m.id} m={m} frac={mobHpFrac(m, sec)} />)}
    </div>
  )
}

/* an enemy token: crimson chip + draining HP bar; bosses are larger + gold-bordered; dead = grayed + skull */
function EnemyToken({ m, frac }: { m: ReplayMob; frac: number }) {
  const dead = frac <= 0.001
  const size = m.isBoss ? 72 : 38
  const pct = Math.round(frac * 100)
  return (
    <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 4, width: m.isBoss ? 160 : 52, opacity: dead ? 0.4 : 1, transition: "opacity .3s" }}>
      <span aria-label={`${m.name} ${pct}%`} style={{
        position: "relative", width: size, height: size, borderRadius: m.isBoss ? 12 : 8, flex: "none",
        border: `2px solid ${m.isBoss ? "var(--amber)" : "#7a2f33"}`, overflow: "hidden",
        background: m.isBoss ? "radial-gradient(circle at 40% 30%, #5a2e1a, #1c0e0c)" : "radial-gradient(circle at 40% 30%, #5b2226, #210d0f)",
        filter: dead ? "grayscale(1) brightness(.6)" : "none", display: "flex", alignItems: "center", justifyContent: "center",
      }}>
        <span style={{ color: m.isBoss ? "var(--amber)" : "#d77b7b", fontWeight: 800, fontSize: m.isBoss ? 24 : 15 }}>{m.name[0]}</span>
        {dead ? <span style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center" }}><Icon name="skull" size={m.isBoss ? 30 : 16} color="#e0444e" /></span> : null}
      </span>
      {m.isBoss ? <span style={{ fontSize: 11, fontWeight: 700, color: "var(--amber)", textAlign: "center", lineHeight: 1.2 }}>{m.name}</span> : null}
      <div style={{ height: m.isBoss ? 6 : 4, width: m.isBoss ? 130 : 44, borderRadius: 3, background: "rgba(0,0,0,.5)", overflow: "hidden" }}>
        <div className="replay-hpbar" style={{ height: "100%", width: pct + "%", background: dead ? "#3a3d48" : "linear-gradient(90deg, #e0626b, #f0a52e)", borderRadius: 3 }} />
      </div>
    </div>
  )
}
