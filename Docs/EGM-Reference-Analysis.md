# Exiled Guild Manager — Reference Analysis

**Source:** decompiled from `Extract/ExiledGuildManager.exe` (Godot 4.6, embedded PCK, 233 scripts + 411 resources recovered to `Extract/recovered/`).
**Purpose:** design study of the GDD's stated reference game. Mechanics, formulas, and tuning values below are for learning — **no code or assets from the recovered project may be copied into GOAT Lite.**
**Method:** six subsystem deep-reads of the actual source, each audited by a second pass that re-verified claimed formulas against the cited files (25 claims checked, 7 minor corrections, 0 unverifiable).

---

## The headline

EGM is architecturally **exactly what our Simulation Spec describes**, proven shipped: a fully deterministic, seeded tick simulation (0.1s ticks) that runs to completion in one synchronous call, producing a result object (outcome, duration, seed, typed event log, per-tick snapshots, per-combatant aggregates) — and the player only ever watches a **replay of that result** with scrub/step/0.5–4× speed. The stored seed makes every fight reproducible, which is precisely the property our Phase 2 leaderboard re-simulation requires.

Where it differs from us: EGM simulates real 2D space (positions, kiting, AoE shapes) at heavy tuning cost, has **no timer, no healer role, no party-level tactics, and no online features**. Our dungeon timer, role-based party model, tactics points + affix counterplay, and leaderboard are genuinely novel relative to the reference — they cannot be cribbed, so they are where our design/tuning budget must go.

---

## System findings (exact values from source)

### Combat engine
- 0.1s fixed ticks; one seeded RNG drives every roll; sim runs headless and instantly (`CombatSimulation.gd`, `MissionRunner.gd:154-166`).
- **Damage pipeline** is one static resolver with a strict ~12-stage mitigation order; every `DAMAGE_DEALT` event carries a per-stage `mitigation_breakdown` (snapshot-diff per stage) so every UI surface is a pure read of the log.
- **No miss roll.** Defenders roll evasion **twice**: both succeed = full evade, exactly one = *glancing blow* at 50% damage. Same expected damage as a single roll, much lower variance, and a third log-friendly outcome. Crit: 5% base, 1.5×, rolled before evasion; crits auto-apply ailment riders.
- **Armour is ratio-based:** reduction = (armour/hit) / (armour/hit + 10), cap 90% — big hits punch through, chip damage is absorbed. Ailment magnitude uses the same shape: 20% max × ((hit/max_life)/0.1)^0.4, discard below 5%.
- **No healer role exists.** All sustain is attacker-side (leech, gain-on-hit, regen, one-shot Second Wind), and every heal burns a persistent "vitality" meta-resource (0.5 per 1 life) that carries across encounters — attrition is run-level, not per-fight.
- Exiles never die mid-combat: they go DOWNED (monsters go DEAD). Death is decided post-mission by the defeat system.
- **Anti-stall is layered:** a stall detector (≥8s in, ≥10s with zero damage → forced retreat decision) plus 60s "overtime" that stacks a Desperation buff/drain every 5s (+5% damage dealt, 0.5 vitality/s drain per stack) to force resolution.
- Abilities are pure data resources (shape, range, cooldown 1.5–20s, wind-up, recovery, damage_scaling 1.2–3.0×) run by one generic TELEGRAPH → EXECUTE → RECOVERY state machine; basic attack is the auto-appended fallback in priority-ordered action slots.
- Monster scaling is linear: **+10% HP, +5% damage, +10% XP per level above base** — damage deliberately at half the HP rate, so harder fights get longer before they get lethal.

