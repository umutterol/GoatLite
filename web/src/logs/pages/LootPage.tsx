/* Step 5 — Loot Distribution: master-loot the real drops, or scrap for shards. */
import { useState } from "react"
import { content } from "@/content"
import { useGame } from "@/state/game-store"
import { mc, qualityColor } from "../analytics"
import type { Go } from "../LogsApp"

const SHARDS_PER_SCRAP = 8

export function LootPage({ go }: { go: Go }) {
  const g = useGame()
  const drops = g.pendingLoot ?? []
  const party = g.party
  const [assign, setAssign] = useState<Record<string, string>>({})

  if (!drops.length) {
    return (
      <div className="page-scroll" style={{ display: "flex", alignItems: "center", justifyContent: "center" }}>
        <div style={{ textAlign: "center", padding: 40 }}>
          <div style={{ fontSize: 20, fontWeight: 700 }}>Nothing to distribute</div>
          <div className="flux" style={{ fontSize: 14, marginTop: 8 }}>The last run dropped no loot.</div>
          <button className="btn btn-primary" style={{ marginTop: 18, padding: "11px 22px" }} onClick={() => { g.confirmLoot({}); go("keystone") }}>Continue → Keystone</button>
        </div>
      </div>
    )
  }

  const done = drops.every((it) => assign[it.uid])
  const scrapped = drops.filter((it) => assign[it.uid] === "scrap").length
  const shardsGained = scrapped * SHARDS_PER_SCRAP
  const outcome = g.lastResult?.outcome ?? "timed"
  const emblems = outcome === "timed" ? 5 : outcome === "depleted" ? 2 : 0

  return (
    <div className="page-scroll" style={{ padding: 24 }}>
      <div style={{ maxWidth: 1100, margin: "0 auto" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-end", marginBottom: 18 }}>
          <div>
            <div className="eyebrow" style={{ color: "var(--accent)" }}>Step 5 · Spoils</div>
            <div style={{ fontSize: 26, fontWeight: 700, marginTop: 5 }}>Distribute Loot</div>
            <div className="flux" style={{ fontSize: 14, marginTop: 4 }}>{(g.lastRunKey ?? g.keystone).dungeon} +{(g.lastRunKey ?? g.keystone).level} · {outcome.toUpperCase()}. Assign each drop to a member, or scrap it for shards.</div>
          </div>
          <div style={{ display: "flex", gap: 12 }}>
            <div className="tile" style={{ textAlign: "center", minWidth: 96 }}><div className="lbl">Emblems</div><div className="val mono" style={{ color: "var(--amber)" }}>+{emblems}</div></div>
            <div className="tile" style={{ textAlign: "center", minWidth: 96 }}><div className="lbl">Shards</div><div className="val mono" style={{ color: shardsGained ? "var(--accent)" : "var(--faint)" }}>+{shardsGained}</div></div>
          </div>
        </div>

        <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
          {drops.map((it) => {
            const qColor = qualityColor(it.rarity)
            const slotName = content.itemSlots.get(it.slot)?.name ?? it.slot
            const choice = assign[it.uid]
            const assignedMember = choice && choice !== "scrap" ? party.find((p) => p.id === choice) : null
            const eligible = party.filter((p) => it.specs.includes(p.spec))
            return (
              <div key={it.uid} className="panel" style={{ padding: 0, overflow: "hidden", borderColor: choice ? (choice === "scrap" ? "var(--line)" : "var(--accent)") : "var(--line)", opacity: choice === "scrap" ? .7 : 1 }}>
                <div style={{ display: "flex", alignItems: "stretch" }}>
                  <div style={{ display: "flex", alignItems: "center", gap: 14, padding: "16px 18px", flex: "0 0 360px", borderRight: "1px solid var(--line-soft)", background: `linear-gradient(120deg, ${qColor}10, transparent)` }}>
                    <span style={{ width: 50, height: 50, flex: "none", borderRadius: 11, background: "linear-gradient(145deg,#23252e,#15161b)", border: `2px solid ${qColor}`, display: "flex", alignItems: "center", justifyContent: "center", fontFamily: "IBM Plex Mono, monospace", fontWeight: 700, fontSize: 17, color: qColor }}>{slotName[0]}</span>
                    <div>
                      <div style={{ color: qColor, fontWeight: 700, fontSize: 16 }}>{it.name}</div>
                      <div style={{ color: "var(--faint)", fontSize: 12.5, marginTop: 2 }}>{slotName} · {it.primaryStat}</div>
                      <div style={{ display: "flex", gap: 8, marginTop: 6, alignItems: "center" }}>
                        <span className="mono" style={{ fontSize: 13, fontWeight: 700, color: qColor }}>ilvl {it.ilvl}</span>
                        <span className="chip" style={{ fontSize: 10.5 }}>{it.rarity}</span>
                      </div>
                    </div>
                  </div>

                  <div style={{ flex: 1, padding: "14px 18px", display: "flex", flexDirection: "column", justifyContent: "center" }}>
                    {choice ? (
                      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
                        <div style={{ fontSize: 14 }}>
                          {choice === "scrap"
                            ? <span style={{ color: "var(--faint)" }}>Scrapped for <b style={{ color: "var(--accent)" }}>{SHARDS_PER_SCRAP} shards</b>.</span>
                            : assignedMember ? <span>Awarded to <b style={{ color: mc(assignedMember.spec).color }}>{assignedMember.name}</b>.</span> : null}
                        </div>
                        <button className="btn btn-sm btn-ghost" onClick={() => setAssign((a) => { const n = { ...a }; delete n[it.uid]; return n })}>Undo</button>
                      </div>
                    ) : (
                      <>
                        <div style={{ marginBottom: 9 }}>
                          <span className="eyebrow" style={{ fontSize: 10 }}>Award to <span style={{ letterSpacing: 0, textTransform: "none", fontWeight: 400, color: "var(--faint)" }}>— current → new ilvl</span></span>
                        </div>
                        <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
                          {eligible.length ? eligible.map((p) => {
                            const u = it.upgrades.find((x) => x.memberId === p.id)
                            const delta = u?.delta ?? 0
                            const isUp = delta > 0
                            return (
                              <button key={p.id} className="btn btn-sm" onClick={() => setAssign((a) => ({ ...a, [it.uid]: p.id }))}
                                style={{ flexDirection: "column", alignItems: "flex-start", gap: 1, borderColor: isUp ? "var(--good)" : "var(--line)", padding: "6px 11px" }}>
                                <span style={{ color: mc(p.spec).color, fontWeight: 700, display: "flex", alignItems: "center", gap: 4 }}>
                                  {p.name}{isUp ? <span style={{ color: "var(--good)" }}>▲</span> : null}
                                </span>
                                <span className="mono" style={{ fontSize: 10.5, color: isUp ? "var(--good)" : "var(--faint)" }}>
                                  {u?.currentIlvl ?? "—"} → {it.ilvl}{delta !== 0 ? ` (${delta > 0 ? "+" : ""}${delta})` : ""}
                                </span>
                              </button>
                            )
                          }) : <span className="flux" style={{ fontSize: 12.5 }}>No one in the party can use this.</span>}
                          <span style={{ width: 1, background: "var(--line)", margin: "0 2px" }} />
                          <button className="btn btn-sm btn-ghost" onClick={() => setAssign((a) => ({ ...a, [it.uid]: "scrap" }))} style={{ color: "var(--faint)" }}>Scrap ◈</button>
                        </div>
                      </>
                    )}
                  </div>
                </div>
              </div>
            )
          })}
        </div>

        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginTop: 22 }}>
          <span className="flux" style={{ fontSize: 13 }}>{Object.keys(assign).length} of {drops.length} drops resolved.</span>
          <button className="btn btn-primary" style={{ padding: "12px 24px", fontSize: 15, opacity: done ? 1 : .5, pointerEvents: done ? "auto" : "none" }} onClick={() => { g.confirmLoot(assign); go("keystone") }}>
            Confirm Distribution → New Keystone
          </button>
        </div>
      </div>
    </div>
  )
}
