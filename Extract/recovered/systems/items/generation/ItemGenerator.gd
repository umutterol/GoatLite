class_name ItemGenerator
extends RefCounted



var affix_pool: AffixPool
var item_bases: Array[ItemBase] = []


func _init(p_affix_pool: AffixPool = null):
    affix_pool = p_affix_pool
    if not affix_pool:
        affix_pool = AffixPool.new()
        affix_pool.load_all_affixes()



func load_item_bases(base_path: String = "res://systems/items/itemBases/"):
    item_bases.clear()
    for full_path in ResourceDirScan.list_tres_files_recursive(base_path):
        var item_base = load(full_path) as ItemBase
        if item_base:
            item_bases.append(item_base)






func generate_item(item_level: int = 1, specific_base: ItemBase = null, active_tags: Array = [], rarity_boost: float = 0.0) -> Item:

    var base_item: ItemBase
    if specific_base:
        base_item = specific_base
    else:
        base_item = _select_random_base(item_level, active_tags)

    if not base_item:
        push_error("No valid item base found for generation")
        return null


    var item = Item.new(base_item, item_level)
    item.source_tags = active_tags.duplicate()


    _roll_base_stats(item)


    _generate_implicits(item)


    var affix_count = _roll_affix_count(rarity_boost)


    if affix_count > 0:
        _generate_explicit_affixes(item, affix_count, active_tags)


    item.update_rarity()

    return item





func _select_random_base(item_level: int, active_tags: Array) -> ItemBase:
    var valid_bases: Array[ItemBase] = []

    for base in item_bases:

        if base.category == ItemEnums.ItemCategory.CURRENCY:
            continue


        if item_level < base.min_item_level:
            continue


        var typed_tags: Array[String] = []
        for tag in active_tags:
            typed_tags.append(str(tag))

        if not base.can_drop_with_tags(typed_tags):
            continue

        valid_bases.append(base)

    if valid_bases.is_empty():
        return null

    return valid_bases.pick_random()


func _roll_base_stats(item: Item):
    var base = item.base_item


    if base.base_armour_max > 0:
        item.rolled_stats["armour"] = randi_range(base.base_armour_min, base.base_armour_max)


    if base.base_evasion_max != 0 or base.base_evasion_min != 0:
        item.rolled_stats["evasion"] = randi_range(base.base_evasion_min, base.base_evasion_max)




    if base.base_physical_damage_max > 0:
        item.rolled_stats["physical_damage_min"] = base.base_physical_damage_min
        item.rolled_stats["physical_damage_max"] = base.base_physical_damage_max


    for damage_type in ["fire", "cold", "lightning", "chaos"]:
        var min_key = "base_" + damage_type + "_damage_min"
        var max_key = "base_" + damage_type + "_damage_max"
        if base.get(max_key) > 0:
            item.rolled_stats[damage_type + "_damage_min"] = base.get(min_key)
            item.rolled_stats[damage_type + "_damage_max"] = base.get(max_key)


    if base.category == ItemEnums.ItemCategory.WEAPON:
        item.rolled_stats["attack_speed"] = base.base_attack_speed


    if base.category == ItemEnums.ItemCategory.WEAPON:
        item.rolled_stats["critical_chance"] = base.base_critical_chance


    if base.category == ItemEnums.ItemCategory.WEAPON:
        item.rolled_stats["attack_range"] = base.base_attack_range


    if base.base_block_chance_max > 0:
        item.rolled_stats["block_chance"] = randi_range(base.base_block_chance_min, base.base_block_chance_max)

    if base.base_block_amount_max > 0:
        item.rolled_stats["block_amount"] = randi_range(base.base_block_amount_min, base.base_block_amount_max)


    if base.movement != 0:
        item.rolled_stats["movement"] = base.movement


func _generate_implicits(item: Item):
    for implicit_affix in item.base_item.implicit_affixes:
        if not implicit_affix:
            continue


        var rolled_value = implicit_affix.roll_value_at_level(item.item_level)





        if _should_round_stat(implicit_affix.stat_type):
            if rolled_value is Dictionary:

                rolled_value.min = round(rolled_value.min)
                rolled_value.max = round(rolled_value.max)
            else:

                rolled_value = round(rolled_value)


        var valid_tiers = affix_pool.get_valid_tiers(implicit_affix, item.item_level)
        var tier = valid_tiers[-1] if not valid_tiers.is_empty() else 1

        var affix_instance = AffixInstance.new(implicit_affix, rolled_value, tier)
        item.implicit_affixes.append(affix_instance)










