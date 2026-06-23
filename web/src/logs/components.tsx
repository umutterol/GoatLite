/* Shared components for the GOAT Lite · Logs reskin. */
import { useRef, useState, type CSSProperties, type ReactNode } from "react"
import { createPortal } from "react-dom"
import { content } from "@/content"
import { mc, parseColor, parseLabel, fmt, fmtInt, mmss, type DmgRow } from "./analytics"
import type { RoleKey } from "@/state/game-store"

/* ---- J.10: one reusable hover tooltip (fixed-position portal — never clipped, follows the trigger) ---- */
export function Tip({ tip, children, max = 280, style }: { tip: ReactNode; children: ReactNode; max?: number; style?: CSSProperties }) {
  const [show, setShow] = useState(false)
  const [pos, setPos] = useState({ x: 0, y: 0 })
  const ref = useRef<HTMLSpanElement>(null)
  if (!tip) return <>{children}</>
  const place = () => { const r = ref.current?.getBoundingClientRect(); if (r) setPos({ x: r.left + r.width / 2, y: r.top }) }
  return (
    <span ref={ref} onMouseEnter={() => { place(); setShow(true) }} onMouseLeave={() => setShow(false)} style={{ display: "inline-flex", alignItems: "center", ...style }}>
      {children}
      {show ? createPortal(
        <div role="tooltip" style={{ position: "fixed", left: pos.x, top: pos.y, transform: "translate(-50%,-100%) translateY(-9px)", zIndex: 9999, pointerEvents: "none", maxWidth: max, background: "var(--panel-3)", border: "1px solid var(--line)", borderRadius: "var(--radius)", boxShadow: "0 8px 24px rgba(0,0,0,.55)", padding: "8px 11px", fontSize: 12.5, lineHeight: 1.5, color: "var(--text)" }}>
          {tip}
        </div>, document.body) : null}
    </span>
  )
}
/** Standard tooltip body: a bold title + optional muted description. */
export function TipBody({ title, desc, accent }: { title: string; desc?: ReactNode; accent?: string }) {
  return (
    <div>
      <div style={{ fontWeight: 700, marginBottom: desc ? 3 : 0, color: accent ?? "var(--text)" }}>{title}</div>
      {desc ? <div className="flux" style={{ fontSize: 11.5 }}>{desc}</div> : null}
    </div>
  )
}
/** Resolve a content tooltip for an asset icon (spec/role/tactic/affix/skill); null = no tooltip. */
function iconTip(kind: IconKind, id: string, label?: string): ReactNode {
  if (kind === "spec") { const s = content.specs.get(id); if (s) return <TipBody title={`${s.name} ${content.classes.get(s.classId)?.name ?? ""}`.trim()} desc={s.blurb} accent={mc(id).color} /> }
  else if (kind === "tactic") { const t = content.tactics.get(id); if (t) return <TipBody title={t.name} desc={t.perPoint} /> }
  else if (kind === "affix") { const a = content.affixes.get(id); if (a) return <TipBody title={a.name} desc={a.effect} /> }
  else if (kind === "skill") { const k = content.operatorSkills.get(id); if (k) return <TipBody title={k.name} desc={k.effect} /> }
  else if (kind === "ability") { const sk = content.skills.get(id); if (sk) return <TipBody title={sk.name} desc={sk.description} /> }
  else if (kind === "role") return <TipBody title={id.charAt(0).toUpperCase() + id.slice(1)} desc="Party role" />
  return label ? <TipBody title={label} /> : null
}

