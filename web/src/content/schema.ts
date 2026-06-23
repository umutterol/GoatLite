import { z } from "zod"

/* ---- enums ---- */
export const Role = z.enum(["Tank", "Healer", "DPS"])
export const Position = z.enum(["Front", "Back"])
export const Rarity = z.enum(["Common", "Uncommon", "Rare", "Epic", "Legendary"])
export const Archetype = z.enum(["Wildcard", "Specialist", "Enabler", "Selfish", "Leader"])

/* ---- domain schemas (each entity has a string `id` = the join key) ---- */
export const ClassSchema = z.object({ id: z.string(), name: z.string(), blurb: z.string() })

export const SpecSchema = z.object({
  id: z.string(), name: z.string(), classId: z.string(), role: Role, position: Position,
  icon: z.string(), defaultProfile: z.string(), blurb: z.string(),
})

export const SkillCategory = z.enum(["Damage", "Healing", "Buff", "Utility", "CC", "Passive"])
// Player skills from the original GOAT roster. The turn-based formula/CD/baseValues are kept as
// REFERENCE metadata only — the 1s-tick sim does not consume them (names drive the replay UX).
export const SkillSchema = z.object({
  id: z.string(), name: z.string(), classId: z.string(), specId: z.string(),
  category: SkillCategory,
  formula: z.string(), description: z.string(), cd: z.number().int().nonnegative(),
  targetType: z.string(), damageType: z.string(), baseValues: z.string(), devStatus: z.string(),
})

/* ---- EGM-model combat (Phase 0): machine-readable player abilities + statuses ----
   data/abilities-player.json is the converted, runnable form of the prose SkillSchema above.
   Effects are intentionally LOOSE (passthrough) at Phase 0; the Phase 1 engine will formalise
   each effect `type` into a strict discriminated union once it consumes them. */
export const AbilityTargeting = z.object({
  side: z.enum(["enemy", "ally", "self"]),
  pattern: z.enum(["single", "adjacent", "all", "lowest-hp", "self", "aura"]),
  count: z.number().int().positive().optional(),
  band: z.enum(["front", "back", "any"]).optional(),
}).passthrough()

export const AbilityEffect = z.object({ type: z.string() }).passthrough()

export const PlayerAbilitySchema = z.object({
  id: z.string(), name: z.string(), classId: z.string(), specId: z.string(),
  category: SkillCategory,
  trigger: z.enum(["active", "passive"]),
  cooldownTurns: z.number().int().nonnegative(),
  windupTurns: z.number().nonnegative().optional(),
  recoveryTurns: z.number().nonnegative().optional(),
  targeting: AbilityTargeting,
  resourceCost: z.object({}).passthrough().optional(),
  generates: z.object({}).passthrough().optional(),
  effects: z.array(AbilityEffect).min(1),
  tags: z.array(z.string()).optional(),
}).passthrough()

export const StatModSchema = z.object({ stat: z.string(), amountPct: z.number() })
export const StatusDefSchema = z.object({
  id: z.string(), name: z.string(),
  kind: z.enum(["dot", "hot", "cc", "debuff", "buff", "shield", "resource"]),
  damageType: z.enum(["Physical", "Magic"]).optional(),
  // P.3: dispel TYPE (distinct from damageType school). A typed cleanse removes only matching statuses — Cleric strips
  // Magic/Curse, Lifebinder strips Nature/Poison — so the curse's type decides WHICH healer can answer it.
  dispel: z.enum(["Magic", "Curse", "Nature", "Poison"]).optional(),
  maxStacks: z.number().int().positive(),
  refresh: z.enum(["stack", "refresh", "replace", "strongest"]),
  perTick: z.boolean().optional(),
  statMods: z.array(StatModSchema).optional(),
  control: z.enum(["stun", "silence", "daze", "freeze"]).optional(),
  untargetable: z.boolean().optional(),
  defaultDurationTurns: z.number().int().nonnegative(),
  note: z.string().optional(),
})

