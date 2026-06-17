# GOAT Lite: Mythic+ Manager
**Subtitle:** *It's not your fault. It's never your fault.*  
**Genre:** Guild Management Sim / Auto-Battler / Satirical RPG  
**Tone:** GOAT — satirical MMO culture, WoW M+ skin  
**Format:** Browser game (online leaderboards)  
**Reference:** Exiled Guild Manager (itch.io)

---

## The Pitch

> *You used to be a world-first raider. The game burned you out years ago. Now you're a QA contractor for a studio that's launching the next big MMO — and they need someone who actually understands endgame to stress-test their dungeon system. You don't play. You don't raid. You run sims, file reports, and tell the devs what's broken before launch.*

A guild management sim set inside the beta of a fictional WoW-like MMO. You play as a retired raider working QA — recruiting test bots, gearing them up, running them through Mythic+ dungeons, and reviewing the results to find what breaks. You don't control the fight. You review the pull. You adjust the tactics. You file the report. You try again.

It's M+… minus the sweating, plus a job.

**GOAT Universe Connection:** GOAT Lite is set during the beta of the same MMO that GOAT main game depicts post-launch. Same world, same classes, same dungeons. The leaderboard exists because other beta testers are running the same builds you are — community competition is part of the QA process. Players who finish GOAT Lite are literally primed for GOAT's release.

---

## Core Loop

```
Select Key → Set Comp & Tactics → Run Dungeon (auto-battle replay) 
→ Review What Went Wrong → Adjust → Push Higher → Leaderboard
```

Each loop is a **decision layer**, not a reaction layer. The game lives in the **preparation and diagnosis**, not the execution.

---

## Player Fantasy

- The **armchair shot-caller** who knows exactly what everyone did wrong
- The **theory-crafter** who min-maxes talent trees before the patch notes are cold
- The **roster manager** who has to decide whether to bench the toxic rogue who parses 99 or keep morale alive
- The **M+ nerd** who understands that Fortified+Bursting+Spiteful is a specific kind of hell
- The **burned-out vet** who finally found a way to engage with the genre that doesn't require 14-hour raid nights

---

## Key Systems

### 1. Classes & Specializations (LOCKED)

GOAT Lite uses the same 5 classes and 10 specializations as GOAT main game. Each spec maps to a clear M+ role.

**Front line = melee range. Back line = ranged / caster.**

| Class | Spec | Role | Position | Identity |
|---|---|---|---|---|
| **Warrior** | Guardian | Tank | Front | Taunt, stun, thorns |
| | Berserker | Melee DPS | Front | Rampage stacks, cleave, bleed |
| **Paladin** | Crusader | Shield Tank / Support | Front | Party shields, guard, mark cleanse |
| | Cleric | Burst Healer | Back | Disc-style burst heals + absorbs + cleanse |
| **Rogue** | Assassin | Single-Target DPS | Front | Camouflage, execute, crit chains |
| | Bard | Buff/Debuff Support | Back | Overdrive windows, CD tweaks, mark/crit setup |
| **Mage** | Pyromancer | AoE Burst DPS | Back | Burn stacks → detonate, long-CD nukes |
| | Arcanist | Control DPS | Back | Silence, slows, party barrier |
| **Sage** | Lifebinder | Regen Healer | Back | HoTs, DOT→heal conversions, nature shields |
| | Mystic | Off-Tank Support | Front | Parries, stuns, self-sustain |

---

#### M+ Role Distribution

| Role | Specs |
|---|---|
| **Primary Tank** | Guardian, Crusader |
| **Off-Tank Hybrid** | Mystic |
| **Primary Healer** | Cleric, Lifebinder |
| **Melee DPS** | Berserker, Assassin |
| **Ranged DPS** | Bard, Pyromancer, Arcanist |

Standard party = 1 Tank + 1 Healer + 3 DPS. Players who want to experiment can run 2-healer or off-tank comps for specific affix weeks (Tyrannical with heavy boss damage, or Grievous-style healing pressure on raging weeks).

**Composition matters for the sim:** different specs interact differently with affixes and tactics points. A Bard's debuff window can compensate for low Cooldowns allocation on Tyrannical week. A Crusader's party shields can soak Volcanic damage if Positioning points are starved.

---

### 2. The Roster

You manage a guild roster that grows from 5 adventurers to a cap of 15. Each dungeon takes 5.

**Every adventurer has:**
- **Class + Spec** — one of the 10 GOAT specs above
- **Item Level** — determines raw throughput
- **Talent Build** — you assign this. Choices matter per affix/dungeon
- **Starting Traits** — permanent personality, assigned at recruitment (2 per character)
- **Earned Traits** — unlocked through gameplay events, replace the old scar system (up to 3)
- **Potentials** — hidden growth profile that biases which earned traits a character rolls; partially revealed at recruitment
- **Morale** — dynamic mental state, affects performance

---

#### Starting Traits (LOCKED)
Permanent. Assigned at recruitment. Define who this person is before the game shapes them.

| Trait | Rarity | Archetype | Net | Effect |
|---|---|---|---|---|
| Jenkins | Common | Wildcard | 6 | +12% output, -15% defensive reliability |
| Boomer | Common | Specialist | 5 | -8% output, -25% death chance |
| Prog Andy | Common | Specialist | 7 | +15% output on repeat attempts of the same dungeon, -10% on first attempt |
| Duo Queue | Common | Enabler | 6 | +8% output when paired with the same teammate across 3+ consecutive runs |
| Casual Andy | Uncommon | Wildcard | 9 | Output capped at 80% ceiling, never dies — reliable floor, limited upside |
| Drama Queen | Uncommon | Wildcard | 10 | +15% output when timer is below 20% remaining OR 2+ deaths have occurred this run |
| Solo Player | Rare | Selfish | 13 | +10% output; party tactics points apply at half strength to this character's individual checks (interrupt assignments, positioning rolls) |
| Loot Goblin | Rare | Selfish | 14 | +15% output when the run's pre-rolled (hidden) loot contains an upgrade this character can equip |

**Visual encoding:** Common = gray border, Uncommon = blue border, Rare = gold border. Rarity is immediately readable on recruitment cards without needing tooltip inspection.

**Distribution rule:** Common traits appear ~70% of the time, Uncommon ~25%, Rare ~5%. A recruit with two Rare traits is a unicorn — and the visible borders make this obvious at first glance.

**Archetype & Net Budget (kiss/curse balance):** every trait carries an **archetype** — *Wildcard / Specialist / Enabler / Selfish / Leader* — and a **Net Budget**, a first-pass power score (kiss minus curse) on roughly the same scale GOAT main uses. Positive = a net gain you build around; for the earned traits below, negative budgets are scars (a net cost), so a pool's expected budget tells you whether triggering it is good or bad on average. Archetypes are the families **Potentials** bias toward (a `survival`-leaning recruit drifts Specialist/defensive). All budgets are *Needs Tuning* — they feed the Trait↔sim reconciliation pass, not the MVP. (Trait names and the kiss/curse framing are drawn from GOAT main's `PossibleTraits` set; re-expressed here in GOAT Lite's output / HP / morale / tactics vocabulary — none of the turn/round/slot mechanics carried over.)

