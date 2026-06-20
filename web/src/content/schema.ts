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
})

export const EnemySchema = z.object({
  id: z.string(), name: z.string(), kind: z.enum(["boss", "trash"]),
  band: z.enum(["front", "back"]).optional(),   // EGM combat band: front=melee, back=ranged/caster (defaults to front)
  baseHp: z.number(), baseDamage: z.number(),
  icon: z.string().optional(), flavor: z.string().optional(), tags: z.array(z.string()).optional(),
  role: z.string().optional(), stage: z.number().optional(), dungeonId: z.string().optional(),
  abilityId: z.string().optional(), testsTactic: z.string().optional(),
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

/* ---- previously-scaffolded domains, now filled ---- */
export const LogKind = z.enum(["normal", "crit", "dodge", "death", "mechanic", "heal", "flavor", "good"])

export const TalentOptionSchema = z.object({
  id: z.string(), name: z.string(), effect: z.string(), tags: z.array(z.string()),
  default: z.boolean().optional(),   // the balanced pick a member starts on
  // machine-readable effect the sim applies. All 5 nodes are wired (H.3 added intakePct/critPct + nodes 3-5).
  effects: z.object({
    maxHpPct: z.number().optional(),
    dmgPct: z.number().optional(),
    intakePct: z.number().optional(),   // ± damage taken (flat; negative = takes less) — folds into the operator intake channel
    critPct: z.number().optional(),     // ± crit chance, percentage points
    // condition type is a closed set the engine understands — a typo fails validation rather than silently un-gating
    onlyIf: z.object({ type: z.enum(["targetHpBelowPct", "enemiesAtLeast", "enemiesAtMost"]), value: z.number() }).optional(),
  }).optional(),
})
export const TalentNodeSchema = z.object({
  id: z.string(), node: z.number().int().min(1).max(5), name: z.string(),
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
