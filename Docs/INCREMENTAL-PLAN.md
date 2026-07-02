# GOAT Lite: Incremental — Conversion Plan (v2)

**Status:** design ✅ locked (2026-07-02) · execution not started (Phase IG in `ROADMAP.md`)
**Owner:** Producer (Claude) + Umut. Companion docs: `ROADMAP.md` (Phase IG tickets), `GDD.md`, `Class-Tools-System.md`.
**This document is the design source of truth for the incremental conversion.** The roadmap tracks execution status;
this doc holds the WHY and the system designs. Update both together (roadmap update protocol applies).

---

## 1. Vision

> **You're a burned-out QA lead running a guild of raid-testing bots. You don't play the dungeon — you staff the
> team, push the key, and read the logs. Numbers go up. Once a week the whole world runs the same key and you
> climb the board.**

Three registers of play on one deterministic engine:

| Register | Player behaviour | What serves it |
|---|---|---|
| **Chill** (default) | park a party farming, loot rains, zero stress | auto-chained runs, result bursts, offline reports |
| **Depth** (opt-in) | open the logs, tune stances/tactics, min-max | the existing WCL replay + parses (`web/src/logs/`) |
| **Social** (v1.5) | weekly key + leaderboards, seasons | deterministic sim → server re-sim verification |

**Not a genre pivot — a re-skin of pacing.** The combat sim, roster, keystones, gear, operator skills, traits,
morale, feed/barks, and all 6 dungeons carry over. What changes: the run becomes fast/repeated/automatable, a
click layer (Momentum) is added, progression gets incremental layering (trees + aspects + prestige), and the
manual run flow is demoted from the core loop to the depth layer.

## 2. Why (market, June 2026)

- Idle/incremental ≈ $14.2B (2025) → ~$34.8B by 2034. The **Steam/browser premium lane** rewards honest, deep
  systems (Melvor, The Farmer Was Replaced, IdleOn) — not mobile IAP patterns.
- The new wave (Loot Loop, Agrivore, Ball Clicker Roguelike) = **seconds-long runs → instant loot → deep tree →
  prestige → leaderboards/contracts**. Loot Loop (92% positive) is literally "party → dungeon → loot → upgrade" —
  our exact shape, validated, minus our depth.
- **Our two moats, which that wave lacks:** (1) the **guild-as-org meta** (roster with personalities/drama vs a flat
  skill tree); (2) a **deterministic, headless sim** → *verifiable* leaderboards (server re-sims any submission) and
  *honest* offline progress. Strategy: clicker surface as the wedge, the sim as the defensible depth.

## 3. Locked decisions

| # | Decision | Call |
|---|---|---|
| D1 | Product scope | **Transform in-place** — GOAT Lite becomes the incremental; manual run flow survives as opt-in depth |
| D2 | v1 platform | **Browser first** (itch.io/web, free) → Steam wrap (Electron/Tauri) after validation |
| D3 | Leaderboards | **Defer to v1.5**, but v1 records the verifiable run-ticket format (seed + full input log) |
| D4 | Art | **Purchased 2D packs** + palette-unification pass; sprite-sheet animation first (Spine/Rive only if needed) |
| D5 | Engine/tech | **Stay TypeScript** — no Unity/Unreal port (would forfeit the deterministic-sim moat + isomorphic server re-sim). Render layer = PixiJS on top of the sim; React keeps menus |
| D6 | Farming model | **Farm = auto-chained keystone runs** (no separate "depth" axis; the key IS the ladder; margin-based +1/+2/+3 kept) |
| D7 | The click | **Momentum**: click = lead damage + a stack; stacks multiply party **damage AND healing**; decay when idle |
| D8 | Difficulty model | **Two scaling knobs**: `hpScalingPerLevel` > `dmgScalingPerLevel` → frontier wall is timer-bound (clickable), survival walls periodic (gear gates) |
| D9 | Progression split | **Persist through prestige:** guild tree, spec trees, aspect Codex. **Reset:** gear+imprints, keystones, operator skills/roster |
| D10 | Spec trees | **Atlas model**: eventually unlock ALL nodes; identity lives in **swappable stance sockets** (= the existing 5 authored talent nodes/spec), stance picked **per party slot**; + ~8–10 new passive nodes/spec |
| D11 | Aspects | **On gear, any aspect → any slot** (unlike D4-slot-typing). Legendary drop → **extract** (destroys item, aspect → permanent Codex) → **imprint** onto any item (shard cost). Cap: 1 active aspect/member, 2 with spec-tree capstone |
| D12 | Prestige | **"The Patch"** — ilvl squish + affix rotation; meta-currency **Institutional Knowledge (IK)**; first Patch attractive at **~3–5h** (browser churn beats a 15h hook) |
| D13 | Time compression | Live runs play at **~36×** (the replay `RATE=36` precedent) → a run ≈ 25–40 wall-seconds |
| D14 | Morale departure | Stays **disabled** (a member quitting overnight is a feel-bad); revisit post-launch |

