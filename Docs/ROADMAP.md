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
| B | **Runtime loop & persistence** | 🟡 13/14 |
| C | Content scale-up | 🟡 4/10 |
| D | Systems depth | ⬜ 0/10 |
| E | Production (art, audio, polish) | ⬜ 0/7 |
| F | **Endgame & Identity (operator skills)** | ✅ 6/6 — live + balanced (operator runway ≈ +3 keys; +2 floor holds) |
| G | **Visual pass (icons + squared corners)** | 🟡 3/4 — G.1–G.3 done; G.4 **in progress** (raster PNG pipeline live + 89 user icons wired incl. the new `ability` kind; remainder = the missing art listed in G.4) |
| H | **Combat depth (per-spec majors + talents)** | ✅ 4/4 — 10 majors live + talents 3–5 wired + rebalanced |
| I | **2D replay (abstract packs)** | 🟡 3/4 — I.1–I.3 done (engine `ReplayTimeline` + SVG canvas + replay-led report layout); I.4 partial (floats/flashes/death-anim in; status pips deferred) |
| J | **Feedback & polish batch (10 user reports)** | ✅ 10/10 — shipped + live-verified (`Post-F-Clusters-Plan.md` Cluster J) |
| K | **Combat AI rework (v2)** | ✅ 6/6 — shared priority-rules brain (players + enemies), data-driven profiles, tactics-as-orders, 20-agent adversarial review (3 fixes) |
| ※ | **Affix swap (original season, IP scrub)** | ⬜ 0/1 — **design ✅** (ready to apply) |
| L | **Roster expansion — Marksman + Necromancer** | ⬜ 0/7 — **design ✅** (`MMO-Nostalgia-Reference.md` §6) |
| M | **Guild Feed & Loot Drama (social meta-layer)** | ✅ 5/5 (+1 v2) — feed + system notifications (M.1), loot-drama snub (M.2), deterministic bark engine (M.3) + voice packs (M.4) + snub-in-feed (M.5), all live-verified. M.6 (exchange beats + Rival) = v2 💤 |
| N | **Intake balance (`enemyDmgMult`) + sim-dump tooling** | ✅ 2/2 — enemy damage is now an **isolated** intake lever (=2.0); survival binds below the timer wall; +2 floor + operator runway (+3) hold; new config/CLI `sim-dump` harness |
| **P** | **Class-Tools System** (classes bring different tools to solve different problems) | ✅ 6/6 (P.0–P.5) — **design ✅** (`Class-Tools-System.md`); **P.0–P.3 done** (boss-dive fix; school tax +4 + Bard→Archer; cast scheduler+interrupt = Bellreach kick-or-wipe; dispel typing = Mire P4 Nature-curse); **P.4 done** (shield/guard kill-priority = the Leaden Carillon summon-shield boss); **P.5 done** (P.5a stacked-shield nerf · P.5b berserker fix · **P.5c the DPS-check / regime shift — survival-bound→timer-bound, generic-EHP demoted, comp spread 3.3, all reads verified/repaired**). **Follow-ons:** P.5d (P9 self-heal enemy + anti-heal/purge), P.5e (P7 eruption), magic-spec pass (pyro ST → Pyreward school read) |

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

## Phase B — Runtime loop & persistence 🟡 (13/14)

