# GOAT Lite — Remaining Cluster Plan (Phases G / H / I + Affix Swap)

**Status:** Draft for review (2026-06-20). Author: Producer (Claude) with Umut.
Captures the rest of the 7-request planning pass. Phase F ("Endgame & Identity") has its own spec
(`Operator-Skills-Design.md`); this doc covers everything else:

| Cluster | Requests | What it is |
|---|---|---|
| **G — Visual pass** | #4 icons, #5 squared corners | radius token + WCL-sharp corners, wire existing icons, asset manifest |
| **H — Combat depth** | #7 major cooldowns, + finish talents | one ~60s signature per spec; complete talent nodes 3–5 |
| **I — 2D replay** | #2 | "abstract packs" replay (one backdrop, packs in sequence, scrubber) |
| **Affix swap** | (earlier) | apply the "Ship It Anyway" original-affix season; scrub WoW trademarks |

**Recommended order:** Affix swap (quick IP win, anytime) → **G** (fast, visible; its radius-token + icon-registry feed Phase F's recruit UI) → **H** → **I** (heaviest; needs dungeon backdrops from G's manifest). Forks I defaulted are flagged ⚙️ — flip any.

---

## Cluster G — Visual pass (#4 icons + #5 squared corners)

### Current state (verified)
- **Border-radius is scattered across ~30 spots in THREE systems** with no shared token: inline JS `borderRadius` (logs pages, 6–24px), Tailwind `rounded-[Xpx]` (kit/TopBar, 3–5px), raw CSS (`logs.css`: `.panel`10 `.btn`7 `.tile`9 `.role-pill`20 …). Missing one spot = visible asymmetry.
- **39 icon assets exist; 18 are already UNUSED** — `role-{tank,healer,dps}` (3), all 10 `spec-*`, all 5 `stat-*`, all 4 `tac-*`. So a big chunk of "text → icons" is *wiring*, not art.
- Two `<Icon>` renderers already exist (game `kit.tsx:7`, logs `components.tsx:7`) — mask + `currentColor` from `/icons/{name}.svg`.
- Text-label seams to convert: class/spec chips, role pills, talents, gear (rarity-colored text), dungeon short-codes, traits.
- Class colors mapped (`game.ts:117 CLASS_COLOR`), rarity colors mapped (`RARITY_HEX`).
- The retired parchment screens (`web/src/screens/`) are out of scope — only the live **logs** app gets the pass.

