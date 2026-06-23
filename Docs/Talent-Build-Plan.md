# GOAT Lite — Talent Build Plan (C.2 implementation)

**Status:** plan ✅ (2026-06-23); **M1 ✅ shipped 2026-06-23** — M2–M8 pending. Companion to `Talent-Trait-Revamp.md` (the design) and `ROADMAP.md` C.2. Grounded in a 5-agent read of the live engine; every file:line below was verified.

The deliverable here is the **sequence + scope + decisions** so we agree before M1. Each milestone ends with a build gate (`cd web && npx tsc -b` + `node scripts/egm-smoke.mjs`) and a commit. **Determinism is the invariant** — goldens stay byte-identical until content actually lands (M7).

---

## Grounding — what's in the code today (not assumptions)

| Surface | Reality | Ref |
|---|---|---|
| Talent data | **5 SHARED, spec-agnostic nodes** (node-1…5); only node-1/2 carry `effects`; 3-5 prose-only | `data/talents.json:1-27` |
| Talent schema | `TalentOptionSchema.effects {maxHpPct,dmgPct,intakePct,critPct, onlyIf{type∈[targetHpBelowPct,enemiesAtLeast,enemiesAtMost], value}}`; `TalentNodeSchema {id,node,name,options}` — **no specId** | `schema.ts:195-211` |
| Engine apply | `resolveTalents(chosen)` → `buildParty` folds: hpMult ×maxHp; **intakePct + critPct UNCONDITIONALLY at build** (intake clamped [0.2,2.0]); dmgPct → runtime array | `stats.ts:111-126,154-181` |
| Two condition evaluators | **`condHolds`** (rich: targetHpBelowPct, selfHitSinceLastAction, targetHasStatus, selfHasStatus, targetBand, targetHotStacksAtLeast) vs **dup switch** in `passiveDamageMult` (only targetHpBelowPct/enemiesAtLeast/enemiesAtMost, gates **only dmgPct**). Talent enum mirrors the poor one. | `combat.ts:63-74` vs `302-330` |
| Abilities | loaded once per combatant in `buildParty` (immutable array); executed per-cast | `stats.ts:159-160`, `combat.ts:583-733` |
| Event hooks (exist) | atonement-heal (339-346), reset-cd-on-crit (347), reset-cd-on-kill (362), crit-lifesteal/stack-buff (352-358), detonate (365-392), parry (213-217), redirect (493-497), block-reflect (484), atonement-on-dot (148-158), blossom-on-expire (159-162) | `combat.ts` |
| Combatant | **one unified struct**, `team:"party"|"enemy"`; party = stable array, mobs = per-stage (gains summons) | `stats.ts:65-106` |
| Summon template | enemy guard: opt-in `bossSummonsId`, `makeEnemy`→`mobs.push`, replay id `s{stage}m{index}` (**index = array length → drifts on out-of-order deaths**) | `engine.ts:192-208` |
| Picker | `Talents()` renders `content.talents` globally, filters to nodes with `effects`; `SET_TALENT` → `RawMember.talents: Record<nodeId,optionId>`; captured in RunTicket via `SimPartyMember.talents`; sanitize-on-load | `CharacterPage.tsx:180-215`, `game-store.tsx:169,441,725,248` |
| Cooldown display | SpellTip shows **"N turn cooldown"** (`components.tsx:154`); Signature card hardcodes **"~60s CD"** (`CharacterPage.tsx:112`); `skills.json` prose has "X turn" | — |
| ⚠️ Spec-id snag | `specs.json` still lists **`bard`** (the P.2 Bard→Archer recut) — the doc's **"Archer" tree maps to specId `bard`** until renamed | `data/specs.json:2-11` |
| Save | `SAVE_VERSION=6`; version mismatch → **full reset** (no migrator); defensive `talents: m.talents ?? {}` | `game-store.tsx:15,244-259` |

---

## Sequencing principle

**Engine capability first, content last.** M1-M6 add *capabilities* with **no talent using them yet**, so `egm-smoke` stays **byte-identical** the whole way (the 2 live MVP nodes use only old vocab). Content (the 10 trees) lands at **M7**, which is the *first* deliberate golden rebump (new power changes sim results) — re-baseline + re-verify the +2 floor there. M8 balances, then hands off to P.5c.

