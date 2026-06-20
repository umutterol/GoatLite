/* Phase F.5 — operator-skill UI primitives, shared by the recruit detail panel + the character sheet.
   Skill bars (current fill, ceiling shaded behind when revealed, else "?"), fuzzy Potential ★, COR color,
   and a scout-report blurb. Reads the operator registry/tuning via @/data/operator. */
import { content } from "@/content"
import { SCALE_MAX, xpPerPoint, type SkillMap, type RevealMap } from "@/data/operator"
import { Icon, GameIcon } from "./components"

const OP_SKILLS = [...content.operatorSkills.values()]

/** 0..100 Current Operator Rating → a WoW-quality-style color ramp. */
export const corColor = (c: number): string =>
  c >= 78 ? "#ff8000" : c >= 62 ? "#a335ee" : c >= 46 ? "#0070ff" : c >= 30 ? "#1eff00" : "#9d9d9d"

/** One partial star (fill 0..1) — a faint base star with an amber star clipped to `fill`. */
function Star({ fill, size = 14 }: { fill: number; size?: number }) {
  return (
    <span style={{ position: "relative", width: size, height: size, display: "inline-block", flex: "none" }}>
      <span style={{ position: "absolute", inset: 0 }}><Icon name="star" size={size} color="var(--line)" /></span>
      {fill > 0 ? <span style={{ position: "absolute", inset: 0, width: `${fill * 100}%`, overflow: "hidden" }}><Icon name="star" size={size} color="var(--amber)" /></span> : null}
    </span>
  )
}
/** Fuzzy Potential rating: 5 stars in half-steps (value 0..5). */
export function Stars({ value, size = 14 }: { value: number; size?: number }) {
  return (
    <span style={{ display: "inline-flex", gap: 2, alignItems: "center" }} title={`${value.toFixed(1)} / 5 potential`}>
      {[0, 1, 2, 3, 4].map((i) => <Star key={i} fill={Math.max(0, Math.min(1, value - i))} size={size} />)}
    </span>
  )
}

/** Operator-skill bars. `ceilings`/`revealed` optional — a hidden ceiling shows "?" and no shaded headroom (scouting fuzz). */
export function SkillBars({ skills, ceilings, revealed, skillXp, color, showXp = false }: {
  skills: SkillMap; ceilings?: SkillMap; revealed?: RevealMap; skillXp?: SkillMap; color: string; showXp?: boolean
}) {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 13 }}>
      {OP_SKILLS.map((s) => {
        const cur = skills[s.id] ?? 0
        const reveal = revealed ? !!revealed[s.id] : true
        const ceil = ceilings?.[s.id] ?? 0
        const curPct = Math.max(0, Math.min(100, (cur / SCALE_MAX) * 100))
        const ceilPct = Math.max(0, Math.min(100, (ceil / SCALE_MAX) * 100))
        const atCap = reveal && ceil > 0 && cur >= ceil
        const xpPct = showXp && !atCap && skillXp ? Math.max(0, Math.min(100, ((skillXp[s.id] ?? 0) / xpPerPoint(cur)) * 100)) : 0
        return (
          <div key={s.id}>
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 5 }}>
              <span style={{ display: "flex", alignItems: "center", gap: 7, minWidth: 0 }}>
                <GameIcon kind="skill" id={s.id} size={15} color={color} label={s.name} />
                <span style={{ fontWeight: 600, fontSize: 13 }}>{s.name}</span>
              </span>
              <span className="mono" style={{ fontSize: 12.5, fontWeight: 700 }}>
                {cur}<span style={{ color: "var(--faint)", fontWeight: 400 }}> / {reveal ? ceil : "?"}</span>
                {atCap ? <span style={{ color: "var(--good)", fontSize: 10, marginLeft: 5, fontWeight: 700 }}>MAX</span> : null}
              </span>
            </div>
            <div style={{ position: "relative", height: 9, borderRadius: "var(--radius)", background: "var(--panel-3)", overflow: "hidden" }}>
              {reveal ? <div style={{ position: "absolute", insetBlock: 0, left: 0, width: `${ceilPct}%`, background: `${color}26` }} /> : null}
              <div style={{ position: "absolute", insetBlock: 0, left: 0, width: `${curPct}%`, background: `linear-gradient(90deg, ${color}, ${color}aa)`, borderRadius: "var(--radius)" }} />
              {xpPct > 0 ? <div style={{ position: "absolute", insetBlock: 0, left: `${curPct}%`, width: `${(xpPct / 100) * (Math.max(0, 100 - curPct))}%`, background: `${color}55` }} /> : null}
              {reveal && ceil > 0 ? <div style={{ position: "absolute", top: -1, bottom: -1, left: `calc(${ceilPct}% - 1px)`, width: 2, background: "var(--text)", opacity: .55 }} /> : null}
            </div>
            <div className="flux" style={{ fontSize: 11, marginTop: 4 }}>{s.satire}</div>
          </div>
        )
      })}
    </div>
  )
}

/** One-line summary of a trait's wired `combat` effects (e.g. "+10% output · +8% dmg taken"), or "" if flavor-only. */
export function traitCombatSummary(traitIds: string[] | undefined): string {
  if (!traitIds?.length) return ""
  const parts: string[] = []
  const sign = (n: number) => (n > 0 ? "+" : "") + n
  for (const id of traitIds) {
    const c = content.traits.get(id)?.combat
    if (!c) continue
    if (c.outputPct) parts.push(`${sign(c.outputPct)}% output`)
    if (c.intakePct) parts.push(`${sign(c.intakePct)}% dmg taken`)
    if (c.critPct) parts.push(`${sign(c.critPct)}% crit`)
    if (c.hpPct) parts.push(`${sign(c.hpPct)}% HP`)
  }
  return parts.join(" · ")
}

/** A short scout report from the precise COR (now) vs fuzzy ★ (ceiling) — the win-now-vs-project read. */
export function scoutBlurb(cor: number, stars: number): string {
  const room = stars - cor / 20   // ★ are 0..5, COR/20 maps current onto the same scale
  if (stars >= 4 && room >= 1.5) return "Blue-chip project. Sky-high ceiling, raw today — bank reps and they become a star."
  if (stars >= 4) return "Polished star. High floor AND high ceiling — sign now, climb forever."
  if (room >= 1.5) return "Diamond in the rough. Modest now, real headroom — a patient pick."
  if (cor >= 62) return "Win-now veteran. Strong today, little left to learn — plug-and-play."
  if (stars <= 2) return "Journeyman. Reliable filler, plateaus early — bench depth, not a centerpiece."
  return "Serviceable. Average across the board with a little room to grow."
}
