# GOAT Lite — Combat AI Rework (Phase K) — Design Spec

**Status:** Draft for review (2026-06-20). Author: Producer (Claude) with Umut.
**Decisions locked (this session):** (1) **priority rules + utility tiebreak** (not pure utility AI); (2) **data-driven profiles (JSON) composing code primitives**; (3) **v1 scope = core brain + role/spec + tactics-as-orders** (aggression / operator-as-competence / trait-as-personality / boss-script integration are fast-follows).
**Companion:** `ROADMAP.md` Phase K, `goatlite-combat-tuning.md`, `combat-model-egm-migration` memory.

---

## 1. The one-paragraph version
Every actor in the sim — **player bot or enemy** — runs the **same brain**: each turn it makes two decisions, *what to do* and *who to target*, by walking an **ordered list of behaviours** (the first that applies wins; utility only breaks ties *within* a behaviour). Behaviours are a small set of **reusable code primitives**; a **profile** is **JSON data** that names, orders, and parameterises them. Roles (Tank/Healer/DPS) are base profiles; specs and enemy types are overlays. The party's **tactics dials become the party's AI orders**, the inert **behavior-profiles** finally drive play, and every future enemy is authored as **data, not code**. It stays **deterministic** (pure functions + the seeded RNG), and it's **legible** so the player can "review the pull" and see *why* a bot made a call.

## 2. Why now / what it fixes (verified in code)
- `selectAbility` (`combat.ts`) fires **longest-CD-ready first** → healers dump Greater Heal on light damage (huge overheal), DPS don't save burst, **majors fire on cooldown** instead of for the boss/danger window.
- Target selection = **focus the lead living enemy** (`targetsFor`), and **enemies always hit the tank** (`engine.ts`: `victim = tank ?? aliveParty()[0]`). No kill-order, no peel, no backline dive, no caster behaviour.
- **`behavior-profiles.json` is inert** (4 prose strings); `profile`/`defaultProfile` is read once (`hasPeel`, `engine.ts:45`) and only halves Spiteful-ghost damage.
- **Tactics are abstract** today: Kill Order/Interrupts/Positioning/Cooldowns scale `outgoingMult`, blunt affix stacks, and roll boss-mechanic chances — they don't drive party *decisions*.

## 3. The model

### 3.1 Two decisions per turn
- **`decideAction(actor, ctx) → ability | basic`** — replaces `selectAbility`.
- **`decideTarget(actor, action, ctx) → Combatant(s)`** — replaces the focus-pick in `targetsFor` and the `victim = tank` line for enemies.

Both consult the actor's **profile** (its ordered behaviour list). A behaviour returns either a concrete choice or "pass" → fall through to the next. The last behaviour is always a safe default (basic attack / nearest target).

