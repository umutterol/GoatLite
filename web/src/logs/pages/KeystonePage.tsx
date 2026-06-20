/* Step 6 — New Keystone reveal: M+ progression after a run. */
import { useEffect, useState } from "react"
import { useGame } from "@/state/game-store"
import { Icon } from "../components"
import type { Go } from "../LogsApp"

export function KeystonePage({ go }: { go: Go }) {
  const g = useGame()
  const k = g.lastKeystoneChange
  const [revealed, setRevealed] = useState(false)

  useEffect(() => {
    const id = setTimeout(() => setRevealed(true), 450)
    return () => clearTimeout(id)
  }, [])

  if (!k) {
    return (
      <div className="page-scroll" style={{ display: "flex", alignItems: "center", justifyContent: "center" }}>
        <div style={{ textAlign: "center", padding: 40 }}>
          <div style={{ fontSize: 20, fontWeight: 700 }}>No recent run</div>
          <div className="flux" style={{ fontSize: 14, marginTop: 8 }}>Finish a key to recalibrate your keystone.</div>
          <button className="btn btn-primary" style={{ marginTop: 18, padding: "11px 22px" }} onClick={() => go("setup")}>Plan a Run</button>
        </div>
      </div>
    )
  }

  const up = k.upgrade
  const upLabel = up > 0 ? "+" + up + " Upgraded" : up < 0 ? up + " Depleted" : "Maintained"
  const upColor = up > 0 ? "var(--good)" : up < 0 ? "var(--danger)" : "var(--amber)"
  const timed = k.outcome === "timed"

  return (
    <div className="page-scroll" style={{ display: "flex", alignItems: "center", justifyContent: "center" }}>
      <div style={{ width: "100%", maxWidth: 760, padding: "40px 24px", textAlign: "center" }}>
        <div className="eyebrow" style={{ color: "var(--accent)" }}>Step 6 · Keystone</div>
        <div style={{ fontSize: 28, fontWeight: 700, marginTop: 8 }}>Your Keystone Recalibrated</div>

        {/* result of last run */}
        <div className="panel" style={{ padding: "16px 20px", marginTop: 22, display: "flex", alignItems: "center", justifyContent: "center", gap: 16, flexWrap: "wrap" }}>
          <Icon name="clock" size={16} color={timed ? "var(--good)" : "var(--danger)"} />
          <span style={{ fontSize: 15 }}>
            <b style={{ color: timed ? "var(--good)" : "var(--danger)" }}>{k.outcome.toUpperCase()}</b> {k.prevDungeon} <span className="mono" style={{ color: "var(--amber)" }}>+{k.prevLevel}</span> in <span className="mono">{k.prevTime}</span>
            <span style={{ color: "var(--faint)" }}> · {k.underBy >= 0 ? `${k.underBy}s under` : `${-k.underBy}s over`} {k.prevPar}</span>
          </span>
          <span style={{ fontWeight: 700, color: upColor, fontSize: 15 }}>{upLabel}</span>
        </div>

        {/* the keystone reveal */}
        <div style={{ marginTop: 24, perspective: 1000 }}>
          <div style={{ opacity: revealed ? 1 : 0, transform: revealed ? "translateY(0) scale(1)" : "translateY(16px) scale(.96)", transition: "all .55s cubic-bezier(.2,.8,.2,1)" }}>
            <div style={{ position: "relative", borderRadius: 18, overflow: "hidden", border: "1px solid var(--line)", background: "linear-gradient(160deg, #1c1f27, #131419)", boxShadow: "0 18px 50px rgba(0,0,0,.5)" }}>
              <div style={{ position: "absolute", inset: 0, background: "radial-gradient(120% 90% at 50% 0%, rgba(43,182,164,.22), transparent 60%)", opacity: revealed ? 1 : 0, transition: "opacity .8s ease .2s" }} />
              <div style={{ position: "relative", padding: "34px 30px 30px" }}>
                <div className="eyebrow" style={{ marginBottom: 10 }}>New Keystone</div>
                <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 18 }}>
                  <div style={{ width: 84, height: 84, borderRadius: 18, background: "linear-gradient(150deg, var(--accent), var(--accent-dim))", display: "flex", alignItems: "center", justifyContent: "center", flex: "none" }}>
                    <span className="mono" style={{ fontWeight: 700, fontSize: 16, color: "#04201d" }}>{k.dungeonShort}</span>
                  </div>
                  <div style={{ textAlign: "left" }}>
                    <div style={{ fontSize: 27, fontWeight: 700 }}>{k.dungeon}</div>
                    <div style={{ display: "flex", alignItems: "baseline", gap: 10, marginTop: 4 }}>
                      <span className="mono" style={{ fontSize: 40, fontWeight: 700, color: "var(--amber)", lineHeight: 1 }}>+{k.level}</span>
                      {up !== 0 ? <span className="mono" style={{ fontSize: 15, fontWeight: 700, color: upColor }}>({up > 0 ? "+" + up : up})</span> : null}
                    </div>
                  </div>
                </div>
                <div style={{ display: "flex", gap: 8, justifyContent: "center", marginTop: 20, flexWrap: "wrap" }}>
                  {k.affixes.map((a) => <span key={a} className="chip" style={{ fontSize: 12.5, padding: "5px 12px" }}>{a}</span>)}
                  <span className="chip" style={{ fontSize: 12.5, padding: "5px 12px", color: "var(--faint)" }}><Icon name="clock" size={12} color="var(--faint)" /> {k.timer} timer</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div className="flux" style={{ fontSize: 13, marginTop: 18, maxWidth: 520, margin: "18px auto 0" }}>
          {up >= 3 ? "Beat the timer by 40%+ — the key jumped three levels."
            : up === 2 ? "Beat the timer by 20%+ — the key climbed two levels."
              : up === 1 ? "Timed it — the key climbed a level."
                : k.level < k.prevLevel ? "Depleted — the key dropped a level. Time the next one to recover."
                  : "Depleted — but the key's already at the floor (+2). Gear up and try again."}{" "}
          A fresh set of weekly affixes is now in effect.
        </div>

        <div style={{ display: "flex", gap: 12, justifyContent: "center", marginTop: 26 }}>
          <button className="btn btn-primary" style={{ padding: "12px 26px", fontSize: 15 }} onClick={() => go("setup")}>
            <Icon name="setup" size={15} color="#04201d" /> Plan Next Run
          </button>
          <button className="btn btn-ghost" style={{ padding: "12px 22px", fontSize: 15 }} onClick={() => go("recruit")}>Visit Recruitment</button>
        </div>
      </div>
    </div>
  )
}