export const StatDefSchema = z.object({
  id: z.string(), name: z.string(),
  category: z.enum(["primary", "core", "secondary", "defensive", "offensive", "utility"]),
  kind: z.enum(["flat", "percent"]), cap: z.number().optional(), desc: z.string(),
})

export const TacticSchema = z.object({
  id: z.string(), name: z.string(), icon: z.string(), perPoint: z.string(), starved: z.string(),
})

export const BehaviorProfileSchema = z.object({
  id: z.string(), name: z.string(), behavior: z.string(),
  // Phase K: machine-readable behaviour lists the brain walks (ids resolve to the code-side behaviour registry).
  // Absent → the brain falls back to the role default. `action`/`targetEnemy` are for party specs; `targetAlly` for enemies.
  action: z.array(z.string()).optional(),
  targetEnemy: z.array(z.string()).optional(),
  targetAlly: z.array(z.string()).optional(),
})
export const PotentialTagSchema = z.object({ id: z.string(), label: z.string() })

/* ---- Phase F: operator skills (the post-gear-cap power axis) ----
   A lean, data-driven registry (3 skills today) so role-specific skills can be added later without a rewrite.
   Per-point numbers / ceiling mapping / XP curve all live in tuning.operator.*, keyed by these ids. */
export const OperatorSkillSchema = z.object({
  id: z.string(), name: z.string(), satire: z.string(), effect: z.string(), icon: z.string(),
})

export const AffixSchema = z.object({
  id: z.string(), name: z.string(), tier: z.union([z.literal(1), z.literal(2)]),
  icon: z.string(), punishes: z.string(), effect: z.string(),
})

/* Phase F: traits are no longer inert prose. `combat` carries machine-readable modifiers wired into
   buildParty; `growth` biases the operator-skill layer. Both optional so legacy/flavor-only traits stay valid. */
export const TraitCombatSchema = z.object({
  outputPct: z.number().optional(),   // ± output (damage/healing)
  intakePct: z.number().optional(),   // ± damage taken (negative = takes less)
  critPct: z.number().optional(),     // ± crit chance, percentage points
  hpPct: z.number().optional(),       // ± max HP
}).strict()
export const TraitGrowthSchema = z.object({
  skill: z.string(),                  // operator-skill id (cross-ref validated in index.ts)
  ceilingDelta: z.number().optional(), // ± to that skill's rolled ceiling
  growthMult: z.number().optional(),   // × XP gain into that skill
}).strict()
export const TraitSchema = z.object({
  id: z.string(), name: z.string(), kind: z.enum(["start", "earned"]), rarity: Rarity,
  archetype: Archetype, netBudget: z.number(), effect: z.string(),
  type: z.enum(["Positive", "Negative"]).optional(),
  pool: z.number().int().min(1).max(4).optional(),
  trigger: z.string().optional(), tags: z.array(z.string()).optional(),
  combat: TraitCombatSchema.optional(),
  growth: TraitGrowthSchema.optional(),
})

export const AbilitySchema = z.object({
  id: z.string(), name: z.string(), kind: z.enum(["enemy", "spec"]),
  shape: z.string().optional(), tactic: z.string().optional(),
  telegraph: z.number().optional(), desc: z.string().optional(),
  // P.2: opt-in to the REAL enemy cast scheduler (a kickable dangerous cast that stacks to a wipe). Only the bosses
  // flagged here run the scheduler; other interrupt-test bosses keep the abstract dial (Ashveil stays dial-pure).
  interruptible: z.boolean().optional(),
  // P.3: opt-in to the spreading-curse mechanic — the dispel TYPE (e.g. "Nature") the boss applies as a stacking
  // party debuff that only the matching healer dispel resets. Flagged on the Mire's rot abilities.
  curse: z.enum(["Magic", "Curse", "Nature", "Poison"]).optional(),
})

