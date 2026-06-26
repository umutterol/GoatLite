/* GOAT Lite · Logs — Guild Feed restyled as a WoW-style chat log: [HH:MM] timestamps, channel-coloured [Channel]
   prefixes, class-coloured speakers. System notifications + in-character barks share one frame. Read-only (no input). */
import { useEffect, useRef } from "react"
import { useGame } from "@/state/game-store"
import { mc } from "./analytics"
import type { GoChar } from "./LogsApp"

// WoW-style channel taxonomy from the entry's kind + tone. tag = the [Channel] prefix, col = its colour, txt = the
// message-body colour (WoW tints body text per channel too). Barks = a member speaking → Party (blue); good news
// (joins, timed keys, upgrades) → Guild (green); warn → Officer (amber); bad/neutral → System (red / yellow).
function channelOf(e: { kind?: string; tone: string }): { tag: string; col: string; txt: string } {
  if (e.kind === "bark") return { tag: "Party", col: "#7ea9ff", txt: "#bcd2ff" }
  if (e.tone === "good") return { tag: "Guild", col: "#40d860", txt: "#cdeed4" }
  if (e.tone === "warn") return { tag: "Officer", col: "#f0a52e", txt: "#f1d6a3" }
  if (e.tone === "bad") return { tag: "System", col: "#ff6b6b", txt: "#f3b9b9" }
  return { tag: "System", col: "#ffd24a", txt: "#d8d9df" }
}
const hhmm = (t: number) => { const d = new Date(t); return `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}` }

export function GuildFeed({ goChar, embedded = false }: { goChar: GoChar; embedded?: boolean }) {
  const { feed } = useGame()
  const scrollRef = useRef<HTMLDivElement>(null)
  // stable per-line wall-clock timestamp (cosmetic): stamp an id the first time it's seen; persists across renders.
  const tsMap = useRef<Map<string, number>>(new Map())
  const now = Date.now()

  // chat-style: newest at the bottom, pinned to the latest line as entries arrive
  useEffect(() => {
    const el = scrollRef.current
    if (el) el.scrollTop = el.scrollHeight
  }, [feed.length])

  return (
    <aside className={"guild-feed" + (embedded ? " embedded" : "")} aria-label="Guild chat">
      <div className="feed-head">
        <span className="panel-title">Guild Chat</span>
        {feed.length ? <span className="feed-count">{feed.length}</span> : null}
      </div>
      <div className="feed-scroll" ref={scrollRef}>
        {feed.length === 0 ? (
          <div className="feed-empty">No activity yet. Run a key to start the log.</div>
        ) : (
          feed.map((e) => {
            let ts = tsMap.current.get(e.id)
            if (ts == null) { ts = now; tsMap.current.set(e.id, ts) }
            const ch = channelOf(e)
            const clickable = !!e.memberId
            return (
              <div
                key={e.id}
                className={`feed-line${clickable ? " clickable" : ""}`}
                onClick={clickable ? () => goChar(e.memberId!) : undefined}
                role={clickable ? "button" : undefined}
                tabIndex={clickable ? 0 : undefined}
                onKeyDown={clickable ? (ev) => { if (ev.key === "Enter") goChar(e.memberId!) } : undefined}
              >
                <span className="feed-time">{hhmm(ts)}</span>
                <span className="feed-chan" style={{ color: ch.col }}>[{ch.tag}]</span>{" "}
                {e.kind === "bark" && e.speaker
                  ? <><span className="feed-who" style={{ color: mc(e.icon?.id ?? "").color }}>{e.speaker}:</span> <span className="feed-msg" style={{ color: ch.txt }}>{e.text}</span></>
                  : <span className="feed-msg" style={{ color: ch.txt }}>{e.text}</span>}
              </div>
            )
          })
        )}
      </div>
    </aside>
  )
}
