/* Step 5 — Loot Distribution: master-loot the real drops, or scrap for shards. */
import { useState } from "react"
import { content } from "@/content"
import { useGame, LOOT_SNUB_GAP, LOOT_SCRAP_MIN } from "@/state/game-store"
import { mc, qualityColor } from "../analytics"
import { Tip, ItemTip, ItemIcon } from "../components"
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
          <div style={{ display: "flex", gap: 12, alignItems: "center" }}>
            <button className="btn btn-sm btn-ghost" title="Assign every drop to its best-fit upgrade (then reconsider any contested ones)"
              onClick={() => setAssign(Object.fromEntries(drops.map((d) => [d.uid, d.upgradeFor ?? "scrap"])))}>Auto best-fit</button>
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
            const upgraders = it.upgrades.filter((u) => u.delta > 0)          // M.2: who would this actually upgrade
            const contested = upgraders.length >= 2
            const bestFit = upgraders.reduce((b, u) => (!b || u.delta > b.delta ? u : b), null as (typeof upgraders)[number] | null)
            // the SNUB the current choice would cause (passed-over bigger claim, or a scrapped real upgrade) — drama only here
            const winnerDelta = assignedMember ? (upgraders.find((u) => u.memberId === assignedMember.id)?.delta ?? 0) : 0
            const snubbed = choice === "scrap"
              ? upgraders.filter((u) => u.delta >= LOOT_SCRAP_MIN)
              : assignedMember ? upgraders.filter((u) => u.memberId !== assignedMember.id && u.delta - winnerDelta >= LOOT_SNUB_GAP) : []
            const snubNames = snubbed.map((u) => party.find((p) => p.id === u.memberId)?.name).filter(Boolean).join(", ")
            return (
              <div key={it.uid} className="panel" style={{ padding: 0, overflow: "hidden", borderColor: choice ? (choice === "scrap" ? "var(--line)" : "var(--accent)") : "var(--line)", opacity: choice === "scrap" ? .7 : 1 }}>
                <div style={{ display: "flex", alignItems: "stretch" }}>
                  <div style={{ display: "flex", alignItems: "center", gap: 14, padding: "16px 18px", flex: "0 0 360px", borderRight: "1px solid var(--line-soft)", background: `${qColor}10` }}>
                    <Tip accent={qColor} tip={<ItemTip item={it} />}><span style={{ cursor: "help", display: "inline-flex" }}><ItemIcon item={it} size={50} /></span></Tip>
                    <div>
                      <Tip accent={qColor} tip={<ItemTip item={it} />}><span style={{ color: qColor, fontWeight: 700, fontSize: 16, cursor: "help" }}>{it.name}</span></Tip>
                      <div style={{ color: "var(--faint)", fontSize: 12.5, marginTop: 2 }}>{slotName} · {it.primaryStat}</div>
                      <div style={{ display: "flex", gap: 8, marginTop: 6, alignItems: "center" }}>
                        <span className="mono" style={{ fontSize: 13, fontWeight: 700, color: qColor }}>ilvl {it.ilvl}</span>
                        <span className="chip" style={{ fontSize: 10.5 }}>{it.rarity}</span>
                        {contested ? <span className="chip" style={{ fontSize: 10.5 }} title="More than one member can use this — awarding to the best fit costs nothing.">Wanted ×{upgraders.length}</span> : null}
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
                          {snubbed.length ? <span style={{ color: "var(--amber)" }}> ⚠ {snubNames} lose{snubbed.length === 1 ? "s" : ""} morale — {choice === "scrap" ? "a real upgrade was scrapped" : "passed over for a bigger upgrade"}.</span> : null}
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
                            const isBest = contested && bestFit?.memberId === p.id   // the no-drama choice
                            return (
                              <button key={p.id} className="btn btn-sm" onClick={() => setAssign((a) => ({ ...a, [it.uid]: p.id }))}
                                style={{ flexDirection: "column", alignItems: "flex-start", gap: 1, borderColor: isUp ? "var(--good)" : "var(--line)", padding: "6px 11px" }}>
                                <span style={{ color: mc(p.spec).color, fontWeight: 700, display: "flex", alignItems: "center", gap: 4 }}>
                                  {p.name}{isUp ? <span style={{ color: "var(--good)" }}>▲</span> : null}
                                  {isBest ? <span style={{ color: "var(--faint)", fontWeight: 700, fontSize: 9, letterSpacing: ".06em", border: "1px solid var(--line)", borderRadius: "var(--radius)", padding: "0 4px" }}>BEST FIT</span> : null}
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
                        {contested && bestFit ? (
                          <div style={{ marginTop: 9, fontSize: 11.5, color: "var(--faint)" }}>
                            {upgraders.length} can use this — <b style={{ color: "var(--good)" }}>best fit {party.find((p) => p.id === bestFit.memberId)?.name} (+{bestFit.delta})</b>. Awarding the best fit costs nothing; passing them over (or scrapping a real upgrade) upsets the snubbed member.
                          </div>
                        ) : null}
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
