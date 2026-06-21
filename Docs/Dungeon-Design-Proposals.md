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
| Sustained-HoT read | Continuous chip, no spikes → roll HoTs that pre-tick the carpet | Lifebinder | ✅ |
| Burst-triage read | Discrete spikes a HoT can't un-do → instant top-ups + absorbs | Cleric (Mystic/Lifebinder partial) | ✅ |
| Anti-yolo aggression tax | Avoidable/Spiteful/Bursting intake scales ~2× with Yolo; dial down | Aggression posture | ✅ |
| Soft-enrage DPS race | Beat the 90s enrage by output or eat ramping damage | Output + Cooldowns | ✅ |
| Spiteful "weakest link" | Ghosts hunt your lowest-**power** member → don't field a passenger | Roster floor + any peel spec | ✅ |
| **Damage school (Phys/Magic)** ⭐ | Boss eats one school → field mixed-school DPS | phys: zerk/sin/mystic/guardian/crusader/bard · magic: pyro/arcanist/cleric | 🔧 |
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
to soften the binary cliff; this key's tactic budget must allow *pin Interrupts AND bank Cooldowns* (budget ≥ 4, or
drop to two interrupt bosses + one breather). **Reward hook:** interrupt/utility-flavored gear that sets up the
cooldown-heavy Hour of Bells. **The Tolling** (v2 affix): periodic penalty to interrupt catch-chance — a second stress
layer on the same dial (hard-coded branch).

---

### 4.2 Stillhour Abbey — *burst-triage healing (the Cleric read)*

> *A drowned monastery where the bells still toll the hours; between each toll the air is dead-calm, and on the hour
> the silence breaks all at once.* **Signature:** low trash density, spike-punishing. **Difficulty:** mid-band; the
> clock is easy, the difficulty is entirely the healer read. **Build:** pure data.