### Roster, stats, potentials
- **Zero stat rolls at generation.** Recruits are deterministic from class (11 classes in 4 rarity tiers, 70/20/8/2); all variance comes from traits and potentials. Validates our ilvl-derived character model.
- Leveling: XP = 100 × 1.5^(level−1); each level = full heal + deterministic class growth + **one drafted choice: pick 1 of 3 weighted-random passives** (rarity 86.5/10/3/0.5, notables ×0.3, keystones ×0.1). Picks persist in a respec-able decision path.
- **Potentials (answers our open question):** per-character tag → weight multipliers, baseline 1.0, sources additive, clamp 0–5. Tags are the *same taxonomy passives carry*, so content stays in sync automatically. Three source layers: 3 random tags (+0.5–0.9 / +0.8–1.4 / +1.1–1.9), class (e.g. Warrior: warrior +2.5, physical +1.5), traits (negatives allowed). **Only effect:** multiplies the appearance weight of matching passives in every level-up draft — never touches raw stats.
- **Hidden-but-active:** generation reveals 50% of potentials (min 1); each level-up has a 50% chance to reveal one more. Hidden entries still apply full weight. Recruit cards collapse them to "+N Unknown". This is the implemented version of our "unknown slots are the hook."
- Classes carry **morale-conditional bonuses** (e.g. Duelist +20% attack speed at ≥95% morale but −40% at ≤35%; a "Twisted" archetype that gets +50% damage at low morale) — morale as a class-flavored axis, not just a global multiplier.

### Morale, traits, defeat
- Morale 0–100 (max_morale is itself a stat = volatility knob), 3-band step: **≥90% = +10% damage/−10% taken/+10% XP; ≤25% = exact inverse; ≤0 = broken.**
- Exact events: mission win +1 (+bonuses); **boredom −(level_diff−1), cap −5, when running content 2+ levels below the character**; **thrilling victory +3 when damage taken ≥80% of max life**; retreat −5 chosen / −15 forced; stacking hunger −3 × consecutive unfed days; boss kill +5 (only if at-level); brutal-hit in-combat morale damage up to −20.
- Morale is **buildable**: morale_gain %, morale_loss_resistance % (cap 90), victory bonus, rest bonus — fed by traits and passives. Morale is a roster-building axis, not just a meter.
- **Guild departure shipped fully implemented but DISABLED** behind one constant (`MORALE_BROKEN_LEAVE_ENABLED = false`). The whole broken-morale ramp ((turns_at_zero − 1) × 5%/turn, cap 95%, one grace turn), a warning signal, and an "unbreakable" opt-out are all coded and test-covered — gated off for release. This is a cleaner pattern than our hard morale floor: let morale reach 0, ship the broken state + warnings + UI in Phase 1, and have Phase 2 flip the flag.
- **Traits** come in three categories: BACKGROUND (rolled 1–3 at recruitment, count 80/15/5, rarity 60/25/12/3 incl. a Legendary tier), LEARNED (auto-granted at levels 10 & 20 from a class-filtered pool), SCAR (assigned by defeat). 28 shipped. Classes hard-exclude nonsense combos via `incompatible_trait_ids`.
- **Defeat = scar-count permadeath, then a weighted outcome.** Death rolls from scar count *only*: `DEATH_CHANCE_PER_SCAR = {0:0%, 1:3%, 2:8%, 3:15%, 4:35%, 5:60%}` (>5 = 60%). **A scar-free character can never die** — first defeats always produce consequences instead. If survived, a context-filtered weighted outcome fires: Recovered (w50, −15% vit/−10 morale/1 day), Battered (w40, −40% vit/3 days), Scarred (w20, **assigns a scar trait**), Gear Damaged (w5), Captured (w10, total-wipe only). Death refunds all equipped gear to the holding bag.
- **Capture → rescue → long-lost pipeline** (the biggest mechanic EGM has that our GDD never mentions): a total wipe can capture a character → a time-limited, level-scaled "Rescue \<name\>" mission auto-spawns → ignored, it becomes `long_lost` with gear stripped → 7 days later scouting can resurface a 2-day second-chance rescue → rescued at 20% life/vitality, 60% morale. Failure becomes urgent bespoke content instead of a stat-loss screen.