### 3.2 Behaviour primitives (the shared kit — code)
*Targeting* — `focusLowestHp` (execute/triage) · `focusByPriority` (casters/healers/adds first = kill order) · `focusByThreat` (enemy→tank, or highest-threat) · `focusHighestHp` (tunnel-vision) · `mirrorTankTarget` (opportunist) · `diveBackline` · `peel` (switch to whoever's hitting my protectee) · `spreadCleave` · `sticky` (stay until dead).
*Action* — `triageHeal` (**size the heal to the injury** → fixes Flash-vs-Greater) · `emergencyHeal/Defensive` (self/ally < threshold) · `holdForWindow` (**save majors/burst for boss or `partyInDanger`** → fixes majors-on-CD) · `maintainDots/Hots` · `interruptCast` · `preShield` · `dumpRotation` (greedy) · `conserveResource`.
*Modifiers (bias the above)* — aggression, `partyInDanger` (already computed), morale band, **operator competence** (Awareness/Composure/Execution), **trait personality**, and the **tactics dials**.

### 3.3 Three layers
1. **Role template** (Tank/Healer/DPS) = the base ordered behaviour list.
   - Tank: `[emergencyDefensive, peel, focusByThreat/taunt, dumpRotation]`
   - Healer: `[emergencyHeal, triageHeal, preShield(holdForWindow), dispel, topUp]`
   - DPS: `[selfDefensive, holdForWindow(burst/major), focusLowestHp(execute), spreadCleave(packs), focusByPriority(killorder), dumpRotation]`
2. **Spec overlay** = reweight/reorder the template (the GDD profiles, finally live):
   - executioner (assassin/berserker) → `focusLowestHp` up; opportunist (bard/pyro/arcanist) → `holdForWindow` up; peel (cleric/lifebinder/mystic) → `peel` awareness; tunnel-vision (guardian/crusader) → pure threat, no peel.
3. **Enemy overlay** = a profile like any other: `melee` (`focusByThreat`/nearest) · `caster` (act from back band, `focusLowestHp` dive, **interruptible**) · `fixate`/`add` (`sticky` on a chosen victim) · `boss` (scripted mechanics + a targeting/rotation profile).

### 3.4 Profile schema (data — extends `behavior-profiles.json`)
A profile is a `{ id, name, base: "tank|healer|dps|enemy", behaviours: [{ id, weight?, params? }] }`. `behaviours` overlays/reorders the base role template; `params` tune a primitive (e.g. `emergencyHeal.thresholdPct`). The 4 existing profiles gain machine-readable `behaviours`; enemies get their own profiles. **New enemy/spec = author a profile, no engine code** (scales to Phase C's ~50–70 enemies).

## 4. Tactics → AI orders (the convergence)
The party's tactics dials become **real behaviour configuration** instead of abstract scalars:
| Dial | Becomes |
|---|---|
| **Kill Order** | `focusByPriority` strength (kill casters/adds/low-HP first) for the party's targeting |
| **Interrupts** | party `interruptCast` readiness (who's assigned to interrupt; see §6 open Q on the cast model) |
| **Cooldowns** | `holdForWindow` / `reactDefensive` discipline (save majors + defensives for spikes) |
| **Positioning** | mechanic-avoidance behaviour weight (reduces avoidable intake — already the abstract effect) |
**Reconciliation:** today these are probability/scalar knobs on affix/boss mechanics. v1 makes the *party-decision* side real (targeting, defensive timing); the affix/boss-mechanic *rolls* can remain as the consequence (a missed interrupt still "goes through"), now informed by whether the brain actually chose to interrupt. Keeping both in sync is a v1 deliverable (avoid double-counting a tactic).

## 5. Cross-system modifiers (fast-follow after the core)
- **Aggression** (Safe/Balanced/Yolo) — global risk knob (already a sim input): biases `holdForWindow` vs `dumpRotation`, pull pace.
- **Operator skills = AI competence** — Awareness → better mechanic avoidance / earlier reactions; Composure → better play while `partyInDanger`; Execution → tighter rotation (less idle). The endgame layer becomes "how well the bot *pilots* the brain."
- **Traits = personality** — Jenkins → greedy/aggressive bias, Boomer → cautious, Drama Queen → clutch-weighted. A behaviour-bias block alongside their `combat`/`growth`.

## 6. Determinism + legibility (hard constraints)
- Behaviours are **pure functions of state + the seeded `rng`** — same seed → identical decisions (verify in `egm-smoke`/`op-verify`).
- Decisions should be **explainable**: emit enough log/meta that the replay can show *why* ("Svenrik triage-heals Grymdark — tank at 41%"). This is the QA-review payoff and the reason we chose priority-rules over opaque utility AI.

## 7. Open questions to settle during build
- **Threat/aggro model:** there's **no threat system** today (taunt deferred) — enemies target "the tank" by role. Do we add a lightweight threat number (taunt/threat-mods become real), or keep role/profile-based enemy targeting for v1? *(Lean: keep role/profile targeting for v1; add threat in a later pass.)*
- **Interrupt/cast model:** non-boss enemies don't cast (they auto-attack); only bosses have telegraphed mechanic "casts" (rolled today). Do we give the party a real `interruptCast` action against boss casts (needs a cast-bar/telegraph model), or keep the Interrupts dial as the existing roll for v1, just driven by the brain's interrupt-readiness? *(Lean: keep the roll for v1, brain-informed; real cast-bars later.)*
- **How far to reconcile the abstract tactic scalars** (outgoingMult etc.) vs replace them with behaviour consequences — incremental, to protect the balance curve.
- **Per-turn cost:** the brain runs for every actor every action; keep primitives cheap (the sim runs thousands of decisions/run).

## 8. Tickets (refines ROADMAP Phase K)
- **K.1 — Brain scaffold + behaviour primitive kit + profile schema.** `decideAction`/`decideTarget` shells; the §3.2 primitives; profile loader extending `behavior-profiles.json`; wire `profile`/`defaultProfile` as the config source. No behaviour change yet (role defaults reproduce current play) — pure refactor + determinism check.
- **K.2 — Player rotation behaviours.** `triageHeal`, `holdForWindow` (majors/burst), `emergencyDefensive`, `dumpRotation` — fixes the healer overheal + majors-on-CD.
- **K.3 — Player + enemy target selection.** `focusByPriority`/`focusLowestHp`/`diveBackline`/`peel` for players; enemy `focusByThreat`/`caster`/`fixate` profiles (smarter than "always the tank").
- **K.4 — Tactics-as-orders.** Map the 4 dials onto behaviour config (§4) + reconcile with the existing affix/boss-mechanic rolls (no double-count).
- **K.5 — Spec overlays.** Give the 4 behavior-profiles machine-readable behaviours + assign per spec; verify each spec plays to flavour.
- **K.6 — Balance + verification.** Re-tune vs the timer curve (smarter AI ≈ more output/survival → may need a difficulty nudge like H.4); `egm-smoke` holds the +2 floor; determinism; adversarial review.
- *(Fast-follow, post-v1: aggression/operator/trait modifiers §5; threat model + real interrupt cast-bars §7; boss-script integration.)*

## 9. Sequencing note
K.1 is a **pure refactor** (reproduce current behaviour through the new brain, prove determinism) — lowest-risk first. Then K.2/K.3 add the smart behaviours; K.4 wires tactics; K.5 the spec flavour; K.6 rebalances. Expect a balance nudge (smarter bots clear better), same as H.4.
