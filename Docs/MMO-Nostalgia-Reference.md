# MMO Nostalgia Reference — GOAT Lite Design

A survey of the most iconic **dungeons, classes, skills, items, and bosses** across the major MMOs
(WoW + all expansions, FFXIV, GW2, ESO, Lost Ark/BDO, RuneScape/OSRS, EverQuest, FFXI, SWTOR, Rift,
WildStar, New World, TERA, Aion), distilled into design hooks for GOAT Lite and **recast into the
game's own gothic-fantasy voice**. Use it as a naming/feature reference when authoring content.

> **Source:** multi-agent research sweep + two synthesis passes (2026-06-20). The cross-MMO facts are
> grounded in community "most iconic / most memorable" sources; the design proposals are original and IP-safe.

---

## 0. The two-layer principle (read first)

GOAT Lite has **two naming registers** that must never bleed into each other:

- **In-world content** — dungeons, bosses, classes, skills, items, affixes — is **earnest dark/high
  fantasy** in the *Ashveil Crypts* register. The names mean their dread literally; never a wink.
- **The wrapper** — you, the burned-out guild manager who "reviews the pull," gears bots, recruits,
  reads reports — is **where ALL the QA/corporate satire lives**, together with the bot-personality
  traits ("Boomer", "Casual Andy", "Parse Goblin").

So: an epic item is **not** "Won't Fix." Rarity is the **standard Common / Uncommon / Rare / Epic /
Legendary** ladder. The joke is the *frame around* the fantasy, not the fantasy itself.

**The technique everywhere below:** *keep the silhouette, rename the noun.* Preserve the recognizable
MMO mechanic + one tested tactic; only the proper noun and flavor become original. Trademarked anchors
(Frostmourne, Atiesh, Bloodlust…) live in design notes, **never** in a shipped `name` field.

---

## 1. The 8 universal laws of MMO nostalgia

Distilled from every game's "what makes it memorable" takeaways:

