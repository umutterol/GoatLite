# GOAT Lite — Data Model

How game content is **decoupled from the GDD** and captured as structured, validated data.
The GDD (`GDD.md`) is now the *spec* — prose, rationale, locked decisions. This document +
the `/data` directory are the *content* — the actual numbers and entities the game and the
UI consume. Grounded in how the reference game (Exiled Guild Manager) structures its
data-driven resources (see `EGM-Reference-Analysis.md`).

---

## Principles

1. **Canonical store: `/data/*.json`** at the repo root — engine-agnostic, diff-friendly,
   not embedded in the GDD and not tangled in app code. Matches the GDD's v1.9 "JSON
   persistence" decision.
2. **Validated on load by Zod** (`web/src/content/schema.ts`). Types are *inferred* from the
   schemas (`z.infer`), so the schema is the single source of truth for shape.
3. **String IDs that double as the join key.** Every entity has an `id`; cross-references are
   by `id`, never by array index or path. (EGM's universal convention — ids match filenames,
   enforced by a startup `content_validation_test`.)
4. **A loud cross-reference validator** (`web/src/content/index.ts`) runs at load and throws
   one aggregated error listing *every* broken reference — mirroring EGM's content validation.
   Proven: breaking `spec.classId` yields `[content] spec 'guardian' → unknown classId 'wizard'`.
5. **Content vs. instance/save.** Content = the catalog (specs, traits, dungeons, items…).
   Instance/save = a particular game state (the recruited roster, wallet, current keystone).
   Instances live under `/data/instances/` and reference content by id. (EGM: `ClassDefinition`
   is content; `ExileData` is the runtime instance.)
6. **Composable sub-schemas.** Small reusable shapes (a stat bonus, a reward, a spawn, a
   dungeon slot) are defined once and reused across domains. (EGM embeds `ConditionalStatBonus`,
   `PassiveStatBonus`, `MissionReward`, `MonsterSpawn` everywhere.)

---

## Layout

```
/data
  classes.json  specs.json  stats.json  potentials.json
  traits.json   talents.json            abilities.json
  affixes.json  tactics.json            behavior-profiles.json
  enemies.json  packs.json              dungeons.json
  item-slots.json  items.json           loot-tables.json   tier-sets.json
  currencies.json  buildings.json       morale-events.json  crafting.json
  recruitment.json   season.json        log-templates.json
  secondary-stats.json                  tuning.json
  /instances
    sample-roster.json                  (a save: roster + wallet + keystone + week)

/web/src/content
  schema.ts     Zod schemas + inferred TS types (the structure)
  index.ts      loader: validate → index byId → cross-ref check → export `content`
/web/src/data/game.ts   thin adapter presenting `content` in the shapes the screens expect
```

Consumed via a `@data` Vite/TS alias. The web app is currently the only consumer; if a
non-web engine is added later, only `index.ts` changes — the JSON is portable as-is.

---

## The registry pattern (from EGM)

EGM's every domain follows: `ResourceDirScan` discovers files → a `Library`/`Manager` autoload
loads them → builds a primary `byId` dictionary + optional secondary indexes (`byRarity`,
`byCategory`). We do the same in `index.ts`: each domain is `index(Schema, json, name)` →
`Map<id, T>` with duplicate detection, then secondary views are derived on demand. Adding a
domain = author the JSON, add a Zod schema, add one `index(...)` line, add its cross-ref checks.

---

## Domains

`status`: all **built** (authored JSON + Zod schema + loader cross-ref checks). Each notes its EGM grounding.
A handful of fields stay first-pass / Needs-Tuning (trait Net Budgets, tier-set bonuses, secondary-stat
ranges, Haste/Mastery sim hooks) pending the GDD's "Trait↔sim reconciliation pass" — flagged in the data.

### Characters & growth

| Domain | Status | Key fields | EGM equivalent |
|---|---|---|---|
| **classes** | built | `id, name, blurb` | `ClassDefinition` (we split spec out) |
| **specs** | built | `id, name, classId→, role, position, icon, defaultProfile→, blurb` | none — EGM is classes-only; specs are our layer |
| **stats** | built | `id, name, category, kind(flat/percent), cap?, desc` | `StatDefinition` (64 .tres; `stat_id` joins to the stat field) |
| **potentials** | built | `id, label` (the tag taxonomy) | `ExilePotential` tags (content-defined string tags) |
| **traits** | built | `id, name, kind(start/earned), rarity, archetype, netBudget, effect, type?, pool?, trigger?, tags[]→potentials` | `TraitDefinition` (category, stat/conditional bonuses, `potential_tags`, `incompatible_trait_ids`) |
| **talents** | built | `id, node, name, options[{id,name,effect,tags[]→potentials}]` — 5 **generic** nodes shared by all specs (1–2 = MVP set; 3–5 = full-game; per-spec trees are future depth) | `PassiveDefinition` (effects, tags, rarity, prerequisites) |

### Abilities

| Domain | Status | Key fields | EGM equivalent |
|---|---|---|---|
| **abilities** | built | `id, name, kind(enemy/spec), shape, tactic→, telegraph, desc` | `MonsterAbility` (shape, range, cooldown, wind_up, recovery, damage_scaling) + `PassiveDefinition` |
| **behavior-profiles** | built | `id, name, behavior` | `TargetRule` / kite-profile presets |

