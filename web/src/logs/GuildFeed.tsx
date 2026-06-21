/* GOAT Lite · Logs — Guild Feed (Phase M.1): the always-visible meta-layer notification stream.
   System notifications only for now (neutral game-voice). In-character barks arrive in M.3/M.4. */
import { useEffect, useRef } from "react"
import { useGame } from "@/state/game-store"
import { GameIcon, type IconKind } from "./components"
import type { GoChar } from "./LogsApp"

export function GuildFeed({ goChar }: { goChar: GoChar }) {
  const { feed } = useGame()
  const scrollRef = useRef<HTMLDivElement>(null)

  // chat-style: newest at the bottom, pinned to the latest line as entries arrive
  useEffect(() => {
    const el = scrollRef.current
    if (el) el.scrollTop = el.scrollHeight
  }, [feed.length])

  return (
    <aside className="guild-feed" aria-label="Guild feed">
      <div className="feed-head">
        <span className="panel-title">Guild Feed</span>
        {feed.length ? <span className="feed-count">{feed.length}</span> : null}
      </div>
      <div className="feed-scroll" ref={scrollRef}>
        {feed.length === 0 ? (
          <div className="feed-empty">No activity yet. Run a key to start the log.</div>
        ) : (
          feed.map((e) => {
            const clickable = !!e.memberId
            return (
              <div
                key={e.id}
                className={`feed-item tone-${e.tone}${clickable ? " clickable" : ""}`}
                onClick={clickable ? () => goChar(e.memberId!) : undefined}
                role={clickable ? "button" : undefined}
                tabIndex={clickable ? 0 : undefined}
                onKeyDown={clickable ? (ev) => { if (ev.key === "Enter") goChar(e.memberId!) } : undefined}
              >
                <span className="feed-ico">
                  {e.icon ? <GameIcon kind={e.icon.kind as IconKind} id={e.icon.id} size={14} noTip /> : <span className="feed-dot" />}
                </span>
                <span className="feed-text">{e.text}</span>
              </div>
            )
          })
        )}
      </div>
    </aside>
  )
}
