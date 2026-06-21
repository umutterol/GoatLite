# GOAT Lite — Class-Tools System (the "different tools for different problems" redesign)

**Status:** design locked (2026-06-22), execution deferred. Supersedes the "bring the player, not the class" tuning of
C.10/C.8. **Companions:** `Dungeon-Design-Proposals.md`, `ROADMAP.md` (C.11 audit + the new Phase P below),
`balance-sweep.mjs`/`balance-probe.mjs` (the verification harnesses).

> Generated via a multi-agent design pass (mapped engine feasibility + the balance audit, built a problem taxonomy,
> judged 3 competing 10-spec redesigns, synthesized), then corrected by the user. The corrections are the contract.

---

## 1. The goal (corrected)

**Classes bring DIFFERENT tools to solve DIFFERENT dungeon problems. Class/spec choice MATTERS — bringing the right
tool is a real, rewarding advantage. This is the OPPOSITE of "bring the player, not the class."**

Guardrails so it's *interesting*, not *gatekeeping*:
- **Diversity:** every problem has **2–3 different-texture answers** across ≥2 specs/roles — so no single mandatory roster.
- **Specific, not generic:** the thing that wins must be the dungeon's **specific tool**, never raw survivability. The
  balance audit (C.11) proved generic EHP (2-healer / party-shields / support-auras) was dominating *uniformly* — that
  is the disease this whole redesign cures.

---

## 2. Core balance rules (locked)

1. **A 2nd healer instead of a DPS must NOT beat the timer.** The **timer is a real DPS check** — boss HP + timer tuned
   so ~3-DPS throughput is needed at the ceiling; a 1T/2H/2DPS comp runs out of clock at high keys. (Today it's inverted
   — 2-heal caps *above* 3-DPS — because survival dominates. This rule + the intake floor fix it.)
2. **Intake floor (GATE 0):** stacked shield + DR + HoT can **never** cut effective intake below **40%** of the incoming
   pre-mitigation hit (mitigation caps at a 60% reduction when stacked). A hard `tuning.json` number, not an adjective.
   Starting value 40%/cap-60% — tune via the sweep.
3. **Tool-tax band:** the **right-tool comp caps +3 to +5 keys above a wrong-tool comp**, *but every problem keeps a
   full-substitute alternate* so no single spec is ever mandatory (bringing *one of* its answers is the edge).
4. **Kill-speed / typed checks are un-(generically)-survivable by construction:** school walls are timer checks no HPS
   fixes; curse/rot ticks scale **past** any flat HPS so only the right dispel/HoT-shape resets them; a dangerous cast
   out-paces throughput and stacks to a wipe; a self-healing boss out-paces your DPS without anti-heal.
5. **Typed tools:** dispels (Magic/Curse vs Nature/Poison) and damage schools (Physical vs Magic) are **real status
   fields** — "a cleanse" or "a shield" can't blanket-answer; you need the *right* one.
6. **DPS don't dispel** (consistency — only healers cleanse the party). Offensive *anti-heal* (a debuff on the enemy) is
   a DPS tool and is distinct from a dispel.
7. **No 2nd tank in a normal comp** — so no mechanic may *require* a tank-swap (this kills the tank-buster/taunt-swap
   problem; see §3 P10 = dropped).

---

## 3. Problem taxonomy

Each problem = a concrete thing the party must answer with the right tool. `✅`=works-now · `🔧`=small/medium engine ·
`🚧`=large engine. **P10 is dropped** (taunt-swap needs 2 tanks).

