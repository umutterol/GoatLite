# GOAT Lite — Production Roadmap & Tracker

**This is a LIVING document. It is the single source of truth for what's left to ship.**
Owner: Producer (Claude). Companion analysis: `EGM-Reference-Analysis.md`, `DataModel.md`, GDD `GDD.md`.

> ### ⚠️ Update protocol (mandatory — do not let this file go stale)
> Whenever a roadmap task is **started, finished, blocked, re-scoped, or added**, in the SAME session:
> 1. update that task's **Status** (and Notes), and
> 2. add a dated line to the **Changelog** at the bottom.
> When a design decision is made, move it from Open Decisions to **resolved** with the answer.
> The tracker reflecting reality is a hard requirement, not a nicety. We work **phase by phase**, top-down.

**Status legend:** ⬜ Todo · 🟡 In progress · ✅ Done · 🔴 Blocked · 💤 Deferred (out of current scope)

---

## Snapshot (as of 2026-06-15)

GOAT Lite = strong design + complete content **data** + a UI now backed by a **working simulation engine**:
a deterministic Ashveil key is playable (the replay screen runs a real `runDungeon()`). Runtime loop, save,
and the rest of the screens are still ahead. EGM (the maturity bar) is a finished game (233 scripts, full tick
sim, 30+ wired screens, save/load, original art + audio).

Maturity vs a finished game: Design ~90% · Data structure ~85% · Content depth ~15% · UI ~18% ·
**Engine/runtime ~45%** (combat sim + playable persistent loop done; gear/recruitment/more screens next) · Assets ~5% · Systems implemented ~20%.

**▶ NOW:** Phase B continued — playable loop + gear progression done, and the Combat Replay reworked into a flowing Warcraft-Logs-style playback (live class-coloured DPS meter + hoverable event tooltips). Remaining: loot-drama modal (B.5), talent picker (B.7), recruitment UI (B.9), and the remaining screens (B.10, B.11).
**NEXT:** finish Phase B, then Phase C — content scale-up.

| Phase | Theme | Progress |
|---|---|---|
| 0 | Foundation (design, data, UI mockup) | ✅ 4/4 |
| A | **Engine — make it a game** | ✅ 12/12 |
| B | **Runtime loop & persistence** | 🟡 6/11 |
| C | Content scale-up | ⬜ 0/7 |
| D | Systems depth | ⬜ 0/9 |
| E | Production (art, audio, polish) | ⬜ 0/7 |

---

## Phase 0 — Foundation ✅

| # | Task | Status | Notes |
|---|---|---|---|
| 0.1 | Design spec | ✅ | GDD Concept v1.10, EGM-informed, locked |
| 0.2 | Content data layer | ✅ | 26 domains, Zod schemas, cross-ref validator (`/data`, `web/src/content`) |
| 0.3 | UI mockup + theme + sourced assets | ✅ | 3 screens, aged-scroll theme, warcraftcn + game-icons (placeholder) |
| 0.4 | EGM reference + maturity gap analysis | ✅ | this roadmap is the output |

## Phase A — Engine: make it a game ⬜ (critical path)

*Goal: a deterministic TypeScript tick-sim that runs an Ashveil key to a `RunResult`, wired into `CombatReplay`.*

