/* Report — Warcraft Logs view of the real RunResult, with playback:
   press play to stream the event log and watch the Details! meter + party
   health bars evolve over the run. */
import { useEffect, useMemo, useRef, useState, type ReactNode } from "react"
import { content } from "@/content"
import { useGame, roleOf } from "@/state/game-store"
import { activeAffixIds } from "@/sim/affixes"
import { buildReport, liveDamage, liveHealing, hpAt, mc, mmss, ROLE_ORDER, type DmgRow, type LogEntry } from "../analytics"
import type { RunResult } from "@/sim"
import { Icon, Meter, ClassName, LogSpell, GameIcon } from "../components"
import { ReplayCanvas } from "../ReplayCanvas"
import type { Go, GoChar } from "../LogsApp"

const SPEEDS = [0.5, 1, 2, 4]
const RATE = 40 // sim-seconds of playback per real second at 1×
// H.2: the per-spec signature majors — their cast lines get a gold accent in the log
const MAJOR_IDS = new Set([...content.playerAbilities.values()].filter((a) => (a.tags ?? []).includes("major")).map((a) => a.id))

export function ReportPage({ go, goChar, viewId, setViewId }: { go: Go; goChar: GoChar; viewId: string | null; setViewId: (id: string | null) => void }) {
  const g = useGame()
  const tickets = g.history
  // viewId is lifted to the app shell (route) so the Report nav-tab dropdown can pick which run to show; null = latest.
  const [tab, setTab] = useState<"log" | "deaths" | "casts">("log")
  const [meterMetric, setMeterMetric] = useState<"dps" | "hps">("dps")
  const [clock, setClock] = useState(0)
  const [playing, setPlaying] = useState(false)
  const [speed, setSpeed] = useState(1)
  const [popupDismissed, setPopupDismissed] = useState(false)   // end-of-run loot popup dismissed for this run

  // viewId===null follows the latest; a fresh run lands here with null → shows the new run, no effect needed
  const ticket = (viewId ? tickets.find((t) => t.id === viewId) : null) ?? tickets[0] ?? null
  const isLatest = ticket != null && ticket.id === tickets[0]?.id
  // the just-finished run is already in lastResult — reuse it (no re-sim); historical runs re-simulate from the ticket
  const result = useMemo(() => {
    if (!ticket) return null
    if (g.lastResult && g.lastResult.seed === ticket.seed) return g.lastResult
    try { return g.replayTicket(ticket) } catch { return null }
  }, [ticket?.id, g.lastResult]) // eslint-disable-line react-hooks/exhaustive-deps
  const runKey = ticket ? { dungeonId: ticket.dungeonId, dungeon: ticket.dungeonName, level: ticket.keyLevel, rating: ticket.rating } : g.keystone
  // show only the affixes that were actually in effect at this run's key level (gating)
  const affixIds = ticket ? activeAffixIds(ticket.affixIds, ticket.keyLevel) : []
  const affixNames = ticket ? affixIds.map((id) => content.affixes.get(id)?.name ?? id) : g.weekAffixes.map((a) => a.name)
  const R = useMemo(() => result ? buildReport(result, runKey, affixNames) : null, [result, ticket?.id]) // eslint-disable-line react-hooks/exhaustive-deps
  const specById = useMemo(() => new Map((result?.partyMeta ?? []).map((m) => [m.id, m.specId])), [result])
  const specByName = useMemo(() => new Map((result?.partyMeta ?? []).map((m) => [m.name, m.specId])), [result])
  const duration = result?.durationSec ?? 0
  // J.2: a wipe replay stops at the wipe itself (last death) — don't play out the dead air after the party falls
  const playEnd = result && result.outcome === "wipe" && result.deaths.length
    ? Math.min(duration, result.deaths[result.deaths.length - 1].tSec + 3)
    : duration

  // auto-play ONLY the freshly-run key, and only the first time it's opened (store-backed flag, consumed once —
  // StrictMode-safe). Historical runs & re-visits show the finished report (paused) — press play to re-watch.
  useEffect(() => {
    if (!result) return
    setPopupDismissed(false)   // a new run (or switching runs) re-arms the end-of-run popup
    // an unwatched current run ALWAYS starts at 0 and plays (forced watch) — closes the navigate-away-and-back bypass;
    // everything else (already-watched current run, or a historical re-view) opens at the end, fully revealed.
    const current = isLatest && !!g.lastResult && g.lastResult.seed === result.seed
    if (current && g.watchedSeed !== result.seed) { setClock(0); setPlaying(true); setSpeed(1); if (result.seed === g.autoplaySeed) g.consumeAutoplay() }
    else { setClock(playEnd); setPlaying(false) }
  }, [result?.seed]) // eslint-disable-line react-hooks/exhaustive-deps

  // advance the playback clock
  useEffect(() => {
    if (!playing || !result) return
    const iv = setInterval(() => {
      setClock((c) => {
        const next = c + RATE * speed * 0.12
        if (next >= playEnd) { setPlaying(false); return playEnd }
        return next
      })
    }, 120)
    return () => clearInterval(iv)
  }, [playing, speed, playEnd, result])

  // watch-gate: once the freshly-run key's replay reaches the end, lock in "watched" → reveal results + flush the
  // deferred outcome/loot feed lines (marked once; re-views/history start at playEnd so they never gate).
  useEffect(() => {
    if (!result) return
    const current = isLatest && !!g.lastResult && g.lastResult.seed === result.seed
    if (clock >= playEnd && current && g.watchedSeed !== result.seed) g.markRunWatched(result.seed)
  }, [clock, playEnd, isLatest, result, g.lastResult, g.watchedSeed]) // eslint-disable-line react-hooks/exhaustive-deps

  if (!result || !R) {
    return (
      <div className="page-scroll" style={{ display: "flex", alignItems: "center", justifyContent: "center" }}>
        <div style={{ textAlign: "center", maxWidth: 460, padding: 40 }}>
          <Icon name="report" size={40} color="var(--faint)" />
          <div style={{ fontSize: 22, fontWeight: 700, marginTop: 16 }}>No run logged yet</div>
          <div className="flux" style={{ fontSize: 14, marginTop: 8 }}>Plan a keystone and simulate it — the pull plays out here like a real combat log.</div>
          <button className="btn btn-primary" style={{ marginTop: 20, padding: "11px 22px" }} onClick={() => go("setup")}><Icon name="setup" size={15} color="#04201d" /> Plan a Run</button>
        </div>
      </div>
    )
  }

  const finished = clock >= playEnd
  const liveDmg = liveDamage(result, clock)
  const liveHeal = liveHealing(result, clock)
  const meterRows = meterMetric === "hps" ? liveHeal.rows : liveDmg.rows
  const meterTotal = meterMetric === "hps" ? liveHeal.total : liveDmg.total
  const hp = hpAt(result, clock)
  const visibleLog = R.log.filter((l) => l.tSec <= clock)
  const visibleDeaths = result.deaths.filter((d) => d.tSec <= clock)
  const showAction = isLatest && !!g.lastResult   // loot/continue only applies to the current, unfinished run
  // watch-gate: the freshly-run key hides ALL results (outcome, deaths, loot) + locks the transport (no scrub-ahead,
  // no fast-forward) until the replay has played out once. Re-views / history tickets start at playEnd ⇒ already revealed.
  const isCurrentRun = isLatest && !!g.lastResult && g.lastResult.seed === result.seed
  const revealed = !isCurrentRun || finished || g.watchedSeed === result.seed
  const gated = !revealed
  const hasLoot = (g.pendingLoot?.length ?? 0) > 0
  const distribute = () => { if (hasLoot) go("loot"); else { g.confirmLoot({}); go("keystone") } }
  const seek = (t: number) => setClock(Math.max(0, Math.min(duration, t)))
  const togglePlay = () => { if (finished) { setClock(0); setPlaying(true) } else setPlaying((p) => !p) }

  return (
    <div className="page">
      <div className="page-scroll" style={{ padding: 20 }}>
        {/* replay (top) — party health (top-left) · timer panel (top-right) · live meter (bottom-right) · loot popup (centered) */}
        <div style={{ marginBottom: 14 }}>
          <ReplayCanvas
            result={result} clock={clock} playing={playing} members={g.members} dungeonId={R.dungeonId}
            hudTopLeft={<PartyHealth result={result} hp={hp} goChar={goChar} />}
            hudTopRight={
              <div style={{ background: "rgba(10,11,15,.66)", backdropFilter: "blur(3px)", border: "1px solid var(--line)", borderRadius: "var(--radius)", padding: "7px 11px" }}>
                <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                  <span style={{ fontSize: 14.5, fontWeight: 700, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{R.title}</span>
                  <span className="mono" style={{ fontSize: 14, fontWeight: 700, color: "var(--amber)", flex: "none" }}>+{R.keyLevel}</span>
                </div>
                {affixIds.length ? (
                  <div style={{ display: "flex", gap: 5, marginTop: 6, flexWrap: "wrap" }}>
                    {affixIds.map((id) => <GameIcon key={id} kind="affix" id={id} size={18} label={content.affixes.get(id)?.name} />)}
                  </div>
                ) : null}
                <div style={{ display: "flex", gap: 14, marginTop: 8, justifyContent: "flex-end" }}>
                  <Stat label="Time" value={<span className="mono">{mmss(clock)}</span>} sub={"/ " + R.par} />
                  <Stat label="Deaths" value={<span className="mono" style={{ color: visibleDeaths.length ? "var(--danger)" : "var(--good)" }}>{visibleDeaths.length}</span>} />
                  <Stat label="Rez" value={<span className="mono" style={{ color: result.finalRezCharges > 0 ? "var(--good)" : "var(--danger)" }}>{result.finalRezCharges}</span>} />
                  <Stat label="Result" value={gated ? <span style={{ color: "var(--faint)" }}>···</span> : <span style={{ color: R.outcomeColor }}>{R.outcome} {R.upgradeLabel}</span>} />
                </div>
              </div>
            }
            hudBottomRight={
              <div style={{ background: "rgba(10,11,15,.66)", backdropFilter: "blur(3px)", border: "1px solid var(--line)", borderRadius: "var(--radius)", padding: "8px 10px" }}>
                <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 7 }}>
                  <span className="eyebrow">Live Meter</span>
                  <div className="seg-group" style={{ padding: 2 }}>
                    <button className={"seg-btn" + (meterMetric === "dps" ? " on accent" : "")} style={{ padding: "3px 9px", fontSize: 11 }} onClick={() => setMeterMetric("dps")}>Damage</button>
                    <button className={"seg-btn" + (meterMetric === "hps" ? " on accent" : "")} style={{ padding: "3px 9px", fontSize: 11 }} onClick={() => setMeterMetric("hps")}>Healing</button>
                  </div>
                </div>
                <Meter rows={meterRows} metric={meterMetric} segName="Overall" total={meterTotal} duration={liveDmg.dur} />
              </div>
            }
            centerPopup={finished && showAction && !gated && !popupDismissed ? (
              <div className="panel" style={{ width: 360, padding: 20, textAlign: "center", boxShadow: "0 12px 48px rgba(0,0,0,.55)" }}>
                <div className="eyebrow" style={{ marginBottom: 6 }}>Run Complete</div>
                <div style={{ fontSize: 26, fontWeight: 800, color: R.outcomeColor }}>{R.outcome} {R.upgradeLabel}</div>
                <div className="mono" style={{ fontSize: 13, color: "var(--muted)", marginTop: 6 }}>
                  {mmss(clock)} <span style={{ color: "var(--faint)" }}>/ {R.par}</span>
                  {visibleDeaths.length ? <span style={{ color: "var(--danger)", marginLeft: 8 }}>☠ {visibleDeaths.length}</span> : null}
                </div>
                <button className="btn btn-primary" style={{ justifyContent: "center", padding: 12, fontSize: 14, width: "100%", marginTop: 16 }} onClick={distribute}>
                  <Icon name="star" size={15} color="#04201d" /> {hasLoot ? "Distribute Loot →" : "Continue → Keystone"}
                </button>
                <button className="btn btn-ghost" style={{ justifyContent: "center", padding: 9, fontSize: 12.5, width: "100%", marginTop: 8 }} onClick={() => setPopupDismissed(true)}>Keep viewing report</button>
              </div>
            ) : null}
          />
        </div>

        {/* run player — readout is vs the dungeon timer (clock / par), not the run's final length; pull ticks reveal as the playhead passes them */}
        <div className="panel" style={{ padding: "10px 16px", marginBottom: 14, display: "flex", alignItems: "center", gap: 16 }}>
          <button className="btn btn-primary btn-sm" style={{ width: 38, height: 34, justifyContent: "center", padding: 0, fontSize: 15 }} onClick={togglePlay} title={playing ? "Pause" : finished ? "Replay" : "Play"}>
            {playing ? "❚❚" : finished ? "↻" : "▶"}
          </button>
          <div className="seg-group" style={{ padding: 2, opacity: gated ? .4 : 1 }} title={gated ? "Locked until you've watched the run" : undefined}>
            {SPEEDS.map((s) => (
              <button key={s} className={"seg-btn" + (speed === s ? " on accent" : "")} style={{ padding: "4px 10px", fontSize: 11.5 }} disabled={gated} onClick={() => setSpeed(s)}>{s}×</button>
            ))}
          </div>
          {/* scrubber — pull ticks (revealed once reached, click to seek) + death dots; both hidden/locked while watch-gated */}
          <div style={{ position: "relative", flex: 1, height: 22, display: "flex", alignItems: "center" }}>
            <input type="range" min={0} max={Math.max(1, Math.round(duration))} value={Math.round(clock)} disabled={gated} onChange={(e) => { setPlaying(false); seek(Number(e.target.value)) }}
              style={{ width: "100%", accentColor: "var(--accent)", cursor: gated ? "not-allowed" : "pointer", opacity: gated ? .5 : 1 }} />
            {R.fights.filter((f) => f.id !== "all" && f.start > 0 && clock >= f.start).map((f) => {
              const tint = f.type === "boss" ? "var(--amber)" : "var(--accent)"
              return (
                <span key={f.id} title={`${f.name} · ${mmss(f.start)}`} onClick={gated ? undefined : () => { setPlaying(false); seek(f.start) }}
                  style={{ position: "absolute", left: `calc(${(f.start / Math.max(1, duration)) * 100}% - 4px)`, top: 1, width: 8, height: 20, display: "flex", justifyContent: "center", alignItems: "flex-start", cursor: gated ? "default" : "pointer", pointerEvents: gated ? "none" : "auto", zIndex: 2 }}>
                  <span style={{ width: 2, height: 18, background: tint, borderRadius: 1, boxShadow: "0 0 3px rgba(0,0,0,.6)" }} />
                </span>
              )
            })}
            {!gated && result.deaths.map((d, i) => (
              <span key={"d" + i} title={`${d.name} · ${d.t}`} style={{ position: "absolute", left: `calc(${(d.tSec / Math.max(1, duration)) * 100}% - 3px)`, top: -1, width: 6, height: 6, borderRadius: "50%", background: "var(--danger)", pointerEvents: "none", zIndex: 3 }} />
            ))}
          </div>
          <span className="mono" style={{ fontSize: 13, color: "var(--muted)", minWidth: 96, textAlign: "right" }}>{mmss(clock)} <span style={{ color: "var(--faint)" }}>/ {R.par}</span></span>
        </div>

        {/* full-width event log */}
        <div className="panel">
          <div className="panel-head" style={{ padding: "10px 14px" }}>
            <div className="nav-tabs" style={{ height: 34, gap: 2 }}>
              {([["log", "Event Log"], ["deaths", "Deaths"], ["casts", "Casts"]] as [typeof tab, string][]).map(([id, lbl]) => (
                <button key={id} className={"seg-btn" + (tab === id ? " on accent" : "")} onClick={() => setTab(id)}>{lbl}</button>
              ))}
            </div>
            <span className="mono" style={{ fontSize: 12, color: "var(--faint)" }}>{visibleLog.length} events · {mmss(clock)}</span>
          </div>
          <div style={{ padding: 14 }}>
            {tab === "deaths" ? <DeathsTab deaths={visibleDeaths} specByName={specByName} /> : null}
            {tab === "casts" ? <CastsTab rows={liveDmg.rows} dur={liveDmg.dur} /> : null}
            {tab === "log" ? <EventLog log={visibleLog} specById={specById} playing={playing} speed={speed} /> : null}
          </div>
        </div>

        {/* action footer — always reachable (the centered popup is an extra prompt at run end, and can be dismissed) */}
        <div style={{ display: "flex", justifyContent: "center", marginTop: 16 }}>
          {gated ? (
            <button className="btn" disabled style={{ justifyContent: "center", padding: "11px 20px", fontSize: 13.5, opacity: .65, cursor: "not-allowed" }} title="Watch the run to the end to reveal results">
              <Icon name="report" size={15} color="var(--faint)" /> Watch the run to reveal results…
            </button>
          ) : showAction ? (
            <button className="btn btn-primary" style={{ justifyContent: "center", padding: "11px 24px", fontSize: 14 }} onClick={distribute}>
              <Icon name="star" size={15} color="#04201d" /> {hasLoot ? "Distribute Loot →" : "Continue → Keystone"}
            </button>
          ) : !isLatest ? (
            <button className="btn btn-ghost" style={{ justifyContent: "center", padding: "11px 24px", fontSize: 14 }} onClick={() => setViewId(null)}>↩ Back to latest run</button>
          ) : (
            <button className="btn btn-primary" style={{ justifyContent: "center", padding: "11px 24px", fontSize: 14 }} onClick={() => go("setup")}>
              <Icon name="setup" size={15} color="#04201d" /> Plan a Run →
            </button>
          )}
        </div>
      </div>
    </div>
  )
}