### Missions / dungeon runs
- A mission is a **linear list of 1–5 combat-encounter slots** (`MissionData.tres`), run one at a time by an autoload `MissionManager` + per-run `MissionRunner` that owns a "holding bag" of loot/XP/currency. **No run timer.**
- Each slot is a hand-authored encounter or a **random pick** from a registry filtered by area + required/excluded tags + `recommended_level ≤ mission.level`, weighted by `selection_weight` (2.0 rare horde → 15.0 common pack). Boss encounters are excluded from random pools.
- **Difficulty is one integer** (`mission.level`) with linear up-only monster scaling (same +10% HP / +5% damage / +10% XP). **Zero affixes/modifiers** — `rarity_bonus`/`quantity_bonus` carry the "harder = juicier" promise instead.
- **The killer mechanic — between-encounter intermission:** after every encounter the player sees party state + banked loot and chooses **Continue** vs two-step-confirmed **Retreat**. Retreat banks everything at partial credit; **a wipe destroys 100% of loot found that run.**
- **Partial completion pays proportionally:** `completion_percent = cleared/total` multiplies scouting, currency (`round(amount×pct)`), and bonus item rolls; guaranteed showcase items require exactly 100%.
- **Party: 1–5, zero composition requirements** — any idle, alive exiles; solo allowed. Comp matters only emergently, never via hard gates.
- Missions cost **no calendar time** — the day advances only from "End Day"; the `TURNS_PER_DAY = 10` turn system is fully coded but never called (dead code). Pacing comes from HP/vitality attrition written back after each encounter.
- Availability: ALWAYS (farmable) / STANDARD (one-shot story) / DISCOVERABLE (scouting-% gated) / OPPORTUNITY (daily roll, 2–4 day cooldowns, 3–4 day timeouts, rare 0.05 jackpots). Failure cascades into content via the rescue pipeline above.

