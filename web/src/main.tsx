import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './logs.css'
import App from './App.tsx'
import { runDungeon, defaultRunInput } from '@/sim'

// dev-only: expose the sim for benchmarking/debugging (stripped from prod builds)
if (import.meta.env.DEV) {
  ;(window as unknown as { __gl: unknown }).__gl = { runDungeon, defaultRunInput }
}

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
