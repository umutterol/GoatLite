# Combat EGM Migration — Phase 0: Data Formats

Status: **draft for review.** Defines the data shapes for the new combat engine before we convert all 60 skills. Nothing here is wired into the sim yet.

Decisions this builds on (see memory `combat-model-egm-migration`):
- Hybrid skills (players keep skills, rebuilt on EGM's damage engine)
- Abstract front/back bands (no 2D)
- Continuous-seconds timeline, attack-speed driven

---

## 1. Stat model — reuse what's already there

GoatLite does **not** have STR/AGI/INT/VIT. Those appear only in the original-GOAT skill prose. The real stats are `ilvl + power + crit/haste/mastery/versatility` (`data/stats.json`). We reuse them:

| Stat | Source | Job in the new engine |
|------|--------|------------------------|
| `ilvl` | gear average | drives `maxHp` and `power` by role |
| `power` | ilvl × role | **the scaling stat** — skill damage/healing = `base + scale × power` |
| `maxHp` / `hp` | ilvl × role | health; also the scaling base for VIT-flavored skills (shields) |
| `mana` / `manaRegen` | role | healer resource (OOM still possible) |
| `armour` | tank gear | mitigates **Physical** (existing ratio formula) |
| `resist` | gear (new, can be 0 early) | mitigates **Magic** (same ratio shape) |
| `crit` | secondary | crit chance % |
| `critMult` | tuning (1.5–2.0) | crit damage multiplier |
| `haste` | secondary | shortens `attackIntervalSec` (acts more often) |
| `versatility` | secondary | dodge chance + flat damage reduction |
| `mastery` | secondary | spec-specific hook (no-op until per-spec design) |
| `attackIntervalSec` | base, modified by haste | seconds between auto-actions on the timeline |

**Damage-type → mitigation:** skills are `Physical` (→ armour) or `Magic` (→ resist). `None` skills (buffs/utility) skip mitigation.

**Stat mapping for formulas:** the original STR/AGI/INT label is collapsed into `power` (single scaler). VIT-scaling skills (e.g. shields) use `scaleStat: "maxHp"` instead.

---

## 2. Time: author in turns, run in seconds

All 60 skills are designed in **turns** (`cd: 3`, "Daze for 1 turn"). We keep authoring in turns and convert at load:

```
seconds = turns × tuning.secondsPerTurn      // e.g. secondsPerTurn = 3
```

So skill data stays readable and matches the original design; the engine runs continuous seconds. Source fields are `cooldownTurns`, `durationTurns`.

---

## 3. Ability (skill) format

An ability is **a list of typed effects**, plus optional targeting, conditions, and resource cost. This is extensible and covers all six categories (Damage / Healing / Buff / Utility / CC / Passive).

```jsonc
{
  "id": "string", "name": "string", "classId": "string", "specId": "string",
  "category": "Damage | Healing | Buff | Utility | CC | Passive",
  "trigger": "active | passive",        // passive = always-on / on-event
  "cooldownTurns": 0,
  "windupTurns": 0, "recoveryTurns": 0, // optional EGM-style telegraph (default 0)
  "targeting": {
    "side": "enemy | ally | self",
    "pattern": "single | adjacent | all | lowest-hp | self | aura",
    "count": 1,                          // for adjacent/multi
    "band": "front | back | any"         // backline targeting etc.
  },
  "resourceCost": { "mana": 0, "hpPct": 0, "stacks": 0 },   // optional
  "generates": { "stacks": 1, "resource": "rampage" },      // optional (Rampage etc.)
  "effects": [ /* Effect[] — see below, applied in order */ ],
  "tags": ["execute", "stealth"]         // optional
}
```

### Effect types (discriminated by `type`)

```jsonc
// direct damage
{ "type": "damage", "damageType": "Physical|Magic", "base": 40, "scale": 0.6,
  "scaleStat": "power",                   // or "maxHp" for VIT-flavored
  "critable": true,
  "modifiers": [ /* conditional bonuses, see below */ ] }

// healing
{ "type": "heal", "base": 60, "scale": 1.2, "scaleStat": "power", "modifiers": [] }

// apply a status / ailment / DoT / CC (see §4)
{ "type": "applyStatus", "status": "bleed", "chancePct": 100,
  "durationTurns": 3, "stacks": 1,
  "magnitudeScale": 0.05, "magnitudeStat": "power",   // for DoTs: dmg/turn
  "onlyIf": { /* Condition */ } }

// timed stat buff/debuff on the target(s)
{ "type": "buff",  "stat": "armour", "amountPct": 10, "durationTurns": 2 }
{ "type": "debuff","stat": "power",  "amountPct": -15, "durationTurns": 2 }

// absorb shield
{ "type": "shield", "base": 80, "scale": 1.0, "scaleStat": "maxHp", "durationTurns": 3 }

// threat
{ "type": "taunt", "kind": "hard|soft", "durationTurns": 2 }

// support
{ "type": "cleanse", "count": 2 }
{ "type": "interrupt" }

// escape hatch for the ~handful of truly unique mechanics
{ "type": "special", "mechanic": "shield-wall-block", "params": { "blocks": 2, "reflectPct": 50 } }
```

### Conditions & modifiers

A `Condition` gates or boosts. Used as `onlyIf` on an effect, or inside a damage effect's `modifiers`:

```jsonc
// condition shapes
{ "type": "targetHpBelowPct", "value": 20 }
{ "type": "selfHitSinceLastAction" }          // Revenge
{ "type": "targetHasStatus", "status": "poison" }
{ "type": "targetBand", "band": "back" }       // vs backline

// modifier: extra damage when a condition holds, or per stack of a status
{ "when": { "type": "targetHpBelowPct", "value": 20 }, "multiplyDamage": 2.0 }
{ "perStackOf": "poison", "onTarget": true, "multiplyDamage": 0.20 }   // +20% per stack
```

---

## 4. Status / ailment format

Our ailment set (from the skills): **Bleed, Poison, Burn, Chill, Daze, Stun, Freeze, Mark, Silence**, plus self-resources like **Rampage**. They all use one shape, modeled on EGM's status system (stacks, refresh mode, per-tick or stat-mod, magnitude set at application):

```jsonc
{
  "id": "bleed", "name": "Bleed",
  "kind": "dot | cc | debuff | buff | shield | resource",
  "damageType": "Physical",              // dots only
  "maxStacks": 1,
  "refresh": "stack | refresh | replace | strongest",
  "perTick": true,                       // dots: damage/turn = magnitude set by the applying skill
  "statMods": [ { "stat": "haste", "amountPct": -25 } ],  // chill/mark/buffs
  "control": "stun | silence | daze",    // cc only (blocks all actions / actives only / loses next action)
  "defaultDurationTurns": 3
}
```

Examples needed for the two proof skills below:

```jsonc
{ "id": "bleed", "name": "Bleed", "kind": "dot", "damageType": "Physical",
  "maxStacks": 1, "refresh": "refresh", "perTick": true, "defaultDurationTurns": 3 }

{ "id": "daze", "name": "Daze", "kind": "cc", "control": "daze",
  "maxStacks": 1, "refresh": "replace", "defaultDurationTurns": 1 }
```

---

## 5. Proof: two converted skills

### Shield Bash (simple — damage + chance to apply CC)
Source: *"Basic attack with 15% chance to Daze target for 1 turn"* — `40 + 60% STR`, cd 0, Physical.

```jsonc
{
  "id": "shield-bash", "name": "Shield Bash", "classId": "warrior", "specId": "guardian",
  "category": "Damage", "trigger": "active", "cooldownTurns": 0,
  "targeting": { "side": "enemy", "pattern": "single" },
  "effects": [
    { "type": "damage", "damageType": "Physical", "base": 40, "scale": 0.60, "scaleStat": "power", "critable": true },
    { "type": "applyStatus", "status": "daze", "chancePct": 15, "durationTurns": 1 }
  ]
}
```

### Revenge (complex — conditional damage + conditional DoT)
Source: *"If hit last turn: 2x damage + apply Bleed (5% STR/turn for 3 turns)"* — `60 + 100% STR`, cd 4, Physical.

```jsonc
{
  "id": "revenge", "name": "Revenge", "classId": "warrior", "specId": "guardian",
  "category": "Damage", "trigger": "active", "cooldownTurns": 4,
  "targeting": { "side": "enemy", "pattern": "single" },
  "effects": [
    { "type": "damage", "damageType": "Physical", "base": 60, "scale": 1.0, "scaleStat": "power", "critable": true,
      "modifiers": [ { "when": { "type": "selfHitSinceLastAction" }, "multiplyDamage": 2.0 } ] },
    { "type": "applyStatus", "status": "bleed", "chancePct": 100, "durationTurns": 3,
      "magnitudeScale": 0.05, "magnitudeStat": "power",
      "onlyIf": { "type": "selfHitSinceLastAction" } }
  ]
}
```

---

## 6. Honest coverage note

About **8–10 of the 60 skills** have one-of-a-kind mechanics that won't be pure data — they use the `special` escape hatch and a small hand-coded handler in the engine. Known ones:

- Shield Wall (block next N attacks + reflect)
- Camouflage (stealth / untargetable + empowered next hit)
- Smite/Holy Fire Atonement (heal an ally from damage dealt)
- Guardian's Oath / Spirit Link (redirect a % of an ally's damage)
- Blessing of Protection (attack immunity)
- Ignite / Conflagration (detonate / spread Burn stacks)
- Vital Surge / Flourish (consume HoT stacks for burst)
- Rhythm Reset / Crescendo (cooldown manipulation / extra action)

Everything else is pure data in the format above.

---

## 7. Next (after format sign-off)

1. Add the Zod schemas (`AbilitySchema`, `EffectSchema`, `StatusDefSchema`) to `web/src/content/schema.ts`.
2. Convert all 60 skills `data/skills.json` → `data/abilities-player.json` (good parallel workflow; verify each against its prose).
3. Author the ~12 status defs `data/statuses.json`.
4. Then Phase 1 (the engine that runs all this).
