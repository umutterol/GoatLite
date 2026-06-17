class_name StatCalculator
extends RefCounted


static func calculate_final_stats(exile: ExileData) -> ExileStats:
    var final_stats = exile.base_stats.duplicate()


    _apply_level_growth(exile, final_stats)


    _apply_flat_bonuses(exile, final_stats)







    final_stats.morale = exile.current_morale


    _apply_increased_reduced_modifiers(exile, final_stats)


    _apply_more_less_modifiers(exile, final_stats)


    _apply_conditional_bonuses(exile, final_stats)


    _apply_final_calculations(exile, final_stats)

    return final_stats


static func _apply_level_growth(exile: ExileData, stats: ExileStats):
    if not exile.class_definition:
        return

    var level_multiplier = exile.level - 1

    for i in range(exile.class_definition.percent_stat_ids.size()):
        if i >= exile.class_definition.percent_stat_values.size():
            break

        var stat_id = exile.class_definition.percent_stat_ids[i]
        var percent_per_level = exile.class_definition.percent_stat_values[i]
        var total_percent = percent_per_level * level_multiplier

        _apply_percentage_to_stat(stats, stat_id, total_percent, "increased")

static func _apply_flat_bonuses(exile: ExileData, stats: ExileStats):



    _apply_weapon_overrides(exile, stats)

    var flat_bonuses = {}


    for passive_id in exile.allocated_passives:
        var passive_data = exile.allocated_passives[passive_id]
        var passive_def = PassiveLibrary.get_passive_by_id(passive_id)
        if passive_def:

            var stack_count = 0
            if passive_data is int:

                stack_count = passive_data
                for bonus in passive_def.stat_bonuses:
                    if bonus.scaling_type == StatDefinition.StatScalingType.FLAT:
                        var stat_id = bonus.stat_id
                        var value = bonus.calculate_bonus_value(stack_count)


                        if stats.get(stat_id) is Vector2:
                            if not flat_bonuses.has(stat_id):
                                flat_bonuses[stat_id] = {"both": 0.0, "min": 0.0, "max": 0.0}

                            match bonus.damage_target:
                                PassiveStatBonus.DamageTarget.MIN_ONLY:
                                    flat_bonuses[stat_id]["min"] += value
                                PassiveStatBonus.DamageTarget.MAX_ONLY:
                                    flat_bonuses[stat_id]["max"] += value
                                _:
                                    flat_bonuses[stat_id]["both"] += value
                        else:

                            if not flat_bonuses.has(stat_id):
                                flat_bonuses[stat_id] = 0
                            flat_bonuses[stat_id] += value
            else:

                stack_count = passive_data["count"]
                for bonus_idx in range(passive_def.stat_bonuses.size()):
                    var current_bonus = passive_def.stat_bonuses[bonus_idx]
                    if current_bonus.scaling_type == StatDefinition.StatScalingType.FLAT:
                        var stat_id = current_bonus.stat_id


                        var total_value = 0.0
                        for stack_idx in range(stack_count):
                            total_value += passive_data["rolled_values"][stack_idx][bonus_idx]


                        if stats.get(stat_id) is Vector2:
                            if not flat_bonuses.has(stat_id):
                                flat_bonuses[stat_id] = {"both": 0.0, "min": 0.0, "max": 0.0}

                            match current_bonus.damage_target:
                                PassiveStatBonus.DamageTarget.MIN_ONLY:
                                    flat_bonuses[stat_id]["min"] += total_value
                                PassiveStatBonus.DamageTarget.MAX_ONLY:
                                    flat_bonuses[stat_id]["max"] += total_value
                                _:
                                    flat_bonuses[stat_id]["both"] += total_value
                        else:

                            if not flat_bonuses.has(stat_id):
                                flat_bonuses[stat_id] = 0
                            flat_bonuses[stat_id] += total_value






    for trait_id in exile.traits:
        var trait_def = TraitLibrary.get_trait_by_id(trait_id)
        if not trait_def:
            continue
        for bonus in trait_def.stat_bonuses:
            if bonus.scaling_type != StatDefinition.StatScalingType.FLAT:
                continue
            var stat_id = bonus.stat_id
            var value = bonus.calculate_bonus_value(1)

            if stats.get(stat_id) is Vector2:
                if not flat_bonuses.has(stat_id):
                    flat_bonuses[stat_id] = {"both": 0.0, "min": 0.0, "max": 0.0}
                match bonus.damage_target:
                    PassiveStatBonus.DamageTarget.MIN_ONLY:
                        flat_bonuses[stat_id]["min"] += value
                    PassiveStatBonus.DamageTarget.MAX_ONLY:
                        flat_bonuses[stat_id]["max"] += value
                    _:
                        flat_bonuses[stat_id]["both"] += value
            else:
                if not flat_bonuses.has(stat_id):
                    flat_bonuses[stat_id] = 0
                flat_bonuses[stat_id] += value


    for slot_key in exile.equipped_items:
        var item: Item = exile.equipped_items[slot_key]
        if item == null:
            continue




        _collect_flat_from_rolled_stats(item, flat_bonuses)


        _collect_flat_from_gear_affixes(item, flat_bonuses)


    for stat_id in flat_bonuses:
        var current = stats.get(stat_id)
        if current is Vector2:

            var bonus_data = flat_bonuses[stat_id]
            var new_min = current.x + bonus_data["both"] + bonus_data["min"]
            var new_max = current.y + bonus_data["both"] + bonus_data["max"]
            stats.set(stat_id, Vector2(new_min, new_max))
        else:

            _add_flat_to_stat(stats, stat_id, flat_bonuses[stat_id])


