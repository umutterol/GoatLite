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

## Snapshot (as of 2026-06-19)

GOAT Lite = strong design + complete content **data** + the **"Logs" (WCL/Raider.io-style) UI** running on a
**real per-hit combat engine**. Since the 06-15 snapshot the whole combat sim was **rebuilt on the EGM damage
model** (Phase A2) — abilities/passives/specials, front/back bands, affixes/tactics/boss-mechanics — **wired into
the live app and balance-calibrated**. The persistent loop runs end-to-end: per-member keystones → party →
run → WCL replay → loot → progression → reports history. Still ahead: art/audio, content scale-up, talent picker,
leaderboard. EGM (the maturity bar) is a finished game (233 scripts, full sim, 30+ screens, save/load, art+audio).

Maturity vs a finished game: Design ~90% · Data structure ~88% · Content depth ~15% · UI ~45% ·
**Engine/runtime ~75%** (real per-hit engine live + balanced; full persistent loop + per-member keys + reports
history done) · Assets ~5% · Systems implemented ~40%.

**▶ NOW:** Phase A2 (EGM engine rebuild) **complete and live**; Phase B essentially done (per-member keystones,
editable New-Run party, reports history with deterministic replay all shipped). Remaining B gaps: loot-drama modal
(B.5), interactive talent picker (B.7), mid-run persistence (B.11).
**NEXT:** finish the B gaps, then Phase C (content scale-up). (Leaderboard/backend is a separate workstream, not yet tracked here.)

| Phase | Theme | Progress |
|---|---|---|
| 0 | Foundation (design, data, UI mockup) | ✅ 4/4 |
| A | Engine v1 (old flat-power sim) | ✅ 12/12 — **superseded by A2** |
| A2 | **Combat engine rebuilt on EGM model** | ✅ 7/7 (live + balanced) |
| B | **Runtime loop & persistence** | 🟡 12/14 |
| C | Content scale-up | ⬜ 0/7 |
| D | Systems depth | ⬜ 0/9 |
| E | Production (art, audio, polish) | ⬜ 0/7 |
| F | **Endgame & Identity (operator skills)** | ✅ 6/6 — live + balanced (operator runway ≈ +3 keys; +2 floor holds) |
| G | **Visual pass (icons + squared corners)** | 🟡 3/4 — G.1–G.3 done (`--radius` token, `<GameIcon>` registry, role/spec/tactic icons wired); G.4 = new art |
| H | **Combat depth (per-spec majors + talents)** | ✅ 4/4 — 10 majors live + talents 3–5 wired + rebalanced |
| I | **2D replay (abstract packs)** | 🟡 3/4 — I.1–I.3 done (engine `ReplayTimeline` + SVG canvas + replay-led report layout); I.4 partial (floats/flashes/death-anim in; status pips deferred) |
| J | **Feedback & polish batch (10 user reports)** | ✅ 10/10 — shipped + live-verified (`Post-F-Clusters-Plan.md` Cluster J) |
| K | **Combat AI rework (v2)** | ✅ 6/6 — shared priority-rules brain (players + enemies), data-driven profiles, tactics-as-orders, 20-agent adversarial review (3 fixes) |
| ※ | **Affix swap (original season, IP scrub)** | ⬜ 0/1 — **design ✅** (ready to apply) |
| L | **Roster expansion — Marksman + Necromancer** | ⬜ 0/7 — **design ✅** (`MMO-Nostalgia-Reference.md` §6) |
| M | **Guild Feed & Loot Drama (social meta-layer)** | ⬜ 0/5 (+1 v2) — **design ✅** (this session): always-visible meta feed, system notifications + solo barks, loot drama wired in |
| N | **Intake balance (`enemyDmgMult`) + sim-dump tooling** | ✅ 2/2 — enemy damage is now an **isolated** intake lever (=2.0); survival binds below the timer wall; +2 floor + operator runway (+3) hold; new config/CLI `sim-dump` harness |

---

## Phase 0 — Foundation ✅

| # | Task | Status | Notes |
|---|---|---|---|
| 0.1 | Design spec | ✅ | GDD Concept v1.10, EGM-informed, locked |
| 0.2 | Content data layer | ✅ | 26 domains, Zod schemas, cross-ref validator (`/data`, `web/src/content`) |
| 0.3 | UI mockup + theme + sourced assets | ✅ | 3 screens, aged-scroll theme, warcraftcn + game-icons (placeholder) |
| 0.4 | EGM reference + maturity gap analysis | ✅ | this roadmap is the output |

## Phase A — Engine: make it a game ✅ (SUPERSEDED by Phase A2)

*Goal: a deterministic TypeScript tick-sim that runs an Ashveil key to a `RunResult`, wired into `CombatReplay`.*
*Note: this v1 engine (`web/src/sim/engine.ts`, flat-power model) shipped and was later **replaced** by the EGM-model
engine (Phase A2). It's kept as `runDungeonLegacy` for rollback. The A.x rows below are historical.*

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

## Phase A2 — Combat engine rebuilt on EGM model ✅ (the real engine)

*Goal: replace the fake flat-power sim with a real per-hit damage engine modeled on EGM (decompiled reference) —
"EGM's damage pipeline, our content, a simpler scheduler." Hybrid skills, abstract front/back bands, continuous
seconds. New engine lives in `web/src/sim/egm/` (pipeline/stats/status/combat/engine). Spec: `Combat-EGM-Phase0.md`,
memory `combat-model-egm-migration`.*

