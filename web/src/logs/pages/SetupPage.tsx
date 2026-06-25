/* Step 3 / 6 — New Run: keystone, affixes, party, aggression + tactics, then simulate. */
import { useState } from "react"
import { content } from "@/content"
import { useGame } from "@/state/game-store"
import { activeAffixIds } from "@/sim/affixes"
import type { Aggression } from "@/sim"
import { mc, qualityColor, moraleColor, MORALE_TIP } from "../analytics"
import { rarityForIlvl } from "@/state/item-stats"
import { Icon, GameIcon, Panel, RolePill, Tip, TipBody, KeyTip } from "../components"
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

  const used = TACTICS.reduce((s, t) => s + (tactics[t.id] || 0), 0)
  const left = TOTAL_POINTS - used
  const setTactic = (id: string, delta: number) => {
    const next = { ...tactics, [id]: Math.max(0, Math.min(MAX_PER, (tactics[id] || 0) + delta)) }
    if (TACTICS.reduce((s, t) => s + (next[t.id] || 0), 0) <= TOTAL_POINTS) setTactics(next)
  }
  const partyFull = g.party.length === 5
  const keys = [...g.keys].sort((a, b) => b.level - a.level)   // highest keys first
  const weekAffixes = g.weekAffixes  // weekly + level-gated (same set for every key; which are ACTIVE depends on the key's level)
  // roster picker order: key owner first, then the rest of the party, then the bench (each by ilvl desc)
  const rank = (id: string) => id === g.selectedKeyOwnerId ? 0 : g.partyIds.includes(id) ? 1 : 2
  const roster = [...g.members].sort((a, b) => rank(a.id) - rank(b.id) || b.ilvl - a.ilvl)

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
              <table className="runs">
                <thead>
                  <tr>
                    <th style={{ width: 40 }}></th>
                    <th>Key</th>
                    <th>Affixes</th>
                    <th>Owner</th>
                    <th className="r">Lvl</th>
                  </tr>
                </thead>
                <tbody>
                  {keys.map((k) => {
                    const info = mc(k.spec)
                    const sel = k.ownerId === g.selectedKeyOwnerId
                    const active = activeAffixIds(weekAffixes.map((a) => a.id), k.level)
                    return (
                      <tr key={k.ownerId} data-key-row onClick={() => g.selectKey(k.ownerId)}
                        style={{ cursor: "pointer", background: sel ? "rgba(43,182,164,.08)" : undefined, boxShadow: sel ? "inset 2px 0 0 var(--accent)" : undefined }}>
                        <td><GameIcon kind="dungeon" id={k.dungeonId} size={26} label={`${k.dungeon} Keystone`} /></td>
                        <td>
                          <Tip accent={qualityColor("Epic")} tip={<KeyTip name={k.dungeon} level={k.level} timer={k.timer} best={k.best} affixes={weekAffixes} />}>
                            <span style={{ color: qualityColor("Epic"), fontWeight: 700, fontSize: 13.5, cursor: "help" }}>{k.dungeon} Keystone</span>
                          </Tip>
                        </td>
                        <td>
                          {weekAffixes.length ? (
                            <span style={{ display: "inline-flex", gap: 3 }}>
                              {weekAffixes.map((a) => <GameIcon key={a.id} kind="affix" id={a.id} size={16} label={a.name} style={{ opacity: active.includes(a.id) ? 1 : .28 }} />)}
                            </span>
                          ) : <span style={{ color: "var(--faint)", fontSize: 11.5 }}>—</span>}
                        </td>
                        <td>
                          <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                            <span style={{ width: 22, height: 22, borderRadius: "var(--radius)", background: "var(--panel-3)", border: `1.5px solid ${info.color}`, display: "inline-flex", alignItems: "center", justifyContent: "center", flex: "none" }}><GameIcon kind="spec" id={k.spec} size={18} color={info.color} label={`${info.subspec} ${info.klass}`} /></span>
                            <span style={{ color: info.color, fontWeight: 700, fontSize: 13 }}>{k.ownerName}</span>
                          </div>
                        </td>
                        <td className="r mono" style={{ fontWeight: 700, fontSize: 15, color: sel ? "var(--amber)" : "var(--muted)" }}>+{k.level}</td>
                      </tr>
                    )
                  })}
                </tbody>
              </table>
              {weekAffixes.length && !activeAffixIds(weekAffixes.map((a) => a.id), g.keystone.level).length
                ? <div className="flux" style={{ fontSize: 11.5, color: "var(--faint)", padding: "8px 14px 12px" }}>Affixes unlock as the key climbs — none are live at this level yet.</div>
                : null}
            </Panel>
          </div>

          {/* party & tactics */}
          <div style={{ display: "flex", flexDirection: "column", gap: 18 }}>
            <Panel title="Party" right={<span className="mono" style={{ fontSize: 12, color: partyFull ? "var(--good)" : "var(--amber)" }}>{g.party.length}/5</span>} bodyStyle={{ padding: 10 }}>
              <div style={{ display: "flex", flexDirection: "column", maxHeight: 360, overflowY: "auto" }}>
                {roster.map((m) => {
                  const info = mc(m.spec)
                  const isOwner = m.id === g.selectedKeyOwnerId
                  const isIn = g.partyIds.includes(m.id)
                  const canToggle = !isOwner && (isIn || !partyFull)
                  return (
                    <div key={m.id} onClick={canToggle ? () => g.togglePartyMember(m.id) : undefined}
                      style={{ display: "flex", alignItems: "center", gap: 11, padding: "8px 8px", borderRadius: 8,
                        border: "1px solid " + (isIn ? "var(--line-soft)" : "transparent"),
                        background: isIn ? "rgba(43,182,164,.07)" : "transparent",
                        opacity: isIn ? 1 : (partyFull ? .45 : .8),
                        cursor: canToggle ? "pointer" : (isOwner ? "default" : "not-allowed"), marginBottom: 2 }}>
                      <span style={{ width: 30, height: 30, borderRadius: 7, background: info.color, display: "flex", alignItems: "center", justifyContent: "center", fontWeight: 700, color: "#0c0d11", fontSize: 14, flex: "none" }}>{m.name[0]}</span>
                      <div style={{ flex: 1, minWidth: 0 }}>
                        <div style={{ color: info.color, fontWeight: 700, fontSize: 14 }}>{m.name}{isOwner ? <span title="Key holder — locked into the party" style={{ marginLeft: 7, fontSize: 11, color: "var(--amber)" }}>★ key</span> : null}</div>
                        <div style={{ color: "var(--faint)", fontSize: 12 }}>{info.subspec} {info.klass}</div>
                      </div>
                      <RolePill role={info.role} iconOnly />
                      <span className="mono" style={{ fontSize: 13, color: qualityColor(rarityForIlvl(m.ilvl)), width: 34, textAlign: "right" }}>{m.ilvl}</span>
                      <Tip tip={<TipBody title="Morale" desc={MORALE_TIP} />}>
                        <span className="mono" style={{ fontSize: 11.5, color: moraleColor(m.morale), width: 40, textAlign: "right", cursor: "help" }}>{m.morale}%</span>
                      </Tip>
                      <span className="mono" style={{ fontSize: 11, width: 44, textAlign: "right", color: isOwner ? "var(--amber)" : isIn ? "var(--accent)" : partyFull ? "var(--faint)" : "var(--muted)" }}>
                        {isOwner ? "locked" : isIn ? "✓ in" : partyFull ? "full" : "+ add"}
                      </span>
                    </div>
                  )
                })}
              </div>
              {!partyFull ? <div className="flux" style={{ fontSize: 12.5, padding: "8px 6px 2px", color: "var(--danger)" }}>Pick {5 - g.party.length} more — click reserves below to add them.</div> : null}
            </Panel>

            <Panel title="Aggression" bodyStyle={{ padding: 18 }}>
              <div className="seg-group" style={{ width: "100%" }}>
                {AGGRO.map((a) => (
                  <button key={a.id} className={"seg-btn" + (aggression === a.id ? " on accent" : "")} style={{ flex: 1 }} onClick={() => setAggression(a.id)}>{a.name}</button>
                ))}
              </div>
              <p className="flux" style={{ fontSize: 13, marginTop: 10 }}>{AGGRO.find((a) => a.id === aggression)!.desc}</p>
              {/* live math, pulled from tuning so the numbers can never drift from the engine */}
              {(() => {
                const a = content.tuning.aggression[aggression]
                const dc = (content.tuning.hitQuality.dialCrit as Record<string, number>)[aggression] ?? 0
                const out = Math.round((a.output - 1) * 100), intake = Math.round((a.avoidableIntake - 1) * 100), crit = Math.round(dc * 100)
                const sign = (n: number) => (n > 0 ? "+" : "") + n
                const parts = [`${sign(out)}% party output`, `${sign(intake)}% avoidable damage taken`]
                if (crit !== 0) parts.push(`${sign(crit)}% crit`)
                const neutral = out === 0 && intake === 0 && crit === 0
                return <div className="mono" style={{ fontSize: 12, marginTop: 8, color: "var(--muted)" }}>{neutral ? "Baseline — no modifiers." : parts.join("  ·  ")}</div>
              })()}
            </Panel>

            <Panel title="Tactics" right={<span className="mono" style={{ fontSize: 12, color: left === 0 ? "var(--good)" : "var(--amber)" }}>{left} of {TOTAL_POINTS} left</span>} bodyStyle={{ padding: 14 }}>
              <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
                {TACTICS.map((t) => (
                  <div key={t.id} style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 12 }}>
                    <div style={{ display: "flex", alignItems: "center", gap: 10, minWidth: 0 }}>
                      <GameIcon kind="tactic" id={t.id} size={20} color="var(--muted)" label={t.name} />
                      <div style={{ minWidth: 0 }}>
                        <div style={{ fontWeight: 600, fontSize: 14 }}>{t.name}</div>
                        <div className="flux" style={{ fontSize: 12 }}>{t.perPoint}</div>
                      </div>
                    </div>
                    <div className="stepper" style={{ flex: "none" }}>
                      <button disabled={(tactics[t.id] || 0) <= 0} onClick={() => setTactic(t.id, -1)}>−</button>
                      <span className="v" style={{ minWidth: 32, fontSize: 15 }}>{tactics[t.id] || 0}</span>
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
