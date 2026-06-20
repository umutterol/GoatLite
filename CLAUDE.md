# GOAT Lite — guide for Claude

Satirical guild-management / auto-battler that skins WoW Mythic+ as a QA job: you don't play the dungeon,
you *review the pull* — gear bots, set comp/tactics, watch a Warcraft-Logs-style replay, push the key.
React + Vite + TypeScript SPA in `web/`; authored content data in `data/` (Zod-validated through `web/src/content`).

## ⚠️ MANDATORY: keep the roadmap current with every implementation
`Docs/ROADMAP.md` is the living single source of truth. **After EVERY implementation — feature, bug fix, balance
change, or refactor — in the SAME session, you MUST:**
1. Update the affected task's **Status** (and Notes) in `Docs/ROADMAP.md`.
2. Add a dated line to the **Changelog** at the bottom of `Docs/ROADMAP.md`.
3. If you settled an item under **Open Design Decisions**, move it to ✅ Resolved with the answer.

This is a hard requirement, not a nicety — a tracker that reflects reality is the contract. When unsure whether a
change "counts," err toward adding a changelog line. (Also update the relevant `…/memory/` file for non-obvious
project facts — see the memory section the harness injects.)

## ⚠️ MANDATORY: commit at every milestone (effective Phase K.2, 2026-06-20)
**Each completed milestone (a roadmap ticket like K.2/K.3/…, or a self-contained feature/fix) MUST end with a git
commit** — once it's verified (build gate + sim/UI checks green) and the roadmap+changelog are updated. Do NOT batch
several milestones into one commit; one commit per milestone keeps history reviewable and rollback cheap. Solo project —
commit on the working branch (currently `master`, matching the existing history); no feature branch needed unless the work
is risky/experimental. Use a clear message summarising the milestone, and end it with the `Co-Authored-By:` trailer. Never
skip hooks or signing. This is a hard requirement, not optional.

## Where things live
- **Live app UI:** `web/src/logs/` — the "Logs" (WCL/Raider.io) reskin. The old `web/src/screens/` parchment
  screens are retired (they still compile but aren't routed; don't build on them).
- **Combat engine (LIVE):** `web/src/sim/egm/` (`pipeline` → `stats` → `status` → `combat` → `engine`). The app
  runs it via `@/sim` → `runDungeonEGM`. The old flat-power sim is kept as `runDungeonLegacy` for rollback only.
- **Game state / save:** `web/src/state/game-store.tsx` (reducer + `localStorage`). Keystones are **per-member**.
- **Balance / tuning:** `data/tuning.json` (`sim.*` = hpUnit/dmgUnit/keyScalingPerLevel/deathPenaltySec/rez*;
  `roleModel.{tank,healer,dps}`). Abilities & statuses: `data/abilities-player.json`, `data/statuses.json`.

## Conventions & gotchas
- **Verify before claiming done:** `cd web && npx tsc -b` (this is the build gate; eslint is NOT) + run the headless
  sim harness `node scripts/egm-smoke.mjs` (Vite-SSR) + a Playwright live check for UI changes. The sim is
  **deterministic** (same seed → identical run) — lean on it.
- **Save migrations:** any change to the SHAPE of a persisted field in `game-store.tsx` MUST either bump
  `SAVE_VERSION` (full reset) or sanitize/migrate on load. Skipping this crashes existing saves.
- **Balance reference:** the standard **1-tank / 1-healer / 3-DPS** comp at gear-appropriate ilvl (≈ `108 + 4·key`)
  is the baseline; the **+2 floor must reliably time at starting gear (~ilvl 110-120)**. 2 healers = safety-over-speed.
  Healing scales off the healer's `power` (`roleModel.healer.powerPerIlvl`) — `hpsPerIlvl` is vestigial in the EGM engine.
- **Pre-launch IP blockers exist** (decompiled reference under `Extract/`, verbatim WoW trademarks) — see the business
  plan; do not add new WoW-verbatim strings casually.
