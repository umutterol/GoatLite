class_name ClassDefinition
extends Resource





enum ClassRarity{
    COMMON = 0, 
    UNCOMMON = 1, 
    RARE = 2, 
    LEGENDARY = 3
}








@export var class_id: String = ""




@export var name: String = ""






@export_multiline var description: String = ""


@export var rarity: ClassRarity = ClassRarity.COMMON



@export var icon: Texture2D










@export_group("Starting Stat Overrides")



@export var override_life: float = -1.0


@export var override_vitality: float = -1.0



@export var override_morale: float = -1.0




@export var override_physical_damage: Vector2 = Vector2(-1, -1)





@export var override_attack_speed: float = -1.0



@export var override_critical_chance: float = -1.0



@export var override_critical_multiplier: float = -1.0


@export var override_evasion: float = -1.0


@export var override_block_chance: float = -1.0



@export var override_cold_resistance: float = -1.0


@export var override_fire_resistance: float = -1.0


@export var override_lightning_resistance: float = -1.0


@export var override_chaos_resistance: float = -1.0



@export var override_life_regen: float = -1.0



@export var override_survival: float = -1.0


@export var override_scouting: float = -1.0


@export var override_scavenging: float = -1.0


@export var override_movement: float = -1.0






@export var override_poison_chance: float = -1.0




@export var override_poison_duration_more_pct: float = -1.0


func get_stat_overrides() -> Dictionary:
    var overrides = {}

    if override_life >= 0: overrides["life"] = override_life
    if override_vitality >= 0: overrides["vitality"] = override_vitality
    if override_morale >= 0: overrides["morale"] = override_morale
    if override_physical_damage.x >= 0: overrides["physical_damage"] = override_physical_damage
    if override_attack_speed >= 0: overrides["attack_speed"] = override_attack_speed
    if override_critical_chance >= 0: overrides["critical_chance"] = override_critical_chance
    if override_critical_multiplier >= 0: overrides["critical_multiplier"] = override_critical_multiplier
    if override_evasion >= 0: overrides["evasion"] = override_evasion
    if override_block_chance >= 0: overrides["block_chance"] = override_block_chance
    if override_cold_resistance >= 0: overrides["cold_resistance"] = override_cold_resistance
    if override_fire_resistance >= 0: overrides["fire_resistance"] = override_fire_resistance
    if override_lightning_resistance >= 0: overrides["lightning_resistance"] = override_lightning_resistance
    if override_chaos_resistance >= 0: overrides["chaos_resistance"] = override_chaos_resistance
    if override_life_regen >= 0: overrides["life_regen"] = override_life_regen
    if override_survival >= 0: overrides["survival"] = override_survival
    if override_scouting >= 0: overrides["scouting"] = override_scouting
    if override_scavenging >= 0: overrides["scavenging"] = override_scavenging
    if override_movement >= 0: overrides["movement"] = override_movement
    if override_poison_chance >= 0: overrides["poison_chance"] = override_poison_chance
    if override_poison_duration_more_pct >= 0: overrides["poison_duration_more_pct"] = override_poison_duration_more_pct

    return overrides






@export_group("Level Up Growth")



@export var life_per_level: float = 5.0


@export var vitality_per_level: float = 2.0









@export_subgroup("Additional Flat Growth")


@export var growth_stat_ids: Array[String] = []


@export var growth_stat_values: Array[float] = []










@export_subgroup("Percentage Growth")


@export var percent_stat_ids: Array[String] = []



@export var percent_stat_values: Array[float] = []





@export_group("Potential Modifiers")



@export var potential_tags: Array[String] = []



@export var potential_values: Array[float] = []


@export_group("Special Properties")






@export var special_effects: Array[String] = []


@export_group("Restrictions")



@export var min_recruit_level: int = 1






@export var incompatible_trait_ids: Array[String] = []


@export_group("Conditional Bonuses")





@export var conditional_bonuses: Array[ConditionalStatBonus] = []

func get_conditional_bonuses() -> Array[ConditionalStatBonus]:
    return conditional_bonuses


func get_drop_weight() -> float:
    var base_weights = {
        ClassRarity.COMMON: GameSettings.CLASS_RARITY_WEIGHTS["COMMON"], 
        ClassRarity.UNCOMMON: GameSettings.CLASS_RARITY_WEIGHTS["UNCOMMON"], 
        ClassRarity.RARE: GameSettings.CLASS_RARITY_WEIGHTS["RARE"], 
        ClassRarity.LEGENDARY: GameSettings.CLASS_RARITY_WEIGHTS["LEGENDARY"]
    }
    return base_weights.get(rarity, 70.0)






func is_compatible_with_traits(trait_ids: Array[String]) -> bool:
    for trait_id in trait_ids:
        if incompatible_trait_ids.has(trait_id):
            return false
    return true


func get_all_growth_stats() -> Dictionary:
    var result = {}
    result["life"] = life_per_level
    result["vitality"] = vitality_per_level


    for i in range(growth_stat_ids.size()):
        if i < growth_stat_values.size():
            result[growth_stat_ids[i]] = growth_stat_values[i]

    return result


func get_potential_modifiers() -> Dictionary:
    var result = {}
    var i = 0
    while i < potential_tags.size() and i < potential_values.size():
        result[potential_tags[i]] = potential_values[i]
        i += 1
    return result