## 4. System designs

### 4.1 Core loop
```
pick/auto party → PUSH (auto-chained runs @36×) → result burst (loot/key±/parse, 2–3s)
      ↑                     │ click = Momentum (active push)
      └── spend: gear/aspects/trees/recruits ←──────┘        "open the logs" = full WCL replay (opt-in)
```
- Idle: policy holds a comfortable key, times reliably, farms while away. Active: clicking builds Momentum to beat
  the timer at keys above the idle ceiling → margin-based +1/+2/+3 climb (existing rule, key-40 clamp removed).
- Progression application moves out of the manual `CONFIRM_LOOT` reducer into a pure `resolveRunRewards()` shared
  by manual / auto-chain / offline paths (audit F3). The watch-gate/anti-spoiler system is removed for auto runs.

### 4.2 Momentum (the click)
- Click → (a) lead damage on current target (scales with a purchasable click-power axis, gold sink), (b) +1 Momentum
  stack. Stacks decay in **wall-clock** time when not clicking; converted to sim-time at the 36× rate (stacks must
  persist ~60–90 sim-seconds so they accumulate between clicks).
- Momentum multiplies party **output AND healing** — implemented at the effective-`power` level (like morale/
  aggression are today), NOT via `opOutputMult` (which heals ignore — audit F1). Without this, Momentum can't push
  survival walls and the active layer dies.
- Clicks enter the sim as a **recorded input stream** in `RunInput` → replay/verification stays deterministic.

### 4.3 Progression stack
| Layer | Holds | Fed by | Prestige | Register |
|---|---|---|---|---|
| **Guild tree** (big, sprawling) | global mults, click/Momentum upgrades, concurrent parties, offline rate, recruit ceilings, policy slots, loot quality | IK (+ gold early) | **persists** | meta / "numbers forever" |
| **Spec trees** ×10 (small) | build identity: ~8–10 passives + **5 stance sockets** (existing authored nodes) | Spec Mastery XP (running that spec) | **persists** | build choice |
| **Gear + aspects** | flat stats (loot chase) + transformative imprints | drops; shards to imprint | **resets** | active chase |
| **Operator skills** | auto-grind to hidden ceilings (existing Phase F system, unchanged) | run XP | **resets** (ceilings re-roll = seasonal recruit lottery) | idle/passive |
| *Run-time* | Momentum, tactics(→policy), aggression, stances-per-slot | — | — | play |

Division-of-labour rule: **raw "+% damage" belongs in the guild tree, never in spec nodes** (spec = qualitative
identity; guild = quantitative scale). Two trees stay additive, not redundant.

### 4.4 Spec trees (Atlas model) — Berserker is the template
- **Stance sockets = the existing 5 talent nodes** (3 options each, all 10 specs already authored + engine-wired +
  UI-editable). Migration: per-member `talents` picks → **per-party-slot stance picks** + shared per-spec unlock state.
- **Passive nodes (~8–10/spec, new):** enablers/smoothing, not % piles — e.g. Berserker: Rampage economy, slow decay
  between packs (idle), crit→Rampage, Momentum-synergy (+max Rampage while Momentum active), bleed spread on kill,
  execute-threshold, capstone = **+1 aspect slot**.
- Full unlock ≈ 15 Mastery levels (mid-game milestone); early game the decision is unlock ORDER, endgame the
  decision is stance configuration per party. Off-meta catch-up: benched specs earn reduced Mastery XP.