1. **Signature "verbs" over stat-blocks** — sheep, grip, bubble, lust, charge, feign, rez. Single
   recognizable *actions* become shared vocabulary. (The #1 takeaway in WoW, GW2, SWTOR, ESO.)
2. **Make the boss SAY something** — a quotable line turns a fight into a cultural artifact; pay off a
   lore-villain after years of buildup (Arthas, Illidan, Molag Bal, Emet-Selch).
3. **Place-as-memory + the "first dungeon" imprint** — Deadmines/Fungal Grotto loved for being *where
   you started*; Karazhan/Blackrock Depths are "places you lived in."
4. **The public timer / status loot** — the M+ clock, the leaderboard, gear that is *visible proof*
   (Thunderfury, Atiesh, Fire Cape). The best item makes the **owner** matter to the group.
5. **The saves and the trolling, not the rotation** — the most-retold stories are the oh-no buttons and
   the disasters (bubble-hearth, Feign Death, Benediction clutch, the Onyxia wipe recording).
6. **Build-freedom = ownership** — Rift's 3 souls, GW1 primary/secondary + 8-skill bar, OSRS skill-not-class.
7. **Untradeable proof-of-mastery + exclusivity** — Fire/Infernal Cape, vMA, Mage Tower, pre-nerf C'Thun.
   The pain *is* the bond; "I was there" is the flex.
8. **Scarcity & the gamble manufacture the memory** — Baron's mount, Twisted Bow, BDO PEN/failstacks.
   The memory is the *hundreds of failed attempts*, not the item.

**Strategic consequence for GOAT Lite:** nostalgia lives in **text and social drama** — exactly what a
log-driven auto-battler delivers cheapest. Spend most on **log lines, named loot, and renamed signature
verbs**; the expensive 3D/kinesthetic nostalgia (flight, action combat, telegraph dodging) is irrelevant
to this format and should be skipped.

---

## 2. Affixes — rename table (the concrete IP fix)

`data/affixes.json` currently ships **8 verbatim Blizzard M+ affix names**. Keep every effect and the
`punishes` mapping; rename the noun into the Ashveil register.

| Current (verbatim WoW) | → Fantasy name | Effect (kept) | Punishes |
|---|---|---|---|
| Fortified | **Barrow-Bound** | Trash HP/dmg ×1.3 | output |
| Tyrannical | **Crowned in Ash** | Boss HP/dmg ×1.3 | cooldowns |
| Bursting | **Plaguebloom** | Stacking party DoT per death | killorder |
| Bolstering | **Wake the Kin** | Survivors +15% per death | killorder |
| Volcanic | **Pyre-Vents** | Eruption under a target (~10s) | positioning |
| Sanguine | **Lifeblood Mire** | Corpses leave enemy-heal pools | positioning |
| Spiteful | **Restless Shade** | Ghost on death hits lowest-output | behavior |
| Raging | **Death-Frenzy** | Mobs <30% HP enrage +25% haste | cooldowns |

**New original affixes** (same spirit; each maps to one tactic):
- **Gravechill** — hits apply stacking healing-reduction that decays out of melee → *positioning*.
- **The Tolling** — a periodic crypt-bell silences anyone mid-cast → *interrupts*.
- **Pale Omen** — a grave-wisp rises and must be killed/banished before it reaches a hero → *killorder*.
- **Censer's Breath** — Vesk's incense lingers where mobs fall, draining + fogging targeting → *behavior*.

---

## 3. Dungeons (fantasy-named; one tested tactic per boss)

Two-word grim place + decay modifier, tuned to sit beside *Ashveil Crypts*.

| Dungeon | Archetype / evokes | Marquee boss + tactic |
|---|---|---|
| **The Tanglewood Warrens** | Affectionate first dungeon (Deadmines/Fungal Grotto) | *Coyle the Cutpurse* — killorder. The +2 floor's home; one slow-telegraphed tactic per boss. |
| **Greywither Manor** | Haunted/cursed (Karazhan, Scarlet Monastery) | *The Weeping Governess* — interrupts; *Lord Greywither, Framed in Oil* — behavior |
| **The Emberthroat** | Wave-gauntlet knowledge-check (Titan-EX, Jad) | *Vurl, the Banked Ember* — behavior. Final breath = a Composure cooldown call. |
| **Stillhour Abbey** | Clock-pressure run (Strat Baron) | *Abbot Vane, Keeper of the Hour* — cooldowns. The signature time-attack. |
| **Blackmarrow Deep** | Mega-dungeon, named sub-areas (Blackrock Depths) | Sub-areas: *Tapped Vein · Cold Forge · Debtors' Ring · Sunless Market · Marrow Throne.* *Regent Holdfast* — cooldowns. |
| **The Glutting Hollows** | Trash gauntlet/attrition (Lower Guk) | *The Overfed* — behavior. Healer-attrition crucible. |
| **The Ashen Spire** | Climbed fortress (ICC, Aion) | *Wraith of the Ninth* — positioning. "Floor 6/9" header = progress bar. |
| **Saltmere Reliquary** | Seasonal rotating pool + hub | Hub **Wend's Rest** (tide-board posts the season's vaults). *The Tideglass Keeper* — behavior. |
| **The Sundered Accord** | Coordination council (Ulduar council) | *The Broken Arbiter* — positioning. Interrupt-assignment showcase. |
| **Hollowroot Barrow** | Green-rot sister to Ashveil (Razorfen/Maraudon) | *Mother Hollowroot* — killorder ("replants from your dead"). |

*Build-first picks beyond the starter: **Greywither Manor** (quotable villain = screenshot value) or
**Stillhour Abbey** (the clock makes the report self-mocking — feeds the wrapper).*

---

## 4. Bosses ("make it SAY something"; all six archetypes)

Each: name + tactic + an original quotable bark.

**A — Mechanic-dance (positioning)**
- *Maelor, the Tithe-Warden* — *"Step where I have not yet been — the rest is owed to me."* (Heigan Safety Dance)
- *The Choirmaster of Wane* — *"Sing in your assigned colour, or be silenced."* (GW2 Vale Guardian)

**B — Lore-villain payoff (killorder)**
- *Othrend's Herald, the First to Kneel* — *"You came for the crown. You will not survive the messenger."* (Illidan gatekeeper)
- *Vaelith, the Unburied Flame* — *"Too early. You have come for me far, far too early."* (Ragnaros "TOO SOON!")

**C — Enrage timer (cooldowns)**
- *Gravewright Holm, the Patient Mason* — *"I have laid every stone but the last. Hold still."* (Patchwerk)
- *The Hollow Tally* — *"Forty and nine remain. Then nine. Then none."* (C'Thun/Brelshaza escalation)

**D — Multi-phase transformation (cooldowns)**
- *Vesk's Final Draught* — *"Hold — I am not finished becoming."* (Kael'thas Phase 5)
- *Aurevant, Mask of Seven Sorrows* — *"This sorrow is spent. Meet the next."* (mask-swap phases)

**E — Stand-in-fire (positioning)**
- *Ifareth, the Kindling Saint* — *"Kneel outside the light. The blessing is only for the deserving."* (Ifrit/telegraphs)
- *The Lurching Cinder* — persistent, shrinking void-zones