| # | Problem | The demand | Answers (2–3 diverse) | Engine |
|---|---|---|---|---|
| **P1** | **Dangerous Cast** (kick-or-wipe) | A party-nuke cast that stacks to a wipe; out-paces healing | Arcanist (ranged *cancel*) · Mystic (melee *cancel*) · Pyromancer (setup-stun *delay*) | 🚧 cast scheduler |
| **P2** | **Magic-Resist Wall** (bring Physical) | Bosses eat Magic; only Physical moves the bar | Berserker · Assassin · Archer | ✅ |
| **P3** | **Armour Wall** (bring Magic) | Bosses eat Physical; only Magic moves the bar | Pyromancer · Arcanist · Cleric (smite) | ✅ |
| **P4** | **Spreading Curse** (dispel-or-rot) | A removable stacking debuff; wrong/no dispel → rot | Cleric (Magic/Curse) · Lifebinder (Nature) *(healers only)* | 🔧 enemy→party status + dispel typing |
| **P5** | **On-the-Hour Spike** (burst-triage) | Discrete spikes a HoT lands a beat late on | Cleric (reactive instant) · Crusader (proactive absorb) · *Lifebinder deliberately can't* | ✅ (re-validate post-GATE-0) |
| **P6** | **Drowning Tick** (sustained rot) | Flat all-party tick that scales past single-target HPS | Lifebinder (rolling HoTs) · Crusader (rot-keyed DR) · Mystic (peel) · *Cleric weak* | ✅ (re-validate post-GATE-0) |
| **P7** | **Telegraphed Eruption** | An avoidable pulse on a flagged ally | Crusader (immunity *negate*) · Guardian (intercept *relocate*) | 🔧 |
| **P8** | **Dangerous Add** (lock-or-kill) | A summoned add with a denial-worthy cast | Arcanist/Mystic/Pyromancer (CC *lock*) · Assassin/Berserker/Archer (*kill*) | 🔧 (real adds + cast) |
| **P9** | **Empowered / Self-Healing Enemy** | Boss mends itself / has strippable buffs; out-paces DPS | Berserker (anti-heal) · Cleric (purge) · Lifebinder (purge) | 🚧 enemy buffs + self-heal + anti-heal/purge |
| ~~P10~~ | ~~Tank-Buster Stack~~ | **DROPPED** — taunt-swap needs a 2nd tank | — | — |
| **P11** | **Sheltered Caster** (reach) | A back-line mob a melee core can't touch | Assassin (melee *dive*) · Archer/Pyromancer/Arcanist (ranged) · Guardian (*grip*) | 🔧 reach primitive |
| **P12** | **Soft-Enrage Race** | Beat the ramp on raw output | Berserker · Pyromancer · Assassin · Archer (burst) | ✅ |

---

## 4. The cohesive 10-spec toolkit

Every spec owns a quotable signature verb mapped to a problem; the 3 tanks / 2 healers / 5 DPS split with no overlap and
no dead weight. **Bard → Archer** (rogue becomes the physical-DPS class). All in-world verbs stay earnest gothic
(Drag to the Dust, Grave-Wound, Barrow-Step, Unbinding Word); the satire lives in the QA wrapper.

### Tanks (Front)
- **Guardian — the threat anchor + reposition.** Signature: **grip** ("Drag to the Dust" — pull the sheltered back-line
  caster to the front, **P11**) and **intercept** ("Barrow-Step" — relocate a flagged ally off the eruption, **P7**),
  plus holds threat so squishies aren't free-cast on. *(Its old taunt-swap pillar is gone with P10; grip + intercept are
  verbs no redirect can copy.)* Bulwark Banner **deleted** (was a generic party-DR major).