static func _apply_increased_reduced_modifiers(exile: ExileData, stats: ExileStats):
    var modifiers = {}


    for passive_id in exile.allocated_passives:
        var passive_data = exile.allocated_passives[passive_id]
        var passive_def = PassiveLibrary.get_passive_by_id(passive_id)
        if not passive_def:
            continue

        if passive_data is int:

            _collect_increased_reduced_from_bonuses(passive_def.stat_bonuses, passive_data, modifiers)
        else:

            var stack_count = passive_data.get("count", 0)
            for bonus_idx in range(passive_def.stat_bonuses.size()):
                var bonus = passive_def.stat_bonuses[bonus_idx]
                var stat_id = bonus.stat_id


                if bonus.scaling_type == StatDefinition.StatScalingType.INCREASED or \
bonus.scaling_type == StatDefinition.StatScalingType.REDUCED:

                    var total_value = 0.0
                    for stack_idx in range(stack_count):

                        total_value += passive_data["rolled_values"][stack_idx][bonus_idx]

                    if total_value == 0.0:
                        continue

                    if not modifiers.has(stat_id):
                        modifiers[stat_id] = {"increased": 0.0, "reduced": 0.0}

                    if bonus.scaling_type == StatDefinition.StatScalingType.INCREASED:
                        modifiers[stat_id].increased += total_value
                    elif bonus.scaling_type == StatDefinition.StatScalingType.REDUCED:
                        modifiers[stat_id].reduced += total_value


    for trait_id in exile.traits:
        var trait_def = TraitLibrary.get_trait_by_id(trait_id)
        if trait_def:
            _collect_increased_reduced_from_bonuses(trait_def.stat_bonuses, 1, modifiers)




    for slot_key in exile.equipped_items:
        var item: Item = exile.equipped_items[slot_key]
        if item == null:
            continue
        for affix_instance in item.get_all_affixes():
            if affix_instance.affix_base == null:
                continue
            if affix_instance.affix_base.is_local:
                continue
            var stat_id = affix_instance.affix_base.stat_type
            if stat_id.is_empty():
                continue
            var value = affix_instance.get_value()
            match affix_instance.affix_base.modifier_type:
                AffixBase.ModifierType.PERCENT_INCREASED:
                    if not modifiers.has(stat_id):
                        modifiers[stat_id] = {"increased": 0.0, "reduced": 0.0}
                    modifiers[stat_id].increased += value
                AffixBase.ModifierType.PERCENT_REDUCED:
                    if not modifiers.has(stat_id):
                        modifiers[stat_id] = {"increased": 0.0, "reduced": 0.0}
                    modifiers[stat_id].reduced += value




    if exile.class_definition:
        _collect_increased_reduced_from_conditionals(exile.class_definition.conditional_bonuses, 1, modifiers, exile, stats)
    for passive_id in exile.allocated_passives:
        var passive_data = exile.allocated_passives[passive_id]
        var passive_def = PassiveLibrary.get_passive_by_id(passive_id)
        if not passive_def:
            continue
        var stack_count: int = passive_data if passive_data is int else passive_data.get("count", 0)
        _collect_increased_reduced_from_conditionals(passive_def.conditional_bonuses, stack_count, modifiers, exile, stats)
    for trait_id in exile.traits:
        var trait_def = TraitLibrary.get_trait_by_id(trait_id)
        if trait_def:
            _collect_increased_reduced_from_conditionals(trait_def.conditional_bonuses, 1, modifiers, exile, stats)


    for stat_id in modifiers:
        var net_percent = modifiers[stat_id].increased - modifiers[stat_id].reduced
        if net_percent != 0:
            _apply_percentage_to_stat(stats, stat_id, net_percent, "increased")