**F — Gimmick fight (behavior / interrupts)**
- *The Sleepless Mirror* — *"I have your face now. Shall I keep it?"* (Yogg sanity / Mind Control)
- *Warden Cael, Keeper of the Quiet Bell* — *"Let it toll once, and I wake the whole barrow."* (Mimiron red button)
- *Nethriel, the Choir of One* — interrupt-the-right-cast puzzle

---

## 5. Skills — the missing signature verbs (mapped to fixed specs)

The highest-nostalgia gaps in the current ability set, named in-world:

| Ability | Spec / Role | Operator skill | Verb it evokes |
|---|---|---|---|
| **Calling Back the Quiet** | Cleric / Healer | Composure | **Battle rez** ("do you have rez?") — binds to existing `sim.rez*` |
| **Lay On the Last Light** | Cleric / Healer | Composure | Single-target panic full-heal (Lay on Hands) |
| **Barrow-Step** | Guardian / Tank | Execution | Engage/gap-close (Charge) |
| **Drag to the Dust** | Guardian / Tank | Awareness | Forced reposition (Death Grip) |
| **Walk Among the Dead** | Assassin / DPS | Awareness | Threat-drop (Feign Death) |
| **Bind the Barrow-Hound** | Mystic / Tank | Awareness | Summon companion (Hunter pet) |
| **Cut the Incantation** | Berserker / DPS | Execution | Interrupt/kick |
| **Unbinding Word** | Lifebinder / Healer | Awareness | Dispel/cleanse |
| **Cairn of Quiet Rest** | Lifebinder / Healer | Execution | **Ground-placed buff zone** (Shaman totem — net-new mechanic: a position-anchored status emitter) |

Already covered (don't rebuild): Bard *Overdrive* (= Bloodlust party haste), Guardian taunt (= Death
Grip), Crusader bubble (= Hand of Protection), Berserker Reckless Frenzy (= Metamorphosis), Arcanist
Silence/Freeze (= Polymorph CC). Keep each new verb a **single quotable log line** so callouts become
social ("who's got **Unbinding Word** on the curse?").

---

## 6. Classes & Specs — what fits GOAT Lite

### 6.1 Current roster (fixed: 5 classes × 2 specs)

| Class | Spec | Role | Pos. | Identity |
|---|---|---|---|---|
| Warrior | **Guardian** | Tank | Front | Taunt, stun, thorns |
| Warrior | **Berserker** | DPS | Front | Rampage stacks, cleave, bleed |
| Paladin | **Crusader** | Tank | Front | Party shields, guard, mark cleanse |
| Paladin | **Cleric** | Healer | Back | Disc-style burst heals + absorbs |
| Rogue | **Assassin** | DPS | Front | Camouflage, execute, crit chains |
| Rogue | **Bard** | DPS | Back | Overdrive windows, mark/crit setup |
| Mage | **Pyromancer** | DPS | Back | Burn stacks then detonate |
| Mage | **Arcanist** | DPS | Back | Silence, slows, party barrier |
| Sage | **Lifebinder** | Healer | Back | HoTs, DoT-to-heal, nature shields |
| Sage | **Mystic** | Tank | Front | Parries, stuns, self-sustain |

**Role economy:** 3 tanks · 2 healers · 5 DPS. (Healer is the thin role — additions should favor it.)

### 6.2 Iconic MMO class fantasies → GOAT coverage

| Iconic fantasy (MMOs) | Covered by | Status |
|---|---|---|
| Plate juggernaut warrior (Arms/Fury, Patchwerk tank) | Guardian / Berserker | ✅ |
| Holy warrior, bubble/Lay-on-Hands (Paladin) | Crusader | ✅ |
| "Heal by damaging" Disc Priest | Cleric | ✅ |
| Stealth assassin (Rogue, Nightblade, Deathblade) | Assassin | ✅ |
| Support/buff Bard (FFXIV Bard, GW2 support) | Bard | ✅ |
| Fire mage / arcane scholar (Black Mage) | Pyromancer | ✅ |
| Control mage (Frost/Poly, ESO Sorc) | Arcanist | ✅ |
| Nature HoT healer (Druid Resto, White Mage, Warden) | Lifebinder | ✅ |
| Avoidance/self-sustain martial tank (FFXIV WAR, Brewmaster) | Mystic | ✅ (gestures at Monk) |
| **Death-knight / Necromancer / undeath** (DK, FFXIV Reaper/DRK, GW2 Necro, ESO Necro, EQ Necro) | — | ❌ **biggest gap; perfect world fit** |
| **Warlock — DoT/curse + demon summon + Soulstone** | — | ❌ (folds into the death class) |
| **Hunter / Beastmaster — ranged physical + pet** (WoW Hunter, GW2 Ranger, ESO bear, TERA) | — | ❌ missing combat niche |
| **Shaman — totems + Bloodlust + elemental** | partial (Cairn verb) | ❌ unique ground-verb |
| **Druid shapeshifter — fill-any-role** | — | ❌ versatility fantasy |
| **Monk — fistweaving healer / Brewmaster** | Mystic-adjacent | 🟡 fistweaver-healer gap |
| **Summoner — primal/egi pets** (FFXIV) | — | ❌ folds into pet/death |
| **Pure support / "make others better"** (Aug Evoker) | partial (Bard) | 🟡 |

