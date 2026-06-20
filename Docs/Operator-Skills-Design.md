# GOAT Lite — Operator Skills & Identity (Design Spec)

**Status:** Draft for review (2026-06-20). Author: Producer (Claude) with Umut.
**Cluster:** "Endgame & Identity" — feature requests #1 (progression past the gear cap), #3 (recruitment list + detail panel), #6 (traits pass). Build order: **this cluster first.**
**Companion docs:** `GDD.md` §Potentials, `EGM-Reference-Analysis.md`, `ROADMAP.md` (Phase F).

---

## The one-paragraph version (read this if nothing else)

Gear stops being a chase once it caps (~ilvl 160, around key 12). To keep climbing, each bot's **operator** (the person playing the character) gets **three skill ratings that grow as you play and make the bot stronger** — that's the new endgame power axis. How high each skill can grow is set by a **hidden ceiling** rolled at recruitment; you only see a fuzzy ★ rating until you play the bot and learn the truth. That hidden ceiling is the same thing your GDD already calls **"Potentials"** — we're giving it a real job (it now decides how good a bot's skills can get) instead of two separate hidden systems. **Traits** become personality that *both* gives a small combat bonus *and* nudges which skills grow fastest. Recruitment turns into a scouting decision (win-now veteran vs. high-ceiling project), which is what fills the new recruit detail panel.

---

## 1. The progression problem we're solving

Today (verified in code):
- Party power = `powerPerIlvl × ilvl × moraleMult × aggressionOutput` (`web/src/sim/egm/stats.ts:129`).
- Loot ilvl = `112 + 4·key` and **has no cap** (`game-store.tsx:38`) — it scales forever, so "gear up" never ends but also never feels like a milestone.
- Keystones cap at 40; enemy power = `1.043^(key−2)` (`engine.ts:37`).

Once a bot is in best-in-slot, there is **nothing left to grow** except pushing keys for their own sake. We want a deliberate, ongoing power lever that takes over at the gear cap.

**Decision (locked):** hard gear cap + a *mechanical* operator-skill layer becomes the endgame axis.

---

## 2. Operator Skills (the power axis)

Each bot's operator has **3 skills**, FM-style, on a **1–20** scale. Start lean; the system is a **data-driven registry** so role-specific skills can be added later without a rewrite.

| Skill | Satire read | Mechanical effect in the sim |
|---|---|---|
| **Execution** | clean APM / ships clean code | **+ output** (throughput). Proposed: **+0.6%/pt** → +12% at 20. |
| **Awareness** | reads the room, catches the bug before prod | **− avoidable-damage intake** + minor uptime. Proposed: **−1.5%/pt avoidable intake** (≈ −28% at 20) and **+0.2%/pt output**. (Absorbs the old "Game Knowledge" + "affix adaptability" flavor — later splits back into two skills.) |
| **Composure** | calm during the incident, no grey parses | **clutch:** when the party is in danger (any member < 35% HP, or a recent death), **+0.8%/pt output** and **−1%/pt intake**; plus a flat **variance reduction** (tightens crit swing / fewer unlucky deaths). (Absorbs the old "Consistency" — later splits back out.) |

**How they enter the sim:** `buildParty` (`stats.ts`) multiplies each bot's existing output/intake by operator-skill factors, *alongside* ilvl/morale/aggression — they complement gear, they don't replace it. All per-point numbers live in `data/tuning.json` (`operator.*`) and get tuned against `node scripts/egm-smoke.mjs`.

**Scale sanity:** a maxed Execution (+12% output) ≈ ~12 ilvl of a DPS. Meaningful, not absurd — enough to extend a bot's reliable key ceiling by a few levels once gear is done.

---

## 3. Ceilings & Potential (the unified hidden layer)

This is the "one system" decision. **The hidden ceiling on each operator skill = the bot's Potential.**

- Each bot has, per skill, a hidden **Ceiling** (1–20) — the max that skill can grow to.
- The set of ceilings is rolled at recruitment from the **existing Potentials tags** (`data/potentials.json` taxonomy: `crit`, `survival`, `interrupt`, `aoe`, `sustain`, …) + class baseline + starting traits — *exactly the sources the GDD already specifies*. The mapping: on-tag weights raise the matching skill's ceiling (e.g. high `burst`/`crit` → high **Execution** ceiling; high `survival`/`positioning` → high **Awareness**/**Composure** ceilings).
- **Hidden-but-active, unchanged from canon:** recruitment reveals ~50% (a fuzzy ★ rating + a couple of skill hints); the rest sit behind "+X Unknown". Each **earned trait** has a 50% chance to reveal one hidden ceiling. You learn who a bot really is by playing them.
- **Potentials keep their old job too:** the same tag weights still bias which **earned traits** roll (GDD §Potentials). We've *added* a job (set the skill ceilings), not removed one.

**Naming:** to avoid two senses of "potential," the per-skill cap is the **Ceiling**; **"Potentials"** stays the name of the hidden tag-weight profile that produces the ceilings + biases trait rolls.

---

## 4. Growth (auto toward the ceiling)

**Decision (locked):** auto-growth, no manual point spend.

- Each run grants participating bots **skill XP** = `f(keyLevel, outcome)` — higher keys teach more; timed > depleted > wipe.
- XP raises skills **automatically toward their ceiling**, weighted by **role** (tank invests more into Awareness/Composure; DPS into Execution), **personality trait growth-bias** (see §5), and **distance to ceiling** (growth slows as a skill nears its cap — asymptotic, so high-ceiling bots keep improving longer = the endgame chase).
- A skill can never exceed its Ceiling. A low-ceiling bot plateaus early (a journeyman); a high-ceiling bot keeps climbing (a star).