| # | Task | Axis | Sev | Effort | Status | Notes |
|---|---|---|---|---|---|---|
| A.1 | Seeded PRNG + deterministic harness | engine | blocker | S | ✅ | `sim/rng.ts` mulberry32; same seed → identical run (verified) |
| A.2 | Role-model character math | engine | blocker | S | ✅ | coefficients from `tuning.json` roleModel; morale band + aggression applied |
| A.3 | Tick loop over 8 stages → `RunResult` | engine | blocker | L | ✅ | `sim/engine.ts`; trash/boss stages; timed/depleted/wipe |
| A.4 | Damage pipeline + Hit Quality | engine | blocker | L | ✅ | ratio armour, morale band, aggression; crit/glance sampled (full per-attack rolls = later polish) |
| A.5 | Tactics-point resolution | engine | blocker | M | ✅ | 4 categories wired; bad allocation → wipes, good → survives (verified) |
| A.6 | Affix mechanics (8) | engine | blocker | M | ✅ | all 8 wired; Bolstering responds to Kill Order, Raging to Cooldowns, Sanguine heals the pack; each boss audits its own tactic |
| A.7 | Healer mana/OOM + death/wipe | engine | blocker | S | ✅ | 2-healer OOM model; die at 0 HP; all-down = wipe + loot forfeit |
| A.8 | Timer, "Calling the Run", soft-enrage | engine | major | S | ✅ | timer + outcome; soft-enrage (90s/stage ramp); Calling-the-Run via `stopAfterStage` (verified: call@4 → early deplete) |
| A.9 | Behavior-profile target AI | engine | major | M | ✅ | profiles read; Peel/tank Spiteful-pickup counterplay. Full per-combatant profile AI + sticky-target = Phase-2 fidelity (GDD defers profiles from MVP) |
| A.10 | Event-log + `RunResult` generation | engine | major | L | ✅ | typed log + flavor from `log-templates.json`; parse + death report |
| A.11 | Wire `CombatReplay` to real sim | ux | blocker | M | ✅ | live `runDungeon()`; real log/parse/HP/deaths + Re-run button |
| A.12 | Validate vs Dungeon Timer acceptance test | engine | major | M | ✅ | clear-time matches table (+8≈71%/+12≈86%/+15≈100%); curve sensible (balanced clean→+15, deplete~+17, wipe~+19; starving the week's key tactic wipes). Live-tuning continues as content/gear curves firm up |

## Phase B — Runtime loop & persistence ⬜

| # | Task | Axis | Sev | Effort | Status | Notes |
|---|---|---|---|---|---|---|
| B.1 | `GameState` runtime model | engine | blocker | L | ✅ | `src/state/game-store.tsx` — mutable roster/wallet/keystone/week via React context + reducer; screens read live state |
| B.2 | JSON save/load + versioned migrator | engine | blocker | M | ✅ | localStorage JSON + version field; **verified persist across reload**; migrator is a reset-stub (full stepwise migrator later) |
| B.3 | Keystone progression (±1) + week/affix advance | engine | blocker | M | ✅ | timed +1 / depleted+wipe −1 (floor 2); week affixes pulled from the season calendar; `advanceWeek` action |
| B.4 | Full loop wiring | engine | blocker | M | ✅ | party picker → tactics → run → review → File Report applies it → repeat. Verified end-to-end via UI + store |
| B.5 | Loot generation + assignment + loot drama UI | engine/ux | major | M | 🟡 | generation → real gear items in the stash + equip assignment done (B.8); only the contested-item **loot-drama** modal (two members want the same drop) is still pending |
| B.6 | Morale runtime (events, bands) | engine | major | M | ✅ | morale events applied on result (timed +10 / depleted −5 / wipe −20); 3-band output already in the sim |
| B.7 | Talent picker UI + per-member persistence | ux | major | M | ⬜ | 2 MVP nodes; saved per roster member. **Skill content now exists** (`data/skills.json`, 60 original-GOAT skills via `content.skills`) to draw from |
| B.8 | Gear / 6-slot inventory + assignment | ux | major | L | ✅ | real gear items (uid/baseId/ilvl/rarity) in a guild stash; per-member 6-slot paper-doll; **char ilvl = slot avg → feeds the sim**; spec-tag-validated equip with upgrade deltas; Character Sheet screen (click a roster card). Verified: equip raises ilvl, runs loot the stash, persists |
| B.9 | Recruitment runtime + Initial Draft UI | ux | major | L | ⬜ | 3 tabs, pick 5, pity floor; ongoing sources |
| B.10 | Remaining core screens | ux | major | L | ⬜ | mission/keystone board, post-run summary, main menu, character sheet, level-up/potential reveal, vault |
| B.11 | Mid-run state persistence | data | minor | M | ⬜ | save/resume a run; cancel with loot at risk |

## Phase C — Content scale-up ⬜

| # | Task | Axis | Sev | Effort | Status | Notes |
|---|---|---|---|---|---|---|
| C.1 | Dungeons 2–6 | content | major | XL | ⬜ | each: bosses, packs, enemies, loot table, items, signature mechanic |
| C.2 | Per-spec talent trees | content | major | XL | ⬜ | 10 specs × 5 nodes ≈ 150 options |
| C.3 | Enemy roster breadth | content | major | XL | ⬜ | ~50–70 total (have 7) |
| C.4 | Item breadth + secondary pool tuning | content | major | L | ⬜ | ~60–72 items (have 12) |
| C.5 | Tier-set content | content | minor | M | ⬜ | 10 sets, 2pc/4pc + piece assignment |
| C.6 | Full affix calendar / season content | content | minor | S | ⬜ | season.json calendar exists; expand + finalize |
| C.7 | Earned-trait event pools (full trigger detail) | content | major | M | ⬜ | 4 pools designed; firm up trigger thresholds |

## Phase D — Systems depth ⬜

| # | Task | Axis | Sev | Effort | Status | Notes |
|---|---|---|---|---|---|---|
| D.1 | Earned-trait triggers + unlock | engine | major | L | ⬜ | probabilistic event gates, key-level gated |
| D.2 | Morale departure (flip flag) + absorption | engine | major | M | ⬜ | leave-at-0 roll; recruitment keeps pace |
| D.3 | Crafting runtime + economy | engine | major | M | ⬜ | reforge/augment/scrap/corrupt; transparent odds |
| D.4 | Gold sinks + building costs/unlocks | design/engine | major | M | ⬜ | gold currently has no spend |
| D.5 | Potentials reveal runtime | engine | major | M | ⬜ | hidden-but-active; 50% reveal on trait earn |
| D.6 | Leaderboard + accounts + server re-sim | design/engine | major | XL | ⬜ | identity, friend/guild grouping, integrity |
| D.7 | Trait↔sim reconciliation + Net Budget tuning | data | minor | L | ⬜ | audit every trait vs real sim |
| D.8 | Haste/Mastery sim hooks | data | minor | M | ⬜ | currently undefined |
| D.9 | Capture→rescue + scar-count death ramp | content | minor | XL | 💤 | deferred; revisit post-Phase-2 (GDD Open Questions) |

## Phase E — Production (art, audio, polish) ⬜

| # | Task | Axis | Sev | Effort | Status | Notes |
|---|---|---|---|---|---|---|
| E.1 | Original character portraits | assets | blocker | XL | ⬜ | recommend class-based + rarity variants (EGM approach); replaces borrowed warcraftcn |
| E.2 | Monster/boss art | assets | blocker | XL | ⬜ | 0 encounter visuals today |
| E.3 | Dungeon/environment art | assets | major | XL | ⬜ | CSS parchment only today |
| E.4 | Audio (music + SFX) | assets | major | XL | ⬜ | zero today; min. hub theme + combat theme |
| E.5 | Ability/affix iconography + item art | assets | major | M | ⬜ | replace game-icons CC-BY with originals; rarity borders |
| E.6 | Branding / title / favicon | assets | minor | S | ⬜ | no title screen/splash today |
| E.7 | Mobile, accessibility, settings/hotkeys | ux | minor | M | ⬜ | desktop-only today |

---

## Open Design Decisions (resolve before/while building the dependent task)

| Decision | Blocks | Status | Resolution |
|---|---|---|---|
| Tick rate: 0.1s (EGM) vs 1s (GDD) | A.3 | ✅ Resolved | **1s** — engine ships on 1s ticks; `tuning.sim` constants (hpUnit/dmgUnit) calibrated to the GDD timer table |
| Client-only vs isomorphic sim | A.1, D.6 | ⬜ Open | leaderboard re-sim wants shared TS sim |
| Gold sinks / economy balance | D.4 | ⬜ Open | gold has no spend yet |
| Haste & Mastery effects | D.8 | ⬜ Open | stats defined, mechanics unspecified |
| Recruitment Board "guild progression" metric | B.9, D.6 | ⬜ Open | which lever scales recruit quality? |
| Dungeon Rescue trigger + departure absorption | D.2 | ⬜ Open | when does a rescue spawn; supply vs departures |
| Affix calendar: fixed cycle vs weekly roll | C.6 | ⬜ Open | infinite key treadmill needs an affix meta |
| Keystone targeting in Phase 2 | B.3 | ⬜ Open | random re-roll vs player choice |
| Capture→rescue + scar ramp scope | D.9 | 💤 Deferred | is permadeath real or flavor? |
| Leaderboard integrity / accounts / anti-cheat | D.6 | ⬜ Open | client-inspectable save trust model |
| Per-spec morale bonuses | B.6 | ⬜ Open | all specs vs a few archetypes |

---

## Changelog

- **2026-06-15** — **Combat log: tank-damage + healer-heal events, and per-skill hover tooltips.** The log now also
  emits **tank damage** ("Grymdark damages Bone Acolyte with Shield Bash for …") and **healer heal** events
  ("Svenrik heals Bramblewen with Greater Heal for … Healing", green) — heals fire only when an ally is actually
  hurt; both are RNG-free so the balance curve is byte-identical (+12/+13 timed → +14 depleted → +15 wipe). Each
  log line carries the resolved **`skillId`**, and the unified per-line tooltip was **replaced with a per-element
  one**: hovering the (dotted-underlined) skill word shows ONLY that skill's card — name, category, flavour
  description, **formula** (e.g. `40 + 70% AGI`), cooldown, target, and school — pulled from `content.skills`.
  Other tokens no longer pop a tooltip. Verified via Playwright (tank/heal lines present, skill tooltip renders,
  no console errors); `tsc -b` + `npm run build` green.
- **2026-06-15** — **Event log now reads as a Warcraft-Logs combat log.** The replay emits steady WCL-style
  damage events in the form **"`<Char>` damages `<Enemy>` with `<Skill>` for `<N>` Damage"** — naming the actual
  focused enemy (Bone Acolyte, Sexton Caldew, Othrend…), the actor's real GOAT spec skill (Scorch, Poisoned
  Blade…), and an amount (crits flagged `✦ Crit`). Rendered as class-coloured combat-log segments (source +
  skill in class colour, enemy in hostile red, amount bold/gold), interleaved with the satirical mechanic/death/
  flavour lines. Damage events are **RNG-free (tick-indexed)** so the seeded sim stream — and the balance curve
  — is unchanged; benchmark across seeds confirms a clean monotonic ramp (+12/+13 timed → +14 depleted → +15
  wipe). ~350 damage events per key. `npm run build` + `tsc -b` green; verified via Playwright (real enemy/skill
  names, no console errors).
