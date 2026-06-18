/* Step 2 / 5 — Recruitment: browse and sign candidates. */
import { useState } from "react"
import { useGame, type RoleKey } from "@/state/game-store"
import { mc, scoreColor } from "../analytics"
import { RolePill, Stat } from "../components"
import type { Go } from "../LogsApp"

export function RecruitPage({ go }: { go: Go }) {
  const g = useGame()
  const [roleFilter, setRoleFilter] = useState<"all" | RoleKey>("all")

  const pool = roleFilter === "all" ? g.recruits : g.recruits.filter((r) => r.role === roleFilter)
  const signedCount = g.signedRecruitIds.length
  const onboarding = g.phase === "recruit"
  const rosterAfter = g.members.length + signedCount
  const needed = Math.max(0, 5 - rosterAfter)

  return (
    <div className="page-scroll" style={{ padding: 24 }}>
      <div style={{ maxWidth: 1280, margin: "0 auto" }}>
        {/* header */}
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-end", marginBottom: 18 }}>
          <div>
            <div className="eyebrow" style={{ color: "var(--accent)" }}>{onboarding ? "Step 2 · Recruitment" : "Recruitment"}</div>
            <div style={{ fontSize: 26, fontWeight: 700, marginTop: 5 }}>Available Players</div>
            <div className="flux" style={{ fontSize: 14, marginTop: 4 }}>
              {onboarding
                ? (needed > 0 ? <>Sign <b style={{ color: "var(--text)" }}>{needed}</b> more to field a full party of five.</> : "Party full — confirm to take your roster into the first key.")
                : <>Bench depth wins seasons. Sign who you like, or draw a fresh board.</>}
            </div>
          </div>
          <div style={{ display: "flex", gap: 12, alignItems: "center" }}>
            <div className="tile" style={{ textAlign: "center", minWidth: 92 }}><div className="lbl">Signed</div><div className="val" style={{ color: rosterAfter >= 5 ? "var(--good)" : "var(--accent)" }}>{signedCount}</div></div>
            <div className="tile" style={{ textAlign: "center", minWidth: 110 }}><div className="lbl">Emblems</div><div className="val mono" style={{ color: "var(--amber)" }}>{g.wallet.emblems}</div></div>
          </div>
        </div>

        {/* filters + reroll */}
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 16 }}>
          <div className="seg-group">
            {([["all", "All"], ["tank", "Tanks"], ["healer", "Healers"], ["dps", "DPS"]] as [string, string][]).map(([id, lbl]) => (
              <button key={id} className={"seg-btn" + (roleFilter === id ? " on" : "")} onClick={() => setRoleFilter(id as "all" | RoleKey)}>{lbl}</button>
            ))}
          </div>
          <button className="btn btn-sm btn-ghost" onClick={() => g.rerollRecruits()}>↻ New Recruits</button>
        </div>

        {/* recruit grid */}
        <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 14 }}>
          {pool.map((r) => {
            const info = mc(r.specId)
            const isSigned = g.signedRecruitIds.includes(r.id)
            const afford = g.wallet.emblems >= r.cost
            const moraleColor = r.morale >= 70 ? "var(--good)" : r.morale >= 55 ? "var(--amber)" : "var(--danger)"
            return (
              <div key={r.id} className="panel recruit-card" style={{ padding: 0, overflow: "hidden", opacity: isSigned ? .8 : 1, borderColor: isSigned ? "var(--accent)" : "var(--line)" }}>
                <div style={{ padding: "14px 16px", display: "flex", gap: 13, alignItems: "center", background: `linear-gradient(120deg, ${info.color}14, transparent)`, borderBottom: "1px solid var(--line-soft)" }}>
                  <span style={{ width: 44, height: 44, borderRadius: 11, background: `linear-gradient(150deg, ${info.color}, ${info.color}99)`, border: `2px solid ${info.color}`, display: "flex", alignItems: "center", justifyContent: "center", fontWeight: 700, color: "#0c0d11", fontSize: 20, flex: "none", boxShadow: `0 0 14px ${info.color}44` }}>{r.name[0]}</span>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ color: info.color, fontWeight: 700, fontSize: 17 }}>{r.name}</div>
                    <div style={{ color: "var(--faint)", fontSize: 12.5 }}>{info.subspec} {info.klass}</div>
                  </div>
                  <RolePill role={r.role} />
                </div>

                <div style={{ padding: "12px 16px", display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 8 }}>
                  <Stat label="Item Lvl" val={r.ilvl} />
                  <Stat label="M+ Score" val={r.score} color={scoreColor(r.score)} />
                  <Stat label="Morale" val={r.morale + "%"} color={moraleColor} />
                </div>

                <div style={{ padding: "0 16px 12px" }}>
                  <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 5 }}>
                    <span style={{ fontSize: 11, fontWeight: 700, letterSpacing: ".04em", textTransform: "uppercase", padding: "2px 9px", borderRadius: 5, color: r.traitGood ? "var(--good)" : "var(--danger)", background: (r.traitGood ? "rgba(78,199,123,.12)" : "rgba(224,68,78,.12)"), border: `1px solid ${r.traitGood ? "rgba(78,199,123,.32)" : "rgba(224,68,78,.32)"}` }}>{r.traitName}</span>
                    {!r.traitGood ? <span style={{ fontSize: 11, color: "var(--danger)", fontWeight: 600 }}>⚠ risk</span> : null}
                  </div>
                  <div className="flux" style={{ fontSize: 12.5, minHeight: 34 }}>{r.traitFlavor}</div>
                </div>

                <div style={{ padding: "12px 16px", borderTop: "1px solid var(--line-soft)", display: "flex", alignItems: "center", justifyContent: "space-between", background: "var(--row-alt)" }}>
                  <span className="mono" style={{ fontSize: 13, color: afford || isSigned ? "var(--amber)" : "var(--danger)" }}>◈ {r.cost} emblems</span>
                  {isSigned ? (
                    <button className="btn btn-sm" onClick={() => g.toggleSignRecruit(r.id)} style={{ color: "var(--accent)", borderColor: "var(--accent-dim)" }}>✓ Signed · Release</button>
                  ) : (
                    <button className="btn btn-primary btn-sm" disabled={!afford} style={{ opacity: afford ? 1 : .45, pointerEvents: afford ? "auto" : "none" }} onClick={() => g.toggleSignRecruit(r.id)}>Sign</button>
                  )}
                </div>
              </div>
            )
          })}
        </div>

        {/* commit CTA */}
        {onboarding ? (
          rosterAfter >= 5 ? (
            <div style={{ display: "flex", justifyContent: "center", marginTop: 24 }}>
              <button className="btn btn-primary" style={{ padding: "13px 28px", fontSize: 15 }} onClick={() => { g.confirmRecruits(); go("setup") }}>
                Party Ready → Run First Key (+{g.keystone.level})
              </button>
            </div>
          ) : null
        ) : signedCount > 0 ? (
          <div style={{ display: "flex", justifyContent: "center", marginTop: 24 }}>
            <button className="btn btn-primary" style={{ padding: "13px 28px", fontSize: 15 }} onClick={() => { g.confirmRecruits(); go("roster") }}>
              Add {signedCount} to Guild →
            </button>
          </div>
        ) : null}
      </div>
    </div>
  )
}
