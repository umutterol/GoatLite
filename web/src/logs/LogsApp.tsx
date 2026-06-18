/* GOAT Lite · Logs — app shell: top nav, routing, onboarding gate. */
import { useState } from "react"
import { useGame } from "@/state/game-store"
import { Icon } from "./components"
import { fmt } from "./analytics"
import { ReportPage } from "./pages/ReportPage"
import { RosterPage } from "./pages/RosterPage"
import { CharacterPage } from "./pages/CharacterPage"
import { SetupPage } from "./pages/SetupPage"
import { GuildCreatePage } from "./pages/GuildCreatePage"
import { RecruitPage } from "./pages/RecruitPage"
import { LootPage } from "./pages/LootPage"
import { KeystonePage } from "./pages/KeystonePage"

export type Page = "report" | "roster" | "character" | "setup" | "recruit" | "guild" | "loot" | "keystone"
export interface Route { page: Page; charId: string | null }
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
  const [route, setRoute] = useState<Route>({ page: "report", charId: null })
  const go: Go = (page) => setRoute({ page, charId: null })
  const goChar: GoChar = (id) => setRoute({ page: "character", charId: id })

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
            {NAV.map((n) => (
              <button key={n.id} className={"nav-tab" + (activeNav === n.id ? " active" : "")} onClick={() => go(n.id)}>
                <Icon name={n.icon} size={15} color={activeNav === n.id ? "var(--accent)" : "currentColor"} />
                {n.label}
              </button>
            ))}
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

      {page === "guild" ? <GuildCreatePage /> : null}
      {page === "recruit" ? <RecruitPage go={go} /> : null}
      {page === "setup" ? <SetupPage go={go} /> : null}
      {page === "report" ? <ReportPage go={go} goChar={goChar} /> : null}
      {page === "loot" ? <LootPage go={go} /> : null}
      {page === "keystone" ? <KeystonePage go={go} /> : null}
      {page === "roster" ? <RosterPage goChar={goChar} /> : null}
      {page === "character" && route.charId ? <CharacterPage id={route.charId} go={go} goChar={goChar} /> : null}
    </div>
  )
}
