class_name AffixPool
extends Resource




@export var prefix_affixes: Array[AffixBase] = []
@export var suffix_affixes: Array[AffixBase] = []
@export var implicit_affixes: Array[AffixBase] = []


var _affixes_by_stat: Dictionary = {}


func load_all_affixes(base_path: String = "res://systems/items/affixes/"):
    prefix_affixes.clear()
    suffix_affixes.clear()
    implicit_affixes.clear()
    _affixes_by_stat.clear()


    _load_affixes_from_directory(base_path + "explicit/prefix/", prefix_affixes, false)
    _load_affixes_from_directory(base_path + "explicit/suffix/", suffix_affixes, false)





    _load_corruption_affixes(base_path + "explicit/corruption_only/")


    _load_affixes_from_directory(base_path + "implicit/", implicit_affixes, true)


    _build_stat_cache()




func _load_affixes_from_directory(path: String, target_array: Array[AffixBase], is_implicit: bool):
    var paths: Array[String] = ResourceDirScan.list_tres_files(path)
    if paths.is_empty():


        if DirAccess.open(path) == null:
            push_warning("Could not open affix directory: " + path)
        return
    for full_path in paths:
        var affix = load(full_path) as AffixBase
        if not affix:
            push_warning("Failed to load affix: " + full_path)
            continue

        if is_implicit and affix.is_implicit:
            _ensure_tier_data(affix)
            target_array.append(affix)
        elif not is_implicit and (affix.is_prefix or affix.is_suffix):
            _ensure_tier_data(affix)
            target_array.append(affix)







func _load_corruption_affixes(path: String) -> void :
    for full_path in ResourceDirScan.list_tres_files(path):
        var affix = load(full_path) as AffixBase
        if not affix:
            push_warning("AffixPool: failed to load corruption affix: " + full_path)
            continue
        _ensure_tier_data(affix)
        if affix.is_prefix:
            prefix_affixes.append(affix)
        elif affix.is_suffix:
            suffix_affixes.append(affix)
        else:
            push_warning("AffixPool: corruption affix has neither is_prefix nor is_suffix: " + full_path)



func _ensure_tier_data(affix: AffixBase):

    if affix.use_tier_helper and affix.value_by_level.is_empty() and not affix.value_tiers.is_empty():
        for tier in affix.value_tiers:
            if tier != null:
                affix.value_by_level[tier.item_level] = tier.to_dictionary()


    if affix.value_by_level.is_empty() and (affix.min_value != 0 or affix.max_value != 0):
        affix.value_by_level[1] = {"min": affix.min_value, "max": affix.max_value}


func _build_stat_cache():
    for affix in prefix_affixes + suffix_affixes + implicit_affixes:
        if not _affixes_by_stat.has(affix.stat_type):
            _affixes_by_stat[affix.stat_type] = []
        _affixes_by_stat[affix.stat_type].append(affix)


func get_valid_prefixes(item_base: ItemBase, item_level: int, active_tags: Array = []) -> Array[AffixBase]:
    return _get_valid_affixes(prefix_affixes, item_base, item_level, active_tags)


func get_valid_suffixes(item_base: ItemBase, item_level: int, active_tags: Array = []) -> Array[AffixBase]:
    return _get_valid_affixes(suffix_affixes, item_base, item_level, active_tags)


func _get_valid_affixes(affix_array: Array[AffixBase], item_base: ItemBase, item_level: int, active_tags: Array) -> Array[AffixBase]:
    var valid_affixes: Array[AffixBase] = []

    for affix in affix_array:

        if not affix.can_appear_on_item(item_base):
            continue


        if item_level < affix.min_item_level or item_level > affix.max_item_level:
            continue


        if not _check_tags(affix, active_tags):
            continue



        if affix.is_local and not _item_supports_local_stat(item_base, affix.stat_type):
            continue

        valid_affixes.append(affix)

    return valid_affixes




func _item_supports_local_stat(base: ItemBase, stat_id: String) -> bool:
    match stat_id:
        "armour":
            return base.base_armour_max > 0
        "evasion":
            return base.base_evasion_max > 0
        "block_chance":
            return base.base_block_chance_max > 0
        "block_amount":
            return base.base_block_amount_max > 0
        "attack_speed", "critical_chance":

            return base.category == ItemEnums.ItemCategory.WEAPON
        "physical_damage":
            return base.base_physical_damage_max > 0
        "fire_damage":
            return base.base_fire_damage_max > 0
        "cold_damage":
            return base.base_cold_damage_max > 0
        "lightning_damage":
            return base.base_lightning_damage_max > 0
        "chaos_damage":
            return base.base_chaos_damage_max > 0
        _:



            return true


