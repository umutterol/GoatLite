/* GOAT Lite · Logs — 16:9 scale-to-fit stage.
   The whole app is authored against a fixed 1920×1080 design canvas and uniformly
   transform:scale()'d to fill the viewport. At the two target resolutions (1920×1080
   and 2560×1440, both exactly 16:9) the stage fills the screen with zero dead margins —
   1440p is just 1080p × 1.333. Off-ratio viewports (ultrawide, windowed, dev) letterbox.

   Anything that needs to position a fixed/portaled overlay (tooltips) must convert real
   screen coordinates into stage-local (unscaled, 0..1920 × 0..1080) space and portal INTO
   the stage element so it inherits the scale — use useStage() + toStageCoords(). */
import { createContext, useContext, useEffect, useRef, useState, type ReactNode } from "react"

/** Design canvas. Content is authored in these units; the stage scales them to the screen. */
export const STAGE_W = 1920
export const STAGE_H = 1080

interface StageInfo {
  /** current uniform scale factor applied to the stage (viewport / design size) */
  scale: number
  /** the .vp-stage DOM node — portal overlays into this so they inherit the scale transform */
  el: HTMLElement | null
}
const StageCtx = createContext<StageInfo>({ scale: 1, el: null })

/** Read the current stage scale + element. Returns {scale:1, el:null} outside a <ViewportStage>. */
export function useStage(): StageInfo {
  return useContext(StageCtx)
}

/** Convert a real-screen client point (e.clientX/clientY, getBoundingClientRect) into the stage's
    local unscaled coordinate space, so overlays portaled into the stage line up after the transform. */
export function toStageCoords(el: HTMLElement | null, scale: number, clientX: number, clientY: number) {
  if (!el) return { x: clientX, y: clientY }
  const r = el.getBoundingClientRect()
  return { x: (clientX - r.left) / scale, y: (clientY - r.top) / scale }
}

export function ViewportStage({ children }: { children: ReactNode }) {
  const [scale, setScale] = useState(1)
  const ref = useRef<HTMLDivElement>(null)
  const [el, setEl] = useState<HTMLElement | null>(null)

  useEffect(() => {
    setEl(ref.current)
    const fit = () => setScale(Math.min(window.innerWidth / STAGE_W, window.innerHeight / STAGE_H))
    fit()
    window.addEventListener("resize", fit)
    return () => window.removeEventListener("resize", fit)
  }, [])

  return (
    <div className="vp-viewport">
      <div ref={ref} className="vp-stage" style={{ transform: `translate(-50%, -50%) scale(${scale})` }}>
        <StageCtx.Provider value={{ scale, el }}>{children}</StageCtx.Provider>
      </div>
    </div>
  )
}
