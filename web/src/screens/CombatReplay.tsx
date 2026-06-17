import { useEffect, useRef, useState, type MouseEvent as ReactMouseEvent } from "react"
import { createPortal } from "react-dom"
import { Icon, Portrait, GiltHeading } from "@/components/kit"
import { Button } from "@/components/ui/warcraftcn/button"
import { Badge } from "@/components/ui/warcraftcn/badge"
import { SPECS, specColor, type LogKind } from "@/data/game"
import { content } from "@/content"
import { useGame } from "@/state/game-store"
import type { View } from "@/components/TopBar"

const LOG_COLOR: Record<LogKind, string> = {
  normal: "#d8c8a0", crit: "#e9c869", dodge: "#9aa0a8", death: "#df7257",
  mechanic: "#e0a458", heal: "#74c46d", flavor: "#bfae84", good: "#a6cf78",
}
const OUTCOME: Record<string, { label: string; tint: string }> = {
  timed: { label: "KEY TIMED · +1", tint: "#3f7d3a" },
  depleted: { label: "DEPLETED · −1", tint: "#b9742f" },
  wipe: { label: "WIPE · −1", tint: "#9a3322" },
}
const SPEEDS = [0.5, 1, 2, 4]
const RATE = 36 // sim-seconds per real-second at 1× — a ~18min run plays in ~30s

const fmt = (s: number) => `${Math.floor(s / 60)}:${String(Math.floor(s % 60)).padStart(2, "0")}`
const fmtNum = (n: number) =>
  n >= 1e6 ? `${(n / 1e6).toFixed(1)}M` : n >= 1e3 ? `${(n / 1e3).toFixed(1)}k` : String(Math.round(n))

type SkillHover = { skillId: string; specId: string; x: number; y: number }

/* Per-skill hover card (like a WoW spell tooltip): name, category, flavour, formula, cooldown, type. */
function SkillTooltip({ skillId, specId, x, y }: SkillHover) {
  const sk = content.skills.get(skillId)
  if (!sk) return null
  const c = specColor(specId)
  const left = Math.min(x + 16, window.innerWidth - 296)
  const top = Math.min(y + 14, window.innerHeight - 210)
  const Row = ({ k, v, color }: { k: string; v: string; color?: string }) => (
    <div className="flex items-baseline justify-between gap-3">
      <span className="heading text-[9.5px] uppercase tracking-wider" style={{ color: "#9c7c45" }}>{k}</span>
      <span className="display text-[11.5px] font-semibold" style={{ color: color ?? "#ecdcb3" }}>{v}</span>
    </div>
  )
  return createPortal(
    <div style={{ position: "fixed", left, top, width: 280, zIndex: 9999, pointerEvents: "none" }}
         className="leather gilt-frame rounded-[5px] p-2.5 shadow-[0_8px_24px_rgba(0,0,0,0.6)]">
      <div className="flex items-center gap-1.5">
        <span className="h-3.5 w-[3px] rounded" style={{ background: c }} />
        <span className="display text-[13.5px] font-bold leading-tight" style={{ color: c }}>{sk.name}</span>
        <span className="ml-auto heading rounded-[3px] px-1 text-[9px] uppercase tracking-wider"
              style={{ color: "#1c1209", background: c }}>{sk.category}</span>
      </div>
      <p className="mt-1.5 text-[11px] italic leading-snug" style={{ color: "#cdbb8c" }}>{sk.description}</p>
      <div className="gilt-rule my-1.5" />
      <div className="flex flex-col gap-1">
        <Row k="Formula" v={sk.formula && sk.formula !== "0" ? sk.formula : "—"} color="#e9c869" />
        <Row k="Cooldown" v={sk.cd === 0 ? "None" : `${sk.cd} turns`} />
        <Row k="Target" v={sk.targetType} />
        {sk.damageType !== "None" && <Row k="School" v={sk.damageType} />}
      </div>
      {sk.baseValues && (
        <>
          <div className="gilt-rule my-1.5" />
          <p className="text-[9.5px] leading-snug" style={{ color: "#9c8a5e" }}>{sk.baseValues}</p>
        </>
      )}
    </div>,
    document.body,
  )
}