### 6.3 Recommended additions (prioritized, in-voice)

**① The Necromancer (NEW CLASS — the headliner).** It single-handedly covers the largest cluster of
unmet nostalgia (Death Knight + Warlock + Necromancer + Reaper), and a crypt-and-barrow world is its
*native* setting — no other addition fits Ashveil so naturally. Two specs that also fix the role economy
(add a DPS niche + the thin 3rd healer):

- **Bonecaller** *(DPS, Back)* — wasting curses + lingering DoTs, raises skeletal servants, drains life.
  *Anchors:* Affliction Warlock, EQ Necromancer, GW2 Reaper. *Signature verbs:* **Bind the Barrow-Hound**
  (summon pet — move it here from Mystic if Necro ships), a Soulstone-style **pre-placed battle-rez**
  decision, a stacking wasting curse. The "personal attachment beyond raw numbers" pet-bond hook.
- **Pallbinder** *(Healer, Back)* — the death-priest who heals by drawing the spark from the dying; the
  grim mirror of Lifebinder ("heal through nature" → "heal through death"). *Anchors:* Disc/Shadow Priest,
  FFXIV Scholar's faerie, EQ lich-healing. Fills the **3rd healer** slot the comp economy wants.
  *(Alt, if you'd rather not add a healer: a **Revenant** undeath-tank — DK Blood / DRK "Living Dead" —
  but the game already has 3 tanks, so Pallbinder is the better fill.)*

**② The Houndmaster (NEW SPEC — Rogue, Back, DPS).** Fills the one combat niche GOAT entirely lacks:
**ranged-physical with a permanent beast companion.** *Anchors:* WoW Hunter, GW2 Ranger/Soulbeast, ESO
Warden bear, TERA. In Ashveil: a handler of barrow-hounds and carrion-birds. *Signature verbs:* a named,
persistent pet (the pet-bond nostalgia), traps, and a **Feign-Death** threat-drop. Lighter-touch than a
new class because it slots into the existing Rogue (cunning, physical) — but the pet is a net-new mechanic.

**③ Totemic Sage (NEW SPEC — Sage, 3rd spec).** A **Cairnshaper** support/off-healer built around the
net-new **ground-placed persistent buff zone** (Shaman totems → the *Cairn of Quiet Rest* verb). *Anchors:*
Shaman. Adds the one structural verb no current spec has (drop a thing on the field the party benefits from).

**Further options (lower priority):** a Sage **shapeshifter** spec (Druid fill-any-role versatility); a
Mystic-line **fistweaver** healer (Monk Mistweaver — "heal by punching"); a pure-support DPS (Aug Evoker)
— though Bard already half-occupies that lane.

### 6.4 The structural decision (yours to make)

GOAT's roster is a clean **2 specs per class**. Two ways to grow it:
- **(a) Add a 6th class** (Necromancer, 2 specs) — cleanest; a 6th class signals an "expansion" beat and
  keeps the 2-per-class symmetry. **Recommended for the death fantasy.**
- **(b) Add 3rd specs to existing classes** (Houndmaster→Rogue, Cairnshaper→Sage) — lighter, but breaks
  symmetry (some classes get 3, others 2). Fine for one-off niche fills.

Whatever the path: keep names in the Ashveil register, avoid verbatim trademarks (no "Death Knight",
"Warlock", "Hunter" as shipped class names — *Necromancer*, *Houndmaster*, *Cairnshaper* are all generic
fantasy and clean), and respect the **1-tank / 1-healer / 3-DPS** comp baseline when tuning new specs.

---

## 7. Items & loot (standard ladder + Ashveil register)

**Rarity:** Common / Uncommon / Rare / Epic / Legendary. Legendaries are **public status + group utility**
(the item makes the owner matter).

- **Catafalque Key** — *Legendary mace.* Owner can summon the party to the keystone + a small pre-pull
  Composure buff. (Atiesh) — *"The kings locked themselves in. This opens every door they died behind."*
