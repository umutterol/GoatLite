/* Scouting-board talents (finding #4): a one-row strip of a spec's selected default talents + a "Talents" button
   that opens a popup showing the full 5-tier × 3-option grid (hover = name + effect). Read-only — recruits show
   the spec's DEFAULT build (the same defaults resolveTalents() falls back to). Talent art (/icons/talent-{id}.png)
   doesn't exist yet, so TalentIcon degrades to a styled tier-numbered tile (not the bear) and auto-upgrades when a
   PNG is dropped in. The popup portals into the scaled stage so it sizes with the 16:9 canvas. */
import { useMemo, useState, type CSSProperties } from "react"
import { createPortal } from "react-dom"
import { content } from "@/content"
import { mc } from "./analytics"
import { Tip, TipBody, Panel } from "./components"
import { useStage } from "./ViewportStage"

type TalentOption = { id: string; name: string; effect: string; default?: boolean }
type TalentNode = { id: string; node: number; specId?: string; name: string; options: TalentOption[] }

/** A talent tile: the painted PNG if present, else the app's default icon art (like every GameIcon) — so talents
    "use fallback icons" until /icons/talent-{id}.png is dropped in. Selected = accent ring; a small tier badge keeps
    the tier readable at a glance. */
function TalentIcon({ opt, tier, on, size = 38 }: { opt: TalentOption; tier: number; on?: boolean; size?: number }) {
  const ring = on ? "var(--accent)" : "var(--line)"
  return (
    <span style={{
      position: "relative", width: size, height: size, flex: "none", borderRadius: "var(--radius)",
      border: `${on ? 2 : 1.5}px solid ${ring}`, background: "var(--panel-3)", display: "inline-flex",
      alignItems: "center", justifyContent: "center", overflow: "hidden",
      boxShadow: on ? "0 0 0 2px rgba(43,182,164,.18)" : undefined,
    }}>
      <img key={opt.id} src={`/icons/talent-${opt.id}.png`} width={size - 3} height={size - 3} alt=""
        onError={(e) => { const t = e.currentTarget; if (!t.src.endsWith("/icons/icon-default.png")) t.src = "/icons/icon-default.png" }}
        style={{ objectFit: "cover", borderRadius: "var(--radius)" }} />
      <span style={{ position: "absolute", bottom: -1, right: 1, fontSize: Math.max(8, Math.round(size * 0.26)), fontWeight: 700, lineHeight: 1, color: on ? "var(--accent)" : "var(--faint)", textShadow: "0 0 3px #000, 0 0 3px #000" }}>{tier}</span>
    </span>
  )
}

function nodesFor(specId: string): TalentNode[] {
  return ([...content.talents.values()] as TalentNode[])
    .filter((n) => n.specId === specId)
    .sort((a, b) => a.node - b.node)
}
const defaultOpt = (n: TalentNode, chosen?: Record<string, string>): TalentOption =>
  n.options.find((o) => o.id === chosen?.[n.id]) ?? n.options.find((o) => o.default) ?? n.options[0]

/** The full 5×3 talent grid, portaled into the scaled stage as a click-dismiss modal. Read-only unless `onPick` is
    passed (then cells are clickable to set the build, e.g. on the Character sheet). */