### Content / encounters

| Domain | Status | Key fields | EGM equivalent |
|---|---|---|---|
| **affixes** | built | `id, name, tier(1/2), icon, punishes(tacticId\|"output"\|"behavior"), effect` | none — our weekly-modifier layer |
| **enemies** | built | `id, name, kind(boss/trash), baseHp, baseDamage, tags[], role?` · boss adds `stage, dungeonId→, abilityId→, testsTactic→` | `MonsterData` (stats, abilities, drop_table, scaling) |
| **packs** | built | `id, name, tags[], mobs[{enemyId→, count}]` | `EncounterData` + `MonsterSpawn` |
| **dungeons** | built | `id, name, theme, timerSeconds, signature, slots[{stage, kind, boss→ \| packTags[]}], lootTable[→items]` | `MissionData` + `MissionConundrumSlot` (mandatory ref **or** filtered-random — exactly our fixed-boss/random-trash shape) |
| **season** | built | `id, name, seasonAffix→, ratingTarget, affixCalendar[]` | mission availability/opportunity cadence |

### Items & economy

| Domain | Status | Key fields | EGM equivalent |
|---|---|---|---|
| **item-slots** | built | `id, name` | item `category`/slot enum |
| **items** | built | `id, name, slot→, specs[]→, note?` (templates) | `ItemBase` (slots, implicit stats, tags, `min_item_level`) |
| **loot-tables** | built | `id, dungeonId→, entries[{itemId→, weight, minKey?}]` (the weighted/keyed form; dungeon.lootTable is the simple catalog) | `MonsterDropTable` + `MonsterDropEntry` |
| **secondary-stats / affix-ranges** | built | `id, statId→, valueByKey{key→[min,max]}, weight, validSlots[]` | `AffixBase` (tiered `value_by_level`, `spawn_weight`, 21 `valid_on_*` flags, `is_local`) |
| **tier-sets** | built | `id, classId→, pieces[→items], bonus2pc, bonus4pc` | (EGM has no sets) |
| **crafting** | built | `id, op(exalt/chaos/vaal), costFormula, outcomes[]` | `CraftingDefinitions` (Exalt/Chaos/Vaal, cost = f(ilvl)) |
| **currencies** | built | `id, name, icon, tint, desc` | 4 int wallet props (EGM keeps currency primitive) |

### Systems config

| Domain | Status | Key fields | EGM equivalent |
|---|---|---|---|
| **tactics** | built | `id, name, icon, perPoint, starved` | none — our party-tactics layer |
| **morale-events** | built | `id, label, delta` | morale event constants in `GameSettings` |
| **buildings** | built | `id, name, icon, effect, cost?` | Quartermaster/infrastructure |
| **recruitment** | built | `pools[], pityFloor, namePool[], portraitPool[], levelMargin` | `RecruitData` + `RarityWeighting` (weighted selection) |
| **tuning** | built | nested: `sim, roleModel{tank/healer/dps}, hitQuality, aggression, morale{bands,departure}, loot, keystone, tacticsPoints` | **`GameSettings`** — the single 627-line tuning source. The most important pattern to copy: one file owns every constant. |
| **log-templates** | built | `id, kind(crit/death/mechanic/flavor/…), affixId?, lines[]` | event-log generation (we author flavor pools) |

---

## What EGM taught us (adopted)

- **String-id = filename = join key**, with a startup validation pass. Implemented as our Zod
  load + cross-ref checker.
- **`MissionConundrumSlot`** — a slot that is *either* a direct boss reference *or* a
  tag-filtered random pick. We use it verbatim for dungeon encounter slots (`boss` vs `packTags`).
- **A single `GameSettings`/`tuning.json`** as the one source of truth for all numeric tuning —
  so balancing never means hunting through content files.
- **Composable sub-resources** (stat bonus, conditional bonus, reward, spawn) reused across
  domains rather than re-declared.
- **Tiered value ranges + spawn weights** (`AffixBase.value_by_level`, `spawn_weight`) — the
  shape our `secondary-stats`/`loot-tables` scaffolds follow.
- **Content vs. instance split** (`ClassDefinition` vs `ExileData`) — our `/data` vs
  `/data/instances`.

### Deliberately *not* copied
- EGM's `override_*` "-1 sentinel" stat pattern — replaced by our role-model coefficients in
  `tuning.json` (cleaner for a role-based sim).
- Godot `.tres`/`ext_resource` binding — replaced by portable JSON + Zod.
- The turn/round/slot/stat assumptions baked into EGM combat data (would clash with our tick sim).

---

## Adding or changing content

1. Edit the JSON in `/data` (or add a new file).
2. If it's a new domain: add a Zod schema in `schema.ts`, one `index(...)` line + cross-ref
   checks in `index.ts`.
3. `npm run build` (or just load the app) — the validator fails loudly on any bad shape,
   duplicate id, or broken reference. Green = consistent.

CSV authoring (e.g. `PossibleTraits.csv`) can layer on later as a build step that compiles
CSV → the canonical JSON; the schema/loader downstream is unchanged.

---

*Companion to GDD Concept v1.10. All 26 domains are now authored, schema-validated, and cross-ref
checked. Remaining work is content depth (per-spec talent trees, the other 5 dungeons, full affix
calendars) and the GDD-tracked tuning passes — not new structure.*