func _roll_affix_count(rarity_boost: float = 0.0) -> int:
    var zero_weight: float = float(GameSettings.ZERO_MOD_BASE_CHANCE) * maxf(0.0, 1.0 - rarity_boost)
    var weights = {
        0: zero_weight, 
        1: float(GameSettings.ONE_MOD_BASE_CHANCE), 
        2: float(GameSettings.TWO_MOD_BASE_CHANCE), 
        3: float(GameSettings.THREE_MOD_BASE_CHANCE), 
        4: float(GameSettings.FOUR_MOD_BASE_CHANCE), 
    }

    var total_weight: float = 0.0
    for weight in weights.values():
        total_weight += weight



    if total_weight <= 0.0:
        return 0

    var roll: float = randf() * total_weight
    var cumulative: float = 0.0

    for count in range(5):
        cumulative += weights[count]
        if roll <= cumulative:
            return count

    return 4


func _generate_explicit_affixes(item: Item, total_count: int, active_tags: Array):

    var valid_prefixes = affix_pool.get_valid_prefixes(item.base_item, item.item_level, active_tags)
    var valid_suffixes = affix_pool.get_valid_suffixes(item.base_item, item.item_level, active_tags)


    var prefix_count = 0
    var suffix_count = 0

    match total_count:
        1:

            if randf() < 0.5 and not valid_prefixes.is_empty():
                prefix_count = 1
            elif not valid_suffixes.is_empty():
                suffix_count = 1
            elif not valid_prefixes.is_empty():
                prefix_count = 1
        2:

            prefix_count = 1 if not valid_prefixes.is_empty() else 0
            suffix_count = 1 if not valid_suffixes.is_empty() else 0
        3:

            prefix_count = 1
            suffix_count = 1
            if randf() < 0.5 and valid_prefixes.size() > 1:
                prefix_count = 2
            elif valid_suffixes.size() > 1:
                suffix_count = 2
            elif valid_prefixes.size() > 1:
                prefix_count = 2
        4:

            prefix_count = min(2, valid_prefixes.size())
            suffix_count = min(2, valid_suffixes.size())


    if prefix_count > 0:
        _add_affixes(item, valid_prefixes, prefix_count, true)


    if suffix_count > 0:
        _add_affixes(item, valid_suffixes, suffix_count, false)


func _add_affixes(item: Item, valid_affixes: Array[AffixBase], count: int, is_prefix: bool):

    var available = valid_affixes.duplicate()
    var target_array = item.prefix_affixes if is_prefix else item.suffix_affixes

    for i in range(count):
        if available.is_empty():
            break



        var affix = affix_pool.pick_weighted_affix(available)
        if affix == null:
            break
        available.erase(affix)


        var valid_tiers = affix_pool.get_valid_tiers(affix, item.item_level)
        var tier = affix_pool.roll_weighted_tier(valid_tiers)


        var rolled_value = affix.roll_value_at_level(item.item_level)



        if _should_round_stat(affix.stat_type):
            if rolled_value is Dictionary:

                rolled_value.min = round(rolled_value.min)
                rolled_value.max = round(rolled_value.max)
            else:

                rolled_value = round(rolled_value)


        var affix_instance = AffixInstance.new(affix, rolled_value, tier)
        target_array.append(affix_instance)









func _should_round_stat(stat_type: String) -> bool:
    if stat_type.is_empty():
        return true
    var definition: StatDefinition = StatDefinitionManager.get_stat_definition(stat_type)
    if definition == null:
        push_warning("ItemGenerator: no StatDefinition for stat_type '%s' — defaulting to round()." % stat_type)
        return true
    return definition.decimal_places <= 0


func generate_item_with_rarity(item_level: int, rarity: Item.Rarity, specific_base: ItemBase = null, active_tags: Array = []) -> Item:

    var desired_count = 0

    match rarity:
        Item.Rarity.COMMON:
            desired_count = 0
        Item.Rarity.UNCOMMON:
            desired_count = randi_range(1, 2)
        Item.Rarity.RARE:
            desired_count = randi_range(3, 4)


    return _generate_with_affix_count(item_level, desired_count, specific_base, active_tags)


func _generate_with_affix_count(item_level: int, affix_count: int, specific_base: ItemBase = null, active_tags: Array = []) -> Item:

    var base_item: ItemBase
    if specific_base:
        base_item = specific_base
    else:
        base_item = _select_random_base(item_level, active_tags)

    if not base_item:
        push_error("No valid item base found for generation")
        return null


    var item = Item.new(base_item, item_level)
    item.source_tags = active_tags.duplicate()


    _roll_base_stats(item)


    _generate_implicits(item)


    if affix_count > 0:
        _generate_explicit_affixes(item, affix_count, active_tags)


    item.update_rarity()

    return item