- **Quiet Hours** — *Legendary off-hand.* Toggles *Vigil* (Composure) ↔ *Wake* (Execution) with a distinct
  swap animation. (Benediction/Anathema duality)
- **Othrend's Repose** — *Legendary 2H, soul-bound,* drops only from Othrend; marks the party's
  priority-kill target. (Frostmourne)
- **The Pale Mercy** — *Legendary 2H axe;* suppresses one boss enrage/behavior escalation per run vs.
  undead. (Ashbringer; ties to existing *Icon of Pale Mercy*)
- **Tier sets** reuse existing names with 2pc/4pc identity: *Warplate of the Interred* (2pc party DR while
  tanking / 4pc lethal-hit refunds a cooldown), *Shroud of the Quiet Blade* (interrupts → damage window /
  kill-order execute), *Regalia of the Ashen Flame* (interrupts refund resource / cooldown-window echo).
- **Animation-hook trinkets:** *Vial of the Second Breath* (Epic; clutch-save pale-light proc),
  *Mourner's Hourglass* (Rare; once-per-run "undo a mistake").
- **The Catafalque Hearse** — *Legendary cosmetic mount, ultra-rare* from Othrend, with a **public attempt
  counter** on your profile. (Baron's deathcharger "didn't drop again")
- **Shroud of the Unmourned** — *Legendary cosmetic cloak, untradeable,* only for timing a high key.
  (Fire Cape proof-of-mastery)
- **Pale Obol** — currency from every timed run → vendor for guaranteed Epic gear; the deterministic floor
  so a run is never wasted. (Badge/Emblem economy)

---

## 8. Where the QA satire lives (the wrapper, not the content)

The manager framing ("review the pull", reports, the self-mocking run score), the bot-personality traits
(Boomer, Casual Andy, Parse Goblin), recruitment flavor, the leaderboard / **server-first race**, and the
pre-pull planning board. Name *player-facing planning* in-world too (e.g. a "Battle Plan" / "Marching
Orders" board for the interrupt/dispel/taunt assignments — the single most on-theme missing mechanic).

---

## 9. Voice cheat-sheet (for naming future content)

- **Shape:** `[grim sacral place-noun] + [of / the + decay-or-grief modifier]`. Word-bank: *barrow, crypt,
  pyre, ash, pale, quiet, interred, mourn, shroud, catafalque, sexton, verger, reliquary.*
- **Earnest, never winking** in-world; the joke is only in the wrapper.
- **Ban the office/Latinate-governance register** as well as tech: no *Quorum, Recess, Custodian (=janitor),
  Mediator, Concordat, Tally-as-ledger* — and never the hard-banned tech list (Outage, Hotfix, Deadline…).
  For "keeper" roles prefer sacral words (*Sexton, Verger, Bellman, Vigil*).
- **Vary stock words** — cap repeats of *Warden / Last / Quiet Rest / Keeper* at ~3 before they read as a template.
- **Keep the silhouette, rename the noun.** Anchors (Frostmourne, Atiesh…) belong in design notes, never in a `name` field.

---

## 10. Prioritized action list

1. **Rename the 8 affixes** in `data/affixes.json` (effects untouched) — the clearest verbatim-trademark
   fix, and it *improves* the flavor. Then grep `data/` for any other verbatim marks.
2. **Invest most in `data/log-templates.json`** — evocative, quotable, renamed-verb log lines for every
   proc, death, clutch save, and disaster. Highest nostalgia-ROI; native to the format.
3. **Rarity ladder + 3–5 named meme legendaries** with a roster/leaderboard badge; fuse each drop to its boss.
4. **One named signature verb per spec**, fired as a logged, anticipated event (the missing rez / panic
   heal / engage / threat-drop / interrupt / dispel / totem).
5. **"Clutch of the Week / Wipe of the Week"** sim highlight flagging → leaderboard. The shareable layer.
6. **The pre-pull assignment board** ("who's on interrupts / dispels / taunt-swaps") — most on-theme missing mechanic.
7. **Classes:** ship the **Necromancer** (6th class, Bonecaller + Pallbinder) as the headline expansion
   beat; add the **Houndmaster** for the ranged-pet niche if a 3rd-spec path is acceptable.
8. **Defer (don't cut):** light upgrade-or-shatter gear gamble, prestige "I-survived" badges, named
   tier-set bonuses, solo "Certification Exam" proving content, attunement gating.
9. **Skip:** scripted class-fantasy cinematics, mounts-as-traversal, flight/telegraph/action-combat — high
   nostalgia, wrong format for a log-driven auto-battler.

---

*Cross-MMO research appendix (per-game highlight reels) available in the workflow transcript; the design
proposals above are the actionable distillation.*