func _check_tags(affix: AffixBase, active_tags: Array) -> bool:

    if affix.custom_tags.is_empty():
        return true


    for tag in affix.custom_tags:
        if tag in active_tags:
            return true

    return false


func get_valid_tiers(affix: AffixBase, item_level: int) -> Array[int]:
    var valid_tiers: Array[int] = []

    for tier_level in affix.value_by_level.keys():
        if tier_level <= item_level:
            valid_tiers.append(tier_level)

    valid_tiers.sort()
    return valid_tiers


func roll_weighted_tier(valid_tiers: Array[int]) -> int:
    if valid_tiers.is_empty():
        return 1

    if valid_tiers.size() == 1:
        return valid_tiers[0]


    var weights: Array[float] = []
    var total_weight = 0.0

    for i in range(valid_tiers.size()):

        var weight = float(i + 1)
        weights.append(weight)
        total_weight += weight


    var roll = randf() * total_weight
    var cumulative = 0.0

    for i in range(weights.size()):
        cumulative += weights[i]
        if roll <= cumulative:
            return valid_tiers[i]


    return valid_tiers[-1]














func pick_weighted_affix(candidates: Array) -> AffixBase:
    if candidates.is_empty():
        return null

    var total_weight: int = 0
    for affix in candidates:
        if affix == null:
            continue
        total_weight += maxi(0, affix.spawn_weight)





    if total_weight <= 0:
        var non_null: Array = []
        for affix in candidates:
            if affix != null:
                non_null.append(affix)
        if non_null.is_empty():
            return null
        return non_null[randi() % non_null.size()]

    var roll: int = randi() % total_weight
    var cumulative: int = 0
    for affix in candidates:
        if affix == null:
            continue
        cumulative += maxi(0, affix.spawn_weight)
        if roll < cumulative:
            return affix

    for i in range(candidates.size() - 1, -1, -1):
        if candidates[i] != null:
            return candidates[i]
    return null







func compute_odds(candidates: Array) -> Dictionary:
    var odds: Dictionary = {}
    if candidates.is_empty():
        return odds

    var total_weight: int = 0
    var non_null_count: int = 0
    for affix in candidates:
        if affix == null:
            continue
        non_null_count += 1
        total_weight += maxi(0, affix.spawn_weight)

    if non_null_count == 0:
        return odds


    if total_weight <= 0:
        var uniform_pct: float = 100.0 / float(non_null_count)
        for affix in candidates:
            if affix == null:
                continue
            odds[affix.affix_id] = uniform_pct
        return odds

    for affix in candidates:
        if affix == null:
            continue
        var weight: int = maxi(0, affix.spawn_weight)
        if weight == 0:
            continue
        odds[affix.affix_id] = 100.0 * float(weight) / float(total_weight)
    return odds






func get_corruption_only_pool(item_base: ItemBase) -> Array[AffixBase]:
    var result: Array[AffixBase] = []



    for affix in prefix_affixes + suffix_affixes:
        if not "corruption_only" in affix.custom_tags:
            continue
        if not affix.can_appear_on_item(item_base):
            continue
        result.append(affix)
    return result



func get_affix_by_id(affix_id: String) -> AffixBase:
    for affix in prefix_affixes + suffix_affixes + implicit_affixes:
        if affix.affix_id == affix_id:
            return affix
    return null


func print_affix_summary():
    print("\n=== AFFIX POOL SUMMARY ===")

    print("\nPREFIXES:")
    for affix in prefix_affixes:
        print("  - ", affix.affix_id, " (", affix.stat_type, ") iLvl ", affix.min_item_level, "-", affix.max_item_level)

    print("\nSUFFIXES:")
    for affix in suffix_affixes:
        print("  - ", affix.affix_id, " (", affix.stat_type, ") iLvl ", affix.min_item_level, "-", affix.max_item_level)

    print("\nIMPLICITS:")
    for affix in implicit_affixes:
        print("  - ", affix.affix_id, " (", affix.stat_type, ") iLvl ", affix.min_item_level, "-", affix.max_item_level)