static func _apply_more_less_modifiers(exile: ExileData, stats: ExileStats):
    var modifiers = {}


    for passive_id in exile.allocated_passives:
        var passive_data = exile.allocated_passives[passive_id]
        var passive_def = PassiveLibrary.get_passive_by_id(passive_id)
        if not passive_def:
            continue

        if passive_data is int:

            _collect_more_less_from_bonuses(passive_def.stat_bonuses, passive_data, modifiers)
        else:

            var stack_count = passive_data.get("count", 0)
            for bonus_idx in range(passive_def.stat_bonuses.size()):
                var bonus = passive_def.stat_bonuses[bonus_idx]
                var stat_id = bonus.stat_id

                if bonus.scaling_type == StatDefinition.StatScalingType.MORE or \
bonus.scaling_type == StatDefinition.StatScalingType.LESS:

                    if not modifiers.has(stat_id):
                        modifiers[stat_id] = {"more": [], "less": []}

                    for stack_idx in range(stack_count):

                        var value = passive_data["rolled_values"][stack_idx][bonus_idx]
                        if bonus.scaling_type == StatDefinition.StatScalingType.MORE:
                            modifiers[stat_id].more.append(value)
                        elif bonus.scaling_type == StatDefinition.StatScalingType.LESS:
                            modifiers[stat_id].less.append(value)


    for trait_id in exile.traits:
        var trait_def = TraitLibrary.get_trait_by_id(trait_id)
        if trait_def:
            _collect_more_less_from_bonuses(trait_def.stat_bonuses, 1, modifiers)




    for slot_key in exile.equipped_items:
        var item: Item = exile.equipped_items[slot_key]
        if item == null:
            continue
        for affix_instance in item.get_all_affixes():
            if affix_instance.affix_base == null:
                continue
            if affix_instance.affix_base.is_local:
                continue
            var stat_id = affix_instance.affix_base.stat_type
            if stat_id.is_empty():
                continue
            var value = affix_instance.get_value()
            match affix_instance.affix_base.modifier_type:
                AffixBase.ModifierType.PERCENT_MORE:
                    if not modifiers.has(stat_id):
                        modifiers[stat_id] = {"more": [], "less": []}
                    modifiers[stat_id].more.append(value)
                AffixBase.ModifierType.PERCENT_LESS:
                    if not modifiers.has(stat_id):
                        modifiers[stat_id] = {"more": [], "less": []}
                    modifiers[stat_id].less.append(value)



    if exile.class_definition:
        _collect_more_less_from_conditionals(exile.class_definition.conditional_bonuses, 1, modifiers, exile, stats)
    for passive_id in exile.allocated_passives:
        var passive_data = exile.allocated_passives[passive_id]
        var passive_def = PassiveLibrary.get_passive_by_id(passive_id)
        if not passive_def:
            continue
        var stack_count: int = passive_data if passive_data is int else passive_data.get("count", 0)
        _collect_more_less_from_conditionals(passive_def.conditional_bonuses, stack_count, modifiers, exile, stats)
    for trait_id in exile.traits:
        var trait_def = TraitLibrary.get_trait_by_id(trait_id)
        if trait_def:
            _collect_more_less_from_conditionals(trait_def.conditional_bonuses, 1, modifiers, exile, stats)


    for stat_id in modifiers:
        for more_value in modifiers[stat_id].more:
            _apply_percentage_to_stat(stats, stat_id, more_value, "more")
        for less_value in modifiers[stat_id].less:
            _apply_percentage_to_stat(stats, stat_id, less_value, "less")