function TalentPopup({ specId, nodes, chosen, onClose, onPick }: { specId: string; nodes: TalentNode[]; chosen?: Record<string, string>; onClose: () => void; onPick?: (nodeId: string, optionId: string) => void }) {
  const { el } = useStage()
  const info = mc(specId)
  const cell: CSSProperties = { display: "flex", flexDirection: "column", alignItems: "center", gap: 6, padding: "10px 6px", borderRadius: "var(--radius)", textAlign: "center" }
  const modal = (
    <div onClick={onClose} style={{ position: "fixed", inset: 0, zIndex: 1000, background: "rgba(0,0,0,.62)", display: "flex", alignItems: "center", justifyContent: "center", padding: 24 }}>
      <div onClick={(e) => e.stopPropagation()} style={{ width: 580, maxWidth: "94%", maxHeight: "88%", overflowY: "auto", background: "var(--panel)", border: "1px solid var(--line)", borderRadius: "var(--radius)", boxShadow: "0 24px 70px rgba(0,0,0,.6)" }}>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "14px 18px", borderBottom: "1px solid var(--line-soft)", background: `${info.color}1f` }}>
          <div><span className="eyebrow" style={{ fontSize: 10, color: "var(--faint)" }}>Talents</span><div style={{ color: info.color, fontWeight: 700, fontSize: 16 }}>{info.subspec} {info.klass}</div></div>
          <button className="btn btn-sm btn-ghost" onClick={onClose}>✕ Close</button>
        </div>
        <div style={{ padding: 16 }}>
          {nodes.map((n) => {
            const cur = defaultOpt(n, chosen).id
            return (
              <div key={n.id} style={{ marginBottom: 14 }}>
                <div className="eyebrow" style={{ fontSize: 9.5, marginBottom: 7 }}>Tier {n.node} · {n.name}</div>
                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 8 }}>
                  {n.options.map((o) => {
                    const on = o.id === cur
                    return (
                      <Tip key={o.id} accent={on ? "var(--accent)" : undefined} tip={<TipBody title={o.name} desc={o.effect} accent={on ? "var(--accent)" : undefined} />}>
                        <div data-talent-cell onClick={onPick ? () => onPick(n.id, o.id) : undefined} style={{ ...cell, border: on ? "1px solid var(--accent)" : "1px solid var(--line-soft)", background: on ? "rgba(43,182,164,.08)" : "transparent", cursor: onPick ? "pointer" : "help" }}>
                          <TalentIcon opt={o} tier={n.node} on={on} size={40} />
                          <span style={{ fontSize: 11.5, fontWeight: 600, lineHeight: 1.25, color: on ? "var(--text)" : "var(--muted)" }}>{o.name}</span>
                        </div>
                      </Tip>
                    )
                  })}
                </div>
              </div>
            )
          })}
          <div className="flux" style={{ fontSize: 11, color: "var(--faint)" }}>{onPick ? "Click an option to set this member's build — applied on the next run." : "Recruits show the spec's default build (highlighted). Builds are tuned per member after signing."}</div>
        </div>
      </div>
    </div>
  )
  return createPortal(modal, el ?? document.body)
}

/** A one-row strip of the spec's selected talents + a "Talents" button opening the full grid. Pass `chosen` to reflect
    a member's saved build (else spec defaults), `onPick` to make the popup editable (Character sheet), and `framed` to
    render inside a Panel (vs the bordered section used in the recruit scout panel). */
export function TalentStrip({ specId, chosen, onPick, framed }: { specId: string; chosen?: Record<string, string>; onPick?: (nodeId: string, optionId: string) => void; framed?: boolean }) {
  const [open, setOpen] = useState(false)
  const nodes = useMemo(() => nodesFor(specId), [specId])
  if (!nodes.length) return null
  const body = (
    <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 8 }}>
      <div style={{ display: "flex", gap: 6 }}>
        {nodes.map((n) => {
          const o = defaultOpt(n, chosen)
          return (
            <Tip key={n.id} tip={<TipBody title={o.name} desc={o.effect} />}>
              <span style={{ display: "inline-flex" }}><TalentIcon opt={o} tier={n.node} on /></span>
            </Tip>
          )
        })}
      </div>
      <button className="btn btn-sm btn-ghost" style={{ flex: "none" }} onClick={() => setOpen(true)}>Talents ▾</button>
    </div>
  )
  const popup = open ? <TalentPopup specId={specId} nodes={nodes} chosen={chosen} onPick={onPick} onClose={() => setOpen(false)} /> : null
  if (framed) return <Panel title="Talents" bodyStyle={{ padding: 14 }}>{body}{popup}</Panel>
  return (
    <div style={{ padding: "12px 16px", borderBottom: "1px solid var(--line-soft)" }}>
      <div className="eyebrow" style={{ fontSize: 10, marginBottom: 9 }}>Talents</div>
      {body}{popup}
    </div>
  )
}
