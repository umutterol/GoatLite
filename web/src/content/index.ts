import { z, type ZodType } from "zod"
import * as S from "./schema"

import classesJson from "@data/classes.json"
import specsJson from "@data/specs.json"
import skillsJson from "@data/skills.json"
import statsJson from "@data/stats.json"
import tacticsJson from "@data/tactics.json"
import profilesJson from "@data/behavior-profiles.json"
import potentialsJson from "@data/potentials.json"
import operatorSkillsJson from "@data/operator-skills.json"
import affixesJson from "@data/affixes.json"
import traitsJson from "@data/traits.json"
import abilitiesJson from "@data/abilities.json"
import enemiesJson from "@data/enemies.json"
import packsJson from "@data/packs.json"
import dungeonsJson from "@data/dungeons.json"
import itemSlotsJson from "@data/item-slots.json"
import itemsJson from "@data/items.json"
import currenciesJson from "@data/currencies.json"
import buildingsJson from "@data/buildings.json"
import moraleEventsJson from "@data/morale-events.json"
import tuningJson from "@data/tuning.json"
import talentsJson from "@data/talents.json"
import lootTablesJson from "@data/loot-tables.json"
import secondaryStatsJson from "@data/secondary-stats.json"
import tierSetsJson from "@data/tier-sets.json"
import craftingJson from "@data/crafting.json"
import recruitmentJson from "@data/recruitment.json"
import seasonsJson from "@data/season.json"
import logTemplatesJson from "@data/log-templates.json"
import abilitiesPlayerJson from "@data/abilities-player.json"
import statusesJson from "@data/statuses.json"
import saveJson from "@data/instances/sample-roster.json"

/* index an array of entities into a Map<id, T>, validating shape + uniqueness */
function index<T extends { id: string }>(schema: ZodType<T>, json: unknown, domain: string): Map<string, T> {
  const arr = z.array(schema).parse(json) as T[]
  const map = new Map<string, T>()
  for (const e of arr) {
    if (map.has(e.id)) throw new Error(`[content] duplicate id '${e.id}' in ${domain}`)
    map.set(e.id, e)
  }
  return map
}

const classes = index(S.ClassSchema, classesJson, "classes")
const specs = index(S.SpecSchema, specsJson, "specs")
const skills = index(S.SkillSchema, skillsJson, "skills")
const playerAbilities = index(S.PlayerAbilitySchema, abilitiesPlayerJson, "player-abilities")
const statuses = index(S.StatusDefSchema, statusesJson, "statuses")
const stats = index(S.StatDefSchema, statsJson, "stats")
const tactics = index(S.TacticSchema, tacticsJson, "tactics")
const profiles = index(S.BehaviorProfileSchema, profilesJson, "behavior-profiles")
const potentials = index(S.PotentialTagSchema, potentialsJson, "potentials")
const operatorSkills = index(S.OperatorSkillSchema, operatorSkillsJson, "operator-skills")
const affixes = index(S.AffixSchema, affixesJson, "affixes")
const traits = index(S.TraitSchema, traitsJson, "traits")
const abilities = index(S.AbilitySchema, abilitiesJson, "abilities")
const enemies = index(S.EnemySchema, enemiesJson, "enemies")
const packs = index(S.PackSchema, packsJson, "packs")
const dungeons = index(S.DungeonSchema, dungeonsJson, "dungeons")
const itemSlots = index(S.ItemSlotSchema, itemSlotsJson, "item-slots")
const items = index(S.ItemSchema, itemsJson, "items")
const currencies = index(S.CurrencySchema, currenciesJson, "currencies")
const buildings = index(S.BuildingSchema, buildingsJson, "buildings")
const moraleEvents = index(S.MoraleEventSchema, moraleEventsJson, "morale-events")
const talents = index(S.TalentNodeSchema, talentsJson, "talents")
const lootTables = index(S.LootTableSchema, lootTablesJson, "loot-tables")
const secondaryStats = index(S.SecondaryStatSchema, secondaryStatsJson, "secondary-stats")
const tierSets = index(S.TierSetSchema, tierSetsJson, "tier-sets")
const crafting = index(S.CraftingOpSchema, craftingJson, "crafting")
const seasons = index(S.SeasonSchema, seasonsJson, "season")
const logTemplates = index(S.LogTemplateSchema, logTemplatesJson, "log-templates")
const tuning = S.TuningSchema.parse(tuningJson)
const recruitment = S.RecruitmentSchema.parse(recruitmentJson)
const save = S.SaveSchema.parse(saveJson)

