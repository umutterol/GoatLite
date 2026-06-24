import { GameProvider } from "@/state/game-store"
import { LogsApp } from "@/logs/LogsApp"
import { ViewportStage } from "@/logs/ViewportStage"

export default function App() {
  return (
    <GameProvider>
      <ViewportStage>
        <LogsApp />
      </ViewportStage>
    </GameProvider>
  )
}