---

## 5. Traits = personality **with** combat modifiers (request #6)

**Problem found in recon:** traits are currently **inert** — `buildParty` never reads `traitIds`; effects are prose only; the array only ever holds one element (`stats.ts:119`, `traits.json`). Talents, by contrast, are fully wired. So traits feel weird because they literally do nothing.

**Decision (locked):** traits become a personality layer that *also* carries real combat modifiers. Rewrite the trait schema to carry three blocks:

1. **`combat`** — machine-readable effects wired into `buildParty` (finally making traits matter): `{ outputPct?, intakePct?, critPct?, hpPct?, … }`.
2. **`growth`** — how the trait biases the operator layer: `{ skill, ceilingDelta?, growthMult? }` (e.g. *Tryhard* → Execution `growthMult 1.3`; *Tilted* → Composure `ceilingDelta −2`, worse while morale is low).
3. **`meta/flavor`** — existing fields kept: `name, rarity, archetype, kind(start/earned), pool, trigger, tags[]→potentials`.

- **Earned traits** unlock via their `pool`/`trigger` (pulls roadmap D.1 forward); biased by Potentials per canon.
- `netBudget` gets re-audited once `combat` effects are real (roadmap D.7).
- Keep single-trait-per-member for now (the array stays for future multi-trait, but only `[0]` is exercised).

---

## 6. Gear cap & the handoff (request #1 core)

- **Hard cap:** `dropIlvl(key)` caps at the **key-12 value = ilvl 160**. Below that, gear is the chase (keys 2–12, runway ~110 → 160).
- **Above the cap:** drops that would exceed ilvl 160 convert to **operator skill XP / a currency** instead of higher ilvl. So power smoothly hands off **gear → operators around key 12**, which is the vacuum we set out to fill.

---

## 7. Recruitment: list + detail panel (request #3)

- **List view** (replaces the 3-column card grid): a dense WCL-style table — portrait · name · role+spec icon · ilvl · **Current Operator Rating** · **Potential ★** · morale · cost · Sign. (Matches the user's reference Image 1.)
- **Detail panel** (click a row; matches reference Image 2 layout, *stats instead of talents*): operator **skill bars** (current value, ceiling shaded behind), **Potential stars**, personality **trait(s)**, **gear**, and a short **scout-report** blurb.
- **Two display numbers:**
  - **Current Operator Rating (COR)** — a 0–100 number from the 3 current skills (role-weighted). Shown precisely = "how good now."
  - **Potential** — derived from the (mostly hidden) ceilings, shown as fuzzy ★ until revealed = "how good they can get."
- This is what makes recruiting a *scouting bet*: win-now veteran (high COR, low remaining ceiling) vs. project (low COR, high Potential). Answers the open roadmap decision *"which lever scales recruit quality?"* — **guild progression unlocks higher-ceiling recruit pools** (the "Recruitment Board" building already promises "access higher potential recruits").

---

## 8. Data, types & save changes

- **`RawMember`** (`game-store.tsx`) gains: `skills: {execution, awareness, composure}` (current 1–20), `ceilings` (hidden caps), `skillXp`, and the Potentials profile (revealed/hidden tag weights).
- **`SimPartyMember`** (`sim/types.ts`) gains the resolved operator multipliers (or the raw skills, resolved in `buildParty`).
- **`traits.json`** schema extended (`combat`, `growth` blocks) + `web/src/content/schema.ts` updated; `buildParty` wired to apply trait `combat` effects.
- **`tuning.json`** gains an `operator.*` block: per-point %s, XP curve, ceiling-from-tag mapping, COR weights.
- **Save:** `SAVE_VERSION 4 → 5`. There is no stepwise migrator yet (version mismatch = full reset, `game-store.tsx:194`). **Decision:** accept a save reset during dev; **build a real stepwise migrator before Early Access** (already flagged on roadmap B.2).

---

## 9. Implementation phases (tickets — see ROADMAP Phase F)

- **F.1 Data + types** — operator skill registry, `tuning.operator.*`, `RawMember` fields, trait schema extension, `SAVE_VERSION` 5.
- **F.2 Sim wiring** — `buildParty` applies operator multipliers + trait `combat` effects. Verify via `egm-smoke`.
- **F.3 Growth + gear cap** — post-run skill XP + auto-growth toward ceiling; `dropIlvl` cap at 160 + above-cap → XP conversion.
- **F.4 Recruitment generation** — roll ceilings from Potentials/class/traits; fuzzy reveal; COR + Potential★.
- **F.5 UI** — recruit **list table** + **detail panel**; Character-sheet operator-skill section; reveal-on-earn.
- **F.6 Balance pass** — tune per-point %s so operators extend the key ceiling a few levels (not trivialize content); smoke sweeps + a live check.

---

## 10. Open numbers to tune (not blocking the design)

- Per-point % for each skill (start: Execution +0.6%, Awareness −1.5% intake/+0.2% output, Composure +0.8%/−1% clutch).
- XP curve — how many runs to cap a skill (target: a season-ish of play to max a high-ceiling bot).
- Ceiling distribution by role/Potential.
- Exact gear-cap ilvl (160 proposed = key 12).
- COR formula weights.

These get settled in F.6 against the deterministic harness.