| # | Task | Axis | Sev | Effort | Status | Notes |
|---|---|---|---|---|---|---|
| B.1 | `GameState` runtime model | engine | blocker | L | ✅ | `src/state/game-store.tsx` — mutable roster/wallet/keystone/week via React context + reducer; screens read live state |
| B.2 | JSON save/load + versioned migrator | engine | blocker | M | ✅ | localStorage JSON + version field (now v4); reset-on-mismatch; **plus sanitize-on-load** (backfills any member missing `.key`, drops legacy non-ticket history) — added after a shape-change crash. Full stepwise migrator still later. |
| B.3 | Keystone progression + week/affix advance | engine | blocker | M | ✅ | **margin-based** (timed +1/+2/+3 by timer margin, deplete/wipe −1, floor 2); week affixes from the season calendar. Now **per-member** (see B.12) — each key levels independently on its owner's run. |
| B.4 | Full loop wiring | engine | blocker | M | ✅ | party picker → tactics → run → review → File Report applies it → repeat. Verified end-to-end via UI + store |
| B.5 | Loot generation + assignment + loot drama UI | engine/ux | major | M | ✅ | generation → real gear items in the stash + equip assignment done (B.8); the **loot-drama** mechanic + UI shipped in **M.2** (contested-item resolution, winner +5% / personality-gated loser morale, ⚔ badge + Auto-best-fit on the Loot screen). The **bark** layer on top is M.3/M.4 → M.5. |
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
| C.1 | Dungeons 2–6 | content | major | XL | ✅ | **All 5 new dungeons authored + verified** (`Dungeon-Design-Proposals.md`): **Bellreach** (interrupts; read log-visible → C.9), **Stillhour** (burst-heal→Cleric) + **Weltering Mire** (rot-heal→Lifebinder) the C.10 healer pair (soft ~1–2-key, "player not class"), **Pyreward Ossuary** (damage-school via C.8; soft ~1–2 school keys), **Hour of Bells** (cooldowns gauntlet; Cooldowns dial ~4-key swing — a *dial* read, allowed to bite). 6-dungeon season complete. Probes: `*-live.mjs`, `healer-ceiling.mjs`, `pyreward-ceiling.mjs`. Mechanics-first + placeholder loot (real loot/tier-sets = C.4/C.5). Open polish: C.9 (sharpen the soft dial reads), per-encounter cadence, IP rename |
| C.8 | Per-enemy armour/resist (damage-school wall) | engine | minor | S | ✅ | `EnemySchema.armour/resist` (default 0 → Ashveil byte-identical) → `makeEnemy` scales by keyScale; existing `pipeline.resolveHit` routes Phys→armour/Magic→resist. Powers **Pyreward Ossuary**. **Caveats found:** the ratio formula is *sticky* (coarse tuning); trash must be **front-melee** (caster trash makes it an AoE check, not a school check); single-school also pays a spec-power penalty (2 strong DPS/school) so raw gap > the ~1–2 *school* keys. `tsc -b` clean; egm-smoke unchanged |
| C.2 | **Per-spec talent trees** (the prioritized pre-P.5c work) | content | major | XL | ✅ | **DONE 2026-06-23 — 10 per-spec trees authored (150 options) + balanced (M1-M8).** Design rev. 2026-06-23 (Umut review applied). Re-scoped: **≥15 nodes/spec grouped into ~5 tiers of 3 mutually-exclusive choices** (pick 1 of 3 per tier), each a **real playstyle tradeoff** (AoE↔single-target · survival/defensive↔output · self-sustain↔raw damage · burst↔sustained · lean-into↔away-from the spec's class-tool), **WoW-inspired** (retail + classic talent design) but with **bright Warcraft-style class-fantasy names, IP-safe** (no verbatim WoW, no gothic drowned-barrow vocab; machine-audited for cross-spec collisions + WoW-verbatim leakage). Covers the **10 active specs**; the Necromancer (Bonecaller/Pallbinder) is **💤 deferred** (kept at the end of the doc). Design report: `Docs/Talent-Trait-Revamp.md` (multi-agent investigation). **Sequenced BEFORE P.5c** (talents are sim power inputs — calibrating the regime before the revamp = double-tuning; see P.5/Open-Decisions). **Umut review pass (2026-06-23):** seconds-not-turns player-facing (`secondsPerTurn=3`); Guardian Tier-3 remade off the deferred P7; paladin DR/absorbs generalised to any-damage **timed windows** (not DoT-typed → tick-tagging plumbing cut); **anti-heal added to Archer** (P9 no longer Berserker-only); `abilityOverride` kept Zod-strict (enumerated, no loose bag); `+maxHP%` safe-picks varied per spec; **summon/pet engine re-scoped as a general system** (enemy adds + future necro), its own milestone. **Engineering keystone** = unify talent `onlyIf` onto `condHolds()` + gate intake/crit (unblocks 11/12). **Build plan ✅ `Docs/Talent-Build-Plan.md`** (2026-06-23, grounded on a 5-agent code map): **M1** §A keystone → **M2** §B abilityOverride → **M3** §C+E status/riders → **M4** §D atonement → **M5** §F tank tools → **M6** §H summon engine → **M7** author 10 trees + picker + seconds-display → **M8** balance → P.5c. Goldens byte-identical M1-M6, deliberate rebump at M7. **M1 ✅ shipped 2026-06-23** (talent `onlyIf` unified onto `condHolds()` + 6 new predicates + runtime conditional intake/crit channels; egm-smoke byte-identical; functional probe `web/scripts/talent-cond-verify.mjs`). **M2 ✅** (`abilityOverride` — strict discriminated-union patch kinds cooldown/targeting/param/scalar/addModifier, clone-and-patch at buildParty so shared content is never mutated, cross-ref validated). **M3a ✅** (event riders — on-hit/crit/kill → applyStatus / adjustCooldown / refundResource / heal, wired in `afterHit`, cross-ref validated). **M3b ✅** (anti-heal: a `healingReceived` statMod, honored in `eff()`/`healInto`, cuts a bearer's incoming healing — the P9 channel). **M4 ✅** (atonement: per-ability disable + party-swap-when-an-ally-is-low, via a pure `atonementTargets`; magnitude via M2 `param`). **M5 ✅** (`selfHoldsHardThreat` wired = the alive party tank; the other §F tank tweaks — thorns/block/redirect/grip params — are M2-`abilityOverride`-covered; the net-new Guardian-capstone mechanics (locked-taunt, untargetable-while-taunt) ship with their abilities in M7). **M6 ✅** (general enemy-add spawner `spawnSummonedCombatant` extracted from the guard code — reusable for any boss/affix add; party-pet deferred with necro). **M7a ✅** (structure: `TalentNodeSchema.specId` optional [back-compat → globals still apply, byte-identical], `resolveTalents`/picker filter by spec, SpellTip shows seconds). **M7b ✅ shipped 2026-06-23** — the **10 per-spec trees are live** (50 nodes × 3 options = 150 in `talents.json`, M1-M6 vocab; Archer = `specId:"bard"`; global MVP nodes dropped; anti-heal statuses + `selfHitSinceLastAction`/`targetHpAbovePct` conditions added; store sanitize drops stale nodeIds, no SAVE bump; SignatureCard + skills.json prose seconds-clean). **Goldens deliberately rebumped (938/978/1208/1414, all timed, 0 deaths); +2 floor times for all 4 comps**; 10-agent adversarial audit → fixed a real no-op class (talent `dmgPct` gates `livingMobs[0]` ⇒ `targetBand:back` unreliable → reworked to riders/`addModifier`s), a cd-text bug, and 2 near-inert healer nodes; Playwright `talent-picker-live.mjs` PASS. **Known engine gap → M8/future: no healer-output (heal/HoT-magnitude) talent channel** — Lifebinder/Cleric throughput nodes lean on cooldown-reductions + Cleric atonement-`dmgPct` + self-survival; design's one-shot/party-buff/status-magnitude hooks are intentional proxies pending engine support. **M8 ✅ shipped 2026-06-23** — power-equality harness (`talent-balance.mjs`, role-aware, clear-DURATION metric on trash+boss): the trees are already **power-equal by content** (DPS tiers' boss-winner = single-target/execute, AoE/utility win their content; spreads 2-11%; no dead/dominant options; tanks/healers tight + survival-bound). One tune (Pyromancer Smothering Ash burn-amp 35→60). **+2 floor 6/6**, **operator runway +2**, determinism reproduced. Known limits → P.5c/future engine: no healer-output (heal/HoT-magnitude) channel; survival options non-differentiable on no-death clears; absolute ceiling dropped (~+18→+15 fresh @ cap from the M7b rebump) — **`keyScalingPerLevel` recalibration is P.5c's job, not pre-empted here.** **C.2 COMPLETE → next is P.5c** (regime tuning, once against the final trees) |
| C.3 | Enemy roster breadth | content | major | XL | ⬜ | ~50–70 total (have 7) |
| C.4 | Item breadth + secondary pool tuning | content | major | L | ✅ | **Item roster: 35 items, full 10-spec × 6-slot coverage** (2026-06-24, was 12 = only guardian/cleric/berserker; 7 specs had ZERO items). weapons by TYPE — shared/interchangeable (1H-sword/flail+shield [guardian,crusader] · staff [arcanist+pyromancer+lifebinder+cleric] · daggers/fists [assassin,mystic] · 2H axe [berserker] · bow [archer]) · armour by **TYPE** — plate (warrior+paladin) / leather (rogue+sage) / cloth (mage, +necro later); every piece wearable by ALL its type's specs (player picks which of their specs it suits) · role trinkets + 2 legacy; **secondaries roll RANDOM per drop** (hunt the roll); WoW-cadence IP-safe names; 23 new + 12 existing (3 cleric pieces extended to crusader). Drops now pull from the **full roster filtered to party specs** (`computeLoot`); per-dungeon `lootTable` superseded/reserved. Icons = GameIcon `item-{id}.png` (user-supplied). **Item-stat system in progress** (Umut, 2026-06-24): rarity-scaled stat blocks — ilvl×slot = budget, **rarity multiplies the whole block incl. main stat** (Common 1.0/Uncommon 1.06/Rare 1.12/Epic 1.25) + gates secondary count (0/1/2/2) from {Haste, Crit Chance, Crit Damage, Versatility}, max 2/item. Power/HP spike intentionally rides on rarity (observe playstyle). Build: **M1 ✅** (schema+generation `item-stats.ts`, deterministic, backfill-on-load, balance-neutral) → **M2 ✅** (sim sources power/HP/armour from `effIlvl`=Σmainstat/MAIN_K; harnesses fall back to raw ilvl → egm-smoke byte-identical; Epic 1.25 → +18-20% DPS spike, dampened from +25% by flat ability base) → **M3 ✅** (all 4 secondaries wired at `SECONDARY_RATING_K`=20: Haste→speed, Crit Chance→crit%, Crit Damage→crit mult, Versatility→+output%/−intake% [floored channel]; egm-smoke byte-identical; epic+~300/stat → +37% Assassin … +65% Berserker [haste×rampage]) → **M4 ✅** (WoW-style ItemTip + rarity colours [Common #fff/Uncommon #1eff00/Rare #0070dd/Epic #a335ee] on name/icon-border/tooltip-border, Character + Loot screens) → **M5 ✅ DONE 2026-06-24 (observe + secondary-pool-tuning call):** faithful geared-season sweep `item-gear-sweep.mjs` (gears parties exactly like the run-party path — full `rollItemStats` set → `effIlvl`/`secondaries`, **rarity the only swept variable**) + a 5-agent adversarial verify. **Observed (realistic RANDOM rolls):** full-Epic vs Common single-target DPS **+54–82%, mean +73%** (Assassin the ST-king spikes *least* at +54% → no runaway), **inside the documented +60–90% intent**. Timed key-ceiling Epic−Common **+4–11, mean +8.1 keys** = the ordinary gear slope (Epic effIlvl 200 vs Common 161 = +39 effIlvl ÷ ~4-per-key ≈ +9.75 predicted), **not** a super-linear multiplier; rarity behaves like ~+39 ilvl. Vers **double-contained** (`VERS_OUTPUT_FACTOR`=0.4 output side + `INTAKE_FLOOR_FRAC`=0.4 intake floor) → stays the safe/survival pick; offensive order Haste≈CritChance ≫ Vers > CritDmg. **DECISION: KEEP `SECONDARY_RATING_K`=20 & `VERS_OUTPUT_FACTOR`=0.4** — the only out-of-band figure (a +122% Haste+CritChance stack) is **unreachable in normal play**: `rollItemStats` picks 2-of-4 secondaries by uid-seeded RNG with **no reforge/reroll** (can't assemble a uniform hunted pair across 6 slots) and Epic is key-gated (`rarityForKey`≥14, ilvl coupled via `dropIlvl`). **⚠️ Re-evaluate iff a reforge/targeted-loot feature ever lands** (it would make the Haste+CritChance pair the universal best and collapse the which-2-of-4 choice). M5 added **only a script** — no engine constant changed; `tsc -b` clean, egm-smoke byte-identical to HEAD. **C.4 COMPLETE.** |
| C.5 | Tier-set content | content | minor | M | ⬜ | 10 sets, 2pc/4pc + piece assignment |
| C.6 | Full affix calendar / season content | content | minor | S | ⬜ | season.json calendar exists; expand + finalize |
| C.7 | Earned-trait event pools (full trigger detail) | content | major | M | ⬜ | 4 pools designed; firm up trigger thresholds |
| C.9 | Tactic-mechanic lethality pass (make the reads *bite*) | balance | major | M | ⬜ | The abstract boss-mechanic coefficients (interrupt cast 16·/ positioning 18·/ cooldowns-party 14·) are too soft at gear-appropriate ilvl — the tactic read is **log-visible but doesn't flip timed↔wipe** (proven on Bellreach, proposals §8.3). Tune the **global** coefficients (and/or land **per-encounter weighting**) so a starved dial actually wipes where the right dial times. **Affects Ashveil's Vesk + Bellreach** (the burst-variant Stillhour is already a hard read via **C.10**). Do it **once** after the pure-data dungeons are authored — not per-dungeon. Re-verify the +2 floor still times afterward |
| C.10 | Burst/rot boss-mechanic variants (soft healer levers) | engine | major | M | ✅ | Opt-in `spikeProfile:"burst"\|"rot"` (EnemySchema; both `testsTactic:cooldowns` so the dial mitigates; Ashveil untouched). **burst** = single hit on the lowest-HP non-tank /6s (`BURST_FRAC` 0.06) → soft Cleric edge. **rot** = flat tick on each non-tank /3s (`ROT_FRAC` 0.06) → soft Lifebinder edge. Tuned to **"player not class"**: both healers clear low/mid, ideal one extends the ceiling **~1–2 keys** (Stillhour Cleric ~+13 vs HoT +12; Mire Lifebinder ~+9–10 vs Cleric ~+8). `engine.ts`+`schema.ts`; `tsc -b` clean; egm-smoke unchanged; sweep `healer-ceiling.mjs`. ⚠️ **See C.11** — these reads turned out to be survival-dominance artifacts |
| C.11 | **Comp-balance / survival-dominance pass** (the big one) | balance | **major** | **XL** | 🔴 | **Audit (2026-06-21, `balance-sweep.mjs`, 10 comps × 6 dungeons):** comp ceilings spread **7–12 keys** (vs intended ~1–2). Root = **survival-bound regime** (2-healer caps *above* 3-DPS). Drivers: spec-utility inequality (Crusader party-shields ≫ Guardian; a support-DPS Arcanist/Bard = +6 keys over selfish; Crusader Divine Shield bug = `scale 1.0×maxHp` full-HP shield) + **back-band bosses diving squishies** (correctness bug — bosses should tank-and-spank). **Decisive lever:** lowering `enemyDmgMult` 2.0→1.5 → timer-bound → Ashveil spread 3, Pyreward 6. **CRITICAL FINDING:** fixing the boss-dive bug **erases the C.10 healer + C.8 school reads** — they were survival-dominance artifacts, not the burst/rot/armour mechanics. DIAL reads (cooldowns) are real and survive. So **balance vs class-reads conflict** — needs a directional decision (regime-shift + re-tune reads via stronger mechanics, vs keep current reads + spread). **Blocks meaningful loot/ilvl calibration.** Tooling: `balance-sweep.mjs` (full), `balance-probe.mjs` (fast) |

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
| D.10 | Telemetry / run-analytics pipeline | engine/infra | major | M | ⬜ | **Sequenced AFTER Phase P.** Log the `RunTicket` (comp/specs/talents/gear/tactics/key/affixes + outcome/timer/deaths) + version stamps to **one HTTP sink (Supabase Postgres) from BOTH web & Steam** — Steam-native Stats are NOT an analytics sink (leaderboard only). Determinism ⇒ ship inputs, re-derive damage/log by re-sim (tiny payload, retroactive analyses). PII-strip (drop player-authored char names; anon installId), consent + Steam data disclosure + opt-out; fire-and-forget (never blocks a run). Stamp schema/SAVE/content/buildTarget — **don't pool pre-P vs post-P runs for balance**. Feeds C.11 (spec/talent pick-rate vs win-rate from real players) + retention/refund signal. Module = `telemetry.ts` (`logs/analytics.ts` is the in-app WCL-style meter view). Plumbing can ship with the Vercel friends-test; **trust balance data only after Phase P settles**. |

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
| G.4 | New-art seams (gated on user-supplied assets) — dungeon banners, ability/talent/trait/item icons, operator-skill icons, affix icons | assets/ux | major | L | 🟡 | **Pipeline switched to full-colour raster** (`GameIcon` renders `/icons/{prefix}-{id}.png`; the SVG-mask path retired; a missing file degrades via `onError` → `affix-default.png` for affixes, `icon-default.png` (the bear) otherwise — drop a PNG in = wired). New **`ability` kind** added + surfaced inline in the event-log spell names, the spell-tooltip header, and the Character-sheet **Signature** card. **89 user PNGs wired** (`Docs/Icons/` → `web/public/icons/`, 10 typo-renames): **53/70 abilities**, all 10 specs, 3 roles, 3 operator skills, 3 currencies, 5 ui, 4 tactics, 2 affixes. **Scope cuts (Umut):** **dungeons reuse `ico-key`** (no per-dungeon art — `kind:"dungeon"` resolves straight to the keystone icon); **stat-ilvl shows as a number** and **secondary stats (crit/haste/mastery/versatility) render as text WoW-style** → **no stat icons needed** (dropped from `icon-tracker.csv`). **Still missing art** (→ bear/affix-default for now): **16 abilities** (shadow-step · 6 Bard [deferred to L] · 10 majors), **6 affixes** (bursting/bolstering/volcanic/sanguine/spiteful/raging — currently blank), **ui-trait**, and **items / talents / traits** (none provided). UI-only → `egm-smoke` byte-identical. Verified `tsc` + `g4-live.mjs` (icons render, raster, tooltip, no broken images, 0 console errors). |

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
| I.2 | Replay canvas (SVG/DOM): backdrop, party orbs, pack rows, HP bars, status pips, floating text | ux | major | L | ✅ | **v2 = faked-spatial arena** (reworked from band-rows after an EGM-decompile study — see the 2026-06-20 changelog): combatants are **dots on a dungeon-tinted field** (party = portrait dots in front/back columns by spec position; enemies = the active stage's mobs split front/back + centered boss) with **deterministic seeded positions** — the sim stays band-based, so positions are cosmetic/derived (no engine change). **Combatants close into a tank-centered scrum like EGM** (movement pass): the party walks a **continuous seeded path** — START → station(pack 1) → station(pack 2) → … so it does NOT reset between packs; each **pack spawns at a deterministic point ANYWHERE** in the arena and its **enemies converge onto the tank** while the **party marches to that pack** (slow ~14s ramp → visible travel). The tank anchors the contact, **enemy melee pile onto it** (M+ behavior), party melee-dps cluster around it with **casters tight behind**, and on boss stages the party fans onto the boss. A **per-attack lunge** jabs melee at their target; a gentle **real-time CSS idle wobble** (`.replay-idle`, paused on scrub) keeps everyone alive without the jitter a clock-based idle would alias into at the ~5 sim-sec/tick playback cadence. **Canvas height doubled** (`H` 800). Per-dot HP bars; attacks fire as **SVG targeting lines + melee swipes + ranged projectiles + impact rings + arcing pop-in damage numbers**, derived from the log, windowed + **gated to playback** (scrub-safe). Width measured via ResizeObserver for px geometry. (Status pips still deferred — they need an additive per-combatant status emit.) |
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

## Phase M — Guild Feed & Loot Drama (always-visible social meta-layer) ✅ (5/5 — v1 done; M.6 = v2 💤)

*An **always-visible** guild-chat panel in the Logs UI, **meta-layer only** (no in-run combat log). Two voices:
**system notifications** (the game, neutral/factual — the notification-center backbone with complete coverage) and
**in-character solo barks** (a roster member in their own personality voice — flavor, curated to ~**1–2 barks/run**).
Multi-character exchanges ("beats" — bots talking **to each other**) are the **v2** upgrade (M.6). The unlock that makes
it scale to a **procedurally-generated roster**: **voice attaches to personality (trait/archetype), never identity** — a
random member inherits a voice pack for free. Loot drama is the feed's flagship customer. See memory `goatlite-guild-feed`.*

| # | Task | Axis | Sev | Effort | Status | Notes |
|---|---|---|---|---|---|---|
| M.1 | Always-visible feed panel + **system-notification** layer | ux/engine | major | M | ✅ | persistent right-rail `GuildFeed.tsx` (visible only in the `playing` phase) reading a new persisted `feed: FeedEntry[]` + `feedSeq` on `PersistState`; notifications **emitted from the reducer** (all data in scope) in neutral game-voice, **zero comedy**: guild founded (`CREATE_GUILD`), member joined (`CONFIRM_RECRUITS`), run filed w/ outcome+time+deaths + loot-dropped (`RAN_KEY`), loot equipped + keystone raised/depleted + operator level-up + morale **at-risk crossing** (all `CONFIRM_LOOT`). Member-tagged lines click → character sheet. **No SAVE_VERSION bump** (additive field + defensive load guard → pre-M saves load with an empty feed); feed capped at 200. **Deferred (no engine yet):** trait-earned (D.1) + departure-warning (D.2) lines. Verified: `tsc -b` clean, `egm-smoke` goldens **byte-identical** (914/884/1182/1367 — no engine touched), Playwright `m-live.mjs` 9/9 + 0 console errors. |
| M.2 | **Loot-drama mechanic** (contested-item resolution) | engine/ux | major | M | ✅ | A **SNUB** that fires only on a real player CHOICE — never on shared loot (the original "every 2+ award" trigger drained morale every run; reworked). Two snub paths in `CONFIRM_LOOT`: **(A)** you award to a member while a **skipped member had a materially bigger ilvl claim** (gap ≥ `LOOT_SNUB_GAP`=5; extra sting if ≥ `LOOT_BIG_GAP`=12), or **(B)** you **scrap an item that was a significant upgrade** (≥ `LOOT_SCRAP_MIN`=8) for a member. Awarding the **best fit** (or one-click **Auto best-fit**) costs nothing → **drama is opt-in**. The snub fires the now-wired **`lost-loot` morale event**, magnitude **personality-scaled** (Selfish −8 / Boomer·Casual-Andy −2 / else −5), stacking on the outcome morale, + a marquee **`Loot snub …` feed line** (M.1). **Winner +5% buff dropped** (was an always-on power creep) → loot drama is **purely social, zero balance impact** (sim threading reverted; `egm-smoke` byte-identical). **No `SAVE_VERSION` bump**. **UI** (`LootPage`): a **BEST FIT** tag on the no-drama choice, a `Wanted ×N` info chip, a live **⚠ warning** when the current pick would snub someone, + Auto best-fit. **Verified:** `tsc -b` clean; `egm-smoke` **byte-identical** (914/884/1182/1367); `op-verify` +2 floor + determinism; `m2-live.mjs` — snub on a bad pick (incl. morale Δ) AND **no snub on a best-fit award** — **0 console errors**. (Barks on top = M.5.) |
| M.3 | **Bark engine** (procedural, deterministic) | engine | major | L | ✅ | `web/src/state/barks.ts` `generateBarks(moments, seed, recent)` — a **pure, seeded** (`Rng` mulberry32, no `Math.random`) selector: collects the run's emotional moments in `CONFIRM_LOOT` (loot snub=100 / wipe=90 / clutch=80 / morale-crater=70 / push=50 / depleted=45 / timed=20), sorts by priority, applies a **rarity budget** (high-emotion ~always barks, low-stakes ~40%, a 2nd bark gated) for **~1–2 barks/run**, one per speaker. Voice = **archetype(tone)** routing to the bank × **morale(mood)** banded-interjection prefix × a **per-character seed** for individuation; **state-grounded** slot fills (`{item}{winner}{dungeon}{key}{margin}`); **no-repeat window** (`barkLog` last 16 template keys, persisted). Works for **random members by construction** (voice = personality, not identity). Barks append to the same feed as `kind:"bark"` (speaker name in spec colour + italic). Verified `m3-bark.mjs` (determinism / variety / routing / no-repeat / rate-limit / mood). |
| M.4 | **Personality voice-pack content** (tiered) | content | major | L | ✅ | `data/barks.json` (new Zod-validated content domain `BarksSchema` → `content.barks`): 7 events × 5 archetypes (Selfish / Wildcard / Specialist / Enabler / Leader) + a `default` fallback + a `moods` bank — **~90 templates**. **Two-layer voice** holds: earnest grim item/dungeon names, ALL satire in the reaction (e.g. *"Treads of Quiet Rest was a bigger upgrade on my sheet but sure, feelycraft it to Bramblewen."*). Loot-snub is the richest bank (the flagship). Grows on observed repetition. |
| M.5 | Loot drama **in the feed** (flagship integration) | ux | major | S | ✅ | falls out of M.2+M.3: a contested **snub** now emits BOTH the marquee **system line** (`Loot snub — X took {item} over Y's bigger claim`) **and** an in-character **bark** from the snubbed member (priority-100 moment → `loot-snub-loser` bank), side by side in the feed — the shareable-screenshot moment. The deeper rival-callback ("*i called that three runs ago*") + repeat-snub Rival escalation stay **M.6 (v2)**. Verified live (`m3-live.mjs`: the snub produces a bark from the snubbed member). |
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

## Phase P — Class-Tools System (classes bring different tools to solve different problems) 🟡 (5/6)

*Design ✅ `Class-Tools-System.md` (2026-06-22). **Replaces the "player not class" tuning of C.10/C.8**: class choice now
MATTERS — each dungeon poses a typed PROBLEM answered by **2–3 different class TOOLS** (diversity, no mandatory comp), and
the SPECIFIC tool wins, never generic survivability. Resolves the C.11 audit's open conflict. One commit per milestone;
execute later.*

| # | Task | Axis | Sev | Effort | Status | Notes |
|---|---|---|---|---|---|---|
| P.0 | **GATE 0** — fix boss-dive bug + global intake-floor (40% / cap-60% stacked) + steepen `resolveHit` school curves; **bump SAVE_VERSION** | engine/balance | major | M | ✅ | **DONE + verified** (2026-06-22). Boss-dive fix (`stats.ts` `makeEnemy`: bosses → `melee`/focusTank, dives stay on trash casters + spikeProfile); hit-size-INDEPENDENT school wall for enemy defenders (`pipeline.schoolWallFraction`, K=380/cap-0.5, armour/resist no longer keyScale-scaled); percentage-only intake floor `intakeFloorFrac=0.40` in `dealDamage` (shields/HoTs excluded per decision); `SAVE_VERSION 5→6`. `tsc -b` clean. **Sweep (before→after spread): Stillhour 3→0, Mire 7→0** = the C.10 burst/rot reads **were survival artifacts, now collapsed** (decisively settles C.11); Pyreward 12→6, Hour 6→1. **egm-smoke shifted 884/914/1182/1367 → 894/953/1190/1380** (intake floor caps the gear-cap tank's armour; determinism + **+2 floor hold**). **⚠️ Ashveil spread 8→9 — the `<2` target was NOT met:** Ashveil is front-boss/no-armour so P.0's 3 levers don't touch it, and `CrusaderTank` still wins all 6 (avg 15.0) via **shields + 2nd-healer throughput** — neither touched here. → generic-EHP compression re-scoped to **P.5** (shield recost + Divine Shield bug) + the new **DPS-check** lever (see P.5 note) |
| P.1 | **Pyreward school re-tune (works-now) + Bard→Archer recut** | balance/content | major | M | ✅ | **DONE (2026-06-22).** **P.1a:** `schoolWallFraction` K 380→**155** (cap 0.65 = safety only, not binding for Pyreward's 250/150 — K is the lever); hit-size-independent so a fully-walled boss trips soft-enrage (an evenly-alternating layout is otherwise mirror-symmetric). **Off-school tax = net +4 keys.** **P.1b Bard→Archer:** spec **display→"Archer"** (id stays `bard` for save stability), recut all 6 abilities + the major from support→**selfish ranged physical DPS** (Barrow-Quarrel ST+Mark · Marrow-Piercer focus-nuke+execute · Over the Barrow back-band reach ×1.3 · Carrion Hail AoE · Cold Focus self-window · Unerring Eye selfish passive · Culling Rain offensive major) — **dropped ALL party support** (lust/heal/cleanse/CD-reduction/song-heal); tuned at assassin-parity; names IP-checked (no WoW-verbatim). **Verified:** content validates (Zod), `tsc -b` clean, egm-smoke byte-identical (894/953/1190/1380 — no archer in that party), net school tax **holds at +4** post-recut, +2 floor holds. **Key finding:** removing the bard-heal dropped the all-physical comps (AllPhysDPS avg 12.0→10.0, Ashveil 11→6) — confirming the **support-DPS confound is gone** — and **exposed a pre-existing magic-DPS≫physical-DPS imbalance** (pyro/arcanist out-scale berserker/archer ~9 keys on the no-wall control via AoE trash-clear) → flagged for a **spec-power pass (P.5)**. Diversity guard (≥2 top answers incl. cleric-smite) still → P.5 full sweep |
| P.2 | **Enemy cast scheduler + real interrupt** → Bellreach = P1 | engine | **major** | **L** | ✅ | **DONE + verified (2026-06-22) — the flagship.** Real cast scheduler in `engine.ts` (gated to abilities flagged `interruptible:true` → only Bellreach's antiphon/drowning-psalm/final-peal; reuses their existing `shape:"cast"`+`telegraph`): the boss begins a cast every ~12s (telegraph = kick window); uninterrupted → a **STACKING party nuke** (`castStackGrowth` → wipe), `pendingCast` on the Combatant. Wired `{type:"interrupt"}` (`combat.ts`, was a no-op) to **cancel** the cast (Counterspell/Zen Strike); a landed **stun/silence/freeze** also cancels (daze doesn't). Dedicated interrupts are **held** (excluded from `dumpRotation`) so a kicker reserves its kick. Brain `interruptPending` pre-empts the rotation when a cast is up. Interrupts dial **demoted** to a weak auto-kick backstop (`castFallback*`). **Verified:** `tsc -b` clean, content validates, egm-smoke byte-identical (Ashveil's Vesk + Pyreward's Heretic stay non-castable → old dial → other 5 dungeons unchanged), live boot 0 errors. **Log probe (arcanist +5): 24/25 casts interrupted → TIMED; no-kicker: 6 casts land → WIPE.** Sweep: kicker comps Bellreach **+6** vs no-kicker **+2-4** (~+3-4 kick gap, in-band); +2 floor holds. **No SAVE bump** (pendingCast runtime-only; matches P.1 precedent). **Caveats → P.5:** `CrusaderTank` (+15) bypasses via shields, `TwoHealer` (+9) via 2nd-healer throughput (generic EHP); kicker absolute ceiling is low (+6 — a Bellreach-difficulty tune, not the mechanic); pyromancer's Meteor-stun is a *situational* kick (cd8), so the reliable kickers are arcanist+mystic. New harness `bellreach-ceiling.mjs` |
| P.3 | **Dispel typing + enemy→party status** → Weltering Mire = P6+**P4** | engine/content | major | M | ✅ | **DONE + verified (2026-06-22).** Real typed-dispel system: a `dispel` field on statuses + a `dispelTypes` field on cleanse effects (Cleric `Mass Dispel`=Magic/Curse, new Lifebinder `Unbinding Word`=Nature/Poison); `cleanseStatuses` only strips a status whose `dispel` matches (untyped cleanse unchanged). New **enemy→party curse**: the Mire's 4 rot bosses flagged `curse:"Nature"` → the engine lays a stacking **`creeping-rot`** DoT on the whole party every 8s that **ticks per stack** (escalates past flat HPS); resolved **data-driven** from the curse type (so a future Magic curse auto-wires its own status, not a hardcoded Nature one). Brain: new healer-only `dispelCurse` pre-empts the rotation to strip a matching curse (scoped to removable kinds); the pure-cleanse `Unbinding Word` is **held** out of `dumpRotation` so it fires reactively; a wrong-type healer (Cleric) returns null → can't answer. **The Mire rot (P6) ran hot post-P.0 (~+5 lifebinder edge)** so `ROT_FRAC`/`BURST_FRAC` were promoted to `tuning.json` and the rot softened 0.06→**0.04** (a +1 secondary spice), letting the **curse carry the read**: `curseBase`=0.06/`curseEverySec`=8. **Verified:** `tsc -b` clean; content validates (+ new cross-ref guards on `dispelTypes`/`curse`→status); egm-smoke byte-identical (894/953/1190/1380 — curse fires only on the Mire, Ashveil untouched); op-verify determinism + +2 floor; live UI 0 console errors. **Read (`mire-verify.mjs`, 5 seeds, gear-appropriate ilvl): Lifebinder ceiling +23 vs Cleric +18 = tool tax +5 (in the +3–5 band); Stillhour control gap +0** (proves it's Mire-specific, not lifebinder>cleric power); **mechanism — Lifebinder dispels (caps at 2 stacks → 0 deaths → times), Cleric can't strip Nature (hits 6 stacks → deaths climb → wipes +18+)**. Adversarial review (5-dim find→verify workflow) → 0 confirmed bugs; 3 latent hardening fixes applied (data-driven curse status, scoped `dispelCurse` scan, `dispelTypes`/`curse` cross-ref validation). **No SAVE bump** (creeping-rot runtime-only; matches P.2 precedent). **Caveats → P.5:** generic-EHP comps (CrusaderTank/2-healer) still bypass via shields/throughput; on the Mire the Nature curse makes the Lifebinder the only *clean* answer (P4 is secondary here — the full-substitute is heavy survival, narrowed at P.5). New harness `mire-verify.mjs`; live check `p3-live.mjs` |
| P.4 | **Shield/guard kill-priority + real summoned adds** (P11 recut + P8) → Hour of Bells | engine/content | major | L | ✅ | **DONE + verified (2026-06-22).** **User recut P11** from positional "reach" (which would globally break melee-vs-back-band) into a **SHIELD/GUARD kill-priority** mechanic, then chose to realize it as a **SUMMON-SHIELD BOSS** (unifying **P8** real adds). New engine primitives (all loose-schema, no break): `guarding`/`shielded`/`summonsId` enemy flags; a `shielded` enemy takes **99% reduced damage** (`sim.shieldGuardReductionPct`, applied as `damageTakenPct`=−99 via `eff()` now folding the base field) while a `guarding` ally lives; a `shielded` boss **summons a real `guarding` add mid-fight** every `sim.summonEverySec` whenever none is alive — spawned into `mobs[]` **and mirrored into the ReplayTimeline** (valid unique `ReplayMob`s, spawn-second HP) so the 2D replay shows adds appear/fight/die (`ReplayCanvas` gained a spawn-visibility gate). Brain: `decidePartyFocus` **focuses the guard first under the Kill Order dial** (K.4 tactics-as-orders). **Content:** **The Leaden Carillon** (Hour stage 3) = `shielded` + `summonsId:"bell-warden"` + `testsTactic:"killorder"`; the summon-only **bell-warden** guard; a summoner boss runs ONLY summon+shield (abstract dial suppressed). **Tuning:** reduction 99 / summonEvery 18 / carillon HP 28 / warden HP 4 — warded from t=0 (unskippable). **Verified:** `tsc -b` clean; content validates (+ `summonsId` + `guarding&&shielded` cross-refs); egm-smoke byte-identical (894/953/1190/1380 — P.4 only touches Hour); op-verify determinism + +2 floor; replay-integrity + determinism (summoned wardens are valid unique ReplayMobs); live UI 0 console errors. **Balance (`balance-sweep`): Hour spread 2** (standard comps +13/+14 = a fair ~1–2-key carillon cost; +2 floor 3/3); **all 5 other dungeons byte-identical to P.3**. **Adversarial review** (5-dim, 17 agents → 6 confirmed all minor/nit, 6 dismissed): **4 fixed** (self-warding soft-lock guard+validation; DoT ticks now respect the ward; warded-from-t=0; `leaden-toll` metadata aligned), **2 documented** (the read is a "flat damper" not a sharp burst-check — AoE out-ceilings via later-stage *survival*, the magic≫physical imbalance → **P.5**; dead-add skull lingers = pre-existing cosmetic). **No SAVE bump** (flags=content, summon/shield=runtime). Harness `carillon-replay.mjs`. **⚠️ Deferred: P7 (telegraphed eruption — Crusader immunity / Guardian relocate) NOT built** — the user's recut focused on the shield-guard; fold P7 into a later ticket. The reach/dive/grip + P7 from the original P.4 scope are superseded/deferred |
| P.5 | **Generic-EHP kill + DPS-check + P9 anti-heal + final kit recut** (the big balance milestone) | engine/balance | major | XL | 🟡 | **P.5b DONE (2026-06-22) — spec-power: berserker fix.** A controlled per-spec probe (`spec-power.mjs`, 1T/1H/3×spec) overturned the "magic≫physical" framing: magic vs physical avg is ~equal (ashveil 6.5 vs 6.7; stillhour 15.0 vs 14.7) — the real outlier was **berserker, broken-LOW** (ashveil +1, stillhour +5 vs the pack's +6–22), dragging down every comp that ran it (Meta-Cleric/AllPhys). Causes: low coefficients (0.6–1.0× vs assassin 0.9–1.4×), a brutal `blood-frenzy` **15%-HP self-cost** (lethal at scale), + an **unimplemented `low-hp-bonus-scaling` passive**. Fix: HP-cost 15%→5%, coefficients +30–40% (cleaving 0.6→0.85, whirlwind 0.7→0.95, bladestorm 1.0→1.35, massacre 0.9→1.2). **Result: berserker +1→+6 (ashveil), +5→+18 (stillhour); ashveil spec-spread 7→2; magic/physical balanced.** egm-smoke byte-identical (no berserker in the std comp); +2 floor 3/3; school + cast reads hold. **Comp-level payoff is modest so far (Meta-Cleric 9.8→11.0 avg) because the regime is still SURVIVAL-bound** (berserker comps wipe on Ashveil → more DPS doesn't help) — the fix unlocks the regime shift (P.5c). Probe `spec-power.mjs`. (Assassin top / arcanist-on-boss low = ST-vs-control niche, left as-is.) 🟡 **P.5c = the DPS-check / regime shift — NOW ACTIVE (C.2 complete).** Re-scoped (Umut, 2026-06-23) into **4 sub-milestones** — **M1 regime shift → M2 EHP recosts → M3 magic↔physical AoE → M4 verify+reads+ceiling-restore** — with **P9/P7 split out to P.5d/P.5e** (net-new mechanics, not calibration) and **NO mana** (Umut: balance via the DPS-check, accept unlimited HPS as inert in a timer-bound regime). **M1 ✅ (2026-06-23): the regime shift.** `enemyDmgMult 2.0→1.5` + `hpUnit 1020→1500` + `keyScalingPerLevel 1.052→1.05` flips the regime **survival-bound → timer-bound**: Ashveil spread **13→5** (the no-util 3-DPS Meta-Cleric now TOPS instead of −13), **generic-EHP demoted** (TwoHealer → lowest avg 9.8, CrusaderTank no longer tops), Stillhour/Mire pulled from "all +20 capped" to measurable (spread 3-4), Pyreward comp-balanced (spread 1). **+2 floor 6/6** (f6) + **determinism** (op-verify r1≡r2) + **operator runway +2** hold; egm-smoke goldens **rebumped** (938/978/1208/1414 → 1344/1379/1731-depleted/2014-depleted — the smoke comp is 1T/2H/2DPS, correctly DPS-demoted). Absolute @cap ceiling **compressed** (f6's 2H comp +15→+9; 3-DPS ~+11 hard / +20 easy) — **expected for a DPS-check; keyScaling ceiling-restore deferred to M4** (it depends on the M2 recosts to avoid re-inflating the Bellreach EHP-bypass). New tool `p5c-regime.mjs` (per-process SIM patch → parallel candidate sweeps). **Residuals → M2/M4:** Bellreach CrusaderTank +11 still bypasses the kick read (M2 Crusader recosts), Pyreward low ceiling from school-wall×HP double-tax (M4 wall softening). Validated direction (enemyDmgMult↓ + HP_UNIT↑) confirmed. **M2 ✅ (2026-06-23): EHP recosts** — Bulwark Banner party-DR → self/tank, Guardian's-Oath reduction 20→0 +cd 4→6, Blessing 2→1 +cd 5→6, Stalwart 15→10 + shield-amp 20-40→15-25. **Near-inert in the timer regime** (CrusaderTank ~parity, +0.7 over no-util, was +5 in C.11) — value = structural hygiene + M4 ceiling-restore insurance; egm-smoke +8 byte-identical. Flagged → M4: Bulwark recost dropped Meta-Cleric Bellreach +4→+1 (verify +2 floor holds on Bellreach / gate the stacking cast off the floor). **M3 ✅ (2026-06-23): magic↔physical — premise INVERTED by the regime.** spec-power shows physical now LEADS (boss: phys 18.7 vs magic 5.5) — the DPS-check favors ST over AoE. Full 10-comp sweep (`p5c-sweep.mjs` →+20): comp spread a healthy **4→3.5 keys** (9.8–13.3), magic comps viable; only laggard = AoE-Stack (no-assassin) + **arcanist broken-LOW** (mono +1/+4). Targeted arcanist buff (P.5b-berserker analog, egm-smoke byte-identical): **Arcane Bolt 0.65→0.95 + Frost Nova 0.6→0.8** → arcanist +3/+7, AoE-Stack 9.0→9.8, spread tightened. Known M4 artifact: op-verify B/C test point (key22/ilvl105) now an unwinnable wipe → recalibrate. **M4 ✅ (2026-06-23) → P.5c COMPLETE.** All-reads verified + repaired: **Mire curse RESTORED** (curseBase 0.06→0.25 → lifebinder +22 vs cleric +18, tax +4); **Bellreach kick survives** (no-kicker +1–5 vs kicker +8–12, +2 floor holds); **Hour carillon intact+deterministic**; **Pyreward school weak/correct-direction** (K=155; softening inverts it — blocked on magic≪physical → magic-spec follow-up); **burst/rot washed out** (regime, C.11-consistent). op-verify B/C recalibrated (key22→12) → 6/6 PASS; talent power-equality re-confirmed; **final comp spread 3.3 (10.0–13.3), generic-EHP demoted, +2 floor 6/6 every dungeon**; @cap ceiling left dungeon-varied (DPS-check intended). 5-agent adversarial review clean (no real issues). **P.5 (Generic-EHP kill + DPS-check) DONE; P9/P7 → P.5d/P.5e; magic-spec pass (pyro ST → Pyreward read) flagged.** The regime **direction is locked (timer-bound)** and should GUIDE the revamp (favor active throughput/utility talents over generic survival). P.5a/P.5b stay committed (spec/mechanic-specific, robust to the revamp). Do P.5c (+ the +2-floor + all-reads re-verify, + P9/P7) as the capstone once the power inputs are final. **P.5a DONE (2026-06-22) — stacked-shield nerf.** Recost the three CRUSADER/ARCANIST stacked shields that drove `CrusaderTank` (the standard Meta-Cleric/egm-smoke comps use neither, so this is a clean hit with **egm-smoke byte-identical** + the +2 floor untouched): **Divine Shield** `scale 1.0→0.4 ×maxHp` + `cd 3→8` (was a >100%-maxHp shield kept PERMANENTLY on the tank — the EHP engine; now a real cooldown ~37% uptime); **Sacred Bastion** party-wide→**single-ally** (no more party shield wall); **Arcane Barrier** `100+1.5×power → 50+0.6×power` (keeps the CC-immunity rider + barrier-break). **Result (balance-probe, cap 20): CrusaderTank −3 to −5 keys** (ashveil +20→+17, bellreach +20→+15, pyreward +17→+14); spreads compressed (ashveil 14→11, bellreach 18→13, pyreward 9→6). **Still owed (P.5b+):** the Crusader's *other* survival (guardians-oath 100% redirect, blessing-of-protection immunity, stalwart-defender shield-amp); **healer-throughput cap** (mana is authored in tuning.json but NEVER wired → 2 healers + lifebinder HoTs = unlimited HPS — the root of 2-heal dominance); **the §2.1 DPS-check** (raise boss HP / tighten timer so 1T/2H/2DPS runs out of clock); recost Bulwark Banner (→self/tank, since grip/intercept weren't built) + Light's Salvation + Blossoming Tide; **the magic≫physical AoE imbalance** (exposed once shields fell — also sharpens P.4's read); **P9** self-mending Pyreward boss + Berserker Grave-Wound anti-heal + enemy-purge; **P7** eruption (owed from P.4). Target: no generic comp tops the avg; every problem ≥2 diverse top answers; wrong-tool falls +3–5; +2 floor holds; P.0–P.4 reads survive |

| P.5d | **P9 — self-healing / empowered enemy + anti-heal/purge** | engine/content | major | M | ⬜ | **Spun out of P.5c (2026-06-23).** The anti-heal CHANNEL is already built (M3b `healingReceived` + riven-wound/serrated-wound statuses + Berserker/Archer on-hit riders). **Still to build:** a boss `healProfile` (periodic self-heal, mirror the `spikeProfile`/curse pattern) so a self-mending boss out-paces DPS *without* anti-heal; and **enemy-purge** (today `cleanseStatuses` strips only debuff/dot/cc on allies — no path to strip an enemy BUFF; enemies can't even hold buffs yet). Then a P9 boss (week/dungeon) answered by Berserker/Archer anti-heal · Cleric/Lifebinder purge. Design `Class-Tools-System.md` P9. |
| P.5e | **P7 — telegraphed eruption** (avoidable pulse on a flagged ally) | engine/content | major | M | ⬜ | **Spun out of P.5c (2026-06-23); originally owed from P.4.** Defensive primitives all EXIST (Crusader Blessing immunity *negates*, Guardian's-Oath redirect *relocates*, the P.2 cast scheduler + telegraph). **Missing:** the cast currently hits the whole party — make it single-target on a flagged ally (`pendingCast.targetId`, pick via `decideEnemyTarget`, single-target resolve, telegraph log). Then a P7 boss answered by Crusader immunity / Guardian intercept. Design `Class-Tools-System.md` P7. |
| P.5f | **DPS-identity pass** (Archer/Crusader/Berserker/Pyro/Arcanist) | balance/content | major | M | ✅ | **DONE (2026-06-23).** Broadened from the originally-flagged "pyro-ST → Pyreward" scope into a full DPS-identity pass (Umut: archer+crusader "look weird", berserker "best AoE + 2nd ST", "move pyro/arcanist up a bit"). Built `dps-dummy.mjs` (1/3/5-target training-dummy harness) + a 4-agent investigation. Surgical coefficient/pattern changes (no new mechanics): Berserker Cleaving 0.85→0.65 + Blood-Frenzy 25→20 (ST trim, AoE engine kept) → now **AoE king with the lowest single-target**; Pyro Scorch 0.6→0.85 + Arcanist Arcane-Bolt 0.95→1.18 (ST up, above berserker); Archer Barrow-Quarrel/Marrow-Piercer/Over-the-Barrow/Carrion-Hail up (kept Culling-Rain major) → ranged-ST generalist (no longer bottom); Crusader Holy-Strike single→adjacent (de-weird flat-20 → 20/40/40). **Result:** clean ST→AoE gradient — Assassin 284 (ST king) > Archer 178 ≈ Arcanist 176 > Pyro 166 > Berserker 165 on single-target; Berserker 565 > Pyro 431 > Arcanist 342 > Archer 268 on 5-target. **Side benefit: Pyreward school read flipped back to correct-direction** (magic > physical, +1-2 tax). +2 floor 6/6; egm-smoke rebumped (pyro); comp spread 4.0 (CrusaderTank crept +1 to 14.3 — documented, not dominance); operator runway compressed +2→+1. **Residual:** stronger Pyreward tax (+3-4) + the CrusaderTank survival creep = future comp/spec touch-ups. |

*Dropped: P10 tank-buster / threat-model (needs a 2nd tank). Hour of Bells keeps its cooldowns-dial identity; Ashveil stays the dial sampler. Cleaner standalone homes for P4/P9 reserved for the Necromancer-expansion dungeons.*

---

## Open Design Decisions (resolve before/while building the dependent task)

| Decision | Blocks | Status | Resolution |
|---|---|---|---|
| Talent/trait revamp vs P.5c regime tuning — order | P.5c, C.2, D.7 | ✅ Resolved | **Revamp talents/traits FIRST, then P.5c.** Talents+traits are sim power inputs (output/intake/hp/crit); P.5c is the global regime calibration → tuning it before the revamp = double-tuning the regime + all reads. The regime **direction (timer-bound) is locked** and guides the revamp (favor active throughput/utility over generic survival). P.5a/P.5b stay committed. |
| Talent naming register + IP | C.2, E.5, L | ✅ Resolved | **Bright Warcraft-style class-fantasy, IP-safe** (Umut, 2026-06-23) — reverses the original "earnest gothic" call. No verbatim/near-verbatim WoW spell/talent names (hard pre-launch gate), no heavy drowned-barrow vocab; renames machine-audited for collisions + leakage. Pre-existing ability-name IP-debt tracked separately for the scrub. |
| Talent `abilityOverride` validation | C.2 | ✅ Resolved | **Keep Zod strict — enumerate each override kind** (no loose `{abilityId, params?}` bag) so a typo'd param fails-closed like the current closed `onlyIf` enum (Umut, 2026-06-23). |
| Paladin DR/immunity: typed vs general | C.2, C.11 | ✅ Resolved | **General (any-damage), not DoT-typed** (Umut, 2026-06-23) — Crusader party-DR + Cleric absorbs — but kept as **timed cooldown windows** (predict-and-press), not flat EHP. **Cuts the DoT-tick-tagging plumbing** from scope (Talent doc synthesis §G). |
| P9 anti-heal coverage | C.2 | ✅ Resolved | **Two specs carry anti-heal** — Berserker (Riving Wound) + **Archer (Serrated Shot)** (Umut, 2026-06-23) — so a self-healing-boss week no longer hard-walls a Berserker-less group. |
| Summon/pet engine scope | C.2, L, D | ✅ Resolved | **Build a general summoned-combatant system regardless of necro** (Umut, 2026-06-23) — used immediately for **enemy adds on trash/bosses**, reused by the deferred Bonecaller later. Its own milestone (Talent doc synthesis §H). |
| Necromancer (Bonecaller/Pallbinder) timing | C.2, L | ✅ Resolved | **Deferred** ("might add later" — Umut, 2026-06-23). Active talent scope = 10 specs; necro trees kept in the doc under a banner, un-revamped until revived. |
| Tick rate / timeline model | A.3, A2.1 | ✅ Resolved | v1 ran 1s ticks; the **EGM rebuild (A2) runs continuous seconds** (DT=0.25 inner step, attack-speed-driven, mm:ss timeline). `tuning.sim` (hpUnit/dmgUnit/keyScalingPerLevel) calibrated to the GDD timer table for the 1T/1H/3D comp. |
| Client-only vs isomorphic sim | A.1, D.6, D.10 | ⬜ Open | leaderboard + telemetry re-sim want a shared/version-pinned TS sim |
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
| Telemetry stack + consent model | D.10 | ⬜ Open | Supabase (raw runs + SQL — leaning pick) vs PostHog (funnels/retention UI) vs thin Vercel fn; **opt-in vs opt-out** + privacy policy required for any public/Steam build |

---

## Changelog

- **2026-06-25** — **New Run fit-pass 3/3: party = 5 square slots + sortable/filterable bench → board fits one screen at any roster size.** Replaced the single scrolling roster list (`SetupPage.tsx`) with the loadout pattern (Umut, after a design pass): **5 square party slots** on top — spec art + name + ilvl, ★-locked key owner, × to remove others, dashed "+" empties; below, the **rest of the guild as a bench** — role **filter chips** (All/Tank/Healer/DPS) + **sortable headers** (Member/Role/iLvl/Morale, click to toggle dir) in a fixed-height (232px) scroll, click a row to fill the next open slot. Bench rows use `IconLabel` (merged spec icon+name), role icon-only, rarity-coloured ilvl, morale. This **bounds the panel regardless of guild size**, which — with the paginated key table (1/3) + compact tactics/aggression (2/3) — makes the **whole New Run board fit the 1080 canvas again with no page scroll** (verified at 13 members). **Verify:** `tsc -b` clean; `newrun-live` (now bootstraps a 13-member roster) PASS — exactly 5 slots, 8 bench rows with role icons + morale, **role filter (Tank) shows only tanks**, key table 10 rows + pager, aggression math, **0 console errors**; full-board screenshot confirms one-screen fit. Files: `web/src/logs/pages/SetupPage.tsx`, `web/scripts/newrun-live.mjs`. **New Run fit-redesign DONE (3/3).**
- **2026-06-25** — **New Run fit-pass 2/3: compact tactics (4-icon row) + thin aggression strip.** Tactics (`SetupPage.tsx`): the vertical list with inline descriptions → a **4-across row** — icon, name below, +/− dial below — with **no description text** (the tactic icon's hover tooltip already carries the full effect via `iconTip`); saves ~150px. Aggression: full panel (3 big buttons + prose + 2 math lines) → a **thin strip** — the seg-group inline with the **live math on one line** (`+15% output · +40% avoidable taken · +5% crit`, still derived from `tuning.json`); flavour moved to a hover `title`; saves ~50px. **Verify:** `tsc -b` clean; `newrun-live` PASS (compact aggression math inline, 0 console errors). Files: `web/src/logs/pages/SetupPage.tsx`, `web/scripts/newrun-live.mjs`. Next: 3/3 party 5-slots + sortable bench.
- **2026-06-25** — **New Run fit-pass 1/3: key table pagination + merged icon/name (`IconLabel`).** With a large roster the New Run board overflowed the 1080 canvas (13 keys → 13-row table, party list scrolling, page scroll). New shared **`IconLabel`** component (`components.tsx`) renders an **icon + name as one merged inline element** (with the icon's tooltip, or a custom `tip` wrapping the whole element) — the start of Umut's "icon and name are one element everywhere". Key table (`SetupPage.tsx`): KeyIcon+name merged into a single **Key** column (Epic-purple, whole cell pops the `KeyTip`), owner shown via `IconLabel kind=spec`, so it's **4 columns** now (Key · Affixes · Owner · Lvl); **paginated at 10 rows** with a "N–M of T" + Prev/Next pager, bounding the left column height regardless of roster size. **Verify:** `tsc -b` clean; `newrun-live` PASS (KeyTip via IconLabel, 0 console errors); 13-member screenshot confirms 10 rows + pager. Files: `web/src/logs/components.tsx`, `web/src/logs/pages/SetupPage.tsx`, `web/scripts/newrun-shot.mjs` (overflow repro). Next: 2/3 compact tactics + aggression strip; 3/3 party 5-slots + sortable bench. (`IconLabel` rollout to specs/items/spells = follow-up.)
- **2026-06-25** — **Boards update — New Run key table (N1/N4/N7/N8/N9) → boards-update batch COMPLETE.** Replaced the character-centric key picker in `SetupPage.tsx` with a **5-column key table** (`runs` table): **KeyIcon** (`GameIcon kind="dungeon"`, N1) · **Key** (the keystone as an **Epic item** — purple name, N9) · **Affixes** (the week's affix icons, dimmed when not yet unlocked at that key's level) · **Owner** (spec icon + name) · **Lvl**. Row click selects the key (holder locks into the party), selected row highlighted. **N4:** dropped the "week N" header text — the panel header now shows the selected key's **timer**. **N8:** deleted the two separate "Affix · Tier 1/2" panels — affixes now live in the table column + the new tooltip. **N9:** new **`KeyTip`** component (`components.tsx`), a WoW item-card for keys: purple "{dungeon} Keystone", "Keystone · +N · Epic", timer/best, and the week's affixes as rows (active = green, still-locked = faint with "unlocks at +N", using `activeAffixIds`/`affixUnlockKey`); the affix effect text flows from the N5 rewrite. A hint line shows when no affixes are live yet at the floor. **Verify:** `tsc -b` clean; `newrun-live` PASS — 5-row key table, **KeyTip renders on hover** ("Stillhour Abbey Keystone · +2 · Epic · Timer 25:00 · … Fortified · unlocks at +7 · Increases non-boss enemies'…"), party/aggression/button all still green, **0 console errors**. Files: `web/src/logs/components.tsx`, `web/src/logs/pages/SetupPage.tsx`, `web/scripts/newrun-live.mjs`. **Boards-update batch DONE (4/4) — all 14 findings (S1-S3 + N1-N11) shipped.** Deferred: the full WoW-tooltip copy-pass over ~71 abilities + ~150 talent options (own milestone, clean+light voice, numbers-match check).
- **2026-06-25** — **Boards update — scouting tweaks (S1 talent fallback · S2 remove blurb · S3 unify rating).** **S1:** `TalentIcon` (`TalentGrid.tsx`) now falls back to the app's default icon art (`icon-default.png`, like every `GameIcon`) instead of hiding the img to reveal a bare tier number — talents "use fallback icons" now and auto-upgrade when `talent-*.png` lands; a small tier badge in the corner keeps tier context. **S2:** removed the "Serviceable. Average across the board…" scout blurb from `ScoutDetail` (+ its `scoutBlurb` import). **S3:** COR and Potential are now **both numeric + consistent** — Operator Rating = precise COR, Potential = a deliberately **vague ceiling band** ("70+", via new shared `potentialLabel`/`potentialCor` in OperatorPanel; floor(stars×20 → 10s)+"+") so it keeps the scouting-estimate feel without false precision; the "how good now"/"how high they climb" sublabels are gone. Applied to the scout panel tiles, the recruit **table** Potential column, AND `CharacterPage` (parity, so the number/stars mismatch can't reappear). **Verify:** `tsc -b` clean; `scout-live` PASS — blurb absent, "Operator Rating … Potential 50+", talents popup 15 cells, **constant panel height 726px across all 12 recruits**, rarity invariant holds, **0 console errors**; screenshot confirms talents show fallback art + the consistent numbers. Files: `web/src/logs/TalentGrid.tsx`, `web/src/logs/OperatorPanel.tsx`, `web/src/logs/pages/RecruitPage.tsx`, `web/src/logs/pages/CharacterPage.tsx`. (Boards-update batch 3 of 4; remaining: the New Run key-table refactor N1/N7/N8/N9.)
- **2026-06-25** — **Boards update — New Run party + aggression (N2/N3/N6/N10).** Party rows (`SetupPage.tsx`): role pill → **icon-only**, added a **morale %** readout (hover-explained) beside the ilvl, and the **ilvl text is now coloured by rarity band** (`qualityColor(rarityForIlvl(m.ilvl))`). Aggression panel now shows **live math derived from `tuning.json`** so it can't drift from the engine — Safe "−10% party output · −30% avoidable damage taken · −3% crit", Yolo "+15% · +40% · +5% crit", Balanced "Baseline — no modifiers." The run button reads **"Start the Run"** (was "Simulate Run → View Report"). Lifted `moraleColor` + `MORALE_TIP` from RecruitPage into the shared `analytics.ts` (one source for the scout panel + roster + party so the <25 threshold can't drift). **Verify:** `tsc -b` clean; new reusable harness `web/scripts/newrun-live.mjs` PASS (5 role icons + 5 morale readouts, live aggression math Yolo/Balanced, button label, **0 console errors**). Files: `web/src/logs/pages/SetupPage.tsx`, `web/src/logs/analytics.ts`, `web/src/logs/pages/RecruitPage.tsx`, `web/scripts/newrun-live.mjs`. (Boards-update batch 2 of 4; remaining: scouting tweaks, key-table refactor.)
- **2026-06-25** — **Boards update — copy/data pass (affix wording + tactics rewrite).** `data/affixes.json`: tier-1 affixes reworded from ×-notation to plain percentage prose — Fortified → "Increases non-boss enemies' HP and damage by 30%", Tyrannical → "Increases boss HP and damage by 30%" (per Umut). `data/tactics.json`: rewrote all 4 `perPoint` + `starved` strings from cryptic/casual to a **clean WoW-tooltip voice with a light world touch** (exact engine numbers preserved — Positioning's 42%/24%/6% per-point, Cooldowns' +4%/−10% per point, Kill Order's +6%/pt). **Display-only — no engine number lives in these strings** (the ×1.3 multiplier + tactic effects are in the sim). Tone/scope decisions (Umut): clean+light voice; **tactics now, the full ~221-string skills+talents copy-pass is a separate future milestone**. **Verify:** `tsc -b` clean; content validates; `egm-smoke` **byte-identical** (1342/1356/1694/1954). Files: `data/affixes.json`, `data/tactics.json`. (Boards-update batch 1 of 4; remaining: New Run party/aggression, scouting tweaks, the key-table refactor.)
- **2026-06-24** — **Item rarity is now a step-function of ilvl (single source of truth) — fixes lower-rarity items out-leveling higher-rarity ones (Umut bug).** Rarity was set in 3 independent places; only drops kept rarity↔ilvl in sync, so a forced-Common starter piece (any ilvl) or a recruit's independently-rolled rarity could out-level a higher-rarity item. New **`rarityForIlvl(ilvl)`** in the pure `item-stats.ts` (`RARITY_ILVL_BANDS`: **Common <120 · Uncommon 120–135 · Rare 136–159 · Epic ≥160**) is now the **only** rarity determiner, used by all three sites: `makeDrop` (was `rarityForKey`, now deleted), `starterGear` (was forced Common), and `recruitGear` (dropped the independent quality-weighted rarity roll — recruit quality now rides on the **headline ilvl**, which naturally raises rarity at the band thresholds). So rarity↔ilvl is monotonic by construction: a lower rarity can't reach a higher ilvl than a higher rarity. **Old saves migrate on load** — `withStats`→**`normalizeGear`** re-derives rarity from ilvl and re-rolls the stat block to match (deterministic from uid → idempotent; **no `SAVE_VERSION` bump**). **Decision (Umut): "Epic at the cap"** — since both key-12/13 and key-14+ drops land at the capped ilvl 160, a pure ilvl rule makes **Epic drop at key 12+ (was 14+)**; **drops are identical for keys 2–11** (Uncommon 2–5, Rare 6–11). Epic's spike *magnitude* (×1.25) is unchanged — only the gate moved 2 keys earlier (the item-stats "+73% / +8-key, not a runaway" finding still holds). **Verify:** `tsc -b` clean; `egm-smoke` **byte-identical** (1342/1356/1694/1954 — sim reads raw ilvl in harnesses, untouched); `scout-live` PASS incl. new assertion **"rarity↔ilvl invariant holds across all recruits' gear"** + constant height + 15-cell popup, 0 errors; `ui-pass-live` **PASS end-to-end** (sign → first key → loot reveal, 0 errors). Floor-safe (rarity only ever ≥ the old value at a given ilvl → +2 floor can't regress). Files: `web/src/state/item-stats.ts`, `web/src/state/game-store.tsx`, `web/scripts/scout-live.mjs`.
- **2026-06-24** — **Scouting board redesign #2: scout panel is now a constant height → SCOUTING BOARD REDESIGN COMPLETE (6/6).** The panel grew/shrank with the selected recruit's **trait-flavor + scout-blurb** length (the only two per-recruit-variable text blocks — the Aptitudes flavor is the same 3 fixed strings for everyone, and header/tiles/gear/talents/skill-bars are all fixed). Clamped both to a **fixed 2-line height** (`height:35; -webkit-line-clamp:2; overflow:hidden`, full text on `title` hover) so the panel is one constant height without a fragile magic number. **Verify:** `tsc -b` clean; `scout-live` asserts **constant panel height across all 12 recruits (802px, one unique value)** + the 15-cell talents popup + spec/role icons + iLvl/morale + Aptitudes, **0 console errors**. Files: `web/src/logs/pages/RecruitPage.tsx`, `web/scripts/scout-live.mjs`. **All 6 scouting-board findings shipped:** (1) spec icon fills a tight border · (2) constant panel height · (3) first-class equipped gear reflecting ilvl · (4) talents strip + 5×3 popup · (5) operator skills → fantasy "Aptitudes" · (6) role icon-only header with relocated, hover-explained ilvl+morale.
- **2026-06-24** — **Scouting board redesign #4: talents section (selected-build strip + 5×3 popup).** New `web/src/logs/TalentGrid.tsx` `<TalentStrip>` inserted in `ScoutDetail` **between the top section and Aptitudes** (per the ask): a one-row strip of the spec's **selected default talents** (5 tiles, left→right) + a **"Talents ▾" button** that opens a **popup grid = 5 tiers (rows) × 3 options (cols)** for the spec, with the default build **highlighted** and **hover tooltips** (name + effect) on every option. Read-only — recruits show the spec's default build (the same defaults `resolveTalents()` falls back to; recruits have no per-member talent store). **Art-optional fallback:** no `talent-*.png` exists yet, so a new `TalentIcon` degrades to a **styled tier-numbered tile (not the bear)** and auto-upgrades when a PNG is dropped in (`/icons/talent-{optionId}.png`). Added a **`talent` case to `iconTip`** + a `TALENT_OPT` optionId→option map in `components.tsx` so any talent icon tooltips. The popup is a click-dismiss modal **portaled into the scaled `.vp-stage`** (via `useStage()`) so it sizes/centres with the 16:9 canvas instead of rendering at 1.0 in `<body>`. **Verify:** `tsc -b` clean; `scout-live` PASS incl. **"talents popup shows 15 cells (5×3) — got 15"**, **0 console errors**; screenshot confirms the highlighted default build + per-tier rows. Files: `web/src/logs/TalentGrid.tsx` (new), `web/src/logs/components.tsx`, `web/src/logs/pages/RecruitPage.tsx`, `web/scripts/scout-live.mjs`. (4 of 6 scouting-board findings; left: fixed panel height.)
- **2026-06-24** — **Scouting board redesign #3: recruits now carry a first-class equipped gear set.** A `Recruit` gained `gear: Record<string, GearItem>` (`game-store.tsx`) — a real 6-slot paper-doll generated in `makeRecruit` via new **`recruitGear()`**: per-slot **ilvl jitter (±4, averages ≈ the headline ilvl** so the table/header number still reads true) + **quality-weighted rarity** (Common baseline; higher-Potential-★ recruits roll some Uncommon/Rare — `quality = clamp((stars−2)/2.5)`, duds stay all-Common; **Epic stays drop-only/key-gated**). Deterministic from the recruit id (seeded `Rng`) so the on-load backfill is stable and **what you scout = what you sign** — `CONFIRM_RECRUITS` now **inherits `rec.gear`** instead of regenerating a fresh Common set. Existing saves **backfill recruit gear on load** (deterministic → **no `SAVE_VERSION` bump**, same pattern as `withStats`). UI: a new **"Equipped"** strip in `ScoutDetail` renders the 6 slots as `ItemIcon`s (rarity-bordered, slot-letter fallback until item art) with `ItemTip` hover (name/ilvl/rarity/stats). **Balance-safe:** recruit gear is only ever ≥ today's Common-at-ilvl, so the **+2 floor can't regress** (floor/dud recruits unchanged; premium recruits merely slightly better). **Verify:** `tsc -b` clean; `egm-smoke` **byte-identical** (1342/1356/1694/1954 — the sim reads the run party, not recruits, so it's untouched); `scout-live` PASS (Equipped strip renders, 0 errors); `ui-pass-live` **PASS end-to-end** (sign 5 → first key runs to reveal, 0 console errors) exercising the gear-inheritance path. Files: `web/src/state/game-store.tsx`, `web/src/logs/pages/RecruitPage.tsx`. (3 of 6 scouting-board findings; left: talents strip+popup, fixed panel height.)
- **2026-06-24** — **Scouting board redesign #1+#6: scout-panel header reworked (spec icon fills its border · role icon-only · ilvl+morale relocated).** The ScoutDetail header (`RecruitPage.tsx`) no longer shows a solid-spec-colour box with the recruit's first letter — it now renders the actual **spec icon (size 46) inside a tight 52px box with a 1.5px spec-colour border** (icon-to-box ≈ 0.88, tighter than the table's 24-in-34). The **role is now icon-only** (`<RolePill iconOnly />`) beside the name (hover = role name), and the freed right-hand area shows **iLvl + Morale**, with morale **hover-explained** via a `Tip`/`TipBody` ("how willing they are to grind … below 25 they may walk"). Added a shared `moraleColor()` (canonical good ≥70 / amber ≥55 / danger ramp) reused by the table + panel (replaces the table's inline copy). **Verify:** `tsc -b` clean; new reusable Playwright harness `web/scripts/scout-live.mjs` PASS (spec-*.png + role-*.png present, iLvl/morale block, Aptitudes label, **0 console errors**) + panel screenshot confirms the look; all 10 `spec-*.png` exist so no bear fallback. Files: `web/src/logs/pages/RecruitPage.tsx`, `web/scripts/scout-live.mjs`. (2 of 6 scouting-board findings; left: equipped gear, talents strip+popup, fixed panel height.)
- **2026-06-24** — **Scouting board redesign #5/6: operator skills → fantasy "Aptitudes" (display-only, sim-safe).** Renamed the 3 operator skills' player-facing copy in `data/operator-skills.json` to fantasy — **Execution→Precision, Awareness→Instinct, Composure→Composure** — and rewrote the flavor/effect lines to drop the META-QA jargon ("APM", "ships clean code", "grey parses", "the bot"). The 3 **IDs (execution/awareness/composure) are untouched**, so the sim/tuning/trait-growth refs and skill icon art are unaffected. Section labels: "Operator Skills" → **"Aptitudes"** on the scout panel (`RecruitPage.tsx`) and the "Operator" panel title → "Aptitudes" on the character sheet (`CharacterPage.tsx`). Per Umut's call, the **COR and Potential (★) tiles stay as-is** (a distinct fantasy word for the skills was chosen over reusing "Potentials", which collided with the existing Potential tile). **Verify:** `tsc -b` clean; `egm-smoke` **byte-identical** (1342/1356/1694-dep/1954-dep) confirming display-only. Files: `data/operator-skills.json`, `web/src/logs/pages/RecruitPage.tsx`, `web/src/logs/pages/CharacterPage.tsx`. (1 of 6 scouting-board findings; rest: spec-icon, fixed height, equipped gear, talents strip+popup, role-icon-only header.)
- **2026-06-24** — **UI/UX redesign step 1: 16:9 scale-to-fit foundation (the whole app is now a fixed 1920×1080 design canvas scaled to any 16:9 viewport).** New `web/src/logs/ViewportStage.tsx` wraps `LogsApp` (in `App.tsx`): a `.vp-viewport` (fills the real screen, provides letterbox bars) holding a `.vp-stage` fixed at **1920×1080**, centred via `position:absolute; left/top:50% + transform: translate(-50%,-50%) scale(s)` where `s = min(vw/1920, vh/1080)` (recomputed on resize). At the two targets — **1920×1080** (scale 1.0) and **2560×1440** (scale 1.333, 1440p = exactly 1080p × 1.333) — the canvas fills the screen edge-to-edge with **zero dead margins**; off-ratio viewports (4:3, ultrawide, windowed) **letterbox, centred** (translate-centring chosen over grid/flex because flex/grid `center` falls back to *start* when the box is larger than the viewport on an axis). `.app-shell` changed `position:fixed`→`absolute; inset:0` to fill the canvas. **Viewport-relative units inside the stage neutralised** (raw `vh/vw` mean the *real* viewport, not the canvas, once scaled): new `--stage-w/--stage-h` (1920/1080px) tokens; `ReportPage` event-log `calc(100vh − 320px)`→`calc(var(--stage-h) − 320px)`. **Tooltips fixed for the scaled stage** — `Tip` + `LogSpell` (`logs/components.tsx`) previously portaled to `document.body` and positioned with `window.innerWidth/innerHeight` → rendered at 1.0 scale (mis-sized/mis-placed at 1440p); they now `useStage()` + `toStageCoords()` to convert client coords into stage-local space and portal **into** `.vp-stage`, so they inherit the scale. **Decisions (Umut):** *scale one 16:9 canvas* (not fluid reflow); *layout + visual refresh* in scope; per-page one-screen fitting + the visual polish are the **next step (Umut drives)** — this commit is just the foundation. **Verify:** `tsc -b` clean; new Playwright harness `web/scripts/stage-fit-live.mjs` **PASS** — at 1920×1080 & 2560×1440: exact scale, ZERO dead margins, stage centred, `.app-shell` fills the 1920×1080 canvas, no document scroll; off-ratio 4:3/ultrawide letterbox centred; tooltip never lands in `<body>`; **0 console errors**; screenshots confirm pixel-identical layout scaled & crisp at 1440p (Chromium re-rasterises DOM text under static transform → no upscale blur). **No `sim/**` touched → egm unaffected; no `SAVE_VERSION` bump** (no persisted shape change). Files: `App.tsx`, `logs/ViewportStage.tsx` (new), `logs.css`, `logs/components.tsx`, `logs/pages/ReportPage.tsx`, `web/.gitignore`, `web/scripts/stage-fit-live.mjs` (new).
- **2026-06-24** — **UI font: IBM Plex Sans → Space Grotesk (Umut: "too sterile, want more character").** Picked from a 5-candidate visual bake-off on the dense Roster (`web/scripts/font-preview.mjs` — Space Grotesk / Chakra Petch / Rubik / Sora / Saira Semi Condensed). `--mono` stays IBM Plex Mono (number alignment); chat + items stay Pixelify. `tsc -b` clean; live check 12/12 PASS (body=Space Grotesk, chat=Pixelify, 0 gradients, watch-gate), 0 console errors. Files: `logs.css`, `scripts/font-preview.mjs`, `scripts/ui-pass-live.mjs`.
- **2026-06-24** — **Reverted full-pixel UI → Pixelify scoped to chat + items only (Umut).** Full Pixelify-everywhere read as too noisy on dense data tables. UI font restored to **IBM Plex Sans/Mono**; **Pixelify Sans** kept as a deliberate accent via a new `--font-pixel` token + `.pixel` utility, applied only to the **Guild Chat** (`.guild-feed`) and **item display** (ItemTip card, ItemIcon fallback letter, item-name spans on the Character + Loot screens). Flat colours / Raider.io rows / WoW-chat layout / watch-gate all unchanged. `ui-pass-live.mjs` now asserts body=IBM Plex Sans + chat=Pixelify (12/12 PASS, 0 console errors). Files: `logs.css`, `logs/components.tsx`, `logs/pages/CharacterPage.tsx`, `logs/pages/LootPage.tsx`.
- **2026-06-24** — **UI/UX pass (5 commits, Umut request): Pixelify-Sans pixel UI + flat colours + Raider.io rows + WoW chat + watch-gated results.** All in the live `web/src/logs/**` (no `sim/egm/**` touched → egm-smoke byte-identical throughout; no `SAVE_VERSION` bump). **C1** — swapped IBM Plex Sans → **Pixelify Sans everywhere** (full pixel UI; new `--font`/`--mono` tokens, tabular-nums kept so number columns align) and **flattened all 34 gradients** to the existing solid tokens (chrome, Details!/damage/heal/XP/HP bar fills, ReplayCanvas arena + dot shading, every avatar/hero/card/crest). **C2** — icon system: GameIcon default 16→18, new `RolePill iconOnly` variant (role icon + tooltip, no word), skill/nav icon bumps. **C3** — **Recruit + Roster → Raider.io rows**: the avatar is now the full-colour spec/class icon, the name leads in class colour, role is icon-only, and the redundant "Subspec Class" words are dropped (icon + tooltip conveys them). **C4** — **Guild Feed → WoW-style chat log**: `[HH:MM]` timestamps + channel-coloured `[Channel]` prefixes (barks→`[Party]` blue, good→`[Guild]` green, warn→`[Officer]`, bad/neutral→`[System]`) + class-coloured speakers, flat translucent frame, no per-line cards/input. **C5** — **watch-gated results**: the freshly-run key masks the outcome verdict (HUD + rail row + per-pull meta), locks the transport (scrubber disabled, speed pinned 1×, death markers hidden) and **defers the outcome/loot chat lines** (new transient `pendingFeed`) so nothing spoils until the replay plays out (~35–48s at 1×, `RATE`=40); on completion `MARK_WATCHED` flushes the feed + reveals + shows the Distribute/Continue button. Re-views/history open already-revealed; navigate-away bypass closed (unwatched current run restarts the watch at 0). **Decisions (Umut):** Pixelify *everywhere*; *hide-all, no-skipping*; chat *visual-only* (no input/tabs). **Verify:** `tsc -b` clean each commit; egm-smoke byte-identical; new reusable Playwright harness `web/scripts/ui-pass-live.mjs` asserts Pixelify font + 0 gradients + the full gate→reveal flow (10/10 PASS, 0 console errors) + screenshots. Files: `logs.css`, `logs/GuildFeed.tsx`, `logs/components.tsx`, `logs/ReplayCanvas.tsx`, `logs/OperatorPanel.tsx`, `logs/LogsApp.tsx`, `logs/pages/*`, `state/game-store.tsx`, `scripts/ui-pass-live.mjs`.
- **2026-06-24** — **Item-stat system M5 (observe the gear spike + secondary-pool-tuning call) — C.4 COMPLETE.** Built a faithful geared-season sweep `web/scripts/item-gear-sweep.mjs` that gears parties exactly the way the live run-party path does (full `rollItemStats` 6-slot set → `effIlvl`=`gearEffectiveIlvl`/`secondaries`=`gearSecondaries`), sweeping **rarity as the only variable** at fixed ilvl160. **Observed (realistic random rolls):** full-Epic vs Common single-target DPS **+54–82%, mean +73%** (Assassin the ST-king spikes *least*, +54% → no runaway); timed key-ceiling Epic−Common **+4–11, mean +8.1 keys**. A 5-agent adversarial verify (faithfulness · runaway-build hunt · regime/floor · determinism gate → synthesis) confirmed: the +73% mean is **inside the documented +60–90% intent**; the +8.1-key ceiling = the **ordinary gear slope** (Epic effIlvl 200 vs Common 161 ≈ +39 effIlvl ÷ ~4-per-key ≈ +9.75 predicted), not a super-linear multiplier; Versatility is **double-contained** (`VERS_OUTPUT_FACTOR`=0.4 output + `INTAKE_FLOOR_FRAC`=0.4 intake floor) so it stays the safe pick (offensive order Haste≈CritChance ≫ Vers > CritDmg). The lone out-of-band figure (a +122% Haste+CritChance hand-stack) is **unreachable in normal play** — `rollItemStats` picks 2-of-4 secondaries by uid-seeded RNG with **no reforge/reroll**, and Epic is key-gated (`rarityForKey`≥14). **DECISION: KEEP `SECONDARY_RATING_K`=20 & `VERS_OUTPUT_FACTOR`=0.4** (intent: "let it spike, observe playstyle"). **⚠️ Re-evaluate iff a reforge/targeted-loot feature ever lands.** **Verify:** M5 added **only a script** (no engine constant changed) → `tsc -b` clean, egm-smoke byte-identical to HEAD, git status = one new untracked file. Files: `web/scripts/item-gear-sweep.mjs`.
- **2026-06-24** — **Items split by ARMOUR TYPE + per-drop random secondaries confirmed (Umut).** Armour `specs` widened from per-class to per-**armour-type**: **Plate** = warrior+paladin (guardian, berserker, crusader, cleric) · **Leather** = rogue+sage (assassin, bard, mystic, lifebinder) · **Cloth** = mage (pyromancer, arcanist; **+Necromancer when added**). Every plate piece is wearable by all 4 plate specs (2 pieces/slot — Interred King + Pale Vigil), leather by all 4 leather specs (Hollow Court + Verdant Wake), cloth by both mage specs (Ashen Flame) — the player decides which of their specs an item suits. Weapons keep last turn's weapon-type groups; trinkets stay role-based. **Secondaries were ALREADY random per drop** (`rollItemStats` seeds off each drop's unique uid) — demonstrated: 5 drops of the same Epic chest → different Crit/Haste/Vers pairs, so players hunt for the right-rolled piece. **Verify:** coverage 10×6 ✓, armour-type sharing ✓ (all type-specs wear every piece of their type), `tsc -b` clean, content validates, egm-smoke byte-identical. No SAVE bump (specs-widening is additive). Files: `data/items.json`, `scripts/item-stats-check.mjs`.
- **2026-06-24** — **Item roster: warcraftified names + weapon-type interchangeability (Umut).** Renamed all 35 items to cohesive WoW-cadence, IP-safe set names — armour sets: **Interred King** (warrior plate) · **Pale Vigil** (paladin plate) · **Hollow Court** (rogue leather) · **Ashen Flame** (mage cloth) · **Verdant Wake** (sage); weapons Bulwark/Flail of the Barrow March/Pale Vigil, Gravecleaver of Ashveil, Barrowstring Longbow, the staves, Fangs/Grips. **Weapons regrouped by TYPE → shared/interchangeable:** 1H sword/flail+shield **[guardian, crusader]** (2), staff **[arcanist+pyromancer+lifebinder+cleric]** (4), daggers/fists **[assassin, mystic]** (2), 2H axe [berserker], **bow** (was crossbow) [archer]. **IDs kept stable → icon filenames unchanged** (only the displayed names + weapon types change). **Verify:** coverage 10×6 ✓ (0 gaps), IP-grep clean (no WoW-verbatim), `tsc -b` clean, content validates, egm-smoke byte-identical. Files: `data/items.json`.
- **2026-06-24** — **Item icons wired (`ItemIcon`).** Character sheet + Loot screen + the ItemTip header now render the painted PNG at `/icons/item-{baseId}.png` via a new `ItemIcon` component (the img hides itself on error, revealing a slot-initial-in-a-rarity-box fallback — not the generic bear — so a missing icon stays informative and user-supplied PNGs auto-show on drop-in). `tsc -b` clean; `item-tip-live` PASS (0 console errors). Files: `logs/components.tsx`, `CharacterPage.tsx`, `LootPage.tsx`.
- **2026-06-24** — **Item roster authored — full spec coverage (C.4).** `data/items.json` 12 → **35 items** so all 10 specs are equippable in all 6 slots (was only guardian/cleric/berserker — 7 specs had ZERO items, ran starter gear only). Model: **1 weapon per spec** (10, spec-locked), **1 armour set per class** shared by its 2 specs (helm/chest/legs/boots × warrior/paladin/rogue/mage/sage = 20), **role trinkets** (tank/healer/dps) + 2 legacy. 23 new + 12 existing (the 3 cleric pieces — Pale Mitre, Shroudweave Vestments/Leggings — extended to crusader). Designed via a per-class workflow (themed IP-safe Ashveil names) + coverage-verified (**0 gaps**). **Drops now pull from the full roster filtered to the party's specs** (`computeLoot`) — the per-dungeon `lootTable` (which only held the original 3-spec items) is superseded/reserved for future per-dungeon curation. **Verify:** `tsc -b` clean; content cross-ref validates all 35 (egm-smoke byte-identical — the sim is unaffected by item templates); `item-tip-live` PASS (0 console errors). Names are first-pass (some Vigil/Hollow repetition). **Next: item icons** (GameIcon `item-{id}.png`, user-supplied). Files: `data/items.json`, `state/game-store.tsx`.
- **2026-06-24** — **Item-stats M4 shipped: WoW-style item tooltips + rarity colours (UI).** Rarity palette set to the WoW codes (Umut): Common **#ffffff** · Uncommon #1eff00 · Rare **#0070dd** · Epic #a335ee (`QUALITY_COLOR` in `logs/analytics.ts` — drives item NAME, ICON BORDER, and TOOLTIP BORDER). New **`ItemTip`** component (`logs/components.tsx`): a WoW-style card — rarity-coloured name, `slot · rarity · Item Level` line, white base stats (+main, +stamina), green secondary stats (+Haste/Crit/Vers). `Tip` gained an `accent` prop so the tooltip border matches the rarity. Wired into the Character sheet (`ItemRow`) + the Loot screen (drop name → so loot decisions show the full stat block). **Verified** (`item-tip-live.mjs` Playwright): Equipped panel renders, Common name is white (rgb 255,255,255), tooltip shows "Worn Weapon · Weapon · Common · Item Level 127 · +64 Strength · +96 Stamina", **0 console errors**. Files: `logs/analytics.ts`, `logs/components.tsx`, `CharacterPage.tsx`, `LootPage.tsx`, `scripts/item-tip-live.mjs`. **Item-stat system M1-M4 live + visible. Left: M5** (observe the spike in a geared season sweep).
- **2026-06-24** — **Item-stats: Versatility output reined in (it was the universal best DPS stat).** A crit-stack experiment (`crit-stack-check.mjs`) showed Versatility's FLAT output multiplier made it the strict best DPS allocation for every spec (+58% Assassin / +60% Berserker vs crit-stack +29%/+44%) — trivializing the which-2-of-4 choice. **`VERS_OUTPUT_FACTOR`=0.4** runs vers's output at 40% rate (its −intake/survival side unchanged + floored). **Build diversity restored:** Assassin's best is now **crit-stack (+29%, 35% @ 2.30×)**, Berserker's is **haste (+56%, feeds its rampage→Bladestorm)**, and Versatility is the **lowest-DPS pick everywhere** (+23/24% → the survival stat, as intended). egm-smoke byte-identical (no secondaries in harnesses). Files: `sim/egm/stats.ts`, `scripts/crit-stack-check.mjs`.
- **2026-06-24** — **Item-stats M3 shipped: all 4 gear secondaries wired (Crit Damage + Versatility = the new hooks).** `buildParty` converts the M2-plumbed summed gear RATINGS → effects at **`SECONDARY_RATING_K`=20** (1% per 20 rating): **Haste**→attack speed, **Crit Chance**→crit%, **Crit Damage**→crit multiplier (base 2.0 + pts), **Versatility**→ +output% (folds into `opOutputMult`) and −intake% (folds into the **floored** `intakeStatic` channel → respects the GATE-0 40% floor). egm-smoke **byte-identical** (harnesses pass no secondaries → no-op). **Verified** (`dps-dummy <ilvl> <rarityMult> <ratingPerStat>`): epic ilvl160 + ~300 rating/stat lifts DPS **+37% (Assassin 352→481)** … **+65% (Berserker 208→344** — Haste compounds its rampage→Bladestorm ramp, a real playstyle quirk). **Full-epic spike is large** (≈+60-90% over Common stacked with the M2 main-stat spike) — intended-to-observe per Umut's design call; `SECONDARY_RATING_K` is the dampening lever if M5 shows it's too wild. Files: `sim/egm/stats.ts`, `scripts/dps-dummy.mjs`. Next: **M4** (UI) + **M5** (observe in geared comps).
- **2026-06-24** — **Item-stats M2 shipped: sim sources power/HP from summed gear stats (the rarity spike goes live).** `SimPartyMember` gained optional `effIlvl` (rarity+slot-weighted effective ilvl = Σ mainStat / MAIN_K) + `secondaries` (summed ratings); `buildParty` scales power/maxHP/armour/hps off **`effIlvl ?? ilvl`** (`egm/stats.ts`). game-store's run/ticket party passes `effIlvl = gearEffectiveIlvl(equipped)` + `secondaries = gearSecondaries(equipped)` (new `item-stats.ts` helpers) → real geared members get the spike, and replays stay faithful (stored in the RunTicket; old tickets lack the fields → fallback). **Back-compat: anything that sets a raw ilvl (every sim harness) falls back → byte-identical** (egm-smoke 1342/1356/1694/1954). **Verified spike** (`dps-dummy <ilvl> <rarityMult>`): Common 1.0 reproduces P.5f *exactly* (Assassin 284, Berserker 165/565); **Epic 1.25 → +18-20%** (Assassin 335, Berserker 197/675) — less than the raw +25% power because abilities carry flat base damage (a sane spike). +2 floor unaffected (starter = Common → effIlvl=ilvl). Secondaries plumbed but applied in M3. Files: `sim/types.ts`, `sim/egm/stats.ts`, `state/item-stats.ts`, `state/game-store.tsx`, `scripts/dps-dummy.mjs`. Next: **M3** (wire Crit Damage + Versatility; apply all 4 secondaries).
- **2026-06-24** — **Item-stats M1 shipped: rarity-scaled stat-block schema + generation.** New PURE module `web/src/state/item-stats.ts` (reused by store + sim + probes): every gear item rolls `{mainStat, mainStatType, stamina, secondaries[]}` from `ilvl × slotWeight × rarityMult`, deterministic from the uid. **Rarity** (Common 1.0 · Uncommon 1.06 · Rare 1.12 · **Epic 1.25**) multiplies the WHOLE block — *including main stat*, so an Epic out-stats a Common at equal ilvl (Umut: let the power spike ride to observe playstyle) — AND gates secondary count (0/1/2/2). Secondaries are distinct draws from **{Haste, Crit Chance, Crit Damage, Versatility}** (max 2/item) as RATINGS (the sim converts rating→% in M3). `GearItem extends ItemStats`; `makeDrop`/`starterGear` roll the block; the 3 gear-reconstruction sites carry it via a `gearFields` picker; existing saves **backfill on load** (`withStats`, deterministic → no SAVE bump). **Balance-neutral — the sim doesn't read the block yet (M2)** → egm-smoke byte-identical (1342/1356/1694/1954). Probe `item-stats-check.mjs`: chest ilvl150 Common Agi+49 → Epic Agi+61 (the ×1.25 main spike) + 2 secondaries; weapon main +101 vs chest +65 (slot weighting). Files: `web/src/state/item-stats.ts`, `game-store.tsx`, `web/scripts/item-stats-check.mjs`. Next: **M2** — sim sources power/HP from summed item stats (the rarity spike goes live).
- **2026-06-23** — **P.5f shipped: DPS-identity pass (Archer/Crusader/Berserker/Pyro/Arcanist) — the timer regime's DPS meta now reads cleanly.** Built a training-dummy harness (`web/scripts/dps-dummy.mjs`: solo spec vs N huge-HP/zero-damage dummies, total damage/time at 1/3/5 targets — reuses the real engine loop via injected synthetic content) + a 4-agent investigation workflow (+synthesis). **Before:** Assassin 284/307/307 (ST king) · Berserker 182/458/605 (AoE king AND 2nd-best ST — too well-rounded) · Arcanist 155/246/319 & Pyromancer 153/342/417 (weak ST) · Archer 150/184/231 (bottom at EVERY count) · Crusader 20/20/20 (flat, anomalous). **Changes (surgical — coefficients + 1 pattern, no new mechanics):** Berserker Cleaving-Strike 0.85→0.65 + Blood-Frenzy 25→20% (single-target trim; AoE engine Bladestorm/Whirlwind untouched — NOT a P.5b revert); Pyromancer Scorch 0.6→0.85 (ST spam); Arcanist Arcane-Bolt 0.95→1.18 (ST spam); Archer Barrow-Quarrel 0.7→0.9 + Marrow-Piercer 1.1→1.35 + Over-the-Barrow 0.8→0.95 + Carrion-Hail 0.6→0.78 (ST kit + modest AoE; **kept Culling-Rain as its AoE major** — rejected the investigation's over-engineered delete-major + new mark/precision mechanic); Crusader Holy-Strike single→adjacent (de-weird the flat-20). **After:** Assassin **284** (ST king, unchanged) · Archer 178/215/268 (ranged-ST generalist, no longer bottom) · Arcanist 176/269/342 · Pyromancer 166/356/431 · **Berserker 165/422/565 — now the AoE KING with the LOWEST single-target** (a real specialist weakness, below the buffed casters) · Crusader 20/40/40. Clean ST→AoE gradient (assassin 1.08× … berserker 3.42×); each DPS has an identity (assassin=boss, berserker=trash, pyro=AoE caster, arcanist=balanced caster, archer=ranged-ST). **Side benefit:** the magic-ST buffs flipped the **Pyreward school read back to correct-direction** (mixed-magic +6 > all-physical +5; was inverted at M4) — subsumes the originally-flagged P.5f "pyro ST → Pyreward" goal (read now correct, still a weak +1-2 tax; a +3-4 tax would need more magic-ST or a wall tune). **Verify:** `tsc -b` clean; **+2 floor 6/6 every dungeon**; egm-smoke goldens rebumped (pyro in the comp: 1344/1379/1748/1984 → 1342/1356/1694-dep/1954-dep, tactics still differentiate all-3 < all-0); comp spread **4.0** (10.3-14.3, was 3.3) — healthy, but **CrusaderTank crept 13.3→14.3** (it runs BOTH buffed casters → top by +1; a documented drift, not C.11-style dominance — the lever if it matters is Crusader *survival*, not these DPS buffs); **operator runway compressed +2→+1** @cap (the pyro buff lifted the 2H f6 comp's fresh ceiling +9→+10 — a minor Phase-F side-effect). Tooltips (`skills.json`) synced + 2 pre-existing stale ones fixed (Cleaving 60%→65%, Blood-Frenzy HP-cost 15%→5% leftover from P.5b). Files: `data/abilities-player.json`, `data/skills.json`, `web/scripts/dps-dummy.mjs`. **Open judgment calls (easy to revert):** Crusader cleave-vs-pure-wall (chose modest cleave to de-weird; one-line revert to 20/20/20); the residual Pyreward +1-2 tax.
- **2026-06-23** — **P.5c-M4 shipped: all-reads verification + read-repairs → P.5c COMPLETE (the DPS-check / regime shift is in).** Verified every P.0–P.4 class-tool read against the M1–M3 regime (dedicated harnesses) and repaired the two the regime softened: **(P.3 Mire dispel/curse) RESTORED** — the M1 `enemyDmgMult` drop (2.0→1.5) had softened the curse DoT so the wrong-dispel cleric reached 6 stacks but still timed (+23 ≥ lifebinder +22, read dead); **`curseBase 0.06→0.25`** restores it: **lifebinder +22 vs cleric +18 = tool tax +4** (cleric wipes at 6 stacks, lifebinder dispels to 1; Mire-only, egm-smoke byte-identical). **(P.2/P.3 Pyreward school) weak → deferred** — softening the wall (tried K 200/300) INVERTS the read (post-regime magic≪physical means mitigated physical still out-clears magic → physical "wins" the armour wall, nonsensical), so K reverted to **155** (the only setting where magic ≥ physical, weakly +1); fully restoring the "+4-key off-school tax" needs a **pyromancer single-target buff** (follow-up magic-spec pass), not a wall tweak. **(P.2 Bellreach kick) SURVIVES** — full sweep: no-kicker comps bottom +1–5, kicker comps (arcanist/mystic) reach +8–12 (a +4–7 comp gap); +2 floor holds (5/6 standard, 6/6 kicker — the read bites at +3+, not the floor). **(P.4 Hour carillon) intact + deterministic** (replay-integrity PASS). **(C.10 burst/rot healer) washed out** — these were intake/survival "soft" reads (C.11 flagged them survival-artifacts); the timer-bound regime makes them inert, and healer differentiation now lives in the typed Mire curse + cleric-as-generalist. **op-verify B/C recalibrated** (key 22→12): the M1 hpUnit raise made key22/ilvl105 an unwinnable total-wipe (death-count a misleading proxy); key12 is the survival edge (skill=1 wipes, skill=20 survives) → **all 6 op-verify checks PASS** (incl. composure + determinism). **@cap ceiling NOT force-restored via keyScaling** — the season's ceilings are dungeon-varied (easy +19–20 give push-room; the DPS-check's moderate @cap is intended; a flatter curve would re-inflate EHP). **Talent power-equality re-confirmed** in the new regime (tier options still cluster ~1–5%, no dead/dominant → C.2 trees need no re-tune). **Final comp balance (`p5c-sweep`, 10 comps →+20): spread 3.3 keys (10.0–13.3)**, generic-EHP demoted (CrusaderTank 13.3 top-of-cluster, TwoHealer 10.0 bottom), magic viable; **+2 floor 6/6 on every dungeon**. **Adversarial review (5-agent workflow): 4 clean + 1 completeness-critic whose "blockers" were mid-review timing artifacts (M4 uncommitted) + a Bellreach misread (the read survives in the full sweep) — no real un-addressed issues.** New tooling: `p5c-floor.mjs` (per-dungeon floor), `p5c-opedge.mjs` (op-verify edge-finder). Files: `data/tuning.json`, `web/src/sim/egm/pipeline.ts` (comment), `web/scripts/{op-verify,p5c-floor,p5c-opedge}.mjs`. **P.5c COMPLETE → P.5 (Generic-EHP kill + DPS-check) DONE.** Follow-ups spun out: **P.5d** (P9 self-healing enemy + anti-heal/purge), **P.5e** (P7 telegraphed eruption), **magic-spec pass** (pyromancer ST buff → restore the Pyreward school read + finish magic parity).
- **2026-06-23** — **P.5c-M3 shipped: the regime INVERTED the magic↔physical imbalance; targeted arcanist DPS buff.** `spec-power.mjs` in the M1/M2 timer regime **overturned the pre-regime "magic≫physical" premise**: physical now LEADS (Stillhour boss: phys avg **18.7** — assassin +22 / berserker +20 — vs magic **5.5**; Ashveil trash: phys 8.0 vs magic 3.5), because the DPS-check makes HP-sponge BOSSES the binding constraint, favoring single-target physical over AoE-flavored magic. The full 10-comp season sweep (new `p5c-sweep.mjs`, →+20) confirmed magic is **fine at the comp level** (MagicHeavyDPS/LifebinderMagic 11.2; comp spread a healthy **4 keys** 9-13, generic-EHP demoted) — the only laggard was **AoE-Stack (9.0**, the lone no-assassin double-magic comp), dragged by **arcanist, the new broken-LOW spec** (mono +1 trash / +4 boss — its only real damage is Arcane Bolt 0.65×; the rest is CC/shield). Fix (the **P.5b-berserker analog**, egm-smoke byte-identical since no comp-of-record runs arcanist): **Arcane Bolt 0.65→0.95**, **Frost Nova 0.6→0.8**. **Result:** arcanist mono +1/+4 → **+3/+7** (≈ pyromancer, de-pathologized); comp spread **4.0→3.5** (9.8–13.3); AoE-Stack 9.0→9.8; MagicHeavyDPS 11.2→12.3 (CrusaderTank 12.7→13.3, nominal top in a 0.6 top-cluster with MysticTank 13.0 — not domination). **Left as-is (out of scope):** AoE-Stack stays the weakest viable comp (it's the only one without assassin, the strong ST archetype — a spec-identity artifact, not a P.5c bug; trimming assassin is risky regime-wide work); pyromancer is comp-viable everywhere despite weak mono-ST. **Verify:** `tsc -b` clean; **egm-smoke byte-identical** (1344/1379/1748/1984); op-verify **determinism (r1≡r2)** + **+2 floor** PASS; spec-power + p5c-sweep as above. **Known test artifact → M4:** op-verify's composure/awareness checks (B/C) use an EXTREME key-22/ilvl-105 point that is now an **unwinnable total-wipe** in the harsher regime (surfaced at M2 via the Bulwark recost) — so death-count is a misleading survival proxy (more deaths can mean *more progress* before the wipe), flipping C to FAIL; the composure **mechanic is unchanged** → recalibrate B/C to a survivable-pressured point in M4. Tools: `p5c-sweep.mjs`. Files: `data/abilities-player.json`, `data/skills.json`, `web/scripts/p5c-sweep.mjs`. Next: **M4** (all-reads + +2-floor-per-dungeon + ceiling-restore + op-verify recalibration + adversarial review).
- **2026-06-23** — **P.5c-M2 shipped: generic-EHP recosts (kit hygiene; the M1 regime already did the balance work).** Applied the design's owed recosts: **Bulwark Banner** party-wide −35% DR major → **self/tank only** (a Shield-Wall personal hold — the grip/intercept verbs meant to replace it ship in P.5d/P.5e); **Guardian's Oath** reductionPct 20→0 (pure peel, no free mitigation vanishes) + cd 4→6; **Blessing of Protection** blocks 2→1 + cd 5→6 (a single hard-negate, not a 2-charge sponge); **Stalwart Defender** armour 15→10 + shield-amp 20/40→15/25. Tooltips (`skills.json`) aligned. **Finding: in the timer-bound M1 regime these recosts are near-balance-inert** — generic survival is no longer the binding constraint, so cutting it barely moves ceilings (CrusaderTank 12.3→**12.7**, Meta-Cleric 12.5→12.0; CrusaderTank now sits at **~parity, +0.7 over the no-util comp**, down from the C.11 **+5** dominance). Their value is **structural hygiene** (no generic party-DR crutch) + **insurance for M4** (when the ceiling is restored via a flatter `keyScaling`, survival could re-matter → recost now so it can't re-inflate). **Verify:** `tsc -b` clean; content validates; **egm-smoke +8 byte-identical to M1** (1344/1379 — Bulwark party→self is inert when the party isn't dying, confirming the recost is edge-only), +14 depleted durations shifted <2% (1731/2014 → 1748/1984); p5c-regime +2 floor (ashveil) 3/3 all comps. **Flagged → M4:** the Bulwark recost dropped Meta-Cleric's Bellreach ceiling +4→+1 (it lost the party-DR crutch on the cast dungeon) — verify the +2 floor still times on Bellreach, and consider gating the stacking cast so the kick read bites at high keys, not the floor. Files: `data/abilities-player.json`, `data/skills.json`. Next: **M3** (magic↔physical AoE parity).
- **2026-06-23** — **P.5c-M1 shipped: the regime shift / DPS-check — survival-bound → timer-bound (the core P.5c calibration).** Re-scoped P.5c (Umut sign-off): **4 sub-milestones** (M1 regime → M2 EHP recosts → M3 magic↔physical AoE → M4 verify), **P9/P7 split to P.5d/P.5e**, and **NO mana** (balance the regime so unlimited HPS is inert — a timer-bound regime demotes 2-healer comps because they're DPS-short, not because they run out of resource). Built `web/scripts/p5c-regime.mjs` — patches `tuning.sim.{enemyDmgMult,hpUnit,keyScalingPerLevel}` **before** the engine module evaluates its SIM constants, so each PROCESS tests one candidate triple (run many in parallel, no file edits). Two bracket rounds (5 + 4 candidates) settled the triple: **`enemyDmgMult 2.0→1.5`** (eases survival so the intake-bound no-util comp converges; 1.4 lets it run away, 1.6≈1.5), **`hpUnit 1020→1500`** (tightens the timer — the generic-EHP demoter: hp≥1500 drops TwoHealer to the bottom, hp≤1450 leaves CrusaderTank topping), **`keyScalingPerLevel 1.052→1.05`** (1.045 re-inflates ceilings + lets CrusaderTank top again via the Bellreach EHP-bypass → kept at 1.05). **Result (p5c-regime, 4 diagnostic comps × 6 dungeons → +20):** Ashveil spread **13→5** (Meta-Cleric no-util now TOPS, was −13 below the field); **generic-EHP demoted** — TwoHealer avg **15.2→9.8 (now LOWEST)**, CrusaderTank **17.3→12.3 (no longer tops)**, Meta-Cleric on top (12.5); Stillhour/Mire pulled from "every comp +20-capped" to measurable (spread 3-4); Pyreward comp-balanced (spread 1); Hour spread 6. **Verify:** `tsc -b` clean; **egm-smoke** runs + mechanics fire + tactics still differentiate (all-3 1731s < all-0 2014s), goldens **deliberately rebumped** 938/978/1208(timed)/1414(timed) → **1344/1379/1731(depleted)/2014(depleted)** (the smoke "balanced" comp is itself 1T/2H/2DPS, so its +14 now depleting = the DPS-check working, not a regression); **f6 +2 floor 6/6** + **operator runway +2**; **op-verify** determinism (r1≡r2 dur=1604s/log=8092) + +2 floor (deaths=0). **Absolute @cap ceiling compressed** (f6's 2H comp +15→+9; a 3-DPS comp ~+11 on hard dungeons / +20 on easy) — **expected for a DPS-check**; **keyScaling-based ceiling restoration is deferred to M4** because a flatter curve re-inflates the Bellreach EHP-bypass, which the **M2 Crusader recosts** remove first (that's what unlocks the flatter curve). **Residuals → M2/M4:** Bellreach CrusaderTank +11 still bypasses the kick read (M2 recosts); Pyreward ceiling low from school-wall×HP double-tax (M4 wall softening). Files: `data/tuning.json`, `web/scripts/p5c-regime.mjs`. **Next: M2** (Bulwark Banner party-DR → self/tank; Guardian's-Oath/Blessing/Stalwart recosts).
- **2026-06-23** — **C.2 M8 shipped: talent-tree balance pass → C.2 COMPLETE (10 per-spec trees authored + balanced).** Built `scripts/talent-balance.mjs` — a role-aware power-equality harness that sweeps each tier's 3 options (others left at default) and measures **clear DURATION** on a trash (Ashveil, AoE) + a boss (Stillhour, single-target) dungeon (duration is the real signal — in a *timed* clear cumulative damage ≈ fixed total HP, so faster = stronger). **Finding: the trees are already power-equal *by content*** — every DPS tier's boss-winner is the single-target/sustained/execute option while AoE/utility/anti-heal options are situationally weaker on a lone boss (they win packs / dangerous-cast / self-healing weeks); spreads mostly 2-11%, **no dead options** (all clear), **no universally-dominant option**, defaults land middle-ish. Tanks (1-3% spread) + healers (~2%) are survival-bound and tight — survival options correctly inert on a no-death clear (they pay at the edge → P.5c regime), Mystic's Warden of Spirits measurably slower (its −10% self-damage cost shows). **One tune:** Pyromancer Smothering Ash burn-amp 35→60 + honest reframe (burn DoT is a *minor* damage fraction in this engine — detonations/direct casts dominate — so a burn-magnitude pick can't out-clear a flat-damage pick on a boss without creating T1/T3 redundancy; kept as the distinct slow-burn/long-fight pick within ~5%). **Verify:** `tsc -b` clean; egm-smoke unchanged (938/978/1208/1414, tune is non-default); **+2 floor 6/6 at starting gear** (`f6-balance`); **operator runway +2** (fresh +15 → maxed +17 @ cap — a few, not a landslide); `balance-probe` reproduces M7b **exactly** (spreads 13/10/2 → determinism + floor confirmed). **Known limits → P.5c / future engine:** (1) no healer-output (heal/HoT-magnitude) talent channel, so healer throughput nodes lean on cooldown-reductions + Cleric atonement-`dmgPct` + self-survival; (2) survival options aren't duration-differentiable on no-death clears; (3) the absolute ceiling dropped (~+18→+15 fresh @ cap) — the M7b rebump made spec defaults net-slightly-weaker on offense; **restoring the global curve is P.5c's job** (it owns `keyScalingPerLevel`), deliberately NOT pre-empted in M8. Files: `data/talents.json`, `scripts/talent-balance.mjs`. **C.2 done — next is P.5c** (regime tuning, calibrated once against the final trees).
- **2026-06-23** — **C.2 M7b shipped: the 10 per-spec talent trees are live (content lands → goldens deliberately rebumped).** Replaced the 5 global MVP nodes with **50 per-spec nodes (10 specs × 5 tiers × 3 mutually-exclusive options = 150)** in `data/talents.json`, authored strictly against the M1-M6 honored vocab (`dmgPct`/`intakePct`/`critPct`/`maxHpPct` + `onlyIf` + `abilityOverrides` + `eventRiders` + `atonement`); Archer tree uses `specId:"bard"` (id kept for save stability — no rename). Added two anti-heal debuff statuses (`riven-wound` −50%, `serrated-wound` −40% healingReceived) for the P9 Berserker/Archer on-hit riders. Schema gained `selfHitSinceLastAction` + `targetHpAbovePct` to the talent `onlyIf` enum (both already in `condHolds`; expose the reactive-bruiser + fresh-target gates). Picker already filtered by spec (M7a) → renders 5 tiers/spec unchanged; `game-store` sanitize drops stale talent nodeIds on load (persisted shape unchanged → **no SAVE bump**); SignatureCard cooldown now derives `{sk.cd×3}s` (dropped the hardcoded "~60s"); `skills.json` player-facing prose converted "turn"→seconds (baseValues reference-units left). **Adversarial verification:** a 10-agent workflow (one auditor/spec) caught a real **no-op class** — talent `dmgPct` gates against `livingMobs[0]`, so `targetBand:back` is unreliable for a front-fighting spec → Guardian Iron Tether reworked to an on-hit Mark rider, Assassin Sever-the-Thread to target-accurate `addModifier`s; plus a cd-text bug (Cleric Steadfast Grace 6s→3s) and two near-inert healer `dmgPct` nodes (Lifebinder) swapped to real self-survival. Remaining audit flags are **acknowledged proxies** (one-shot evasives, party-wide buffs, HoT-magnitude — not expressible in current vocab; the **healer-output talent channel is a known engine gap** for a future milestone). **Verify:** `tsc -b` clean; content cross-ref validates; **egm-smoke deliberately rebumped → 938/978/1208/1414, all timed, 0 deaths** (≈+5% slower than M7a's defaults — new spec defaults are net-slightly-weaker on offense; within M8's remit); `balance-probe` **+2 floor times for all 4 comps** (Meta-Cleric/MagicHeavy/TwoHealer/CrusaderTank); `talent-cond-verify` ALL PASS (M1-M6 channels intact); **Playwright `talent-picker-live.mjs` PASS** (per-spec 5×3 renders, pick persists, seconds-clean, 0 console errors). Files: `data/talents.json`, `data/statuses.json`, `data/skills.json`, `schema.ts`, `combat.ts`, `game-store.tsx`, `CharacterPage.tsx`, `scripts/talent-picker-live.mjs`. **Next: M8** (balance — tier power-equality across 150 options, re-verify floor + operator runway, then **P.5c** regime tuning calibrates once against the final trees).
- **2026-06-23** — **C.2 M7a shipped: per-spec talent structure (back-compat) + seconds display.** `TalentNodeSchema` gained an optional `specId` (absent = global node applying to every spec — preserves the MVP shared nodes); `resolveTalents(chosen, specId)` and the Character-sheet picker now filter to global + the member's spec nodes; cross-ref validates `specId ∈ specs`. SpellTip renders **`{cd×3}s cooldown`** instead of "N turn cooldown" (the seconds-not-turns fix, secondsPerTurn=3). All byte-identical because every current node is global (the filter is a no-op until per-spec nodes exist). **Verify:** `tsc -b` clean; **egm-smoke byte-identical**; probe green. Files: `schema.ts`, `index.ts`, `stats.ts`, `CharacterPage.tsx`, `components.tsx`. **Remaining:** M7b (author the 10 per-spec trees — the 150-node content, which deliberately rebumps the goldens) + M8 (balance: re-verify the +2 floor & tier power-equality, then P.5c). **Engine foundation (M1-M6) + structure (M7a) complete.**
- **2026-06-23** — **C.2 M6 shipped: §H general summon engine (enemy-add spawner).** Extracted the inline summon-shield-boss guard code into a reusable `spawnSummonedCombatant(g, opts)` in `engine.ts` — builds an enemy from a content def, drops it into the live `mobs` array, and mirrors a `ReplayMob` (stable `s{stage}m{index}` id, spawn-second HP). The summon-shield `summonGuard` is now a thin caller; any future boss/affix add (or wave) reuses the spawner. **Party-side pets stay deferred with the Necromancer** (they need a party-combatant builder, not `makeEnemy`) — per decision #6, the general *enemy-add* system ships now. Pure extraction (same args/order/id scheme). **Verify:** `tsc -b` clean; **egm-smoke byte-identical**; new `summon-check.mjs` probe (hour-of-bells → The Leaden Carillon summons bell-wardens) **byte-identical** at +6 and +10 (outcome/dur/deaths/summon-lines/replay mob-ids). Files: `engine.ts`, `scripts/summon-check.mjs`. **Engine milestones M1-M6 complete.** Next: **M7** (author the 10 trees + picker + seconds display — content lands, goldens rebump).
- **2026-06-23** — **C.2 M5 shipped: §F tank tools.** Wired `selfHoldsHardThreat` in `condHolds` — the abstract sim has no numeric threat pool, so the predicate resolves to "the alive party tank" (the threat-holder while tanking); this unblocks the Guardian/Crusader/Mystic capstones that gate on holding threat. **Audit finding:** the rest of §F is already covered — thorns-reflect %, block-reflect %, redirect %/reduction, grip target-count are all params on existing `special` mechanics, patchable via M2's `abilityOverride` (`param`/`scalar`/`targeting`/`addModifier`); no new engine work needed for them. The two genuinely-new Guardian-capstone mechanics (a locked single-target taunt, and the back-band-untargetable-while-taunt aura) are content-coupled and will be built alongside their abilities in M7. **Verify:** `tsc -b` clean; **egm-smoke byte-identical**; probe +2 (tank gates true, dps false). Files: `combat.ts`. Next: **M6** (§H general summon engine).
- **2026-06-23** — **C.2 M4 shipped: §D atonement extensions.** A talent `atonement` config (`disableAbilityId`, `partyWhenLowestAllyBelowPct`) now reshapes the heal-by-damage path in `afterHit`: it can turn off atonement on a named ability (Cleric "Piercing Ray: Radiance no longer heals") or spread it to ALL injured allies when the lowest is critically low (Cleric "Crowned in Light" / Lifebinder "Verdant Reckoning"). Logic extracted to a pure, exported `atonementTargets(at, abilityId, injured, self)`. Atonement *magnitude* (healPctOfDamage) is covered by M2's `param` override. **Verify:** `tsc -b` clean; **egm-smoke byte-identical** (no config set → returns `[lowest]`, identical to prior); probe +6. Files: `schema.ts`, `index.ts`, `stats.ts`, `combat.ts`. (atonement-on-dot path extension deferred to when a Holy-Fire-tuning node is authored.) Next: **M5** (§F tank tools).
- **2026-06-23** — **C.2 M3b shipped: the anti-heal (healing-received) channel.** Added a `healingReceived` statMod (reusing the existing `eff()` stat-mod switch → new `EffStats.healingTakenPct`), honored in `healInto` (`combat.ts`): a status carrying `healingReceived: -50` on its bearer cuts incoming healing by half — the engine half of the P9 anti-heal (Berserker Riving Wound / Archer Serrated Shot apply such a status via an M3a `on-hit` rider; the status def + the self-healing enemy land with content/P.5). **Verify:** `tsc -b` clean; **egm-smoke byte-identical** (no status carries it yet); probe +2 (`eff.healingTakenPct` reads −50, 0 without). Files: `stats.ts`, `combat.ts`. **M3 complete.** Next: **M4** (§D atonement extensions).
- **2026-06-23** — **C.2 M3a shipped: §E talent event riders.** A talent can now hook combat events via a strict `EventRiderSchema` (trigger `on-hit`/`on-crit`/`on-kill` [+`on-parry`/`on-detonate`/`on-expiry`/`on-cleanse` reserved], optional `ability` gate + `chancePct`, action = `applyStatus` / `adjustCooldown` / `refundResource` / `heal`). Wired in `afterHit` (`combat.ts`) — one hot-path loop over `attacker.talentEventRiders`; empty for enemies / no-talent members → no-op. `applyEventRider` exported + cross-ref validates `statusId`/`abilityId`. **Verify:** `tsc -b` clean; **egm-smoke byte-identical**; probe +5 (reset/reduce cooldown, refund resource, heal %maxHp & %damage). Files: `schema.ts`, `index.ts`, `stats.ts`, `combat.ts`. (DoT/HoT magnitude tuning is covered by M2's `scalar` override; `cleanseImmune`/`suppressCrit` flags deferred — limited active-spec use.) Next: **M3b** (healing-received / anti-heal channel).
- **2026-06-23** — **C.2 M2 shipped: the §B `abilityOverride` channel.** A talent can now patch a named ability via a **strict, enumerated discriminated union** (`AbilityOverrideSchema` in `schema.ts`): `cooldown` (set cooldownTurns), `targeting` (pattern/count/band), `param` (an enumerated numeric key on a special-mechanic effect), `scalar` (base/scale/duration… on the primary damage/heal/shield/dot/hot effect), `addModifier` (append a `when`/`multiplyDamage` modifier to the damage effect). A typo in a `kind`/`key`/`pattern` fails Zod validation; the cross-ref validator (`index.ts`) checks every `abilityId` exists. Applied in `buildParty` via `applyAbilityOverrides` (`stats.ts`), which **clones** any patched ability per-member so the shared content Map is never mutated; empty overrides return the same arrays (byte-identical default). **Verify:** `tsc -b` clean; **egm-smoke byte-identical** (no live node uses it yet); probe `talent-cond-verify.mjs` +10 assertions (all 5 kinds patch correctly, original untouched, unknown id skipped). Files: `schema.ts`, `index.ts`, `stats.ts`. Next: **M3** (§C status authoring + §E event riders).
- **2026-06-23** — **C.2 M1 shipped: the §A `condHolds` keystone.** Unified the talent `onlyIf` path onto the engine's existing `condHolds()` evaluator (deleted the duplicate 3-predicate switch in `passiveDamageMult`), widened the talent schema `onlyIf` enum to the full closed set (added `selfHpBelowPct` / `allyHpBelowPct` / `lowestAllyHpBelowPct` / `selfStacksAtLeast` / `selfHoldsHardThreat` [M5 stub], and moved `enemiesAtLeast`/`enemiesAtMost` into `condHolds`), and added **runtime conditional `intakePct`/`critPct` channels** — gated intake folds into the per-step `intakeMult` refresh (`engine.ts`), gated crit adds into the 5 party-caster `resolveHit` sites — so Tier-4 keyed defenses and conditional-crit nodes become expressible. Unconditional intake/crit keep the build-time fold. **Verify:** `tsc -b` clean; **egm-smoke byte-identical** (894/953/1190/1380 — inert for current content, by design); new functional probe `web/scripts/talent-cond-verify.mjs` **15/15** (selfHpBelowPct/enemiesAtLeast/allyHpBelowPct/targetHpBelowPct/selfStacksAtLeast/targetHasStatus gating + the unconditional branch all fire). Files: `schema.ts`, `stats.ts`, `combat.ts`, `engine.ts`. Unblocks 11/12 specs' conditional vocab. Next: **M2** (`abilityOverride`, enumerated).
- **2026-06-23** — **C.2 build plan authored: `Docs/Talent-Build-Plan.md`** (no code yet; awaiting sign-off). Ran a 5-agent read-only code map (talent data/schema/pipeline · the §A keystone surface · ability/status hooks · picker UI + persistence + cooldown display · combatant model + summon engine) and turned it into a sequenced **M1→M8** plan, each milestone with the exact files/line-refs it touches, its verify gate, commit boundary, and determinism/save-migration risks. Sequencing principle: **engine capability first (M1-M6, goldens byte-identical), content last (M7, deliberate golden rebump + re-verify the +2 floor), then balance (M8) → P.5c.** Surfaced grounded facts: talents are currently **spec-agnostic shared nodes** (need a `specId` + per-spec restructure); intake/crit are folded **unconditionally** today (M1 must add a runtime conditional channel); the summon **guard** (`engine.ts:192-208`) is the template for a general summon system but its replay id drifts (needs a per-stage counter); and `specs.json` still calls the Archer spec **`bard`** (P.2 recut — reconcile in M7). 6 cross-cutting decisions flagged for sign-off (data shape, save handling, conditional intake/crit, golden policy, bard↔archer, summon scope). Doc-only.
- **2026-06-23** — **Talent-Trait revamp — Umut's review pass applied** to `Docs/Talent-Trait-Revamp.md` (design-only; C.2 stays execution-deferred). Ran a 12-agent workflow (10 spec rewrites + reference §4 + a name-collision/IP audit) to action the review: **(1)** naming register switched gothic → **bright Warcraft-style class-fantasy, IP-safe** — every talent + referenced spell renamed by class school, machine-audited (**3 cross-spec collisions + ~16 WoW-verbatim leaks fixed**; residual *pre-existing* ability-name IP-debt — Rally Cry / Holy Strike / Light's Salvation / Emberstorm / Glacial Cataclysm / … — listed in synthesis §3 for the separate scrub); **(2) seconds not turns** in all player-facing prose (`secondsPerTurn=3`; UI seconds-display pass folded into C.2 wiring); **(3) Guardian Tier-3 remade** — the old fork depended on the *deferred* P7 eruption → new "Sentinel's Voice" rally / locked-taunt / war-cry axis; **(4)** Necromancer (Bonecaller/Pallbinder) **💤 deferred** → active scope now **10 specs** (necro trees kept under a banner, un-revamped); **(5)** `abilityOverride` kept **Zod-strict / enumerated** (validation-strictness note added so we don't lose it); **(6) anti-heal added to the Archer** (Serrated Shot) so **P9 is no longer Berserker-only**; **(7) paladin DR/immunity generalised** — Crusader party-DR + Cleric absorbs now soak *any* damage (not DoT-typed) but stay **timed cooldown windows** → this **cuts the DoT-tick-tagging engine work** (synthesis §G); **(8) summon/pet engine re-scoped as a general system** (enemy adds on trash/bosses + the future necro), its own milestone, built regardless of necro; **(9)** the repeated `+maxHP%` safe-pick replaced with distinct per-spec floors. Keystone-sequencing clarified two ways (engineering: the `condHolds` unification first; roadmap: revamp before P.5c). Doc-only — `tsc`/sim untouched.
- **2026-06-22** — **Sequencing decision: talent/trait revamp BEFORE P.5c (regime tuning); talent-tree investigation kicked off.**
  P.5c (the DPS-check / regime shift) is the GLOBAL balance calibration, and talents+traits are direct sim power inputs
  (output/intake/hp/crit into `buildParty`). Calibrating the regime now and revamping after would force re-tuning the whole
  regime + all six dungeons' reads a second time — so the revamp comes first; the regime **direction (timer-bound) is locked**
  and will guide the revamp (design active throughput/utility talents over generic survival). P.5a/P.5b stay committed
  (spec/mechanic-specific). **Kicked off the talent-tree design investigation** (`Docs/Talent-Trait-Revamp.md`): WoW-inspired
  (retail + classic), **≥15 nodes/spec in ~5 tiers of 3 mutually-exclusive choices**, each a real playstyle tradeoff
  (AoE↔ST · survival↔output · sustain↔burst · lean-into↔away-from the class-tool), **earnest in-world gothic names** (no
  meta/QA puns), across all **12 specs** (10 current + Necromancer Bonecaller/Pallbinder). Re-scoped C.2 accordingly.
- **2026-06-22** — **P.5b spec-power: berserker fix SHIPPED (+ overturned the magic≫physical framing).** The user chose
  "spec-power first" because the magic≫physical imbalance was confounding the generic-EHP measurements. A controlled
  per-spec probe (`spec-power.mjs` — 1T/1H/3×[spec], neutral tactics, on a trash-heavy dungeon (Ashveil) and a boss-spike
  one (Stillhour)) **disproved magic≫physical**: magic vs physical *averages* are ~equal (ashveil 6.5 vs 6.7; stillhour
  15.0 vs 14.7), and excluding berserker physical is actually *stronger*. The real outlier was **berserker, broken-LOW**
  (ashveil **+1**, stillhour **+5** vs the pack's +6–22), which dragged down every comp that ran it (Meta-Cleric, AllPhys)
  — the true reason those comps looked weak. Root causes in its kit: low damage coefficients (0.6–1.0× vs assassin's
  0.9–1.4×), a **15%-HP self-cost on `blood-frenzy`** (every 6s — lethal at scale, and a heavy healer tax), and an
  **unimplemented `low-hp-bonus-scaling` passive** ("not specified… flagged for tuning"). Fix: `blood-frenzy` HP cost
  15%→5%; coefficients +30–40% (cleaving-strike 0.6→0.85, whirlwind 0.7→0.95, bladestorm 1.0→1.35, massacre 0.9→1.2).
  **Result: berserker +1→+6 (ashveil), +5→+18 (stillhour) — now mid-pack; Ashveil spec-spread 7→2; magic/physical
  balanced.** **Verified:** egm-smoke **byte-identical** (894/953/1190/1380 — the standard comp runs no berserker);
  op-verify determinism + +2 floor; sweep — the berserker comps rose (Meta-Cleric avg 9.8→11.0) and the school (AllPhys
  mono +7 vs magic +14 on Pyreward) + cast reads hold. **Key finding:** the comp-level payoff is modest because the regime
  is **still survival-bound** (berserker comps *wipe* on Ashveil, so more DPS doesn't lift the ceiling) — the fix is the
  prerequisite that lets **P.5c (the DPS-check / regime shift)** land cleanly without berserker confounding it. No SAVE
  bump (data-only). (Assassin = top, arcanist = low-on-bosses → ST-vs-control niche, left as-is.) Probe `spec-power.mjs`.
- **2026-06-22** — **P.5a stacked-shield nerf SHIPPED (first step of the generic-EHP kill).** The C.11/P.0 disease:
  generic-EHP comps out-ceiling the standard 3-DPS comps by ~4–5 keys (`CrusaderTank` won all 6, avg 15.0). Two Explore
  agents mapped the drivers: (1) **stacked shields** — Divine Shield (`80 + 1.0×maxHp`, **cd3**) kept a >100%-of-maxHP
  shield PERMANENTLY on the tank; Sacred Bastion a 35%-maxHp PARTY shield; Arcane Barrier a 1.5×power party shield — and
  (2) **unlimited healer throughput** (`mana`/`healCost`/`manaRegenPerSec` are authored in `tuning.json` but **never wired**,
  so 2 healers + lifebinder HoTs heal forever). P.5a takes the **clean, isolated first cut**: the three shields above are
  CRUSADER/ARCANIST-only, and the standard Meta-Cleric/egm-smoke comps run neither — so nerfing them hits the generic-EHP
  comps **without touching the standard comp's +2 floor or egm-smoke**. Changes: **Divine Shield** `scale 1.0→0.4 ×maxHp`,
  `cd 3→8` (a real ~37%-uptime cooldown, not a permanent second HP bar); **Sacred Bastion** party→**single-ally** peel
  (`0.35→0.5 ×maxHp` on one ally); **Arcane Barrier** shield `100+1.5×power → 50+0.6×power` (keeps the CC-immunity rider +
  barrier-break). Tooltips (`skills.json`) aligned. **Verified:** egm-smoke **byte-identical** (894/953/1190/1380); content
  validates. **Result (balance-probe, cap 20): CrusaderTank −3 to −5 keys** (ashveil +20→+17, bellreach +20→+15, pyreward
  +17→+14); spreads compressed (ashveil 14→11, bellreach 18→13, pyreward 9→6). **A real compression, but insufficient
  alone** — CrusaderTank still tops because its EHP also rides the Crusader's redirect/immunity/stalwart kit + the
  lifebinder's unlimited HoTs, and part of its lead is the **magic≫physical AoE imbalance** (now exposed). **Still owed
  (P.5b+):** healer-throughput cap, the §2.1 DPS-check, the Crusader's other survival, Bulwark/Light's-Salvation recosts,
  the spec-power pass, P9 anti-heal, and the P7 eruption (owed from P.4). No SAVE bump (data-only). Decided to bank P.5a
  and check in before the larger regime-shift pieces.
- **2026-06-22** — **P.4 shield/guard kill-priority + real summoned adds SHIPPED (P11 recut + P8) — the Leaden Carillon.**
  The user **recut P11** from positional "reach" (a back-line caster melee can't hit — which would globally break
  melee-vs-back-band targeting) into a cleaner **shield/guard kill-priority** mechanic, then chose to realize it as a
  **summon-shield boss**, unifying it with **P8 "real adds."** New engine primitives (loose-schema, no break): `guarding` /
  `shielded` / `summonsId` enemy flags; a `shielded` enemy takes **99% reduced damage** (`sim.shieldGuardReductionPct`,
  applied as `damageTakenPct`=−99 — `eff()` now folds the base field, byte-identically since it's 0 everywhere else) while a
  `guarding` ally lives; a `shielded` boss **summons a real `guarding` add mid-fight** every `sim.summonEverySec` whenever
  none is alive, spawned into `mobs[]` **and mirrored into the ReplayTimeline** (valid unique `ReplayMob`s with spawn-second
  HP) so the 2D replay shows adds appear/fight/die — `ReplayCanvas` gained a spawn-visibility gate so summoned adds don't
  phantom in early. Brain: `decidePartyFocus` **focuses the guard first under the Kill Order dial** (K.4 tactics-as-orders).
  **Content:** **The Leaden Carillon** (Hour of Bells stage 3) is now `shielded` + `summonsId:"bell-warden"` +
  `testsTactic:"killorder"`; the summon-only **bell-warden** guards it; a summoner boss runs ONLY summon+shield (its
  abstract dial mechanic is suppressed). **Tuning:** reduction 99 / summonEvery 18 / carillon HP 28 / warden HP 4, **warded
  from t=0** (unskippable). **Verified:** `tsc -b` clean; content validates (+ `summonsId` and `guarding&&shielded`
  cross-refs); egm-smoke **byte-identical** (894/953/1190/1380 — P.4 touches only Hour); op-verify determinism + **+2 floor**;
  replay-integrity + determinism (the 18→5 summoned wardens are valid unique ReplayMobs); live UI **0 console errors**.
  **Balance (`balance-sweep`): Hour spread 2** (standard comps +13/+14 = a fair ~1–2-key carillon cost; +2 floor 3/3);
  **all 5 other dungeons byte-identical to the P.3 sweep.** **Adversarial review** (5-dimension find→verify, 17 agents →
  **6 confirmed all minor/nit + 6 dismissed**): **4 fixed** — (1) a mob flagged BOTH guarding+shielded would ward itself
  into a soft-lock → engine self-exclusion + a content-validation rule forbidding it; (2) DoT/bleed ticks bypassed the ward
  (leak ~1–2% boss HP, not the claimed 22%) → DoT ticks now respect the guard DR; (3) the boss was exposed for the first
  ~18s so a wildly over-geared burst could skip the mechanic → **summon the first guard at t=0**; (4) stale `leaden-toll`
  metadata → aligned to the kill-the-warden read. **2 documented, not fixed** — the read is currently a "flat damper" not a
  sharp burst skill-check (the 4-HP warden dies in one volley; AoE out-ceilings the standard comp via later-stage **survival**,
  the pre-existing **magic≫physical** imbalance → **P.5**), and a dead summoned add lingers as a skull dot (pre-existing
  cosmetic for all trash; P.4 just makes it visible on a boss). **No SAVE bump** (flags = content; summon/shield = runtime).
  Harness `carillon-replay.mjs`. **⚠️ Deferred: P7 (telegraphed eruption — Crusader immunity / Guardian relocate) was NOT
  built** — the user's recut focused on the shield-guard; fold P7 into a later ticket. Next: **P.5** (anti-heal/purge +
  self-healing P9 boss + final kit recut + the generic-EHP kill + the spec-power/DPS-check that also sharpens P.4's read).
- **2026-06-22** — **P.3 dispel typing + spreading curse SHIPPED — the Weltering Mire P4 typed-dispel read.** Built a real
  typed-dispel system: a `dispel` type on statuses (Magic/Curse/Nature/Poison) + a `dispelTypes` filter on cleanse effects,
  so `cleanseStatuses` only strips a status whose type matches — the **Cleric** (`Mass Dispel` = Magic/Curse) and the new
  **Lifebinder** ability **`Unbinding Word`** (Nature/Poison) answer *different* curses. New **enemy→party curse**: the
  Mire's 4 rot bosses are flagged `curse:"Nature"`, and the engine lays a stacking **`creeping-rot`** DoT on the whole
  party every 8s that **ticks per stack** (escalates past flat HPS) — resolved **data-driven** from the curse type (a
  future Magic curse auto-wires its own status rather than misfiring the hardcoded Nature one). Brain: a healer-only
  `dispelCurse` behaviour pre-empts the rotation to strip a matching curse (scoped to removable kinds), and the
  pure-cleanse `Unbinding Word` is **held** out of `dumpRotation` so it fires reactively; a wrong-type healer can't answer.
  Because the Mire **rot (P6) ran hot post-P.0** (~+5 lifebinder edge — over the whole +3–5 budget), promoted
  `ROT_FRAC`/`BURST_FRAC` into `tuning.json` and **softened the rot 0.06→0.04** (a +1 secondary spice) so the **curse
  carries the read** (`curseBase` 0.06 / `curseEverySec` 8). **Verified:** `tsc -b` clean; content validates (+ new
  cross-ref guards on `dispelTypes` and the `curse`→status link); egm-smoke **byte-identical** (894/953/1190/1380 — the
  curse fires only on the Mire, every other dungeon untouched); op-verify determinism + **+2 floor**; live UI **0 console
  errors** (`p3-live.mjs`). **Read (`mire-verify.mjs`, 5 seeds, gear-appropriate ilvl): Lifebinder ceiling +23 vs Cleric
  +18 = tool tax +5** (top of the +3–5 band); **Stillhour control gap +0** (proves the gap is Mire-specific, not
  lifebinder>cleric power); **mechanism — the Lifebinder dispels (caps the curse at 2 stacks → 0 deaths → times) where the
  Cleric can't strip Nature (hits 6 stacks → deaths climb → wipes at +18+)**. **Adversarial review** (5-dimension
  find→verify workflow, 9 agents) → **0 confirmed bugs**; applied 3 latent-trap hardening fixes (data-driven curse status,
  removable-kinds-scoped `dispelCurse` scan, `dispelTypes`/`curse` cross-ref validation). **No SAVE bump** (creeping-rot is
  runtime-only; matches the P.2 precedent). **Caveats → P.5:** generic-EHP comps still bypass via shields/2nd-healer
  throughput; on the Mire the Nature curse makes the Lifebinder the only *clean* answer (P4 is secondary here, full
  substitute = heavy survival, narrowed at P.5). Next: **P.4 reach + real adds + avoidable-immunity** (P11/P8/P7).
- **2026-06-22** — **Roadmap visualization board added (`Docs/roadmap-board.html`).** A self-contained, dependency-free
  interactive HTML view of this tracker (double-click to open): **Kanban board** (Todo/In-Progress/Blocked/Done/Deferred,
  phase-tagged cards with effort/severity/★-leverage badges), **wave Gantt** (phases sequenced by dependency order with a
  NOW marker, not calendar dates), **dependency map** (critical build chains + the Open-Design-Decisions-that-gate-tasks
  table), and a **quick-wins quadrant** (effort × impact: quick-wins / big-rocks / fill-ins / money-pits). Generated +
  Playwright-verified (`web/scripts/roadmap-board-check.mjs`, 0 console errors), and its embedded data was adversarially
  audited against this file (5-auditor workflow → all statuses/efforts/severities CLEAN, no missing/extra tasks; 3
  decision→blocked-task link completeness fixes applied). **Tooling/docs only — no game code, sim, or balance touched.**
  Regenerate/re-verify whenever the roadmap changes.
- **2026-06-22** — **P.2 enemy cast scheduler + real interrupt SHIPPED — the flagship "kick-or-wipe" (Bellreach = P1).**
  Built a real enemy cast scheduler in `engine.ts`, gated to abilities flagged `interruptible:true` (only Bellreach's
  antiphon/drowning-psalm/final-peal — reusing their existing `shape:"cast"`+`telegraph` data, so Ashveil's Vesk and
  Pyreward's Heretic stay on the abstract dial and every other dungeon is byte-identical). A flagged boss begins a cast
  every ~12s (telegraph = the kick window) and, if the window elapses uninterrupted, lands a **stacking party-wide nuke**
  (`sim.castStackGrowth` → escalates to a wipe) tracked via a runtime `pendingCast` on the Combatant. Un-deferred the
  `{type:"interrupt"}` effect (`combat.ts`, previously a no-op) so Counterspell/Zen Strike **cancel** the pending cast; a
  landed **stun/silence/freeze** also cancels (daze doesn't — keeps interrupt a mage/sage identity). Dedicated interrupts
  are now **held** (excluded from `dumpRotation`) so a kicker reserves its kick instead of burning it as filler, and a new
  brain behaviour `interruptPending` pre-empts the rotation when a cast is up. The Interrupts tactic **dial is demoted** to
  a weak auto-kick backstop (`sim.castFallback*`). **Verified:** `tsc -b` clean; content validates; egm-smoke
  byte-identical (894/953/1190/1380); live boot 0 console errors; **log probe (arcanist +5: 24/25 casts interrupted →
  TIMED; no-kicker: 6 casts land → WIPE at dur 266)**; full sweep — kicker comps cap Bellreach **+6** vs no-kicker **+2-4**
  (a ~+3-4 kick gap, in the +3-5 band), other 5 dungeons unchanged, **+2 floor holds**. **No SAVE bump** (pendingCast is
  runtime-only; matches the P.1 results-change-without-shape-change precedent). New harness `bellreach-ceiling.mjs`.
  **Caveats → P.5:** generic EHP still bypasses the read (`CrusaderTank` +15 via shields, `TwoHealer` +9 via 2nd healer);
  the kicker's absolute Bellreach ceiling is low (+6 — a Bellreach-difficulty tune, not the mechanic); pyromancer's
  Meteor-stun is a *situational* kick (cd8), so arcanist + mystic are the reliable answers. Next: **P.3 dispel typing**.
- **2026-06-22** — **P.1b Bard→Archer recut SHIPPED — P.1 complete.** Repurposed the rogue support spec into a **selfish
  ranged physical DPS** (the design's "rogue is the physical class: Assassin melee-dive + Archer ranged"). Spec **display
  name Bard→Archer** (internal id kept `bard` for save/ticket stability — like the H.1 ability-rename precedent; ability ids
  *are* re-id'd since they aren't persisted). Recut all 6 abilities + the major from support→damage: Barrow-Quarrel (ST +
  Mark), Marrow-Piercer (cd3 focus-nuke + execute), Over the Barrow (back-band reach ×1.3 — P11 flavour; full primitive =
  P.4), Carrion Hail (AoE), Cold Focus (self power/crit window), Unerring Eye (selfish passive), Culling Rain (offensive AoE
  major). **Dropped ALL party support** — lust (Anthem), party-heal/cleanse (Soothing Ballad + Inspiring Presence song-heal),
  ally CD-reduction (Rhythm Reset), party buffs (Crescendo/Rallying Crescendo). Tuned at assassin-parity; names IP-checked.
  **Verified:** content validates (Zod), `tsc -b` clean, egm-smoke byte-identical (no archer in that party), the P.1a school
  tax **holds at net +4** post-recut, +2 floor holds. **Key finding:** removing the bard-heal dropped the all-physical comps
  (AllPhysDPS avg 12.0→10.0, Ashveil 11→6) — the **support-DPS confound is gone** — which **exposed a pre-existing
  magic-DPS≫physical-DPS imbalance** (pyro/arcanist out-scale berserker/archer ~9 keys on the no-wall control via AoE
  trash-clear). Flagged for a **spec-power pass (P.5)**; Archer itself is correctly tuned (assassin-parity, ST-focused by
  design). Next: **P.2 cast scheduler + real interrupt** (Bellreach flagship "kick-or-wipe").
- **2026-06-22** — **D.10 added — telemetry / run-analytics pipeline (planned, sequenced after Phase P).** Design
  decided this session: every key already builds a `RunTicket` (comp/specs/talents/gear/tactics/key/affixes +
  outcome/timer/deaths) and the sim is deterministic with a working `replayTicket` re-sim — so the analytics record
  **and** its re-derivation already exist; the only missing piece is shipping the ticket to a sink. Plan: POST the
  ticket + version stamps to **one HTTP sink (Supabase Postgres) from BOTH the web (Vercel) and Steam builds** —
  Steam-native Stats are explicitly NOT the analytics sink (Steam-native = leaderboard-only). Log inputs + outcome,
  re-derive damage/log by re-sim (tiny payload; lets new analyses run retroactively on old runs). Hard requirements
  baked in: PII-strip (drop player-authored character names; anonymous installId), consent + Steam data disclosure +
  opt-out, fire-and-forget (never blocks a run), and version stamps (schema/SAVE/content/buildTarget) so pre-P and
  post-P runs aren't pooled for balance. Powers **C.11** (spec/talent pick-rate vs win-rate from real players) +
  retention/refund signal. Plumbing may land alongside the Vercel friends-test; trustworthy *balance* data only
  accrues **after Phase P combat settles**. Open decision logged: stack (Supabase vs PostHog vs thin Vercel fn) +
  consent model. Module = `telemetry.ts` (not `logs/analytics.ts`, which is the in-app WCL-style meter view).
- **2026-06-22** — **P.1a Pyreward school re-tune SHIPPED (the works-now class axis).** Tuned `pipeline.schoolWallFraction`
  K 380→**155** (cap 0.65 is a safety ceiling — not binding for Pyreward's armour/resist 250/150, so K is the only active
  lever). Iterated against `pyreward-ceiling.mjs` (extended to keys 2–18 + a balanced-2P1M diversity comp): the **off-school
  tax now lands at net +4 keys** — an all-physical (mono-school) core caps **+5** on Pyreward vs a mixed core's **+14**,
  minus the **+5 Ashveil spec-power control**, so +4 is the school-attributable tax (centered in the +3–5 band). Discovered
  the wall only differentiates once it's steep enough that a fully-walled boss trips **soft-enrage** (an evenly-alternating
  armour/resist layout is otherwise mirror-symmetric — both mono cores eat equal average tax). Full `balance-sweep`:
  AllPhysDPS Pyreward 14→10, **other 5 dungeons byte-identical to P.0**; egm-smoke unchanged (Ashveil armour 0 → wall inert);
  **+2 floor holds**; `tsc -b` clean. **Caveats (honest):** the read leans near-binary "bring 2 magic" (only 2 magic DPS
  specs; cleric-smite as a 3rd magic source is untested → P.5 full sweep); generic-EHP comps (Crusader/Mystic shields +
  sustain) still top Pyreward regardless of school (P.5); and the magnitude is **provisional pending P.1b** (Bard→Archer
  removes the bard party-heal that inflates the all-physical control comp). Next: **P.1b Bard→Archer**.
- **2026-06-22** — **P.0 GATE 0 SHIPPED — and it settled the C.11 conflict.** Implemented the three GATE-0 levers + a clean
  `SAVE_VERSION` bump (5→6): (1) **boss-dive fix** — `makeEnemy` now gives bosses the `melee`/focusTank profile (the old
  `band==="back" → caster` rule made 10 back-band bosses auto-attack the squishy back-line; intentional dives still run via
  `spikeProfile`/abilities); (2) **hit-size-independent school wall** for enemy defenders (`pipeline.schoolWallFraction`,
  K=380/cap-0.5) replacing the self-defeating ratio formula, with armour/resist no longer keyScale-scaled (stable off-school
  tax %); (3) **percentage-only intake floor** `sim.intakeFloorFrac=0.40` clamped in `dealDamage` (armour×Awareness×DR can't
  cut a hit below 40% of the raw swing; shields/HoTs deliberately excluded — recost at P.5). **Verified:** `tsc -b` clean;
  **sweep before→after spread: Stillhour 3→0, Mire 7→0** — the C.10 burst/rot healer "reads" **collapsed, proving they were
  survival-dominance artifacts** (exactly the C.11 hypothesis; they get rebuilt via real mechanics in P.3/P.5, not tuned),
  Pyreward 12→6, Hour 6→1; egm-smoke shifted 884/914/1182/1367 → **894/953/1190/1380** (floor caps the gear-cap tank's
  armour; determinism + **+2 floor hold**). **Did NOT meet `Ashveil <2`:** Ashveil (front-boss/no-armour) is untouched by
  the 3 levers and `CrusaderTank` still wins all 6 (avg 15.0) via **shields + 2nd-healer throughput** → that compression
  re-scoped to **P.5** (Divine Shield bug + shield recost) plus a new **DPS-check** lever (boss HP / timer). Baselines:
  `balance-sweep.mjs`. (User decision: commit P.0 scoped, proceed to P.1.)
- **2026-06-22** — **Phase P designed — the "Class-Tools System" (`Class-Tools-System.md`); goal flipped to "class choice
  MATTERS".** After the C.11 audit, the user clarified the real goal is the OPPOSITE of "player not class": **classes
  bring different tools to solve different dungeon problems**, class choice is a rewarding edge, and the user will redesign
  the classes for cohesion. A multi-agent design pass produced a **12-problem taxonomy** (interrupt / school walls /
  curse-dispel / burst / rot / eruption / adds / empowered-enemy / reach / enrage), a **cohesive 10-spec recut** (every
  spec a signature verb, 2–3 diverse answers per problem, no dead weight), the **anti-generic-EHP plan** (narrow the 5
  fungible majors), the **dungeon remap**, the **engine backlog** (cast scheduler is the key unlock), and a 6-milestone
  build plan. User corrections locked: **2-healer must be timer-limited** (timer = real DPS check); **Bard→Archer**
  (ranged physical); **DPS don't dispel** (healer-only); **P10 tank-buster DROPPED** (no 2nd tank) → Hour of Bells keeps
  cooldowns; **Light's Salvation → reactive burst heal**, not a rez (combat-rez already exists); **intake floor 40%/cap-60%**;
  **tool-tax +3–5 keys** with full-substitute alternates; **SAVE_VERSION bump at P.0**. Design-only — execution deferred.
- **2026-06-21** — **Balance audit (C.11 opened) — comp spread is 7–12 keys, and the class-reads are survival artifacts.**
  Ran `balance-sweep.mjs` (10 comps × 6 dungeons). Found comp ceilings spread **7–12 keys** (vs intended ~1–2), driven by
  a **survival-bound regime** (2-healer caps above 3-DPS; party-mitigation specs dominate). Root causes: spec-utility
  inequality (Crusader party-shields ≫ Guardian; a support-DPS = +6 keys; Crusader **Divine Shield bug** = full-HP
  shield), and **back-band bosses diving squishies** (correctness bug). The decisive compression lever is global intake
  (`enemyDmgMult`). **Critical:** fixing the boss-dive bug **erases the C.10 healer + C.8 school reads** — they were
  survival-dominance artifacts, not the burst/rot/armour mechanics (the **dial** reads are real and survive). So balance
  and the class-reads conflict → directional decision pending (regime-shift + re-tune reads, vs keep reads + spread).
  Committed the audit tooling (`balance-sweep.mjs`, `balance-probe.mjs`); no balance values changed yet (exploration
  reverted to keep the repo stable). Blocks loot/ilvl calibration until resolved. **→ Resolved 2026-06-22 into Phase P
  (Class-Tools System): the goal flipped to "class choice MATTERS" — classes bring different tools, the specific tool
  wins not generic EHP. See `Class-Tools-System.md`.**
- **2026-06-21** — **C.1 DONE — The Hour of Bells (5/5); the 6-dungeon season is complete.** Authored the final dungeon
  as **pure data** (no engine work): a boss-dense gauntlet of **5 cooldowns-spike bosses** + 3 trash, added to the
  season, placeholder loot. Verified via `hour-of-bells-live.mjs`: **+2 floor times** (600s/1500s), and the **Cooldowns
  dial swings the ceiling ~4 keys** (Cooldowns-3 caps ~+9 vs Cooldowns-0 ~+5) — the −12%/pt spike mitigation compounds
  across 5 bosses, making it the **clearest dial read** of the set. That's a *tactic-dial* read (a player decision), so
  it's allowed to bite hard — distinct from the soft ~1–2-key rule that governs *class* preferences. Ships under the
  standard Fortified+Bursting pool (Tyrannical+Raging enhance, don't gate). `tsc -b` clean; egm-smoke unchanged.
  **C.1 complete: Ashveil + Bellreach + Stillhour + Weltering Mire + Pyreward Ossuary + Hour of Bells**, each a distinct
  solve (interrupts / burst-heal / rot-heal / damage-school / cooldowns), mechanics-first with placeholder loot.
- **2026-06-21** — **C.8 + C.1 The Pyreward Ossuary (4/5): per-enemy damage-school defense, soft-tuned.** Shipped **C.8**:
  optional `EnemySchema.armour/resist` (default 0 → Ashveil byte-identical), wired through `makeEnemy` (scaled by
  keyScale) and routed by the existing `pipeline.resolveHit` (Physical→armour, Magic→resist, ratio formula). Authored the
  **Ossuary** — 4 bosses alternating high-armour (eats Physical) / high-resist (eats Magic), each a distinct `testsTactic`,
  + front-melee trash; added to the season; placeholder loot. Tuned to the **soft-gap spec** (armour/resist 250 boss /
  150 trash): a mixed-school core caps ~+13 like the other dungeons, the **school-specific tax is ~1–2 keys** (verified via
  `pyreward-ceiling.mjs` with Ashveil as the no-armour control to subtract spec-power confound). **Findings:** the
  `resolveHit` ratio formula is *sticky* (small hits stay ~15–20% mitigated across a wide armour range → coarse tuning);
  trash **must be front-melee** (caster-heavy trash turned it into an AoE check — pyro/arcanist shred back-liners —
  confounding "have magic" with "have AoE"); and a single-school core also eats a spec-power penalty (only 2 strong DPS
  per school), so the raw ceiling gap is wider than the ~1–2 *school* keys. `tsc -b` clean; egm-smoke (Ashveil) unchanged.
- **2026-06-21** — **C.1 The Weltering Mire (3/5) + C.10 re-tuned to "bring the player, not the class".** Adopted a design
  principle: tactic dials are the primary solve; spec preference is a *soft* secondary lever — both options clear the
  floor and mid keys, the ideal spec only extends the **ceiling ~1–2 key levels**. Re-tuned **Stillhour's burst from a
  hard floor-wall (`0.35·maxHp`) down to a soft `0.06`** (both healers now clean to +12; Cleric ~+13–14, HoT caps +12).
  Added the symmetric **`rot` spikeProfile** (flat tick on each non-tank /3s, `ROT_FRAC` 0.06) and authored **The
  Weltering Mire** around it (4 rot bosses, low auto-attack + thin front-melee trash so the party-wide rot — not tank
  survival — decides the ceiling): both healers clean to ~+6, **Lifebinder ~+9–10 vs Cleric ~+8**. New sweep harness
  `healer-ceiling.mjs` (per-healer timed-ceiling per key). `tsc -b` clean; egm-smoke (Ashveil) unchanged; opt-in so
  Ashveil/the +2 floor are untouched. (The pure-data Mire inverted — back-band casters concentrate damage, the Cleric's
  strength — which is why the symmetric engine pattern was needed.) Placeholder loot; polish pass later.
- **2026-06-21** — **C.10 + C.1 Stillhour Abbey (2/5): a burst-spike engine pattern, and the dungeon that uses it.**
  Verifying Stillhour exposed its burst-Cleric read as **inverted** in the engine (the HoT Lifebinder out-healed the
  burst Cleric on the soft party-wide toll) — and it was **not data-fixable**. **C.10 (engine):** opt-in
  `spikeProfile:"burst"` boss variant (`engine.ts` + `schema.ts`) — a single hard hit on the **lowest-HP non-tank every
  6s** (`0.35·maxHp`, still `testsTactic:cooldowns` so the Cooldowns dial mitigates; Ashveil untouched via opt-in).
  **C.1 Stillhour (data):** 4 bosses (Verger Antiphon positioning-teacher + 3 burst tolls), thin trash, placeholder loot,
  probe `stillhour-live.mjs`. **Verified:** the Cleric **times the +2 floor across 5 seeds** while the HoT Lifebinder
  **wipes 4/5**; misspent dials wipe; `tsc -b` clean; egm-smoke (Ashveil) unchanged. The healer-choice pair now works
  (Stillhour→Cleric via C.10; the Weltering Mire→Lifebinder is the native inverse, pure data).
- **2026-06-21** — **C.1 Bellreach Sanctum authored (1/5 new dungeons) — the interrupts dungeon, mechanics-first.**
  Pure data: `dungeons.json` (8-slot dungeon, placeholder loot reusing Ashveil items), `enemies.json` (4 bosses —
  Cantor Brivael / The Drowned Choir / Verger Mottram[breather, cooldowns] / The Unrung Bell — + 3 caster-heavy trash),
  `abilities.json` (antiphon/drowning-psalm/toll-the-hours/final-peal), `packs.json` (2 back-band packs),
  `season.json` (added to rotation). New probe `web/scripts/bellreach-live.mjs`. **Verified:** content validates,
  `tsc -b` clean, egm-smoke (Ashveil) unaffected, **+2 floor times**, and the Interrupts dial controls the cast mechanic
  (Interrupts-3 → 0 casts through; Interrupts-0 → ~19–26). **Known limit (logged, not a blocker):** the interrupt read
  is log-visible but does **not** flip timed↔wipe at gear-appropriate ilvl — sharpening it needs a global cast-coefficient
  tune or per-encounter weighting (balance follow-up, proposals §8.4). Loot/items/tier-set = later polish pass.
- **2026-06-21** — **G.4 in progress: full-colour raster icon pipeline + 89 user icons wired (abilities now have art).**
  Umut dropped a folder of painted PNGs (`Docs/Icons/`). Switched `GameIcon` from the CSS-mask SVG path to a **full-colour
  raster** render: `<img src=/icons/{prefix}-{id}.png>`, and a missing file degrades via `onError` to a default —
  `affix-default.png` for affixes, `icon-default.png` (the bear) for everything else — so wiring a new icon is just
  dropping the PNG in (no manifest to maintain). Added a new **`ability` kind** and surfaced ability art **inline in the
  event-log spell names**, the **spell-tooltip header**, and the Character-sheet **Signature** card (was a generic bolt).
  Copied **89 PNGs** into `web/public/icons/` with **10 typo-renames** (`abilitiy-`/`abilitt-`/`challange`/`eviscreate`/
  `groces`/`dispell`/`assasin`/`postioning`/`tack-`); skipped 3 spares (`bladestorm2`, the 2 `status-*` — no status UI).
  **Wired:** 53/70 abilities, all 10 specs, 3 roles, 3 operator skills (were placeholders!), 3 currencies, 5 ui, 4 tactics,
  4 stats, 2 affixes. **Still missing → bear/affix-default** (the art to make next): **17 abilities** (shadow-step, the 6
  Bard skills [deferred to L], the 10 majors), **6 affixes** (bursting/bolstering/volcanic/sanguine/spiteful/raging — these
  show **blank** until drawn), **stat-ilvl**, **ui-trait**, and **items / talents / traits / dungeon banners** (none
  supplied). Per Umut's call: full-raster-only + default-image-everywhere. **UI/asset-only → `egm-smoke` byte-identical.**
  Verified: `tsc -b` clean; `g4-live.mjs` — ability icons inline + raster (no mask spans) + tooltip icon + spec/role icons
  + character sheet + **no broken images** (missing resolves to default), **0 console errors**.
- **2026-06-21** — **C.1 dungeon roster designed → `Dungeon-Design-Proposals.md`.** Multi-agent design pass (engine-mapped
  + adversarially critiqued) settled the **new-dungeon roster: Ashveil + 5**, each a distinct player "solve": Bellreach
  Sanctum (interrupts), Stillhour Abbey (burst-triage heal), The Weltering Mire (sustained-HoT heal + kill-order), The
  Hour of Bells (cooldowns gauntlet) — **all pure data** — and **The Pyreward Ossuary** (Physical-vs-Magic damage school),
  the only dungeon with **real comp pressure**, gated on new ticket **C.8** (un-hardcode `makeEnemy` armour/resist, "small").
  Key engine truth recorded: a dungeon's solve = the 4 tactic **dials** (comp does **not** feed them; "bring a kicker" is
  fiction until a large interrupt-capability ticket); damage-school is the lone comp lever. New affix proposed (**The
  Tolling**) + the verbatim-WoW affix **IP rename** (Bursting→Plaguebloom, Spiteful→Restless Shade, Tyrannical→Crowned in
  Ash, Raging→Death-Frenzy) flagged as a build-now prereq. No code/data shipped yet — design only.
- **2026-06-21** — **M.3 + M.4 + M.5 shipped: the bark engine + voice packs + loot-drama-in-the-feed — Phase M complete (v1).**
  Roster members now react in their **own personality voice** in the guild feed, on top of the neutral M.1 notifications.
  **M.3 (engine):** `web/src/state/barks.ts` `generateBarks` — a **pure, seeded** (`Rng` mulberry32, **no `Math.random`** →
  deterministic + replay-safe) selector. `CONFIRM_LOOT` collects the run's emotional moments (loot snub=100 / wipe=90 /
  clutch=80 / morale-crater=70 / keystone-push=50 / depleted=45 / comfortable-timed=20), sorts by priority, and a **rarity
  budget** keeps the cadence to **~1–2 barks/run** (high-emotion ~always, low-stakes ~40%, a 2nd bark gated; one per
  speaker). Voice = **archetype(tone)** bank routing × **morale(mood)** banded-interjection prefix × a **per-character
  seed** (individuation) — **state-grounded** via slot fills (`{item}{winner}{dungeon}{key}{margin}`), with a **no-repeat
  window** (`barkLog`, last 16 keys, persisted; additive, no `SAVE_VERSION` bump). Because voice attaches to **personality,
  not identity**, procedurally-generated members get a voice for free. **M.4 (content):** `data/barks.json` — a new
  Zod-validated content domain (`BarksSchema` → `content.barks`): 7 events × 5 archetypes (Selfish / Wildcard / Specialist
  / Enabler / Leader) + `default` + a `moods` bank ≈ **90 templates**, holding the **two-layer rule** (earnest grim item
  names, ALL satire in the reaction). **M.5 (integration, fell out for free):** a loot **snub** now emits BOTH the marquee
  system line AND an in-character bark from the snubbed member, side by side — the shareable moment (e.g. *"Treads of Quiet
  Rest was a bigger upgrade on my sheet but sure, feelycraft it to Bramblewen."*). Barks render in `GuildFeed.tsx` as
  `kind:"bark"` (speaker name in spec colour + italic, dashed accent). **Verified:** `tsc -b` clean; `egm-smoke` goldens
  **byte-identical** (914/884/1182/1367 — barks live in the reducer, not the sim) + `op-verify` green (content still loads);
  new `m3-bark.mjs` (determinism / state-grounding / variety / archetype routing / no-repeat / rate-limit / mood — 7/7) and
  `m3-live.mjs` (a snub yields a bark from the snubbed member, speaker-attributed + italic — 5/5, **0 console errors**).
  **Phase M v1 complete**; M.6 (multi-character exchange beats + Rival escalation) stays **v2 💤**. Memory: `goatlite-guild-feed`.
- **2026-06-21** — **Signature-major ids de-metaed: internal ids now match the in-world spell name.** The 10 Phase-H
  per-spec majors still carried their pre-H.1 **QA/dev codenames** as their `id` (`code-freeze`, `hotfix-deploy`,
  `prod-incident`, `zen-mode`, …) while their display `name` had been renamed to fantasy MMO spells — so the
  `icon-tracker.csv` `icon_id`s (derived as `ability-{id}`) read as meta names, not the spell. Renamed each `id` to the
  kebab of its display name (`bulwark-banner`, `lights-salvation`, `emberstorm`, …) across **`data/abilities-player.json`
  + `data/skills.json`** (one shared id namespace — the engine emits `skillId: ability.id`, the UI resolves the tooltip
  via `content.skills.get(skillId)`, so both files must rename together) and updated the **`Docs/icon-tracker.csv`**
  `icon_id`s to match, restoring the `icon_id == ability-{id}` convention. Safe by construction: majors are selected by
  the `"major"` **tag** (not id) in `combat.ts`/`ReportPage` `MAJOR_IDS`, no behaviour-profile/talent/save references the
  codenames, and file order (determinism) is unchanged. **Verified:** `tsc -b` clean; `egm-smoke` green; **10/10
  major→skill joins resolve**.
- **2026-06-21** — **M.2 reworked: loot drama is a SNUB, not a per-run tax (+ winner buff dropped).** Umut flagged that
  the first cut drained morale on *every* run — with the multi-spec Ashveil items almost every drop has 2+ eligible
  members, so "contested = 2+ can use it" punished the roster passively. Reframed: **shared loot is normal and free; only
  a *snub* costs morale** — a call someone can legitimately resent. Two snub paths in `CONFIRM_LOOT`: **(A)** awarding to
  a member while a **skipped member had a materially bigger ilvl claim** (gap ≥ `LOOT_SNUB_GAP`=5, extra sting ≥
  `LOOT_BIG_GAP`=12), and **(B)** **scrapping an item that was a significant upgrade** (≥ `LOOT_SCRAP_MIN`=8) for a member
  ("you DE'd my BiS"). Awarding the **best fit** — or one click of **Auto best-fit** — now costs nothing, so drama is
  **opt-in**. The snub still fires the `lost-loot` event with personality-scaled magnitude (Selfish −8 / Boomer·Casual-Andy
  −2 / else −5) and a `Loot snub …` feed line. **Dropped the +5% winner buff entirely** (per Umut) — it was a quiet
  always-on power creep; loot drama is now **purely social with zero balance impact** (reverted the `SimPartyMember.lootBuffPct`
  → `opOutputMult` threading; removed `RawMember.lootBuffPct`; deleted `m2-buff.mjs`). **UI** (`LootPage`): a **BEST FIT**
  tag on the no-drama choice, a `Wanted ×N` info chip (replacing the scary ⚔ badge), and a live **⚠ warning** that names
  who'd lose morale for the *current* pick. **Verified:** `tsc -b` clean; `egm-smoke` goldens **byte-identical**
  (914/884/1182/1367 — confirms the sim is back to baseline); `op-verify` +2 floor + determinism; reworked `m2-live.mjs`
  proves a snub on a bad pick (the snubbed member gained 8 morale vs a teammate's 10) AND **no snub on a best-fit award**,
  **0 console errors**. Memory: `goatlite-guild-feed`.
- **2026-06-21** — **M.2 shipped: the loot-drama mechanic (contested-item resolution) — also closes B.5.** When a drop
  would upgrade **2+ party members** and the winner is one of them, it's **contested**. **Winner:** a new persisted
  `RawMember.lootBuffPct` = **+5% output next run**, threaded through `SimPartyMember` and folded into `opOutputMult` in
  `buildParty` (`stats.ts`) — captured in the run ticket (replay-faithful) and **consumed/cleared after that next run**.
  **Loser(s):** the previously-**dormant `lost-loot` morale event** (`morale-events.json`) is now wired and applied,
  **personality-gated** — Selfish archetypes (Loot Goblin / Solo Player / Cocky / Rival) lose more (−8), Boomer /
  Casual Andy shrug (−2), everyone else the canon −5; it **stacks** on the outcome morale delta. **No `SAVE_VERSION`
  bump** — `lootBuffPct` is additive and sanitized on load (default 0), so existing rosters survive (supersedes the
  design-note "bump"). **Feed:** `CONFIRM_LOOT` emits a marquee `Contested: {winner} took {item} over {losers}` line
  through M.1 (the bark layer is M.3/M.4 → M.5). **UI** (`LootPage`): a ⚔ Contested badge, a consequence preview
  (winner +5% / losers −morale), and a one-click **Auto best-fit** so resolution is opt-in — a decision, not a tax.
  Also surfaced `lootBuffPct` on the shaped `Member`. **Verified:** `tsc -b` clean; new `m2-buff.mjs` proves the buff
  raises output, is a **no-op at 0** (so goldens are safe) and stays deterministic; `egm-smoke` goldens **byte-identical**
  (914/884/1182/1367); `op-verify` +2 floor + determinism green; new `m2-live.mjs` drives a guardian+berserker comp to a
  real contested drop and asserts the ⚔ badge, the `Contested:` feed line, the winner's +5% buff, and the personality-
  gated snub (a Boomer loser took only −2) — **0 console errors**. Roadmap B.5 → ✅ (loot-drama UI delivered here);
  Phase B 13/14, Phase M 2/5. Memory: `goatlite-guild-feed`.
- **2026-06-21** — **M.1 shipped: the always-visible Guild Feed + system-notification stream (Phase M started).** Built
  the meta-layer notification center first (zero comedy — barks land in M.3/M.4). **State:** added a persisted
  `feed: FeedEntry[]` + monotonic `feedSeq` to `PersistState` (`game-store.tsx`) — **no `SAVE_VERSION` bump** (additive
  field; `freshState` seeds `[]` and a defensive load-guard means pre-M saves load with an empty feed), capped at 200
  entries. **Emit from the reducer** (every event's data is already in scope, deterministic): `CREATE_GUILD` → "founded";
  `CONFIRM_RECRUITS` → one "{name} the {Spec} joined the guild" per sign; `RAN_KEY` → "{owner}'s +{lvl} {dungeon} —
  {Timed/Depleted/Wiped} in m:ss, N deaths" + "N items dropped — awaiting distribution"; `CONFIRM_LOOT` → "{name}
  equipped {item} (ilvl X)", "{owner}'s keystone upgraded/depleted to +N", operator level-up (integer-tick), and a
  morale **at-risk** line only when a member **crosses** below 25 this run (no spam). Each line carries an optional spec
  `GameIcon` + a tone (good/bad/warn/neutral, tinted left border). **UI:** new `GuildFeed.tsx` mounted as a persistent
  300px right rail in `LogsApp.tsx` (wrapped the page render in `.app-body`/`.app-main`; rail shows only in the `playing`
  phase), chat-style newest-at-bottom with auto-scroll; member-tagged lines click through to the character sheet. Reuses
  `Panel`/`GameIcon` idioms + existing CSS vars (new `.guild-feed`/`.feed-item` styles in `logs.css`). **Deferred** (no
  engine yet): trait-earned (D.1) + departure-warning (D.2) notifications. **Verified:** `tsc -b` clean; `egm-smoke`
  goldens **byte-identical** (914/884/1182/1367, 0 deaths — confirms zero engine/sim impact); new Playwright
  `m-live.mjs` 9/9 green + **0 console errors** (feed hidden in onboarding → visible in play → founding/join/run/loot/
  keystone lines → click-through). Memory: `goatlite-guild-feed`.
- **2026-06-21** — **Icon-tracker triage: dropped the 16 `status-*` icons; kept all ability icons.** Audited (3-reader
  workflow + a direct grep) whether P3 ability/status icons surface anywhere in the live UI. Finding: the `GameIcon`
  registry (`web/src/logs/components.tsx:65-79`) has **no `status` kind and no aura/buff-bar UI exists** — statuses
  (dots/hots/buffs/debuffs/cc) live only inside the sim and are never drawn, so the 16 `status-*` rows were **removed
  from `Docs/icon-tracker.csv`** (re-add only if a status/aura surface is ever designed). Per design decision, **all
  ~70 `ability-*` rows (player + enemy) are kept** as needed — the user wants every ability to carry an icon. ⚠️
  Follow-up (not done here): abilities currently render as **text only** (Event Log `LogSpell`; the per-spec MAJOR on
  `CharacterPage` SignatureCard still uses a generic `bolt`) — making them show real icons needs an `ability` kind
  wired into `GameIcon` + the render surfaces updated, in addition to sourcing the art.
- **2026-06-21** — **Replay arena: continuous traveling path + tighter casters + de-aliased idle.** Reworked the
  movement from a per-pack reset into a **continuous seeded path**: a `useMemo` computes, per replay stage, a
  deterministic **pack center anywhere in the arena** (`hashF(seed+idx)` → `[0.32,0.80]×[0.30,0.78]`) and a party
  **station** a standoff short of it on the approach side, chained off the previous station (START for the first).
  Per frame the party **marches** prevStation→station while the pack's enemies **converge onto the tank** (lerp
  spawn→near-tank by `eng`); the tank position is **continuous across stage boundaries** (no reset/snap — the
  stage-change snap was removed). Formation builds along the engagement axis (party behind the tank, **casters in a
  tight cluster** — fixes "casters too static/spread"), so it faces whichever way the next pack is. **Fixed an idle
  aliasing bug** (20-agent review): the old clock-based idle sinusoids jittered because the playback clock jumps
  ~5 sim-sec/tick — moved the idle wobble to a **real-time CSS animation** (`.replay-idle`, paused on a scrubbed
  frame) so it's smooth at any speed and stays scrub-safe. Removed dead `Dot.ax/ay`/`spreadY`. UI-only → determinism
  untouched. Verified: `tsc -b` clean; live check 9/9, 0 console errors; headless path check confirms each stage gets
  a distinct location. Review: 3 dims → 14 findings → **2 confirmed (both fixed)**, rest refuted (continuity/
  determinism/axis-flip/no-tank/degenerate-geometry all hold). Memory: `goatlite-2d-replay`.
- **2026-06-21** — **Replay arena: pack-to-pack travel + taller canvas.** Two refinements to the arena: (1) **new
  packs spawn FAR RIGHT** (away from the party) and the engagement ramp was **slowed** (`eng` over ~16 sim-sec vs
  2.5) so the **party visibly travels across the arena** to engage each pack — the contact/scrum forms on the right
  where the pack stands, reading as "going pack to pack" rather than mobs teleporting into melee. A **stage-change
  snap** (suppress the `.replay-dot` transition on the first frame of a new pack) stops the persistent party dots
  from sliding *back* from the previous pack — each stage reads as "enter at the column, charge the pack". Enemy dots
  remount per stage (stage-keyed ids) so they pop in at the far edge then close in. (2) **Doubled the canvas height**
  (`H` 400→800) so the travel + spread + scrum have room. Still UI-only (derived positions) → determinism untouched.
  Verified: `tsc -b` clean; live check 9/9, 0 console errors; play-frame sequence shows enemies spawning far right,
  the party crossing the gap, and the scrum forming on the right where the pack stood.
- **2026-06-21** — **Replay arena: combatants now CLOSE into a tank-centered scrum (EGM-style movement, faked).**
  Following up the v2 arena, the dots no longer hold separate columns and shoot across a static gap — they engage.
  Added a movement pass to `ReplayCanvas.tsx` (UI-only, still no sim positions): an **engaged formation** (`eng` ramps
  over a stage's first seconds = the charge-in) where the **tank anchors a center contact line, enemy melee PILE ONTO
  THE TANK** (M+ behavior), and party melee-dps join the scrum around it; the **boss** holds center and the party fans
  onto it. **Ranged hold back and KITE** (a wider strafe so they're not static) while firing projectiles in. On top:
  a melee **press-sway** + a **per-attack lunge** (melee jab toward their target each hit, via a `transform` translate
  eased by the `.replay-dot` transition, which now includes `transform`). Verified: `tsc -b` clean; live check
  (`scripts/i-live.mjs`) 9/9, 0 console errors; play-frames show enemy tokens piled on the party-melee scrum (trash) /
  the party fanning onto the boss, with casters kiting and firing from the back. No engine change → determinism
  untouched. Memory: `goatlite-2d-replay`.
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
