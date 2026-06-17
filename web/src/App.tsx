import { useState } from "react"
import { Stage } from "@/components/kit"
import { TopBar, type View } from "@/components/TopBar"
import { GuildHall } from "@/screens/GuildHall"
import { RunSetup } from "@/screens/RunSetup"
import { CombatReplay } from "@/screens/CombatReplay"
import { CharacterSheet } from "@/screens/CharacterSheet"
import { GameProvider } from "@/state/game-store"

export default function App() {
  const [view, setView] = useState<View>("guild")
  const [memberId, setMemberId] = useState<string | null>(null)
  const openMember = (id: string) => { setMemberId(id); setView("char") }
  return (
    <GameProvider>
      <Stage>
        <div className="flex h-full w-full flex-col">
          <TopBar view={view} setView={setView} />
          <main className="parchment relative min-h-0 flex-1 overflow-hidden">
            {view === "guild" && <GuildHall setView={setView} onOpenMember={openMember} />}
            {view === "run" && <RunSetup setView={setView} />}
            {view === "replay" && <CombatReplay setView={setView} />}
            {view === "char" && memberId && <CharacterSheet memberId={memberId} setView={setView} />}
          </main>
        </div>
      </Stage>
    </GameProvider>
  )
}
