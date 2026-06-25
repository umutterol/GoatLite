/* Step 3 / 6 — New Run: keystone, affixes, party, aggression + tactics, then simulate. */
import { useState } from "react"
import { content } from "@/content"
import { useGame, type RoleKey } from "@/state/game-store"
import { activeAffixIds } from "@/sim/affixes"
import type { Aggression } from "@/sim"
import { mc, qualityColor, moraleColor } from "../analytics"
import { rarityForIlvl } from "@/state/item-stats"
import { Icon, GameIcon, Panel, RolePill, KeyTip, IconLabel } from "../components"
import type { Go } from "../LogsApp"

const TACTICS = [...content.tactics.values()]
const AGGRO: { id: Aggression; name: string; desc: string }[] = [
  { id: "Safe", name: "Safe", desc: "Wide pulls off the table. You will time it, slowly." },
  { id: "Balanced", name: "Balanced", desc: "Press where it's free, respect what bites back." },
  { id: "Yolo", name: "Yolo", desc: "Everything at once. Glorious, or a four-minute death report." },
]
const TOTAL_POINTS = 6, MAX_PER = 3

export function SetupPage({ go }: { go: Go }) {
  const g = useGame()
  const [aggression, setAggression] = useState<Aggression>("Balanced")
  const [tactics, setTactics] = useState<Record<string, number>>({ interrupts: 2, positioning: 1, cooldowns: 1, killorder: 2 })
  const [keyPage, setKeyPage] = useState(0)
  const [benchFilter, setBenchFilter] = useState<"all" | RoleKey>("all")
  const [benchSort, setBenchSort] = useState<{ key: "name" | "role" | "ilvl" | "morale"; dir: 1 | -1 }>({ key: "ilvl", dir: -1 })
  const sortBy = (key: "name" | "role" | "ilvl" | "morale") =>
    setBenchSort((s) => ({ key, dir: s.key === key ? (s.dir * -1 as 1 | -1) : (key === "name" || key === "role" ? 1 : -1) }))

  const used = TACTICS.reduce((s, t) => s + (tactics[t.id] || 0), 0)
  const left = TOTAL_POINTS - used
  const setTactic = (id: string, delta: number) => {
    const next = { ...tactics, [id]: Math.max(0, Math.min(MAX_PER, (tactics[id] || 0) + delta)) }
    if (TACTICS.reduce((s, t) => s + (next[t.id] || 0), 0) <= TOTAL_POINTS) setTactics(next)
  }
  const partyFull = g.party.length === 5
  const keys = [...g.keys].sort((a, b) => b.level - a.level)   // highest keys first
  const weekAffixes = g.weekAffixes  // weekly + level-gated (same set for every key; which are ACTIVE depends on the key's level)
  const KEYS_PER_PAGE = 10
  const totalKeyPages = Math.max(1, Math.ceil(keys.length / KEYS_PER_PAGE))
  const keyPg = Math.min(keyPage, totalKeyPages - 1)
  const pageKeys = keys.slice(keyPg * KEYS_PER_PAGE, keyPg * KEYS_PER_PAGE + KEYS_PER_PAGE)
  // party = 5 slots (key owner pinned first); bench = the rest of the guild, role-filtered + sorted
  const ownerId = g.selectedKeyOwnerId
  const partyOrdered = [...g.party].sort((a, b) => (a.id === ownerId ? -1 : 0) - (b.id === ownerId ? -1 : 0) || a.name.localeCompare(b.name))
  const bench = g.members
    .filter((m) => !g.partyIds.includes(m.id))
    .filter((m) => benchFilter === "all" || mc(m.spec).role === benchFilter)
    .sort((a, b) => {
      const d = benchSort.dir
      if (benchSort.key === "name") return d * a.name.localeCompare(b.name)
      if (benchSort.key === "role") return d * mc(a.spec).role.localeCompare(mc(b.spec).role)
      if (benchSort.key === "ilvl") return d * (a.ilvl - b.ilvl)
      return d * (a.morale - b.morale)
    })

  const simulate = () => { if (g.party.length !== 5) return; g.runKey({ tactics, aggression }); go("report") }

  return (
    <div className="page-scroll" style={{ padding: 24 }}>
      <div style={{ maxWidth: 1280, margin: "0 auto" }}>
        <div style={{ marginBottom: 18 }}>
          <div className="eyebrow">Plan a Run</div>
          <div style={{ fontSize: 24, fontWeight: 700, marginTop: 4 }}>New Keystone</div>
        </div>

        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 18, alignItems: "start" }}>
          {/* keys — the focus of this board. Pick one to run; its holder locks into the party. */}
          <div style={{ display: "flex", flexDirection: "column", gap: 18 }}>
            <Panel title="Choose a Key" right={<span className="mono" style={{ fontSize: 11.5, color: "var(--faint)" }}>timer {g.keystone.timer}</span>} bodyStyle={{ padding: 0 }}>
              {/* fixed height while paginated → a short last page reserves the full 10-row space (panel never shrinks) */}
              <div style={{ height: totalKeyPages > 1 ? 462 : undefined, overflowY: "auto" }}>
              <table className="runs">
                <thead>
                  <tr>
                    <th>Key</th>
                    <th>Affixes</th>
                    <th>Owner</th>
                    <th className="r">Lvl</th>
                  </tr>
                </thead>
                <tbody>
                  {pageKeys.map((k) => {
                    const info = mc(k.spec)
                    const sel = k.ownerId === g.selectedKeyOwnerId
                    const active = activeAffixIds(weekAffixes.map((a) => a.id), k.level)
                    return (
                      <tr key={k.ownerId} data-key-row onClick={() => g.selectKey(k.ownerId)}
                        style={{ cursor: "pointer", background: sel ? "rgba(43,182,164,.08)" : undefined, boxShadow: sel ? "inset 2px 0 0 var(--accent)" : undefined }}>
                        {/* key icon + name as ONE merged element, whole thing pops the Epic KeyTip */}
                        <td><IconLabel kind="dungeon" id={k.dungeonId} name={`${k.dungeon} Keystone`} color={qualityColor("Epic")} accent={qualityColor("Epic")} size={24}
                          tip={<KeyTip name={k.dungeon} level={k.level} timer={k.timer} best={k.best} affixes={weekAffixes} />} /></td>
                        <td>
                          {weekAffixes.length ? (
                            <span style={{ display: "inline-flex", gap: 3 }}>
                              {weekAffixes.map((a) => <GameIcon key={a.id} kind="affix" id={a.id} size={16} label={a.name} style={{ opacity: active.includes(a.id) ? 1 : .28 }} />)}
                            </span>
                          ) : <span style={{ color: "var(--faint)", fontSize: 11.5 }}>—</span>}
                        </td>
                        <td><IconLabel kind="spec" id={k.spec} name={k.ownerName} color={info.color} size={18} fontSize={13} /></td>
                        <td className="r mono" style={{ fontWeight: 700, fontSize: 15, color: sel ? "var(--amber)" : "var(--muted)" }}>+{k.level}</td>
                      </tr>
                    )
                  })}
                </tbody>
              </table>
              </div>
              {totalKeyPages > 1 ? (
                <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "8px 14px" }}>
                  <span className="flux mono" style={{ fontSize: 11.5, color: "var(--faint)" }}>{keyPg * KEYS_PER_PAGE + 1}–{Math.min(keys.length, keyPg * KEYS_PER_PAGE + KEYS_PER_PAGE)} of {keys.length}</span>
                  <div style={{ display: "flex", gap: 6 }}>
                    <button className="btn btn-sm btn-ghost" disabled={keyPg <= 0} onClick={() => setKeyPage(keyPg - 1)}>‹ Prev</button>
                    <button className="btn btn-sm btn-ghost" disabled={keyPg >= totalKeyPages - 1} onClick={() => setKeyPage(keyPg + 1)}>Next ›</button>
                  </div>
                </div>
              ) : null}
              {weekAffixes.length && !activeAffixIds(weekAffixes.map((a) => a.id), g.keystone.level).length
                ? <div className="flux" style={{ fontSize: 11.5, color: "var(--faint)", padding: "8px 14px 12px" }}>Affixes unlock as the key climbs — none are live at this level yet.</div>
                : null}
            </Panel>
          </div>

          {/* party & tactics */}
          <div style={{ display: "flex", flexDirection: "column", gap: 18 }}>
            <Panel title="Party" right={<span className="mono" style={{ fontSize: 12, color: partyFull ? "var(--good)" : "var(--amber)" }}>{g.party.length}/5</span>} bodyStyle={{ padding: 12 }}>
              {/* 5 square party slots — key owner pinned (★, locked), others removable (×), empties are click-to-fill targets */}
              <div style={{ display: "flex", gap: 8 }}>
                {Array.from({ length: 5 }).map((_, i) => {
                  const m = partyOrdered[i]
                  if (!m) return <div key={i} data-party-slot style={{ flex: 1, aspectRatio: "1 / 1", borderRadius: "var(--radius)", border: "1px dashed var(--line)", display: "flex", alignItems: "center", justifyContent: "center", color: "var(--faint)", fontSize: 24 }}>+</div>
                  const info = mc(m.spec), isOwner = m.id === ownerId
                  return (
                    <div key={m.id} data-party-slot style={{ flex: 1, aspectRatio: "1 / 1", minWidth: 0, position: "relative", borderRadius: "var(--radius)", border: `1px solid ${info.color}66`, background: `${info.color}14`, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 4, padding: 6 }}>
                      <GameIcon kind="spec" id={m.spec} size={51} color={info.color} label={`${info.subspec} ${info.klass}`} />
                      <span style={{ color: info.color, fontWeight: 700, fontSize: 11.5, maxWidth: "100%", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{m.name}</span>
                      <span className="mono" style={{ fontSize: 16, fontWeight: 700, color: qualityColor(rarityForIlvl(m.ilvl)) }}>{m.ilvl}</span>
                      {isOwner
                        ? <span title="Key holder — locked into the party" style={{ position: "absolute", top: 3, right: 5, fontSize: 11, color: "var(--amber)" }}>★</span>
                        : <button title="Remove from party" onClick={() => g.togglePartyMember(m.id)} style={{ position: "absolute", top: 0, right: 3, border: "none", background: "none", color: "var(--faint)", cursor: "pointer", fontSize: 15, lineHeight: 1 }}>×</button>}
                    </div>
                  )
                })}
              </div>

              {/* the rest of the guild — role filter + sortable headers, click a row to fill the next open slot */}
              <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 8, margin: "14px 0 2px" }}>
                <div className="seg-group">
                  {([["all", "All"], ["tank", "Tank"], ["healer", "Heal"], ["dps", "DPS"]] as [string, string][]).map(([id, lbl]) => (
                    <button key={id} className={"seg-btn" + (benchFilter === id ? " on" : "")} onClick={() => setBenchFilter(id as "all" | RoleKey)}>{lbl}</button>
                  ))}
                </div>
                <span className="flux" style={{ fontSize: 11, color: "var(--faint)" }}>{bench.length} on the bench</span>
              </div>
              <div style={{ height: 232, overflowY: "auto" }}>
                <table className="runs">
                  <thead>
                    <tr>
                      {([["name", "Member", ""], ["role", "Role", ""], ["ilvl", "iLvl", "r"], ["morale", "Mrl", "r"]] as [typeof benchSort.key, string, string][]).map(([k, lbl, cls]) => (
                        <th key={k} className={cls} onClick={() => sortBy(k)} style={{ cursor: "pointer", position: "sticky", top: 0, background: "var(--panel)", userSelect: "none" }}>
                          {lbl}{benchSort.key === k ? (benchSort.dir < 0 ? " ↓" : " ↑") : ""}
                        </th>
                      ))}
                      <th style={{ position: "sticky", top: 0, background: "var(--panel)" }}></th>
                    </tr>
                  </thead>
                  <tbody>
                    {bench.map((m) => {
                      const info = mc(m.spec)
                      return (
                        <tr key={m.id} data-bench-row onClick={() => !partyFull && g.togglePartyMember(m.id)}
                          style={{ cursor: partyFull ? "not-allowed" : "pointer", opacity: partyFull ? .5 : 1 }}>
                          <td><IconLabel kind="spec" id={m.spec} name={m.name} color={info.color} size={22} fontSize={13} /></td>
                          <td><RolePill role={info.role} iconOnly /></td>
                          <td className="r mono" style={{ color: qualityColor(rarityForIlvl(m.ilvl)), fontWeight: 600 }}>{m.ilvl}</td>
                          <td className="r mono" style={{ color: moraleColor(m.morale) }}>{m.morale}%</td>
                          <td className="r mono" style={{ fontSize: 11, color: partyFull ? "var(--faint)" : "var(--accent)" }}>{partyFull ? "full" : "+ add"}</td>
                        </tr>
                      )
                    })}
                  </tbody>
                </table>
                {bench.length === 0 ? <div className="flux" style={{ fontSize: 12, color: "var(--faint)", padding: "12px 8px", textAlign: "center" }}>No guild members match this filter.</div> : null}
              </div>
              {!partyFull ? <div className="flux" style={{ fontSize: 12.5, padding: "8px 4px 0", color: "var(--danger)" }}>Pick {5 - g.party.length} more — click a member below to add them.</div> : null}
            </Panel>

            {/* thin aggression strip — seg + live math (from tuning, can't drift); flavour on hover */}
            <Panel title="Aggression" bodyStyle={{ padding: 12 }}>
              {/* 3 balanced cards — each option carries its own math, so there's no orphan stat line */}
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 6 }}>
                {AGGRO.map((a) => {
                  const t = content.tuning.aggression[a.id]
                  const dc = (content.tuning.hitQuality.dialCrit as Record<string, number>)[a.id] ?? 0
                  const out = Math.round((t.output - 1) * 100), intake = Math.round((t.avoidableIntake - 1) * 100), crit = Math.round(dc * 100)
                  const sign = (n: number) => (n > 0 ? "+" : "") + n
                  const neutral = out === 0 && intake === 0 && crit === 0
                  const on = aggression === a.id
                  return (
                    <button key={a.id} title={a.desc} onClick={() => setAggression(a.id)}
                      style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 4, padding: "9px 6px", borderRadius: "var(--radius)", cursor: "pointer", textAlign: "center", fontFamily: "inherit",
                        border: on ? "1px solid var(--accent)" : "1px solid var(--line)", background: on ? "rgba(43,182,164,.10)" : "var(--panel-3)" }}>
                      <span style={{ fontWeight: 700, fontSize: 13, color: on ? "var(--accent)" : "var(--text)" }}>{a.name}</span>
                      <span className="mono" style={{ fontSize: 10, lineHeight: 1.45, color: on ? "var(--muted)" : "var(--faint)" }}>
                        {neutral ? "baseline" : <>{sign(out)}% out · {sign(intake)}% taken{crit !== 0 ? <><br />{sign(crit)}% crit</> : null}</>}
                      </span>
                    </button>
                  )
                })}
              </div>
            </Panel>

            {/* compact tactics — 4 icons across, name + dials below each; the icon's tooltip carries the full effect */}
            <Panel title="Tactics" right={<span className="mono" style={{ fontSize: 12, color: left === 0 ? "var(--good)" : "var(--amber)" }}>{left} of {TOTAL_POINTS} left</span>} bodyStyle={{ padding: 14 }}>
              <div style={{ display: "flex", gap: 10 }}>
                {TACTICS.map((t) => (
                  <div key={t.id} style={{ flex: 1, minWidth: 0, display: "flex", flexDirection: "column", alignItems: "center", gap: 7 }}>
                    <GameIcon kind="tactic" id={t.id} size={30} color="var(--muted)" label={t.name} />
                    <div style={{ fontWeight: 600, fontSize: 12, textAlign: "center", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis", maxWidth: "100%" }}>{t.name}</div>
                    <div className="stepper sm">
                      <button disabled={(tactics[t.id] || 0) <= 0} onClick={() => setTactic(t.id, -1)}>−</button>
                      <span className="v">{tactics[t.id] || 0}</span>
                      <button disabled={left <= 0 || (tactics[t.id] || 0) >= MAX_PER} onClick={() => setTactic(t.id, +1)}>+</button>
                    </div>
                  </div>
                ))}
              </div>
            </Panel>

            <button className="btn btn-primary" style={{ justifyContent: "center", padding: 14, fontSize: 15, opacity: partyFull ? 1 : .5, pointerEvents: partyFull ? "auto" : "none" }} onClick={simulate}>
              <Icon name="bolt" size={16} color="#04201d" /> Start the Run
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
