/* Step 1 — Guild Creation (onboarding). */
import { useState } from "react"
import { useGame } from "@/state/game-store"
import { Panel } from "../components"

const CRESTS = ["#2bb6a4", "#f0a52e", "#a98ce0", "#e0626b", "#56a8ff", "#4ec77b", "#c41f3b", "#e5cc80"]
const CREST_GLYPHS = ["⚔", "☠", "✦", "❖", "⛨", "✷", "✪", "♆"]

export function GuildCreatePage() {
  const game = useGame()
  const [name, setName] = useState("")
  const [crest, setCrest] = useState(CRESTS[0])
  const [glyph, setGlyph] = useState(CREST_GLYPHS[0])
  const [motto, setMotto] = useState("")

  const valid = name.trim().length >= 3

  return (
    <div className="page-scroll" style={{ display: "flex", alignItems: "flex-start", justifyContent: "center" }}>
      <div style={{ width: "100%", maxWidth: 940, padding: "40px 24px 48px" }}>
        <div style={{ textAlign: "center", marginBottom: 30 }}>
          <div className="eyebrow" style={{ color: "var(--accent)" }}>Step 1 · Found your guild</div>
          <div style={{ fontSize: 34, fontWeight: 700, marginTop: 8, letterSpacing: "-.01em" }}>Establish a Mythic+ Guild</div>
          <div className="flux" style={{ fontSize: 15, marginTop: 8, maxWidth: 560, margin: "8px auto 0" }}>
            Name your banner and choose a crest. You'll draft your first five players next.
          </div>
        </div>

        <div style={{ display: "grid", gridTemplateColumns: "320px 1fr", gap: 22, alignItems: "start" }}>
          {/* live crest preview */}
          <div className="panel" style={{ padding: 24, position: "sticky", top: 20, textAlign: "center", background: "var(--panel)" }}>
            <div className="eyebrow" style={{ marginBottom: 16 }}>Preview</div>
            <div style={{ width: 132, height: 132, margin: "0 auto", borderRadius: 24, background: crest, display: "flex", alignItems: "center", justifyContent: "center", boxShadow: "inset 0 2px 0 rgba(255,255,255,.18)", border: `2px solid ${crest}` }}>
              <span style={{ fontSize: 64, color: "#0c0d11", lineHeight: 1 }}>{glyph}</span>
            </div>
            <div style={{ fontSize: 22, fontWeight: 700, marginTop: 18, color: crest, minHeight: 28 }}>{name.trim() ? "<" + name.trim() + ">" : "<Your Guild>"}</div>
            {motto.trim() ? <div className="flux" style={{ fontSize: 13, marginTop: 12, fontStyle: "italic" }}>“{motto.trim()}”</div> : null}
          </div>

          {/* form */}
          <div style={{ display: "flex", flexDirection: "column", gap: 18 }}>
            <Panel title="Guild Name" bodyStyle={{ padding: 16 }}>
              <input className="field" value={name} maxLength={28} onChange={(e) => setName(e.target.value)} placeholder="e.g. Greatest of All Time" autoFocus />
              <div className="flux" style={{ fontSize: 12, marginTop: 7 }}>{name.trim().length < 3 ? "At least 3 characters." : "Looks good. This is how you'll appear on the ladder."}</div>
            </Panel>

            <Panel title="Crest" bodyStyle={{ padding: 16 }}>
              <div className="eyebrow" style={{ fontSize: 10, marginBottom: 8 }}>Color</div>
              <div style={{ display: "flex", gap: 9, flexWrap: "wrap", marginBottom: 16 }}>
                {CRESTS.map((c) => (
                  <button key={c} onClick={() => setCrest(c)} style={{ width: 34, height: 34, borderRadius: "var(--radius)", background: c, cursor: "pointer", border: crest === c ? "2px solid #fff" : "2px solid transparent" }} />
                ))}
              </div>
              <div className="eyebrow" style={{ fontSize: 10, marginBottom: 8 }}>Emblem</div>
              <div style={{ display: "flex", gap: 9, flexWrap: "wrap" }}>
                {CREST_GLYPHS.map((gl) => (
                  <button key={gl} onClick={() => setGlyph(gl)} style={{ width: 38, height: 38, borderRadius: 9, background: glyph === gl ? crest + "22" : "var(--panel-2)", border: glyph === gl ? `2px solid ${crest}` : "1px solid var(--line)", cursor: "pointer", fontSize: 20, color: glyph === gl ? crest : "var(--muted)" }}>{gl}</button>
                ))}
              </div>
            </Panel>

            <Panel title="Guild Motto" right={<span className="chip" style={{ color: "var(--faint)" }}>optional</span>} bodyStyle={{ padding: 16 }}>
              <input className="field" value={motto} maxLength={48} onChange={(e) => setMotto(e.target.value)} placeholder="e.g. Time it or scrap it." />
            </Panel>

            <button className="btn btn-primary" style={{ justifyContent: "center", padding: 14, fontSize: 15, opacity: valid ? 1 : .5, pointerEvents: valid ? "auto" : "none" }}
              onClick={() => game.createGuild({ name: name.trim(), crest, glyph, motto: motto.trim() })}>
              Found Guild → Draft Players
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