static func _apply_conditional_bonuses(exile: ExileData, stats: ExileStats):

    if exile.class_definition:
        for conditional in exile.class_definition.conditional_bonuses:
            if conditional.scaling_type != StatDefinition.StatScalingType.FLAT:
                continue
            if conditional.is_condition_met(exile, stats):
                _apply_single_bonus_from_conditional(stats, conditional, 1)


    for passive_id in exile.allocated_passives:
        var passive_data = exile.allocated_passives[passive_id]
        var passive_def = PassiveLibrary.get_passive_by_id(passive_id)
        if passive_def:
            var stack_count = 0
            if passive_data is int:
                stack_count = passive_data
            else:
                stack_count = passive_data.get("count", 0)

            for conditional in passive_def.conditional_bonuses:
                if conditional.scaling_type != StatDefinition.StatScalingType.FLAT:
                    continue
                if conditional.is_condition_met(exile, stats):
                    _apply_single_bonus_from_conditional(stats, conditional, stack_count)


    for trait_id in exile.traits:
        var trait_def = TraitLibrary.get_trait_by_id(trait_id)
        if trait_def:
            for conditional in trait_def.conditional_bonuses:
                if conditional.scaling_type != StatDefinition.StatScalingType.FLAT:
                    continue
                if conditional.is_condition_met(exile, stats):
                    _apply_single_bonus_from_conditional(stats, conditional, 1)


static func _apply_final_calculations(exile: ExileData, stats: ExileStats):

    stats.fire_resistance = min(stats.fire_resistance, stats.fire_resistance_cap)
    stats.cold_resistance = min(stats.cold_resistance, stats.cold_resistance_cap)
    stats.lightning_resistance = min(stats.lightning_resistance, stats.lightning_resistance_cap)
    stats.chaos_resistance = min(stats.chaos_resistance, stats.chaos_resistance_cap)




    stats.evasion = clampf(stats.evasion, 0.0, GameSettings.EVASION_CAP)





    stats.critical_chance = clampf(stats.critical_chance, 0.0, 100.0)


    stats.life = max(1, stats.life)
    stats.attack_speed = max(0.1, stats.attack_speed)


    stats.max_life = stats.life
    stats.current_life = min(exile.current_life, stats.life)
    stats.max_vitality = stats.vitality
    stats.current_vitality = min(exile.current_vitality, stats.vitality)
    stats.morale = min(exile.current_morale, stats.max_morale)




static func _add_flat_to_stat(stats: ExileStats, stat_id: String, value: float):
    var current = stats.get(stat_id)

    if current is Vector2:

        stats.set(stat_id, Vector2(current.x + value, current.y + value))
    elif current is float or current is int:
        stats.set(stat_id, current + value)

static func _apply_percentage_to_stat(stats: ExileStats, stat_id: String, percent: float, type: String):




    if stat_id == "elemental_damage":
        for element_stat in ["fire_damage", "cold_damage", "lightning_damage"]:
            _apply_percentage_to_stat(stats, element_stat, percent, type)
        return




    if stat_id == "damage":
        for damage_stat in ["physical_damage", "fire_damage", "cold_damage", "lightning_damage", "chaos_damage"]:
            _apply_percentage_to_stat(stats, damage_stat, percent, type)
        return

    var current = stats.get(stat_id)
    var multiplier = 1.0

    match type:
        "increased":
            multiplier = 1.0 + (percent / 100.0)
        "more":
            multiplier = 1.0 + (percent / 100.0)
        "reduced":
            multiplier = 1.0 - (percent / 100.0)
        "less":
            multiplier = 1.0 - (percent / 100.0)

    if current is Vector2:
        stats.set(stat_id, Vector2(current.x * multiplier, current.y * multiplier))
    elif current is float or current is int:
        stats.set(stat_id, current * multiplier)


