import { useEffect, useState, type CSSProperties, type ReactNode } from "react"
import { cn } from "@/lib/utils"
import type { Rarity, Trait, Affix } from "@/data/game"
import { RARITY_CLASS } from "@/data/game"

/* ---- tintable icon (game-icons SVGs recoloured to currentColor via mask) ---- */
export function Icon({
  name, size = 20, className, style,
}: { name: string; size?: number; className?: string; style?: CSSProperties }) {
  const url = `/icons/${name}.svg`
  return (
    <span
      aria-hidden
      className={cn("inline-block shrink-0 align-middle", className)}
      style={{
        width: size, height: size, backgroundColor: "currentColor",
        WebkitMaskImage: `url(${url})`, maskImage: `url(${url})`,
        WebkitMaskRepeat: "no-repeat", maskRepeat: "no-repeat",
        WebkitMaskPosition: "center", maskPosition: "center",
        WebkitMaskSize: "contain", maskSize: "contain",
        ...style,
      }}
    />
  )
}

/* ---- 16:9 stage: fixed 1280x720 design, scaled to fit, letterboxed ---- */
export function Stage({ children }: { children: ReactNode }) {
  const [scale, setScale] = useState(1)
  useEffect(() => {
    const fit = () => setScale(Math.min(window.innerWidth / 1280, window.innerHeight / 720))
    fit()
    window.addEventListener("resize", fit)
    return () => window.removeEventListener("resize", fit)
  }, [])
  return (
    <div className="stage-viewport">
      <div className="stage" style={{ transform: `scale(${scale})` }}>{children}</div>
    </div>
  )
}

/* ---- gilt-framed portrait ---- */
export function Portrait({
  src, size = 64, className, ring,
}: { src: string; size?: number; className?: string; ring?: string }) {
  return (
    <div
      className={cn("relative shrink-0 overflow-hidden rounded-[3px] gilt-frame", className)}
      style={{ width: size, height: size, borderColor: ring }}
    >
      <img src={src} alt="" className="h-full w-full object-cover"
           style={{ objectPosition: "50% 22%" }} />
      <span className="pointer-events-none absolute inset-0"
            style={{ boxShadow: "inset 0 -14px 22px rgba(20,12,5,0.6), inset 0 0 0 1px rgba(231,193,99,0.35)" }} />
    </div>
  )
}

export function moraleBand(v: number) {
  if (v >= 90) return { label: "Inspired", color: "#3f7d3a" }
  if (v >= 50) return { label: "Steady", color: "#c79a3f" }
  if (v >= 30) return { label: "Shaken", color: "#b9742f" }
  return { label: "Breaking", color: "#9a3322" }
}

export function MoraleBar({ value, className }: { value: number; className?: string }) {
  const band = moraleBand(value)
  return (
    <div className={cn("w-full", className)}>
      <div className="flex items-center justify-between text-[10px] uppercase tracking-wider"
           style={{ color: "#5b4428" }}>
        <span className="heading">Morale</span>
        <span style={{ color: band.color }}>{value} · {band.label}</span>
      </div>
      <div className="mt-0.5 h-2 w-full overflow-hidden rounded-full"
           style={{ background: "rgba(42,28,14,0.35)", boxShadow: "inset 0 1px 2px rgba(0,0,0,0.5)" }}>
        <div className="h-full rounded-full transition-all"
             style={{ width: `${value}%`, background: `linear-gradient(90deg, ${band.color}aa, ${band.color})` }} />
      </div>
    </div>
  )
}

/* ---- tactics pip row ---- */
export function Pips({ value, max = 3 }: { value: number; max?: number }) {
  return (
    <div className="flex gap-1">
      {Array.from({ length: max }).map((_, i) => (
        <span key={i} className={cn("pip", i < value && "pip-on")} />
      ))}
    </div>
  )
}

export function GiltHeading({ children, sub, className }: { children: ReactNode; sub?: string; className?: string }) {
  return (
    <div className={cn("mb-2", className)}>
      <h2 className="heading text-engraved text-[15px] font-bold uppercase tracking-[0.18em]">{children}</h2>
      {sub && <p className="text-[11px] italic" style={{ color: "#6b5230" }}>{sub}</p>}
      <div className="gilt-rule mt-1" />
    </div>
  )
}

export function RarityText({ rarity, children }: { rarity: Rarity; children: ReactNode }) {
  return <span className={RARITY_CLASS[rarity]}>{children}</span>
}

export function TraitChip({ trait }: { trait: Trait }) {
  const dot: Record<string, string> = {
    Common: "#9a8a63", Uncommon: "#4caf3f", Rare: "#2f7fd6", Epic: "#a335ee", Legendary: "#e08a1e",
  }
  return (
    <span
      title={trait.effect}
      className="inline-flex items-center gap-1 rounded-[3px] border px-1.5 py-0.5 text-[10px] leading-none"
      style={{ borderColor: "rgba(74,52,28,0.5)", background: "rgba(42,28,14,0.08)", color: "#3a2a16" }}
    >
      <span className="h-2 w-2 rounded-full" style={{ background: dot[trait.rarity] }} />
      <span className="heading font-semibold">{trait.name}</span>
      {trait.kind === "Earned" && <Icon name="ico-trait" size={10} style={{ color: "#8c6a26" }} />}
    </span>
  )
}

export function AffixChip({ affix, big }: { affix: Affix; big?: boolean }) {
  return (
    <div className={cn(
      "flex items-center gap-2 rounded-[4px] border px-2 py-1",
      big && "px-2.5 py-1.5",
    )} style={{ borderColor: "rgba(140,106,38,0.6)", background: "rgba(42,28,14,0.10)" }}>
      <Icon name={affix.icon} size={big ? 22 : 16} style={{ color: affix.tier === 1 ? "#9a3322" : "#8c6a26" }} />
      <div className="leading-tight">
        <div className="heading font-bold text-engraved" style={{ fontSize: big ? 13 : 11 }}>{affix.name}</div>
        {big && <div className="text-[10px]" style={{ color: "#6b5230" }}>{affix.effect}</div>}
      </div>
    </div>
  )
}

/* ---- a parchment panel with a faint inner gild ---- */
export function Panel({ children, className, tone = "parchment" }: {
  children: ReactNode; className?: string; tone?: "parchment" | "leather"
}) {
  return (
    <div className={cn(tone, "gilt-frame rounded-[5px]", className)}>{children}</div>
  )
}