export const EnemySchema = z.object({
  id: z.string(), name: z.string(), kind: z.enum(["boss", "trash"]),
  band: z.enum(["front", "back"]).optional(),   // EGM combat band: front=melee, back=ranged/caster (defaults to front)
  baseHp: z.number(), baseDamage: z.number(),
  icon: z.string().optional(), flavor: z.string().optional(), tags: z.array(z.string()).optional(),
  role: z.string().optional(), stage: z.number().optional(), dungeonId: z.string().optional(),
  abilityId: z.string().optional(), testsTactic: z.string().optional(),
  // C.10: opt-in boss-mechanic variant (both stay testsTactic:"cooldowns" so the dial mitigates).
  //   "burst" = a single hit on the lowest-HP non-tank /6s (soft Cleric-favoring lever).
  //   "rot"   = a flat tick on each non-tank /3s (soft HoT-favoring lever).
  // Both are tuned so the healer gap is only ~1-2 key levels of ceiling. Absent = the standard testsTactic mechanic.
  spikeProfile: z.enum(["burst", "rot"]).optional(),
  // C.8: per-enemy damage-school defense (default 0 → unmitigated, Ashveil unchanged). armour mitigates incoming
  // Physical, resist mitigates Magic (ratio formula in pipeline.resolveHit). The engine scales these by keyScale.
  // A soft ~1-2-key "bring mixed-school DPS" lever (the Pyreward Ossuary alternates high-armour and high-resist bosses).
  armour: z.number().optional(),
  resist: z.number().optional(),
  // P.4 (P11 recut): kill-priority "bodyguard" mechanic. A `shielded` enemy takes near-zero damage (sim.shieldGuardReductionPct)
  // while ANY `guarding` ally in its stage is alive — so you must kill the guard FIRST to expose it. Absent = normal enemy.
  guarding: z.boolean().optional(),
  shielded: z.boolean().optional(),
  // P.4 (P8 unify): a `shielded` boss SUMMONS this guard enemy (id) on a cadence whenever none is alive (a real mid-fight add).
  summonsId: z.string().optional(),
})

export const PackSchema = z.object({
  id: z.string(), name: z.string(), tags: z.array(z.string()),
  mobs: z.array(z.object({ enemyId: z.string(), count: z.number().int().positive() })),
})

export const DungeonSlotSchema = z.object({
  stage: z.number().int(), kind: z.enum(["trash", "boss"]),
  boss: z.string().optional(), packTags: z.array(z.string()).optional(),
})
export const DungeonSchema = z.object({
  id: z.string(), name: z.string(), theme: z.string(), timerSeconds: z.number(),
  signature: z.string(), slots: z.array(DungeonSlotSchema), lootTable: z.array(z.string()),
})

export const ItemSlotSchema = z.object({ id: z.string(), name: z.string() })
export const ItemSchema = z.object({
  id: z.string(), name: z.string(), slot: z.string(), specs: z.array(z.string()), note: z.string().optional(),
})
export const CurrencySchema = z.object({ id: z.string(), name: z.string(), icon: z.string(), tint: z.string(), desc: z.string() })
export const BuildingSchema = z.object({ id: z.string(), name: z.string(), icon: z.string(), effect: z.string() })
export const MoraleEventSchema = z.object({ id: z.string(), label: z.string(), delta: z.number() })

/* M.4 guild-feed barks: event → archetype → templates (voice attaches to personality). `_doc` passthrough allowed. */
export const BarksSchema = z.object({
  events: z.record(z.string(), z.record(z.string(), z.array(z.string()))),
  moods: z.object({ low: z.array(z.string()), high: z.array(z.string()) }).optional(),
}).passthrough()

/* ---- previously-scaffolded domains, now filled ---- */
export const LogKind = z.enum(["normal", "crit", "dodge", "death", "mechanic", "heal", "flavor", "good"])