static func _apply_single_bonus(stats: ExileStats, bonus: PassiveStatBonus, stack_count: int):
    var value = bonus.calculate_bonus_value(stack_count)

    match bonus.scaling_type:
        StatDefinition.StatScalingType.FLAT:
            _add_flat_to_stat(stats, bonus.stat_id, value)
        StatDefinition.StatScalingType.INCREASED:
            _apply_percentage_to_stat(stats, bonus.stat_id, value, "increased")
        StatDefinition.StatScalingType.MORE:
            _apply_percentage_to_stat(stats, bonus.stat_id, value, "more")
        StatDefinition.StatScalingType.REDUCED:
            _apply_percentage_to_stat(stats, bonus.stat_id, value, "reduced")
        StatDefinition.StatScalingType.LESS:
            _apply_percentage_to_stat(stats, bonus.stat_id, value, "less")


static func _apply_single_bonus_from_conditional(stats: ExileStats, conditional: ConditionalStatBonus, stack_count: int):
    var value = conditional.calculate_bonus_value(stack_count)

    match conditional.scaling_type:
        StatDefinition.StatScalingType.FLAT:
            _add_flat_to_stat(stats, conditional.stat_id, value)
        StatDefinition.StatScalingType.INCREASED:
            _apply_percentage_to_stat(stats, conditional.stat_id, value, "increased")
        StatDefinition.StatScalingType.MORE:
            _apply_percentage_to_stat(stats, conditional.stat_id, value, "more")
        StatDefinition.StatScalingType.REDUCED:
            _apply_percentage_to_stat(stats, conditional.stat_id, value, "reduced")
        StatDefinition.StatScalingType.LESS:
            _apply_percentage_to_stat(stats, conditional.stat_id, value, "less")




static func _apply_weapon_overrides(exile: ExileData, stats: ExileStats) -> void :

    var weapon: Item = null
    var main_key = ItemEnums.EquipSlot.keys()[ItemEnums.EquipSlot.MAIN_HAND]
    var both_key = ItemEnums.EquipSlot.keys()[ItemEnums.EquipSlot.BOTH_HANDS]

    if exile.equipped_items.has(main_key):
        weapon = exile.equipped_items[main_key]
    elif exile.equipped_items.has(both_key):
        weapon = exile.equipped_items[both_key]

    if weapon == null:
        return


    var weapon_aspd = weapon.rolled_stats.get("attack_speed", weapon.base_item.base_attack_speed)
    stats.attack_speed = weapon_aspd


    var weapon_crit = weapon.rolled_stats.get("critical_chance", weapon.base_item.base_critical_chance)
    stats.critical_chance = weapon_crit


    var damage_stats: = ["physical_damage", "fire_damage", "cold_damage", "lightning_damage", "chaos_damage"]
    for stat_id in damage_stats:
        if stats.get(stat_id) is Vector2:
            stats.set(stat_id, Vector2.ZERO)








static func _collect_flat_from_rolled_stats(item: Item, flat_bonuses: Dictionary) -> void :
    var rolled_stats: Dictionary = item.rolled_stats




    var direct_keys = [
        "armour", "evasion", 
        "block_chance", "block_amount", "movement"
    ]
    for key in direct_keys:
        if rolled_stats.has(key):
            if not flat_bonuses.has(key):
                flat_bonuses[key] = 0.0


            flat_bonuses[key] += item.get_local_stat_total(key)







    var damage_types = ["physical", "fire", "cold", "lightning", "chaos"]
    for damage_type in damage_types:
        var min_key = damage_type + "_damage_min"
        var max_key = damage_type + "_damage_max"
        var stat_id = damage_type + "_damage"
        if rolled_stats.has(min_key) or rolled_stats.has(max_key):
            if not flat_bonuses.has(stat_id):
                flat_bonuses[stat_id] = {"both": 0.0, "min": 0.0, "max": 0.0}
            var local_range: Vector2 = item.get_local_damage_range(damage_type)
            flat_bonuses[stat_id]["min"] += local_range.x
            flat_bonuses[stat_id]["max"] += local_range.y