- **2026-06-15** — **Original-GOAT player skills wired into content + replay (60 skills).** Imported
  `Docs/PlayerSkills.csv` (the original GOAT spell roster) as a new first-class content domain
  `data/skills.json` (60 skills, one per row): `SkillSchema` added to the content schema, indexed +
  cross-ref-validated in `content/index.ts` (every skill's `classId`/`specId` must resolve), and exposed as
  `content.skills`. The CSV's `Specialization`/`Class` columns map 1:1 onto our 10 specs / 5 classes. **Deliberately
  did NOT port the turn-based formulas** (`40 + 60% STR`, CDs-in-turns, Rampage/Burn stacks, per-turn DoTs) into
  the 1s-tick sim — they'd break it; formula/CD/baseValues are kept as **reference metadata only**. The replay now
  shows **real skill names**: crit log lines pick the actor's spec-appropriate Damage skill (e.g. Assassin →
  Ambush / Eviscerate / Shadow Step / Poisoned Blade), surfaced as an inline class-coloured chip and as the WCL
  tooltip headline. The picker is RNG-free (indexed by tick) so sim determinism/balance is unchanged. This also
  seeds the future **talent picker (B.7)** with real skill content. Verified: content validates at runtime (no
  throw), 9 roster cards render, real names flow into the log, `npm run build` + `tsc -b` green.