```
M1 §A keystone ─┬─ M2 §B abilityOverride ─┐
                ├─ M3 §C+§E status+riders ─┼─ M7 author 10 trees + picker + seconds ── M8 balance ──▶ P.5c
                ├─ M4 §D atonement ────────┤
                ├─ M5 §F tank tools ───────┤
                └─ M6 §H summon engine ────┘
M2-M6 depend only on M1; they can be done in any order (or batched). M7 depends on all capabilities a given spec uses.
```

---

## Milestones

### M1 — §A The `condHolds` keystone *(the unlock — do first)* ✅ SHIPPED 2026-06-23
> **Done:** talent `onlyIf` routed through `condHolds()` (dup switch deleted); enum widened (+ `selfHpBelowPct`/`allyHpBelowPct`/`lowestAllyHpBelowPct`/`selfStacksAtLeast`/`selfHoldsHardThreat`[M5 stub]; `enemiesAtLeast/Most` moved in); runtime conditional `intakePct` (per-step `intakeMult` refresh) + `critPct` (5 party-caster `resolveHit` sites) channels added. `tsc` clean · egm-smoke **byte-identical** · `web/scripts/talent-cond-verify.mjs` **15/15**. Files: `schema.ts`, `stats.ts`, `combat.ts`, `engine.ts`.

**Goal:** one condition path; `onlyIf` gates **dmg + intake + crit**.
**Changes:**
- `schema.ts:205` — widen the talent `onlyIf` enum to the full closed set (+ `selfHpBelowPct`, `allyHpBelowPct`, `lowestAllyHpBelowPct`, `selfStacksAtLeast` (+ a `resource?` field), `selfHoldsHardThreat`, and move `enemiesAtLeast/atMost` here).
- `combat.ts:63-74` — add those predicates to `condHolds` (`selfHoldsHardThreat` = stub→false until M5 wires the threat read; `enemiesAtLeast/atMost` implemented identically to the old switch).
- `combat.ts:302-330` — **delete the dup switch**, route the talent dmg loop through `condHolds` (cache `livingMobs(ctx)` once before the loop).
- `stats.ts` — **add a runtime, per-hit conditional channel for intakePct + critPct** (so a Tier-4 "−20% taken while <50% HP" or "+5% crit while 3+ enemies" works). Unconditional intake/crit keep the existing build-time fold; only *gated* ones evaluate at hit-time (`dealDamage` for intake, `resolveHit` for crit).
**Verify:** `tsc -b`; `egm-smoke` **byte-identical** (no node uses new predicates); a scratch unit check that a self-HP-gated intake node actually fires, then removed.
**Risk:** determinism — pure conditions (no RNG), cache `livingMobs`, keep the 3 existing types' math identical. No SAVE bump. **Decision needed:** confirm conditional intake/crit moves to runtime in M1 (vs deferring) — recommended **yes** (Tier-4 defenses need it).
**Commit:** M1.

### M2 — §B `abilityOverride` (enumerated, Zod-strict) ✅ SHIPPED 2026-06-23
> **Done:** `AbilityOverrideSchema` discriminated union (`cooldown`/`targeting`/`param`/`scalar`/`addModifier`), applied via `applyAbilityOverrides` in `buildParty` (clones the patched ability — shared content never mutated). Cross-ref validates `abilityId`. `tsc` clean · egm-smoke byte-identical · probe +10. Files: `schema.ts`, `index.ts`, `stats.ts`.

**Goal:** a talent patches a named ability's params.
**Changes:** `schema.ts` — **enumerated** override kinds (`abilityScalarOverride`, `abilityTargetingOverride`, `abilityCooldownOverride`, `abilityChargeOverride`) — no loose bag (typos fail-closed). `stats.ts` buildParty (141-181) — after loading a combatant's ability array, **clone** the targeted ability (never mutate the shared content Map) and apply the patch. `index.ts` cross-ref — `abilityId` must exist.
**Verify:** `tsc`; `egm-smoke` byte-identical; scratch test that an override changes a cooldown.
**Risk:** must deep-clone the patched ability per combatant. Powers Berserker/Cleric/Arcanist/Mystic/Archer/Crusader/Lifebinder/Pyromancer scalar+targeting edits.
**Commit:** M2.

