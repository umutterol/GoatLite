# GOAT Lite — Dungeon Design Proposals (Phase C content)

**Status:** design proposal (2026-06-21). Feeds roadmap **C.1 (Dungeons 2–6)**.
**Companions:** `ROADMAP.md`, `MMO-Nostalgia-Reference.md` (affix-rename table + voice), `Combat-AI-Design.md`, `DataModel.md`.

> Generated via a multi-agent design workflow that mapped the live engine, enumerated solve-axes, designed one
> dungeon per axis, and adversarially critiqued each for *real-solve / legible-failure / honest-buildability*.
> The honesty notes below are the load-bearing part — they keep us from authoring puzzles the engine can't honor.

---

## 1. Decision summary (locked)

Ship a **6-dungeon roster = Ashveil + 5 new**. Five are **pure data**; one (**The Pyreward Ossuary**) needs a
**small ~2-edit engine change** (per-enemy armour/resist) because it's the *only* dungeon that creates real comp pressure.

| # | Dungeon | Primary solve | Build cost |
|---|---|---|---|
| 1 | **Ashveil Crypts** *(shipped)* | all-four-dials sampler | — |
| 2 | **Bellreach Sanctum** | interrupts (commit a dial) | data |
| 3 | **Stillhour Abbey** | burst-triage healing (Cleric read) | data |
| 4 | **The Weltering Mire** | sustained-HoT healing (Lifebinder read) + kill-order | data |
| 5 | **The Hour of Bells** | cooldowns (boss-gauntlet) | data* |
| 6 | **The Pyreward Ossuary** ⭐ | damage **school** (Physical vs Magic) | **small engine change** |

\* Hour of Bells is data-only but is *designed around* the Tyrannical+Raging affixes, which are outside the current
MVP affix pool (Fortified+Bursting) — ship it post-MVP or give it a Fortified variant.

---

## 2. The engine reality — what a "solve" can mechanically be

> ### Design principle: bring the player, not the class
> The **tactic dials (player decisions) are the primary solve.** Class/spec-required solutions are a *minor secondary*
> factor: where a dungeon favors a spec, the gap must be **small — only ~1–2 key levels of ceiling at the very top**,
> and **invisible below it** (both options clear the floor and mid keys cleanly). A spec preference should let you push
> a little higher, never gate the content. The C.10 healer levers (burst→Cleric on Stillhour, rot→Lifebinder on the
> Mire) are tuned to exactly this: same outcome at low/mid keys, ~1–2 key ceiling difference when you're pushing.

**This section is the brief.** Everything else is downstream of it.

A dungeon's puzzle today is expressed almost entirely through the **four tactic dials**
(`interrupts / positioning / cooldowns / killorder`). Each is a **hard-coded ~12-second branch** in the combat loop,
keyed off a boss's `testsTactic`. Two consequences shape every design:

1. **Comp does not feed the dials.** They are manual sliders set on the pre-pull board. The only genuinely
   comp-derived lever in the sim is `hasPeel`, and **both** healers satisfy it for free. So *"bring an Arcanist to
   kick the cast"* is currently **fiction** — only dragging the Interrupts slider up beats an interrupt boss,
   regardless of who is in the party. (Making "bring a kicker" real is a **large** engine ticket: enemies don't
   actually cast, and the player `interrupt` effect is a no-op.)
2. **The damage-school axis (Physical vs Magic) is the one true comp lever** — and it's inert today. The pipeline
   already routes Physical→armour and Magic→resist (90% cap), but `makeEnemy` hard-codes `armour:0 / resist:0`, so
   damage school has **zero** effect. Un-hardcoding it is ~2 edits. This is the highest-leverage change available.