- **2026-06-15** — **Combat Replay reworked into a Warcraft-Logs-style playback (replay UX polish).** The replay
  no longer dumps results instantly — the event log now **flows over a playback clock** with play/pause, a
  click-to-seek scrubber (death markers + cursor), and a functional 0.5/1/2/4× speed dial; the outcome badge is
  withheld until the run finishes (a live timer + "● simulating" shows during playback). The parse overlay is now
  a **live class-coloured DPS meter** ("Damage Done"): bars recompute from a new per-tick cumulative **damage
  series** as the clock advances, sorted high-to-low, in canonical **WoW class colours** (Warrior tan / Paladin
  pink / Rogue yellow / Mage cyan / Sage→Druid orange) with DPS + % of raid. Every log line is **hoverable** with
  a WCL-style tooltip (timestamp · class-coloured source · ability · amount · target · result · flavour) and a ▷
  "jump to this moment" control. Engine changes: `RunResult` gained `series`/`seriesIds`/`partyMeta`, and key log
  lines (crits, boss mechanics, affixes, deaths, OOM) now carry structured `meta` for the tooltips; new
  `CLASS_COLOR`/`specColor()` map in `data/game.ts`. Verified via Playwright: 64-line run, 50 lines with meta,
  1417-row series, 5 distinct class-coloured bars, no console errors. `npm run build` green.