- **Crusader — the transferable bubble.** Signature: single-ally **immunity / 100% redirect** that hard-negates ONE
  incoming event (**P7 negate, P5 proactive absorb**) + a small **rot-keyed party-DR** (the 2nd real **P6** answer, so
  rot weeks aren't Lifebinder-mandatory). Sacred Bastion → single-ally immunity-peel (not a 35% party shield); Divine
  Shield gated to one charge per predictable window.
- **Mystic — the control tank.** Signature: **melee interrupt** (Zen Strike *cancel*, **P1**) + **AoE stun** (Leg Sweep,
  **P8 lock**) + **partial peel** (Spirit Link, **P6**). Survives by **avoidance/lifesteal**, NOT a shield wall (no
  off-heal — caps its EHP smuggling).

### Healers (Back) — split by *shape*, not survival
- **Cleric — reactive burst + Magic dispel.** Signature: **instant spike-top** + overheal→shield (**P5**), **Magic/Curse
  cleanse** (**P4**), atonement **smite** (Magic damage for **P3**), and enemy **purge** (**P9**). Light's Salvation →
  a **strong reactive single-target burst heal, party-shield half removed** (NOT a battle-rez — combat-rez already
  exists). Raw throughput capped so 2 healers buy *safety*, not a higher ceiling.
- **Lifebinder — proactive HoT coverage + Nature dispel.** Signature: rolling **all-ally HoTs** that outlast the drowning
  tick (**P6**), **Nature/Poison cleanse** ("Unbinding Word", **P4** — a *different type* than Cleric), purge (**P9**).
  **Deliberately weak at the P5 spike** (its HoT lands a beat late) so the P5/P6 healer read is a real choice.
  Blossoming Tide → a **rot-keyed HoT that LOSES to a single hard spike** (so it can't double as generic survival).

### DPS
- **Berserker — physical executioner + the ONLY anti-heal.** Physical burst/cleave (**P2**), and "Grave-Wound" a
  -50%-incoming-healing mortal-strike rider that beats a **self-healing boss** a purge can't (**P9**, **P12** burst).
- **Assassin — melee priority-delete + the ONLY melee reach.** Single-target erase (**P8 kill, P12**) and a true **back-
  band dive** reach primitive (**P11**, **P2** physical).
- **Archer — ranged physical sharpshooter** *(was Bard)*. Native **ranged reach** (picks off the sheltered caster, **P11**)
  + physical single-target/focus (**P2**, **P8 kill**, **P12**). **No lust, no dispel** (DPS-consistency). The rogue is now
  the physical class (Assassin melee-dive + Archer ranged).
- **Pyromancer — burn-stack AoE detonator.** Magic AoE for the **armour wall** (**P3**), native ranged (**P11**), and a
  setup-gated stun that **delays** a cast (**P1**) / locks an add (**P8**).
- **Arcanist — the lockdown caster.** The **cleanest ranged interrupt** (**P1 cancel**), mass silence/freeze **add-lock**
  (**P8**), control. Arcane Barrier → **CC-immunity rider only** (party-shield half removed).

---

## 5. Coverage matrix (proof: 2–3 diverse answers per problem; every spec a niche)

```
P1  Dangerous Cast   : Arcanist(cancel-ranged) · Mystic(cancel-melee) · Pyromancer(delay-stun)     [2 roles]
P2  Resist Wall(phys): Berserker · Assassin · Archer
P3  Armour Wall(mag) : Pyromancer · Arcanist · Cleric(smite)
P4  Spreading Curse  : Cleric(Magic) · Lifebinder(Nature)                                          [healers only]
P5  On-the-Hour Spike: Cleric(reactive) · Crusader(proactive)        [Lifebinder cannot — by design]
P6  Drowning Tick    : Lifebinder(HoTs) · Crusader(rot-DR) · Mystic(peel)   [Cleric weak — by design]
P7  Eruption         : Crusader(negate) · Guardian(relocate)
P8  Dangerous Add    : Arcanist/Mystic/Pyromancer (LOCK) · Assassin/Berserker/Archer (KILL)
P9  Empowered Enemy  : Berserker(anti-heal) · Cleric(purge) · Lifebinder(purge)
P11 Sheltered Caster : Assassin(dive) · Archer/Pyromancer/Arcanist(ranged) · Guardian(grip)
P12 Enrage Race      : Berserker · Pyromancer · Assassin · Archer
```
**Every spec's niche:** Guardian=P11/P7 (grip+relocate) · Berserker=P2/P9 (only anti-heal) · Crusader=P7/P5/P6 (immunity+
rot-DR) · Cleric=P5/P4/P3/P9 (burst+Magic dispel) · Assassin=P11/P8/P2 (only melee reach) · Archer=P2/P11/P12 (ranged
physical) · Pyromancer=P3/P8/P11 (armour AoE) · Arcanist=P1/P8 (interrupt+lock) · Lifebinder=P6/P4 (HoT+Nature dispel) ·
Mystic=P1/P8/P6 (control). No spec is dead weight; none is the sole answer to any problem.

---

## 6. Anti-generic-EHP plan (narrow the 5 fungible majors)

The audit's root cause: five fungible party-DR/shield/heal majors + spammable Divine Shield scaled EHP against
*everything*, so "bring more survivability" beat "bring the counter." The fix (after GATE 0):

| Major | Was | Becomes |
|---|---|---|
| Bulwark Banner (Guardian) | −35% party DR | **DELETED** (Guardian gets grip/intercept) |
| Sacred Bastion (Crusader) | 35% maxHp party shield | **single-ally immunity-peel** (P7/P5) |
| Light's Salvation (Cleric) | party heal+shield | **strong reactive single-target burst heal, no shield** (P5) — *not* a rez |
| Blossoming Tide (Lifebinder) | party HoT | **rot-keyed HoT that loses to a spike** (P6 only) |
| Arcane Barrier (Arcanist) | team shield | **CC-immunity rider only** (shield half removed) |

Surviving always-on majors are **pure offense** (Emberstorm, Killing Edge) — can't substitute for a counter. Divine
Shield gated to one charge/window. The only surviving party-DR is Crusader's, **keyed only to rot/tick** (a real 2nd P6
answer, useless vs bursts/walls). Cleric/Lifebinder raw throughput capped; Mystic = lifesteal only. **Dispels and schools
typed** so a generic cleanse/shield can't blanket-answer.

