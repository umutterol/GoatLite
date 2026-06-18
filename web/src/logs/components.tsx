/* Shared components for the GOAT Lite · Logs reskin. */
import { type CSSProperties, type ReactNode } from "react"
import { mc, parseColor, parseLabel, fmt, fmtInt, mmss, type DmgRow } from "./analytics"
import type { RoleKey } from "@/state/game-store"

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
  return <span className="role-pill" style={{ color: r.color }}><span className="dot" style={{ background: r.color }} />{r.label}</span>
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
    <div style={{ background: "var(--panel-2)", borderRadius: 7, padding: "7px 9px", textAlign: "center" }}>
      <div className="eyebrow" style={{ fontSize: 9 }}>{label}</div>
      <div className="mono" style={{ fontSize: 15, fontWeight: 700, marginTop: 2, color: color || "var(--text)" }}>{val}</div>
    </div>
  )
}