/* ---- tiny geometric icons (from the design) ---- */
const ICONS: Record<string, (c: string) => ReactNode> = {
  report: (c) => <path d="M3 13l3.5-4 3 3L14 6m0 0v3.5M14 6h-3.5" stroke={c} strokeWidth="1.6" fill="none" strokeLinecap="round" strokeLinejoin="round" />,
  roster: (c) => <g stroke={c} strokeWidth="1.5" fill="none"><circle cx="6" cy="6" r="2.3" /><circle cx="12" cy="7" r="1.9" /><path d="M2.5 14c0-2.2 1.6-3.6 3.5-3.6s3.5 1.4 3.5 3.6M10 14c0-1.6.9-2.9 2.4-3.2" strokeLinecap="round" /></g>,
  character: (c) => <g stroke={c} strokeWidth="1.5" fill="none"><circle cx="8" cy="5.5" r="2.6" /><path d="M3.5 14c0-2.7 2-4.3 4.5-4.3s4.5 1.6 4.5 4.3" strokeLinecap="round" /></g>,
  setup: (c) => <g stroke={c} strokeWidth="1.5" fill="none" strokeLinecap="round"><path d="M8 2.5v11M2.5 8h11" /><circle cx="8" cy="8" r="5.3" /></g>,
  star: (c) => <path d="M8 1.8l1.7 3.9 4.3.4-3.2 2.8 1 4.1L8 11.1 4.2 13l1-4.1L2 6.1l4.3-.4z" fill={c} />,
  skull: (c) => <g fill="none" stroke={c} strokeWidth="1.4"><path d="M3 7.5C3 4.5 5.2 2.5 8 2.5s5 2 5 5c0 1.7-.8 2.8-1.6 3.4v1.6a1 1 0 01-1 1H6.6a1 1 0 01-1-1v-1.6C4.8 10.3 3 9.2 3 7.5z" /><circle cx="6" cy="7.3" r="1.1" fill={c} stroke="none" /><circle cx="10" cy="7.3" r="1.1" fill={c} stroke="none" /></g>,
  clock: (c) => <g fill="none" stroke={c} strokeWidth="1.5"><circle cx="8" cy="8" r="5.6" /><path d="M8 4.8V8l2.3 1.6" strokeLinecap="round" /></g>,
  bolt: (c) => <path d="M9 1.5L3.5 9H7l-1 5.5L12.5 7H9z" fill={c} />,
  chevron: (c) => <path d="M6 4l4 4-4 4" stroke={c} strokeWidth="1.7" fill="none" strokeLinecap="round" strokeLinejoin="round" />,
}
export function Icon({ name, size = 15, color = "currentColor" }: { name: string; size?: number; color?: string }) {
  const draw = ICONS[name]
  return <svg width={size} height={size} viewBox="0 0 16 16" style={{ display: "block", flex: "none" }}>{draw ? draw(color) : null}</svg>
}

/* ---- G.4: full-colour raster icon registry (/public/icons/{prefix}-{id}.png) ----
   <GameIcon kind id/> renders the painted PNG art at /icons/{prefix}-{id}.png. A missing file degrades (via onError)
   to a default image: `affix-default.png` for affixes, `icon-default.png` for everything else — so dropping a new PNG
   in is all it takes to wire it. The `color` prop is accepted but ignored (raster art carries its own colour). */
const ICON_PREFIX = {
  role: "role", spec: "spec", stat: "stat", tactic: "tac", affix: "affix", currency: "cur", ui: "ico",
  skill: "skill", ability: "ability", class: "class", talent: "talent", trait: "trait", item: "item", dungeon: "dungeon",
} as const
export type IconKind = keyof typeof ICON_PREFIX
export function GameIcon({ kind, id, size = 16, label, style, noTip = false }: {
  kind: IconKind; id: string; size?: number; color?: string; label?: string; style?: CSSProperties; noTip?: boolean
}) {
  const aria = label ?? `${id} ${kind}`
  // every dungeon uses the keystone icon (no per-dungeon art); affixes fall back to affix-default; else the bear
  const fallback = kind === "affix" ? "/icons/affix-default.png" : kind === "dungeon" ? "/icons/ico-key.png" : "/icons/icon-default.png"
  const src = kind === "dungeon" ? "/icons/ico-key.png" : `/icons/${ICON_PREFIX[kind]}-${id}.png`
  const img = (
    <img
      role="img" aria-label={aria} alt={aria} src={src} width={size} height={size}
      onError={(e) => { const t = e.currentTarget; if (!t.src.endsWith(fallback)) t.src = fallback }}
      style={{ width: size, height: size, flex: "none", objectFit: "cover", borderRadius: "var(--radius)", display: "inline-block", verticalAlign: "middle", ...style }}
    />
  )
  if (noTip) return img
  return <Tip tip={iconTip(kind, id, label)}>{img}</Tip>
}

export function Panel({ title, right, children, className = "", style = {}, bodyStyle = {}, bodyClass = "" }: {
  title?: ReactNode; right?: ReactNode; children: ReactNode; className?: string; style?: CSSProperties; bodyStyle?: CSSProperties; bodyClass?: string
}) {
  return (
    <div className={"panel " + className} style={style}>
      {title || right ? (
        <div className="panel-head">
          <span className="panel-title">{title}</span>
          {right}
        </div>
      ) : null}
      <div className={bodyClass} style={{ padding: 16, ...bodyStyle }}>{children}</div>
    </div>
  )
}