---

## 7. Dungeon remap

| Dungeon | Problem(s) | Notes |
|---|---|---|
| **Ashveil Crypts** | none — **dial sampler / +2 floor (control)** | Keep dial-pure. Success metric: after GATE 0 its comp spread drops **<2 keys** (proof generic EHP no longer decides). |
| **Bellreach Sanctum** | **P1** Dangerous Cast | The flagship "kick-or-wipe." Needs the cast scheduler (M2). The interrupts dial demotes to fallback automation. |
| **Stillhour Abbey** | **P5** Burst-spike | Keep `spikeProfile:burst`. Re-validate as a real HPS-*shape* read post-GATE-0 (honestly a shape read, not a wall). |
| **The Weltering Mire** | **P6** Rot + **P4** Spreading Curse (secondary) | Keep `spikeProfile:rot`. Add the removable rot-curse (P4) — fits the drowning theme; pairs HoT-coverage with dispel-type. |
| **The Pyreward Ossuary** | **P2/P3** School walls + **P9** self-healing boss (secondary) | The **one works-now class axis** — re-tune FIRST (M1). Add a self-mending boss (P9) later. |
| **The Hour of Bells** | **cooldowns DIAL** (keep) | **NOT** repurposed to P10. It's a genuinely good working dial read — keep the cooldowns crucible. |

*(Cleaner standalone homes for P4 and P9 are reserved for the future Necromancer-expansion dungeons.)*

---

## 8. Engine backlog (ordered by leverage)

| Item | Makes real | Effort |
|---|---|---|
| **GATE 0a** — fix the boss-dive / back-band auto-attack bug (squishies artificially concentrated) | Prereq for *every* read; tells us which gaps are real vs artifact | medium |
| **GATE 0b** — global **intake floor** (40%/cap-60% in `tuning.json`) + **steepen `resolveHit` resist/armour curves** | Compresses generic EHP so the *specific* tool decides; widens the P2/P3 school tax | medium |
| **Enemy cast scheduler** — pending-cast state (windup+telegraph+payload) from `abilities.json` shape/telegraph | **P1** (something to kick) + **P8** (adds get a denial-worthy cast) + **P11** (caster worth reaching) — one system, 3 verbs | **large** |
| **Wire interrupt** (`combat.ts:675` no-op) + landed-CC to cancel a pending cast; demote interrupts dial | P1 across Arcanist/Mystic/Pyromancer | medium |
| **Enemy→party `applyStatus` + dispel TYPING** (Magic/Curse vs Nature/Poison status field; AI values cleansing) | **P4** (healer-only, typed) | medium |
| **Reach primitive** — back-band reach penalty + Assassin dive + Guardian grip | **P11** (only bites an all-melee core, by design) | medium |
| **Immunity/relocate→avoidables + summon REAL adds** (CC-able/castable, not a fake timer) | **P7** + completes **P8** | medium |
| **Enemy buffs + self-heal + anti-heal/purge path** (Berserker Grave-Wound; enemy-purge mode) | **P9** | **large** |

**Dropped from the original plan:** the **threat model / taunt-swap** (P10 is dead — no 2nd tank).

---

