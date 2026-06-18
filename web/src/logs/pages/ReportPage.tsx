/* Report — Warcraft Logs view of the real RunResult, with playback:
   press play to stream the event log and watch the Details! meter + party
   health bars evolve over the run. */
import { useEffect, useMemo, useRef, useState, type ReactNode } from "react"
import { useGame, roleOf } from "@/state/game-store"
import { buildReport, liveDamage, liveHealing, hpAt, mc, fmt, mmss, ROLE_ORDER, type DmgRow } from "../analytics"
import type { Member } from "@/data/game"
import type { RunResult } from "@/sim"
import { Icon, Panel, Meter, ClassName } from "../components"
import type { Go, GoChar } from "../LogsApp"

const SPEEDS = [0.5, 1, 2, 4]
const RATE = 40 // sim-seconds of playback per real second at 1×

export function ReportPage({ go, goChar }: { go: Go; goChar: GoChar }) {
  const g = useGame()
  const tickets = g.history
  const [viewId, setViewId] = useState<string | null>(null)   // null = follow the latest run
  const [tab, setTab] = useState<"log" | "deaths" | "casts">("log")
  const [meterMetric, setMeterMetric] = useState<"dps" | "hps">("dps")
  const [clock, setClock] = useState(0)
  const [playing, setPlaying] = useState(true)
  const [speed, setSpeed] = useState(1)

  // viewId===null follows the latest; a fresh run lands here with null → shows the new run, no effect needed
  const ticket = (viewId ? tickets.find((t) => t.id === viewId) : null) ?? tickets[0] ?? null
  const isLatest = ticket != null && ticket.id === tickets[0]?.id
  // re-simulate the selected run from its ticket (deterministic) — no full RunResults are stored
  const result = useMemo(() => { try { return ticket ? g.replayTicket(ticket) : null } catch { return null } }, [ticket?.id]) // eslint-disable-line react-hooks/exhaustive-deps
  const runKey = ticket ? { dungeonId: ticket.dungeonId, dungeon: ticket.dungeonName, level: ticket.keyLevel, rating: ticket.rating } : g.keystone
  const affixNames = ticket ? ticket.affixNames : g.weekAffixes.map((a) => a.name)
  const R = useMemo(() => result ? buildReport(result, runKey, affixNames, g.guild?.region ?? "—") : null, [result, ticket?.id, g.guild]) // eslint-disable-line react-hooks/exhaustive-deps
  const specById = useMemo(() => new Map((result?.partyMeta ?? []).map((m) => [m.id, m.specId])), [result])
  const specByName = useMemo(() => new Map((result?.partyMeta ?? []).map((m) => [m.name, m.specId])), [result])
  const duration = result?.durationSec ?? 0

  // restart playback whenever a new run is simulated
  useEffect(() => { if (result) { setClock(0); setPlaying(true) } }, [result?.seed]) // eslint-disable-line react-hooks/exhaustive-deps

  // advance the playback clock
  useEffect(() => {
    if (!playing || !result) return
    const iv = setInterval(() => {
      setClock((c) => {
        const next = c + RATE * speed * 0.12
        if (next >= duration) { setPlaying(false); return duration }
        return next
      })
    }, 120)
    return () => clearInterval(iv)
  }, [playing, speed, duration, result])

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

  const finished = clock >= duration
  const liveDmg = liveDamage(result, clock)
  const liveHeal = liveHealing(result, clock)
  const meterRows = meterMetric === "hps" ? liveHeal.rows : liveDmg.rows
  const meterTotal = meterMetric === "hps" ? liveHeal.total : liveDmg.total
  const hp = hpAt(result, clock)
  const visibleLog = R.log.filter((l) => l.tSec <= clock)
  const visibleDeaths = result.deaths.filter((d) => d.tSec <= clock)
  const activeFight = R.fights.find((f) => f.id !== "all" && clock >= f.start && clock < f.end) ?? R.fights[R.fights.length - 1]
  const showAction = isLatest && !!g.lastResult   // loot/continue only applies to the current, unfinished run
  const hasLoot = (g.pendingLoot?.length ?? 0) > 0
  const distribute = () => { if (hasLoot) go("loot"); else { g.confirmLoot({}); go("keystone") } }
  const seek = (t: number) => setClock(Math.max(0, Math.min(duration, t)))
  const togglePlay = () => { if (finished) { setClock(0); setPlaying(true) } else setPlaying((p) => !p) }

  return (
    <div className="page">
      {/* ---- fight rail ---- */}
      <div className="rail">
        <div style={{ padding: "16px 16px 12px", borderBottom: "1px solid var(--line)" }}>
          <div className="eyebrow" style={{ marginBottom: 6 }}>Report</div>
          <div style={{ fontSize: 17, fontWeight: 700 }}>{R.title}</div>
          <div className="mono" style={{ fontSize: 12, color: "var(--faint)", marginTop: 3 }}>{R.region}</div>
          <div style={{ display: "flex", gap: 6, marginTop: 11, flexWrap: "wrap" }}>
            <span className="chip" style={{ color: "var(--amber)", borderColor: "#4a3a17" }}>+{R.keyLevel} Key</span>
            {R.affixes.map((a) => <span className="chip" key={a}>{a}</span>)}
          </div>
        </div>
        <div style={{ padding: "8px 0", overflowY: "auto", flex: 1 }}>
          <div className="eyebrow" style={{ padding: "6px 16px 8px" }}>Runs · click to view</div>
          {tickets.map((t, i) => {
            const oc = t.outcome === "timed" ? "var(--good)" : t.outcome === "wipe" ? "var(--danger)" : "var(--amber)"
            return (
              <div key={t.id} className={"fight" + (t.id === ticket?.id ? " active" : "")} style={{ cursor: "pointer" }} onClick={() => setViewId(t.id)}>
                <span className="fight-ic" style={{ background: oc, borderRadius: 3 }} />
                <span className="fight-nm">{t.ownerName} · +{t.keyLevel}{i === 0 ? <span style={{ color: "var(--faint)", fontWeight: 400 }}> · latest</span> : null}</span>
                <span className="fight-meta mono">
                  {t.deaths > 0 ? <span style={{ color: "var(--danger)", marginRight: 6 }}>☠{t.deaths}</span> : null}
                  {mmss(t.durationSec)}
                </span>
              </div>
            )
          })}
          <div style={{ height: 12, borderBottom: "1px solid var(--line)", marginBottom: 8 }} />
          <div className="eyebrow" style={{ padding: "6px 16px 8px" }}>Pulls · click to seek</div>
          {R.fights.map((f) => {
            const tint = f.type === "boss" ? "var(--amber)" : f.type === "all" ? "var(--accent)" : "#5b6472"
            const isActive = f.id === "all" ? false : f.id === activeFight.id
            return (
              <div key={f.id} className={"fight" + (isActive ? " active" : "")} onClick={() => f.id === "all" ? seek(0) : seek(f.start)}>
                <span className="fight-ic" style={{ background: tint, borderRadius: f.type === "boss" ? 6 : 2 }} />
                <span className="fight-nm">{f.name}</span>
                <span className="fight-meta mono">
                  {f.deaths > 0 ? <span style={{ color: "var(--danger)", marginRight: 6 }}>☠{f.deaths}</span> : null}
                  {mmss(f.end - f.start)}
                </span>
              </div>
            )
          })}
        </div>
      </div>

      {/* ---- main ---- */}
      <div className="page-scroll" style={{ padding: 20 }}>
        {/* summary */}
        <div className="panel" style={{ padding: "16px 20px", marginBottom: 14, display: "flex", alignItems: "center", justifyContent: "space-between", gap: 20 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
            <div style={{ width: 46, height: 46, borderRadius: 10, background: "linear-gradient(150deg,#2a2d37,#15161b)", border: "1px solid var(--line)", display: "flex", alignItems: "center", justifyContent: "center" }}>
              <Icon name="skull" size={24} color="#8b93a3" />
            </div>
            <div>
              <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                <span style={{ fontSize: 21, fontWeight: 700 }}>{R.title}</span>
                <span className="mono" style={{ fontSize: 18, fontWeight: 700, color: "var(--amber)" }}>+{R.keyLevel}</span>
              </div>
              <div style={{ display: "flex", gap: 6, marginTop: 5 }}>
                {R.affixes.map((a) => <span className="chip" key={a}>{a}</span>)}
                <span className="chip" style={{ color: "var(--accent)" }}>{finished ? activeFight.name : activeFight.name + " …"}</span>
              </div>
            </div>
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: 26 }}>
            <Summary label="Result" value={<span style={{ color: R.outcomeColor }}>{R.outcome} {R.upgradeLabel}</span>} />
            <Summary label="Time" value={<span className="mono">{R.time}</span>} sub={"par " + R.par} />
            <Summary label="Deaths" value={<span className="mono" style={{ color: visibleDeaths.length ? "var(--danger)" : "var(--good)" }}>{visibleDeaths.length}</span>} />
            <Summary label="Rating" value={<span className="mono" style={{ color: "var(--amber)" }}>{R.rating}</span>} sub={R.deltaRating ? "▲ " + R.deltaRating : undefined} />
          </div>
        </div>

        {/* playback bar */}
        <div className="panel" style={{ padding: "10px 16px", marginBottom: 14, display: "flex", alignItems: "center", gap: 16 }}>
          <button className="btn btn-primary btn-sm" style={{ width: 38, height: 34, justifyContent: "center", padding: 0, fontSize: 15 }} onClick={togglePlay} title={playing ? "Pause" : finished ? "Replay" : "Play"}>
            {playing ? "❚❚" : finished ? "↻" : "▶"}
          </button>
          <div className="seg-group" style={{ padding: 2 }}>
            {SPEEDS.map((s) => (
              <button key={s} className={"seg-btn" + (speed === s ? " on accent" : "")} style={{ padding: "4px 10px", fontSize: 11.5 }} onClick={() => setSpeed(s)}>{s}×</button>
            ))}
          </div>
          {/* scrubber with death markers */}
          <div style={{ position: "relative", flex: 1, height: 22, display: "flex", alignItems: "center" }}>
            <input type="range" min={0} max={Math.max(1, Math.round(duration))} value={Math.round(clock)} onChange={(e) => { setPlaying(false); seek(Number(e.target.value)) }}
              style={{ width: "100%", accentColor: "var(--accent)", cursor: "pointer" }} />
            {result.deaths.map((d, i) => (
              <span key={i} title={`${d.name} · ${d.t}`} style={{ position: "absolute", left: `calc(${(d.tSec / Math.max(1, duration)) * 100}% - 3px)`, top: 0, width: 6, height: 6, borderRadius: "50%", background: "var(--danger)", boxShadow: "0 0 5px var(--danger)", pointerEvents: "none" }} />
            ))}
          </div>
          <span className="mono" style={{ fontSize: 13, color: "var(--muted)", minWidth: 96, textAlign: "right" }}>{mmss(clock)} <span style={{ color: "var(--faint)" }}>/ {mmss(duration)}</span></span>
        </div>

        {/* content row */}
        <div style={{ display: "flex", gap: 16, alignItems: "flex-start" }}>
          <div className="panel" style={{ flex: 1, minWidth: 0 }}>
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
              {tab === "log" ? <EventLog log={visibleLog} specById={specById} playing={playing} /> : null}
            </div>
          </div>

          {/* right column: meter + party health */}
          <div style={{ width: 320, flex: "none", display: "flex", flexDirection: "column", gap: 16 }}>
            <div>
              <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 9 }}>
                <span className="eyebrow">Live Meter</span>
                <div className="seg-group" style={{ padding: 2 }}>
                  <button className={"seg-btn" + (meterMetric === "dps" ? " on accent" : "")} style={{ padding: "4px 12px", fontSize: 11.5 }} onClick={() => setMeterMetric("dps")}>Damage</button>
                  <button className={"seg-btn" + (meterMetric === "hps" ? " on accent" : "")} style={{ padding: "4px 12px", fontSize: 11.5 }} onClick={() => setMeterMetric("hps")}>Healing</button>
                </div>
              </div>
              <Meter rows={meterRows} metric={meterMetric} segName="Overall" total={meterTotal} duration={liveDmg.dur} />
            </div>

            <PartyHealth result={result} hp={hp} members={g.members} goChar={goChar} />

            {showAction ? (
              <button className="btn btn-primary" style={{ justifyContent: "center", padding: 12, fontSize: 14 }} onClick={distribute}>
                <Icon name="star" size={15} color="#04201d" /> {hasLoot ? "Distribute Loot →" : "Continue → Keystone"}
              </button>
            ) : !isLatest ? (
              <button className="btn btn-ghost" style={{ justifyContent: "center", padding: 12, fontSize: 14 }} onClick={() => setViewId(null)}>↩ Back to latest run</button>
            ) : (
              // latest run already resolved (loot distributed) — always offer a forward path
              <button className="btn btn-primary" style={{ justifyContent: "center", padding: 12, fontSize: 14 }} onClick={() => go("setup")}>
                <Icon name="setup" size={15} color="#04201d" /> Plan a Run →
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}

/* ---- party portraits + live health bars (replaces the old Run Details panel) ---- */
function PartyHealth({ result, hp, members, goChar }: { result: RunResult; hp: Record<string, number>; members: Member[]; goChar: GoChar }) {
  const rows = result.partyMeta
    .map((pm) => ({ ...pm, role: roleOf(pm.specId), portrait: members.find((m) => m.id === pm.id)?.portrait, frac: hp[pm.id] ?? 1 }))
    .sort((a, b) => ROLE_ORDER[a.role] - ROLE_ORDER[b.role])
  return (
    <Panel title="Party · Health" bodyStyle={{ padding: 12 }}>
      <div style={{ display: "flex", flexDirection: "column", gap: 9 }}>
        {rows.map((r) => {
          const info = mc(r.specId)
          const down = r.frac <= 0.001
          const pct = Math.round(r.frac * 100)
          const barColor = down ? "#3a3d48" : r.frac > 0.5 ? "var(--good)" : r.frac > 0.25 ? "var(--amber)" : "var(--danger)"
          return (
            <div key={r.id} style={{ display: "flex", alignItems: "center", gap: 10, cursor: "pointer" }} onClick={() => goChar(r.id)}>
              <span style={{ position: "relative", width: 38, height: 38, borderRadius: 9, flex: "none", border: `2px solid ${info.color}`, boxShadow: `0 0 8px ${info.color}44`, overflow: "hidden", background: info.color, filter: down ? "grayscale(1) brightness(.6)" : "none" }}>
                {r.portrait
                  ? <img src={r.portrait} alt="" style={{ width: "100%", height: "100%", objectFit: "cover" }} />
                  : <span style={{ display: "flex", width: "100%", height: "100%", alignItems: "center", justifyContent: "center", color: "#0c0d11", fontWeight: 700 }}>{r.name[0]}</span>}
                {down ? <span style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center" }}><Icon name="skull" size={18} color="#e0444e" /></span> : null}
              </span>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline", gap: 6 }}>
                  <span style={{ color: info.color, fontWeight: 700, fontSize: 13, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{r.name}</span>
                  <span className="mono" style={{ fontSize: 11.5, color: down ? "var(--danger)" : "var(--faint)", flex: "none" }}>{down ? "DOWN" : pct + "%"}</span>
                </div>
                <div style={{ height: 7, borderRadius: 4, background: "rgba(255,255,255,.06)", marginTop: 4, overflow: "hidden" }}>
                  <div style={{ height: "100%", width: pct + "%", background: barColor, borderRadius: 4, transition: "width .12s linear, background .2s" }} />
                </div>
              </div>
            </div>
          )
        })}
      </div>
    </Panel>
  )
}

function Summary({ label, value, sub }: { label: string; value: ReactNode; sub?: string }) {
  return (
    <div style={{ textAlign: "right" }}>
      <div className="eyebrow" style={{ fontSize: 10 }}>{label}</div>
      <div style={{ fontSize: 19, fontWeight: 700, marginTop: 3 }}>{value}</div>
      {sub ? <div className="mono" style={{ fontSize: 10.5, color: "var(--faint)", marginTop: 1 }}>{sub}</div> : null}
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
              <div className="dd-fill" style={{ width: (d.casts / max) * 100 + "%", background: `linear-gradient(90deg, ${info.color}cc, ${info.color}55)`, boxShadow: `inset 2px 0 0 ${info.color}` }} />
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

function EventLog({ log, specById, playing }: { log: { tSec: number; tag: string; color: string; who: string | null; whoName: string | null; text: string; amount: number }[]; specById: Map<string, string>; playing: boolean }) {
  const ref = useRef<HTMLDivElement>(null)
  useEffect(() => { if (playing && ref.current) ref.current.scrollTop = ref.current.scrollHeight }, [log.length, playing])
  return (
    <div ref={ref} className="scroll-thin" style={{ display: "flex", flexDirection: "column", maxHeight: "calc(100vh - 320px)", overflowY: "auto" }}>
      {log.map((e, i) => {
        const specId = e.who ? specById.get(e.who) : null
        const color = specId ? mc(specId).color : null
        const lead = e.whoName && e.text.startsWith(e.whoName)
        const rest = lead ? e.text.slice(e.whoName!.length) : e.text
        return (
          <div key={i} style={{ display: "grid", gridTemplateColumns: "52px 60px 1fr auto", gap: 12, alignItems: "center", padding: "7px 8px", borderBottom: "1px solid var(--line-soft)", fontSize: 13 }}>
            <span className="mono" style={{ color: "var(--faint)", fontSize: 12 }}>{mmss(e.tSec)}</span>
            <span className="mono" style={{ color: e.color, fontWeight: 700, fontSize: 11, letterSpacing: ".04em" }}>{e.tag}</span>
            <span className="flux" style={{ fontSize: 13 }}>
              {lead && color ? <span style={{ color, fontWeight: 700 }}>{e.whoName}</span> : null}
              {rest}
            </span>
            <span className="mono" style={{ color: e.color, fontSize: 12.5, fontWeight: 600 }}>{e.amount ? fmt(e.amount) : ""}</span>
          </div>
        )
      })}
      {!log.length ? <div className="flux" style={{ fontSize: 13, padding: "8px 2px" }}>Press play to stream the pull…</div> : null}
    </div>
  )
}