---

#### Earned Traits (LOCKED)
Unlocked through probabilistic event triggers during runs. Replace the old scar system entirely.

**Design rules:**
- Triggers are event-based and probabilistic — no countable farming
- Every trigger has a minimum key level gate — can't be farmed on low keys
- The player sees the event type but not the specific trait until it unlocks
- Each event type rolls from a pool of 4 outcomes with weighted rarity — you never know which
- Maximum 3 earned traits per character, slots fill over time

**Rarity weights:** Common 60% / Uncommon 30% / Rare 10%

---

**Pool 1 — Pressure Response**
*Trigger: Near-death event (sub 5% HP) on key +10 or higher*

| Trait | Rarity | Type | Archetype | Net | Effect |
|---|---|---|---|---|---|
| Tilted | Common | Negative | Wildcard | -6 | -10% output on keys above +14 |
| Triggered | Uncommon | Negative | Wildcard | -5 | -10% performance on the affix active when this triggered |
| Second Wind | Uncommon | Positive | Specialist | +10 | +15% output when below 30% HP |
| Hard Carry | Rare | Positive | Leader | +12 | +10% output when 2+ teammates are dead |

---

**Pool 2 — Mechanic Exposure**
*Trigger: Significant avoidable damage from a specific affix on key +8 or higher*

| Trait | Rarity | Type | Archetype | Net | Effect |
|---|---|---|---|---|---|
| Standing in Fire | Common | Negative | Wildcard | -6 | -10% output on the affix that triggered this |
| Pool Dweller | Common | Negative | Wildcard | -6 | Always positions badly in Sanguine |
| Mechanic Master | Uncommon | Positive | Specialist | +9 | +8% damage resistance to that affix's damage type |
| Spatial Awareness | Rare | Positive | Specialist | +13 | +10% positioning reliability on all affixes |

---

**Pool 3 — Success Response**
*Trigger: First-time timing a key above +15, or 10+ consecutive timed keys on +8 or higher*

| Trait | Rarity | Type | Archetype | Net | Effect |
|---|---|---|---|---|---|
| Burnout | Common | Negative | Wildcard | -5 | -8% output on affixes they've cleared 5+ times |
| Cocky | Uncommon | Negative | Selfish | -4 | +15% output, +20% death chance |
| Redemption Arc | Uncommon | Positive | Wildcard | +9 | +12% output in dungeons previously wiped in |
| Cracked | Rare | Positive | Specialist | +14 | +5% to all stats |

---

**Pool 4 — Social Response**
*Trigger: Last survivor of a full party wipe, or top performer 5 runs in a row — key +12 or higher*

| Trait | Rarity | Type | Archetype | Net | Effect |
|---|---|---|---|---|---|
| Survivor's Guilt | Common | Negative | Wildcard | -6 | -10% output the run immediately following any wipe |
| Rival | Uncommon | Negative | Selfish | -4 | +10% output, -15% morale if a specific teammate dies |
| Battle-Hardened | Uncommon | Positive | Specialist | +9 | +8% max HP |
| Guild Leader | Rare | Positive | Leader | +12 | +8% output when highest item level in the party |

---

#### Morale (LOCKED)

Scale: 0–100. New recruits start at 70.

| Event | Morale Change |
|---|---|
| Timed key | +10 |
| Timed a near-wipe (2+ deaths, or timer finished below 10%) | +5 (thrilling victory) |
| Depleted key (no wipe) | -5 |
| Party wipe | -20 |
| Lost contested loot | -5 |
| Timed a key that drops gear 30+ ilvl below what the character already wears (farming trivial content) | -3 (boredom) |
| Morale Officer building (per run) | +5 |

Boredom and thrilling-victory are borrowed from the reference game: boredom pushes players up the key ladder instead of farming safe keys, and thrilling-victory makes a clutch Yolo run emotionally profitable.

**Sim effect (3 bands):** morale ≥ 90 → ×1.05 output (high-morale reward — the upside the meter previously lacked); 50–89 → ×1.0; below 50 → falls linearly to ×0.7 at 0.

**Low morale (below 30):** negative trait effects are amplified ×1.5. Traits are passive conditional modifiers, not procs — "personalities get worse under pressure" means amplification, and Coaching Corner reduces it to ×1.25.

**Departure (feature-flagged):** when morale hits 0 the adventurer rolls to leave the guild — a ramping chance (one grace run, then +5%/run while at zero, cap 95%) with warnings surfaced beforehand. **Phase 1 ships the broken-morale state, the warnings, and the UI but keeps the departure roll disabled behind a flag**; Phase 2 flips it on once Ongoing Recruitment can absorb losses. (Cleaner than a hard floor — the whole system ships in MVP; only the consequence waits. Pattern lifted from the reference game.)

**Morale is buildable (Phase 2):** every gain and loss passes through two per-character modifiers — **morale gain** (+% to gains) and **morale-loss resistance** (−% to losses, capped ~90%) — so a trait or building can turn morale from a global meter into a roster-building axis (a "Stoic" trait that shrugs off wipe morale; the Morale Officer raising recovery). MVP uses the flat table above with no modifiers; the hooks arrive with traits and buildings.

**Morale-conditional spec bonuses (Phase 2):** beyond the global output band, individual specs can carry their own morale-threshold conditionals — a high-strung DPS that gains extra output above 90 morale but craters below 30, versus a steady spec that barely notices. This makes "who do I keep happy" a spec-flavored decision rather than a uniform meter. Per-spec values are Phase 2 content (they need the full 10-spec roster); the MVP's 3 specs use the global band only. (Both morale extensions are borrowed from the reference game.)

---

#### Potentials (LOCKED — Phase 2)

Potentials are the hidden growth profile that makes one recruit feel different from another with the same class and item level. They are **draft-bias weights, not stat bonuses** — they never touch the Output formula directly.