static func _collect_flat_from_gear_affixes(item: Item, flat_bonuses: Dictionary) -> void :
    for affix_instance in item.get_all_affixes():
        if affix_instance.affix_base == null:
            continue
        if affix_instance.affix_base.modifier_type != AffixBase.ModifierType.FLAT_ADDED:
            continue
        if affix_instance.affix_base.is_local:
            continue

        var stat_id = affix_instance.affix_base.stat_type
        if stat_id.is_empty():
            continue


        if affix_instance.rolled_value is Dictionary and affix_instance.rolled_value.has("min"):
            if not flat_bonuses.has(stat_id):
                flat_bonuses[stat_id] = {"both": 0.0, "min": 0.0, "max": 0.0}
            flat_bonuses[stat_id]["min"] += float(affix_instance.rolled_value.min)
            flat_bonuses[stat_id]["max"] += float(affix_instance.rolled_value.max)
        else:

            if not flat_bonuses.has(stat_id):
                flat_bonuses[stat_id] = 0.0
            flat_bonuses[stat_id] += affix_instance.get_value()


static func _collect_increased_reduced_from_bonuses(bonuses: Array, stack_count: int, modifiers: Dictionary):
    for bonus in bonuses:
        if bonus.scaling_type == StatDefinition.StatScalingType.INCREASED:
            var stat_id = bonus.stat_id
            if not modifiers.has(stat_id):
                modifiers[stat_id] = {"increased": 0.0, "reduced": 0.0}
            modifiers[stat_id].increased += bonus.calculate_bonus_value(stack_count)
        elif bonus.scaling_type == StatDefinition.StatScalingType.REDUCED:
            var stat_id = bonus.stat_id
            if not modifiers.has(stat_id):
                modifiers[stat_id] = {"increased": 0.0, "reduced": 0.0}
            modifiers[stat_id].reduced += bonus.calculate_bonus_value(stack_count)

static func _collect_more_less_from_bonuses(bonuses: Array, stack_count: int, modifiers: Dictionary):
    for bonus in bonuses:
        if bonus.scaling_type == StatDefinition.StatScalingType.MORE:
            var stat_id = bonus.stat_id
            if not modifiers.has(stat_id):
                modifiers[stat_id] = {"more": [], "less": []}
            modifiers[stat_id].more.append(bonus.calculate_bonus_value(stack_count))
        elif bonus.scaling_type == StatDefinition.StatScalingType.LESS:
            var stat_id = bonus.stat_id
            if not modifiers.has(stat_id):
                modifiers[stat_id] = {"more": [], "less": []}
            modifiers[stat_id].less.append(bonus.calculate_bonus_value(stack_count))





static func _collect_increased_reduced_from_conditionals(conditionals: Array, stack_count: int, modifiers: Dictionary, exile: ExileData, stats: ExileStats):
    for conditional in conditionals:
        if not conditional.is_condition_met(exile, stats):
            continue
        if conditional.scaling_type == StatDefinition.StatScalingType.INCREASED:
            var stat_id = conditional.stat_id
            if not modifiers.has(stat_id):
                modifiers[stat_id] = {"increased": 0.0, "reduced": 0.0}
            modifiers[stat_id].increased += conditional.calculate_bonus_value(stack_count)
        elif conditional.scaling_type == StatDefinition.StatScalingType.REDUCED:
            var stat_id = conditional.stat_id
            if not modifiers.has(stat_id):
                modifiers[stat_id] = {"increased": 0.0, "reduced": 0.0}
            modifiers[stat_id].reduced += conditional.calculate_bonus_value(stack_count)

static func _collect_more_less_from_conditionals(conditionals: Array, stack_count: int, modifiers: Dictionary, exile: ExileData, stats: ExileStats):
    for conditional in conditionals:
        if not conditional.is_condition_met(exile, stats):
            continue
        if conditional.scaling_type == StatDefinition.StatScalingType.MORE:
            var stat_id = conditional.stat_id
            if not modifiers.has(stat_id):
                modifiers[stat_id] = {"more": [], "less": []}
            modifiers[stat_id].more.append(conditional.calculate_bonus_value(stack_count))
        elif conditional.scaling_type == StatDefinition.StatScalingType.LESS:
            var stat_id = conditional.stat_id
            if not modifiers.has(stat_id):
                modifiers[stat_id] = {"more": [], "less": []}
            modifiers[stat_id].less.append(conditional.calculate_bonus_value(stack_count))

















