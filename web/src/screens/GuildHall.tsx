import { Icon, Portrait, MoraleBar, TraitChip, GiltHeading } from "@/components/kit"
import { Button } from "@/components/ui/warcraftcn/button"
import { Badge } from "@/components/ui/warcraftcn/badge"
import { SPECS, ASHVEIL_BOSSES, type Member } from "@/data/game"
import { useGame } from "@/state/game-store"
import type { View } from "@/components/TopBar"

const BUILDINGS = [
  { name: "Flasks & Cauldron", icon: "spec-arcanist", note: "Party stat buffs" },
  { name: "War Room", icon: "tac-cooldowns", note: "Extra replay data" },
  { name: "Coaching Corner", icon: "ico-morale", note: "Softens low-morale procs" },
  { name: "Morale Officer", icon: "ico-trait", note: "+5 morale / run" },
]

function RoleTag({ role }: { role: string }) {
  const map: Record<string, { c: string; i: string }> = {
    Tank: { c: "#4a78a8", i: "role-tank" },
    Healer: { c: "#3f7d3a", i: "role-healer" },
    DPS: { c: "#9a3322", i: "role-dps" },
  }
  const m = map[role]
  return (
    <span className="inline-flex items-center gap-1 rounded-[3px] px-1.5 py-0.5 text-[10px]"
          style={{ background: `${m.c}22`, border: `1px solid ${m.c}66`, color: m.c }}>
      <Icon name={m.i} size={11} /> <span className="heading font-semibold">{role}</span>
    </span>
  )
}

function RosterCard({ m, onOpen }: { m: Member; onOpen: () => void }) {
  const spec = SPECS[m.spec]
  return (
    <button onClick={onOpen}
            className="gilt-frame relative flex w-full flex-col gap-2 rounded-[5px] p-2.5 text-left transition-all hover:brightness-[1.04]"
            style={{ background: "linear-gradient(180deg, #f1e4c0, #e2cd99)" }}>
      <div className="flex gap-2.5">
        <Portrait src={m.portrait} size={62} />

        <div className="min-w-0 flex-1">
          <div className="flex items-start justify-between gap-1">
            <div className="min-w-0">
              <div className="heading truncate text-[14px] font-bold text-engraved leading-tight">{m.name}</div>
              <div className="truncate text-[10px] italic" style={{ color: "#6b5230" }}>{m.title}</div>
            </div>
            <div className="shrink-0 text-right leading-none">
              <div className="heading text-[9px] uppercase tracking-wide" style={{ color: "#8c6a26" }}>ilvl</div>
              <div className="display text-[16px] font-bold" style={{ color: "#3a2a16" }}>{m.ilvl}</div>
            </div>
          </div>
          <div className="mt-1 flex items-center gap-1.5">
            <span className="flex items-center gap-1 text-[11px]" style={{ color: "#3a2a16" }}>
              <Icon name={spec.icon} size={14} style={{ color: "#6b4a1d" }} />
              <span className="heading font-semibold">{spec.name}</span>
            </span>
            <RoleTag role={spec.role} />
          </div>
        </div>
      </div>

      <MoraleBar value={m.morale} />

      <div className="flex flex-wrap gap-1">
        {m.traits.map((t) => <TraitChip key={t.name} trait={t} />)}
      </div>
    </button>
  )
}