/* §B (M2): talent ability-override — enumerated, STRICT patch kinds applied to a clone of a named ability at
   buildParty time (the shared content object is never mutated). Closed kinds + enum keys mean a typo fails Zod
   validation rather than silently no-opping; the cross-ref validator checks `abilityId` exists. */
export const AbilityOverrideSchema = z.discriminatedUnion("kind", [
  z.object({ kind: z.literal("cooldown"), abilityId: z.string(), cooldownTurns: z.number().int().nonnegative() }).strict(),
  z.object({
    kind: z.literal("targeting"), abilityId: z.string(),
    pattern: z.enum(["single", "adjacent", "all", "lowest-hp", "self", "aura"]).optional(),
    count: z.number().int().positive().optional(),
    band: z.enum(["front", "back", "any"]).optional(),
  }).strict(),
  z.object({  // patch a numeric param on a special-mechanic effect (selected by mechanic)
    kind: z.literal("param"), abilityId: z.string(), mechanic: z.string(),
    key: z.enum(["perStackPct", "healHpPct", "healPctOfDamage", "redirectPct", "reductionPct", "splashCount", "splashPct", "amountPct", "buffAmountPct", "buffDurationTurns", "durationTurns", "stacks", "chancePct", "addTurns", "extendTurns", "reduceTurns", "parryChancePct"]),
    value: z.number(),
  }).strict(),
  z.object({  // patch a top-level field on the ability's primary damage/heal/shield/dot/hot effect
    kind: z.literal("scalar"), abilityId: z.string(),
    effectType: z.enum(["damage", "heal", "shield", "dot", "hot", "buff", "debuff"]),
    field: z.enum(["base", "scale", "durationTurns", "stacks", "amountPct"]), value: z.number(),
  }).strict(),
  z.object({  // add a conditional damage modifier to the ability's primary damage effect (execute / band amps)
    kind: z.literal("addModifier"), abilityId: z.string(),
    when: z.object({ type: z.string(), value: z.number().optional(), band: z.enum(["front", "back"]).optional(), status: z.string().optional() }).strict().optional(),
    multiplyDamage: z.number(),
  }).strict(),
])

/* §E (M3a): talent event rider — on a combat event (hit/crit/kill), run an action. Strict shape; actions are
   strict sub-objects. on-parry/detonate/expiry/cleanse triggers are reserved (schema-allowed; engine-wired when authored). */
export const EventRiderSchema = z.object({
  trigger: z.enum(["on-hit", "on-crit", "on-kill", "on-parry", "on-detonate", "on-expiry", "on-cleanse"]),
  ability: z.string().optional(),     // gate to a specific ability id (else fires on any qualifying hit incl. basics)
  chancePct: z.number().optional(),   // proc chance (default 100)
  applyStatus: z.object({ statusId: z.string(), target: z.enum(["enemy-target", "self", "lowest-ally"]).optional(), durationTurns: z.number().optional(), stacks: z.number().int().positive().optional() }).strict().optional(),
  adjustCooldown: z.object({ abilityId: z.string(), deltaTurns: z.number() }).strict().optional(),   // negative reduces; <= -900 = full reset to now
  refundResource: z.object({ resource: z.string(), amount: z.number() }).strict().optional(),
  heal: z.object({ target: z.enum(["self", "lowest-ally"]), pctOfDamage: z.number().optional(), pctOfMaxHp: z.number().optional() }).strict().optional(),
}).strict()