static func get_total_increased_percent(exile: ExileData, stat_ids: Array[String]) -> float:
    if exile == null:
        return 0.0
    var total: = 0.0
    var current_stats: ExileStats = exile.current_stats if exile.current_stats != null else exile.base_stats


    for passive_id in exile.allocated_passives:
        var passive_data = exile.allocated_passives[passive_id]
        var passive_def = PassiveLibrary.get_passive_by_id(passive_id)
        if passive_def == null:
            continue

        if passive_data is int:


            for bonus in passive_def.stat_bonuses:
                total += _scaling_inc_red_value_for(bonus, passive_data, stat_ids)
        else:
            var stack_count: int = passive_data.get("count", 0)
            var rolled_values: Array = passive_data.get("rolled_values", [])
            for bonus_idx in range(passive_def.stat_bonuses.size()):
                var bonus = passive_def.stat_bonuses[bonus_idx]
                if not stat_ids.has(bonus.stat_id):
                    continue
                if bonus.scaling_type != StatDefinition.StatScalingType.INCREASED and \
bonus.scaling_type != StatDefinition.StatScalingType.REDUCED:
                    continue
                var summed: = 0.0
                for stack_idx in range(stack_count):
                    if stack_idx >= rolled_values.size():
                        break
                    var stack_row: Array = rolled_values[stack_idx]
                    if bonus_idx < stack_row.size():
                        summed += stack_row[bonus_idx]
                if bonus.scaling_type == StatDefinition.StatScalingType.INCREASED:
                    total += summed
                else:
                    total -= summed


        var stack_for_cond: int = passive_data if passive_data is int else passive_data.get("count", 0)
        total += _sum_active_increased_reduced_conditionals(
            passive_def.conditional_bonuses, stack_for_cond, stat_ids, exile, current_stats)


    for trait_id in exile.traits:
        var trait_def = TraitLibrary.get_trait_by_id(trait_id)
        if trait_def == null:
            continue
        for bonus in trait_def.stat_bonuses:
            total += _scaling_inc_red_value_for(bonus, 1, stat_ids)
        total += _sum_active_increased_reduced_conditionals(
            trait_def.conditional_bonuses, 1, stat_ids, exile, current_stats)


    if exile.class_definition:
        total += _sum_active_increased_reduced_conditionals(
            exile.class_definition.conditional_bonuses, 1, stat_ids, exile, current_stats)
        var level_multiplier: = exile.level - 1
        for i in range(exile.class_definition.percent_stat_ids.size()):
            if i >= exile.class_definition.percent_stat_values.size():
                break
            if not stat_ids.has(exile.class_definition.percent_stat_ids[i]):
                continue
            total += exile.class_definition.percent_stat_values[i] * level_multiplier


    for slot_key in exile.equipped_items:
        var item: Item = exile.equipped_items[slot_key]
        if item == null:
            continue
        for affix_instance in item.get_all_affixes():
            if affix_instance.affix_base == null or affix_instance.affix_base.is_local:
                continue
            if not stat_ids.has(affix_instance.affix_base.stat_type):
                continue
            var value: float = affix_instance.get_value()
            match affix_instance.affix_base.modifier_type:
                AffixBase.ModifierType.PERCENT_INCREASED:
                    total += value
                AffixBase.ModifierType.PERCENT_REDUCED:
                    total -= value

    return total




static func _scaling_inc_red_value_for(bonus: PassiveStatBonus, stack_count: int, stat_ids: Array[String]) -> float:
    if bonus == null or not stat_ids.has(bonus.stat_id):
        return 0.0
    var value: float = bonus.calculate_bonus_value(stack_count)
    if bonus.scaling_type == StatDefinition.StatScalingType.INCREASED:
        return value
    if bonus.scaling_type == StatDefinition.StatScalingType.REDUCED:
        return - value
    return 0.0



static func _sum_active_increased_reduced_conditionals(
        conditionals: Array, stack_count: int, stat_ids: Array[String], 
        exile: ExileData, current_stats: ExileStats) -> float:
    var total: = 0.0
    for conditional in conditionals:
        if conditional == null:
            continue
        if not conditional.is_condition_met(exile, current_stats):
            continue
        if not stat_ids.has(conditional.stat_id):
            continue
        var value: float = conditional.calculate_bonus_value(stack_count)
        if conditional.scaling_type == StatDefinition.StatScalingType.INCREASED:
            total += value
        elif conditional.scaling_type == StatDefinition.StatScalingType.REDUCED:
            total -= value
    return total