Further hard facts (from the adversarial pass — author to these, don't fight them):

- **The mechanic coefficients are constants, not data.** interrupts-cast ≈ `16·keyScale·DMG_UNIT` party-wide, catch
  chance `min(0.95, 0.2 + 0.25·interrupts)`; cooldowns-phase ≈ `14·keyScale·(1 − 0.12·cooldowns)` party-wide;
  positioning-ground ≈ `18·keyScale` to one random victim; the 12s cadence is fixed. **Two bosses with the same
  `testsTactic` are mechanically identical bar HP/damage + theme** until the *per-encounter weighting* gap is closed.
- **Boss `baseDamage` drives only the boss auto-attack (constant chip), NOT the toll/spike.** So cranking `baseDamage`
  to make a "louder spike" actually floods the calm with chip and *weakens* the spike identity. Tune spike lethality
  via key level / `keyScale`, keep `baseDamage` low for spike dungeons.
- **On boss stages, defensive majors fire on cooldown regardless of the Cooldowns dial** (`holdForWindow`). The dial's
  real boss-stage effects are only `−12%/pt` spike and `+4%/pt` boss DPS; its *defensive-timing* benefit applies on
  **trash** packs and to the **tank's** emergency threshold. Don't teach "Cooldowns pre-pops your raid-save on bosses."
- **There is no mana economy.** A struggling healer is never "OOM" — frame failure as *reactive heals arriving a tick
  late*, not running dry.
- **Affixes are hard-coded branches**; the `effect` strings in `affixes.json` are display-only. A *new* affix
  (e.g. "The Tolling") is a code branch, not data.
- **No enemy applies a status to the party**, so there is **nothing to dispel/cleanse**; and there is **no reach gate**,
  so "your melee can't touch the back line" can't be honored. Those axes are deliberately *not* faked into a dungeon.

---

## 3. The solve-axis menu (14 ideas, tagged by build cost)

These are the mechanical ideas a dungeon can be wrapped around. ✅ = pure data · 🔧 = small engine change ·
🚧 = larger engine work (currently un-honorable).

| Axis | The solve the player must find | Answered by | Cost |
|---|---|---|---|
| Interrupt commitment | "Cast not interrupted ×6" is a *budget* problem — pin the dial, stop hedging | Interrupts slider | ✅ |
| Cooldown discipline | Boss spike phases; the dial is 3-in-1 (−12% spike / +4% boss DPS / trash defensive-timing) | Cooldowns slider + defensive-major specs | ✅ |
| Positioning / floor-is-lava | Avoidable ground damage dominates; raise Positioning, drop aggression | Positioning slider + Safe aggression | ✅ |
| Kill-order / triage queue | Sequence casters & priority adds or Bursting/Bolstering snowball | Kill Order slider | ✅ |
| Sustained-HoT read | A flat tick on every squishy → all-ally HoTs cover them; single-target can't (soft, ~1–2 keys) | Lifebinder | 🔧→✅ C.10 rot |
| Burst-triage read | A single toll on the flagging one → instant top-ups + absorbs (a HoT can't; soft, ~1–2 keys) | Cleric (Mystic/Lifebinder partial) | 🔧→✅ C.10 burst |
| Anti-yolo aggression tax | Avoidable/Spiteful/Bursting intake scales ~2× with Yolo; dial down | Aggression posture | ✅ |
| Soft-enrage DPS race | Beat the 90s enrage by output or eat ramping damage | Output + Cooldowns | ✅ |
| Spiteful "weakest link" | Ghosts hunt your lowest-**power** member → don't field a passenger | Roster floor + any peel spec | ✅ |
| **Damage school (Phys/Magic)** | Boss eats one school → field mixed-school DPS (soft ~1–2 keys) | phys: zerk/sin/mystic/bard · magic: pyro/arcanist/cleric | 🔧→✅ C.8 |
| "The Tolling" affix | Second interrupt-stress layer (periodic catch-chance penalty) | Interrupts slider | 🔧 |
| Hard-CC lockdown | Deny fast-hitting mobs their swings via stun/freeze/silence | Mystic/Arcanist/Pyromancer | 🚧 *(verify wiring first)* |
| Dispel / cleanse pressure | Remove a stacking enemy debuff before it snowballs | Cleric / Bard | 🚧 *(no enemy applies statuses)* |
| Back-line reach | Shut down casters your melee can't reach | ranged/back specs | 🚧 *(no reach gate)* |

The chosen roster covers every ✅ axis plus the 🔧 damage-school flagship. The 🚧 axes are the menu for a future
engine-investment wave (see §6) — each one buys one more genuinely-distinct dungeon toward an eventual 8.

---

## 4. Recommended roster — full designs

> **Naming/voice:** earnest gothic dread for the world; the **satire lives in the QA-job wrapper** (the post-run
> report, Parse Goblin, the guild feed), never in the dungeon's own flavor. Match Ashveil's register.
> **Shape→tactic map:** `summon→killorder · cast→interrupts · ground→positioning · phase→cooldowns`.

### 4.0 Ashveil Crypts *(shipped — the baseline)*

The four-dial **sampler**: each of its four bosses audits a different tactic, so a naive even split survives. This is
the +2 floor that must reliably time at starting gear, and the teaching baseline every other dungeon's *monomania* is
felt against. No roster pressure by design — it teaches that the dials exist.

| Stage | Boss | Shape→Tactic | Audits |
|---|---|---|---|
| 2 | Sexton Caldew | summon→killorder | spacing deaths under Bursting |
| 4 | Embalmer Vesk | cast→interrupts | the Interrupts dial |
| 6 | The Unmourned | ground→positioning | the Positioning dial |
| 8 | Othrend, Last of the Interred Kings | phase→cooldowns | banking burst for the spike |

---

### 4.1 Bellreach Sanctum — *interrupts (dial-commitment)*

> *A drowned cathedral whose choir never stopped singing; the dead keep the liturgy because no one ever rang the bell
> to end the service.* **Signature:** relentless dangerous-cast density, Interrupts-punishing. **Difficulty:** the
> first "monomaniacal" step up from Ashveil. **Build:** pure data (The Tolling affix is a v2 upgrade).

**The puzzle.** Most bosses here fire the party-wide interrupt-tax every 12s. The player must read that the report line
*"Cast not interrupted ×6"* is **not a healer problem — it's a tactic-budget problem**, and **pin Interrupts to 3**
(the single highest-value point-spend in the game for this key). The trap is the habitual even-split: Bellreach has
almost no avoidable/add pressure, so every point *not* in Interrupts is wasted.

**Failure mode (the replay tells it).** The whole party flatlines in lockstep every 12 seconds — five bars dropping
together, not one squishy getting picked. The boss timeline reads `CAST LANDED` stamped six, eight, ten times. The
healer's output graph is maxed and still losing, because no throughput out-paces three casters left to free-cast. The
run dies to the same event it never once stopped. *(Parse Goblin blames the Cleric; the log says the dial was at 0.)*

**Comp answer (honest).** Today the **Interrupts slider is the only counter** — pin it to 3 and it's solved regardless
of roster. The fiction *wants* this to force the Arcanist (only ranged kicker) **and** the Mystic, but the pre-pull
board must prompt the **dial**, not a roster slot, or an attentive recruiter is silently punished. The Arcanist+Mystic
recruit-pressure becomes real the day the interrupt-as-capability gap closes (§6).

| Stage | Boss | Shape→Tactic | Mechanic (≈) | Flavor |
|---|---|---|---|---|
| 2 | Cantor Brivael | cast→interrupts | readable teacher cast; coefficient **lowered (~12)** so 2 points feels "close, not dead" | "Sing it back to me. The dead remember every verse." |
| 4 | The Drowned Choir | cast→interrupts | same tax, faster fiction; "too many throats for one kicker" | "Quiet one and another takes the breath." |
| 6 | Verger Mottram | phase→cooldowns | the **one breather** — rewards the points you banked into Cooldowns | "Spend yourselves before it strikes again." |
| 8 | The Unrung Bell | cast→interrupts | capstone wall; one uninterrupted peal into soft-enrage ends the run | "No one ever rang me. So the service never ends." |

**Fixes folded in:** one boss per stage (the engine can't do simultaneous casters); **stagger coefficients 12/16/20**
to soften the binary cliff. Tactic budget is **6 total / max 3 per dial** (`tuning.tacticsPoints`, confirmed), so
*pin Interrupts to 3 AND bank 3 into Cooldowns* is exactly affordable — the intended spend. **Reward hook:** interrupt/utility-flavored gear that sets up the
cooldown-heavy Hour of Bells. **The Tolling** (v2 affix): periodic penalty to interrupt catch-chance — a second stress
layer on the same dial (hard-coded branch).

**Build status (2026-06-21): authored + verified (mechanics-first).** Pure data (`dungeons`/`enemies`/`abilities`/
`packs`/`season`), placeholder loot reuses Ashveil items, plus probe `web/scripts/bellreach-live.mjs`. Verified: content
validates, `tsc -b` clean, Ashveil run unaffected, **+2 floor times**, and the Interrupts dial controls the mechanic
(Interrupts-3 → **0** casts through; Interrupts-0 → **~19–26** casts through; Yolo widens the gap). **Honest limit:** at
gear-appropriate ilvl the read is *log-visible* (casts-through + a duration delta) but does **not** flip timed↔wipe —
the per-cast tax is too soft at the floor, and high-key wipes (+12/+16) come from general scaling + Bursting/kill-order
(they hit before the interrupt bosses), not the interrupt content. Sharpening it into a real win/lose wall needs a
**global cast-coefficient tune** (also affects Ashveil's Vesk) or the **per-encounter-weighting** engine gap — a balance
follow-up, not a data fix.

---

### 4.2 Stillhour Abbey — *burst-triage healing (the Cleric read)*

> *A drowned monastery where the bells still toll the hours; between each toll the air is dead-calm, and on the hour
> the silence breaks all at once.* **Signature:** low trash density, spike-punishing. **Difficulty:** mid-band.
> **Build:** the **C.10 burst-spike** engine pattern (shipped + verified). **Healer preference is SOFT** — see the principle in §2.

**The puzzle.** Both healers clear Stillhour comfortably at the floor and through the mid keys — this is a *soft*
preference, not a wall. Near your **ceiling**, the burst toll (which lands on whoever's flagging) rewards the **triage
Cleric**: its instant Flash/Greater Heal (and overheal→shield) tops a focused target before the next 6s toll, where a
rolling HoT recovers a beat too slow. Net effect: the Cleric pushes **~1–2 key levels higher** than a HoT Lifebinder.
Raise **Cooldowns** (−12%/toll) + **Positioning** (the stage-2 avoidable).

**The read.** Invisible below the ceiling (both healers breeze low/mid). Pushing your limit, the Lifebinder caps ~1–2
keys lower — the log shows the flagging target dying to a toll the HoT couldn't top in time.

| Stage | Boss | Shape→Tactic | Mechanic | Flavor |
|---|---|---|---|---|
| 2 | Verger Antiphon | ground→positioning | single-victim avoidable toll — teaches "a HoT can't pre-load a target it doesn't yet know will be hit" | "The hour is kept. Kneel for it." |
| 4 | The Sunken Choir | **burst**→cooldowns | **C.10 burst:** every 6s the toll falls on the **lowest-HP non-tank** for `0.06·maxHp` (−12%/pt Cooldowns) | "All voices, on the hour. None after." |
| 6 | Drowned Sacristan | **burst**→cooldowns | the same burst, escalating | "Kneel or stand, the bell counts you the same." |
| 8 | Bellwarden Mire, Keeper of the Hour | **burst**→cooldowns | the capstone burst | "I ring it whether you are ready or not." |

**Build status (2026-06-21): authored + the C.10 burst pattern shipped & re-tuned to the soft-gap spec.** Opt-in
`spikeProfile:"burst"` — a hit on the **lowest-HP non-tank every 6s** for `0.06·maxHp` (`testsTactic:cooldowns` so the
dial mitigates; Ashveil untouched). Verified via the `healer-ceiling.mjs` sweep (3 seeds, gear-appropriate ilvl): **both
healers clean (3/3) through +12; Cleric extends to ~+13–14, Lifebinder caps +12 → gap ~1–2 keys, clean below.** `tsc -b`
clean; egm-smoke unchanged. (Earlier the burst was `0.35` — a hard floor-wall; softened per the "player not class"
principle.) **Reward hook:** the "Stillhour" healer/absorb set. **Loot = placeholder (Ashveil items), polish pass later.**

---

### 4.3 The Weltering Mire — *sustained-HoT healing (the Lifebinder read)*

> *A drowned barrow-fen where the water never stops rising; the dead don't spike, they pull you under by inches.*
> **Signature:** relentless sustained rot — a healer-attrition crucible. **Difficulty:** mid-band; the **symmetric
> inverse of Stillhour**. **Build:** the **C.10 `rot` pattern** (the inverse of burst). **Healer preference is SOFT** (§2).

**The puzzle.** The mirror of Stillhour: both healers clear the low/mid keys fine. Near the ceiling, the boss **rot** —
a flat tick on **every non-tank squishy** at once — rewards the **rolling-HoT Lifebinder**: its all-ally HoTs cover four
ticking targets where the single-target Cleric falls behind. Net: the Lifebinder pushes **~1–2 key levels higher**.
Raise **Cooldowns** (−12%/tick). Boss/trash auto-attack is deliberately **low** so the party-wide rot — not tank
survival — is the binding constraint (otherwise the Cleric's big single-target tank heals win, and it inverts).

**The read.** Invisible below the ceiling. Pushing your limit, the Cleric caps ~1–2 keys lower — the whole party grinds
down together as the rot out-paces reactive single-target healing.

| Stage | Boss | Shape→Tactic | Mechanic | Flavor |
|---|---|---|---|---|
| 2 | The Sodden Verger | **rot**→cooldowns | **C.10 rot:** every 3s a flat tick hits each non-tank for `0.06·maxHp` (−12%/pt Cooldowns) | "The fen keeps what it takes." |
| 4 | Mireborn the Unsurfaced | **rot**→cooldowns | the same rot, escalating | "I rose once. I can wait for you to sink." |
| 6 | The Tidemother | **rot**→cooldowns | the rot rises | "Every drowned thing was once someone's child." |
| 8 | The Glut-Drowned Choir | **rot**→cooldowns | the capstone rot | "Sing, drowned ones. Sing until the water is full." |

**Build status (2026-06-21): authored + the C.10 `rot` pattern shipped & tuned to the soft-gap spec.** Opt-in
`spikeProfile:"rot"` — a flat tick on each non-tank every 3s for `0.06·maxHp` (`testsTactic:cooldowns`; Ashveil
untouched). Boss `baseDamage` lowered (5–8) + thin front-melee trash so the party-wide rot dominates the ceiling.
Verified via `healer-ceiling.mjs`: **both clean through ~+6; Lifebinder reaches ~+9–10, Cleric caps ~+8 → gap ~1–2,
Lifebinder favored.** Needed a **second engine pattern** (the symmetric `rot`) — the pure-data version inverted because
back-band casters concentrate damage on one squishy (Cleric's strength). No mana economy — failure is "reactive heals a
tick late," not OOM. **Reward hook:** sustained-throughput healer gear.

---

### 4.4 The Hour of Bells — *cooldowns (the deepest dial, boss-gauntlet)*

> *A black-stone abbey run on a lethal timetable.* **Signature:** boss-dense, spike-punishing under enrage co-stress.
> **Difficulty:** the difficulty step-up. **Build:** pure data, but **designed around Tyrannical+Raging** (outside the
> MVP Fortified+Bursting pool) — ship post-MVP or build a Fortified variant.

**The puzzle.** A boss-dense run where most encounters fire the 12s party-wide spike. **Cooldowns is a three-in-one
dial:** −12%/pt spike, +4%/pt boss DPS (so the gauntlet dies inside the timer), and on **trash** it lowers the brain's
defensive-major gate. Cap Cooldowns first, then bank Positioning for the one ground boss.

**Comp answer (honest).** Cap the **Cooldowns slider** (not a recruit). Soft nudge toward a defensive-major spec
(Guardian/Crusader/Cleric/Arcanist) whose majors the dial pre-times **on trash**. Be honest: on **boss** stages
`holdForWindow` pops majors on cooldown regardless of the dial — the boss-stage benefit is just −12% spike / +4% DPS.

| Stage | Boss | Shape→Tactic | Role | Flavor |
|---|---|---|---|---|
| 2 | Verger Mauthe, Who Keeps the Hour | phase→cooldowns | the teacher spike | "Mind the hour. It does not mind you." |
| 4–6 | The Leaden Carillon | phase→cooldowns | escalation under Death-Frenzy (Raging) trash | "Every bell heavier than the last." |
| 8 | Lord-Abbot Crell, the Final Peal | phase→cooldowns | capstone | "Pop everything now, child — or pop nothing, and be tolled." |

**Fixes folded in:** **sim-sweep boss `baseHp`/`baseDamage` so cd=0 wipes AND cd=3 reliably times** (the central
balance task — the floor as-authored does *not* wipe; lethality must be tuned in). Fix the `tactics.json` tooltip
(−10% vs engine −12%). Don't claim "Cleric > Lifebinder" (a slow 12s spike is exactly what HoTs cover) unless a
Bursting layer is added. Gate behind the affix-pool fix.

---

### 4.5 The Pyreward Ossuary — *damage school (Physical vs Magic)*

> *A bone-vault of grave-iron and warding-salt — half the dead blunt the blade, half drink the spell.* **Signature:**
> alternating grave-iron (eats Physical) and salt-ward (eats Magic). **Difficulty:** the comp-literacy capstone.
> **Build:** the **C.8** engine change (per-enemy armour/resist), shipped. **Healer/comp preference is SOFT** (§2).

**The puzzle.** Grave-Iron bosses (armour) eat **Physical**; salt-warded bosses (resist) eat **Magic**; they alternate.
A comp with **both** schools always has un-mitigated damage on every boss; an all-one-school core has half its damage
eaten on half the bosses → slower kills → loses ~1–2 key levels of ceiling. Per the "player not class" rule (§2) this
is a **soft** preference: any reasonable comp (the strong DPS split 2 Physical / 2 Magic, so balance is natural) clears
the low/mid keys; tunnel-visioning one school just caps a couple keys lower.

**Comp answer (soft).** physical = Assassin/Berserker (+ Bard/Mystic) · magic = Pyromancer/Arcanist (+ Cleric). Bring
at least one of each (easy — the roster only has 2 strong DPS per school, so a balanced core is the default). It's a
**kill-speed/timer** check (school mitigation slows the wrong dealers), not survival.

| Stage | Boss | Defends | Shape→Tactic | Flavor |
|---|---|---|---|---|
| 2 | Vergil, the Grave-Iron Warden | **armour** (eats Physical) | summon→killorder | "Iron does not bleed." |
| 4 | Saltmother Quell | **resist** (eats Magic) | ground→positioning | "Salt drinks the spell before it lands." |
| 6 | The Annealed Choir | **armour** | phase→cooldowns | "Tempered in the pyre, cooled in the dark." |
| 8 | Heretic-Pyre Ossuar | **resist** (finale) | cast→interrupts | "Burn the word from the air." |

*(Bosses get **distinct** `testsTactic` so the school wall layers over varied tactic tests.)*

**Build status (2026-06-21): C.8 shipped + the Ossuary tuned to the soft-gap spec.** `EnemySchema.armour/resist`
(default 0 → Ashveil byte-identical), wired through `makeEnemy` (scaled by `keyScale`), routed by the existing
`pipeline.resolveHit`. Boss armour/resist `250`, trash `150`. Verified via `pyreward-ceiling.mjs` (mixed vs
all-physical core, with **Ashveil as the no-armour control** to subtract spec-power confound): mixed caps ~+13 (like the
other dungeons); the **school-specific tax is ~1–2 keys**. **Two findings baked in:** (1) the `resolveHit` ratio formula
is *sticky* (small hits stay ~15–20% mitigated across a wide armour range), so the value is coarse — don't expect fine
control. (2) **Trash must be front-melee** — caster-heavy trash made it an *AoE* check (pyro/arcanist shred back-liners),
confounding "have magic" with "have AoE"; front-melee trash isolates the school wall. **Reward hook:** spec-targeted
weapons. **Loot = placeholder.** **Note:** a single-school core also pays a spec-power penalty (only 2 strong DPS per
school), so its *raw* ceiling drop looks bigger than the ~1–2 *school* keys — that confound is roster-wide, not the wall.

---

## 5. New affixes (IP rename + one new branch)

The verbatim-WoW affix names are a **pre-launch IP gate** (see `MMO-Nostalgia-Reference.md` and the roadmap
"Affix swap" row) — but it is **deferred / low priority** (done way down the line as one global cosmetic pass). It is
**not on the content critical path**: dungeons reference affixes by **`id`**, so they inherit the rename automatically
whenever it lands. Author the dungeons against the existing ids now. Rename the **noun only** — keep `id`/`icon`/`punishes`
and the exact curves:

| New name | Renames (verbatim WoW) | Effect (unchanged curve) | Punishes |
|---|---|---|---|
| **Plaguebloom** | Bursting | each non-boss death → stacking party DoT (~0.7%/stack/s, decays 0.3/s); Kill Order cuts stack gain | killorder *(powers the Mire's rot)* |
| **Restless Shade** | Spiteful | each non-boss death hits the lowest-power ally (halved if any peel) | behavior *(NB: free pass — both healers peel)* |
| **Crowned in Ash** | Tyrannical | boss HP+damage ×1.3 | cooldowns *(co-stress for Hour of Bells)* |
| **Death-Frenzy** | Raging | sub-30% mobs gain up to +25% haste, blunted 10%/pt by Cooldowns | cooldowns *(trash enrage, Hour of Bells)* |
| **The Tolling** *(NEW, v2)* | — | periodic penalty to effective interrupt catch-chance on the next cast | interrupts *(second layer for Bellreach)* |

---

## 6. Engine backlog (what unlocks the rest)

| Item | Unlocks | Effort |
|---|---|---|
| ~~**Burst + rot boss variants**~~ — ✅ **DONE (C.10)**: opt-in `spikeProfile:"burst"\|"rot"`, soft ~1–2-key healer levers (burst→Cleric, rot→Lifebinder) | **Stillhour Abbey** (burst) + **The Weltering Mire** (rot) | medium |
| ~~**Per-enemy `armour`/`resist`**~~ — ✅ **DONE (C.8)**: `EnemySchema.armour/resist` (default 0), `makeEnemy` scales by keyScale, routed by existing `resolveHit` | **The Pyreward Ossuary** (soft ~1–2-key school preference) | small |
| **"The Tolling" affix** — new hard-coded branch perturbing the interrupt catch term | Bellreach v2 difficulty layer | small |
| **Per-encounter mechanic cadence/coefficients in data** — so same-tactic bosses differ mechanically | breaks "same spike, bigger numbers" across Bellreach/Hour/Stillhour/Mire | medium |
| **Real interrupt capability + enemy cast-bar/telegraph** — makes "bring a kicker" a genuine solve | Bellreach's *promised* Arcanist/Mystic roster pressure | large |
| **Enemy-applied statuses + dispel target; threat/taunt; reach gate** — none exist today | future CC / dispel / back-line-reach dungeons (toward 8 total) | large |

---

## 7. Build-now sequencing

Target is the **6-dungeon roster** (not chasing 8 — see §8). The **IP affix rename is deferred** and off the critical
path (dungeons reference affix `id`s; §5). Tactic budget is **confirmed 6 / max 3 per dial**.

Each dungeon is staged **mechanics-first** (playable + the puzzle verifiably reads via `egm-smoke`), with loot/items/
tier-set as a follow-up polish pass — so we don't block a playable dungeon on its full loot table.

1. **Author the pure-data trio** (no engine work, no affix dependency), mechanics-first, in this order:
   **Bellreach** (interrupts) → **Stillhour** (burst-heal) → **Weltering Mire** (HoT, references the Bursting `id`).
   Per dungeon: `dungeons.json` entry + `enemies.json` bosses/trash + `abilities.json` boss abilities + `packs.json`,
   add to `season.json` rotation, then `node scripts/egm-smoke.mjs` to confirm the +2 floor still times **and** the
   intended failure actually reads (wrong dial/healer → visible loss).
2. **Land C.8** (the small armour/resist engine change), then author **The Pyreward Ossuary** as the marquee — the only
   dungeon with real comp pressure.
3. **The Hour of Bells** last — it needs Tyrannical+Raging, outside the MVP Fortified+Bursting pool, so it's gated on
   the affix-pool decision (lift the restriction, or build a Fortified variant of its spike pressure).
4. **Loot/items/tier-set polish pass** across the new dungeons (`items.json` + `loot-tables.json` + `tier-sets.json`).
5. *(Way down the line, low prio)* the global **IP affix rename** — one cosmetic pass; dungeons inherit it via `id`.

**Progression order & lesson:** Ashveil (the dials exist) → Bellreach (commit a dial) → Stillhour (read the spike) →
Weltering Mire (read the rot — completes the healer-choice tutorial) → Hour of Bells (master the deepest dial under
enrage) → Pyreward Ossuary (the one lesson no dial fixes: bring the right school).

---

## 8. Open decisions

**✅ Resolved**
- **Tactic-point budget** — `tuning.tacticsPoints` = **6 total / max 3 per dial**. "Pin one dial to 3 AND bank 3" is
  affordable; Bellreach et al. stand as designed.
- **Roster size** — staying at **6 (Ashveil + 5)**; not funding the 🚧 levers to chase 8 for now (CC / dispel / reach /
  real-interrupt remain a future-wave menu in §6, each buying one more distinct dungeon if we ever want them).
- **IP affix rename** — **deferred, low priority**; off the content critical path (dungeons reference affix `id`s).
- **Healer-choice pair (Stillhour + Mire)** — **resolved by the C.10 burst/rot patterns**, tuned to the "bring the
  player, not the class" spec (§2): both healers clear low/mid keys; the ideal healer extends the ceiling ~1–2 keys
  (Cleric on Stillhour's burst, Lifebinder on the Mire's rot). Verified via `healer-ceiling.mjs`.

**⬜ Still open**
1. **Hour of Bells needs Tyrannical+Raging** (outside MVP pool). Lift the affix-pool restriction, or design a
   Fortified+Bursting variant of its spike pressure? *(Deferred to when we author Hour of Bells — it ships last.)*
2. **Per-encounter mechanic cadence** (medium effort) would end "same spike, bigger numbers" monotony across the spike
   dungeons. Worth it for v1, or accept thematic-only differentiation?
3. **Bellreach's interrupt read doesn't flip the outcome yet** (verified 2026-06-21 — log-visible casts-through + a
   duration delta, but timed↔wipe is unchanged at the floor). Tune the **global** interrupt cast coefficient (also
   hits Ashveil's Vesk), or land **per-encounter weighting**, so Interrupts-0 actually wipes where Interrupts-3 times?
   Separately: a 6-point budget can't fund interrupts+cooldowns **and** kill-order, so +12-ish wipes on trash under
   Bursting — intended tension, or does Bellreach want lighter trash / a higher key-band entry?