/* ---- party live health overlay (top-left of the replay canvas): name · health bar · square class icon ----
   buff/debuff row is deferred (the sim exposes no per-second status timeline yet — would need engine instrumentation). */
function PartyHealth({ result, hp, goChar }: { result: RunResult; hp: Record<string, number>; goChar: GoChar }) {
  const rows = result.partyMeta
    .map((pm) => ({ ...pm, role: roleOf(pm.specId), classId: content.specs.get(pm.specId)?.classId ?? "", frac: hp[pm.id] ?? 1 }))
    .sort((a, b) => ROLE_ORDER[a.role] - ROLE_ORDER[b.role])
  return (
    <div style={{ background: "rgba(10,11,15,.66)", backdropFilter: "blur(3px)", border: "1px solid var(--line)", borderRadius: "var(--radius)", padding: "8px 10px", width: 212 }}>
      <div className="eyebrow" style={{ marginBottom: 8 }}>Party · Health</div>
      <div style={{ display: "flex", flexDirection: "column", gap: 9 }}>
        {rows.map((r) => {
          const info = mc(r.specId)
          const down = r.frac <= 0.001
          const pct = Math.round(r.frac * 100)
          const barColor = down ? "#3a3d48" : r.frac > 0.5 ? "var(--good)" : r.frac > 0.25 ? "var(--amber)" : "var(--danger)"
          return (
            <div key={r.id} style={{ cursor: "pointer", filter: down ? "grayscale(.7) brightness(.8)" : "none" }} onClick={() => goChar(r.id)}>
              {/* name */}
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline", gap: 6 }}>
                <span style={{ color: info.color, fontWeight: 700, fontSize: 12.5, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{r.name}</span>
                <span className="mono" style={{ fontSize: 11, color: down ? "var(--danger)" : "var(--faint)", flex: "none" }}>{down ? "DOWN" : pct + "%"}</span>
              </div>
              {/* health bar */}
              <div style={{ height: 6, borderRadius: 4, background: "rgba(255,255,255,.06)", marginTop: 3, overflow: "hidden" }}>
                <div style={{ height: "100%", width: pct + "%", background: barColor, borderRadius: 4, transition: "width .12s linear, background .2s" }} />
              </div>
              {/* square class icon (buff/debuff row goes here next) */}
              <div style={{ display: "flex", alignItems: "center", gap: 5, marginTop: 5 }}>
                <GameIcon kind="class" id={r.classId} size={18} label={info.klass} noTip style={{ borderRadius: 3, border: `1px solid ${info.color}` }} />
              </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}

function Stat({ label, value, sub }: { label: string; value: ReactNode; sub?: string }) {
  return (
    <div style={{ textAlign: "right" }}>
      <div className="eyebrow" style={{ fontSize: 9.5 }}>{label}</div>
      <div style={{ fontSize: 14.5, fontWeight: 700, marginTop: 2 }}>{value}</div>
      {sub ? <div className="mono" style={{ fontSize: 10, color: "var(--faint)", marginTop: 1 }}>{sub}</div> : null}
    </div>
  )
}

function DeathsTab({ deaths, specByName }: { deaths: { tSec: number; t: string; name: string; cause: string }[]; specByName: Map<string, string> }) {
  if (!deaths.length) return <div style={{ color: "var(--good)", fontSize: 13.5, padding: "8px 2px" }}>No casualties yet — the run is clean. Deaths appear here as they happen.</div>
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
      {deaths.map((d, i) => (
        <div key={i} style={{ background: "var(--row)", borderRadius: 7, padding: "12px 14px", borderLeft: "3px solid var(--danger)" }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <span style={{ display: "flex", alignItems: "center", gap: 9 }}>
              <Icon name="skull" size={16} color="var(--danger)" />
              <ClassName name={d.name} specId={specByName.get(d.name) ?? "berserker"} showSpec={false} />
            </span>
            <span className="mono" style={{ fontSize: 12, color: "var(--faint)" }}>{d.t}</span>
          </div>
          <div className="flux" style={{ fontSize: 13, marginTop: 7 }}>Cause: {d.cause}.</div>
        </div>
      ))}
    </div>
  )
}

function CastsTab({ rows, dur }: { rows: DmgRow[]; dur: number }) {
  const sorted = [...rows].sort((a, b) => b.casts - a.casts)
  const max = sorted[0]?.casts || 1
  return (
    <div className="dd">
      <div className="dd-head"><div>#</div><div>Name</div><div className="r">Casts</div><div className="r">APM</div><div className="r">Active</div></div>
      {sorted.map((d, i) => {
        const info = mc(d.specId)
        return (
          <div className="dd-row" key={d.id}>
            <div className="dd-rank">{i + 1}</div>
            <div className="dd-name-cell">
              <div className="dd-fill" style={{ width: (d.casts / max) * 100 + "%", background: `${info.color}cc`, boxShadow: `inset 2px 0 0 ${info.color}` }} />
              <div className="dd-name"><span className="nm" style={{ color: info.color }}>{d.name}</span><span className="sp">{info.subspec}</span></div>
            </div>
            <div className="dd-amt mono">{d.casts}</div>
            <div className="dd-dps mono">{(d.casts / (dur / 60)).toFixed(1)}</div>
            <div className="dd-pct mono">{d.active}%</div>
          </div>
        )
      })}
    </div>
  )
}

function EventLog({ log, specById, playing, speed }: { log: LogEntry[]; specById: Map<string, string>; playing: boolean; speed: number }) {
  const ref = useRef<HTMLDivElement>(null)
  useEffect(() => { if (playing && ref.current) ref.current.scrollTop = ref.current.scrollHeight }, [log.length, playing])
  // J.3: while playing, each newly-revealed line eases in over a duration that scales with the speed dial
  // (slow, readable fade at 0.5×; snappy at 4×) so the speed visibly changes the log cadence. Off when paused/seeking.
  const reveal = playing ? `logIn ${Math.max(0.07, 0.42 / speed).toFixed(2)}s ease-out` : undefined
  return (
    <div ref={ref} className="scroll-thin" style={{ display: "flex", flexDirection: "column", maxHeight: "calc(var(--stage-h) - 320px)", overflowY: "auto" }}>
      {log.map((e, i) => {
        const specId = e.who ? specById.get(e.who) : null
        const color = specId ? mc(specId).color : null
        const lead = e.whoName && e.text.startsWith(e.whoName)
        const rest = lead ? e.text.slice(e.whoName!.length) : e.text
        // a player ability cast → split the spell name out as a bold, underlined, hover-tooltipped LogSpell
        const si = e.skillId && e.ability && rest.includes(e.ability) ? rest.indexOf(e.ability) : -1
        const isMajor = !!e.skillId && MAJOR_IDS.has(e.skillId)   // H.2: signature majors get a gold accent
        return (
          <div key={i} style={{ display: "grid", gridTemplateColumns: "52px 56px 1fr", gap: 10, alignItems: "baseline", padding: "6px 8px", borderBottom: "1px solid var(--line-soft)", fontSize: 13, animation: reveal, boxShadow: isMajor ? "inset 2px 0 0 var(--amber)" : undefined, background: isMajor ? "rgba(240,165,46,.05)" : undefined }}>
            <span className="mono" style={{ color: "var(--faint)", fontSize: 12 }}>{mmss(e.tSec)}</span>
            <span className="mono" style={{ color: isMajor ? "var(--amber)" : e.color, fontWeight: 700, fontSize: 11, letterSpacing: ".04em" }}>{isMajor ? "✦ MAJOR" : e.tag}</span>
            <span className="flux" style={{ fontSize: 13, lineHeight: 1.5 }}>
              {/* J.4: paint the source name even for enemy strikes (no spec color) — neutral hostile tone */}
              {lead ? <span style={{ color: color ?? "#d77b7b", fontWeight: 700 }}>{e.whoName}</span> : null}
              {si >= 0 ? (
                <>
                  {rest.slice(0, si)}
                  <LogSpell name={e.ability!} skillId={e.skillId} color={isMajor ? "var(--amber)" : (color ?? undefined)} />
                  {rest.slice(si + e.ability!.length)}
                </>
              ) : rest}
            </span>
          </div>
        )
      })}
      {!log.length ? <div className="flux" style={{ fontSize: 13, padding: "8px 2px" }}>Press play to stream the pull…</div> : null}
    </div>
  )
}