export function Parse({ p, big = false }: { p: number; big?: boolean }) {
  const c = parseColor(p)
  return (
    <span className="parse" style={{ color: c, background: c + "22", boxShadow: `inset 0 0 0 1px ${c}55`, fontSize: big ? 14 : 12.5, padding: big ? "3px 10px" : undefined }}>
      {p}<span className="qlbl">{parseLabel(p)}</span>
    </span>
  )
}

export function ClassName({ name, specId, showSpec = true, size = 14 }: { name: string; specId: string; showSpec?: boolean; size?: number }) {
  const info = mc(specId)
  return (
    <span style={{ display: "inline-flex", alignItems: "baseline", gap: 7 }}>
      <span style={{ color: info.color, fontWeight: 700, fontSize: size }}>{name}</span>
      {showSpec ? <span style={{ color: "var(--faint)", fontSize: size - 2.5, fontWeight: 500 }}>{info.subspec}</span> : null}
    </span>
  )
}

export const ROLE_META: Record<RoleKey, { label: string; color: string }> = {
  tank: { label: "Tank", color: "var(--tank)" },
  healer: { label: "Healer", color: "var(--healer)" },
  dps: { label: "DPS", color: "var(--dps)" },
}
export function RolePill({ role }: { role: RoleKey }) {
  const r = ROLE_META[role]
  return <span className="role-pill" style={{ color: r.color }}><GameIcon kind="role" id={role} size={12} color={r.color} label={`${r.label} role`} noTip />{r.label}</span>
}

/* A `.chip` that tooltips its affix's effect (J.10). Looks the affix up by display name. */
const AFFIX_BY_NAME = new Map([...content.affixes.values()].map((a) => [a.name, a]))
export function AffixChip({ name, style }: { name: string; style?: CSSProperties }) {
  const a = AFFIX_BY_NAME.get(name)
  return <Tip tip={a ? <TipBody title={a.name} desc={a.effect} /> : null}><span className="chip" style={style}>{name}</span></Tip>
}

/* ---- spell tooltip (WoW-style spell card) + an underlined/bold spell name for the event log ---- */
/** A WoW-style spell card: name, cd/target, school·formula, then the description as yellow flavor. No SpellID. */
export function SpellTip({ skillId, name }: { skillId?: string; name?: string }) {
  const sk = skillId ? content.skills.get(skillId) : undefined
  const title = sk?.name ?? name ?? "Ability"
  return (
    <div style={{ minWidth: 190, maxWidth: 280 }}>
      <div style={{ fontWeight: 700, fontSize: 14, color: "#fff", display: "flex", alignItems: "center", gap: 7 }}>
        {skillId ? <GameIcon kind="ability" id={skillId} size={20} noTip /> : null}{title}
      </div>
      {sk ? (
        <>
          <div style={{ display: "flex", justifyContent: "space-between", gap: 16, marginTop: 2, color: "var(--muted)", fontSize: 11.5 }}>
            <span>{sk.cd > 0 ? `${sk.cd * 3}s cooldown` : "No cooldown"}</span>
            <span>{sk.targetType}</span>
          </div>
          {sk.damageType && sk.damageType !== "None"
            ? <div style={{ color: "var(--muted)", fontSize: 11.5 }}>{sk.damageType}{sk.formula && sk.formula !== "0" ? ` · ${sk.formula}` : ""}</div>
            : (sk.formula && sk.formula !== "0" ? <div style={{ color: "var(--muted)", fontSize: 11.5 }}>{sk.formula}</div> : null)}
          {sk.description ? <div style={{ color: "#ffd100", fontSize: 12, marginTop: 5, lineHeight: 1.45 }}>{sk.description}</div> : null}
        </>
      ) : null}
    </div>
  )
}
/** A bold, underlined spell name in the combat log; hovering it pops the SpellTip next to the cursor. */
export function LogSpell({ name, skillId, color }: { name: string; skillId?: string; color?: string }) {
  const [show, setShow] = useState(false)
  const [pos, setPos] = useState({ x: 0, y: 0 })
  const move = (e: { clientX: number; clientY: number }) => {
    const flip = e.clientX > window.innerWidth - 300
    setPos({ x: flip ? e.clientX - 300 : e.clientX + 16, y: Math.min(e.clientY + 18, window.innerHeight - 150) })
  }
  return (
    <>
      {skillId ? <GameIcon kind="ability" id={skillId} size={13} noTip style={{ marginRight: 4, verticalAlign: "-2px" }} /> : null}
      <span className="log-spell" onMouseEnter={(e) => { move(e); setShow(true) }} onMouseMove={move} onMouseLeave={() => setShow(false)}
        style={{ fontWeight: 700, textDecoration: "underline", textUnderlineOffset: 2, cursor: "help", color: color ?? "inherit" }}>{name}</span>
      {show ? createPortal(
        <div role="tooltip" style={{ position: "fixed", left: pos.x, top: pos.y, zIndex: 9999, pointerEvents: "none", background: "var(--panel-3)", border: "1px solid var(--line)", borderRadius: "var(--radius)", boxShadow: "0 8px 24px rgba(0,0,0,.55)", padding: "9px 12px" }}>
          <SpellTip skillId={skillId} name={name} />
        </div>, document.body) : null}
    </>
  )
}