### 4.5 Aspects & the Codex
- `data/aspects.json`: id, scope (spec/class/generic), effect handler ref, magnitude tiers. Engine side = data-driven
  `special` handlers (same pattern as Bladestorm's 5-stack bleed) gated by an `imprint` field on `GearItem`.
- Launch pool: 8 Berserker (designed: Crimson Tide, Whirling Reaper, Unending Fury, Executioner, Bloodlust Eternal,
  Momentum's Edge, Berserker's Heart, Contagion) + ~3 generic per role. Pool grows post-launch.
- The Codex (discovered aspects) is **guild knowledge** — persists; the imprinted power is on gear — resets. Every
  season re-hunts drops and re-imprints known builds.

### 4.6 Guild layer & idle depth
- **Concurrent parties** (guild-tree unlock): N steppers ticking; a member can be in one party; each party runs its
  key-owner's keystone (per-member keys make multi-party elegant).
- **Auto-run policies:** key owner, comp template, stance/tactics/aggression preset, stop rules. **Default safety
  stop-rules** ship ON: "hold at last-timed key", "stop below morale X" — prevents the AFK deplete/wipe morale
  death-spiral (timed +10 / depleted −5 / wipe −20 compounds badly unattended).
- **Offline:** seed-chained resolution on return; closed-form estimator for bulk + real sims for the tail/highlight
  run (split decided by the IG-0.4 spike); "While you were away" report; offline rate is a guild-tree axis.
- **Biomes:** all 6 dungeons are fully authored and runnable (audit F7) — each IS a biome with a distinct mechanical
  read (interrupt / dispel / shield-priority / school-wall / attrition / burst). Activate the currently-unused
  per-dungeon `lootTable` field so each biome has curated loot → the *reason to choose* where to farm.

### 4.7 Prestige — The Patch
- Player-initiated at a wall (min-key gate). Resets/persists per D9. IK formula off best-key + throughput.
- Each Patch also rotates the affix season (ties into the ※ affix-swap/IP-scrub ticket).
- Pacing targets (validated in the economy harness): idle wall ~2–4h in; clicking worth ~+2–3 keys; first Patch
  ~3–5h; each meta layer visibly moves the wall.

### 4.8 Economy (sources → sinks; no dead currencies)
| Currency | Sources | Sinks (new in bold) |
|---|---|---|
| Gold | per-run (`200+40·key`, wipe 0) | **click-power upgrades, early guild-tree nodes, policy unlocks** (today: none — dead) |
| Shards | scrapping (8/item; auto-scrap at scale) | **aspect imprinting**, crafting (today: none — dead) |
| Emblems | per-run (5/2/0) + start 600 | recruiting (recurring via prestige re-recruit) |
| Spec Mastery XP | running the spec (reduced for bench) | spec-tree unlocks (persists) |
| **Institutional Knowledge** | The Patch (best-key + throughput) | guild tree (persists) |
- **Loot at scale:** auto-equip-upgrades + auto-scrap policies; only notable drops (aspect legendaries, big upgrades)
  surface as decisions; loot-drama barks fire on auto-distribution (the feed narrates your absence).
- All reward rates re-derived for idle run-volume (~50–100× today's manual cadence) — esp. operator XP
  (`34 × outcome × (1+0.08·key)`, 1.18^level curve maxes ceilings in ~a day of chained runs).

## 5. Audit findings that shaped this plan (2026-07-02 code audit)

| # | Finding | Consequence |
|---|---|---|
| F1 🔴 | Healing ignores the output-mult stack (`combat.ts:682` vs `:657`); high-key wall is survival-bound by design (`enemyDmgMult=1.5`, `intakeFloorFrac=0.4`, HP+dmg share one `1.05^(key−2)` scale) | Momentum-as-damage would be useless at the wall → D7 (heals scale) + D8 (two-knob split) |
| F2 🔴 | `tuning.loot` block + `morale.bands` are DEAD CONFIG; real economy hardcoded in `game-store.tsx` (drop ilvl `112+4·key` etc.); gold + shards have zero sinks | IG-0.6 tuning unification is a prerequisite for all balance work; §4.8 sink table |
| F3 🔴 | Loot/key/morale/XP applied only inside the watch-gated `CONFIRM_LOOT` reducer; engine `keyDelta` only feeds the legacy `FILE_REPORT` path | IG-0.5 `resolveRunRewards()` extraction + path consolidation |
| F4 🟡 | Manual loot distribution can't survive idle volume (2 drops × hundreds of runs) | IG-1.5 loot-at-scale |
| F5 🟡 | AFK morale death-spiral at the wall | IG-4.3 default safety stop-rules |
| F6 🟡 | `egm-smoke.mjs` is a fixed-scenario probe (no CLI/sweeps/seed-averaging); reward rates tuned for manual cadence | IG-2.3 economy harness is a from-scratch build; IG-2.4 re-derivation |
| F7 🟢 | All 6 dungeons fully authored/runnable (roadmap comment stale); per-dungeon `lootTable` exists unused; all 10 spec talent trees authored + engine-wired + UI-editable | 6 biomes day one (IG-6 needs 6 backdrops); stances are FREE content (IG-3 halves); IG-4.5 lootTable activation |
| F8 🟢 | Replay already runs at 36× (`CombatReplay.tsx RATE=36`); live key-delta is margin-based +1/+2/+3 clamp 2–40 | D13 time compression; keep margin climb, drop the 40 clamp |

## 6. Execution phases — tickets live in `ROADMAP.md` Phase IG

IG-0 Engine foundations (~1–2wk) → IG-1 Core loop transform (~2–3wk) → IG-2 Balance spine (~2wk + continuous)
→ IG-3 Spec trees + aspects (~2–3wk) → IG-4 Guild layer + idle depth (~2–3wk) → IG-5 Prestige (~1–2wk)
→ IG-6 Render + assets (~3–4wk, overlaps 3–5) → IG-7 Browser launch (~1–2wk). **v1.5:** Weekly Key + verified
leaderboards (thin server re-sims v1's run tickets — no client migration).

**Total ≈ 14–19 solo-dev weeks.** **Kill/continue gate = end of IG-2:** the economy harness must show the two-knob
model producing the idle/active gradient (idle wall, click = +2–3 keys, prestige moves the wall) BEFORE the
expensive content/art phases. IG-1 carries ONE hard save reset (`SAVE_VERSION` bump); every later phase is
additive + sanitize-on-load.

**Process:** roadmap update protocol + one commit per milestone (CLAUDE.md mandates) apply to every IG ticket.
Build gate: `tsc -b` + determinism suite + economy-harness spot-checks + Playwright live checks for UI.
**Pause further manual-run-flow polish** (Report/SetupPage etc.) until IG-1 lands — those surfaces get demoted/
repurposed (Report → "open the logs"; SetupPage → policy editor; LootPage → notable-drop queue).

## 7. Risks & open questions

- **R1 — Regime retune scope.** D8's two-knob split re-opens the P.5c calibration (which deliberately made the
  regime timer-bound at 1.5/1.05). All Class-Tools reads (P.0–P.5) must be re-verified in the harness after IG-2.1.
- **R2 — Click feel.** Input-buffered clicks (applied at next 0.25s DT tick) need instant client-side visual
  response decoupled from sim application, or the click feels dead.
- **R3 — Background-tab throttling.** Browsers throttle timers in hidden tabs; "tab open, farming" needs a
  batch-sim catch-up on `visibilitychange`, else it silently becomes offline mode.
- **R4 — Estimator honesty.** If the offline estimator drifts >~10% from real sims (aspects/stances complicate the
  closed form), fall back to more real-sim batches (IG-0.4 measures the budget).
- **R5 — IP scrub is a launch gate.** Browser launch makes the pre-launch IP blockers real (Extract/ reference,
  WoW-adjacent strings, purchased-asset licenses). IG-7.2 is a hard gate, and every asset purchase logs its license.
- **R6 — Balance surface.** 10 spec trees × stances × aspects × guild tree: launch waves (Berserker + 4 specs fully
  passive-treed at v1; the rest post-launch) rather than all-10-day-one.
- **Open:** exact IK formula; aspect drop rates; whether tactics points survive as a policy knob or fold into
  stances entirely; telemetry stack (existing open decision D.10 applies to the browser build).