## 9. Build sequence (one commit per milestone; we execute later)

- **M0 — GATE 0 (own commit, bump `SAVE_VERSION`).** Boss-dive fix + intake floor (40%/60%) + steeper school curves.
  **Verify:** `tsc -b` + egm-smoke + `balance-sweep.mjs` — Ashveil comp spread drops **<2 keys**, and record *which* of
  P5/P6/P2/P3 gaps survive (survivors are real; collapsed ones get re-tuned, not designed around).
- **M1 — Pyreward school re-tune (works-now, no new mechanic).** Steepen the tax to **+3–5 keys**; add an all-melee and
  an all-magic comp to the sweep; confirm a mixed-school core tops and a single-school core falls. Re-validate
  Stillhour/Mire's burst/rot as real *shape* reads post-GATE-0 (re-tune if collapsed). **Also do the Bard→Archer recut
  here** (ranged physical; remove lust/dispel). *The cheapest proof the redesign is reachable — ship before any large lift.*
- **M2 — Cast scheduler + real interrupt (own commit).** Build the pending-cast state; wire interrupt + landed-CC to
  cancel; demote the dial. Re-theme Bellreach to **P1**. **Verify:** a no-kicker comp wipes Bellreach where an
  Arcanist/Mystic/Pyromancer comp times — the flagship read.
- **M3 — Dispel typing + enemy→party status.** Author the spreading rot-curse on the Mire (**P4**); recut Cleric (Magic)
  vs Lifebinder (Nature). **Verify:** the wrong-type healer fails to answer; the right one resets the stack.
- **M4 — Reach + real adds + avoidable-immunity** (P11/P8/P7). Assassin dive + Guardian grip + back-band reach penalty;
  real CC-able adds; immunity/relocate on the eruption. **Verify:** an all-melee core can't reach the sheltered caster;
  an add wave demands lock-or-kill.
- **M5 — Anti-heal/purge + self-healing enemy (P9) + final kit recut.** Self-mending boss on Pyreward; Berserker
  Grave-Wound; enemy-purge. Apply the §6 major recosts (delete Bulwark, recost Sacred Bastion / Light's Salvation /
  Blossoming Tide / Arcane Barrier; gate Divine Shield; cap healer throughput). **Full `balance-sweep.mjs`** across all 6
  with per-problem solver/anti-solver comps — confirm **no generic comp tops the avg column** and **every problem has ≥2
  diverse top-tier answers**, with the wrong-tool comp falling +3–5 below.

**Throughout:** update `ROADMAP.md` status+changelog every milestone; grep every new name/text against the verbatim-WoW
blocklist before it lands.

---

## 10. Decisions locked (2026-06-22)

1. **P4/P9 homes:** P4 → secondary on the Weltering Mire; P9 → self-healing boss on the Pyreward Ossuary; cleaner
   standalone versions reserved for the future Necromancer dungeons. ✅
2. **Intake floor:** **40%** (stacked mitigation caps at 60% reduction) — starting target, tune via sweep. ✅
3. **Tool-tax band:** right-tool **+3 to +5 keys** above wrong-tool, every problem keeps a full substitute. ✅
4. **P10 dropped;** Hour of Bells keeps its cooldowns-dial identity. ✅
5. **Cast scheduler built for real at M2;** the matrix is partly aspirational for M0–M1. ✅
6. **`SAVE_VERSION` bumped at M0** (clean reset, no migration). ✅
7. **2-healer must be timer-limited;** **DPS don't dispel;** **no mechanic may require a 2nd tank.** ✅ (core rules, §2)

---

## 11. Verification harness extensions (for `balance-sweep.mjs`)

Three guards to add before M0, so the sweep directly measures "bringing the tool vs not":
1. **Per dungeon:** the right-tool comps occupy the TOP of the ceiling table; the wrong-tool comp visibly drops (+3–5).
2. **No single comp tops the CEILING MATRIX across all six** (the avg column must not be dominated by one generic comp).
3. **Per problem, ≥2 different-spec comps reach the top tier** (diversity guard) AND a generic-EHP comp with the *wrong*
   tool falls below them. Add per-problem solver/anti-solver comps (no-kicker for Bellreach, all-melee for Pyreward, etc.).