### Items & economy
- A compact, faithful PoE system: **~37 `ItemBase` resources**, up to **2 prefixes + 2 suffixes** from a pool of ~100 `AffixBase` resources, tier-tabled at item levels **1/3/5/8**.
- **Rarity is derived from affix count** (0 = Common, 1–2 = Uncommon, 3–4 = Rare), never rolled separately; crafting auto-upgrades rarity as affixes are added. Drop-time affix-count weights 50/20/15/10/5; mission rarity bonus only **shrinks the zero-affix weight** (harder = removes the junk floor, doesn't raise the ceiling).
- **Crafting = exactly 3 operations, full odds shown before committing:** Exalt (add affix, cost `1 × item_level`), Chaos (targeted replace, `1 × item_level`), Vaal (flat 1 orb, four 25% outcomes, then the item is permanently locked).
- Currencies: chaos/food/scrap/exalt + physical Vaal orbs. Faucets: fractional per-monster drops (`floor + Bernoulli(frac)`) + global "natural" rolls per item dropped (exalt 1/20, chaos 1/35, vaal 1/50). **Salvage is quality-sensitive:** `chaos = max(1, affix_tier_sum / 4)` — junk rares are the crafting faucet, white items yield nothing.
- **No vendor anywhere** — the "Quartermaster" is a food-ration system (0/1/2 food → vitality regen + rest morale). 10-slot paper doll; **spatial Tetris inventory** (stash 4 tabs × 12×8) forced heavy edge-case code (equip-no-space, displaced-item planning).
- Total data budget: ~100 affix definitions + 4 tiers ships a satisfying crafting game — reassurance that our 10–12 templates/dungeon + 4 secondaries is comfortably in range.

### Meta-loop, tactics, recruitment
- **Persistent campaign with a day counter**, not run-after-run: MainMenu → start recruitment (pick 1 of 2 "rafts" of 2 free level-1 exiles) → Guild hub (13 seats: 5 core + 8 bench) → mission board (pick mission + ≤5 party) → combat playback → report → hub. The day advances only on **End Day** (animated before/after `EndOfDayReport` + autosave).
- **Tactics are per-character combat-AI overrides** (`TacticsWindow`), stored as a nullable diff against weapon-inferred defaults (unset = inherit). Controls: **Target Lock** (Let Them Decide / Off 0.2s / Short 1.0s / Long 2.5s sticky), **Kite Profile** (5 value-bundles, not free sliders), **Fallback picker** (9 options), and an **ordered TargetRule list** (Filter × Picker, first match fires). **There is no party-level tactics layer at all — no aggression dial, no point allocation.**
- **Recruitment = 3 event sources through one minimizable modal queue:** `passing_boat` (every 6–12 days, 2–3 **paid** candidates at level `[ceil(max_level×0.6), max_level]`), `mission_recruit` (free, from RECRUIT-tagged missions, +0.3 quality bonus), `wandering_exile` (free pity recruit when the living roster hits 0). Cost `= (10 + class_rarity + Σ trait_rarities) × level_multiplier × (1 ± 0.2)`. `quality_bonus` shifts Common-tier weight onto higher tiers (the "access higher-potential recruits" lever). Game-start uses a **pity floor**: reroll until each raft has ≥1 Uncommon+ class and ≥1 Uncommon+ trait.
- **Save** = single-file serialized Godot resources + integer version + stepwise migrator (needed 4 migrations during beta — couples saves to class layout). **Online: none** — no leaderboard, accounts, or telemetry; the entire "web platform" layer is pause-on-focus-loss + right-click suppression. Cut systems are kept behind flags or as dead code rather than half-wired.

---

## GDD implications — what to steal, what we own

**Steal (proven, in-genre, mostly cheap):**
- **Sim/replay container + per-event `mitigation_breakdown`** — the architecture our Simulation Spec, parse overlay, death report, and Phase-2 re-simulation all need.
- **Potentials = tag-weight draft bias, hidden-but-active** — fills our biggest open question. *Coupling to resolve:* Potentials need a random draft to bias, and our talents are fixed/freely-swappable — so adopting this means biasing the earned-trait pools or adding a talent-draft layer, not a free drop-in.
- **Double-roll evasion with a glancing tier** — upgrades our Hit Quality (same average, lower variance, an extra frequent log event; relevant to the Safe-vs-Yolo dial).
- **Ratio-based armour** ("big hits punch through") — could power Tyrannical boss-hit feel vs our flat tank ×0.6.
- **Departure behind a feature flag** instead of a hard floor; plus a **high-morale reward band**, a **boredom penalty** (anti-farm, pushes the key ladder), a **thrilling-victory bonus** (makes Yolo emotionally profitable), and ≥1 character-side morale stat hook.
- **Capture → rescue** analog and a **scar-count death ramp** as overlays on our earned-trait system.
- **Economy one-liners:** tier = derived stat count; crafting/reroll cost = f(item level); salvage yield ∝ stat count × tier; transparent odds at the bench.
- **Run loop:** an "abandon run" decision point between stages with loot-at-risk; linear partial-credit loot for depleted keys.
- **Sim hygiene:** sticky-target hysteresis as an internal constant (0.2/1.0/2.5s working range) to stop target-thrash; a Desperation-style soft-enrage so a pull can't stalemate.
- **Recruitment:** peg candidate level to a margin below your best character; a pity floor on the Initial Draft so a first roster can't be all-gray.
- **Architecture:** plain-JSON save snapshots (not serialized engine resources — easier server-side leaderboard validation); mandatory pause-on-blur for web playback; feature-flag cut systems.

**We own (no EGM reference to crib — this is where design/tuning budget goes):**
- **Party-level Tactics** — 6 points across 4 categories + the Aggression dial + the affix↔tactics counterplay matrix. EGM has none of this; it is our clearest differentiator.
- **The Dungeon Timer + key ladder** — timed/depleted keystone treadmill with weekly affixes. EGM has no run timer and a finite level 1–10 mission list.
- **Role-modeled sim** — tank threat/mitigation and healer mana/OOM. EGM has no healer role and no death mid-combat (sustain is an attacker-side vitality budget).

**Applied to the GDD in v1.8:** Potentials (fully designed, closes the open question), Hit Quality → double-roll-with-glancing, morale high-band + boredom + thrilling-victory + feature-flagged departure, ratio-based tank armour, soft-enrage + RunResult container + sticky-target hysteresis in the sim, Shard salvage/craft-cost rules + transparent odds, partial-credit loot, and the mid-run "Calling the Run" decision.

**Applied in v1.9:** buildable morale (gain / loss-resistance hooks) + morale-conditional spec bonuses, tier = derived stat count, draft pity floor, recruit level-pegging, Legendary corruption sink (Vaal-orb model), fractional currency faucet, JSON persistence, and feature-flagged cut systems as a build principle.

**Evaluated and deferred** (noted in GDD Open Questions): capture→rescue and the scar-count death ramp.

**Not applied:** pause-on-blur (Godot-web-specific; dropped — the project won't necessarily be a Godot web build).

---

*Companion to GDD Concept v1.7. Full decompiled source at `Extract/recovered/`; analysis basis: GDRE Tools v2.5.0-beta.5, six-subsystem multi-agent read with per-area formula audits (25 claims checked, 7 minor data corrections, 0 architectural changes). Reference only — no code or assets from the recovered project may be copied into GOAT Lite.*