import { useState } from "react"
import { Icon, Portrait, Pips, GiltHeading, AffixChip } from "@/components/kit"
import { Button } from "@/components/ui/warcraftcn/button"
import { Badge } from "@/components/ui/warcraftcn/badge"
import { SPECS, TACTIC_CATS, PROFILES } from "@/data/game"
import { useGame } from "@/state/game-store"
import type { Aggression } from "@/sim"
import type { View } from "@/components/TopBar"
import { cn } from "@/lib/utils"

const TOTAL_POINTS = 6
const AGGRO = [
  { id: "Safe", note: "−10% output · −30% damage taken", tint: "#3f7d3a" },
  { id: "Balanced", note: "baseline", tint: "#c79a3f" },
  { id: "Yolo", note: "+15% output · +40% damage taken", tint: "#9a3322" },
] as const

export function RunSetup({ setView }: { setView: (v: View) => void }) {
  const { members, partyIds, togglePartyMember, weekAffixes, keystone, runKey } = useGame()
  const [pts, setPts] = useState<Record<string, number>>({ interrupts: 2, positioning: 1, cooldowns: 1, killorder: 2 })
  const [aggro, setAggro] = useState<Aggression>("Balanced")
  const [profiles, setProfiles] = useState<Record<string, string>>({})

  const used = Object.values(pts).reduce((a, b) => a + b, 0)
  const remaining = TOTAL_POINTS - used
  const partyFull = partyIds.length === 5
  const affSet = new Set(weekAffixes.map((a) => a.id))

  const bump = (id: string, d: number) =>
    setPts((p) => {
      const next = Math.max(0, Math.min(3, p[id] + d))
      if (d > 0 && remaining <= 0) return p
      return { ...p, [id]: next }
    })

  const warnings: string[] = []
  if (pts.killorder === 0 && affSet.has("bursting")) warnings.push("Kill Order 0 on a Bursting week → mob deaths stack the DoT. This wipes.")
  if (pts.killorder === 0 && affSet.has("bolstering")) warnings.push("Kill Order 0 on Bolstering → survivors snowball out of control.")
  if (pts.interrupts === 0) warnings.push("Interrupts 0 → Embalmer Vesk's Preserving Fume lands on the party.")
  if (pts.positioning === 0 && (affSet.has("volcanic") || affSet.has("sanguine"))) warnings.push("Positioning 0 → avoidable damage / the pack heals in pools.")
  if (pts.cooldowns === 0 && affSet.has("raging")) warnings.push("Cooldowns 0 on Raging → the enrage spike goes unmitigated.")
  if (aggro === "Yolo") warnings.push("Yolo dial: +40% avoidable damage taken. Riskier, faster.")

  const launch = () => { if (partyFull) { runKey({ tactics: pts, aggression: aggro }); setView("replay") } }

  return (
    <div className="flex h-full gap-4 p-4">
      {/* party picker */}
      <aside className="flex w-[250px] shrink-0 flex-col">
        <GiltHeading sub="Pick five. Click to add or bench.">The Party · {partyIds.length}/5</GiltHeading>
        <div className="flex min-h-0 flex-1 flex-col gap-1.5 overflow-auto scroll-thin pr-1">
          {members.map((m) => {
            const spec = SPECS[m.spec]
            const picked = partyIds.includes(m.id)
            return (
              <div key={m.id}
                   className="gilt-frame rounded-[5px] p-2 transition-all"
                   style={{
                     background: picked ? "linear-gradient(180deg, #f4e9c5, #e6d09a)" : "linear-gradient(180deg, #e7d6ab, #d8c089)",
                     opacity: picked ? 1 : 0.72,
                     boxShadow: picked ? "0 0 0 1px #c79a3f, inset 0 0 12px rgba(201,154,63,0.18)" : undefined,
                   }}>
                <button onClick={() => togglePartyMember(m.id)} className="flex w-full items-center gap-2.5 text-left">
                  <Portrait src={m.portrait} size={40} />
                  <div className="min-w-0 flex-1">
                    <div className="heading truncate text-[12px] font-bold text-engraved">{m.name}</div>
                    <div className="flex items-center gap-1 text-[10px]" style={{ color: "#6b5230" }}>
                      <Icon name={spec.icon} size={12} style={{ color: "#6b4a1d" }} />
                      {spec.name} · ilvl {m.ilvl}
                    </div>
                  </div>
                  <Icon name={picked ? "role-tank" : "ico-key"} size={14}
                        style={{ color: picked ? "#3f7d3a" : "#9a8a63", opacity: picked ? 1 : 0.5 }} />
                </button>
                {picked && (
                  <select
                    value={profiles[m.id] ?? (spec.role === "Healer" ? "Peel" : "Executioner")}
                    onChange={(e) => setProfiles((p) => ({ ...p, [m.id]: e.target.value }))}
                    className="heading mt-1.5 w-full rounded-[3px] px-1 py-0.5 text-[10px] outline-none"
                    style={{ background: "rgba(42,28,14,0.10)", border: "1px solid #6f532066", color: "#3a2a16" }}
                  >
                    {PROFILES.map((p) => <option key={p} value={p}>{p}</option>)}
                  </select>
                )}
              </div>
            )
          })}
        </div>
      </aside>

      {/* tactics */}
      <main className="flex min-w-0 flex-1 flex-col">
        <GiltHeading sub="Two minutes to set. No right answer — only right for this week.">Tactics</GiltHeading>

        <div className="mb-4">
          <div className="heading mb-1.5 text-[11px] uppercase tracking-widest" style={{ color: "#8c6a26" }}>Aggression Dial</div>
          <div className="grid grid-cols-3 gap-2">
            {AGGRO.map((a) => (
              <button key={a.id} onClick={() => setAggro(a.id)}
                className={cn("gilt-frame rounded-[5px] px-3 py-2 text-left transition-all")}
                style={{
                  background: aggro === a.id ? `linear-gradient(180deg, ${a.tint}33, ${a.tint}18)` : "linear-gradient(180deg, #ecdcb3, #dcc590)",
                  borderColor: aggro === a.id ? a.tint : undefined,
                  boxShadow: aggro === a.id ? `0 0 0 1px ${a.tint}, inset 0 0 14px ${a.tint}22` : undefined,
                }}>
                <div className="display text-[15px] font-bold" style={{ color: aggro === a.id ? a.tint : "#3a2a16" }}>{a.id}</div>
                <div className="text-[10px]" style={{ color: "#6b5230" }}>{a.note}</div>
              </button>
            ))}
          </div>
        </div>

        <div className="mb-2 flex items-center justify-between">
          <div className="heading text-[11px] uppercase tracking-widest" style={{ color: "#8c6a26" }}>Tactics Points</div>
          <Badge variant={remaining === 0 ? "secondary" : "default"} size="sm">{remaining} / {TOTAL_POINTS} unspent</Badge>
        </div>
        <div className="grid grid-cols-2 gap-2.5">
          {TACTIC_CATS.map((c) => (
            <div key={c.id} className="gilt-frame rounded-[5px] p-2.5" style={{ background: "linear-gradient(180deg, #f1e4c0, #e2cd99)" }}>
              <div className="flex items-center gap-2">
                <Icon name={c.icon} size={20} style={{ color: "#6b4a1d" }} />
                <div className="heading text-[13px] font-bold text-engraved">{c.name}</div>
                <div className="ml-auto flex items-center gap-1.5">
                  <button onClick={() => bump(c.id, -1)} className="dial-btn">−</button>
                  <Pips value={pts[c.id]} />
                  <button onClick={() => bump(c.id, +1)} className="dial-btn">＋</button>
                </div>
              </div>
              <div className="mt-1.5 text-[10px] italic" style={{ color: pts[c.id] === 0 ? "#9a3322" : "#6b5230" }}>
                {pts[c.id] === 0 ? `Starved → ${c.starved}` : `Allocated ${pts[c.id]} / 3`}
              </div>
            </div>
          ))}
        </div>

        <style>{`.dial-btn{font-family:var(--font-heading);width:22px;height:22px;border-radius:4px;
          border:1px solid #6f5320;background:linear-gradient(#3a2a18,#221608);color:#e6c163;
          font-size:14px;line-height:1;display:grid;place-items:center;}
          .dial-btn:hover{filter:brightness(1.2)}`}</style>
      </main>

      {/* key + run */}
      <aside className="flex w-[280px] shrink-0 flex-col">
        <GiltHeading sub={`${keystone.dungeon} +${keystone.level}`}>The Key</GiltHeading>
        <div className="flex flex-col gap-2">
          {weekAffixes.map((a) => <AffixChip key={a.name} affix={a} big />)}
        </div>

        <div className="mt-3 gilt-frame rounded-[5px] p-2.5" style={{ background: "linear-gradient(180deg, #f3e3b9, #e6cf95)" }}>
          <div className="heading mb-1 flex items-center gap-1.5 text-[11px] uppercase tracking-widest" style={{ color: "#9a3322" }}>
            <Icon name="ico-skull" size={14} /> What will go wrong
          </div>
          {warnings.length === 0 ? (
            <p className="text-[11px] italic" style={{ color: "#3f7d3a" }}>Nothing obvious. The log will find something.</p>
          ) : (
            <ul className="flex flex-col gap-1.5">
              {warnings.map((w, i) => <li key={i} className="text-[11px] leading-snug" style={{ color: "#5b3a1e" }}>• {w}</li>)}
            </ul>
          )}
        </div>

        <div className="mt-auto">
          <Button variant="frame" className="w-full !py-3 text-[14px] uppercase tracking-wide"
                  disabled={!partyFull} style={{ opacity: partyFull ? 1 : 0.5 }} onClick={launch}>
            <Icon name="ico-timer" size={17} /> {partyFull ? "Run Dungeon" : `Pick ${5 - partyIds.length} more`}
          </Button>
          <p className="mt-1.5 text-center text-[10px] italic" style={{ color: "#6b5230" }}>
            You don't play it. You watch it. Then you file the report.
          </p>
        </div>
      </aside>
    </div>
  )
}