- **2026-06-15** — **Gear & inventory done (B.8) — progression loop closed (Phase B 6/11).** Real `GearItem`
  instances (uid/baseId/slot/specs/ilvl/rarity); a guild **stash**; each roster member has 6 equipment slots
  (starter "Worn" gear at their sample ilvl), and **character ilvl = average of equipped slots → feeds the sim**
  (better gear = stronger runs = higher keys). New **Character Sheet** screen (click any roster card): paper-doll
  + a spec-tag-filtered stash with upgrade deltas and one-click equip; loot now drops real items into the stash
  (save bumped to v2). Verified: equipping a +170 cleaver raised Dolgrun 160→162, a timed run added 2 items to
  the stash, and gear persisted across reload. Only the contested-item loot-**drama** modal remains on B.5.
- **2026-06-15** — **Phase B started — the game is playable & persistent (5/11).** Built `src/state/game-store.tsx`
  (React context + reducer): mutable `GameState` (roster, wallet, keystone, week), localStorage save/load with a
  version field, and actions (`runKey`, `fileReport`, `advanceWeek`, party select, `newGame`). Refactored TopBar +
  all 3 screens to read live state; `RunSetup` now has a real **party picker** and launches the run; `CombatReplay`
  plays the stored `RunResult`; **File Report applies it** — keystone ±1 (floor 2), morale events (timed +10 /
  depleted −5 / wipe −20), loot generation (items off the loot table + emblems/gold). Verified end-to-end via UI
  and store: ran a +12 → TIMED → keystone 12→13, +5 emblems, +680 gold, +10 morale, loot logged, and **state
  survived a page reload** (localStorage). B.1/B.2/B.3/B.4/B.6 ✅; B.5 🟡 (generation done, assignment/drama UI
  pending). Dev-only `window.__game` store handle added. Full `npm run build` green.
- **2026-06-15** — **Phase A complete (12/12).** Finished the four remaining engine items: all 8 affixes
  wired (Bolstering ← Kill Order, Raging ← Cooldowns, Volcanic damages / Sanguine heals the pack, plus
  Fortified/Tyrannical/Bursting/Spiteful); **each Ashveil boss now audits its own tactic** (Caldew→Kill Order,
  Vesk→Interrupts, Unmourned→Positioning, Othrend→Cooldowns) instead of every boss testing Interrupts;
  soft-enrage (90s/stage ramp); Calling-the-Run via `stopAfterStage` (verified early-deplete); behavior-profile
  Peel/Spiteful counterplay. Calibrated the death curve: balanced spread clears clean to ~+15, depletes ~+17,
  wipes ~+19; starving the week's punished tactic (Kill Order on a Bursting week) wipes; Safe slow-but-safe vs
  Yolo fast-but-risky. Fixed a `defaultRunInput` bug dropping `stopAfterStage`. Full `npm run build` green.
- **2026-06-15** — **Phase A kicked off — simulation engine built & wired.** Added `web/src/sim/`
  (`rng.ts` seeded PRNG, `types.ts`, `engine.ts` tick loop, `index.ts` API). `runDungeon()` runs a real Ashveil
  key from the content data → `RunResult`; `CombatReplay` now plays a live simulated run (real event log, parse,
  HP, deaths, Re-run button). Verified: deterministic per seed; clear-time curve matches the GDD timer table
  (+8≈71%/+12≈86%/+15≈100%); tactics + aggression measurably change outcomes (good tactics survive a Bursting
  week, starved Interrupts/Kill Order wipe; Safe slow-but-safe vs Yolo fast-but-risky); seeds vary under
  pressure. Marked A.1/A.2/A.3/A.4/A.5/A.7/A.10/A.11 ✅; A.6 (3 of 8 affixes fully wired), A.8 (timer done;
  soft-enrage + Calling-the-Run pending), A.9 (focus-fire done; profiles pending), A.12 (clear-time calibrated;
  death-balance tuning ongoing) → 🟡. Resolved the tick-rate decision (1s). Fixed a latent `TuningSchema.loot`
  validation bug surfaced by running the app (the audit-added `keyBands`/string formulas were rejected by a
  number-only record). Added a dev-only `window.__gl` sim handle in `main.tsx` (stripped from prod).
- **2026-06-15** — Roadmap/tracker created (Producer). Phase 0 marked done; Phases A–E + open decisions
  populated from the six-lens EGM maturity gap analysis. Consolidated the standalone `MaturityRoadmap.md`
  analysis into this living tracker.