### M3 — §C + §E status authoring + event riders ✅ SHIPPED 2026-06-23
> **M3a:** `EventRiderSchema` (on-hit/crit/kill → applyStatus/adjustCooldown/refundResource/heal), wired in `afterHit`; `applyEventRider` exported; cross-ref validated. **M3b:** anti-heal — `healingReceived` statMod honored in `eff()`/`healInto`. `tsc`/egm-smoke/probe green. **DoT/HoT tuning** → use M2 `scalar` override (no separate statusMod). `cleanseImmune`/`suppressCrit` deferred (limited active-spec use).
**Goal:** talents apply/tune/suppress statuses and hook on-kill/crit/parry/detonate/expiry/cleanse.
**Changes:** `schema.ts` — enumerated `statusRider` (apply debuff on hit), `statusMod` (magnitude/duration tune), `statusFlags` (suppressCrit / cleanseImmune), `eventRiders[]` (trigger enum → {applyStatus|adjustCooldown|refundResource|heal|dealDamage}). `combat.ts` — insert into `afterHit` (333-363), `detonateBurn` (365-392), `onStatusEvents` (147-163), parry (213-217); guard the loops (`if (!riders.length) return`). `stats.ts` ActiveStatus += `suppressCrit?/cleanseImmune?/eventRiderId?`. `status.ts` cleanse path honors `cleanseImmune`. **`on-cleanse` is net-new.**
**Verify:** `tsc`; `egm-smoke` byte-identical; per-rider scratch tests.
**Risk:** `afterHit` is hot — keep rider checks cheap. Likely **split M3a (status authoring) / M3b (event riders)** if large.
**Commit:** M3(a/b).

### M4 — §D atonement / healer hooks ✅ SHIPPED 2026-06-23
> **Done:** `atonement` config (`disableAbilityId` + `partyWhenLowestAllyBelowPct`) reshapes the `afterHit` heal-by-damage path via pure exported `atonementTargets`. Magnitude → M2 `param`. `tsc`/egm-smoke/probe(+6) green. (rotate/exclude-last + atonement-on-dot deferred to when authored.)

**Goal:** per-ability atonement override + disable flag + target-mode (rotate / exclude-last / party-swap gated on lowest-ally HP).
**Changes:** reuse §B for `healPctOfDamage` overrides; `combat.ts` atonement block (339-346) + atonement-on-dot (148-158) gain a `target` mode + `disableAtonement` flag; the party-swap uses `lowestAllyHpBelowPct` from M1.
**Verify:** `tsc`; `egm-smoke` byte-identical; Cleric/Lifebinder heal scratch tests.
**Commit:** M4.

### M5 — §F tank-tool extensions ✅ SHIPPED 2026-06-23
> **Done:** `selfHoldsHardThreat` wired (= alive party tank). **Audit:** thorns/block/redirect/grip param tweaks are all M2-`abilityOverride`-covered (no new work). The locked-taunt + untargetable-while-taunt Guardian-capstone mechanics are content-coupled → build with their abilities in M7. `tsc`/egm-smoke/probe(+2) green.
**Goal:** thorns→all-front-band; grip (+root/+count/on-kill-reset/convert-to-strike); block-reflect scalar + route as real damage; redirect (+extra DR / min-1-HP / multi-concurrent / un-cleansable); **Guardian "Sentinel's Voice"** (rally party-buff / **locked single-target taunt** / AoE soften+interrupt war cry); **untargetable-back-band-while-holding-taunt** + paired self −50% dmg.
**Changes:** `combat.ts` SPECIALS (531-550) + guard/redirect/parry handlers; new **locked-taunt** state on Combatant; a minimal **threat read** so `selfHoldsHardThreat` (M1 stub) resolves — there's no numeric threat pool today (targeting is brain-priority), so define "holds hard threat" = "is the current taunt-holder / tank-focus".
**Verify:** `tsc`; `egm-smoke` byte-identical; tank scratch tests.
**Risk:** locked-taunt + untargetable-aura touch the targeting brain (`combat.ts:898-962`) — determinism-sensitive. The threat read is the one genuinely new tank concept.
**Commit:** M5.