export const TalentOptionSchema = z.object({
  id: z.string(), name: z.string(), effect: z.string(), tags: z.array(z.string()),
  default: z.boolean().optional(),   // the balanced pick a member starts on
  // machine-readable effect the sim applies. All 5 nodes are wired (H.3 added intakePct/critPct + nodes 3-5).
  effects: z.object({
    maxHpPct: z.number().optional(),
    dmgPct: z.number().optional(),
    intakePct: z.number().optional(),   // ± damage taken (flat; negative = takes less) — folds into the operator intake channel
    critPct: z.number().optional(),     // ± crit chance, percentage points
    // §A keystone: the talent onlyIf is routed through the engine's shared condHolds() evaluator. Closed set — a typo
    // fails validation rather than silently un-gating. `value` is optional (status/band gates don't use it).
    onlyIf: z.object({
      type: z.enum([
        "targetHpBelowPct", "enemiesAtLeast", "enemiesAtMost",
        "selfHpBelowPct", "allyHpBelowPct", "lowestAllyHpBelowPct",
        "selfStacksAtLeast", "selfHoldsHardThreat",
        "targetHasStatus", "selfHasStatus", "targetBand",
      ]),
      value: z.number().optional(),
      resource: z.string().optional(),               // selfStacksAtLeast (default "rampage")
      status: z.string().optional(),                 // target/selfHasStatus
      minStacks: z.number().optional(),              // target/selfHasStatus
      band: z.enum(["front", "back"]).optional(),    // targetBand
    }).optional(),
    abilityOverrides: z.array(AbilityOverrideSchema).optional(),   // §B (M2): patch a named ability's params at buildParty time
    eventRiders: z.array(EventRiderSchema).optional(),             // §E (M3a): on hit/crit/kill → applyStatus / adjustCooldown / refundResource / heal
    atonement: z.object({ disableAbilityId: z.string().optional(), partyWhenLowestAllyBelowPct: z.number().optional() }).strict().optional(),   // §D (M4): atonement disable / party-swap (magnitude → use an M2 `param` override)
  }).optional(),
})
export const TalentNodeSchema = z.object({
  id: z.string(), node: z.number().int().min(1).max(5), name: z.string(),
  specId: z.string().optional(),   // M7: per-spec tree (absent = global node, applies to every spec — back-compat with the MVP shared nodes)
  options: z.array(TalentOptionSchema),
})

export const LootTableSchema = z.object({
  id: z.string(), dungeonId: z.string(),
  entries: z.array(z.object({ itemId: z.string(), weight: z.number().int().positive(), minKey: z.number().int().optional() })),
})

export const SecondaryStatSchema = z.object({
  id: z.string(), name: z.string(), statId: z.string(), weight: z.number().int().positive(),
  phase: z.number().int().optional(),
  valueByKey: z.record(z.string(), z.tuple([z.number(), z.number()])),
  validSlots: z.array(z.string()),
})

export const TierSetSchema = z.object({
  id: z.string(), name: z.string(), classId: z.string(),
  bonus2pc: z.string(), bonus4pc: z.string(),
  pieces: z.array(z.string()), note: z.string().optional(),
})

export const CraftingOpSchema = z.object({
  id: z.string(), op: z.enum(["reroll", "add", "salvage", "corrupt"]), name: z.string(),
  currency: z.string(), costFormula: z.string(), phase: z.number().int().optional(), desc: z.string(),
  outcomes: z.array(z.object({ weight: z.number(), effect: z.string() })).optional(),
})

export const RecruitmentSchema = z.object({
  initialDraft: z.object({
    tabs: z.array(z.string()), candidatesPerTab: z.number(), pick: z.number(), pityFloor: z.string(),
  }),
  traitDistribution: z.record(z.string(), z.number()),
  rosterCap: z.number(),
  levelMargin: z.object({ min: z.number(), max: z.number(), note: z.string() }),
  sources: z.array(z.object({
    id: z.string(), cadence: z.string(), count: z.number().optional(),
    paid: z.boolean(), currency: z.string().optional(), note: z.string(),
  })),
  namePool: z.array(z.string()),
  portraitPool: z.array(z.string()),
})

export const SeasonSchema = z.object({
  id: z.string(), name: z.string(), seasonAffix: z.string().nullable(),
  ratingTarget: z.number(), dungeons: z.array(z.string()), note: z.string().optional(),
  affixCalendar: z.array(z.object({
    week: z.number().int(), tier1: z.string(), tier2: z.array(z.string()),
  })),
})