**The puzzle.** Long calm windows, then a discrete spike on the :00 beat that a HoT **cannot retroactively un-do**.
Read *"big infrequent hits, not constant chip"* → bring the **triage Cleric** (Flash Heal instant top-ups, sub-30%
Greater Heal, Light's Salvation pre-absorb) over the rolling-HoT Lifebinder, and raise **Cooldowns** to shave the
party-wide toll (−12%/pt). The deliberate **inverse twin** of the Weltering Mire.

**Failure mode.** Deaths cluster exactly on the :00 beats; the calm windows show overheal everywhere. The log reads
"fine, fine, fine, DEAD, fine, fine, DEAD." A Lifebinder's Regrowth ticks a beat behind the spike instead of ahead of
the next one.

**Comp answer (honest).** A **soft preference**, not a one-spec wall: burst-heal coverage is *strong* (Cleric, with
Mystic/Lifebinder partial), so own this as a **"diagnose the damage profile"** dungeon, not a forced recruit. The real
lever is *reading spike-vs-rot*. Tactic: max Cooldowns.

| Stage | Boss | Shape→Tactic | Mechanic (≈) | Flavor |
|---|---|---|---|---|
| 2 | Verger Antiphon | ground→positioning | the toll floods under **one** random celebrant (18·keyScale single victim) — teaches "a HoT can't pre-load a target it doesn't know will be hit" | "The hour is kept. Kneel for it." |
| 5 | The Sunken Choir | phase→cooldowns | the toll goes **party-wide** (14·keyScale, −12%/pt); the burn-window between tolls grants +4%/pt | "All voices, on the hour. None after." |
| 8 | Bellwarden Mire, Keeper of the Hour | phase→cooldowns | the loudest toll; an un-triaged party loses someone every beat | "I ring it whether you are ready or not." |

**Honesty caveats (must respect):** keep `baseDamage` **low** (the toll ignores it; high baseDamage floods the calm).
At the +2 floor the spike is only ~11–16% of a DPS's HP — **the spike read only emerges above the floor / on Yolo**;
document that rather than dramatizing "100%→15%." Don't teach "Cooldowns pre-pops your save on bosses" (false). The
Lifebinder has a built-in sub-25% instant (Nature's Grace) + Vital Surge, so it under-performs on *throughput-per-spike*,
it doesn't "heal a corpse." **Reward hook:** the "Stillhour" healer/absorb set (Censer of the Last Hour, Tolling-Bell
Reliquary). **Open question:** is a soft-preference lesson compelling enough, or add a Bursting layer to genuinely
punish HoTs and harden the choice?

---

### 4.3 The Weltering Mire — *sustained-HoT healing (the Lifebinder read) + kill-order*

> *A drowned barrow-fen of plague-blossoms — wall-to-wall low-HP trash, no spike, a healer attrition crucible.*
> **Signature:** relentless sustained chip, rot-punishing. **Difficulty:** mid-band; the inverse of Stillhour.
> **Build:** pure data (leans on the **Plaguebloom**/Bursting affix → needs the IP rename first).

**The puzzle.** Damage-taken is a flat party-wide **carpet of ticks** (Plaguebloom DoT off dense corpses + chip), zero
big spikes. Read *"rot, not spike"* → bring the **rolling-HoT Lifebinder** over the burst Cleric (HoTs pre-tick the
carpet; reactive direct heals arrive a tick late), raise **Kill Order** to throttle Plaguebloom stack-gain, and ease
aggression (the rot scales by `aggroIntake`).

**Failure mode.** No single death-cause — the whole party grinds down together as Plaguebloom stacks climb faster than
reactive heals land. The replay's **Bursting stack-count readout** (surface it as first-class) is the smoking gun.

**Comp answer (honest).** Lifebinder is the load-bearing pick — but frame the Cleric gap as **throughput timing**, not
mana (there is no mana economy). Both healers are peel, so **don't** lean on Spiteful to separate them; lean on HoT
pre-ticking alone. Tactic: Kill Order for even deaths + low aggression.

| Stage | Boss | Shape→Tactic | Mechanic (≈) | Flavor |
|---|---|---|---|---|
| 2 | The Sodden Verger | summon→killorder | rot-tutor; short DPS-check between rot packs (**bosses don't feed adds** — the attrition lives on trash) | "The fen keeps what it takes." |
| 5 | Mireborn the Unsurfaced | summon→killorder | escalation; denser rot packs flank it | "I rose once. I can wait for you to sink." |
| 8 | The Glut-Drowned Choir | summon→killorder | sustained finale; the carpet is thickest here | "Sing, drowned ones. Sing until the water is full." |

**Honesty caveats:** the attrition lives **entirely on trash**; bosses spawn no killable adds — frame them as short
DPS-checks *between* rot packs. Purge all mana/OOM language. Sim-verify the Cleric actually struggles and the
Lifebinder clears before shipping. **Reward hook:** sustained-throughput healer gear + Kill-Order-flavored DPS pieces.

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

### 4.5 The Pyreward Ossuary ⭐ — *damage school (Physical vs Magic)*

> *A bone-vault of grave-iron and warding-salt — half resist the blade, half resist the spell.* **Signature:** the
> season's comp-literacy gate. **Difficulty:** the capstone (a knowledge-wall, not a numbers-wall). **Build:**
> **needs the small engine change** (per-enemy armour/resist). **The flagship — the only dungeon with real comp pressure.**

**The puzzle.** Boss HP isn't the problem — your damage **school** is. Grave-Iron bosses eat **Physical**; Ward-woven
bosses eat **Magic**; they alternate, so **no single-school DPS core clears all four**. You must field at least one
magic dealer **and** one physical dealer. The trash "half the pack survives your AoE" beat teaches it cheaply (and
sidesteps the single-target auto-focus problem).

**Comp answer (real roster pressure — the point of the dungeon).** magic = Pyromancer/Arcanist/Cleric ·
physical = Berserker/Assassin/Mystic/Guardian/Crusader/Bard. **No dial touches school mitigation.** Tune for a **slow
kill** (~75–85% mitigation — loses the soft-enrage race) not a 90% brick wall, so the bar still moves and the failure
reads as *"half your damage was eaten,"* not "immune."

| Stage | Boss | Defends | Shape→Tactic | Flavor |
|---|---|---|---|---|
| 2 | Vergil, the Grave-Iron Warden | high **armour** (eats Physical) | summon→killorder | "Iron does not bleed." |
| 4 | Saltmother Quell | high **resist** (eats Magic) | ground→positioning | "Salt drinks the spell before it lands." |
| 6 | The Annealed Choir | high **armour** | phase→cooldowns | "Tempered in the pyre, cooled in the dark." |
| 8 | Heretic-Pyre Ossuar | high **resist** (finale) | cast→interrupts | "Burn the word from the air." |

*(Bosses get **distinct** `testsTactic` so the school wall layers over varied tactic tests instead of four
cooldowns-clones.)*

**Engine change required (small).** Add optional `armour`/`resist` number fields to `EnemySchema` (default `0`, so
Ashveil stays byte-identical) and replace the hard-coded `armour:0 / resist:0` in `makeEnemy` (`stats.ts`) with
`opts.armour / opts.resist`. Decide armour-vs-hit-size scaling (multiply by `keyScale` **and** party power so the wall
holds as gear climbs). `pipeline.resolveHit` already routes Physical→armour, Magic→resist at the 90% cap — **no new
branch.** **Reward hook:** plain spec-targeted weapons (defer proc-based "school-flex" trinkets until a proc system
exists). **Don't** claim "fails at ANY ilvl" — the mitigation ratio is hit-size dependent; scale it or reframe honestly.

---

## 5. New affixes (IP rename + one new branch)

The verbatim-WoW affix names are a **hard pre-launch IP gate** (see `MMO-Nostalgia-Reference.md` and the roadmap
"Affix swap" row). Rename the **noun only** — keep `id`/`icon`/`punishes` and the exact curves:

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
| **Per-enemy `armour`/`resist`** — schema fields + un-hardcode `makeEnemy`; decide hit-size scaling | **The Pyreward Ossuary** (the chosen flagship) | **small** |
| **"The Tolling" affix** — new hard-coded branch perturbing the interrupt catch term | Bellreach v2 difficulty layer | small |
| **Per-encounter mechanic cadence/coefficients in data** — so same-tactic bosses differ mechanically | breaks "same spike, bigger numbers" across Bellreach/Hour/Stillhour/Mire | medium |
| **Real interrupt capability + enemy cast-bar/telegraph** — makes "bring a kicker" a genuine solve | Bellreach's *promised* Arcanist/Mystic roster pressure | large |
| **Enemy-applied statuses + dispel target; threat/taunt; reach gate** — none exist today | future CC / dispel / back-line-reach dungeons (toward 8 total) | large |

---

## 7. Build-now sequencing

1. **IP affix rename** (Bursting→Plaguebloom, Spiteful→Restless Shade, Tyrannical→Crowned in Ash, Raging→Death-Frenzy)
   as one clean commit — the Mire and Hour of Bells depend on the renamed nouns matching their earnest register.
2. **Confirm `tuning.tacticsPoints`** (3 vs 4) — Bellreach et al. assume you can *pin one dial AND bank leftovers*.
3. **Author the Fortified/Bursting-compatible trio first** — **Bellreach → Stillhour → Weltering Mire** (pure data:
   dungeons/enemies/abilities/packs/items/loot-tables/season). Run `node scripts/egm-smoke.mjs` to confirm the +2 floor
   still times and each dungeon's failure actually reads.
4. **Land the small armour/resist engine change**, then author **The Pyreward Ossuary** as the marquee.
5. **Unlock Tyrannical/Raging** (or build a Fortified variant) and author **The Hour of Bells**.

**Progression order & lesson:** Ashveil (the dials exist) → Bellreach (commit a dial) → Stillhour (read the spike) →
Weltering Mire (read the rot — completes the healer-choice tutorial) → Hour of Bells (master the deepest dial under
enrage) → Pyreward Ossuary (the one lesson no dial fixes: bring the right school).

---

## 8. Open decisions

1. **Tactic-point budget: 3 or 4?** Several designs assume "pin one dial to 3 AND bank leftovers" — impossible at 3.
2. **Stillhour's healer split is a *soft* preference** (both healers viable). Compelling enough as a diagnose-the-profile
   lesson, or add a Bursting layer to harden it into a real wall?
3. **Hour of Bells needs Tyrannical+Raging** (outside MVP pool). Lift the affix-pool restriction, or design a
   Fortified+Bursting variant of its spike pressure?
4. **Per-encounter mechanic cadence** (medium effort) would end "same spike, bigger numbers" monotony across the four
   spike dungeons. Worth it for v1, or accept thematic-only differentiation?
5. **Reaching a true 8:** which 🚧 engine lever(s) to fund (CC / dispel / reach / real-interrupt), each buying one more
   genuinely-distinct dungeon?