/* WCL damage/healing table */
export function DamageTable({ rows, metric = "dps" }: { rows: DmgRow[]; metric?: "dps" | "hps" }) {
  const max = rows.length ? rows[0].amount : 1
  const rateLabel = metric === "hps" ? "HPS" : "DPS"
  return (
    <div className="dd">
      <div className="dd-head">
        <div>#</div><div>Name</div><div className="r">Amount</div><div className="r">{rateLabel}</div><div className="r">%</div>
      </div>
      {rows.map((d, i) => {
        const info = mc(d.specId)
        const rate = metric === "hps" ? (d.hps ?? 0) : d.dps
        return (
          <div className="dd-row" key={d.id}>
            <div className="dd-rank">{i + 1}</div>
            <div className="dd-name-cell">
              <div className="dd-fill" style={{ width: (d.amount / max) * 100 + "%", background: `linear-gradient(90deg, ${info.color}cc, ${info.color}55)`, boxShadow: `inset 2px 0 0 ${info.color}` }} />
              <div className="dd-name">
                <Parse p={d.parse} />
                <span className="nm" style={{ color: info.color }}>{d.name}</span>
                <span className="sp">{info.subspec}</span>
              </div>
            </div>
            <div className="dd-amt mono">{fmt(d.amount)}<span className="raw">{fmtInt(d.amount)}</span></div>
            <div className="dd-dps mono">{fmt(rate)}</div>
            <div className="dd-pct mono">{d.pct.toFixed(1)}%</div>
          </div>
        )
      })}
    </div>
  )
}

/* Details!-style compact meter */
export function Meter({ rows, metric = "dps", segName, total, duration }: { rows: DmgRow[]; metric?: "dps" | "hps"; segName: string; total: number; duration: number }) {
  const max = rows.length ? rows[0].amount : 1
  const rate = (d: DmgRow) => (metric === "hps" ? (d.hps ?? 0) : d.dps)
  return (
    <div className="meter">
      <div className="meter-titlebar">
        <span className="seg-name"><Icon name="bolt" size={12} color="var(--accent)" />{segName}</span>
        <span className="seg-meta mono">{fmt(total)} · {mmss(duration)}</span>
      </div>
      <div className="meter-body">
        {rows.map((d, i) => {
          const info = mc(d.specId)
          return (
            <div className="meter-row" key={d.id}>
              <div className="meter-bar" style={{ width: (d.amount / max) * 100 + "%", background: `linear-gradient(90deg, ${info.color}, ${info.color}aa)` }} />
              <div className="meter-content">
                <span className="ml"><span style={{ opacity: .8 }}>{i + 1}.</span>{d.name}</span>
                <span className="mr">{fmt(rate(d))} <span style={{ opacity: .7 }}>({d.pct.toFixed(1)}%)</span></span>
              </div>
            </div>
          )
        })}
      </div>
      <div className="meter-foot mono">
        <span>Details! · Mythic+</span>
        <span>{rows.length} combatants</span>
      </div>
    </div>
  )
}

export function Upgrade({ n }: { n: number }) {
  if (n <= 0) return <span className="depleted mono" style={{ fontWeight: 700 }}>Depleted</span>
  return <span className="upg mono">+{n}</span>
}

export function Stat({ label, val, color }: { label: string; val: ReactNode; color?: string }) {
  return (
    <div style={{ background: "var(--panel-2)", borderRadius: "var(--radius)", padding: "7px 9px", textAlign: "center" }}>
      <div className="eyebrow" style={{ fontSize: 9 }}>{label}</div>
      <div className="mono" style={{ fontSize: 15, fontWeight: 700, marginTop: 2, color: color || "var(--text)" }}>{val}</div>
    </div>
  )
}
