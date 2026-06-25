/* Character profile — Raider.io style, real gear + talents. */
import { content } from "@/content"
import { useGame, roleOf, SLOTS, type GearItem } from "@/state/game-store"
import type { Member } from "@/data/game"
import { corOf, potentialStars, roleKeyOf } from "@/data/operator"
import { mc, memberScore, scoreColor, qualityColor, bestRunsFor } from "../analytics"
import { Icon, Panel, RolePill, Upgrade, Tip, ItemTip, ItemIcon, SpellTip, GameIcon } from "../components"
import { TalentStrip } from "../TalentGrid"
import { SkillBars, corColor, potentialLabel, potentialCor, traitCombatSummary } from "../OperatorPanel"
import type { Go, GoChar } from "../LogsApp"

const SEASON_DUNGEONS = ([...content.seasons.values()][0]?.dungeons ?? [...content.dungeons.keys()])

export function CharacterPage({ id, go }: { id: string; go: Go; goChar: GoChar }) {
  const g = useGame()
  const m = g.members.find((x) => x.id === id)
  if (!m) {
    return <div className="page-scroll" style={{ display: "flex", alignItems: "center", justifyContent: "center" }}><div style={{ padding: 40 }} className="flux">Character not found. <a onClick={() => go("roster")} style={{ cursor: "pointer" }}>Back to roster</a></div></div>
  }
  const info = mc(m.spec)
  const best = m.key?.best || m.key?.level || 2   // this member's own key
  const score = memberScore(m.ilvl, best)
  const runs = bestRunsFor(m.ilvl, best, SEASON_DUNGEONS)
  const role = roleOf(m.spec)
  const inParty = g.partyIds.includes(m.id)
  const gear = g.gearFor(m.id)
  const runColor = (s: number) => (s >= 280 ? "#e268a8" : s >= 250 ? "#ff8000" : s >= 220 ? "#a335ee" : s >= 190 ? "#0070ff" : "#1eff00")

  return (
    <div className="page-scroll">
      {/* hero banner */}
      <div style={{ position: "relative", overflow: "hidden", borderBottom: "1px solid var(--line)" }}>
        <div style={{ position: "absolute", inset: 0, background: "var(--bg-grad-top)" }} />
        <div style={{ position: "absolute", inset: 0, opacity: .5, background: `${info.color}14` }} />
        <div style={{ position: "relative", maxWidth: 1280, margin: "0 auto", padding: "22px 24px", display: "flex", alignItems: "center", justifyContent: "space-between", gap: 24 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 20 }}>
            <button className="btn btn-ghost btn-sm" onClick={() => go("roster")} style={{ position: "absolute", top: -2, left: 0 }}>← Roster</button>
            <div style={{ width: 92, height: 92, borderRadius: 16, marginTop: 14, background: info.color, border: `2px solid ${info.color}`, display: "flex", alignItems: "center", justifyContent: "center", color: "#0c0d11", fontWeight: 700, fontSize: 44 }}>{m.name[0]}</div>
            <div style={{ marginTop: 14 }}>
              <div style={{ fontSize: 30, fontWeight: 700, color: info.color, lineHeight: 1.1 }}>{m.name}</div>
              {m.title ? <div style={{ color: "var(--muted)", fontSize: 14, marginTop: 2 }}>{m.name} {m.title}</div> : null}
              <div className="mono" style={{ color: "var(--faint)", fontSize: 13, marginTop: 6 }}>&lt;{g.guild?.name ?? "Greatest of All Time"}&gt;</div>
              <div style={{ display: "flex", gap: 8, marginTop: 10, alignItems: "center", flexWrap: "wrap" }}>
                <RolePill role={role} />
                <span className="chip">{info.subspec} {info.klass}</span>
                <span className="chip" style={{ color: inParty ? "var(--accent)" : "var(--faint)" }}>{inParty ? "Core" : "Reserve"}</span>
                {m.traits.map((t) => <span key={t.name} className="chip" style={{ color: "var(--muted)" }}>{t.name}</span>)}
              </div>
            </div>
          </div>
          <div style={{ textAlign: "right", marginTop: 14 }}>
            <div className="eyebrow">Mythic+ Score</div>
            <div className="mono" style={{ fontSize: 52, fontWeight: 700, color: scoreColor(score), lineHeight: 1 }}>{score}</div>
            <div style={{ display: "flex", gap: 16, justifyContent: "flex-end", marginTop: 8 }}>
              <div><span className="eyebrow" style={{ fontSize: 9.5 }}>Item Level</span><div className="mono" style={{ fontWeight: 600, color: "var(--muted)" }}>{m.ilvl}</div></div>
              <div><span className="eyebrow" style={{ fontSize: 9.5 }}>Morale</span><div className="mono" style={{ fontWeight: 600, color: m.morale >= 70 ? "var(--good)" : m.morale >= 50 ? "var(--amber)" : "var(--danger)" }}>{m.morale}%</div></div>
            </div>
          </div>
        </div>
      </div>

      <div style={{ maxWidth: 1280, margin: "0 auto", padding: 24, display: "grid", gridTemplateColumns: "1fr 320px", gap: 18, alignItems: "start" }}>
        {/* left: gear + best runs */}
        <div style={{ display: "flex", flexDirection: "column", gap: 18 }}>
          <Equipment gear={gear} avg={m.ilvl} />
          <div className="panel">
            <div className="panel-head">
              <span className="panel-title">Best Mythic+ Runs · This Season</span>
              <span className="mono" style={{ fontSize: 12, color: "var(--faint)" }}>{runs.length} dungeon{runs.length === 1 ? "" : "s"}</span>
            </div>
            <table className="runs">
              <thead><tr><th>Dungeon</th><th className="r">Key</th><th className="r">Time</th><th className="r">Result</th><th className="r">Score</th></tr></thead>
              <tbody>
                {runs.map((r) => (
                  <tr key={r.short}>
                    <td>
                      <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                        <span style={{ width: 26, height: 26, borderRadius: 6, background: "var(--panel-3)", border: "1px solid var(--line)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 10, fontWeight: 700, color: "var(--muted)", fontFamily: "var(--mono)", flex: "none" }}>{r.short}</span>
                        <span style={{ fontWeight: 600 }}>{r.dungeon}</span>
                      </div>
                    </td>
                    <td className="r"><span className="key-badge" style={{ color: r.timed ? "var(--amber)" : "var(--danger)" }}>+{r.key}</span></td>
                    <td className="r mono" style={{ color: r.timed ? "var(--text)" : "var(--danger)" }}>{r.time}</td>
                    <td className="r"><Upgrade n={r.upgrades} /></td>
                    <td className="r"><span className="mono" style={{ fontWeight: 700, color: runColor(r.score) }}>{r.score}</span></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* right: signature + operator + talents */}
        <div style={{ display: "flex", flexDirection: "column", gap: 18 }}>
          <SkillsCard specId={m.spec} color={info.color} />
          <OperatorCard member={m} color={info.color} />
          <TalentStrip specId={m.spec} chosen={m.talents} onPick={(node, opt) => g.setTalent(m.id, node, opt)} framed />
          <button className="btn btn-primary" style={{ justifyContent: "center", padding: "11px" }} onClick={() => go("report")}>
            <Icon name="report" size={15} color="#04201d" /> View Latest Report
          </button>
        </div>
      </div>
    </div>
  )
}

/** All of the spec's skills as icons — hover each for its full spell card (name, cooldown, school, effect). */
function SkillsCard({ specId, color }: { specId: string; color: string }) {
  const abilities = [...content.playerAbilities.values()].filter((a) => a.specId === specId)
  if (!abilities.length) return null
  return (
    <Panel title="Skills" right={<span className="mono" style={{ fontSize: 11, color: "var(--faint)" }}>{abilities.length}</span>} bodyStyle={{ padding: 14 }}>
      <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
        {abilities.map((a) => (
          <Tip key={a.id} tip={<SpellTip skillId={a.id} name={a.name} />}>
            <span style={{ display: "inline-flex", cursor: "help" }}><GameIcon kind="ability" id={a.id} size={40} noTip style={{ border: `1px solid ${color}55` }} /></span>
          </Tip>
        ))}
      </div>
    </Panel>
  )
}

function OperatorCard({ member, color }: { member: Member; color: string }) {
  if (!member.skills) return null
  const role = roleKeyOf(member.spec)
  const cor = corOf(member.skills, role)
  const stars = potentialStars(member.ceilings ?? member.skills, role)
  const combat = traitCombatSummary(member.traitIds)
  return (
    <Panel title="Aptitudes" right={<span className="mono" style={{ fontSize: 13, fontWeight: 700, color: corColor(cor) }}>{cor} <span style={{ color: "var(--faint)", fontWeight: 400, fontSize: 10 }}>COR</span></span>} bodyStyle={{ padding: 14 }}>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 13 }}>
        <span className="flux" style={{ fontSize: 12 }}>Potential</span>
        <span className="mono" style={{ fontSize: 15, fontWeight: 700, color: corColor(potentialCor(stars)) }}>{potentialLabel(stars)}</span>
      </div>
      <SkillBars skills={member.skills} ceilings={member.ceilings} revealed={member.revealed} skillXp={member.skillXp} color={color} showXp />
      {combat ? <div className="flux" style={{ fontSize: 11, marginTop: 13, color: "var(--faint)" }}>Trait in combat: <span style={{ color: "var(--muted)" }}>{combat}</span></div> : null}
    </Panel>
  )
}

function Equipment({ gear, avg }: { gear: Record<string, GearItem>; avg: number }) {
  const rows = SLOTS.map((s) => ({ key: s, label: content.itemSlots.get(s)?.name ?? s, item: gear[s] }))
  const col0 = rows.slice(0, Math.ceil(rows.length / 2))
  const col1 = rows.slice(Math.ceil(rows.length / 2))
  return (
    <div className="panel">
      <div className="panel-head">
        <span className="panel-title">Equipped Items</span>
        <span className="mono" style={{ fontSize: 12, color: "var(--faint)" }}>avg ilvl <span style={{ color: "var(--text)", fontWeight: 700 }}>{avg}</span></span>
      </div>
      <div style={{ padding: 12, display: "grid", gridTemplateColumns: "1fr 1fr", gap: "6px 14px" }}>
        <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>{col0.map((r) => <ItemRow key={r.key} label={r.label} item={r.item} />)}</div>
        <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>{col1.map((r) => <ItemRow key={r.key} label={r.label} item={r.item} />)}</div>
      </div>
    </div>
  )
}
function ItemRow({ label, item }: { label: string; item?: GearItem }) {
  const qColor = item ? qualityColor(item.rarity) : "#444"
  return (
    <Tip accent={qColor} tip={item ? <ItemTip item={item} label={label} /> : null} style={{ width: "100%" }}>
    <div style={{ display: "flex", alignItems: "center", gap: 10, padding: "5px 7px", borderRadius: "var(--radius)", background: "var(--row)", width: "100%" }}>
      <ItemIcon item={item} size={36} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div className="pixel" style={{ color: qColor, fontWeight: 600, fontSize: 13, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{item?.name ?? "—"}</div>
        <div style={{ color: "var(--faint)", fontSize: 11, marginTop: 1 }}>{label}</div>
      </div>
      <span className="mono" style={{ fontSize: 13.5, fontWeight: 700, color: qColor, flex: "none" }}>{item?.ilvl ?? "—"}</span>
    </div>
    </Tip>
  )
}