export function GuildHall({ setView, onOpenMember }: { setView: (v: View) => void; onOpenMember: (id: string) => void }) {
  const { members, keystone } = useGame()
  return (
    <div className="flex h-full gap-4 p-4">
      {/* left rail */}
      <aside className="flex w-[300px] shrink-0 flex-col gap-3">
        <div className="gilt-frame rounded-[5px] p-3"
             style={{ background: "radial-gradient(120% 100% at 50% 0%, #f4e8c6, #e0ca92)" }}>
          <GiltHeading sub="One keystone. It rolls a new dungeon each level.">The Keystone</GiltHeading>
          <div className="flex items-center gap-3">
            <div className="grid h-16 w-16 place-items-center rounded-[5px] gilt-frame"
                 style={{ background: "radial-gradient(circle at 40% 30%, #3a2a18, #160d06)" }}>
              <Icon name="ico-key" size={36} style={{ color: "#e6c163" }} className="ember" />
            </div>
            <div className="min-w-0 flex-1">
              <div className="display text-[17px] font-bold text-engraved leading-tight">{keystone.dungeon}</div>
              <div className="mt-1 flex items-center gap-2">
                <Badge size="lg" className="!py-0.5">+{keystone.level}</Badge>
                <span className="flex items-center gap-1 text-[12px]" style={{ color: "#5b4428" }}>
                  <Icon name="ico-timer" size={14} style={{ color: "#8c6a26" }} /> {keystone.timer}
                </span>
              </div>
            </div>
          </div>
          <div className="mt-3 grid grid-cols-2 gap-2 text-center">
            <div className="rounded-[4px] py-1" style={{ background: "rgba(42,28,14,0.08)" }}>
              <div className="heading text-[9px] uppercase tracking-wide" style={{ color: "#8c6a26" }}>Best Timed</div>
              <div className="display text-[15px] font-bold text-engraved">+{keystone.best}</div>
            </div>
            <div className="rounded-[4px] py-1" style={{ background: "rgba(42,28,14,0.08)" }}>
              <div className="heading text-[9px] uppercase tracking-wide" style={{ color: "#8c6a26" }}>Mythic Rating</div>
              <div className="display text-[15px] font-bold text-engraved">{keystone.rating}</div>
            </div>
          </div>
          <Button variant="frame" className="mt-3 w-full !py-2.5 text-[13px] uppercase tracking-wide"
                  onClick={() => setView("run")}>
            <Icon name="ico-key" size={16} /> Run this Key
          </Button>
        </div>

        <div className="gilt-frame flex-1 rounded-[5px] p-3"
             style={{ background: "linear-gradient(180deg, #ecdcb3, #dcc590)" }}>
          <GiltHeading>Guild Hall</GiltHeading>
          <ul className="flex flex-col gap-1.5">
            {BUILDINGS.map((b) => (
              <li key={b.name} className="flex items-center gap-2.5 rounded-[4px] px-2 py-1.5"
                  style={{ background: "rgba(42,28,14,0.06)" }}>
                <Icon name={b.icon} size={18} style={{ color: "#6b4a1d" }} />
                <div className="leading-tight">
                  <div className="heading text-[12px] font-semibold text-engraved">{b.name}</div>
                  <div className="text-[10px]" style={{ color: "#6b5230" }}>{b.note}</div>
                </div>
              </li>
            ))}
          </ul>
          <div className="gilt-rule my-2.5" />
          <div className="heading mb-1 text-[10px] uppercase tracking-widest" style={{ color: "#8c6a26" }}>
            This Dungeon · Bosses
          </div>
          <ul className="flex flex-col gap-1">
            {ASHVEIL_BOSSES.map((b) => (
              <li key={b.n} className="flex items-center gap-2 text-[11px]" style={{ color: "#4a341c" }}>
                <Icon name={b.icon} size={13} style={{ color: "#8c6a26" }} />
                <span className="heading font-semibold text-engraved">{b.name.split(",")[0]}</span>
                <span className="ml-auto italic" style={{ color: "#6b5230" }}>{b.tests}</span>
              </li>
            ))}
          </ul>
        </div>
      </aside>

      {/* roster */}
      <main className="flex min-w-0 flex-1 flex-col">
        <div className="flex items-end justify-between">
          <GiltHeading sub="Ten-to-fifteen adventurers. Five run each key. Bench the toxic, keep morale alive.">
            The Roster
          </GiltHeading>
          <div className="mb-2 flex items-center gap-2 text-[11px]" style={{ color: "#6b5230" }}>
            <Icon name="ico-skull" size={14} style={{ color: "#8c6a26" }} />
            <span className="italic">It's not your fault. It's never your fault.</span>
          </div>
        </div>
        <div className="grid min-h-0 flex-1 grid-cols-3 content-start gap-3 overflow-auto scroll-thin pr-1">
          {members.map((m) => <RosterCard key={m.id} m={m} onOpen={() => onOpenMember(m.id)} />)}
        </div>
      </main>
    </div>
  )
}
