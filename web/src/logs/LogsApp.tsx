/* GOAT Lite · Logs — app shell: top nav, routing, onboarding gate. */
import { useState } from "react"
import { useGame } from "@/state/game-store"
import { Icon } from "./components"
import { fmt, mmss } from "./analytics"
import { ReportPage } from "./pages/ReportPage"
import { RosterPage } from "./pages/RosterPage"
import { CharacterPage } from "./pages/CharacterPage"
import { SetupPage } from "./pages/SetupPage"
import { GuildCreatePage } from "./pages/GuildCreatePage"
import { RecruitPage } from "./pages/RecruitPage"
import { LootPage } from "./pages/LootPage"
import { KeystonePage } from "./pages/KeystonePage"
import { GuildFeed } from "./GuildFeed"

export type Page = "report" | "roster" | "character" | "setup" | "recruit" | "guild" | "loot" | "keystone"
// reportRunId: which logged run the Report shows (null = follow latest). Lifted here so the Report nav-tab dropdown can drive it.
export interface Route { page: Page; charId: string | null; reportRunId: string | null }
export type Go = (page: Page) => void
export type GoChar = (id: string) => void

const NAV: { id: Page; label: string; icon: string }[] = [
  { id: "report", label: "Report", icon: "report" },
  { id: "roster", label: "Roster", icon: "roster" },
  { id: "recruit", label: "Recruit", icon: "character" },
  { id: "setup", label: "New Run", icon: "setup" },
]

export function LogsApp() {
  const g = useGame()
  const [route, setRoute] = useState<Route>({ page: "report", charId: null, reportRunId: null })
  const [runsOpen, setRunsOpen] = useState(false)
  const go: Go = (page) => { setRunsOpen(false); setRoute({ page, charId: null, reportRunId: null }) }
  const goChar: GoChar = (id) => { setRunsOpen(false); setRoute({ page: "character", charId: id, reportRunId: null }) }

  // onboarding gate — guild creation and the opening draft are forced, linear
  const page: Page = g.phase === "create" ? "guild" : g.phase === "recruit" ? "recruit" : route.page
  const playing = g.phase === "playing"
  const activeNav: Page = page === "character" ? "roster" : page

  return (
    <div className="app-shell">
      <nav className="topnav">
        <div className="brand" onClick={() => playing && go("roster")} style={{ cursor: playing ? "pointer" : "default" }}>
          <span className="brand-mark">G</span>
          <span className="brand-name">GOAT&nbsp;Lite <span className="sub">· Logs</span></span>
        </div>
        {playing ? (
          <div className="nav-tabs">
            {NAV.map((n) => {
              const btn = (
                <button className={"nav-tab" + (activeNav === n.id ? " active" : "")} onClick={() => go(n.id)}>
                  <Icon name={n.icon} size={17} color={activeNav === n.id ? "var(--accent)" : "currentColor"} />
                  {n.label}
                </button>
              )
              // the Report tab carries a runs dropdown (the old left-rail "Runs" list) when there's history
              if (n.id !== "report" || g.history.length === 0) return <span key={n.id} style={{ display: "inline-flex", height: "100%" }}>{btn}</span>
              return (
                <div key={n.id} style={{ position: "relative", display: "inline-flex", alignItems: "center", height: "100%" }}>
                  {btn}
                  <button className="nav-tab" style={{ padding: "0 7px", color: runsOpen ? "var(--accent)" : undefined }} title="Pick a run" aria-label="Choose run" onClick={() => setRunsOpen((o) => !o)}>▾</button>
                  {runsOpen ? (
                    <>
                      <div onClick={() => setRunsOpen(false)} style={{ position: "fixed", inset: 0, zIndex: 40 }} />
                      <div style={{ position: "absolute", top: "100%", left: 0, zIndex: 41, minWidth: 248, maxHeight: 360, overflowY: "auto", background: "var(--panel)", border: "1px solid var(--line)", borderRadius: "var(--radius)", boxShadow: "0 10px 32px rgba(0,0,0,.5)", padding: "6px 0" }}>
                        <div className="eyebrow" style={{ padding: "6px 14px 8px" }}>Runs · click to view</div>
                        {g.history.map((t, i) => {
                          const oc = t.outcome === "timed" ? "var(--good)" : t.outcome === "wipe" ? "var(--danger)" : "var(--amber)"
                          const active = t.id === route.reportRunId || (route.reportRunId === null && i === 0)
                          const hideMeta = g.watchedSeed !== t.seed && i === 0   // don't spoil an unwatched fresh run
                          return (
                            <div key={t.id} className={"fight" + (active ? " active" : "")} style={{ cursor: "pointer" }}
                              onClick={() => { setRoute({ page: "report", charId: null, reportRunId: t.id }); setRunsOpen(false) }}>
                              <span className="fight-ic" style={{ background: oc, borderRadius: 3 }} />
                              <span className="fight-nm">{t.ownerName} · +{t.keyLevel}{i === 0 ? <span style={{ color: "var(--faint)", fontWeight: 400 }}> · latest</span> : null}</span>
                              <span className="fight-meta mono">
                                {hideMeta ? "···" : <>{t.deaths > 0 ? <span style={{ color: "var(--danger)", marginRight: 6 }}>☠{t.deaths}</span> : null}{mmss(t.durationSec)}</>}
                              </span>
                            </div>
                          )
                        })}
                      </div>
                    </>
                  ) : null}
                </div>
              )
            })}
          </div>
        ) : null}
        <div className="nav-spacer" />
        {playing ? (
          <div className="nav-readout mono">
            <span className="nav-stat"><span className="k">Key</span><span style={{ color: "var(--amber)", fontWeight: 700 }}>+{g.keystone.level}</span></span>
            <span className="nav-stat"><span className="k">Emblems</span><span style={{ color: "var(--amber)" }}>{fmt(g.wallet.emblems)}</span></span>
            <span className="nav-stat"><span className="k">Shards</span><span style={{ color: "var(--accent)" }}>{fmt(g.wallet.shards)}</span></span>
          </div>
        ) : null}
      </nav>

      <div className="app-body">
        <div className="app-main">
          {page === "guild" ? <GuildCreatePage /> : null}
          {page === "recruit" ? <RecruitPage go={go} /> : null}
          {page === "setup" ? <SetupPage go={go} /> : null}
          {page === "report" ? <ReportPage go={go} goChar={goChar} viewId={route.reportRunId} setViewId={(id) => setRoute((r) => ({ ...r, page: "report", reportRunId: id }))} /> : null}
          {page === "loot" ? <LootPage go={go} /> : null}
          {page === "keystone" ? <KeystonePage go={go} /> : null}
          {page === "roster" ? <RosterPage goChar={goChar} /> : null}
          {page === "character" && route.charId ? <CharacterPage id={route.charId} go={go} goChar={goChar} /> : null}
        </div>
        {/* the Report page hosts its own chat (moved into the body); every other page keeps the docked chat rail */}
        {playing && page !== "report" ? <GuildFeed goChar={goChar} /> : null}
      </div>
    </div>
  )
}
