import { Icon, Portrait, MoraleBar, TraitChip, GiltHeading } from "@/components/kit"
import { Button } from "@/components/ui/warcraftcn/button"
import { SPECS, RARITY_HEX } from "@/data/game"
import { useGame, SLOTS, type GearItem } from "@/state/game-store"
import { content } from "@/content"
import type { View } from "@/components/TopBar"

const slotName = (s: string) => content.itemSlots.get(s)?.name ?? s

function SlotCard({ slot, item }: { slot: string; item?: GearItem }) {
  const tint = item ? RARITY_HEX[item.rarity] ?? "#c8b88e" : "#9a8a63"
  return (
    <div className="gilt-frame rounded-[5px] p-2.5" style={{ background: "linear-gradient(180deg, #f1e4c0, #e2cd99)" }}>
      <div className="heading mb-1 text-[10px] uppercase tracking-widest" style={{ color: "#8c6a26" }}>{slotName(slot)}</div>
      <div className="flex items-center gap-2">
        <span className="h-3 w-3 shrink-0 rounded-[2px]" style={{ background: tint, boxShadow: `0 0 6px ${tint}88` }} />
        <div className="min-w-0 flex-1">
          <div className="heading truncate text-[12px] font-semibold" style={{ color: tint === "#c8b88e" ? "#3a2a16" : tint }}>{item?.name ?? "— empty —"}</div>
          <div className="text-[10px]" style={{ color: "#6b5230" }}>{item ? `${item.rarity} · ilvl ${item.ilvl}` : ""}</div>
        </div>
      </div>
    </div>
  )
}

export function CharacterSheet({ memberId, setView }: { memberId: string; setView: (v: View) => void }) {
  const { members, gearFor, equip, stash } = useGame()
  const m = members.find((x) => x.id === memberId)

  if (!m) {
    return (
      <div className="grid h-full place-items-center gap-3">
        <Button onClick={() => setView("guild")}>← Back to the Guild Hall</Button>
      </div>
    )
  }
  const spec = SPECS[m.spec]
  const gear = gearFor(memberId)
  const equippable = stash.filter((i) => i.specs.includes(m.spec))

  return (
    <div className="flex h-full flex-col gap-3 p-4">
      {/* header */}
      <div className="gilt-frame flex items-center gap-3 rounded-[5px] px-3 py-2" style={{ background: "linear-gradient(180deg, #f2e4bb, #e4cd93)" }}>
        <Button className="!px-3 !py-1.5 text-[11px] uppercase" onClick={() => setView("guild")}>← Guild Hall</Button>
        <Portrait src={m.portrait} size={54} />
        <div className="leading-tight">
          <div className="display text-[17px] font-bold text-engraved">{m.name}</div>
          <div className="flex items-center gap-1 text-[11px] italic" style={{ color: "#6b5230" }}>
            <Icon name={spec.icon} size={13} style={{ color: "#6b4a1d" }} />{m.title} · {spec.className} {spec.name}
          </div>
        </div>
        <div className="ml-4 text-center leading-none">
          <div className="heading text-[9px] uppercase tracking-wide" style={{ color: "#8c6a26" }}>Item Level</div>
          <div className="display text-[24px] font-bold text-gilt">{m.ilvl}</div>
        </div>
        <div className="ml-4 w-44"><MoraleBar value={m.morale} /></div>
        <div className="ml-auto flex max-w-[320px] flex-wrap justify-end gap-1">
          {m.traits.map((t) => <TraitChip key={t.name} trait={t} />)}
        </div>
      </div>

      <div className="flex min-h-0 flex-1 gap-4">
        {/* paper doll */}
        <section className="flex min-w-0 flex-1 flex-col">
          <GiltHeading sub="Six slots — item level is their average. Gear up to push higher keys.">Equipment</GiltHeading>
          <div className="grid grid-cols-2 content-start gap-2.5">
            {SLOTS.map((s) => <SlotCard key={s} slot={s} item={gear[s]} />)}
          </div>
        </section>

        {/* stash */}
        <aside className="flex w-[380px] shrink-0 flex-col">
          <GiltHeading sub={`${equippable.length} of ${stash.length} stashed items fit ${m.name}`}>The Stash</GiltHeading>
          <div className="flex min-h-0 flex-1 flex-col gap-1.5 overflow-auto scroll-thin pr-1">
            {equippable.length === 0 ? (
              <p className="text-[11px] italic" style={{ color: "#6b5230" }}>Nothing in the stash fits this character. Run keys to loot upgrades.</p>
            ) : (
              equippable
                .map((it) => ({ it, delta: it.ilvl - (gear[it.slot]?.ilvl ?? 0) }))
                .sort((a, b) => b.delta - a.delta)
                .map(({ it, delta }) => {
                  const tint = RARITY_HEX[it.rarity] ?? "#c8b88e"
                  const upgrade = delta > 0
                  return (
                    <button key={it.uid} onClick={() => equip(memberId, it.uid)}
                            className="gilt-frame flex items-center gap-2 rounded-[5px] p-2 text-left transition-all hover:brightness-105"
                            style={{ background: "linear-gradient(180deg, #f1e4c0, #e2cd99)" }}>
                      <span className="h-3 w-3 shrink-0 rounded-[2px]" style={{ background: tint, boxShadow: `0 0 6px ${tint}88` }} />
                      <div className="min-w-0 flex-1">
                        <div className="heading truncate text-[12px] font-semibold" style={{ color: tint === "#c8b88e" ? "#3a2a16" : tint }}>{it.name}</div>
                        <div className="text-[10px]" style={{ color: "#6b5230" }}>{slotName(it.slot)} · ilvl {it.ilvl}</div>
                      </div>
                      <div className="shrink-0 text-right">
                        <div className="heading text-[12px] font-bold" style={{ color: upgrade ? "#3f7d3a" : delta < 0 ? "#9a3322" : "#8c6a26" }}>
                          {delta > 0 ? `+${delta}` : delta < 0 ? `${delta}` : "="}
                        </div>
                        <div className="text-[9px] uppercase tracking-wide" style={{ color: "#8c6a26" }}>{upgrade ? "equip" : "swap"}</div>
                      </div>
                    </button>
                  )
                })
            )}
          </div>
        </aside>
      </div>
    </div>
  )
}
