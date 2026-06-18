import { GameProvider } from "@/state/game-store"
import { LogsApp } from "@/logs/LogsApp"

export default function App() {
  return (
    <GameProvider>
      <LogsApp />
    </GameProvider>
  )
}