**How they work:**
- Each potential is a **tag → weight** (baseline 1.0, sources add, clamped 0–5). Tags are the same taxonomy the trait pools use — `crit`, `survival`, `interrupt`, `positioning`, `aoe`, `cleave`, `sustain`, etc.
- A weight **biases a random draft toward matching outcomes**, and nothing else. Concretely: when an **Earned Trait** trigger fires and rolls one of the 4 traits in its pool, each trait's tags are matched against the character's potential weights — a high on-tag weight pulls the roll toward that trait, a low or negative weight pushes it away. A recruit with a high `positioning` potential who triggers Pool 2 (Mechanic Exposure) is far likelier to roll **Spatial Awareness** (+positioning reliability) than the rest of that pool.
- *(Coupling note: talents are fixed and freely swappable, so there is no talent draft for potentials to bias — the Earned-Trait pools are the draft they steer. **Wiring step:** tag each of the 16 earned traits with the taxonomy above; a few purely contextual traits (e.g. Tilted, Burnout) carry no tag and simply aren't biased. If a random talent-draft layer is ever added, potentials bias it too — same mechanism.)*
- Sources stack: **3 random tags** at generation (+0.5–0.9 / +0.8–1.4 / +1.1–1.9 → totals 1.5–2.9×), a **class** baseline, and **starting traits**. Negative sources are allowed — a flaw-trait can push a tag *below* 1.0, suppressing those outcomes.

**Hidden but active (the recruitment hook):** generation reveals ~50% of a recruit's potentials (the 2–3 shown on the card); the rest sit behind the "+X Unknown" counter. **Hidden potentials apply their full weight while concealed** — a high hidden potential quietly carries a recruit, a low one quietly drags. Each time a character earns a trait there is a 50% chance to **reveal one hidden potential**. You learn who someone really is by playing them — the same feeling as a chaos orb slam.

Phase 2 (ships with recruitment and earned traits). Model adapted from the reference game — see EGM-Reference-Analysis.md.

---

#### Recruitment (LOCKED)

Two distinct recruitment phases: **Initial Draft** (game start) and **Ongoing Recruitment** (post-start).

---

**Initial Draft — Role-Based Tab Selection**

The draft screen has **3 tabs** — one per M+ role. Each tab presents **10 candidates** of that role. Player picks **exactly 5 candidates total** across the three tabs to form their starting roster.

| Tab | Candidate Pool |
|---|---|
| **Tank** | 10 candidates from Guardian / Crusader (and occasional Mystic as off-tank hybrid) |
| **Healer** | 10 candidates from Cleric / Lifebinder |
| **DPS** | 10 candidates from Berserker / Assassin / Bard / Pyromancer / Arcanist |

**Total candidates available: 30. Player picks 5.**

---

**Composition is the opening decision:**

| Comp | Picks | Trade-off |
|---|---|---|
| Standard | 1 Tank / 1 Healer / 3 DPS | Balanced, safe baseline |
| Defensive | 2 Tanks / 1 Healer / 2 DPS | Slower clears, more survivability — good for Tyrannical |
| Heal-Heavy | 1 Tank / 2 Healers / 2 DPS | Sustain through brutal affixes — good for Grievous-style weeks |
| Glass Cannon | 1 Tank / 1 Healer / 3 high-damage DPS | Fastest clears, fragile |
| Tankless | 0 Tanks / 1 Healer / 4 DPS | High variance — punished hard on Fortified weeks |

Because there's no bench at start, this 5-pick decision shapes the first several runs significantly. Bench depth comes later through Ongoing Recruitment.

**Draft pity floor:** each role tab is guaranteed a minimum of higher-rarity candidates (≥2 with an Uncommon-or-better trait per tab), so a new player's first roster can't roll all-gray. The 70/25/5 trait distribution shapes the pool, but the floor protects the opening experience. (Reference-game technique — they reroll the starting draft until a quality floor is met.)

---

**Each candidate card shows:**
- Portrait + Name + Class + Spec
- 2 visible Traits with rarity-colored borders (visual enhancement only)
- 2–3 Known Potentials (visible growth stats e.g. "3.2 Interrupt Affinity", "2.1 Crit Scaling")
- "+X Unknown" counter showing how many hidden potentials exist

**Trait border colors** (cosmetic, not mechanical):
- Gold = Rare, Blue = Uncommon, Gray = Common. Helps players spot flashy candidates at a glance.

---

**Ongoing Recruitment — Post Initial Draft**

After the initial 5 are locked in, three recruitment sources unlock for adding to the roster:

| Source | Mechanic | Notes |
|---|---|---|
| **Recruitment Board** | New single candidate available each week | Quality scales with guild progression |
| **Dungeon Rescue** | Rare chance to recruit an NPC found during a run | Highest variance — could be Rare-trait jackpot |
| **Trade** | Spend currency to poach a specific class/spec | Unknown Potentials stay hidden — pure gear bet |

Roster cap = 15. Above 5 active characters, you choose who runs each key.

**Recruit level pegging:** ongoing recruits arrive geared at a margin *below* your best character (≈ 60–100% of your top item level), so they're worth developing without leapfrogging the roster you've built. The Recruitment Board "quality scales with guild progression" metric remains an Open Questions item, but the level-relative-to-roster rule is fixed. (Reference-game tuning.)

---

**The unknown slots are the hook.** A recruit might reveal "High Morale Ceiling" after run 3 — or "Sanguine Magnet." You don't know until they're on your roster. Same feeling as a chaos orb slam.

---

### 3. The Key System (LOCKED)

Keys are your content layer.

- **Dungeon** — 6 dungeons in the base game, each with distinct mob types and bosses
- **Key Level** — 2 through 20+. Higher = more HP/damage, better loot
- **Affixes** — weekly modifiers that change how the dungeon plays

---

#### Key Acquisition (LOCKED)

The guild holds **one keystone**, starting at +2 (Ashveil Crypts at season start). Timed → it goes up one level; depleted → down one (floor +2). In the full game the keystone re-rolls to a random dungeon whenever its level changes — per-dungeon best scores accumulate naturally as it cycles. Runs are unlimited and cost nothing: "Select Key" means running the keystone you hold, or deliberately depleting it to walk it down.

---

#### Affix Structure

**Tier 1 — Always active, alternates weekly:**

| Affix | Sim Effect | Punishes |
|---|---|---|
| Fortified | Trash HP/damage ×1.3 | Low team output on trash |
| Tyrannical | Boss HP/damage ×1.3 | Weak Cooldowns allocation |

**Tier 2 — Two rotate weekly from this pool of six:**

| Affix | Sim Effect | Tactics Category Punished |
|---|---|---|
| Bursting | Each mob death applies a stacking party DoT | Kill Order |
| Bolstering | Each mob death buffs surviving mobs' damage and HP | Kill Order |
| Volcanic | Random damage events on trash pulls | Positioning |
| Sanguine | Mobs heal in pools — time bleeds away if unaddressed | Positioning |
| Spiteful | Ghosts target lowest-output character after mob deaths | Behavior Profile |
| Raging | Mobs enrage below 30% HP, spiking damage | Kill Order + Cooldowns |

**Design rule:** Bursting and Bolstering never appear in the same week — both punish Kill Order and stacking them removes all counterplay.

---

#### Sim Impact Summary

Each affix maps directly to a tactics category. Starving that category on a week with that affix will produce visible failures in the event log:

- Bursting/Bolstering week + Kill Order 0 → pulls spiral out of control, time collapses
- Volcanic/Sanguine week + Positioning 0 → deaths on trash, healer overwhelmed
- Spiteful week + wrong Behavior Profile → ghosts shred your lowest-output character
- Raging + Cooldowns 0 → enrage phases on bosses hit too hard, Tyrannical week especially brutal

---

#### Key Progression (LOCKED)

- **Timed** → key level +1
- **Depleted** → key level -1 (floor at +2)
- Weekly vault reward = best timed key of the week gives one item choice
- Affix rotation changes every week — forces build and tactics adaptation

---

#### Calling the Run (LOCKED)

Between any two stages the player may **call the run** — end it early and take the **depleted** outcome (key −1, its **1 guaranteed item**, plus the elite's bonus item if you cleared it) instead of risking the rest. Pushing on is the gamble: clear it for the **timed** reward (key +1, **2 items**, vault eligibility), or **wipe and forfeit the run's loot entirely**. So the back half of a marginal key becomes a push-your-luck call: lock in the depleted item, or risk it all for the timed clear.

Available from the MVP — it's a button plus a loot rule, and it adds real decision surface to the "Review → Adjust" loop. (Adapted from the reference game's between-encounter retreat; see EGM-Reference-Analysis.md.)

---

#### Dungeon Timer (LOCKED)

**Ashveil Crypts base timer: 25 minutes**

| Key Level | Approx clear time (0 deaths, balanced tactics) | Buffer |
|---|---|---|
| +2 | ~14.5 min | 10.5 min |
| +5 | ~17 min | 8 min |
| +8 | ~20 min | 5 min |
| +10 | ~22 min | 3 min |
| +13 | ~24.5 min | 0.5 min |
| +15 | ~27 min | Depleted |

Each death = +5 seconds penalty + character outputs 0 for 10 seconds while rezzed. Three deaths on a +13 at 24 minutes = depleted.

The table assumes a fixed reference team geared for +8 (ilvl ~140) pushing upward — that's why rows above +8 exceed 80% of timer. The sweet spot: appropriate item level for the key + balanced tactics + zero deaths = ~80% of timer used. Deaths and bad tactics push toward 100% or over. **This table is the sim's acceptance test: all tuning constants must reproduce it.**

---

### 4. Talent System

Simple 3-choice nodes, not a full tree. Each spec has **5 decision points**, chosen before the run.

Each node is a meaningful tradeoff:

```
Node 1 — Survival vs. Throughput
  [A] Iron Will: +15% max HP
  [B] Executioner: +12% damage to targets below 30% HP  
  [C] Adaptive: +8% HP and +6% damage (balanced)

Node 2 — Single Target vs. AoE
  [A] Focused Strike: +20% single target damage
  [B] Cleaving Blow: attacks hit 2 additional targets for 40% damage
  [C] Opportunist: +15% damage when 3+ enemies are nearby
```

**No wrong answers, but wrong answers for the dungeon.** Fortified week = you want AoE nodes. Tyrannical week = single target. This is the theory-crafting hook.

Builds are **saved per roster member** and can be swapped before each key. The player gradually learns which builds work for which dungeons and affixes — the same way real M+ players do.

---

### 5. Tactics System (LOCKED)

Two layers. Fast to set up, meaningful in outcome.

---

#### Layer 1 — Per-Character Behavior Profile
Pick one profile per roster member before the run. Sets individual AI priority.

| Profile | Behavior |
|---|---|
| Tunnel Vision | Always hits highest HP target, ignores adds |
| Executioner | Switches to lowest HP target to secure kills |
| Peel | Prioritizes targets attacking allies |
| Opportunist | Mirrors the tank's current target |

Each class/spec has a default profile. You only change it when the dungeon or affix demands it.

---

#### Layer 2 — Party Tactics (Aggression Dial + Points)

Set once per run at the party level.

**Aggression Dial:**

| Setting | Effect |
|---|---|
| Safe | -10% output, -30% avoidable damage taken |
| Balanced | Baseline |
| Yolo | +15% output, +40% avoidable damage taken |

**Tactics Points — 6 points, 4 categories (min 0, max 3 per category):**

| Category | What it covers | Starved = |
|---|---|---|
| Interrupts | Cast interruption reliability | Dangerous spells go through |
| Positioning | Spread/stack, Sanguine/Volcanic avoidance | Deaths to avoidables |
| Cooldowns | Heroism timing, defensives on mechanics | Wrong phase, wasted CDs |
| Kill Order | Focus targeting, add priority | Adds live too long, healer OOM |

**Example setup:**
```
Aggression: Yolo
Interrupts: 3 | Positioning: 1 | Cooldowns: 2 | Kill Order: 0
```

The event log directly punishes starved categories — players see exactly why the zero hurt them.

---

**Design rules:**
- Tactics screen should take under 2 minutes to set
- No single correct answer — only correct answers for this dungeon/affix combo
- Full conditional rule builder (PoE-style) graduates to GOAT main game

---

### 6. Auto-Battle Replay

You don't play the dungeon. You watch it.

**Replay features:**
- Variable speed (1x, 2x, 4x, 0.5x for that one death)
- Pause + scrub timeline
- **Event log** — timestamped in-universe flavor text
- **Death report** — cause, what tactic failed, morale impact
- **Parse overlay** — actual vs. expected output per player
- **Highlight reel** — auto-generated best moments and biggest mistakes
- **Filter toggles** — show/hide Monster damage, Party damage, Heals, Mechanics

---

#### Hit Quality System (LOCKED)

Every attack event in the tick sim rolls one of four outcomes. These are real sim variance, not log decoration — crits and dodges change damage dealt and taken:

| Outcome | Effect | Log Color |
|---|---|---|
| Normal | Standard damage | White |
| Critical | 1.5–2x damage (uniform roll) | Yellow |
| Glancing | Half damage — one of the two avoid rolls landed | Gray |
| Dodged | Zero damage — both avoid rolls landed | Dark gray |

Each incoming hit first rolls **crit** (attacker side), then rolls the defender's **avoid chance twice**: both succeed → **Dodged** (zero damage), exactly one → **Glancing** (×0.5), neither → full hit. The double roll keeps *average* mitigation identical to a single avoid roll but cuts its variance — glancing is the frequent, low-stakes log event; a clean dodge is the rare lucky moment. Base rates: 5% crit (×1.5–2), 10% avoid per roll (→ ~18% glancing, ~1% dodge). Crit rating raises crit chance; Versatility raises avoid chance and reduces damage taken. The Aggression dial widens or narrows the crit tail: Yolo +5% crit (spikier), Safe −3% crit (consistent baseline). (Secondary-stat gear is Phase 2; in the MVP only base rates and the dial apply.) *(Double-roll-with-glancing model borrowed from the reference game — see EGM-Reference-Analysis.md.)*

---

**The event log is written in-universe:**

> *[1:47] Grymdark the Rogue ignored interrupt assignment. Cast went through.*
> *[1:48] Half the party is now polymorphed.*
> *[1:49] Grymdark typed "mb" in party chat.*
> *[1:52] Grymdark has left the dungeon.*

> *[3:12] Svenrik stood in Sanguine. Again.*
> *[3:13] Healer is out of mana.*
> *[3:14] Party wipe. Morale: -20. One member is now "questioning their life choices."*

---

### 7. Gear System

**Equipment slots (LOCKED):** every character has 6 slots — Weapon, Helm, Chest, Legs, Boots, Trinket. **Character Item Level = average of the 6 equipped items.** Items are spec-tagged (each item lists which specs can equip it), and the ~10-item dungeon loot tables are distributed across these slots.

- Gear drops at end of dungeon; **drop ilvl = 100 + 5 × key level** (a +6 key drops ilvl 130). New characters start at ilvl 105 in every slot
- **Stat secondaries** — Crit / Haste / Mastery / Versatility (Phase 2 — MVP gear is slot + item level only. Crit and Versatility hook into the Hit Quality System; Haste and Mastery hooks are an Open Questions item)
- **Tier set bonuses** — 2pc and 4pc per class (bonus content not yet designed — see Open Questions)
- **Crafted gear** — spend Shards at the crafting bench to target specific stats (Phase 2)
- **Corruption (Legendary / season-end sink, Phase 2)** — a one-way gamble on a finished item: reroll all stats, shift each up or down a tier, or stamp a corruption-only mod from an overpowered pool (above normal stat caps), after which the item is locked from further crafting. This is what a Legendary's "unique mods" *are* mechanically — passive stat-style mods beyond normal caps — and it gives the economy a true endgame sink. (Vaal-orb model from the reference game.)
- **Vault** — best timed key of the week gives one bonus item choice

Loot drama is a **mechanic**. Two roster members want the same item — you decide. The loser's morale drops (-5). The winner gets a +5% output buff for their next run. Classic.

---

### 8. Online Leaderboard

The competitive layer. Season-based, resets periodically. All weekly systems (affix rotation, vault, recruitment board, weekly ranking) run on **real-world calendar weeks**, server-synchronized. Runs per week are unlimited.

**What's tracked:**
- **Highest key timed** per dungeon (like Raider.io)
- **Overall Mythic Rating** — sum of each dungeon's best score (formula in the Simulation Spec)
- **Weekly ranking** — best key timed that week globally
- **Guild ranking** — compare with friends' rosters

**Leaderboard display shows:**
- Player name + rating score
- Highest key level timed
- Roster composition used
- Key affix combination

This is the **replayability engine**. Seeing someone time a +18 Ashveil Crypts on Tyrannical week makes you want to figure out how.

**Integrity (Phase 2 feature, Phase 1 constraint):** the sim must be fully deterministic given a run seed. In Phase 2, seeds are server-issued at run start and submitted runs are validated by server-side re-simulation of the serialized inputs (roster, gear, talents, tactics, affixes, seed). Honoring this in Phase 1 costs nothing — use a seeded PRNG from day one — but it cannot be retrofitted if the MVP sim ships on raw randomness. Accounts/identity and friend/guild grouping are also required here and are not yet designed — see Open Questions.

**Persistence:** saves and submitted runs serialize as **plain JSON** (roster, gear, talents, tactics, seed), never engine-native objects — this keeps server-side re-simulation and save migrations cheap, and is decided now because the data model is load-bearing for both. (The reference game serialized engine resources and paid for it with repeated migrations.)

---

### 9. Guild Infrastructure (Light Layer)

| Building | Effect |
|---|---|
| Flasks & Cauldron | Party gets consumable stat buffs |
| War Room | Replay shows additional combat data |
| Coaching Corner | Reduces low-morale negative-trait amplification (×1.5 → ×1.25) |
| Recruitment Board | Access higher potential recruits |
| Morale Officer | Passive morale recovery between runs |

---

### 10. Progression Structure

**Season format:**
- 6 dungeons per season
- A season affix (always active, changes meta)
- Mythic Rating target for season reward
- Leaderboard resets each season

**Weekly cadence:**
- Affix rotation changes weekly (forces build adaptation)
- Vault reward for best key
- New recruits available on roster board

---

## Dungeon Roster (6 Base Dungeons)

Names feel like real WoW locations — faction history, geography, event. No winking.

| # | Name | Theme | Signature Mechanic |
|---|---|---|---|
| 1 | Ashveil Crypts | Undead catacombs beneath a fallen city | High undead density, Bursting-punishing |
| 2 | Ironhold Garrison | Abandoned military fortress, now occupied | Patrol routes, dangerous pull timing |
| 3 | The Sunken Reliquary | Partially flooded ancient vault | Positional hazards, Sanguine-punishing |
| 4 | Brackwater Mines | Haunted mining complex, volatile gas pockets | Environmental damage, tight corridors |
| 5 | Thornwall Bastion | Besieged outer wall, multiple factions fighting | Faction aggro mechanic, chaotic pulls |
| 6 | Cinderpeak Sanctum | Volcanic temple, fire cult + elemental forces | Volcanic affix synergy, heavy movement |

Each dungeon has:
- ~4 boss encounters
- 2–3 distinct mob types requiring different tactics
- 1 optional elite encounter (skip it, or spend ~90 seconds of timer for a guaranteed bonus item + 1 emblem — a 3rd item on a timed clear)
- A signature environmental hazard

---

#### Ashveil Crypts — Bosses (LOCKED — MVP content)

The four bosses sit at sim stages 2, 4, 6, and 8, and each audits a different tactics category — the MVP dungeon doubles as the tutorial for reading the event log.

| # | Boss | Encounter | Tests |
|---|---|---|---|
| 1 | Sexton Caldew | The crypt's undying caretaker, still working. **Grave Detail** summons digger adds throughout the fight — and every add death feeds Bursting on Bursting weeks | Kill Order |
| 2 | Embalmer Vesk | Alchemist of the dead. Channels **Preserving Fume** — a party-wide damage-over-time cast that must be stopped | Interrupts |
| 3 | The Unmourned | The city's unclaimed dead, fused into one shape. Drops **Pooling Sorrow** under characters; standing in it is avoidable damage | Positioning |
| 4 | Othrend, Last of the Interred Kings | Final boss. Rises from the catafalque; **Final Coronation** is a timed damage-spike phase, with burn windows between | Cooldowns |

Boss abilities are per-dungeon data consumed by the tick sim: Grave Detail spawns real mobs (trash for affix purposes — Kill Order's kill plan applies), Preserving Fume is a dangerous cast (Interrupts roll), Pooling Sorrow is an avoidable event (Positioning roll), and Final Coronation is a spike phase (Cooldowns mitigation) with burn windows between (Cooldowns damage bonus).

---

## What Makes This Different from the PoE Game

| Exiled Guild Manager | GOAT Lite M+ Manager |
|---|---|
| Serious tone, faithful to PoE | Satirical, WoW culture commentary |
| Individual exile builds | Party composition puzzle (5-man) |
| Exploration/scouting missions | Key selection + affix strategy |
| Passive tree per exile | 3-choice talent nodes per spec |
| Map system | Key level + Mythic Rating progression |
| Morale system | Morale + Personality Trait drama |
| Desktop/itch.io | Browser + online leaderboards |
| No meta-commentary | The event log IS the meta-commentary |

---

## MVP Scope (Phase 1 — Browser Proof)

- 1 dungeon (Ashveil Crypts), including its optional elite encounter
- 3 specs (Guardian/Tank, Cleric/Healer, Berserker/Melee DPS)
- Key levels 2–10, single keystone starting at +2
- 2 affixes (Fortified + Bursting)
- **Tactics in:** 6 tactics points + Aggression dial — Bursting's counterplay is Kill Order, so it cannot ship without them. Behavior profiles deferred to Phase 2 (one fixed comp makes them near-meaningless)
- 3-choice talent nodes — the 2 generic decision points (Node 1 + Node 2), shared by all 3 specs
- **Calling the run** — the mid-run bank-and-leave decision (depleted, keep loot) vs push-and-risk-wipe (forfeit loot)
- **Morale fully in, departure disabled by flag:** morale moves per the locked table (incl. boredom + thrilling-victory) and feeds the 3-band output multiplier and loot drama; the broken-morale state and warnings ship, but the leave-at-0 roll is flag-disabled until Phase 2
- Text-based event log replay (no visuals yet) — a filtered readout of real tick-sim events, not synthesized flavor
- Basic gear drops + item level (6 slots; no secondaries, crafting, or vault yet)
- 5 pregenerated roster members (1 Guardian / 1 Cleric / 3 Berserkers), no personality traits yet — Initial Draft ships in Phase 2
- Deterministic seeded sim from day one (Phase 2 leaderboard validation depends on it)
- Local score saving (leaderboard in Phase 2)
- **Build principle:** systems cut from Phase 1 ship behind disabled flags rather than half-wired (as the morale departure roll already does), so Phase 2 flips a constant instead of rebuilding

---

## Simulation Spec (LOCKED — v1 tuning values)

The sim is an **event-level tick simulation**: it steps through the run in 1-second ticks, generating discrete events — attacks, casts, interrupts, mob deaths, character damage/healing, deaths, affix triggers. The event log, death report, and parse overlay are **filtered readouts of this real event stream**, never post-hoc flavor. The sim is **fully deterministic given a run seed** (seeded PRNG; the seed is stored with every result — required for Phase 2 leaderboard validation).

**Result container.** The sim runs to completion in one pass and emits a single **RunResult** (outcome, duration, seed, the typed event log with per-event detail — including a per-stage damage-mitigation breakdown — plus per-character aggregates and per-stage snapshots). Every review surface (event log, death report, parse overlay, highlight reel, the War Room building) is a **pure read of that container**, never re-derived. This is the architecture that makes Phase 2 server re-simulation a drop-in: revalidating a submitted run = re-running the sim on the serialized inputs + seed and comparing the RunResult. (Pattern proven by the reference game.)

Numbers below are v1 tuning values, not aspirations: the **Dungeon Timer table is the acceptance test** — constants get retuned until a key-appropriate team at balanced tactics with 0 deaths clears in ~80% of the timer.

---

### Dungeon Structure
Each dungeon runs 8 stages in order:
```
Trash Pull → Boss → Trash Pull → Boss → Trash Pull → Boss → Trash Pull → Final Boss
```
- Trash stage = one pack of 4–6 mobs (count, HP, damage, and abilities are per-dungeon data)
- Boss stage = one boss (HP, damage, and abilities are per-dungeon data). Boss-summoned adds count as trash for affix purposes — Fortified scales them and their deaths feed Bursting/Bolstering/Sanguine — while the boss itself takes Tyrannical
- Mob HP/damage scale **×1.05 per key level above 2** (compounding), then ×1.3 Fortified (trash) or ×1.3 Tyrannical (bosses)
- Optional elite encounter sits between any two stages: difficulty midway between a trash pack and a boss (~90s for an on-level team), rewards a guaranteed bonus item (added to the run's loot) + 1 emblem. Skip or fight is a real timer-vs-loot decision.

---

### Character Model

Every character has HP, per-tick damage/healing, and (healers) mana — all derived from **Character Item Level** (average of the 6 equipped slots). "Appropriate ilvl" for a key = that key's drop ilvl (100 + 5 × key level).

| Role | Damage | HP | Special |
|---|---|---|---|
| Tank | 0.5 × ilvl per tick | 15 × ilvl | Holds threat — mobs attack the tank by default. Mitigation is **ratio-based**: damage taken ×(1 − reduction), reduction = (armour/hit)/(armour/hit + 10) capped at 0.9, armour = 8 × ilvl |
| Healer | 0.3 × ilvl per tick | 10 × ilvl | Heals lowest-HP ally at 1.2 × ilvl HPS; mana 100, heal cast costs 4, regen 1/s — long pulls genuinely OOM the healer |
| DPS | 1.0 × ilvl per tick | 10 × ilvl | — |

This is where comp trade-offs come from: tankless comps route mob damage onto unmitigated characters; heal-heavy comps trade kill speed for sustain; Defensive comps split threat across two mitigated targets.

**Why ratio armour** (replacing a flat ×0.6): big hits punch through and chip is absorbed, so a Tyrannical boss spike threatens the tank without separate tuning while trash stays survivable — one curve replaces two knobs. Non-tank roles carry no armour; their defense is Positioning and not standing in things. The armour coefficient (8) is a v1 value pinned to the timer table. (Curve borrowed from the reference game.)

**Per-tick character output** (the Output formula, now a damage rate):
```
DPS = Role damage from the table above   (already ilvl-scaled — e.g. DPS role: 1.0 × ilvl)
    × Talent effects      (nodes apply their printed effects directly — no abstract "efficiency" score)
    × Trait modifiers     (starting + earned traits whose conditions currently hold)
    × Morale modifier     (3 bands: ×1.05 at ≥90, ×1.0 at 50–89, falling linearly to ×0.7 at 0)
    × Aggression dial     (Safe 0.9 / Balanced 1.0 / Yolo 1.15)
```
Behavior Profiles are deliberately not a multiplier: they are the target-selection AI, and their output impact is emergent — hitting the wrong target wastes real damage. To stop per-tick target-thrash, the AI holds a chosen target for a short minimum dwell (~2–3 ticks) before re-evaluating — without this, an Executioner re-picks the lowest-HP enemy every tick and never commits damage. (Sticky-target hysteresis is a known requirement from the reference game's sim.)

---

### Damage Intake & Death

Mobs deal damage per tick to their current target — the tank by default; Spiteful ghosts and boss mechanics retarget. Avoidable damage events (Volcanic eruptions, Sanguine pools, boss mechanics) roll against Positioning; dangerous casts roll against Interrupts (tables below).

**Death is emergent: a character dies when HP reaches 0.** (This replaces the earlier abstract per-pull death roll.) The Aggression dial scales avoidable-damage intake: Safe ×0.7 / Balanced ×1.0 / Yolo ×1.4. Defensive traits modify intake directly (Boomer -25% avoidable-hit chance, Casual Andy never drops below 1 HP, etc. — v1 mappings; the full trait audit is an Open Questions item).

Each death = +5 sec timer penalty (run-back) + the character contributes nothing for 10 sec while rezzed.
All 5 dead = wipe = Depleted, **and the run's loot is forfeited** (the contrast that gives "calling the run" its stakes). Morale -20 for all characters.

**Soft-enrage (anti-stall):** if a single stage runs past 90 sim-seconds, every mob in it gains a stacking +5% damage every 5s until the stage resolves. This guarantees a degenerate stalemate pull (healer sustain ≈ mob damage) ends decisively instead of hanging — the timer punishes it, the enrage finishes it. (Borrowed from the reference game's Desperation mechanic.)

---

### Tactics Points — Sim Contribution (per point, 0–3 per category)

| Category | Per-point effect | Starved (0) = |
|---|---|---|
| Interrupts | Dangerous cast interrupted at 20% + 25% per point (max 95%) | Casts go through — heavy party damage / CC events |
| Positioning | Avoidable event hits its target at 60% − 18% per point | Deaths to avoidables; Sanguine/Volcanic losses |
| Cooldowns | +4%/pt party damage in boss burn windows; −10%/pt damage taken from boss spike phases and enraged (Raging) mobs | CDs wasted on wrong phase; Raging/Tyrannical spikes hurt |
| Kill Order | +6%/pt effective party DPS on trash and boss-summoned adds (target discipline); sets the kill plan — focus-fire by default, staggered kills on Bursting, evened kills on Bolstering | Adds live too long; healer OOMs |

**Solo Player ruling:** that character's individual checks (interrupt assignments, positioning rolls) use half the party's point benefit.

---

### Affix Mechanics (event-level)

| Affix | Sim Effect |
|---|---|
| Fortified | Trash HP/damage ×1.3 |
| Tyrannical | Boss HP/damage ×1.3 |
| Bursting | Each mob death applies a 4-second stacking party DoT (~1% party HP per stack per second). Focus fire (Kill Order) kills mobs sequentially so stacks stay low; unfocused damage kills several at once and stacks spike |
| Bolstering | Each mob death grants surviving pack mobs +15% HP and damage; Kill Order's kill plan levels mob HP so the pack drops near-simultaneously, minimizing stacks |
| Volcanic | Eruption event under a random character every ~10s on trash; Positioning roll to avoid |
| Sanguine | Dead mobs leave heal pools; mobs standing in one heal 5% HP/s until the pack repositions (delay scales inversely with Positioning) |
| Spiteful | Ghost spawns on each mob death and attacks the lowest-output character; tank pickup and the Peel profile mitigate |
| Raging | Mobs below 30% HP gain +50% damage until death; Cooldowns points absorb the spike, Kill Order kills enraged targets first |

---

### Loot System (LOCKED — WotLK-inspired)

**Per run: items + Emblems of Heroism + Gold.** Loot is partial-credit by outcome: a **timed** clear drops **2 items**, a **depleted** clear (timer expired, party survived) drops **1** — you keep what you earned — and the weekly **vault** choice requires a **timed** clear. The optional elite's bonus item is added to whatever the run yields, so it survives a depleted clear. A **wipe forfeits the run's loot entirely**, which is what gives Calling the Run its stakes.

#### Item Quality Tiers (WoW Color Coding)

| Tier | Color | Source | Stats |
|---|---|---|---|
| Poor | Gray | Scrap-only drops at very low keys | No stats — disenchant value only |
| Common | White | Low key fillers | 1 primary stat |
| Uncommon | Green | Key +2 to +5 | 1 primary + 1 secondary |
| Rare | Blue | Key +6 to +15 | 1 primary + 2 secondaries |
| Epic | Purple | Key +11+ (occasional), +16+ (common), and Vault rewards | 1 primary + 3 secondaries |
| Legendary | Orange | Very rare drops + season-end rewards | Unique mods, top stat values |

| Key Level | Most Common Drop Tier |
|---|---|
| 2–5 | Uncommon (Green) |
| 6–10 | Rare (Blue) |
| 11–15 | Rare / occasional Epic |
| 16+ | Epic (Purple), rare Legendary chance |

- Items roll from a dungeon-specific loot table (10–12 items per dungeon, slot-based — Ashveil Crypts' table is authored below; the other five dungeons are Phase 2 content, see Open Questions)
- Secondaries: Crit / Haste / Mastery / Versatility
- Player assigns both items — if two characters want the same piece, player decides, loser's morale drops
- Unwanted items → scrapped into **Shards** (crafting material)
- Quality tier color is visible immediately on the item icon — players read drop value at a glance
- **Tier is derived from secondary count, not a separate roll** — Green = 1 secondary, Blue = 2, Epic = 3. So adding a secondary at the crafting bench *is* the tier upgrade (a Blue that gains a 3rd secondary becomes an Epic), and drops and crafting share one rule. (Reference-game unification.)

**Emblems of Heroism:**
- Timed run: 5 emblems
- Depleted run: 2 emblems
- Vendor sells specific BiS items for 30–50 emblems

**Currency faucet model:** Gold (and any per-mob currency) drops as expected-value-per-mob (`floor(amount)` + a chance for the fractional remainder) plus rare global bonus rolls, not fixed lumps — so partial/depleted runs accrue gold proportional to how far you got, and the faucet stays smoothly tunable. Emblems remain the flat completion reward above (5 timed / 2 depleted). (Pattern from the reference game.)

**Shards (Phase 2 crafting bench):**
- **Salvage yield scales with quality:** scrapping gear gives Shards = (number of secondaries) × (1 + key band) — a junk Epic (3 secondaries) shards for far more than a Green, so a wrong-spec drop the loot-drama loser receives still feels rewarding.
- **Crafting cost scales with item level:** rerolling or adding a secondary costs Shards = effective key level, i.e. (ilvl − 100) / 5 — an endgame piece costs more than a leveling one, auto-scaling the sink with progression.
- The bench shows the **exact weighted odds** of each secondary outcome before you commit — crafting is an informed decision for the theory-crafter, not a slot machine.

*(Cost = f(item level), quality-scaled salvage, and transparent pre-commit odds are all lifted from the reference game's crafting loop.)*

**Loot Goblin trait resolution:** loot is pre-rolled (hidden from the player) at run start; Loot Goblin's +15% output applies when the pre-roll contains an item this character can equip at a higher item level than their current piece in that slot.

---

#### Ashveil Crypts Loot Table (LOCKED — MVP content)

Items are **templates**: name + slot + eligible specs. The drop roll assigns item level (100 + 5 × key level) and quality tier by key band — the same template drops as a Green at +3 and a Blue at +8. Spec tags below are MVP-era and widen in Phase 2 as the other seven specs arrive (e.g. Guardian/Berserker armor gains the Crusader tag). Trinkets are stat sticks — on-use and proc effects are deliberately **not a system** in this design; the Legendary tier's "unique mods" are passive stat-style modifiers, not procs.

| # | Item | Slot | Specs (MVP) |
|---|---|---|---|
| 1 | Bastion of the Barrow March *(sword and shield)* | Weapon | Guardian |
| 2 | Scepter of Quiet Rest | Weapon | Cleric |
| 3 | Ashveil Cleaver *(two-handed axe)* | Weapon | Berserker |
| 4 | Faceguard of Interred Kings | Helm | Guardian, Berserker |
| 5 | Pale Mitre of Ashveil | Helm | Cleric |
| 6 | Cuirass of Interred Kings | Chest | Guardian, Berserker |
| 7 | Shroudweave Vestments | Chest | Cleric |
| 8 | Legplates of the Barrow March | Legs | Guardian, Berserker |
| 9 | Shroudweave Leggings | Legs | Cleric |
| 10 | Treads of Quiet Rest | Boots | Guardian, Cleric, Berserker |
| 11 | Vial of Crypt Dust | Trinket | Guardian, Cleric, Berserker |
| 12 | Icon of Pale Mercy | Trinket | Guardian, Cleric, Berserker |

The shared suffixes are deliberate set voice, the way a real dungeon's loot speaks one dialect: *Interred Kings* plate, *Barrow March* warfront pieces, *Shroudweave* cloth, *Quiet Rest* for the things that touch the dead.

**Contest design is deliberate.** The MVP roster (1 Guardian / 1 Cleric / 3 Berserkers) means the three Berserkers fight over items 3, 4, 6, and 8, and everyone wants 10–12. Loot drama needs collisions — a table where every drop has exactly one owner would kill the mechanic.

**Starter gear:** every recruit arrives in generic White (Common) "Beta Standard Issue" pieces at ilvl 105 in all six slots — bottom-of-the-ladder quality, replaced within the first few runs. (White, not Gray: the Poor tier is scrap-only with no stats, and equipped starter gear must feed the ilvl-driven Character Model.)

---

### Mythic Rating
```
Dungeon Score = Key Level timed × Time modifier
Time modifier = 1.0 (timed) + 0.1 bonus per 5% time remaining
Total Rating = sum of best score per dungeon
```
Both Fortified and Tyrannical scores are tracked separately per dungeon (they feed the leaderboard display and weekly ranking); a dungeon's contribution to Total Rating is the **higher** of its two affix scores. Leaderboard ranks by Total Rating.

---

## Open Questions

*The MVP (Phase 1) is fully specified. The following systems are referenced by the design but intentionally not yet designed. None block Phase 1; the first group must be designed before the Phase 2 features that depend on them:*

**Design before Phase 2:**
- **Tier set bonuses** — 2pc/4pc content for all 5 classes, plus set-piece allocation in loot tables
- **Loot tables and boss rosters for the remaining five dungeons** — 10–12 item templates each (name + slot + spec tags) plus ~4 named bosses with tactics-mapped signature abilities, themed per dungeon, following the Ashveil Crypts pattern
- **Ongoing recruitment economy** — Trade currency and prices, the "guild progression" metric that scales Recruitment Board quality (and its interaction with the Recruitment Board building), Dungeon Rescue trigger and accept/decline flow, and departure absorption (what happens when 0-morale departures outpace the one-candidate-per-week board)
- **Gold sinks and Guild Infrastructure costs** — gold currently has no spend; buildings have no prices or unlock conditions
- **Trait↔sim reconciliation pass** — damage types (Mechanic Master), final low-morale amplification values, Net Budget tuning, and a full audit of every trait effect against the tick sim
- **Leaderboard integrity stack** — accounts/identity, friend and guild grouping, server-side re-simulation of submitted runs (the Phase 1 deterministic-seed requirement exists so this stays buildable)
- **Secondary stat hooks** — Haste and Mastery sim hooks and rating-to-percent conversions for all four secondaries (Crit and Versatility already hook into Hit Quality; Shard costs and reroll rules are now specified in the Loot System)
- **Keystone dungeon targeting** — the v1 ruling re-rolls the keystone to a random dungeon on level change; decide whether any Phase 2 lever lets players aim it at a specific dungeon ("Select Key" as a strategic choice depends on this)

**Candidate mechanics (from the reference analysis — evaluated, deferred, not adopted):**
- **Capture → rescue** — a wipe captures a roster member and spawns a time-limited bespoke rescue key, turning failure into urgent content. The reference game's strongest narrative system; deferred to keep scope tight, revisit post-Phase-2.
- **Scar-count death ramp** — escalating permadeath risk as an overlay on earned traits (0 scars never dies → 3/8/15/35/60% per accumulated scar). A more legible push-or-retire risk meter than flat per-trait death modifiers; deferred.

**Later:**
- Season structure and roster persistence
- Mobile browser optimization (desktop browser only for MVP)

---

*DawnforgeGames — GOAT Lite: Mythic+ Manager — Concept v1.10 — v1.5: sim core respecified as a deterministic event-level tick simulation; MVP scope ruled on tactics, morale, roster, and keystone; equipment slots, morale numerics, key acquisition, and elite stakes defined; undesigned post-MVP systems moved to explicit deferrals. v1.6: Ashveil Crypts loot table authored (12 original item templates + starter gear); remaining dungeon tables deferred. v1.7: Ashveil Crypts boss roster authored (4 bosses, one per tactics category); boss-summoned adds ruled trash for affix purposes. v1.8: folded in reference-analysis findings — Potentials fully designed (closes open question); Hit Quality switched to double-roll-with-glancing; morale gained a high-morale band, boredom, thrilling-victory, and feature-flagged departure; ratio-based tank armour; soft-enrage + RunResult container + sticky-target in the sim; Shard salvage/craft costs specified; partial-credit loot + Calling the Run added; capture→rescue and scar-ramp evaluated and deferred. v1.9: folded in the remaining reference recommendations — buildable + spec-conditional morale, tier = derived stat count, draft pity floor, recruit level-pegging, Legendary corruption sink, fractional currency faucet, JSON persistence, and feature-flagged cut systems as a build principle (pause-on-blur dropped as Godot-web-specific). v1.10: Assassin corrected to Front / Melee DPS; all 24 traits re-flavoured into GOAT main's satirical archetype voice (effects unchanged) with Archetype + Net Budget columns drawn from the `PossibleTraits` set*