| # | Task | Status | Notes |
|---|---|---|---|
| A2.0 | Data formats (abilities/statuses) | ✅ | `data/abilities-player.json` (60 abilities → typed effects), `data/statuses.json` (16 statuses); Zod schemas + cross-ref validated. Author in turns → engine runs seconds. |
| A2.1 | Stat-driven engine + damage pipeline | ✅ | `pipeline.ts` (dodge→crit→ratio-mitigation by type→damageTaken), `stats.ts` (real combat stats from ilvl+roleModel), `engine.ts` (continuous-seconds, DT=0.25, per-sec snapshots). Produces the same `RunResult` shape. |
| A2.2–3 | Abilities + statuses + buffs/CC/shields | ✅ | rotation (selectAbility/executeAbility), damage/heal/applyStatus, DoT/HoT, buff/debuff stat-mods, CC enforcement (stun/silence/daze/freeze), shields, cleanse, conditions/modifiers. |
| A2.3.5 | Passives + ~all special mechanics (3 waves) | ✅ | on-hit/crit/kill hooks + 10 passives (Bloodlust/Cold Blood/Stalwart/Combustion/Divine Insight/Nature's Grace/Inner Peace/Thorns/Arcane Mastery/Inspiring Presence) + ~30 specials (detonate/splash/atonement/redirect/immunity/parry/empower/barrier-break/blossom/etc.). Two turn-scheduler mechanics (Anthem/Crescendo) reworked into pure stat buffs to avoid a scheduler. Each wave adversarially reviewed. |
| A2.4 | Enemy front/back bands | ✅ | enemies carry `band`; band-aware targeting (Leg Sweep frontline, Poisoned Blade/Ambush dive backline for +30%); Thorns gated to melee attackers. |
| A2.5a | Affixes / tactics / boss mechanics reconnected | ✅ | all 8 affixes (bursting/bolstering/spiteful/raging/volcanic/sanguine + tyrannical/fortified), 4 boss mechanics gated by audited tactic, tactics drive output (`outgoingMult`) + mitigate intake. Tactics measurably swing outcomes. |
| A2.5b | UI cutover + balance retune | ✅ | app `@/sim` now runs `runDungeonEGM` (legacy kept for rollback). Calibrated so the **standard 1T/1H/3D comp** at gear-appropriate ilvl hits the GDD timer table: +2 floor 16/16 timed → +8 comfortable → +15 a geared-1H squeak; drops scale with key (`112+4·key`); deaths cost 15s; combat-rez charges (1 + 1/5min, all-down = wipe). Verified live (Playwright) + headless sweeps. |

## Phase B — Runtime loop & persistence 🟡 (12/14)

| # | Task | Axis | Sev | Effort | Status | Notes |
|---|---|---|---|---|---|---|
| B.1 | `GameState` runtime model | engine | blocker | L | ✅ | `src/state/game-store.tsx` — mutable roster/wallet/keystone/week via React context + reducer; screens read live state |
| B.2 | JSON save/load + versioned migrator | engine | blocker | M | ✅ | localStorage JSON + version field (now v4); reset-on-mismatch; **plus sanitize-on-load** (backfills any member missing `.key`, drops legacy non-ticket history) — added after a shape-change crash. Full stepwise migrator still later. |
| B.3 | Keystone progression + week/affix advance | engine | blocker | M | ✅ | **margin-based** (timed +1/+2/+3 by timer margin, deplete/wipe −1, floor 2); week affixes from the season calendar. Now **per-member** (see B.12) — each key levels independently on its owner's run. |
| B.4 | Full loop wiring | engine | blocker | M | ✅ | party picker → tactics → run → review → File Report applies it → repeat. Verified end-to-end via UI + store |
| B.5 | Loot generation + assignment + loot drama UI | engine/ux | major | M | 🟡 | generation → real gear items in the stash + equip assignment done (B.8). The **loot-drama** portion (contested-item resolution + consequences + barks) is **expanded and rehomed into Phase M** (M.2 mechanic, M.5 feed integration) — see that phase. |
| B.6 | Morale runtime (events, bands) | engine | major | M | ✅ | morale events applied on result (timed +10 / depleted −5 / wipe −20); 3-band output already in the sim |
| B.7 | Talent picker UI + per-member persistence | ux | major | M | ✅ | **2 MVP nodes** (Survival↔Throughput, Focus↔Spread), 3 choices each, shared by all specs — `data/talents.json` options gained machine-readable `effects` (maxHpPct / dmgPct + `onlyIf` gate). Engine applies them (buildParty maxHp mult + `passiveDamageMult` dmg mods); **interactive picker** in the Character sheet (replaces the old read-only auto-pick); saved per member, captured in the run ticket so replays are faithful. Nodes 3-5 stay prose-only until C.2. |
| B.8 | Gear / 6-slot inventory + assignment | ux | major | L | ✅ | real gear items (uid/baseId/ilvl/rarity) in a guild stash; per-member 6-slot paper-doll; **char ilvl = slot avg → feeds the sim**; spec-tag-validated equip with upgrade deltas; Character Sheet screen (click a roster card). Verified: equip raises ilvl, runs loot the stash, persists |
| B.9 | Recruitment runtime + Initial Draft UI | ux | major | L | ✅ | `RecruitPage`: opening draft (sign 5, emblem budget) + ongoing sign/confirm/reroll; recruits arrive with starter gear + their own +2 key. Pity floor / deeper ongoing sources basic. |
| B.10 | Remaining core screens | ux | major | L | ✅ | Logs reskin: Report (WCL replay), Keystone reveal, Roster, Character sheet, Loot, New Run (Setup), Guild-create, Recruit — all live. Deferred: Vault, level-up/potential-reveal screens (Phase D.5). |
| B.11 | Mid-run state persistence | data | minor | M | ⬜ | save/resume a run; cancel with loot at risk |
| B.12 | **Per-member keystones** | engine/ux | major | M | ✅ | each roster member holds & levels their own key (`RawMember.key`); New Run **key picker** (pick whose key to run; owner auto-locked into party); loot/progression key off the run owner. Random +2 on recruit (all Ashveil until Phase C). |
| B.13 | **Editable New-Run party** | ux | minor | S | ✅ | interactive roster picker (toggle in/out, 5-cap) built around the locked key owner; reuses TOGGLE_PARTY/SET_PARTY with owner-lock. |
| B.14 | **Reports history (replayable)** | ux | major | M | ✅ | every run stored as a tiny **RunTicket** (seed+inputs+party snapshot); ReportPage lists past runs (newest first) and **re-simulates on open** (deterministic — no bulky results saved); back-to-latest + loot-action gating. |

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

## Phase F — Endgame & Identity (operator skills) ⬜ (design ✅)

*Goal: a power axis that takes over after the gear cap (~ilvl 160 / key 12). Each bot's **operator** has 3 growable
skills (Execution / Awareness / Composure) that feed the sim; how high each grows is a **hidden Ceiling** = the bot's
**Potential** (unifies the GDD's locked Potentials with the new power layer — Potentials now set the ceilings AND still
bias earned-trait rolls). Traits become **personality + real combat modifiers** (today they're inert). Recruitment
becomes a scouting bet (Current rating vs fuzzy Potential ★) → fills the new recruit list + detail panel. Full spec:
`Docs/Operator-Skills-Design.md`. Pulls D.1 / D.5 / D.7 forward.*

| # | Task | Axis | Sev | Effort | Status | Notes |
|---|---|---|---|---|---|---|
| F.1 | Data + types: operator skill registry, `tuning.operator.*`, `RawMember` fields, trait schema (`combat`/`growth`), SAVE_VERSION→5 | data/engine | major | M | ✅ | `data/operator-skills.json` registry + `tuning.operator.*`; `OperatorSkill`/`TraitCombat`/`TraitGrowth` schemas + cross-ref; `RawMember.{skills,ceilings,skillXp,revealed,potentialProfile}`; helpers in `web/src/data/operator.ts`; SAVE_VERSION 4→5 + loadState backfill |
| F.2 | Sim wiring: `buildParty` applies operator multipliers + trait `combat` effects (traits currently inert) | engine | major | M | ✅ | `web/src/sim/egm/operator.ts` `resolveOperator`; Execution→output (`passiveDamageMult`), Awareness→**uniform** intake (per-member `intakeMult` in `dealDamage`), Composure→clutch (`partyInDanger` per step) + dodge; trait combat (output/intake/crit/hp) baked in `buildParty`. **Traits no longer inert.** Verified via `op-verify.mjs` (deltas + determinism + +2 floor); 1-finding adversarial review fixed (self-cost bypass) |
| F.3 | Growth (auto toward ceiling) + hard gear cap | engine | major | M | ✅ | post-run `applyGrowth` in `CONFIRM_LOOT` (role/trait-weighted, asymptotic to ceiling); `dropIlvl` caps at ilvl 160 (key 12); above-cap keys grant bonus operator XP (the gear→operator handoff) |
| F.4 | Recruitment generation: roll Ceilings from Potentials/class/traits; fuzzy reveal; COR + Potential★ | engine | major | M | ✅ | `makeRecruit` rolls hidden Potentials profile → ceilings → starting skills (veteran-frac by quality); fuzzy ~50% reveal mask; COR + Potential★ stored on the recruit. Reveal-on-earn hook dormant (earned-trait *triggering* deferred to D.1). Guild-progression→higher-ceiling-pool lever still a future nicety |
| F.5 | UI: recruit **list table** + **detail panel**; Character-sheet operator-skill section | ux | major | L | ✅ | RecruitPage rebuilt as a WCL **scouting board** (dense list + sticky detail): precise COR + fuzzy Potential★, skill bars (ceiling shaded where scouted, "?" where hidden), scout-report blurb, trait-combat summary. `OperatorPanel.tsx` (`SkillBars`/`Stars`/`corColor`/`scoutBlurb`). Character sheet gained an **Operator** panel (COR, ★, bars + XP-to-next, trait-in-combat). Built squared+iconned (G). Verified live (Playwright: scout board + char panel render, 0 console errors) |
| F.6 | Balance pass: tune per-point %s vs the timer curve | engine | major | M | ✅ | swept the key ceiling at the gear cap (`f6-balance.mjs`): **operator runway ≈ +3 key levels** (fresh +17 → maxed +20 @ ilvl160), **+2 floor still 6/6 timed** at starting gear. Starting per-point %s landed in-target; no retune needed (uniform-Awareness 0.5%/pt confirmed over the design's avoidable-only 1.5%) |

## Phase G — Visual pass (icons + squared corners) ⬜ (design ✅)

*Requests #4 (icon-ify text) + #5 (squared/WCL corners). Full spec: `Post-F-Clusters-Plan.md`. Do G.1–G.3 early —
they feed Phase F's recruit list/detail UI so it's built squared + iconned once. Subsumes part of E.5.*

| # | Task | Axis | Sev | Effort | Status | Notes |
|---|---|---|---|---|---|---|
| G.1 | Radius token: one `--radius` (~2px), replace the ~30 scattered values across 3 systems | ux | minor | S | ✅ | `--radius: 2px` in `logs.css`; all rectangular `border-radius` → `var(--radius)` (true circles exempt); `Stat`/F.5 use it. (A few onboarding-only inline radii, e.g. GuildCreate, remain — cosmetic follow-up) |
| G.2 | Typed `<Icon>` registry + missing-asset placeholder + `aria-label` convention | ux | minor | S | ✅ | `<GameIcon kind id/>` in `components.tsx` — mask-tinted assets with a **labelled placeholder** (initial-in-a-box) for not-yet-drawn art (skill/class/talent/trait/item/dungeon); every icon has `aria-label`. `ICON_ASSETS` manifest = drop file + add id |
| G.3 | Wire the **18 already-existing-but-unused** icons (spec/role/stat/tactic) into the live pages | ux | minor | M | ✅ | role icons in `RolePill` (→ recruit/roster/setup/character), tactic icons on New-Run dials, spec icons in roster + recruit board + char. Stat icons await secondary-stat displays (C.4/D.8) |
| G.4 | New-art seams (gated on user-supplied assets) — see manifest: dungeon banners, ability/talent/trait/item icons, 3 operator-skill icons, 8 re-cut affix icons | assets/ux | major | L | ⬜ | biggest lift = ~70 ability icons |

## Phase H — Combat depth (per-spec majors + finish talents) ⬜ (design ✅)

*Request #7 (each spec a proper major cooldown) + completing talent nodes 3–5 (the C.2 MVP gap). Decisions: role-templated
mechanics + unique flavor, ~60s CD, net-power then balance pass, mostly free-fire. 10 major concepts in `Post-F-Clusters-Plan.md`.*

| # | Task | Axis | Sev | Effort | Status | Notes |
|---|---|---|---|---|---|---|
| H.1 | Author 10 per-spec majors in `abilities-player.json` (`tags:["major"]`, ~60s; reuse effect types/SPECIALS) | content | major | M | ✅ | 10 majors (`cooldownTurns:20`=60s since secondsPerTurn=3), **fantasy MMO names** (the bots cast fantasy spells; QA flavor stays in the meta layer): Bulwark Banner / Sacred Bastion / Unmoving Mountain / Light's Salvation / Blossoming Tide / Reckless Frenzy / Killing Edge / Rallying Crescendo / Emberstorm / Nullifying Surge. All reuse existing effects/SPECIALS (no new handlers); mirrored into `skills.json` for tooltips (internal ids unchanged). Detonate gate narrowed so the pyro AoE fires without Burn. All 10 verified firing |
| H.2 | UI: surface the major in Character sheet + as a prominent replay/log event | ux | minor | S | ✅ | `SignatureCard` on the Character sheet (name + SpellTip) + gold "✦ MAJOR" accent on major cast lines in the replay log. Live-verified |
| H.3 | Finish **talent nodes 3–5** with machine-readable `effects`+`onlyIf` (closes C.2 MVP gap) | content | major | M | ✅ | extended talent effects schema with `intakePct`+`critPct` (wired in `resolveTalents`/`buildParty`; talent intakePct folds into the operator intake channel); nodes 3–5 got real effects + defaults. Picker now shows all 5 nodes |
| H.4 | Balance pass: baseline vs major windows; smoke sweeps hold the timer curve | engine | major | M | ✅ | majors + the now-5 talent nodes added ~+4 net power → nudged `keyScalingPerLevel` 1.043→1.052 to restore the curve (fresh ceiling +18, maxed +20 ≈ F.6; operator runway +2). +2 floor 6/6, determinism holds. Adversarial review (35 agents) → 4 findings, 2 fixed (Zen Mode counter over-scale; `usable()` gate narrowed so Zen Mode/Hotfix fire at full HP) |

## Phase I — 2D replay (abstract packs) 🟡 (3/4 — I.4 partial)

*Request #2. One backdrop, packs spawn in sequence, front/back rows, HP bars + status pips, scrubber synced to the log.
No spatial arena (sim has no positions). Heaviest cluster; needs G's dungeon backdrops. Full spec: `Post-F-Clusters-Plan.md`.
Built this session; user layout: replay leads the report with the summary header + live meter overlaid INSIDE the canvas.*

| # | Task | Axis | Sev | Effort | Status | Notes |
|---|---|---|---|---|---|---|
| I.1 | Engine emits `ReplayTimeline` on `RunResult`: stage/pack/boss events + per-mob spawn/death/HP with stable seed IDs | engine | major | L | ✅ | `egm/engine.ts` emits `ReplayTimeline` (`types.ts`): stages with **real** start/end timing + per-mob spawn/death + per-second HP-fraction samples + stable ids `s{stage}m{i}` + front/back band. Hooked into `snapshot()` (whole-sec) + a stage-finalize block. **Additive: egm-smoke goldens BYTE-IDENTICAL** (884/914/1182/1367, 0 deaths) → zero balance impact. **Transient** (in the store `TRANSIENT` set → stripped from saves; recomputed from the ticket). `replay?` optional so the legacy engine's `RunResult` stays valid. |
| I.2 | Replay canvas (SVG/DOM): backdrop, party orbs, pack rows, HP bars, status pips, floating text | ux | major | L | ✅ | **v2 = faked-spatial arena** (reworked from band-rows after an EGM-decompile study — see the 2026-06-20 changelog): combatants are **dots on a dungeon-tinted field** (party = portrait dots in front/back columns by spec position; enemies = the active stage's mobs split front/back + centered boss) with **deterministic seeded positions + an idle bob** — the sim stays band-based, so positions are cosmetic/derived (no engine change). Per-dot HP bars; attacks fire as **SVG targeting lines + melee swipes + ranged projectiles + impact rings + arcing pop-in damage numbers**, derived from the log, windowed + **gated to playback** (scrub-safe). Width measured via ResizeObserver for px geometry. (Status pips still deferred — they need an additive per-combatant status emit.) |
| I.3 | Scrubber + transport synced to the log clock; "Replay" tab on ReportPage | ux | major | M | ✅ | ReportPage **re-laid-out top-down** per the user's spec: replay canvas on top with the **summary header overlaid top-LEFT** and the **live DPS/HPS meter overlaid top-RIGHT** *inside* the canvas (meter moved out of the right column); **timer adjuster** (play/speed dial/scrubber + death markers) directly **below**; then Event Log/Deaths/Casts + Party Health as usual. (Replay *leads* the report — not a separate "Replay tab".) |
| I.4 | Polish: death anim, mechanic/affix flashes, speed dial | ux | minor | M | 🟡 | **Shipped:** floating combat text + boss-mechanic/affix flashes + death bursts (skull). **Windowed event layer** — covers the ~5 sim-sec/tick clock skip (an `=== sec` gate dropped ~80% of events), plays only while PLAYING, enemy bursts read the FULL timeline so a boundary-killed mob still flashes. Speed dial pre-existed. **Deferred:** status/cooldown pips on orbs (per the build decision); float/burst anchors are name-keyed (exact-duplicate display names misroute — cosmetic nit, documented in `ReplayCanvas.tsx`). **Adversarial review** (4 review dims + per-finding verify, 14 agents → 10 findings → 6 confirmed): **all 6 fixed** (windowed event layer [major]; full-timeline enemy bursts [2× minor]; crit float-size dead branch [nit]; restored combat-rez recharge ETA dropped in the HUD compaction [minor]) bar the name-key nit. |

## Phase J — Feedback & polish batch ✅ (10/10)

*10 issues from playing the Phase-F build, each grounded in code (`Post-F-Clusters-Plan.md` Cluster J). All shipped + live-verified (Playwright, 0 console errors); `tsc -b` clean, `op-verify`/`egm-smoke` still green.*

| # | Task | Axis | Sev | Effort | Status | Notes |
|---|---|---|---|---|---|---|
| J.1 | Remove Horde/Alliance + realm from guild creation | ux | minor | S | ✅ | dropped FACTIONS/REGIONS UI + `GuildInfo.faction/region` + the 3 consumers (Roster/Report/Character) + `ReportView.region`/`buildReport` arg. No save migration (extra persisted fields ignored) |
| J.2 | Replay stops at the wipe (not full duration) | ux | minor | S | ✅ | `ReportPage` `playEnd` = last-death tSec +3 on `outcome==="wipe"`; playback loop + `finished` + paused-view cap to it |
| J.3 | Replay speed dial vs log reveal cadence | ux | minor | S | ✅ | each newly-revealed log line eases in via a `logIn` keyframe whose duration scales `0.42/speed` (slow at 0.5×, snappy at 4×) — the dial now visibly changes cadence |
| J.4 | Combat log shows enemy attacker name | ux | minor | S | ✅ | renderer now paints the source name even when it's not a party spec (enemy strikes) in a hostile tone — no engine change needed (the name was being sliced then dropped) |
| J.5 | Healing meter wired to real heals | engine/ux | major | M | ✅ | engine emits `healSeries` (cumulative `p.healDone`/sec) on `RunResult`; `analytics.healingWindow` slices it (deleted the fabricated `healingTable`). Verified non-zero per-healer + determinism intact |
| J.6 | Loot: ↑ for every upgrade + show current item | ux | minor | M | ✅ | `computeLoot` → `LootDrop.upgrades[]` (every eligible member + current ilvl + delta); `LootPage` shows ▲ + "cur → new (+Δ)" per candidate |
| J.7 | "Assassin problematic" → soften backline gate to a bonus | balance | major | S | ✅ | dropped `targeting.band:"back"` on Poisoned Blade + Ambush (kept the `targetBand back ×1.3` modifier) → hits the focus/kill-order target; dive is upside. No Ashveil balance shock; +2 floor + determinism hold |
| J.8 | Remove glow effects | ux | minor | M | ✅ | stripped all `0 0 blur color` glows — 3 in `logs.css` (brand-mark/btn-primary/radio) + 15 inline box/text-shadows across the pages; kept depth shadows + focus rings |
| J.9 | Battle-Res count + timer on report (not Rating) | engine/ux | minor | S | ✅ | `RunResult.finalRezCharges` + `nextRezChargeAtSec` emitted; report header "Combat Rez = N · +1 in m:ss / ready" |
| J.10 | Tooltips everywhere | ux | major | M | ✅ | reusable `<Tip>` (fixed-position portal) + `<TipBody>`/`<AffixChip>` on `GameIcon` (role/spec/tactic/affix/skill), affix chips, gear rows. **Event-log spell names are bold+underlined → hover pops a WoW-style `SpellTip` at the cursor** (cd/target/school/formula + yellow desc, no SpellID). Plus the combat log was reworded to possessive style ("X's Spell hits Y for N School.(Critical)", inline amounts). Custom, not Radix |

## Phase K — Combat AI rework (v2) ⬜ (design ✅ — `Combat-AI-Design.md`)

*One **shared brain** for players AND enemies: each turn decides *what* + *who* by walking an ordered list of **behaviour
primitives** (priority rules + utility tiebreak — legible/deterministic, not opaque utility AI). **Data-driven profiles**
(JSON composing code primitives, extending the inert `behavior-profiles.json`) so future enemies are data, not code. The
**tactics dials become the party's AI orders**, and operator/aggression/trait become modifiers. v1 = core brain + role/spec
+ tactics-as-orders (aggression / operator-as-competence / trait-as-personality / threat model / real interrupt cast-bars /
boss-script integration are fast-follows). Full design + open questions in `Combat-AI-Design.md`.*

| # | Task | Axis | Sev | Effort | Status | Notes |
|---|---|---|---|---|---|---|
| K.1 | Brain scaffold + behaviour primitive kit + profile schema | engine | major | L | ✅ | `decideAction`/`decideEnemyTarget` single decision points in `combat.ts` walk a profile-resolved behaviour list (`brainOf`); default `dumpRotation`/tank-focus reproduce current play; `Combatant.profile` wired (spec defaultProfile / enemy melee\|caster); `BehaviorProfileSchema` gained optional `base`+`behaviours` (K.5 populates). **Byte-identical proven** — egm-smoke matches golden (798/868/1068/1202) + op-verify determinism 6/6, `tsc` clean |
| K.2 | Player rotation behaviours | engine | major | M | ✅ | `holdForWindow` (defensive majors wait for danger/boss; offensive majors fire on boss/≥3-pack — no more dumping on a straggler), `triageHeal` (healer casts the heal SIZED to the injury, skips near-full allies → fixes Flash-vs-Greater overheal), `emergencyDefensive`, `dumpRotation` now excludes majors. Verified: healer mixes Flash 84×/Greater 68× (was always-Greater), +2 floor 6/6, determinism holds, **ceiling unchanged (+18/+20) → no nudge needed** |
| K.3 | Player + enemy target selection | engine | major | M | ✅ | `TARGET_BEHAVIOURS`: party `focusByPriority` (kill back-band casters first, focus-fire), `focusLowestHp` (executioner snipe), `focusHighestHp` (tunnel-vision tank) — profile-driven; enemy `caster`→`focusSquishy` (dive non-tank back-line), melee/adds→`focusTank`. Wired into `targetsFor` single-target + `basicAttack` + `decideEnemyTarget`. Verified: casters now hit squishies (180× non-tank / 0× tank), +2 floor 6/6, determinism holds, ceiling back to fresh +17/maxed +20/runway +3 (≈ F.6) — no nudge. (peel folds into focusByPriority; no threat system per design) |
| K.4 | Tactics-as-orders | engine | major | M | ✅ | `ctx.tactics` threaded into the brain. **Kill Order** gates `focusByPriority` (0 → just hit the lead, no caster priority); **Cooldowns** scales the `emergencyDefensive` threshold + pre-empts defensive majors on big packs. **Interrupts/Positioning** stay the existing affix/boss rolls (already real — real interrupt cast-bars are a fast-follow). Verified: all-0 (1238s) vs all-3 (1097s) diverge more; +2 floor 6/6; determinism + ceiling (+17/+20/+3) hold (no double-count surfaced) |
| K.5 | Spec overlays (data-driven profiles) | engine | major | M | ✅ | moved the profile→behaviour mapping from `brainOf` code into `behavior-profiles.json` data: the 4 GDD profiles got `targetEnemy` (tunnel-vision→focusHighestHp, executioner→focusLowestHp+priority, peel/opportunist→focusByPriority) + 2 new enemy profiles (melee→focusTank, caster→focusSquishy) with `targetAlly`. `BehaviorProfileSchema` now `action?`/`targetEnemy?`/`targetAlly?` string lists; `brainOf` reads them (role provides the action base). **New enemy/spec = author a profile, no engine code.** Byte-identical to K.4 (egm-smoke 816/868/1097/1238, op-verify 6/6) |
| K.6 | Balance + verification pass | engine | major | M | ✅ | 20-agent adversarial review of the K brain → 3 confirmed (2 major, 1 nit), all fixed: (1) `triageHeal` was dead for the Lifebinder (filtered only `heal`-type effects; that spec heals entirely via HoTs) → broadened to HoT/special heals with HoT-aware sizing; (2) `majorKind` misclassified the HoT-only major **Blossoming Tide** as offensive → now HoT/heal-special majors are defensive (held for danger, not dumped on packs); (3) hardened content load to cross-validate the hardcoded enemy `melee`/`caster` profiles. No difficulty nudge needed — fixing the over-dumped raid HoT naturally tightened the maxed ceiling +20→**+19** (fresh **+17** unchanged, **+2** operator runway); +2 floor 6/6, determinism holds, live UI clean |

## ※ Affix swap — original fantasy season (IP scrub) ⬜ (design ✅, ready)

*Replace the 8 verbatim-WoW affixes with the original season. **Must rename the engine `id` literals**, not just display
names — ids are hardcoded (`aff.has(...)`, ~9 sites) and persist into saves, so a display-only rename does NOT scrub the
trademark (a pre-launch IP blocker). Isolated — good warm-up commit. **Names follow the in-world fantasy direction**
(`MMO-Nostalgia-Reference.md` §2 — Barrow-Bound / Crowned in Ash / Plaguebloom / Wake the Kin / Pyre-Vents /
Lifeblood Mire / Restless Shade / Death-Frenzy), NOT QA/dev puns (supersedes the earlier "Ship It Anyway" / "Merge
Conflict" placeholders, per the 2026-06-20 in-world-naming decision).*

| # | Task | Axis | Sev | Effort | Status | Notes |
|---|---|---|---|---|---|---|
| Affix.1 | Swap `data/affixes.json` (8 new ids/names/effects), rename the ~9 `aff.has` literals + death-cause string in `engine.ts`, fix `spiteful.punishes` bug, theme the 4 tactic dial labels; optional new fantasy affix (e.g. **Gravechill**) | engine/data | minor | M | ⬜ | verify `tsc -b` + `egm-smoke` times the +2 floor on all weeks |

---

## Phase L — Roster expansion: Marksman + Necromancer ⬜ (design ✅ — `MMO-Nostalgia-Reference.md` §6)

*Two roster decisions (2026-06-20): (1) repurpose the **Bard** spec into a **ranged Rogue (Marksman)** — the more
universal back-line-physical fantasy — **keeping its Overdrive party-haste kit** (the only Bloodlust/Heroism carrier,
nostalgia 10); (2) add a 6th class, **Necromancer**, the pet/summoner class, whose healer spec also fills the thin
3rd-healer slot. Result: **6 classes / 12 specs = 3 tanks / 3 healers / 6 DPS**.*

| # | Task | Axis | Sev | Effort | Status | Notes |
|---|---|---|---|---|---|---|
| L.1 | **Bard → Marksman** rework | content/ux | major | M | ⬜ | rename `bard` spec → `marksman` (ranged Rogue, Back); reskin lute→bow/hunting-horn; **keep the Overdrive party-haste + crit-setup kit intact**. Stays pet-less (pets = Necromancer). Name alts: Stalker / Deadeye. |
| L.2 | **Necromancer** — 6th class | content | major | S | ⬜ | add `necromancer` to `classes.json`; the pet/summoner class; two specs (L.3/L.4). |
| L.3 | **Bonecaller** spec (Necro DPS, Back) | content | major | L | ⬜ | raises skeletal servants + wasting curses/DoTs (Affliction / EQ-Necro / GW2 Reaper). Depends on the pet mechanic (L.5). |
| L.4 | **Pallbinder** spec (Necro Healer, Back) | content | major | L | ⬜ | bound guardian-wraith + leech/anima heal (FFXIV Scholar pet-healer pattern); **fills the 3rd healer slot** (2→3 healers). |
| L.5 | **Pet/minion engine mechanic** (net-new) | engine | major | L | ⬜ | persistent summoned combatant(s) acting on the tick loop, contributing output/threat; no analog exists today. Consumed by Bonecaller (+ optional Marksman beast). |
| L.6 | New-spec content (abilities/talents/loot/icons) | content | major | XL | ⬜ | author majors/abilities in `abilities-player.json` + `skills.json`; **bumps C.2 to 12 specs**, adds a Necromancer tier set (**bumps C.5**), spec loot/items (**C.4**), default behaviour profiles, role/spec icons. |
| L.7 | Save migration for the roster change | engine | major | M | ⬜ | rewrite `bard`→`marksman` specId on load + register new class/specs; bump `SAVE_VERSION` or sanitize so existing rosters with Bard members don't crash. |

---

## Phase M — Guild Feed & Loot Drama (always-visible social meta-layer) ⬜ (design ✅, this session)

*An **always-visible** guild-chat panel in the Logs UI, **meta-layer only** (no in-run combat log). Two voices:
**system notifications** (the game, neutral/factual — the notification-center backbone with complete coverage) and
**in-character solo barks** (a roster member in their own personality voice — flavor, curated to ~**1–2 barks/run**).
Multi-character exchanges ("beats" — bots talking **to each other**) are the **v2** upgrade (M.6). The unlock that makes
it scale to a **procedurally-generated roster**: **voice attaches to personality (trait/archetype), never identity** — a
random member inherits a voice pack for free. Loot drama is the feed's flagship customer. See memory `goatlite-guild-feed`.*

| # | Task | Axis | Sev | Effort | Status | Notes |
|---|---|---|---|---|---|---|
| M.1 | Always-visible feed panel + **system-notification** layer | ux/engine | major | M | ⬜ | the persistent guild-feed panel + the neutral game-voice stream covering every meta-layer state change (run filed, loot ready, trait earned, morale change / at-risk, recruit available, keystone depleted/raised, operator level-up, departure warning). The notification center — ships first, fully functional with **zero comedy**. |
| M.2 | **Loot-drama mechanic** (contested-item resolution) | engine/ux | major | M | ⬜ | when a drop upgrades **2+ members**, surface the decision; assign; **loser −5 morale** (wire the dormant `lost-loot` event), **winner +5% output next run** (persisted buff → `SAVE_VERSION` bump). **Personality-gated:** Selfish archetypes (Loot Goblin / Solo Player) contest loudly + lose more morale; Boomer / Casual Andy shrug. Rehomes B.5's pending loot-drama UI. |
| M.3 | **Bark engine** (procedural, deterministic) | engine | major | L | ⬜ | voice packs keyed by personality; template+slot grammar **grounded in real state** (item / key / name / rival / morale); per-member **no-repeat window**; **rarity budget**; **~1–2 barks/run** rate limit; seeded → replay-deterministic. Works for **random characters by construction**. Voice = trait(tone) × spec(vocabulary) × morale(mood) × per-character style seed. **No runtime LLM** (offline/deterministic/free). |
| M.4 | **Personality voice-pack content** (tiered) | content | major | L | ⬜ | author per-personality bark banks for the highest-frequency events first (loot win/loss, wipe, clutch timed, trait earned, morale crater, farming-boredom); a plain functional line for everything else. Start ~**40 templates**, grow on observed repetition; Claude-assisted drafting, curate keepers. **Two-layer voice:** earnest grim item names, all satire in the reaction. |
| M.5 | Loot drama **in the feed** (flagship integration) | ux | major | S | ⬜ | wire M.2 through M.1+M.3 so the contested decision + aftermath produce the marquee system-line + bark moments ("*i called that three runs ago*") — the shareable-screenshot content. |
| M.6 | *(v2)* Multi-character **exchange beats** + **Rival** escalation | content/engine | major | L | 💤 | whole-beat authored exchanges (two members talking **to each other**, cast from real roster + facts → coherent because authored as a unit); repeated loot snubs to the same rival **earn the Rival trait** (+10% output, −15% morale if that teammate dies — already in GDD). Deferred until v1 voice packs prove out. |

---

## Phase N — Intake balance (`enemyDmgMult`) + sim-dump tooling ✅ (2/2)

*Closes the 2026-06-20 balance note: enemy DAMAGE was undertuned, so survival/healing/tank/peel were decorative
(standard comp took 0 deaths through ~+18–21; healing ~all overheal). Investigation corrected the diagnosis —
`DMG_UNIT` is **not** two-sided (it scales only enemy-dealt damage, never player throughput or enemy HP), so an
isolated intake lever was a one-line constant change, not a re-architecture. Built the `sim-dump` harness first so
the investigation (and all future ones) is config-driven and saved to files.*

| # | Task | Axis | Sev | Effort | Status | Notes |
|---|---|---|---|---|---|---|
| N.1 | **`sim-dump` harness** — config/CLI sim runner that saves runs to files | tooling | major | M | ✅ | `web/scripts/sim-dump.mjs` (+ `sim-config.example.json`). **single** mode → full input + RunResult + derived analytics (per-member min-HP/DPS/HPS, party min-HP, seconds-in-danger, timer margin) as JSON **plus a readable combat-log `.md`**; **sweep** mode → matrix over keyLevels × affixSets × aggressions × seeds → aggregated table. Inputs: comp (presets `standard`/`probe`/`safety` or per-member objects), per-member ilvl/morale/skills/traits/talents, tactics, affix, aggression, key, seed, dungeon. `--ilvl-mode auto` = gear-appropriate (112+4·key, cap 160). Output → `web/sim-logs/` (gitignored). Supersedes `lifebinder-probe.mjs`. |
| N.2 | **`enemyDmgMult` intake lever** — isolate + raise enemy damage | engine/balance | major | S | ✅ | added `tuning.sim.enemyDmgMult` (default 1 = no-op) folded into the `DMG_UNIT` constant in **both** `egm/stats.ts:~49` and `egm/engine.ts:~44` → one isolated "all enemy-dealt damage ×N" knob (auto-attacks + the 6 boss/affix mechanics), with **zero** effect on enemy HP (`HP_UNIT`), player throughput (`power`, no `DMG_UNIT` term), or kill-speed. Set to **2.0** from sim-dump sweeps. **Result (gate comp = safety 2H):** +2 floor still **6/6** timed at starting gear; +8 comfortable (54% min-HP, 0 danger); **survival now binds below the timer wall** (+17 wipes with time on the clock); gear-cap ceiling fresh +15 / maxed +18 → **operator runway +3** (was +17/+19 — the drop is intended: survival co-limits the ceiling now). Determinism intact (op-verify 6/6). **egm-smoke goldens shifted** (even 0-death low/over-geared runs ~8% slower — the AI now spends actions on healing/defense): week +8 868→**914s**, Volcanic +8 826→**884s**, all-3 1097→**1182s**, all-0 1258→**1367s**. No save migration (tuning is content, not persisted). |

---

## Open Design Decisions (resolve before/while building the dependent task)

| Decision | Blocks | Status | Resolution |
|---|---|---|---|
| Tick rate / timeline model | A.3, A2.1 | ✅ Resolved | v1 ran 1s ticks; the **EGM rebuild (A2) runs continuous seconds** (DT=0.25 inner step, attack-speed-driven, mm:ss timeline). `tuning.sim` (hpUnit/dmgUnit/keyScalingPerLevel) calibrated to the GDD timer table for the 1T/1H/3D comp. |
| Client-only vs isomorphic sim | A.1, D.6 | ⬜ Open | leaderboard re-sim wants shared TS sim |
| Gold sinks / economy balance | D.4 | ⬜ Open | gold has no spend yet |
| Haste & Mastery effects | D.8 | 🟡 Partial | **Haste now wired** in the EGM engine (shortens `attackInterval`; Chill = −haste slows). Mastery still a no-op (per-spec hook unspecified). |
| Recruitment Board "guild progression" metric | B.9, D.6, F.4 | ✅ Resolved | **Operator-skill Ceilings** are the recruit-quality lever — guild progression unlocks **higher-Ceiling recruit pools** ("access higher potential recruits"). Current rating shown precisely; Potential shown as fuzzy ★. See `Operator-Skills-Design.md`. |
| Potentials: draft-bias vs power lever | F.1–F.4, D.5 | ✅ Resolved | **Unified.** The locked GDD "Potentials" (hidden tag-weights, never touched power) now ALSO set each operator skill's **Ceiling** (so they drive power) while keeping their old job of biasing earned-trait rolls. One hidden "how good can this bot get" system instead of two. GDD §Potentials updated. |
| Dungeon Rescue trigger + departure absorption | D.2 | ⬜ Open | when does a rescue spawn; supply vs departures |
| Affix calendar: fixed cycle vs weekly roll | C.6 | ⬜ Open | infinite key treadmill needs an affix meta |
| Keystone targeting / ownership | B.3, B.12 | ✅ Resolved | **Per-member keys** — each member holds their own key; the player **picks which key (owner) to run**; each levels independently (deplete a high key → push a lower one). Random dungeon on recruit (Ashveil-only until C.1). |
| Capture→rescue + scar ramp scope | D.9 | 💤 Deferred | is permadeath real or flavor? |
| Leaderboard integrity / accounts / anti-cheat | D.6 | ⬜ Open | client-inspectable save trust model |
| Per-spec morale bonuses | B.6 | ⬜ Open | all specs vs a few archetypes |
| Guild feed: form factor + v1 scope | M.1–M.5 | ✅ Resolved | **Always-visible** meta-layer panel (not a tab you visit); **meta-only** (no in-run combat log). v1 = **system notifications + solo barks**, curated **~1–2 barks/run**; multi-character exchange "beats" deferred to **v2 (M.6)**. |
| Bark authoring for random characters | M.3, M.4 | ✅ Resolved | **Voice attaches to personality (trait/archetype), never identity** → procedurally-generated members inherit a voice pack for free. Voice = trait(tone) × spec(vocabulary) × morale(mood) × per-character style seed; **templated + state-grounded**, no runtime LLM (deterministic/offline). Coherence for v2 exchanges comes from authoring whole multi-role **beats**, not stitching atomic lines. |
| Loot drama: depth + who contests | B.5, M.2 | ✅ Resolved | Wire the GDD-canon mechanic (loser −5 morale, winner +5% next run) but **personality-gated**: Selfish archetypes contest loudly + lose more, passive ones shrug. Make it a **decision, not a tax** (give to best-fit vs placate fragile morale) + a default auto-assign policy so the modal is opt-in. Rival-trait escalation from repeat snubs → **v2 (M.6)**. |

---

## Changelog

- **2026-06-20** — **Replay v2: reworked into an EGM-style "faked-spatial" arena (I.2 rework).** Studied how the
  EGM reference handles its 2D combat (4 parallel readers over `Extract/recovered/gameUI/combat/` +
  `systems/combat/`): EGM's `CombatPlaybackScreen` is one immediate-mode `draw_arena()` driven by **two sim
  timelines** — an `event_log` *and* per-tick `snapshots` carrying every unit's `pos: Vector2` / `state` /
  `life_pct` / `target_id` — i.e. it is **fully spatial** (free x/y movement, kiting), with projectile/pulse attack
  VFX + particle impact bursts + arcing damage numbers + per-ailment status pips, all RNG seeded by `(tick, id)` so
  it stays deterministic. Our web sim is deliberately **band-based (no x/y)**, so going truly spatial would mean an
  engine change; per the user's call we took the **faked-spatial (UI-only)** route. Reworked `ReplayCanvas.tsx`
  from band-rows into a 2D arena: combatants are **dots with deterministic seeded positions + an idle bob** (party
  = front/back columns by spec position; enemies = the active stage's mobs front/back + centered boss), with
  **SVG targeting lines + melee swipes + ranged projectiles (CSS `--dx/--dy`) + impact rings + arcing pop-in
  damage numbers** derived from the existing log (windowed, gated to playback, scrub-safe). **No engine/sim change
  → determinism untouched by construction.** Verified: `tsc -b` clean; Playwright live check (`scripts/i-live.mjs`)
  9/9, **0 console errors** (arena, HUD overlays, HP bars, projectiles + numbers during playback, scrubbing).
  **Adversarial review** (3 dims → per-finding verify, 15 agents → 3 confirmed, all fixed): same-named pack mobs
  were collapsing their floats/shots/impacts/death-skulls onto one dot — now enemy deaths resolve by **precise
  per-mob id** and enemy-target VFX anchor to the **lowest-HP living dot of that name** (numbers track the draining
  mob); plus dead v1 CSS removed. **Deferred:** status/cooldown pips (need a small additive per-combatant status
  emit — same deterministic/transient pattern as the replay timeline). Memory: `goatlite-2d-replay`,
  `egm-combat-playback-reference`.
- **2026-06-20** — **Phase I (mostly) shipped: the 2D "abstract packs" replay — the report now LEADS with a live
  combat viewport.** Built top-to-bottom: **I.1** — `egm/engine.ts` now emits a deterministic, **additive**
  `ReplayTimeline` on `RunResult` (new types in `sim/types.ts`, re-exported from `sim/index.ts`): real stage
  start/end timing, per-mob spawn/death + per-second HP-fraction samples, stable ids `s{stage}m{i}`, front/back
  band — recorded purely by reading values the sim already computes (hooked into `snapshot()` + a stage-finalize
  block; no RNG consumed, no combat state touched). **egm-smoke goldens BYTE-IDENTICAL** (884/914/1182/1367, 0
  deaths) → zero balance impact; **transient** (`lastResult` is in the store `TRANSIENT` set → stripped before
  `localStorage`, recomputed from the ticket, so no save migration); `replay?` optional so the legacy engine stays
  valid. **I.2** — new `ReplayCanvas.tsx` (DOM/SVG): dungeon-tinted **abstract backdrop** (placeholder for G.4
  art), party portrait orbs (lower-left, live HP via `hpAt`), the active stage's enemies as a **pack split into
  front/back rows** (bosses = large gold token), draining HP bars — **pure `clock`-driven, scrub-safe**. **I.3** —
  ReportPage **re-laid-out per the user's spec**: the replay canvas leads, with the **summary header overlaid
  top-left** and the **live DPS/HPS meter overlaid top-right INSIDE the canvas** (the meter moved out of the right
  column), the **timer adjuster** (play / speed dial / scrubber + death markers) directly **below**, then the
  usual Event Log/Deaths/Casts + Party Health. **I.4 (partial)** — floating combat text + boss-mechanic/affix
  flashes + death bursts, via a **windowed event layer** that covers the ~5 sim-sec/tick playback skip (a naive
  `=== sec` gate dropped ~80% of events), plays only while PLAYING, and reads enemy deaths from the full timeline
  so a boundary-killed mob still flashes. **Deferred:** status/cooldown pips on orbs (per the build decision);
  name-keyed float/burst anchors (cosmetic dup-name nit, documented). Verified: `tsc -b` clean; egm-smoke
  determinism intact; Playwright live check (`scripts/i-live.mjs`) 9/9 green, **0 console errors** (canvas renders,
  HUD overlays inside the canvas, front/back band split, floats during playback, scrubbing). **Adversarial review**
  (4 dimensions → per-finding verify, 14 agents → 10 findings → 6 confirmed): **all 6 fixed** (windowed event layer
  [major]; full-timeline enemy bursts [2× minor]; crit float-size dead branch [nit]; restored combat-rez recharge
  ETA dropped in the HUD compaction [minor]) bar the documented name-key nit. Memory: `goatlite-2d-replay`.
- **2026-06-20** — **Phase N shipped: intake balance (`enemyDmgMult`) + `sim-dump` tooling — the enemy-damage gap
  is fixed.** First built **`web/scripts/sim-dump.mjs`** (N.1), a config/CLI sim harness that **saves runs to files**:
  `single` mode dumps the full input + RunResult + derived analytics (per-member min-HP/DPS/HPS, party min-HP,
  seconds-in-danger, timer margin) as JSON **plus a readable combat-log `.md`**; `sweep` mode runs a matrix
  (keyLevels × affixSets × aggressions × seeds) → aggregated table. Comp presets + per-member ilvl/morale/skills/
  traits/talents/tactics/affix/aggression/seed; `--ilvl-mode auto` = gear-appropriate. Output → `web/sim-logs/`
  (gitignored). Then the **investigation corrected the prior diagnosis**: `DMG_UNIT` is **NOT** two-sided — grep +
  engine read prove it appears ONLY in enemy-dealt damage (auto-attacks `stats.ts:181` + the 6 boss/affix mechanics
  in `egm/engine.ts`); player damage uses `power` (no `DMG_UNIT`), enemy HP uses `HP_UNIT`. So the isolated lever was
  a one-line constant change (N.2): added **`tuning.sim.enemyDmgMult`** (default 1) folded into `DMG_UNIT` in both
  `egm/stats.ts:~49` and `egm/engine.ts:~44` → one "all enemy-dealt damage ×N" knob, zero leak to HP/throughput/
  kill-speed. Swept candidates with sim-dump and **set 2.0**: reproduces the bug at 1.0 (gate comp 0 deaths through
  +20, decorative survival), and at 2.0 **survival binds below the timer wall** (+17 wipes with time on the clock)
  while +2 floor stays **6/6** timed and +8 stays comfortable (54% min-HP). Verified: `tsc -b` clean; **op-verify
  6/6** (operator deltas + determinism + floor); **f6-balance** +2 floor 6/6, gear-cap ceiling fresh +15 / maxed +18
  → **operator runway +3** (down from +17/+19 — intended, survival co-limits the ceiling now). egm-smoke goldens
  shifted (intake now costs clear-time via healing/defense even at 0 deaths): week +8 868→**914s**, Volcanic +8
  826→**884s**, all-3 1097→**1182s**, all-0 1258→**1367s**; all still timed. No save migration (tuning is content).
  **24-agent adversarial review** (5 find lenses → adversarial verify): 19 findings → 12 confirmed (11 were
  *confirmations the lever is correct* — isolation/determinism/no-double-count/clean-build/no-migration), 7 refuted,
  **0 real bugs in the change**. One pre-existing nit surfaced: the **Volcanic** affix scales its frequency with
  aggression but not its per-hit damage (unlike Spiteful/Positioning) — documented in `engine.ts` with a code comment
  (behaviour unchanged; deferred to the next balance pass). Memory: `enemy-damage-undertuned` (now RESOLVED +
  corrected), `sim-dump-tool`.
- **2026-06-20** — **⚠️ Balance note (✅ FIXED — see Phase N / enemyDmgMult): enemy DAMAGE is undertuned — intake is not a real difficulty
  lever at/around the floor.** Player report (facerolled to **+15 on ilvl 110**) reproduced in the headless sim:
  with starting gear (ilvl 110–120) the standard comp (Mystic/Lifebinder/Bard/Pyro/Assassin) takes **0 deaths through
  ~+18–21** on both the week affixes (fortified/bursting/spiteful) *and* volcanic/raging; first 4+ deaths only appear
  at **+22–23**, guaranteed by +24–26. At +5 nobody drops below **86% HP** (tank ~96%), so the Lifebinder's healing is
  ~all overheal → effective **HPS ≈ 8–11** (the meter only credits non-overheal — `combat.ts:100`). Crucially, every
  +14 **depletion** we could produce was a **0-death throughput fail** (Safe aggression and/or morale<50 cutting output
  to as low as 0.63×), never a survival fail. **Diagnosis:** the F.6/H.4/K.6 balance passes calibrated the *timer/clear-speed*
  curve, but enemy damage scales via `attackPower = baseDamage × keyScale × affMult × DMG_UNIT` (`stats.ts:181`) where
  `keyScalingPerLevel` (1.052) and `DMG_UNIT` (4.6) move enemy HP/damage **and** player throughput together — so tuning
  the kill-speed curve never isolated intake, leaving deaths/healing/peeling as essentially decorative until ~+22.
  **Fix candidates (TBD, needs its own balance ticket):** raise per-enemy `baseDamage` in dungeon content, or add an
  **enemy-damage-only** global multiplier (isolates intake from kill speed; `DMG_UNIT`/`keyScalingPerLevel` cannot, since
  they're two-sided). Goal: make survival a binding constraint *below* the timer wall at gear-appropriate keys, so healer
  HPS and tank/peel play actually matter. Harness left at `web/scripts/lifebinder-probe.mjs`. Memory: `enemy-damage-undertuned`.
- **2026-06-20** — **Planned Phase M — Guild Feed & Loot Drama (social meta-layer).** Design-locked this session: an
  **always-visible** meta-layer guild-chat panel with two voices — **system notifications** (neutral game-voice, complete
  coverage, the notification center) and **in-character solo barks** (personality voice, curated to ~**1–2 barks/run**).
  v1 ships barks + notifications; multi-character exchange "beats" + Rival escalation are v2 (M.6). The scaling unlock:
  **voice attaches to personality, never identity**, so a procedurally-generated roster gets voices for free (templated +
  state-grounded, no runtime LLM). Loot drama is the flagship customer — its mechanic (loser −5 / winner +5%, personality-
  gated) + barks rehome B.5's pending loot-drama UI. Added M.1–M.5 (+M.6 v2 deferred); resolved 3 design decisions (feed
  form factor/scope, bark-for-random-characters voice model, loot-drama depth). Memory: `goatlite-guild-feed`.
- **2026-06-20** — **K.6 shipped: Phase K complete — balance + 20-agent adversarial review.** Ran a find→verify review
  workflow over the whole K brain (rotation / targeting / tactics+data+determinism); 3 findings survived independent
  verification (2 major, 1 nit), all fixed in `combat.ts` + `content/index.ts`: **(1)** `triageHeal` was silently dead
  for the Lifebinder healer — it filtered only plain `heal` effects, but that spec heals *entirely* through HoTs
  (`applyStatus`) and heal-specials, so triage never fired (it fell through to `dumpRotation`). Broadened the heal filter
  to mirror `usable()`'s detection and gave `sizeOf` HoT-aware sizing (tick×duration) + burst-special sizing, so both
  healer specs now size their heal to the injury. **(2)** `majorKind()` misclassified the HoT-only major **Blossoming
  Tide** as *offensive* (its lone effect is an applyStatus regrowth HoT, which matched neither the def nor off predicate)
  → it was being dumped on every 3+ trash pack instead of held for danger. HoT/heal-special majors are now **defensive**.
  **(3)** Hardened `content/index.ts` to cross-validate the two enemy profile ids (`melee`/`caster`) that `makeEnemy`
  hardcodes. **No difficulty nudge needed:** fixing the over-dumped raid HoT honestly tightened the maxed ceiling
  +20→**+19** (fresh **+17** unchanged → **+2** operator runway, still "a few keys"); the +2 floor holds 6/6, determinism
  holds (op-verify), smoke all-timed (Volcanic 826s / week 868s / all-3 1097s / all-0 1258s), live UI clean (24 majors,
  0 console errors). Phase K (shared combat-AI brain) is done.
- **2026-06-20** — **K.5 shipped: data-driven AI profiles.** Moved the profile→behaviour mapping out of `brainOf` code
  into `behavior-profiles.json` data — the 4 GDD profiles gained machine-readable `targetEnemy` lists (tunnel-vision →
  focusHighestHp, executioner → focusLowestHp+priority, peel/opportunist → focusByPriority) and 2 new **enemy profiles**
  (melee → focusTank, caster → focusSquishy) carry `targetAlly`. `BehaviorProfileSchema` is now `action?`/`targetEnemy?`/
  `targetAlly?` string lists; `brainOf` reads them (the role still provides the action base since profiles span roles).
  **The payoff: a new enemy or spec is now authored as a profile, with no engine code.** Byte-identical to K.4 (egm-smoke
  816/868/1097/1238, op-verify 6/6, ceiling +17/+20/+3, `tsc` clean).
- **2026-06-20** — **K.4 shipped: tactics dials are now the party's AI orders.** Threaded `ctx.tactics` (the 4 dials) into
  the brain. **Kill Order** gates `focusByPriority` — at 0 the party just hits the lead enemy (no caster priority), at ≥1
  it kills back-band casters first. **Cooldowns** makes defence proactive — it raises the `emergencyDefensive` HP threshold
  (pop walls earlier) and lets defensive majors pre-empt on big packs. **Interrupts** and **Positioning** stay the existing
  affix/boss-mechanic rolls (already real per-dial; real interrupt cast-bars deferred to the fast-follow). The pre-existing
  abstract tactic scalars (Kill Order→trash-DPS, Cooldowns→spike-reduction) were kept alongside the new behaviours with
  **no double-count** in the curve. **Verified:** `tsc` clean; all-0 vs all-3 now diverge more (1238s vs 1097s); +2 floor
  6/6; determinism holds; ceiling unchanged for the standard tactics (fresh +17 / maxed +20 / runway +3).
- **2026-06-20** — **Phase L queued — roster expansion (Marksman + Necromancer).** Logged two roster decisions:
  repurpose **Bard → Marksman** (ranged Rogue, keeps the Overdrive party-haste — the only Bloodlust carrier), and add
  a 6th class **Necromancer** (the pet/summoner class: **Bonecaller** DPS + **Pallbinder** healer, which fills the thin
  3rd-healer slot) → **6 classes / 12 specs = 3T/3H/6D**. Seven tasks (L.1–L.7), incl. a net-new pet/minion engine
  mechanic and a `bard→marksman` save migration. Also **aligned the ※ affix-swap names to the in-world fantasy
  direction** (Barrow-Bound, etc.), superseding the QA-pun placeholders ("Ship It Anyway"/"Merge Conflict").
- **2026-06-20** — **K.3 shipped: brain-driven target selection (players + enemies).** `TARGET_BEHAVIOURS` kit: party
  `focusByPriority` (kill back-band casters first, then lowest HP — stable so the party focus-fires together), `focusLowestHp`
  (executioner specs snipe almost-dead mobs), `focusHighestHp` (tunnel-vision tanks hold the biggest); enemy `caster` profile
  → `focusSquishy` (dive the squishiest non-tank, back line first), melee/adds → `focusTank`. The GDD profile picks the
  party targeting list; wired into `targetsFor` (single-target), `basicAttack`, and `decideEnemyTarget` (which dropped its
  cached-tank param). **Verified:** `tsc` clean; Bone Acolyte casters now hit non-tanks 180× / tank 0× (were glued to the
  tank); +2 floor 6/6; determinism holds; key ceiling settled at **fresh +17 / maxed +20 / runway +3** — back at the F.6
  calibration (the caster-dive pressure offset by smarter kill-priority), so no nudge needed. (Peel folds into
  focusByPriority — no threat system in v1, per the design lean.)
- **2026-06-20** — **K.2 shipped: player rotation behaviours (the first real AI smarts).** Replaced the brain's default
  behaviours with: `holdForWindow` — the spec major no longer fires on cooldown; **defensive** majors (walls/absorbs/raid
  heals, classified by effect) wait for `partyInDanger` or a boss, **offensive** majors fire on a boss or a ≥3-enemy pack
  (so a burst/AoE isn't wasted on a lone straggler); `triageHeal` — a healer now casts the heal **sized to the most-injured
  ally** (light scratch → the small/efficient heal, big drop → the big heal) and skips near-full allies, killing the
  "Greater Heal overheals a topped target" problem; `emergencyDefensive` (pop a shield/parry when self drops <40%); and
  `dumpRotation` now **excludes majors** (they're decided by `holdForWindow`). Also added the **commit-per-milestone**
  mandate to `CLAUDE.md` (effective K.2). **Verified:** `tsc` clean; the cleric now mixes **Flash Heal 84× / Greater Heal
  68×** (vs always-Greater before); +2 floor 6/6; determinism holds; key ceiling **unchanged (fresh +18 / maxed +20)** so no
  difficulty nudge needed. First per-milestone commit lands here (bundles the uncommitted session: F, G.1–3, H, Cluster J, K.1).
- **2026-06-20** — **Design reference added: `Docs/MMO-Nostalgia-Reference.md`.** Multi-MMO nostalgia survey
  (WoW/FFXIV/GW2/ESO/Lost Ark/BDO/OSRS/EQ/FFXI/SWTOR/Rift/WildStar/New World/TERA/Aion) distilled into
  GOAT-Lite design hooks, **recast into the Ashveil gothic-fantasy voice** (satire stays in the wrapper;
  in-world content is earnest). Includes: the 8 laws of MMO nostalgia; an **affix rename table** (the 8
  verbatim-WoW affixes → Barrow-Bound / Crowned in Ash / Plaguebloom / Wake the Kin / Pyre-Vents /
  Lifeblood Mire / Restless Shade / Death-Frenzy, effects unchanged) + 4 new affixes; 10 dungeons, 16
  bosses (with barks), 9 missing signature-verb abilities, an items/rarity catalog, and a **Classes & Specs**
  gap analysis recommending a 6th class **Necromancer** (Bonecaller DPS + Pallbinder healer) and a
  **Houndmaster** ranged-pet Rogue spec. No code/data changed yet — affix rename is the top actionable.
- **2026-06-20** — **K.1 shipped: AI brain scaffold (pure refactor, byte-identical).** Introduced the single decision
  points the rest of Phase K builds on — `decideAction` (party: which ability) and `decideEnemyTarget` (enemy: who to hit)
  in `combat.ts`, each walking an ordered behaviour list resolved from the actor's profile (`brainOf`). For K.1 every
  profile maps to the **defaults that reproduce today's play exactly**: `dumpRotation` delegates to the unchanged
  `selectAbility`, and enemy targeting reproduces the per-tick tank-focus rule. Added `Combatant.profile` (spec
  `defaultProfile` / per-member override; enemies = `melee`\|`caster` by band) and an optional `base`+`behaviours` overlay
  on `BehaviorProfileSchema` (K.5 fills it). Wired `engine.ts` to call the brain instead of `selectAbility`/the inline
  victim pick. **Acceptance = byte-identical:** captured a golden, and after the refactor egm-smoke matches it exactly
  (+8 798s/868s, tactics 1068s/1202s), op-verify determinism 6/6, `tsc` clean. Zero behaviour change — the seams now exist
  for K.2 (rotation behaviours: triageHeal/holdForWindow) and K.3 (targeting) to plug into.
- **2026-06-20** — **Phase K designed: combat AI rework — one shared, data-driven behaviour brain for players + enemies.**
  Design session with Umut. Locked: (1) **priority rules + utility tiebreak** (legible/deterministic — fits "review the
  pull" — over opaque utility AI); (2) **data-driven profiles** (JSON composing code-side behaviour primitives, extending
  the inert `behavior-profiles.json`) so future enemies are data not code; (3) **v1 = core brain + role/spec + tactics-as-
  orders**. The model: every actor runs the same brain (decide *what* + *who* by walking an ordered behaviour list);
  3 layers (common primitives → role templates → spec/enemy overlays). Key insight: the **tactics dials become the party's
  AI orders** (Kill Order→target priority, Interrupts→interrupt readiness, Cooldowns→hold-for-window, Positioning→avoidance),
  and operator-skills/aggression/traits become competence/risk/personality **modifiers** (fast-follow). Grounded the spec in
  the current seams: `selectAbility` longest-CD-first, enemies-always-hit-the-tank, the 95%-dead profile system, tactics-as-
  abstract-scalars. New `Docs/Combat-AI-Design.md` (architecture + behaviour catalog + profile schema + tactics mapping +
  open questions: threat model, interrupt cast-bars + refined tickets K.1–K.6, K.1 = pure-refactor-first). **No code.**
- **2026-06-20** — **Phase H complete — combat depth: 10 per-spec major cooldowns + talent nodes 3–5 + rebalance.**
  **H.1:** every spec now has a ~60s **signature major** (`cooldownTurns:20`, since secondsPerTurn=3), named as
  **fantasy MMO spells** (the bots cast in-world spells; the QA satire stays in the meta layer — affixes/tactics/UI):
  Guardian *Bulwark Banner* (party −35% DR), Crusader *Sacred Bastion* (party absorb), Mystic *Unmoving Mountain* (parry
  wall + self-regen), Cleric *Light's Salvation* (party heal + absorb), Lifebinder *Blossoming Tide* (party HoT bloom),
  Berserker *Reckless Frenzy* (burst, 10% HP cost), Assassin *Killing Edge* (execute burst + empowered follow-up), Bard
  *Rallying Crescendo* (party haste/output), Pyromancer *Emberstorm* (AoE + Burn detonate), Arcanist *Nullifying Surge*
  (damage window + mass chill/silence). [Renamed from the initial QA-jargon working names per Umut.]
  All reuse existing effect types/SPECIALS (no new engine handlers), authored in `abilities-player.json` + mirrored to
  `skills.json` (so the spell tooltip resolves). Narrowed the `usable()` detonate gate so Prod Incident fires without Burn.
  **H.2:** a **Signature** card on the Character sheet + a gold **✦ MAJOR** accent on major cast lines in the replay.
  **H.3:** extended the talent effects schema (`intakePct`+`critPct`, folded into the operator intake/crit channels) and
  gave **nodes 3–5 real effects** + defaults — the picker now shows all 5 nodes. **H.4:** majors + the now-5 talent
  nodes added ~+4 net power, so nudged `keyScalingPerLevel` 1.043→1.052 to restore the curve (fresh ceiling +18 / maxed
  +20 ≈ the F.6 calibration; operator runway compressed +3→+2). **Verified:** `tsc -b` clean, all 10 majors fire,
  talent stats apply, +2 floor 6/6, `op-verify` determinism 6/6, live Playwright (Signature card + ✦ MAJOR + all-5-nodes
  picker, 0 console errors). Adversarial review (35 agents, 4 confirmed findings) → **fixed**: Zen Mode's counter was
  ~7× over-scaled (maxHp coefficient copied from a power-scaled sibling → scaled off power); the pure-heal `usable()` gate
  was suppressing Zen Mode (parry+HoT) and Hotfix (heal+shield) at full HP → narrowed to exempt proactive shield/setup
  payloads. New harness: `spec-parse.mjs`, `h-live.mjs`.
- **2026-06-20** — **Planned Phase K — Combat AI rework (v2).** Added a dedicated phase (K.1–K.6) for the combat-AI
  overhaul Umut flagged: utility-scored player rotations (right heal for the injury, save burst/emergencies, reactive
  tank defensives), kill-order-aware target selection, wiring the inert behavior profiles, smarter enemy AI (casters,
  target variety), and major-cooldown timing. **Sequenced after Phase H** (the AI needs the full kit — esp. the per-spec
  majors — to reason about; K.5 is blocked by H.1). No code — planning only.
- **2026-06-20** — **Combat-log clarity: overhealing shown + friendly casts name their target.** (1) Heals now log
  WoW-style **overhealing** — `Cleric's Greater Heal heals Tank for 103. (304 Overhealing)` — which explains the
  reported "Greater Heal (68) seems weaker than Flash Heal (232)": it wasn't weaker (Greater Heal = 100+180% INT vs
  Flash Heal 60+120%), it just **overhealed a near-full target** and the log only showed the post-cap effective amount.
  No data/AI change — purely surfacing the surplus (`combat.ts` heal emit). (2) Non-damaging casts (buffs / shields /
  redirects / CC) that fell through to a bare "uses X" line now **name the target**: `Tank uses Rally Cry on the party.`,
  `Druid uses Blossom Ward on Tank.`, so e.g. Guardian's Oath shows who it protects (new `castTargetDesc` helper +
  enhanced fallback emit in `combat.ts`). Verified: `tsc -b` clean, `op-verify` determinism + `+2` floor hold,
  `egm-smoke` probes pass — both are text-only (no balance/RNG impact).
- **2026-06-20** — **J.10 follow-up: WoW-style spell tooltips in the event log + the combat log reworded to possessive
  style.** Per Umut's references: (1) event-log **spell names are now bold + underlined** in the caster's spec colour
  and hovering one pops a **WoW-style spell card next to the cursor** (cursor-following portal) — title, cd/target,
  school·formula, and the description as **yellow flavor**; **no SpellID** (skillIds match `content.skills` 1:1, so the
  rich card resolves for every player ability). New `SpellTip` + `LogSpell` in `components.tsx`; the log line splits the
  ability name out of the sentence (`LogEntry.skillId` added). Replaced the line-level J.10 tooltip on log rows with
  this spell-only hover. (2) The combat-log lines were **reworded to WoW's possessive style** with inline amounts —
  `X's <Spell> hits Y for N School.(Critical)` / `X's <Spell> heals Y for N.` / `X's melee swing hits Y for N School.`
  (engine emits in `combat.ts` ×4 + `engine.ts` enemy strike); dropped the redundant right-hand amount column so the log
  reads as a sentence stream (matches the reference). Verified: `tsc -b` clean, `egm-smoke` probes still pass, determinism
  intact; Playwright (`spell-live.mjs`) confirms 500+ underlined spells + the cursor tooltip ("Poisoned Blade" card),
  0 console errors.
- **2026-06-20** — **Phase J shipped (9 remaining tickets J.1–J.6, J.8–J.10) — the post-Phase-F feedback batch is done.**
  **Bugs:** the **healing meter** was fake (engine emitted no heal data; `analytics` fabricated it) → engine now emits a
  real `healSeries` (cumulative `healDone`/sec) on `RunResult` and `analytics.healingWindow` slices it like the damage
  meter (J.5); the combat log **dropped enemy attacker names** (renderer only painted party-spec sources) → now paints
  any source, enemies in a hostile tone (J.4); the **replay played past a wipe** → stops at the last death (J.2); the
  **speed dial didn't visibly change log cadence** → per-line `logIn` fade scaled by speed (J.3). **Features:** guild
  creation lost the **Horde/Alliance + realm** pickers (`GuildInfo` slimmed to name/crest/glyph/motto; 3 consumers +
  `ReportView.region` updated; no save migration) (J.1); **loot** shows a green ▲ + "current → new (+Δ)" for *every*
  eligible member (`LootDrop.upgrades[]`) (J.6); the report header shows **Combat Rez** charges + regen timer instead of
  Rating (new `RunResult.finalRezCharges`/`nextRezChargeAtSec`) (J.9); **tooltips** via a reusable portal `<Tip>` wired
  into `GameIcon` (role/spec/tactic/affix/skill), affix chips, event-log spells, and gear rows (J.10). **Polish:** stripped
  every `0 0 blur color` glow (3 CSS + 15 inline) while keeping depth shadows (J.8). **Verified:** `tsc -b` clean,
  `op-verify`/`egm-smoke` still green + deterministic (heal series confirmed non-zero per healer), and a Playwright
  end-to-end (`j-live.mjs`) drove guild→run→report→loot with **all assertions green + 0 console errors**. New harness
  scripts kept: `op-verify.mjs`, `f5-live.mjs`, `f6-balance.mjs`, `spec-parse.mjs`, `j-live.mjs`.
- **2026-06-20** — **J.7 done: assassin backline gate softened to a bonus.** Umut clarified the assassin felt
  *inconsistent* (not weak — a measurement showed it's the top single-target DPS). Root cause: Poisoned Blade + Ambush
  carried `targeting.band:"back"`, which `targetsFor` turns into a forced redirect to the back-row whenever one exists —
  so the assassin's burst got yanked off the focus/kill-order target onto a back-row caster (and reverted on back-rowless
  packs). Fix: removed the two `targeting.band:"back"` gates (`data/abilities-player.json`) while **keeping** the
  `targetBand back → ×1.3` damage modifier — so the abilities now hit the focus target like the rest of the kit and the
  backline dive is pure upside. Verified: `tsc -b` clean, content validates, `op-verify` determinism + `+2` floor hold,
  `egm-smoke` times all weeks, and `spec-parse.mjs` shows **identical Ashveil aggregate output** (no balance shock — the
  change only stops the off-focus redirect in front-led / future caster-heavy packs). It remains the strongest DPS
  (705k / 830s / 0 deaths) — flagged in case a later nerf is wanted, but the user's ask was consistency, not tuning.
- **2026-06-20** — **Phase J planned: 10 user-reported issues from the Phase-F build investigated + ticketed (no code).**
  9-agent fan-out recon grounded each in code (root cause + fix + effort) → new **Cluster J** in `Post-F-Clusters-Plan.md`
  + a Phase J table here. Bugs: replay doesn't stop at the wipe; combat log drops the enemy attacker name (no `sourceId`
  on the strike meta); the **healing meter is fake** (engine emits no heal series — `analytics` fabricates it); replay
  speed dial doesn't visibly change log cadence. Small features: drop faction/realm from guild creation; loot ↑ for every
  upgrade + show current item; Battle-Res count+timer on the report instead of Rating. Polish: kill the `0 0 blur color`
  glows. Cross-cutting: real tooltips (Radix) for icons/affixes/tactics/log-spells/gear. **Assassin "problematic" was
  measured (`scripts/spec-parse.mjs`) and the assumption was WRONG — it's the strongest single-target DPS (705k dmg /
  830s clear / 0 deaths, vs berserker 671k/1034s/5.2 deaths); so the ticket is flagged "needs Umut's call" (overtuned vs.
  backline-gated inconsistency), not a buff.** None implemented yet.
- **2026-06-20** — **Phase F complete (F.5 UI + F.6 balance) + visual pass G.1–G.3 — operator skills are now playable
  end to end.** **F.5:** rebuilt RecruitPage from a 3-column card grid into a Warcraft-Logs-style **scouting board**
  — a dense list (avatar/name/spec icon · role · iLvl · precise **Operator Rating** · fuzzy **Potential★** · morale ·
  cost · Sign) beside a sticky **scout detail panel** (the two scouting numbers, a scout-report blurb, operator
  **skill bars** with the ceiling shaded where scouted and "?" where hidden, and the trait's wired combat summary).
  Added an **Operator** card to the Character sheet (COR, ★, skill bars with XP-to-next, "trait in combat"). New
  shared `web/src/logs/OperatorPanel.tsx` (`SkillBars` with half-star `Stars`, `corColor`, `scoutBlurb`,
  `traitCombatSummary`); `Member`/`shapeMember` now carry the operator block. **F.6:** swept the key ceiling at the
  gear cap (`f6-balance.mjs`) — a maxed-operator party extends the reliable ceiling **≈ +3 key levels** over fresh
  recruits (fresh +17 → maxed +20 @ ilvl160) while the **+2 floor still times 6/6** at starting gear; the starting
  per-point %s were in-target so **no retune** (confirms uniform-Awareness 0.5%/pt over the design's avoidable-only
  1.5%). **G.1:** one `--radius` token (2px, WCL-sharp) replaces every rectangular `border-radius` in `logs.css`
  (true circles exempt). **G.2:** typed `<GameIcon kind id/>` registry — mask-tinted `/icons/*.svg` with a **labelled
  placeholder** for art that doesn't exist yet (the 3 operator-skill icons among them) + `aria-label` everywhere.
  **G.3:** wired the existing role/spec/tactic icons into RolePill (→ recruit/roster/setup/character), the New-Run
  tactic dials, and the roster/recruit tables. **Verified:** `tsc -b` clean; `op-verify`/`egm-smoke` still green;
  Playwright live check drives guild→scout-board→character with **0 console errors** (skill bars, COR, ★ all render;
  placeholder skill icons show correctly). Test harnesses added: `op-verify.mjs`, `f5-live.mjs`, `f6-balance.mjs`.
- **2026-06-20** — **Phase F engine/data shipped (F.1–F.4): operator skills are live in the sim; traits are no longer
  inert.** Built the post-gear-cap power axis end to end. **F.1 (data/types/schema):** `data/operator-skills.json`
  (3-skill registry: Execution/Awareness/Composure) + a `tuning.operator.*` block (per-point %s, ceiling tag-map, XP
  curve, COR weights, gear cap); `OperatorSkillSchema` + `TraitCombat`/`TraitGrowth` (`.strict()`) schemas + index
  cross-ref (growth.skill + ceiling.byTag); `RawMember` gained `{skills,ceilings,skillXp,revealed,potentialProfile}`;
  shared helpers in `web/src/data/operator.ts` (roll profile→ceilings→skills, COR, Potential★, XP curve, growth);
  **SAVE_VERSION 4→5** with loadState backfill (accept dev reset). **F.2 (sim wiring):** new `web/src/sim/egm/operator.ts`
  `resolveOperator` → Execution adds output in `passiveDamageMult` (party-only), **Awareness = uniform** all-incoming
  reduction via a per-member `intakeMult` applied in `dealDamage` (user-chosen over avoidable-only), Composure = clutch
  (+output/−intake when any ally <35% HP or a death within `recentDeathSec`, computed per DT step as `ctx.partyInDanger`)
  plus a flat dodge ("variance reduction"); **trait `combat` blocks (output/intake/crit/hp) authored on all 24 traits
  and wired into `buildParty` — traits finally do something.** **F.3 (growth + cap):** `CONFIRM_LOOT` grants each
  participant role/trait-weighted skill XP (asymptotic toward ceiling); `dropIlvl` hard-caps at ilvl 160 (key 12) and
  above-cap keys convert the lost ilvl into bonus operator XP (the gear→operator handoff). **F.4 (recruit gen):**
  `makeRecruit` rolls a hidden Potentials profile → ceilings → starting skills (veteran-frac by recruit quality),
  a fuzzy ~50% reveal mask, and stores COR + Potential★. Earned-trait *triggering* deferred to D.1 (reveal-on-earn hook
  dormant). **Verification:** `tsc -b` clean; `egm-smoke` still times the +2 floor on all weeks; new `op-verify.mjs`
  proves exec/awareness/composure/trait deltas point the right way, determinism is byte-identical, and the +2 floor
  holds at baseline skills. Adversarial review workflow (22 agents, 18 verdicts) found **1 real defect** — operator
  intake was discounting self-inflicted HP ability costs (Blood Frenzy) — **fixed** via a `bypassIntake` flag on
  `dealDamage`; all other findings refuted as correct-by-design. Remaining: F.5 (recruit list/detail + character-sheet
  skill UI, built in G's squared+iconned style) and F.6 (balance pass).
- **2026-06-20** — **Phases G/H/I + affix-swap designed (spec only, no code yet) — full 7-request plan captured.**
  Planned the rest of the cluster work alongside Phase F. New `Docs/Post-F-Clusters-Plan.md` covers: **G — Visual pass**
  (requests #4/#5: one `--radius` token at ~2px replacing ~30 scattered values; wire the **18 already-existing unused**
  icons; typed `<Icon>` registry + placeholder; an **asset manifest** of what art to produce — ~70 ability icons is the
  big lift); **H — Combat depth** (request #7: 10 per-spec **major cooldowns**, role-templated + unique QA-flavored names,
  ~60s CD since 180s would never fire in 20–30s pulls, net-power then balance; + finish the prose-only **talent nodes
  3–5**); **I — 2D replay** (request #2 "abstract packs": engine emits a new `ReplayTimeline` with stage/pack/mob events +
  stable seed IDs — nothing spatial is emitted today — rendered as SVG party-orbs + pack-rows + scrubber; needs G's
  dungeon backdrops); and the **affix swap** (apply the original "Ship It Anyway" season; must rename the hardcoded
  `aff.has(...)` id literals, not just display names, to actually scrub the WoW trademark). Roadmap gained Phase tables
  G/H/I + the Affix.1 ticket and the summary table rows. Recommended order: Affix.1 (anytime) → F (with G.1–G.3 early) →
  H → I. Grounded in `data/specs.json` (3 tanks / 2 healers / 5 DPS) + the existing 60-ability kits. **No code touched.**
- **2026-06-20** — **Phase F designed: "Endgame & Identity" / operator skills (spec only, no code yet).** Planning pass
  with Umut on the next work cluster (requests: progression past the gear cap, recruitment list+detail, traits pass).
  Ran a 6-explorer recon workflow over roster/progression/specs/traits/replay/UI to ground the design. Decisions
  locked: (1) **hard gear cap** (~ilvl 160 / key 12) + a **mechanical operator-skill layer** as the post-cap power
  axis — 3 lean skills (Execution→output, Awareness→avoidable-intake, Composure→clutch/variance), 1–20, data-driven
  registry so role-specific skills can be added later; (2) skills **grow automatically toward a hidden Ceiling**;
  (3) **Ceiling = the GDD's "Potentials"** — *unified*: the locked hidden tag-weight profile now sets the skill
  ceilings (driving power) AND keeps biasing earned-trait rolls, instead of two separate hidden systems (this overrides
  the old "Potentials never touch the Output formula" rule — GDD §Potentials updated); (4) recruit scouting stays
  **hidden-but-active / fuzzy ★** per canon; (5) **traits become personality + real combat modifiers** (`combat` +
  `growth` schema blocks) — they're currently **inert** (`buildParty` never reads `traitIds`). New `Docs/Operator-Skills-Design.md`
  (full spec + tickets F.1–F.6). Resolved two open decisions (recruit-quality lever; Potentials power reconciliation).
  Pulls D.1/D.5/D.7 forward. **No code touched** — implementation starts next session (build order: this cluster first;
  2D replay deferred as "abstract packs", explained). SAVE_VERSION will bump 4→5 at F.1 (accept reset in dev).
- **2026-06-19** — **Raging reworked: +25% haste instead of +50% per-hit damage.** Enraged trash (sub-30% HP, never
  bosses) now *attacks ~25% faster* rather than hitting 50% harder per swing — implemented in the live EGM engine
  (`web/src/sim/egm/engine.ts`) by shortening the mob's `attackInterval` (`interval /= 1 + 0.25·(1 − 0.1·cooldowns)`)
  and removing the old `amount *= 1.5` per-hit spike. **Cooldowns still blunts it** (the affix↔tactic counter and the
  RunSetup "Cooldowns 0 on Raging" warning stay meaningful), and it remains **trash-only**. Net effect is a softer
  enrage window (≈+25% damage *throughput* vs the old +50% per swing). Mirrored in the rollback `runDungeonLegacy`
  aggregate sim as the DPS-equivalent `hit *= 1 + 0.25·(1 − 0.1·cooldowns)` (additive-bonus form so Raging stays ≥
  baseline even at max Cooldowns — matches the EGM; also now `!m.isBoss`). Display text updated in `data/affixes.json`
  (propagates to the live SetupPage affix list) and the GDD affix tables (incl. fixing a stale "Raging hits bosses"
  bullet). Verified: `tsc -b` clean + `egm-smoke.mjs` (Raging week timed, 0 deaths) + a 3-lens adversarial review pass.
- **2026-06-19** — **Fix: fresh-run report was instant-finishing (StrictMode bug in the prior auto-play fix).** The
  earlier "auto-play once" used a module-level Set mutated inside the effect; under React `<StrictMode>` (dev), mount
  effects double-invoke, so the first invocation marked the seed played and the second saw it as "already played" →
  jumped to the finished state (the fresh run never played). Replaced with a **store-backed flag**: RAN_KEY sets
  `autoplaySeed = result.seed`; the Report auto-plays the run whose seed matches, then dispatches `consumeAutoplay`
  (idempotent → StrictMode-safe). Verified live: fresh run plays from 0 and advances (scrubber 24→58/852), re-visit
  & historical stay finished/paused, 0 console errors.
- **2026-06-19** — **Fix: Report no longer auto-replays the sim on every visit (B.14 refinement).** The ticket-driven
  Report was re-simulating + auto-playing the run on *every* open (and for historical runs), because the playback
  effect set `playing=true` whenever the result changed. Now: the freshly-run key auto-plays **once** on first open
  (tracked by a session-level set of played seeds); re-visits and historical-run selections show the **finished**
  report paused (press play to re-watch). Also the just-run now reuses `g.lastResult` instead of re-simulating it
  (only historical runs re-sim from their ticket). Verified live (Playwright): fresh=auto-play, re-visit=paused,
  historical=paused, 0 console errors.
- **2026-06-19** — **Affixes gated by key level (WoW-style) + Raging no longer hits bosses.** A standard 1T/1H/3D comp
  was still wiping/depleting the +2 floor on the **Tyrannical+Raging** affix weeks — root cause: affixes ran at full
  strength even at the floor, AND Raging (+50% sub-30% damage) was applying to **bosses** (it shouldn't — in WoW only
  Tyrannical touches bosses). Fixes: new `web/src/sim/affixes.ts` `activeAffixIds(affixIds, keyLevel)` gates affixes
  by key (tunable `sim.affixTier2FromKey=4`, `affixTier1FromKey=7`): +2–3 none, +4–6 tier-2, +7+ adds Tyrannical/
  Fortified — used by the engine AND the New-Run/Report affix displays (which now show "unlocks at +N"). Raging gated
  to `!m.isBoss`. Verified: **+2 floor 16/16 timed on all 8 affix weeks** (was 8T/4W); difficulty still escalates
  (hard week: +7 11T/5W, +10 5T/11W); tsc clean. (My earlier re-balance only checked week-1 affixes — this closes
  that gap.)
- **2026-06-19** — **Interactive talent picker shipped (B.7 ✅).** Turned the read-only fake auto-pick into a real
  per-member build system. Gave the two MVP talent nodes (`data/talents.json` node-1 Survival↔Throughput, node-2
  Focus↔Spread) machine-readable `effects` (maxHpPct / dmgPct with an optional `onlyIf` gate — focus-HP / enemy-count);
  the engine resolves a member's picks in `buildParty` (maxHp multiplier) and `passiveDamageMult` (damage mods), with
  the choices saved per member, defaulted to balanced, backfilled on load, and captured in the run **ticket** so
  Reports replays stay faithful. The Character-sheet **Talents panel is now interactive** (click to pick; only the two
  effect-bearing nodes are shown — nodes 3-5 stay prose until C.2). Verified: resolver math (Iron Will +15% HP),
  damage A/B (focused vs cleaving vs opportunist give different raw damage; conditional gates evaluate), determinism,
  persistence across reload, ticket-faithful replay, and the live click — 0 console errors. Adversarial review
  (workflow, 5→3 minor) → fixed: unknown `onlyIf.type` now fails **closed** (was silently un-gating to an always-on
  buff), `onlyIf.type` tightened to a schema enum, and engine/UI default-fallback made to agree. Also added `CLAUDE.md`
  (repo guide) whose first rule mandates this roadmap update on every implementation.
- **2026-06-19** — **Balance re-tuned for the standard comp + top-end softened + drops aligned.** Found a real
  undertuning: a normal **1-tank/1-healer/3-DPS** comp wiped ~30–58% on the **+2 floor** at starting gear (the
  prior retune was mistakenly calibrated against a *2-healer* comp). Re-calibrated against the correct 1T/1H/3D
  reference at gear-appropriate ilvl per key (key lever: healer `powerPerIlvl` 0.3→1.06, since `hpsPerIlvl` is
  vestigial in the EGM engine; `hpUnit` 742→1020). Result: +2 floor **16/16 timed**, comfortable through +8.
  Then **softened the high end** (`keyScalingPerLevel` 1.05→1.043) so a geared 1-healer can *squeak* +15 (was
  all-wipe → ~coin-flip at ilvl 168). **Drop ilvls re-aligned** to the gear curve (`100+5·key` → `112+4·key`: +2
  now drops ilvl-120, an upgrade, not the old downgrade). Verified via headless seed-sweeps + live Playwright.
  Roadmap brought up to date (this entry; Phase A2 added; B → 11/14).
- **2026-06-18** — **Combat engine fully rebuilt on the EGM model and made live (Phase A2 complete).** Finished the
  migration off the fake flat-power sim onto a real per-hit engine (`web/src/sim/egm/`): wired the remaining
  **passives + ~all special mechanics** (3 adversarially-reviewed waves — on-hit/crit/kill hooks, detonate/splash/
  atonement/redirect/immunity/parry/empower/barrier-break/blossom, etc.; the two turn-scheduler skills reworked
  into pure stat buffs); added **enemy front/back bands** (backline-dive + frontline-AoE + melee-only Thorns now
  live); **reconnected affixes/tactics/boss-mechanics** (all 8 affixes, 4 boss mechanics gated by their audited
  tactic, tactics swing output+intake); and **cut the live app over** to `runDungeonEGM` (legacy kept as
  `runDungeonLegacy`). Added a **15s death penalty** and a **combat-resurrection charge** system (1 + 1/5min;
  all-down = wipe) to stop rez-spam. Each phase verified with headless SSR sweeps + Playwright; reviews run as
  fan-out workflows (find→verify), all confirmed findings fixed.
- **2026-06-18** — **Per-member keystones, editable New-Run party, and replayable Reports history (B.12–B.14).**
  Keystones moved from one guild key to **per-member** keys — each member holds & levels their own (New Run **key
  picker**; owner auto-locked into the party; loot/progression key off the run owner; SAVE_VERSION→4). The New-Run
  **party panel is now an interactive picker** (toggle members around the locked owner, 5-cap). Reports gained a
  **history list** (newest first) that **re-simulates each run from a tiny stored ticket** (deterministic; no bulky
  RunResults persisted) with back-to-latest. Adversarial review workflows on the state-model + report changes;
  fixed all confirmed findings (keyless-member crash → loadState backfill; a save-shape-change crash → history
  sanitize-on-load; loot dead-end; FILE_REPORT rating parity).
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
