/* Roster — Raider.io–style guild table. */
import { useState } from "react"
import { useGame, roleOf, type RoleKey } from "@/state/game-store"
import { mc, memberScore, scoreColor } from "../analytics"
import { Icon, RolePill } from "../components"
import type { GoChar } from "../LogsApp"

export function RosterPage({ goChar }: { goChar: GoChar }) {
  const g = useGame()
  const [sort, setSort] = useState<"score" | "ilvl" | "name">("score")
  const [roleFilter, setRoleFilter] = useState<"all" | RoleKey>("all")

  const keyOf = (m: typeof g.members[number]) => m.key?.best || m.key?.level || 2   // each member's own key
  let rows = g.members.map((m) => ({ ...m, role: roleOf(m.spec), keyLvl: keyOf(m), score: memberScore(m.ilvl, keyOf(m)) }))
  if (roleFilter !== "all") rows = rows.filter((r) => r.role === roleFilter)
  rows = rows.sort((a, b) => (sort === "score" ? b.score - a.score : sort === "ilvl" ? b.ilvl - a.ilvl : a.name.localeCompare(b.name)))

  const avg = g.members.length ? Math.round(g.members.reduce((s, m) => s + memberScore(m.ilvl, keyOf(m)), 0) / g.members.length) : 0
  const core = g.partyIds.length
  const crest = g.guild?.crest ?? "#2bb6a4"

  if (!g.members.length) {
    return (
      <div className="page-scroll" style={{ display: "flex", alignItems: "center", justifyContent: "center" }}>
        <div style={{ textAlign: "center", padding: 40 }}>
          <Icon name="roster" size={40} color="var(--faint)" />
          <div style={{ fontSize: 20, fontWeight: 700, marginTop: 14 }}>No players yet</div>
          <div className="flux" style={{ fontSize: 14, marginTop: 8 }}>Head to Recruitment to sign your roster.</div>
        </div>
      </div>
    )
  }

  return (
    <div className="page-scroll" style={{ padding: 24 }}>
      <div style={{ maxWidth: 1280, margin: "0 auto" }}>
        {/* guild header */}
        <div className="panel" style={{ padding: 22, marginBottom: 18, display: "flex", alignItems: "center", justifyContent: "space-between", background: "linear-gradient(110deg, #1c1f27, #16171c)" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 18 }}>
            <div style={{ width: 58, height: 58, borderRadius: 12, background: `linear-gradient(150deg, ${crest}, ${crest}88)`, display: "flex", alignItems: "center", justifyContent: "center", color: "#04201d", fontWeight: 700, fontSize: 28, boxShadow: `0 0 20px ${crest}55`, border: `2px solid ${crest}` }}>{g.guild?.glyph ?? "G"}</div>
            <div>
              <div style={{ fontSize: 24, fontWeight: 700, whiteSpace: "nowrap" }}>&lt;{g.guild?.name ?? "Greatest of All Time"}&gt;</div>
              <div className="mono" style={{ color: "var(--faint)", fontSize: 13, marginTop: 3 }}>{g.guild?.region ?? "—"} · {g.guild?.faction === "alliance" ? "Alliance" : "Horde"}</div>
            </div>
          </div>
          <div style={{ display: "flex", gap: 12 }}>
            <div className="tile" style={{ textAlign: "center", minWidth: 96 }}><div className="lbl">Roster</div><div className="val">{g.members.length}</div></div>
            <div className="tile" style={{ textAlign: "center", minWidth: 96 }}><div className="lbl">Party</div><div className="val" style={{ color: "var(--accent)" }}>{core}</div></div>
            <div className="tile" style={{ textAlign: "center", minWidth: 110 }}><div className="lbl">Avg M+ Score</div><div className="val" style={{ color: scoreColor(avg) }}>{avg}</div></div>
          </div>
        </div>

        {/* controls */}
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 12 }}>
          <div className="seg-group">
            {([["all", "All"], ["tank", "Tanks"], ["healer", "Healers"], ["dps", "DPS"]] as [string, string][]).map(([id, lbl]) => (
              <button key={id} className={"seg-btn" + (roleFilter === id ? " on" : "")} onClick={() => setRoleFilter(id as "all" | RoleKey)}>{lbl}</button>
            ))}
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
            <span className="eyebrow">Sort</span>
            <div className="seg-group">
              {([["score", "M+ Score"], ["ilvl", "Item Level"], ["name", "Name"]] as [string, string][]).map(([id, lbl]) => (
                <button key={id} className={"seg-btn" + (sort === id ? " on" : "")} onClick={() => setSort(id as "score" | "ilvl" | "name")}>{lbl}</button>
              ))}
            </div>
          </div>
        </div>

        {/* table */}
        <div className="panel" style={{ overflow: "hidden" }}>
          <table className="runs">
            <thead>
              <tr>
                <th style={{ width: 40 }}>#</th>
                <th>Character</th>
                <th>Role</th>
                <th className="r">Item Level</th>
                <th className="r">M+ Score</th>
                <th className="r">Best Key</th>
                <th className="r">Status</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((r, i) => {
                const info = mc(r.spec)
                const inParty = g.partyIds.includes(r.id)
                return (
                  <tr key={r.id} style={{ cursor: "pointer" }} onClick={() => goChar(r.id)}>
                    <td className="mono" style={{ color: "var(--faint)" }}>{i + 1}</td>
                    <td>
                      <div style={{ display: "flex", alignItems: "center", gap: 11 }}>
                        <span style={{ width: 30, height: 30, borderRadius: 7, background: info.color, display: "flex", alignItems: "center", justifyContent: "center", fontWeight: 700, color: "#0c0d11", fontSize: 14, flex: "none" }}>{r.name[0]}</span>
                        <div>
                          <div style={{ color: info.color, fontWeight: 700, fontSize: 14.5 }}>{r.name}</div>
                          <div style={{ color: "var(--faint)", fontSize: 12 }}>{info.subspec} {info.klass}</div>
                        </div>
                      </div>
                    </td>
                    <td><RolePill role={r.role} /></td>
                    <td className="r mono" style={{ fontWeight: 600 }}>{r.ilvl}</td>
                    <td className="r"><span className="mono" style={{ fontWeight: 700, fontSize: 15, color: scoreColor(r.score) }}>{r.score}</span></td>
                    <td className="r"><span className="key-badge" style={{ color: "var(--amber)" }}>+{r.keyLvl}</span></td>
                    <td className="r"><span className="chip" style={{ color: inParty ? "var(--accent)" : "var(--faint)" }}>{inParty ? "Core" : "Reserve"}</span></td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}
