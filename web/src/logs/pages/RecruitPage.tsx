/* Step 2 / 5 — Recruitment: a Warcraft-Logs-style scouting board. Dense list (left) + scout detail panel (right).
   Two display numbers per recruit: precise Current Operator Rating (now) and a fuzzy Potential ★ (ceiling). */
import { useState } from "react"
import { useGame, type RoleKey, SLOTS } from "@/state/game-store"
import { mc, qualityColor } from "../analytics"
import { RolePill, GameIcon, Tip, TipBody, ItemIcon, ItemTip } from "../components"
import { TalentStrip } from "../TalentGrid"
import { Stars, corColor, SkillBars, scoutBlurb, traitCombatSummary } from "../OperatorPanel"
import type { Go } from "../LogsApp"

/** Canonical morale colour ramp (good ≥70 · amber ≥55 · danger) — shared by the table + the scout panel. */
const moraleColor = (m: number): string => (m >= 70 ? "var(--good)" : m >= 55 ? "var(--amber)" : "var(--danger)")
const MORALE_TIP = "How willing they are to show up and grind. Wins lift it, wipes tank it — high morale sharpens performance, and below 25 they may walk."

export function RecruitPage({ go }: { go: Go }) {
  const g = useGame()
  const [roleFilter, setRoleFilter] = useState<"all" | RoleKey>("all")
  const [selId, setSelId] = useState<string | null>(null)

  const pool = roleFilter === "all" ? g.recruits : g.recruits.filter((r) => r.role === roleFilter)
  const sel = pool.find((r) => r.id === selId) ?? pool[0]
  const signedCount = g.signedRecruitIds.length
  const onboarding = g.phase === "recruit"
  const rosterAfter = g.members.length + signedCount
  const needed = Math.max(0, 5 - rosterAfter)

  return (
    <div className="page-scroll" style={{ padding: 24 }}>
      <div style={{ maxWidth: 1320, margin: "0 auto" }}>
        {/* header */}
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-end", marginBottom: 18 }}>
          <div>
            <div className="eyebrow" style={{ color: "var(--accent)" }}>{onboarding ? "Step 2 · Recruitment" : "Recruitment"}</div>
            <div style={{ fontSize: 26, fontWeight: 700, marginTop: 5 }}>Scouting Board</div>
            <div className="flux" style={{ fontSize: 14, marginTop: 4 }}>
              {onboarding
                ? (needed > 0 ? <>Sign <b style={{ color: "var(--text)" }}>{needed}</b> more to field a full party of five.</> : "Party full — confirm to take your roster into the first key.")
                : <>Rating is what they are <b style={{ color: "var(--text)" }}>now</b>; ★ is how high they can climb. Win-now veteran or high-ceiling project?</>}
            </div>
          </div>
          <div style={{ display: "flex", gap: 12, alignItems: "center" }}>
            <div className="tile" style={{ textAlign: "center", minWidth: 92 }}><div className="lbl">Signed</div><div className="val" style={{ color: rosterAfter >= 5 ? "var(--good)" : "var(--accent)" }}>{signedCount}</div></div>
            <div className="tile" style={{ textAlign: "center", minWidth: 110 }}><div className="lbl">Emblems</div><div className="val mono" style={{ color: "var(--amber)" }}>{g.wallet.emblems}</div></div>
          </div>
        </div>

        {/* filters + reroll */}
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 14 }}>
          <div className="seg-group">
            {([["all", "All"], ["tank", "Tanks"], ["healer", "Healers"], ["dps", "DPS"]] as [string, string][]).map(([id, lbl]) => (
              <button key={id} className={"seg-btn" + (roleFilter === id ? " on" : "")} onClick={() => setRoleFilter(id as "all" | RoleKey)}>{lbl}</button>
            ))}
          </div>
          <button className="btn btn-sm btn-ghost" onClick={() => g.rerollRecruits()}>↻ New Recruits</button>
        </div>

        {/* list + detail */}
        <div style={{ display: "grid", gridTemplateColumns: "1fr 372px", gap: 18, alignItems: "start" }}>
          <div className="panel" style={{ overflow: "hidden" }}>
            <table className="runs">
              <thead>
                <tr>
                  <th>Player</th>
                  <th>Role</th>
                  <th className="r">iLvl</th>
                  <th className="r">Rating</th>
                  <th>Potential</th>
                  <th className="r">Morale</th>
                  <th className="r">Cost</th>
                  <th className="r"></th>
                </tr>
              </thead>
              <tbody>
                {pool.map((r) => {
                  const info = mc(r.specId)
                  const isSigned = g.signedRecruitIds.includes(r.id)
                  const isSel = sel?.id === r.id
                  const afford = g.wallet.emblems >= r.cost
                  return (
                    <tr key={r.id} onClick={() => setSelId(r.id)}
                      style={{ cursor: "pointer", background: isSel ? "rgba(43,182,164,.08)" : undefined, boxShadow: isSel ? "inset 2px 0 0 var(--accent)" : undefined }}>
                      <td>
                        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                          <span style={{ width: 34, height: 34, borderRadius: "var(--radius)", background: "var(--panel-3)", border: `1.5px solid ${info.color}`, display: "flex", alignItems: "center", justifyContent: "center", flex: "none", opacity: isSigned ? .7 : 1 }}><GameIcon kind="spec" id={r.specId} size={24} color={info.color} label={`${info.subspec} ${info.klass}`} /></span>
                          <span style={{ color: info.color, fontWeight: 700, fontSize: 14.5 }}>{r.name}{isSigned ? <span style={{ color: "var(--accent)", fontSize: 11, marginLeft: 6 }}>✓</span> : null}</span>
                        </div>
                      </td>
                      <td><RolePill role={r.role} iconOnly /></td>
                      <td className="r mono" style={{ fontWeight: 600 }}>{r.ilvl}</td>
                      <td className="r"><span className="mono" style={{ fontWeight: 700, fontSize: 15, color: corColor(r.cor) }}>{r.cor}</span></td>
                      <td><Stars value={r.stars} size={13} /></td>
                      <td className="r mono" style={{ color: moraleColor(r.morale), fontWeight: 600 }}>{r.morale}%</td>
                      <td className="r mono" style={{ color: afford || isSigned ? "var(--amber)" : "var(--danger)" }}>◈{r.cost}</td>
                      <td className="r">
                        {isSigned ? (
                          <button className="btn btn-sm" onClick={(e) => { e.stopPropagation(); g.toggleSignRecruit(r.id) }} style={{ color: "var(--accent)", borderColor: "var(--accent-dim)" }}>Release</button>
                        ) : (
                          <button className="btn btn-primary btn-sm" disabled={!afford} style={{ opacity: afford ? 1 : .45, pointerEvents: afford ? "auto" : "none" }} onClick={(e) => { e.stopPropagation(); g.toggleSignRecruit(r.id) }}>Sign</button>
                        )}
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>

          {/* scout detail */}
          {sel ? <ScoutDetail key={sel.id} r={sel} /> : <div className="panel" style={{ padding: 24 }} ><span className="flux">No recruits match this filter.</span></div>}
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

function ScoutDetail({ r }: { r: ReturnType<typeof useGame>["recruits"][number] }) {
  const g = useGame()
  const info = mc(r.specId)
  const isSigned = g.signedRecruitIds.includes(r.id)
  const afford = g.wallet.emblems >= r.cost
  const combat = traitCombatSummary([r.traitId])
  return (
    <div className="panel" style={{ position: "sticky", top: 12, overflow: "hidden" }}>
      {/* header — spec icon fills a tight border; role is icon-only beside the name; ilvl + morale sit where the role pill used to */}
      <div style={{ padding: "16px 16px 14px", display: "flex", gap: 13, alignItems: "center", background: `${info.color}1f`, borderBottom: "1px solid var(--line-soft)" }}>
        <span style={{ width: 52, height: 52, borderRadius: "var(--radius)", background: "var(--panel-3)", border: `1.5px solid ${info.color}`, display: "flex", alignItems: "center", justifyContent: "center", flex: "none", overflow: "hidden" }}>
          <GameIcon kind="spec" id={r.specId} size={46} color={info.color} label={`${info.subspec} ${info.klass}`} />
        </span>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
            <span style={{ color: info.color, fontWeight: 700, fontSize: 19, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{r.name}</span>
            <RolePill role={r.role} iconOnly />
          </div>
          <div style={{ color: "var(--faint)", fontSize: 12.5, marginTop: 2 }}>{info.subspec} {info.klass}</div>
        </div>
        <div style={{ display: "flex", flexDirection: "column", alignItems: "flex-end", gap: 5, flex: "none" }}>
          <div style={{ textAlign: "right" }}>
            <div className="eyebrow" style={{ fontSize: 8.5, lineHeight: 1 }}>iLvl</div>
            <div className="mono" style={{ fontSize: 17, fontWeight: 700, lineHeight: 1.1 }}>{r.ilvl}</div>
          </div>
          <Tip tip={<TipBody title="Morale" desc={MORALE_TIP} />}>
            <span className="mono" style={{ fontSize: 13, fontWeight: 700, color: moraleColor(r.morale), cursor: "help" }}>{r.morale}% <span style={{ color: "var(--faint)", fontWeight: 400, fontSize: 9.5 }}>mrl</span></span>
          </Tip>
        </div>
      </div>

      {/* the two scouting numbers */}
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", borderBottom: "1px solid var(--line-soft)" }}>
        <div style={{ padding: "13px 16px", borderRight: "1px solid var(--line-soft)" }}>
          <div className="eyebrow" style={{ fontSize: 9.5 }}>Operator Rating</div>
          <div className="mono" style={{ fontSize: 30, fontWeight: 700, color: corColor(r.cor), lineHeight: 1.1 }}>{r.cor}</div>
          <div className="flux" style={{ fontSize: 10.5 }}>how good now</div>
        </div>
        <div style={{ padding: "13px 16px" }}>
          <div className="eyebrow" style={{ fontSize: 9.5 }}>Potential</div>
          <div style={{ marginTop: 5 }}><Stars value={r.stars} size={17} /></div>
          <div className="flux" style={{ fontSize: 10.5, marginTop: 4 }}>how high they climb</div>
        </div>
      </div>

      {/* scout report */}
      <div style={{ padding: "12px 16px", borderBottom: "1px solid var(--line-soft)", background: "var(--row-alt)" }}>
        <div className="flux" style={{ fontSize: 12.5, fontStyle: "italic" }}>“{scoutBlurb(r.cor, r.stars)}”</div>
      </div>

      {/* equipped gear — a real paper-doll reflecting their ilvl (per-slot) + quality (rarity); inherited on sign */}
      <div style={{ padding: "12px 16px", borderBottom: "1px solid var(--line-soft)" }}>
        <div className="eyebrow" style={{ fontSize: 10, marginBottom: 9 }}>Equipped</div>
        <div style={{ display: "flex", gap: 6 }}>
          {SLOTS.map((s) => {
            const it = r.gear?.[s]
            return it
              ? <Tip key={s} accent={qualityColor(it.rarity)} tip={<ItemTip item={it} />}><span style={{ display: "inline-flex" }}><ItemIcon item={it} size={36} /></span></Tip>
              : <span key={s} style={{ width: 36, height: 36, borderRadius: "var(--radius)", border: "1px solid var(--line-soft)", display: "inline-block" }} />
          })}
        </div>
      </div>

      {/* talents — selected default build (one row) + a popup with the full 5×3 grid */}
      <TalentStrip specId={r.specId} />

      {/* aptitudes (operator skills) */}
      <div style={{ padding: 16, borderBottom: "1px solid var(--line-soft)" }}>
        <div className="eyebrow" style={{ fontSize: 10, marginBottom: 11 }}>Aptitudes <span style={{ color: "var(--faint)", letterSpacing: 0, textTransform: "none", fontWeight: 400 }}>— ceiling shown where scouted</span></div>
        <SkillBars skills={r.skills} ceilings={r.ceilings} revealed={r.revealed} color={info.color} />
      </div>

      {/* trait + sign */}
      <div style={{ padding: 16 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 6 }}>
          <span style={{ fontSize: 11, fontWeight: 700, letterSpacing: ".04em", textTransform: "uppercase", padding: "2px 9px", borderRadius: "var(--radius)", color: r.traitGood ? "var(--good)" : "var(--danger)", background: r.traitGood ? "rgba(78,199,123,.12)" : "rgba(224,68,78,.12)", border: `1px solid ${r.traitGood ? "rgba(78,199,123,.32)" : "rgba(224,68,78,.32)"}` }}>{r.traitName}</span>
          {combat ? <span className="mono" style={{ fontSize: 11, color: "var(--muted)" }}>{combat}</span> : null}
        </div>
        <div className="flux" style={{ fontSize: 12.5, minHeight: 32 }}>{r.traitFlavor}</div>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginTop: 14 }}>
          <span className="mono" style={{ fontSize: 13, color: afford || isSigned ? "var(--amber)" : "var(--danger)" }}>◈ {r.cost} emblems</span>
          {isSigned ? (
            <button className="btn btn-sm" onClick={() => g.toggleSignRecruit(r.id)} style={{ color: "var(--accent)", borderColor: "var(--accent-dim)" }}>✓ Signed · Release</button>
          ) : (
            <button className="btn btn-primary" disabled={!afford} style={{ opacity: afford ? 1 : .45, pointerEvents: afford ? "auto" : "none", padding: "8px 20px" }} onClick={() => g.toggleSignRecruit(r.id)}>Sign</button>
          )}
        </div>
      </div>
    </div>
  )
}