/* ---- cross-reference validation (mirrors EGM's content_validation_test) ---- */
const errors: string[] = []
const ref = (ok: boolean, msg: string) => { if (!ok) errors.push(msg) }
const AFFIX_PUNISH_SPECIAL = new Set(["output", "behavior"])

for (const s of specs.values()) {
  ref(classes.has(s.classId), `spec '${s.id}' → unknown classId '${s.classId}'`)
  ref(profiles.has(s.defaultProfile), `spec '${s.id}' → unknown defaultProfile '${s.defaultProfile}'`)
}
for (const sk of skills.values()) {
  ref(classes.has(sk.classId), `skill '${sk.id}' → unknown classId '${sk.classId}'`)
  ref(specs.has(sk.specId), `skill '${sk.id}' → unknown specId '${sk.specId}'`)
}
for (const ab of playerAbilities.values()) {
  ref(classes.has(ab.classId), `player-ability '${ab.id}' → unknown classId '${ab.classId}'`)
  ref(specs.has(ab.specId), `player-ability '${ab.id}' → unknown specId '${ab.specId}'`)
  for (const eff of ab.effects) {
    const e = eff as Record<string, unknown>
    if (e.type === "applyStatus" && typeof e.status === "string")
      ref(statuses.has(e.status), `player-ability '${ab.id}' → unknown status '${e.status}'`)
  }
}
for (const a of affixes.values())
  ref(tactics.has(a.punishes) || AFFIX_PUNISH_SPECIAL.has(a.punishes), `affix '${a.id}' → unknown punishes '${a.punishes}'`)
for (const ab of abilities.values())
  if (ab.tactic) ref(tactics.has(ab.tactic), `ability '${ab.id}' → unknown tactic '${ab.tactic}'`)
for (const t of traits.values()) {
  for (const tag of t.tags ?? []) ref(potentials.has(tag), `trait '${t.id}' → unknown potential tag '${tag}'`)
  if (t.growth) ref(operatorSkills.has(t.growth.skill), `trait '${t.id}' → growth references unknown operator skill '${t.growth.skill}'`)
}
// Phase F: the operator tuning block's tag→skill ceiling map must reference known skills + potential tags
{
  const op = tuning.operator as { ceiling?: { byTag?: Record<string, string[]> } }
  for (const [skillId, tags] of Object.entries(op.ceiling?.byTag ?? {})) {
    ref(operatorSkills.has(skillId), `tuning.operator.ceiling.byTag → unknown operator skill '${skillId}'`)
    for (const tag of tags) ref(potentials.has(tag), `tuning.operator.ceiling.byTag['${skillId}'] → unknown potential tag '${tag}'`)
  }
}
for (const e of enemies.values()) {
  if (e.abilityId) ref(abilities.has(e.abilityId), `enemy '${e.id}' → unknown abilityId '${e.abilityId}'`)
  if (e.testsTactic) ref(tactics.has(e.testsTactic), `enemy '${e.id}' → unknown testsTactic '${e.testsTactic}'`)
  if (e.dungeonId) ref(dungeons.has(e.dungeonId), `enemy '${e.id}' → unknown dungeonId '${e.dungeonId}'`)
}
for (const p of packs.values())
  for (const m of p.mobs) ref(enemies.has(m.enemyId), `pack '${p.id}' → unknown enemyId '${m.enemyId}'`)
