import { Icon } from "@/components/kit"
import { Button } from "@/components/ui/warcraftcn/button"
import { cn } from "@/lib/utils"
import { useGame } from "@/state/game-store"

const ROMAN = ["0", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII"]

export type View = "guild" | "run" | "replay" | "char"

const NAV: { id: View; label: string; icon: string }[] = [
  { id: "guild", label: "Guild Hall", icon: "ico-trait" },
  { id: "run", label: "Key & Tactics", icon: "ico-key" },
  { id: "replay", label: "Replay", icon: "ico-timer" },
]

function Coin({ icon, value, tint }: { icon: string; value: number; tint: string }) {
  return (
    <div className="flex items-center gap-1.5">
      <Icon name={icon} size={20} style={{ color: tint }} />
      <span className="heading text-[15px] font-semibold" style={{ color: "#ecd9a6" }}>
        {value.toLocaleString()}
      </span>
    </div>
  )
}

export function TopBar({ view, setView }: { view: View; setView: (v: View) => void }) {
  const { wallet, weekAffixes, weekNumber } = useGame()
  return (
    <header className="leather relative z-20 flex h-[70px] items-center gap-5 px-5"
            style={{ borderBottom: "2px solid #6f5320", boxShadow: "0 3px 12px rgba(0,0,0,0.55)" }}>
      {/* crest + title */}
      <div className="flex items-center gap-3">
        <div className="grid h-11 w-11 place-items-center rounded-[4px] gilt-frame"
             style={{ background: "radial-gradient(circle at 40% 30%, #3a2a18, #160d06)" }}>
          <Icon name="ico-skull" size={26} style={{ color: "#c79a3f" }} />
        </div>
        <div className="leading-none">
          <div className="display text-[22px] font-black text-gilt">GOAT LITE</div>
          <div className="heading text-[10px] uppercase tracking-[0.34em]" style={{ color: "#9c7c45" }}>
            Mythic+ Manager · QA Build
          </div>
        </div>
      </div>

      <div className="mx-1 h-9 w-px" style={{ background: "linear-gradient(#0000,#6f532088,#0000)" }} />

      {/* week + affixes */}
      <div className="flex items-center gap-3">
        <div className="leading-tight">
          <div className="heading text-[10px] uppercase tracking-widest" style={{ color: "#9c7c45" }}>Beta Week</div>
          <div className="display text-[18px] font-bold text-gilt">{ROMAN[weekNumber] ?? weekNumber}</div>
        </div>
        <div className="flex items-center gap-1.5">
          {weekAffixes.map((a) => (
            <div key={a.name} title={`${a.name} — ${a.effect}`}
                 className="flex items-center gap-1.5 rounded-[4px] px-2 py-1"
                 style={{ background: "rgba(0,0,0,0.30)", border: "1px solid #6f532066" }}>
              <Icon name={a.icon} size={16} style={{ color: a.tier === 1 ? "#d18a5a" : "#d9b85e" }} />
              <span className="heading text-[11px] font-semibold" style={{ color: "#e6d4a8" }}>{a.name}</span>
            </div>
          ))}
        </div>
      </div>

      {/* currencies + nav */}
      <div className="ml-auto flex items-center gap-5">
        <div className="flex items-center gap-4 rounded-[5px] px-3 py-1.5"
             style={{ background: "rgba(0,0,0,0.28)", border: "1px solid #6f532066" }}>
          <Coin icon="cur-gold" value={wallet.gold} tint="#e6c163" />
          <Coin icon="cur-emblem" value={wallet.emblems} tint="#cf9a52" />
          <Coin icon="cur-shard" value={wallet.shards} tint="#7fc7d6" />
        </div>

        <nav className="flex items-center gap-1.5">
          {NAV.map((n) =>
            view === n.id ? (
              <Button key={n.id} variant="frame"
                      className="!px-3.5 !py-2 text-[12px] uppercase tracking-wide"
                      onClick={() => setView(n.id)}>
                <Icon name={n.icon} size={15} /> {n.label}
              </Button>
            ) : (
              <button key={n.id} onClick={() => setView(n.id)}
                className={cn("heading flex items-center gap-1.5 rounded-[4px] px-3.5 py-2 text-[12px] uppercase tracking-wide",
                  "transition-colors")}
                style={{ color: "#b89a63", border: "1px solid transparent" }}
                onMouseEnter={(e) => (e.currentTarget.style.color = "#ecd9a6")}
                onMouseLeave={(e) => (e.currentTarget.style.color = "#b89a63")}>
                <Icon name={n.icon} size={15} /> {n.label}
              </button>
            )
          )}
        </nav>
      </div>
    </header>
  )
}