### M6 — §H summon engine (general) ✅ SHIPPED 2026-06-23
> **Done:** extracted `spawnSummonedCombatant(g, opts)` from the inline guard code (reusable enemy-add spawner); `summonGuard` is now a thin caller. Party-pet deferred with necro. `tsc`/egm-smoke byte-identical + `summon-check.mjs` (hour-of-bells) byte-identical at +6/+10.
**Goal:** a general summoned-combatant system — enemy adds **now**, party-pet **later**.
**Changes:** `engine.ts` — extract `spawnSummonedCombatant({team, duration?, ownerId, sourceName, band})` from the guard code (192-208); add a **per-stage summon counter** → stable replay id `s{stage}a{n}` (fixes the array-length id drift). The existing boss-guard calls the new spawner. `types.ts` ReplayMob unchanged. `combat.ts` targeting handles summoned combatants (already does — unified struct).
**Verify:** `tsc`; `egm-smoke` **byte-identical** (guard math preserved); summon scratch test (deterministic ids).
**Risk:** replay-id stability (counter, not `mobs.length`). **Party-pet** (target enemies, contribute to party parse, own brain) is a **later increment (M6b), deferred with the Necromancer** — but the general enemy-add system ships here and is immediately usable for boss/trash adds.
**Commit:** M6.