for (const d of dungeons.values()) {
  for (const slot of d.slots) {
    if (slot.kind === "boss") ref(!!slot.boss && enemies.has(slot.boss), `dungeon '${d.id}' stage ${slot.stage} → unknown boss '${slot.boss}'`)
    if (slot.kind === "trash") ref((slot.packTags ?? []).some((tag) => [...packs.values()].some((p) => p.tags.includes(tag))), `dungeon '${d.id}' stage ${slot.stage} → no pack matches tags ${JSON.stringify(slot.packTags)}`)
  }
  for (const itemId of d.lootTable) ref(items.has(itemId), `dungeon '${d.id}' lootTable → unknown item '${itemId}'`)
}
for (const it of items.values()) {
  ref(itemSlots.has(it.slot), `item '${it.id}' → unknown slot '${it.slot}'`)
  for (const sp of it.specs) ref(specs.has(sp), `item '${it.id}' → unknown spec '${sp}'`)
}
ref(dungeons.has(save.keystone.dungeonId), `save → unknown keystone dungeon '${save.keystone.dungeonId}'`)
for (const aff of save.week.affixes) ref(affixes.has(aff), `save → unknown week affix '${aff}'`)
for (const cur of Object.keys(save.wallet)) ref(currencies.has(cur), `save → unknown wallet currency '${cur}'`)
for (const m of save.roster) {
  ref(specs.has(m.specId), `roster '${m.id}' → unknown specId '${m.specId}'`)
  for (const tid of m.traitIds) ref(traits.has(tid), `roster '${m.id}' → unknown traitId '${tid}'`)
}
for (const t of talents.values())
  for (const o of t.options) for (const tag of o.tags) ref(potentials.has(tag), `talent '${t.id}' option '${o.id}' → unknown tag '${tag}'`)
for (const lt of lootTables.values()) {
  ref(dungeons.has(lt.dungeonId), `loot-table '${lt.id}' → unknown dungeon '${lt.dungeonId}'`)
  for (const e of lt.entries) ref(items.has(e.itemId), `loot-table '${lt.id}' → unknown item '${e.itemId}'`)
}
for (const ss of secondaryStats.values()) {
  ref(stats.has(ss.statId), `secondary-stat '${ss.id}' → unknown statId '${ss.statId}'`)
  for (const sl of ss.validSlots) ref(itemSlots.has(sl), `secondary-stat '${ss.id}' → unknown slot '${sl}'`)
}
for (const set of tierSets.values()) {
  ref(classes.has(set.classId), `tier-set '${set.id}' → unknown classId '${set.classId}'`)
  for (const pc of set.pieces) ref(items.has(pc), `tier-set '${set.id}' → unknown piece '${pc}'`)
}
for (const c of crafting.values())
  ref(currencies.has(c.currency), `crafting '${c.id}' → unknown currency '${c.currency}'`)
for (const src of recruitment.sources)
  if (src.currency) ref(currencies.has(src.currency), `recruitment source '${src.id}' → unknown currency '${src.currency}'`)
for (const se of seasons.values()) {
  if (se.seasonAffix) ref(affixes.has(se.seasonAffix), `season '${se.id}' → unknown seasonAffix '${se.seasonAffix}'`)
  for (const dg of se.dungeons) ref(dungeons.has(dg), `season '${se.id}' → unknown dungeon '${dg}'`)
  for (const wk of se.affixCalendar) {
    ref(affixes.has(wk.tier1), `season '${se.id}' week ${wk.week} → unknown tier1 '${wk.tier1}'`)
    for (const a2 of wk.tier2) ref(affixes.has(a2), `season '${se.id}' week ${wk.week} → unknown tier2 '${a2}'`)
  }
}
for (const lg of logTemplates.values())
  if (lg.affixId) ref(affixes.has(lg.affixId), `log-template '${lg.id}' → unknown affixId '${lg.affixId}'`)

if (errors.length) throw new Error(`[content] ${errors.length} broken reference(s):\n  - ${errors.join("\n  - ")}`)

export const content = {
  classes, specs, skills, stats, tactics, profiles, potentials, operatorSkills, affixes, traits,
  abilities, enemies, packs, dungeons, itemSlots, items, currencies, buildings,
  moraleEvents, talents, lootTables, secondaryStats, tierSets, crafting,
  seasons, logTemplates, playerAbilities, statuses, tuning, recruitment, save,
}

export type {
  Spec, Skill, PlayerAbility, StatusDef, Trait, TraitCombat, TraitGrowth, OperatorSkill, Affix, Tactic, Enemy, Dungeon, Item, RosterMember, Save,
  TalentNode, LootTable, SecondaryStat, TierSet, CraftingOp, Recruitment, Season, LogTemplate,
} from "./schema"