export const LogTemplateSchema = z.object({
  id: z.string(), kind: LogKind, affixId: z.string().optional(), lines: z.array(z.string()),
})

export const TuningSchema = z.object({
  sim: z.record(z.string(), z.number()),
  roleModel: z.record(z.string(), z.record(z.string(), z.number())),
  hitQuality: z.record(z.string(), z.unknown()),
  aggression: z.record(z.string(), z.object({ output: z.number(), avoidableIntake: z.number() })),
  morale: z.record(z.string(), z.unknown()),
  loot: z.record(z.string(), z.unknown()),
  keystone: z.object({ startLevel: z.number(), floorLevel: z.number() }),
  tacticsPoints: z.object({ total: z.number(), maxPerCategory: z.number() }),
  operator: z.record(z.string(), z.unknown()),   // Phase F: per-point %s, ceiling mapping, XP curve, COR weights, gear cap
})

/* sample save / instance data (references content by id) */
export const RosterMemberSchema = z.object({
  id: z.string(), name: z.string(), title: z.string(), specId: z.string(),
  ilvl: z.number(), morale: z.number(), portrait: z.string(),
  traitIds: z.array(z.string()), note: z.string().optional(),
})
export const SaveSchema = z.object({
  _note: z.string().optional(),
  keystone: z.object({ dungeonId: z.string(), level: z.number(), best: z.number(), rating: z.number() }),
  wallet: z.record(z.string(), z.number()),
  week: z.object({ number: z.number(), affixes: z.array(z.string()) }),
  roster: z.array(RosterMemberSchema),
})

/* ---- inferred types ---- */
export type ClassDef = z.infer<typeof ClassSchema>
export type Spec = z.infer<typeof SpecSchema>
export type Skill = z.infer<typeof SkillSchema>
export type PlayerAbility = z.infer<typeof PlayerAbilitySchema>
export type AbilityEffectT = z.infer<typeof AbilityEffect>
export type StatusDef = z.infer<typeof StatusDefSchema>
export type StatDef = z.infer<typeof StatDefSchema>
export type Tactic = z.infer<typeof TacticSchema>
export type BehaviorProfile = z.infer<typeof BehaviorProfileSchema>
export type PotentialTag = z.infer<typeof PotentialTagSchema>
export type OperatorSkill = z.infer<typeof OperatorSkillSchema>
export type Affix = z.infer<typeof AffixSchema>
export type Trait = z.infer<typeof TraitSchema>
export type TraitCombat = z.infer<typeof TraitCombatSchema>
export type TraitGrowth = z.infer<typeof TraitGrowthSchema>
export type Ability = z.infer<typeof AbilitySchema>
export type Enemy = z.infer<typeof EnemySchema>
export type Pack = z.infer<typeof PackSchema>
export type Dungeon = z.infer<typeof DungeonSchema>
export type ItemSlot = z.infer<typeof ItemSlotSchema>
export type Item = z.infer<typeof ItemSchema>
export type Currency = z.infer<typeof CurrencySchema>
export type Building = z.infer<typeof BuildingSchema>
export type MoraleEvent = z.infer<typeof MoraleEventSchema>
export type Tuning = z.infer<typeof TuningSchema>
export type RosterMember = z.infer<typeof RosterMemberSchema>
export type Save = z.infer<typeof SaveSchema>
export type TalentNode = z.infer<typeof TalentNodeSchema>
export type LootTable = z.infer<typeof LootTableSchema>
export type SecondaryStat = z.infer<typeof SecondaryStatSchema>
export type TierSet = z.infer<typeof TierSetSchema>
export type CraftingOp = z.infer<typeof CraftingOpSchema>
export type Recruitment = z.infer<typeof RecruitmentSchema>
export type Season = z.infer<typeof SeasonSchema>
export type LogTemplate = z.infer<typeof LogTemplateSchema>