### M7 — Author the 10 trees + picker + seconds display *(content lands — goldens move here)* ✅ SHIPPED 2026-06-23 (M7a + M7b)
> **M7a (structure) done:** `specId` optional on `TalentNodeSchema` (back-compat → globals still apply, byte-identical); `resolveTalents`/picker filter by spec; cross-ref validates `specId`; SpellTip shows `{cd×3}s`.
> **M7b (content) done 2026-06-23:** authored the **10 per-spec trees (50 nodes × 3 options = 150)** in `talents.json` against the M1-M6 honored vocab; dropped the 5 global MVP nodes (**deliberate golden rebump** → 938/978/1208/1414, all timed, 0 deaths; **+2 floor times for all 4 comps**). Archer kept `specId:"bard"` (decision: no rename — `specs.json` keeps the id for save stability, so decision #5's reconcile is moot). Added 2 anti-heal statuses (`riven-wound`/`serrated-wound`) + `selfHitSinceLastAction`+`targetHpAbovePct` to the talent `onlyIf` enum & `condHolds`. Store sanitize drops stale nodeIds on load (persisted shape unchanged → **no SAVE bump**, per decision #2). SignatureCard cd → `{cd×3}s`; `skills.json` player-facing prose "turn"→seconds (baseValues left as reference units). A **10-agent adversarial audit** caught a real no-op class — talent `dmgPct` gates evaluate against `livingMobs[0]` (the lead enemy), so `targetBand:back` is unreliable for front-fighting specs → Guardian Iron Tether reworked to an on-hit Mark rider, Assassin Sever-the-Thread to target-accurate `addModifier`s (which DO see the real hit target); + a cd-text bug + 2 near-inert healer `dmgPct` nodes swapped to self-survival. **Known engine gap (flag for M8/a future milestone): no healer-output (heal/HoT-magnitude) talent channel** — Lifebinder/Cleric throughput nodes use cooldown-reductions + Cleric atonement-`dmgPct` + self-survival; the design's one-shot-evasive / party-buff / status-magnitude hooks are intentional proxies. **Verify:** `tsc -b`; content validator; egm-smoke (rebumped); `balance-probe` (+2 floor); `talent-cond-verify` (M1-M6 channels); Playwright `talent-picker-live.mjs` PASS. Then **M8** balance.
**Goal:** make it real.
**Changes:**
- `schema.ts` `TalentNodeSchema` += `specId` + rename/add `tier` (1-5). `index.ts` cross-ref: `specId ∈ specs`, every referenced `abilityId ∈ abilities`.
- `data/talents.json` — restructured to **10 specs × 5 tiers × 3 options** using the M1-M6 effect vocab (flat nodes, spec-prefixed ids e.g. `guardian-t1`). **Resolve the `bard`↔`archer` spec-id** here.
- `CharacterPage.tsx:180-215` — filter by `member.specId`, render the 5 tiers.
- `game-store.tsx:248` — extend sanitize-on-load to **drop stale talent nodeIds** (old `node-1` picks → fall back to spec defaults). No full reset needed (persisted shape `Record<string,string>` is unchanged).
- **Seconds display pass:** `components.tsx:154` ("N turn cooldown" → `mmss(cd*3)`), `CharacterPage.tsx:112` (hardcoded "~60s CD" → from `sk.cd*3`), `skills.json` prose ("X turn" → seconds).
**Verify:** `tsc`; content validator green; `egm-smoke` **deliberately rebumped** (new power) — document the new goldens + **re-verify the +2 floor times at starting gear**; Playwright (picker shows 5 tiers/spec, persists, replay faithful, tooltips show seconds).
**Risk:** save handling (sanitize, not reset — see Decisions); first deliberate golden change; spec-id reconciliation. **Likely split M7a (schema+data+validator+picker) / M7b (seconds display) / per-spec batches.**
**Commit:** M7(a/b/…).

### M8 — Balance pass → hand off to P.5c
**Goal:** sweep the trees vs the timer curve; every tier's 3 options power-equal; +2 floor holds; operator runway intact. Then **P.5c** (the regime tuning) calibrates once against the final trees.
**Changes:** `scripts/*.mjs` sweeps, `data/tuning.json`, talent tuning.
**Verify:** `balance-sweep`/`balance-probe`; +2 floor; determinism.
**Commit:** M8 (then P.5c is its own phase).

---

## Cross-cutting decisions to lock (your nod, before M1)

1. **Per-spec data shape** → *recommend* **flat nodes with `specId` + `tier`** (spec-prefixed ids), member storage stays `Record<nodeId,optionId>`. (Simplest; no nested record; minimal engine change.)
2. **Save handling** → *recommend* **sanitize-on-load drops stale talent picks** (→ defaults), **no SAVE_VERSION bump / no full reset** (the persisted shape doesn't change; only nodeIds do).
3. **Conditional intake/crit** → *recommend* **runtime per-hit eval in M1** (Tier-4 defenses + conditional-crit nodes need it).
4. **Goldens** → *recommend* **byte-identical through M1-M6**, **one deliberate rebump at M7** when content lands (+ re-verify +2 floor).
5. **`bard`↔`archer` spec-id** → *recommend* **rename specId `bard`→`archer`** in `specs.json` + refs during M7 if clean (else map the Archer tree to `bard`).
6. **Summon engine** → *recommend* **ship the general enemy-add system at M6**; party-pet (M6b) deferred with the Necromancer.

---

## Risk register

| Risk | Where | Mitigation |
|---|---|---|
| Determinism drift | M1 (condHolds routing), M5 (taunt/targeting), M6 (summon ids) | cache `livingMobs`; pure conditions; keep existing-type math identical; stable summon counter; `egm-smoke` byte-identical gate every milestone M1-M6 |
| Save breakage | M7 (id-space change) | sanitize-on-load drops unknown nodeIds → defaults; persisted shape unchanged; malformed RunTickets already dropped |
| Hot-loop cost | M3 (`afterHit` riders) | early-out when a combatant has no riders; resolve rider lists at build time |
| No numeric threat model | M1 `selfHoldsHardThreat`, M5 | define "holds hard threat" = current taunt-holder/tank-focus; stub in M1, wire in M5 |
| Golden rebump hides a regression | M7 | re-baseline deliberately, diff the *reason* for each change, re-verify +2 floor + operator runway |
| Spec-id mismatch | M7 (`bard`/`archer`) | reconcile explicitly; cross-ref validator enforces `specId ∈ specs` |
| Validation laxity | M2/M3 schema | enumerate every override/rider kind (Zod-strict) — no free-form bag |

---

## Effort & dependency summary

| Milestone | Scope | Size | Depends on | Goldens |
|---|---|---|---|---|
| M1 §A keystone ✅ | engine condition unification + runtime intake/crit | M | — | ✅ byte-identical (shipped) |
| M2 §B abilityOverride ✅ | enumerated param patching | S-M | M1 | ✅ byte-identical |
| M3 §C+§E status + riders ✅ | the bulk of DPS/healer hooks | L | M1 | ✅ byte-identical |
| M4 §D atonement ✅ | healer damage-to-heal extensions | S-M | M1, (M2) | ✅ byte-identical |
| M5 §F tank tools ✅ | threat predicate (rest M2-covered; capstone mechanics → M7) | S | M1 | ✅ byte-identical |
| M6 §H summon ✅ | general enemy-add system | M | — | ✅ byte-identical (+ summon-check) |
| M7 author + picker + seconds ✅ | 10 trees content + UI | XL | M1-M6 (per spec) | ✅ M7a (struct byte-identical) + M7b (deliberate rebump 938/978/1208/1414, +2 floor holds) |
| M8 balance → P.5c | sweep + tune | M | M7 | tuned |

With M1-M5 done, ~9 of 10 specs are fully expressible; M6 adds the summon axis; M7 makes it playable.