export function CombatReplay({ setView }: { setView: (v: View) => void }) {
  const { lastResult, rerun, fileReport, members, keystone, weekAffixes } = useGame()
  const result = lastResult

  const [clock, setClock] = useState(0)
  const [playing, setPlaying] = useState(true)
  const [speed, setSpeed] = useState(1)
  const [hover, setHover] = useState<SkillHover | null>(null)
  const logRef = useRef<HTMLDivElement>(null)

  // reaching the Replay tab with no pending run → simulate the current key
  useEffect(() => { if (!lastResult) rerun() }, [lastResult, rerun])

  // a fresh run (new seed) restarts the playback from the top
  const seed = result?.seed
  useEffect(() => { setClock(0); setPlaying(true); setHover(null) }, [seed])

  const duration = result?.durationSec ?? 0
  // advance the playback clock while playing
  useEffect(() => {
    if (!playing || !result) return
    const id = setInterval(() => setClock((c) => Math.min(duration, c + 0.1 * RATE * speed)), 100)
    return () => clearInterval(id)
  }, [playing, speed, duration, result])
  useEffect(() => { if (result && clock >= duration && playing) setPlaying(false) }, [clock, duration, playing, result])

  const visible = result ? result.log.filter((l) => l.tSec <= clock) : []
  // auto-scroll the log as new lines flow in
  useEffect(() => { const el = logRef.current; if (el && playing) el.scrollTop = el.scrollHeight }, [visible.length, playing])

  if (!result) {
    return (
      <div className="grid h-full place-items-center">
        <div className="heading text-[14px]" style={{ color: "#6b5230" }}>Simulating the pull…</div>
      </div>
    )
  }

  const oc = OUTCOME[result.outcome]
  const finished = clock >= duration
  const frac = duration ? Math.min(1, clock / duration) : 0
  const sub = result.outcome === "timed" ? `${fmt(result.timerSec - result.durationSec)} to spare.`
    : result.outcome === "depleted" ? `over time by ${fmt(Math.max(0, result.durationSec - result.timerSec))}.`
    : `loot forfeited at ${fmt(result.durationSec)}.`

  // --- live DPS meter from the cumulative damage series at the current playback time ---
  const idx = Math.min(Math.max(0, Math.floor(clock)), result.series.length - 1)
  const row = result.series[idx] ?? []
  const elapsed = Math.max(1, clock)
  const meter = result.partyMeta
    .map((p, i) => ({ ...p, dmg: row[i] ?? 0, dps: (row[i] ?? 0) / elapsed }))
    .sort((a, b) => b.dps - a.dps)
  const topDps = Math.max(1, meter[0]?.dps ?? 1)
  const totalDps = meter.reduce((s, r) => s + r.dps, 0) || 1

  const deadByNow = new Set(result.deaths.filter((d) => d.tSec <= clock).map((d) => d.name))
  const shownDeaths = result.deaths.filter((d) => d.tSec <= clock)

  const togglePlay = () => { if (finished) { setClock(0); setPlaying(true) } else setPlaying((p) => !p) }
  const seek = (e: ReactMouseEvent<HTMLDivElement>) => {
    const r = e.currentTarget.getBoundingClientRect()
    const f = Math.min(1, Math.max(0, (e.clientX - r.left) / r.width))
    setClock(f * duration); setPlaying(false)
  }

  return (
    <div className="flex h-full flex-col gap-3 p-4">
      {/* header: context · outcome (revealed at the end) · actions */}
      <div className="gilt-frame flex items-center gap-4 rounded-[5px] px-4 py-2"
           style={{ background: "linear-gradient(180deg, #f2e4bb, #e4cd93)" }}>
        <div className="flex items-center gap-2">
          <Icon name="ico-key" size={22} style={{ color: "#8c6a26" }} />
          <div className="leading-tight">
            <div className="display text-[15px] font-bold text-engraved">{keystone.dungeon} +{keystone.level}</div>
            <div className="text-[10px] heading uppercase tracking-widest" style={{ color: "#8c6a26" }}>
              {weekAffixes.map((a) => a.name).join(" · ")}
            </div>
          </div>
        </div>

        {finished ? (
          <>
            <Badge size="lg" className="!py-0.5" style={{ filter: result.outcome === "timed" ? "none" : "saturate(0.7)" }}>
              <Icon name="ico-timer" size={14} /> {oc.label}
            </Badge>
            <span className="text-[12px] italic" style={{ color: oc.tint }}>{sub}</span>
          </>
        ) : (
          <div className="flex items-center gap-2">
            <span className="display text-[16px] font-bold tabular-nums text-engraved">{fmt(clock)}</span>
            <span className="text-[12px]" style={{ color: "#8c6a26" }}>/ {fmt(duration)}</span>
            <span className="heading text-[10px] uppercase tracking-widest ember" style={{ color: "#9a6a1e" }}>● simulating</span>
          </div>
        )}

        <div className="ml-auto flex items-center gap-3">
          <Button className="!px-3 !py-1.5 text-[11px] uppercase" onClick={() => rerun()}>
            <Icon name="ico-key" size={14} /> Re-run
          </Button>
          <Button variant="frame" className="!px-3 !py-1.5 text-[11px] uppercase" onClick={() => { fileReport(); setView("guild") }}>
            <Icon name="ico-trait" size={14} /> File Report
          </Button>
        </div>
      </div>

      {/* transport: play/pause · scrubber (death markers + cursor) · speed */}
      <div className="flex items-center gap-3 px-1">
        <button onClick={togglePlay} className="transport-btn" aria-label={playing ? "Pause" : "Play"}>
          {finished ? "↻" : playing ? "❚❚" : "▶"}
        </button>
        <span className="heading w-9 text-right text-[11px] tabular-nums" style={{ color: "#8c6a26" }}>{fmt(clock)}</span>
        <div onClick={seek}
             className="group relative h-2.5 flex-1 cursor-pointer overflow-hidden rounded-full"
             style={{ background: "rgba(42,28,14,0.30)", boxShadow: "inset 0 1px 2px rgba(0,0,0,0.5)" }}>
          <div className="h-full rounded-full" style={{ width: `${frac * 100}%`, background: "linear-gradient(90deg,#b98f3c,#e6c163)" }} />
          {result.deaths.map((d, i) => (
            <span key={i} className="absolute top-1/2 h-3.5 w-1 -translate-y-1/2 rounded"
                  style={{ left: `${(d.tSec / Math.max(1, duration)) * 100}%`, background: "#df7257" }}
                  title={`${d.name} died — ${d.t}`} />
          ))}
          <span className="pointer-events-none absolute top-1/2 h-4 w-4 -translate-x-1/2 -translate-y-1/2 rounded-full"
                style={{ left: `${frac * 100}%`, background: "radial-gradient(circle at 40% 30%, #ffe9ab, #b98f3c)", boxShadow: "0 0 6px rgba(230,193,99,0.7), 0 1px 2px rgba(0,0,0,0.5)" }} />
        </div>
        <span className="heading w-9 text-[11px] tabular-nums" style={{ color: "#8c6a26" }}>{fmt(duration)}</span>
        <div className="flex items-center gap-1">
          {SPEEDS.map((s) => (
            <button key={s} onClick={() => setSpeed(s)} className="dial-btn2"
              style={{ color: speed === s ? "#160d06" : "#e6c163", background: speed === s ? "linear-gradient(#e6c163,#b98f3c)" : "linear-gradient(#3a2a18,#221608)" }}>
              {s}×
            </button>
          ))}
        </div>
      </div>

      <div className="flex min-h-0 flex-1 gap-4">
        {/* flowing event log */}
        <section className="leather gilt-frame flex min-w-0 flex-1 flex-col rounded-[5px]">
          <div className="flex items-center justify-between px-4 pt-3">
            <h2 className="heading text-[13px] font-bold uppercase tracking-[0.2em]" style={{ color: "#e6c163" }}>Event Log</h2>
            <span className="text-[10px] italic" style={{ color: "#9c7c45" }}>
              {visible.length}/{result.log.length} events · seed {result.seed}
            </span>
          </div>
          <div className="gilt-rule mx-4 my-2" />
          <div ref={logRef} className="min-h-0 flex-1 overflow-auto scroll-thin px-3 pb-3">
            {visible.map((l, i) => {
              const ac = l.meta?.sourceSpec ? specColor(l.meta.sourceSpec) : LOG_COLOR[l.kind]
              const icon = l.meta?.sourceSpec ? SPECS[l.meta.sourceSpec]?.icon : undefined
              const isDmg = (l.kind === "normal" || l.kind === "crit") && !!l.meta?.sourceSpec && !!l.meta?.target && typeof l.meta?.amount === "number"
              const isHeal = l.kind === "heal" && !!l.meta?.sourceSpec && !!l.meta?.target && typeof l.meta?.amount === "number"
              const isEvent = isDmg || isHeal
              // the skill word is its own hover target → shows ONLY that skill's tooltip
              const skillToken = l.meta?.skillId ? (
                <span className="cursor-help font-semibold underline decoration-dotted underline-offset-2"
                      style={{ color: ac, textDecorationColor: `${ac}88` }}
                      onMouseEnter={(e) => setHover({ skillId: l.meta!.skillId!, specId: l.meta!.sourceSpec!, x: e.clientX, y: e.clientY })}
                      onMouseMove={(e) => setHover((h) => (h ? { ...h, x: e.clientX, y: e.clientY } : h))}
                      onMouseLeave={() => setHover(null)}>{l.meta!.ability}</span>
              ) : (
                <span className="font-semibold" style={{ color: ac }}>{l.meta?.ability}</span>
              )
              return (
                <div key={i}
                     className="group relative flex items-center gap-2 rounded-[3px] px-1.5 py-[3px] text-[12.5px] leading-snug hover:bg-[rgba(230,193,99,0.08)]">
                  <span className="shrink-0 tabular-nums text-[11px]" style={{ color: "#a07c33" }}>[{l.t}]</span>
                  <span className="h-3.5 w-[3px] shrink-0 rounded" style={{ background: ac }} />
                  {icon
                    ? <Icon name={icon} size={13} style={{ color: ac }} className="shrink-0" />
                    : <span className="grid h-3.5 w-3.5 shrink-0 place-items-center"><span className="h-2 w-2 rounded-full" style={{ background: ac }} /></span>}
                  {isEvent && l.meta ? (
                    <span>
                      <span className="heading font-semibold" style={{ color: ac }}>{l.meta.sourceName}</span>
                      <span style={{ color: "#9c8a5e" }}> {isHeal ? "heals" : "damages"} </span>
                      <span style={{ color: isHeal ? "#86c06a" : "#e0795f" }}>{l.meta.target}</span>
                      <span style={{ color: "#9c8a5e" }}> with </span>
                      {skillToken}
                      <span style={{ color: "#9c8a5e" }}> for </span>
                      <span className="display font-bold tabular-nums" style={{ color: isHeal ? "#74c46d" : l.kind === "crit" ? "#f0cf6e" : "#ecdcb3" }}>{l.meta.amount!.toLocaleString()}</span>
                      <span style={{ color: "#9c8a5e" }}> {isHeal ? "Healing" : "Damage"}</span>
                      {l.kind === "crit" && <span className="heading font-bold" style={{ color: "#f0cf6e" }}> ✦ Crit</span>}
                    </span>
                  ) : (
                    <>
                      {l.meta?.sourceSpec && l.meta?.ability && (
                        <span className="heading shrink-0 rounded-[3px] px-1 text-[10.5px] font-semibold leading-tight"
                              style={{ color: ac, background: `${ac}1f`, border: `1px solid ${ac}55` }}>{l.meta.ability}</span>
                      )}
                      <span className={l.kind === "flavor" ? "italic" : ""} style={{ color: LOG_COLOR[l.kind] }}>{l.text}</span>
                    </>
                  )}
                  <button onClick={() => { setClock(l.tSec); setPlaying(false) }}
                          title="Jump to this moment"
                          className="ml-auto shrink-0 px-1 text-[12px] opacity-0 transition-opacity group-hover:opacity-100"
                          style={{ color: "#e6c163" }}>▷</button>
                </div>
              )
            })}
            {visible.length === 0 && (
              <div className="px-1.5 py-2 text-[12px] italic" style={{ color: "#9c7c45" }}>The font flares…</div>
            )}
          </div>
        </section>

        {/* right column */}
        <aside className="flex w-[348px] shrink-0 flex-col gap-3">
          {/* party portraits — fall as their death time passes */}
          <div className="flex justify-between gap-1.5">
            {result.finalHpPct.map((h) => {
              const m = members.find((x) => x.id === h.id)
              const dead = deadByNow.has(h.name)
              return (
                <div key={h.id} className="flex flex-col items-center gap-1">
                  <div className="relative" style={{ filter: dead ? "grayscale(1) brightness(0.6)" : "none" }}>
                    {m && <Portrait src={m.portrait} size={48} />}
                    {dead && <span className="absolute inset-0 grid place-items-center"><Icon name="ico-skull" size={22} style={{ color: "#df7257" }} /></span>}
                  </div>
                  <div className="h-1.5 w-12 overflow-hidden rounded-full" style={{ background: "rgba(42,28,14,0.4)" }}>
                    <div className="h-full rounded-full" style={{ width: `${dead ? 100 : finished ? h.pct : 100}%`, background: dead ? "#5e1d13" : "linear-gradient(90deg,#7a2e22,#3f7d3a)" }} />
                  </div>
                </div>
              )
            })}
          </div>

          {/* live class-coloured DPS meter (Warcraft-Logs / Details! style) */}
          <div className="leather gilt-frame rounded-[5px] p-3">
            <div className="mb-2 flex items-center justify-between">
              <h3 className="heading text-[12px] font-bold uppercase tracking-[0.18em]" style={{ color: "#e6c163" }}>Damage Done</h3>
              <span className="display text-[12px] font-bold tabular-nums" style={{ color: "#d8c8a0" }}>{fmtNum(totalDps)} raid DPS</span>
            </div>
            <div className="flex flex-col gap-1.5">
              {meter.map((r) => {
                const c = specColor(r.specId)
                const pct = Math.round((r.dps / totalDps) * 100)
                return (
                  <div key={r.id} className="relative h-[24px] overflow-hidden rounded-[3px]" style={{ background: "rgba(0,0,0,0.36)" }}>
                    <div className="absolute inset-y-0 left-0 transition-[width] duration-200"
                         style={{ width: `${(r.dps / topDps) * 100}%`, background: `linear-gradient(90deg, ${c}cc, ${c})` }} />
                    <div className="relative flex h-full items-center gap-1.5 px-2 text-[11px]">
                      <Icon name={SPECS[r.specId]?.icon ?? "stat-ilvl"} size={13} style={{ color: "#1c1209" }} className="shrink-0" />
                      <span className="heading font-bold" style={{ color: "#1c1209", textShadow: "0 1px 0 rgba(255,255,255,0.25)" }}>{r.name}</span>
                      <span className="ml-auto display font-bold tabular-nums" style={{ color: "#ffffff", textShadow: "0 1px 2px rgba(0,0,0,0.8)" }}>{fmtNum(r.dps)}</span>
                      <span className="w-9 text-right tabular-nums" style={{ color: "#d8c8a0", textShadow: "0 1px 2px rgba(0,0,0,0.8)" }}>{pct}%</span>
                    </div>
                  </div>
                )
              })}
            </div>
          </div>

          {/* death report — fills in as deaths occur */}
          <div className="gilt-frame flex-1 rounded-[5px] p-3" style={{ background: "linear-gradient(180deg, #f3e0b4, #e6cb8f)" }}>
            <GiltHeading sub="cause · time · morale">Death Report</GiltHeading>
            <div className="flex flex-col gap-2 text-[11px]">
              {result.deaths.length === 0 ? (
                <p className="italic" style={{ color: "#3f7d3a" }}>No deaths. A clean run — savor it.</p>
              ) : shownDeaths.length === 0 ? (
                <p className="italic" style={{ color: "#6b5230" }}>No deaths yet. Hold your breath.</p>
              ) : (
                shownDeaths.slice(0, 6).map((d, i) => (
                  <div key={i} className="rounded-[4px] p-2" style={{ background: "rgba(154,51,34,0.10)", border: "1px solid #9a332244" }}>
                    <div className="heading font-bold" style={{ color: "#7a2e22" }}>{d.name} — {d.t}</div>
                    <div style={{ color: "#5b3a1e" }}>Cause: {d.cause}. Morale −20.</div>
                  </div>
                ))
              )}
            </div>
          </div>
        </aside>
      </div>

      {hover && <SkillTooltip {...hover} />}

      <style>{`.dial-btn2{font-family:var(--font-heading);min-width:34px;height:24px;border-radius:4px;
        border:1px solid #6f5320;font-size:11px;font-weight:600;padding:0 6px;}
        .dial-btn2:hover{filter:brightness(1.12)}
        .transport-btn{font-family:var(--font-heading);display:grid;place-items:center;width:30px;height:26px;
        border-radius:5px;border:1px solid #6f5320;font-size:12px;color:#e6c163;
        background:linear-gradient(#3a2a18,#221608);}
        .transport-btn:hover{filter:brightness(1.15)}`}</style>
    </div>
  )
}