### Decisions
- **G-1 ⚙️ Corner severity:** centralize into ONE token (`--radius`, default ~**2px** to match WCL's near-sharp look), replace all ~30 sites. (Alt: 0px fully-sharp.) Makes the whole look one-line tunable.
- **G-2 ⚙️ Icon density:** **icon + short text** in roomy spots, **icon-only + tooltip** in dense tables. (Alt: icon-only everywhere — riskier for readability/accessibility.) Every icon gets an `aria-label`.
- **G-3 Icon registry:** one typed `<Icon kind="spec|role|stat|tac|affix|class|talent|trait|item|dungeon" id=…/>` with a graceful **missing-asset placeholder** (today the renderer shows nothing on failure). Adding your art later = drop a file + map entry.

### Tickets
- **G.1** Radius token: add `--radius` (+ a Tailwind theme value); replace the ~30 scattered values. Pure refactor; visual diff only.
- **G.2** Icon registry + placeholder fallback + `aria-label` convention.
- **G.3** Wire the 18 existing icons: spec/role icons into roster/recruit/setup/character; stat icons into the (future) secondary-stat displays; tactic icons into the New-Run tactics dials.
- **G.4** New-art seams (needs your assets — see manifest): dungeon banners, talent icons, trait icons, ability/spell icons, item/rarity icons, the 3 operator-skill icons, the 8 redesigned affix icons.

### 🎨 Asset manifest (what to produce; convention `public/icons/{prefix}-{id}.svg`, ~64px square master, monochrome-friendly for tinting)
| Prefix | Count | Notes |
|---|---|---|
| `spec-*` | 10 ✅ exist | already in repo, just unused |
| `role-*`, `stat-*`, `tac-*` | 12 ✅ exist | already in repo, unused |
| `affix-*` | 8 → **re-cut** | rename to the new ids (microservice-sprawl, load-bearing-legacy, tech-debt-interest, bolt-on-dependency, flaky-test, heisenbug, page-the-junior, merge-conflict) |
| `skill-*` (operator) | **3 new** | execution, awareness, composure (Phase F) |
| `class-*` | 5 new (opt.) | warrior/paladin/rogue/mage/sage glyphs (or reuse spec icons) |
| `abil-*` (spells) | ~**70 new** | 60 existing abilities + 10 new majors; biggest art lift |
| `talent-*` | ~15–30 new | per talent option (MVP: the live nodes first) |
| `trait-*` | ~28 new (or per-archetype ~5) | recommend per-archetype to cut count |
| `item-*` | ~12 now → ~70 | or use rarity-bordered slot glyphs instead of per-item art |
| `dungeon-*` | 1 now → 6 | a **wide banner** + a small glyph per dungeon (none exist today) |

### Open numbers
- Exact `--radius` (0 vs 2px). • Per-archetype vs per-trait icons. • Per-item art vs rarity-bordered slot glyphs.

---

## Cluster H — Combat depth (#7 major cooldowns + finish talents)

### Current state (verified)
- 10 specs = 1 passive + 5 actives each. **Longest existing cooldown is ~8s** (Meteor); everything else is short rotational. **No spec has a big "signature" button.**
- Engine: `selectAbility` fires **longest-CD-ready first** (`combat.ts:739`), cooldowns tracked as ready-at seconds (`secondsPerTurn=1`), a `SPECIALS` map (`combat.ts:508`) handles custom mechanics. Trash packs last ~20–30s; soft-enrage at 90s.
- **Talent nodes 3–5 are prose-only placeholders** (no machine-readable `effects`); only nodes 1–2 are live (B.7).

### Decisions
- **H-1 ⚙️ Design philosophy:** **role-templated mechanics + unique flavor** — tanks get a defensive/party-save wall, healers a raid-save, DPS a burst window; each spec dresses it differently. (Alt: fully-unique-per-spec = max flavor, max balance work.)
- **H-2 Cooldown length:** **~60s** (`cooldownTurns: 60`). 180s would essentially never fire given pull length; 60s lands roughly once per boss / big pack.
- **H-3 ⚙️ Power budget:** majors **add net power**, then a balance pass nudges baseline (Alt: cost-neutral — lower baseline to compensate). Net-power makes them *feel* like a cooldown.
- **H-4 Gating:** mostly **free-fire** (the bot "plays well"); boss-biased via `onlyIf` only where it's clearly a save-it-for-the-boss tool. Tag all 10 `tags:["major"]` for UI prominence + the future replay.

### The 10 majors (concepts — exact numbers at implementation; QA-flavored names, no kit dupes)
| Spec | Role | Major (working name) | Type | Effect sketch |
|---|---|---|---|---|
| **Guardian** | Tank | **Code Freeze** | party defensive | party −35% damage taken, 8s |
| **Crusader** | Tank | **Rollback Plan** | party absorb | large absorb shield on all 5, 8s/until spent |
| **Mystic** | Tank | **Zen Mode** | self-sustain | parry/avoid most incoming + self-heal, 8s |
| **Cleric** | Healer | **Hotfix Deploy** | raid-save | instant big party heal + short absorb |
| **Lifebinder** | Healer | **Gradual Rollout** | raid-save | strong party HoT bloom, 8s channel |
| **Berserker** | DPS | **Crunch Time** | burst | +output/+crit window, 8s (slight self-cost) |
| **Assassin** | DPS | **Ship It** | execute burst | massive focus-target burst, guaranteed crits |
| **Bard** | DPS | **Standup Hype** | raid haste | party +haste/+output, 8s (the "lust") |
| **Pyromancer** | DPS | **Prod Incident** | AoE nuke | huge AoE, consumes/ignores Burn stacks |
| **Arcanist** | DPS | **Root-Cause Analysis** | burst + control | +damage window + mass slow/silence |

### Tickets
- **H.1** Author 10 majors in `data/abilities-player.json` (`tags:["major"]`, ~60s). Most reuse existing effect types/SPECIALS; add a handler only where a concept needs one.
- **H.2** UI: surface the major in the Character sheet + replay/log as a prominent event.
- **H.3** Finish **talent nodes 3–5** (machine-readable `effects` + `onlyIf`) — closes C.2's MVP gap.
- **H.4** Balance pass: retune baseline vs major windows; smoke sweeps keep the timer curve.

### Open numbers
- Per-major magnitudes/durations. • Exact baseline nerf (if any) after net-power. • Which (if any) majors are boss-gated.

---

## Cluster I — 2D replay (#2, "abstract packs")

### Current state (verified)
- `RunResult` = **text log + per-tick HP/damage series + deaths**. **No positions, no per-mob IDs, no stage/pack/spawn events.** `stageIdx` is a local var, never emitted; mobs spawn into an anonymous array (`engine.ts:97`).
- Front/back **bands exist but are static** (`Combatant.position`, `Enemy.band`) — targeting uses them; nothing moves.
- Stage timeline is reconstructed **post-hoc** by weight interpolation (`analytics.ts:98 buildFights`), not emitted by the engine.
- Sim is **deterministic** → a replay is fully reconstructable once the engine emits the structure.

### What "abstract packs" is (the agreed target)
One fixed dungeon **backdrop**; your 5 bots as portrait orbs on one side (HP bar + buff/CD pips); enemies as a **pack** of tokens on the other, split into **two rows = front/back bands**. The run plays **stage-by-stage in sequence** — pack 1 appears, health bars drain, status pips pop, floating combat text + mechanic/affix flashes, mobs die → pack 2 slides in → … → boss. A bottom **scrubber synced to the log** (drag to any second; play/pause/1–4×). No x/y arena, no movement — positioning stays abstracted to rows + tactics dials, honest to the sim.

### Decisions
- **I-1** Engine emits a new **`ReplayTimeline`** on `RunResult`: stage-enter / pack-enter / boss-enter events, and **per-mob spawn + death + HP-sample** with **stable seed-derived mob IDs**. Additive — no balance impact, transient (not saved; recomputed from the deterministic ticket).
- **I-2 ⚙️ Renderer:** **SVG/DOM** tokens (small token count, styleable, accessible, reuses the icon registry). (Alt: canvas — only if perf ever demands.)
- **I-3** Reuse the existing per-tick HP/damage series for bars; reuse `LogLine.meta` for floating text; map bands → two rows.
- **I-4** Needs **dungeon backdrop art** (see G manifest) — one per dungeon.

### Tickets
- **I.1** Engine: lift `stageIdx` to emitted events; assign stable mob IDs; build `ReplayTimeline`. Verify determinism in `egm-smoke`.
- **I.2** Replay canvas component (SVG): backdrop, party orbs, pack rows, HP bars, status pips, floating text.
- **I.3** Scrubber + transport synced to the existing log clock; a "Replay" tab on ReportPage next to the text log.
- **I.4** Polish: death anim, mechanic/affix flashes, speed dial.

### Open numbers
- Per-mob token vs single pack-cluster bar at high mob counts. • HP-sample rate for replay (vs the existing series). • Backdrop art style.

---

## Affix swap — apply "Ship It Anyway" (IP hygiene quick win)

The original-affix season is **already designed** (8 affixes, see the earlier redesign output / chat). This is just the apply step. **Key fact:** affixes are matched by **hardcoded id literals** (`aff.has("bursting")`, ~9 sites in `engine.ts` + the death-cause string), and those ids persist into saves — so renaming *display names alone does NOT scrub the WoW trademark* (a pre-launch IP blocker). The swap must rename the **ids**.

### Ticket — Affix.1
- `data/affixes.json`: replace the 8 entries (new ids/names/effects, icons `affix-<newid>`).
- `engine.ts`: rename the ~9 `aff.has(...)` id literals + the death-cause label; fix the stale `spiteful.punishes:"behavior"` → `killorder` data bug.
- Theme the 4 tactic **dial display names** (Interrupts→Code Review, Positioning→Test Coverage, Cooldowns→Incident Response, Killorder→Triage Order) — display only, engine ids unchanged.
- Optional: add **Merge Conflict** (the one new affix, ~14 lines, time-windowed `revertMultUntil` field) — the only affix that makes the interrupts/Code-Review dial matter on trash. Cut it to stay 100% reskin.
- New affix icons (G manifest). Verify: `tsc -b` + `egm-smoke` (all weights time the +2 floor).

---

## Sequencing & dependency summary

```
Affix.1 ─ (anytime; isolated; IP win)
Phase F ── F.1 data ─ F.2 sim ─ F.3 growth/cap ─ F.4 recruit-gen ─┬─ F.5 UI ── F.6 balance
Phase G ── G.1 radius ─ G.2 registry ─ G.3 wire-icons ───────────┘  (G feeds F.5's recruit list/detail)
            └ G.4 new-art (gated on your assets)
Phase H ── H.1 majors ─ H.2 UI ─ H.3 talents 3–5 ─ H.4 balance     (after G)
Phase I ── I.1 engine-emit ─ I.2 canvas ─ I.3 scrubber ─ I.4 polish (last; needs G dungeon backdrops)
```

- **G overlaps F:** do G.1–G.3 early so Phase F's recruit list/detail panel is built in the final squared + icon style (avoids reskinning it twice).
- **I depends on G** for dungeon backdrops, and reuses the icon registry.
- **Affix.1** is independent — a good warm-up / low-risk first commit.
- Save: `SAVE_VERSION` bumps at F.1 (4→5); G/H/I are additive (no further bump unless H stores major state).

---

## Cluster J — Feedback & polish batch (user-reported 2026-06-20, post Phase-F build)

> **✅ ALL 10 SHIPPED & live-verified (2026-06-20).** See the Phase J table + changelog in `ROADMAP.md` for the
> as-built notes per ticket. The per-ticket "Today/Fix" detail below is the original investigation, kept for the record.

Ten issues Umut raised after playing the operator-skills build. Each was **investigated and grounded in code** (9-agent fan-out recon). Mix of real bugs, small features, a polish pass, and one cross-cutting tooltip feature. Most are isolated and low-risk; recommended order is the cheap bug-fixes first.

| # | Item | Type | Effort | Main files |
|---|---|---|---|---|
| J.1 | Guild create: drop faction + realm pickers | feature | S | `GuildCreatePage.tsx`, `game-store` GuildInfo, 3 consumers |
| J.2 | Replay: stop at the wipe (don't play to the end) | bug | S | `ReportPage.tsx` playback loop |
| J.3 | Replay: speed dial doesn't change perceived log cadence | bug/UX | S–M | `ReportPage.tsx` clock + EventLog reveal |
| J.4 | Combat log: enemy attacker name not shown | bug | S | `engine.ts` emit + `ReportPage.tsx` renderer |
| J.5 | Healing meter never moves (not wired to real heals) | bug | M | `engine.ts`/`combat.ts`/`types.ts` + `analytics.ts` |
| J.6 | Loot: green ↑ for **every** upgrade + show current item | feature | M | `game-store` `computeLoot`/`LootDrop` + `LootPage.tsx` |
| J.7 | "Assassin seems problematic" | balance/design | M | `abilities-player.json`, `combat.ts` — **needs a call (see below)** |
| J.8 | Remove the glowy effects | polish | M | `logs.css` + inline `boxShadow`/`textShadow` across `logs/` |
| J.9 | Report header: Battle-Res count + timer instead of Rating | feature | S | `types.ts`/`engine.ts` (emit rez) + `ReportPage.tsx` |
| J.10 | Tooltips for everything (icons, log spells, affixes, items) | feature | M | reusable Radix tooltip; many seams |

### J.1 — Remove Horde/Alliance + realm from guild creation  *(feature, S)*
- **Today:** `GuildCreatePage.tsx` has `FACTIONS`/`REGIONS` consts + state, a Faction panel + Realm panel, and threads `faction`/`region` into `createGuild()`. `GuildInfo` (game-store) requires both. Consumers display them: `RosterPage.tsx:43` (region · faction), `ReportPage.tsx:39,100` (threads `region` through `buildReport`/`ReportView` in `analytics.ts:79,173,194`), `CharacterPage.tsx:42`.
- **Fix:** delete the two panels + their state + the preview faction dot/region line; drop `faction`/`region` from `GuildInfo` and the `createGuild` payload; drop the secondary "region · faction" lines from the 3 consumers and the `region` param from `buildReport`/`ReportView`. **No save migration needed** (extra persisted fields are simply ignored on load).

### J.2 — Stop the replay at the wipe  *(bug, S)*
- **Today:** the playback loop (`ReportPage.tsx:~52-63`) advances the clock to `result.durationSec` regardless of outcome; on a wipe you still watch dead air after the last death.
- **Fix:** compute `stopAtSec` before the loop = `outcome === "wipe" ? (last death tSec) : durationSec` (data already in `result.deaths` / `result.outcome`, `types.ts:39`); clamp the clock and `setPlaying(false)` when reached. Timed/depleted still play full.

### J.3 — Speed dial vs log reveal cadence  *(bug/UX, S–M)*  ⚙️ needs a one-line UX confirm
- **Finding:** the speed multiplier **is** applied to the clock (`c + RATE*speed*0.12`), so lines *should* appear faster at 4×. But there's **no per-line reveal animation** — lines pop in the instant their `tSec` is crossed and the panel auto-scrolls, so it reads as "instant" at every speed. Likely the rate constant is high enough that even 0.5× blows through, or the user wants a visible per-line stagger.
- **Fix options:** (a) lower the base `RATE` so 0.5× is genuinely slow; (b) add a speed-scaled per-line fade/stagger (`revealAt = tSec + index*40/speed`ms) so cadence is *visible*. **Confirm intent before coding** (just slow it down, vs. add a typewriter-style reveal).

### J.4 — Show the enemy attacker name in the log  *(bug, S)*
- **Today:** `engine.ts:~210` emits enemy-strike lines with `sourceName: m.name` but **no `sourceId`**. The renderer (`ReportPage.tsx:~339-350`) only renders a colored source prefix when `sourceId` resolves to a spec color (`lead && color`); with no `sourceId`, `color` is null and the source is dropped → "hits Dolgrun for 35 Physical".
- **Fix (preferred):** add `sourceId: m.id` to the emit, and in the renderer handle "id present but not a party spec" → render the enemy name in a neutral/hostile color (gray/red). (Alt: keep no id, special-case `sourceName && !color` to render gray.) Keeps determinism; cosmetic only.

### J.5 — Wire the healing meter to real heals  *(bug, M)*
- **Today:** the engine emits **no heal series** — `analytics.ts:149-167` fabricates a deterministic `healingTable()` seeded by member id, so the "Healing" meter shows static nonsense that never tracks the run. (Damage meter works because it slices the real `result.series`.) The Meter UI + `metric:"hps"` switch are already correct — the gap is **purely data**.
- **Fix:** add a `healSeries` to the engine parallel to `series` (snapshot `Math.round(p.healDone)` per member per second — `healDone` is already tracked on `Combatant` via `healInto`), expose it on `RunResult` (`types.ts`), and add a `healingWindow()` in `analytics.ts` that slices it (mirror of the damage window). Additive + deterministic (no balance impact). Watch: cumulative across stages, count net heal not overheal (already the case in `healInto`).

### J.6 — Loot: per-character upgrade arrows + current item  *(feature, M)*
- **Today:** `computeLoot` (`game-store.tsx:~279-301`) records only the **single best** `upgradeFor`/`upgradeAmt`; `LootPage` shows one green ↑ and never shows the candidate's currently-equipped piece.
- **Fix:** change `LootDrop` to carry `upgradeMembers: {memberId, delta, currentIlvl}[]` (iterate all spec-compatible party members in `computeLoot`); in `LootPage`, show the green ↑ on every member with `delta>0` and a faint "currently ilvl N → N (+Δ)" line per candidate. Data already on hand (party + `gear[slot].ilvl`); not persisted, so no save break.

### J.7 — "Assassin seems problematic"  *(✅ RESOLVED & IMPLEMENTED 2026-06-20)*
- **Resolution (Umut):** it's *inconsistency*, not weakness → softened the backline gate to a bonus. Removed
  `targeting.band:"back"` from Poisoned Blade + Ambush (kept the `targetBand back → ×1.3` modifier) in
  `data/abilities-player.json`, so they now hit the focus/kill-order target like the rest of the kit and the dive is
  upside, not a forced redirect off-focus. Verified: tsc/content/op-verify/egm-smoke green; Ashveil aggregate output
  unchanged (no balance shock). Still the top DPS (705k/830s/0 deaths) — left as-is per the consistency-not-tuning ask.
- **⚠️ Measurement contradicts the "weak" assumption (kept for the record).** A head-to-head sweep (1T+1H+3× the spec, ilvl150 +8, `scripts/spec-parse.mjs`) shows the **assassin is the strongest single-target DPS**, not the weakest: avg DPS damage **705k** + fastest clear **830s** + **0 deaths**, vs berserker 671k/1034s/**5.2 deaths**, pyromancer 641k/1275s, arcanist 550k/1767s, bard 395k/1702s.
- **So "problematic" is most likely one of:** (a) **overtuned** (it out-DPSes and out-survives the field — a nerf), or (b) **situational inconsistency** — Poisoned Blade + Ambush are hard-gated to `band:"back"` (`abilities-player.json:772,850`), so on a pack with **no back-row** the assassin can't fire its core kit and idles on autoattacks (feels broken even though aggregate is high), or (c) a kit-depth gap the investigator flagged (no poison-detonate/-amplify analog to Ignite/Combustion) that makes its rotation feel flat. **Decision needed from Umut: which behavior did you see?** Likely fix per case — (a) trim Eviscerate/poison scaling; (b) soften the backline gate to a *bonus* (target freely, +30% only when a back-row exists); (c) add a `detonate-poison` special + a `poison-amplify` passive (new `combat.ts` handler). Don't tune until the intent is confirmed + a fresh measurement.

### J.8 — Remove the glow effects  *(polish, M)*
- **Today:** colored glow halos everywhere — CSS `box-shadow: 0 0 Npx rgba(accent…)` on `.brand-mark`/`.btn-primary`/`.radio-dot.on`/`.field:focus`, and ~12 inline `boxShadow: '0 0 Npx ${color}'` / `textShadow` glows across the pages (hero avatars, M+ score, key/level numbers, parse badges, talent radios, death markers, keystone reveal, crest preview).
- **Fix:** strip every `0 0 <blur> <color>` (pure glow) pattern; **keep** subtle depth (`inset 0 1px 0 rgba(255,255,255,…)`, `0 1px 0 rgba(0,0,0,…)`, panel drop-shadows). Optionally convert a few signal glows to a 1px low-opacity colored border. Purely visual. (Pairs naturally with G's squared-corner pass.)

### J.9 — Battle-Res count + timer on the report header  *(feature, S)*
- **Today:** the engine tracks `rezCharges`/`nextRezChargeAt` internally but **`RunResult` doesn't expose them** (`types.ts:37-53`); the report header shows the keystone `Rating`.
- **Fix:** emit `finalRezCharges` + `nextRezChargeAtSec` (= `nextRezChargeAt - t`) on `RunResult`; swap the header "Rating" tile for "Combat Rez" = `N charges · ready / regen m:ss` (reuse the existing `mmss()`). Self-contained, no save/data change.

### J.10 — Tooltips for everything  *(feature, M; cross-cutting)*
- **Today:** only browser-native `title` on `GameIcon`, plus a bespoke fixed-position skill tooltip in the **retired** `screens/CombatReplay`. `@radix-ui/react-tooltip` is in deps + a `warcraftcn/tooltip.tsx` wrapper exists but is **unused in `logs/`**.
- **Fix:** build one reusable `<Tip content>` (Radix) and decorate the seams: `GameIcon` (skill/role/spec/tactic/affix names + effects), affix chips (`SetupPage` — `affix.effect`/`punishes`), tactic dials (`tactic.perPoint`/`starved`), event-log abilities (log meta already carries `skillId` from A2 → look up `content.skills`), gear items (`CharacterPage`/`LootPage` — needs item metadata; gear carries `baseId`→`content.items`). Lowest-lift first: affixes + tactics + icons (text already in content), then log spells, then gear. Reuses G.2's `<GameIcon>`.

### Sequencing (Cluster J)
Cheap isolated bug-fixes first — **J.4 → J.1 → J.9 → J.2** (all S, no deps) — then **J.5 → J.6 → J.8** (M), then **J.10** (cross-cutting; pairs with G.2), and **J.7 last** (blocked on Umut's intent + a re-measure). J.5/J.9 add transient `RunResult` fields (additive, no save bump). None touch the deterministic balance except J.7.
