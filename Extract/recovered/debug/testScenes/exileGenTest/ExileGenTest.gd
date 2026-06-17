extends Control


@onready var title_label = $ColorRect / MarginContainer / ScrollContainer / VBoxContainer / TitleLabel
@onready var basic_info_label = $ColorRect / MarginContainer / ScrollContainer / VBoxContainer / HBoxContainer / BasicInfoLabel
@onready var stats_label = $ColorRect / MarginContainer / ScrollContainer / VBoxContainer / HBoxContainer / StatsLabel
@onready var traits_label = $ColorRect / MarginContainer / ScrollContainer / VBoxContainer / HBoxContainer2 / TraitsLabel
@onready var potentials_label = $ColorRect / MarginContainer / ScrollContainer / VBoxContainer / HBoxContainer2 / PotentialsLabel
@onready var passives_label = $ColorRect / MarginContainer / ScrollContainer / VBoxContainer / HBoxContainer2 / PassivesLabel

var test_exile: ExileData

func _ready():

    setup_ui()


    print("\n========== GENERATING TEST EXILE ==========")
    generate_test_exile()


    display_exile_info()

func setup_ui():

    title_label.bbcode_enabled = true
    basic_info_label.bbcode_enabled = true
    stats_label.bbcode_enabled = true
    traits_label.bbcode_enabled = true
    potentials_label.bbcode_enabled = true
    passives_label.bbcode_enabled = true


    $ColorRect.color = Color(0.1, 0.1, 0.1, 1.0)

func generate_test_exile():

    var params = {


        "min_trait_rarity": 0, 
        "name": "", 
        "level": 1
    }

    test_exile = ExileGenerator.create_exile(params)




    print("Generated exile: ", test_exile.name, " (ID: ", test_exile.id, ")")

func display_exile_info():

    if test_exile:
        ExileGenerator.recalculate_stats(test_exile)


    title_label.text = "[center][b][color=yellow]EXILE GENERATION TEST[/color][/b][/center]"


    display_basic_info()


    display_stats()


    display_traits()


    display_potentials()


    display_passives()

func display_basic_info():
    var info = "[b][color=cyan]BASIC INFORMATION[/color][/b]\n\n"

    info += "[b]Name:[/b] " + test_exile.name + "\n"
    info += "[b]ID:[/b] " + str(test_exile.id) + "\n"
    info += "[b]Level:[/b] " + str(test_exile.level) + "\n"
    info += "[b]Experience:[/b] " + str(test_exile.experience) + "/" + str(test_exile.get_exp_for_next_level()) + "\n"
    info += "[b]Status:[/b] " + test_exile.status + "\n\n"


    if test_exile.class_definition:
        var class_def = test_exile.class_definition
        info += "[b]Class:[/b] " + class_def.name + " (" + class_def.class_id + ")\n"
        info += "[b]Class Rarity:[/b] " + _get_rarity_name(class_def.rarity) + "\n"
        info += "[b]Description:[/b] " + class_def.description + "\n"


        var overrides = class_def.get_stat_overrides()
        if not overrides.is_empty():
            info += "\n[color=yellow]Starting Stats:[/color]\n"
            for stat_id in overrides:
                var stat_def = StatDefinitionManager.get_stat_definition(stat_id)
                if stat_def:
                    var value = overrides[stat_id]
                    if value is Vector2:
                        info += "  • " + stat_def.display_name + ": " + str(int(value.x)) + "-" + str(int(value.y)) + "\n"
                    else:
                        info += "  • " + stat_def.display_name + ": " + str(value) + "\n"


        info += "\n[color=yellow]Growth Per Level:[/color]\n"
        var growth_stats = class_def.get_all_growth_stats()
        for stat_id in growth_stats:
            if growth_stats[stat_id] != 0:
                var stat_def = StatDefinitionManager.get_stat_definition(stat_id)
                if stat_def:
                    info += "  • " + stat_def.display_name + ": +" + str(growth_stats[stat_id]) + "\n"


        if not class_def.percent_stat_ids.is_empty():
            info += "\n[color=yellow]Percentage Growth Per Level:[/color]\n"
            for i in range(class_def.percent_stat_ids.size()):
                if i < class_def.percent_stat_values.size():
                    var stat_id = class_def.percent_stat_ids[i]
                    var percent = class_def.percent_stat_values[i]
                    var stat_def = StatDefinitionManager.get_stat_definition(stat_id)
                    if stat_def:
                        info += "  • " + stat_def.display_name + ": " + str(percent) + "% increased\n"

    basic_info_label.text = info

func display_stats():
    var info = "[b][color=cyan]STATISTICS[/color][/b]\n\n"


    info += "[b]Life:[/b] " + str(test_exile.current_life) + " / " + str(test_exile.current_stats.life) + "\n\n"


    info += "[color=yellow]Core Stats:[/color]\n"
    info += _compare_stat("Life", "life")
    info += _compare_stat("Vitality", "vitality")
    info += _compare_stat("Morale", "morale")
    info += _compare_stat("Max Morale", "max_morale")
    info += "\n"


    info += "[color=yellow]Defensive Stats:[/color]\n"
    info += _compare_stat("Armour", "armour")
    info += _compare_stat("Evasion", "evasion", "%")
    info += _compare_stat("Block Chance", "block_chance", "%")
    info += _compare_stat("Block Amount", "block_amount")
    info += _compare_stat("Endurance", "endurance")
    info += _compare_stat("Endurance Threshold", "endurance_threshold", "%")
    info += "\n"


    info += "[color=yellow]Resistances:[/color]\n"
    info += _compare_resistance_with_cap("Fire Resistance", "fire_resistance", "fire_resistance_cap")
    info += _compare_resistance_with_cap("Cold Resistance", "cold_resistance", "cold_resistance_cap")
    info += _compare_resistance_with_cap("Lightning Resistance", "lightning_resistance", "lightning_resistance_cap")
    info += _compare_resistance_with_cap("Chaos Resistance", "chaos_resistance", "chaos_resistance_cap")
    info += "\n"


    info += "[color=yellow]Recovery Stats:[/color]\n"
    info += _compare_stat("Life Regeneration", "life_regen", "/sec")
    info += _compare_stat("Life Leech", "life_leech", "%")
    info += _compare_stat("Life Gain on Hit", "life_gain_on_hit")
    info += _compare_stat("Second Wind Chance", "second_wind_chance", "%")
    info += _compare_stat("Second Wind Amount", "second_wind_amount", "%")
    info += _compare_stat("Second Wind Threshold", "second_wind_threshold", "%")
    info += "\n"


    info += "[color=yellow]Offensive Stats:[/color]\n"
    info += _compare_damage_stat("Physical Damage", "physical_damage")
    info += _compare_damage_stat("Fire Damage", "fire_damage")
    info += _compare_damage_stat("Cold Damage", "cold_damage")
    info += _compare_damage_stat("Lightning Damage", "lightning_damage")
    info += _compare_damage_stat("Chaos Damage", "chaos_damage")
    info += _compare_stat("Critical Chance", "critical_chance", "%")
    info += _compare_stat("Critical Multiplier", "critical_multiplier", "%")
    info += _compare_stat("Attack Speed", "attack_speed")
    info += "\n"


    info += "[color=yellow]Morale Modifiers:[/color]\n"
    info += _compare_stat("Morale Gain", "morale_gain", "%")
    info += _compare_stat("Morale Loss Resistance", "morale_loss_resistance", "%")
    info += _compare_stat("Victory Morale Bonus", "victory_morale_bonus")
    info += _compare_stat("Well-Fed Rest Morale Bonus", "well_fed_rest_morale_bonus")

    stats_label.text = info

func display_traits():
    var info = "[b][color=cyan]TRAITS[/color][/b]\n\n"

    if test_exile.traits.is_empty():
        info += "[i]No traits[/i]\n"
    else:
        for trait_id in test_exile.traits:
            var trait_def = TraitLibrary.get_trait_by_id(trait_id)
            if trait_def:
                info += "[b]" + trait_def.name + "[/b]"
                info += " [color=gray](" + _get_rarity_name(trait_def.rarity) + ")[/color]\n"
                info += "[i]" + trait_def.description + "[/i]\n"


                if not trait_def.stat_bonuses.is_empty():
                    info += "  Bonuses:\n"
                    for bonus in trait_def.stat_bonuses:
                        var display_text = bonus.get_display_text()

                        display_text = display_text.replace("+-", "-")
                        info += "    • " + display_text + "\n"


                if not trait_def.special_effects.is_empty():
                    info += "  Special: " + str(trait_def.special_effects) + "\n"

                info += "\n"

    traits_label.text = info

func display_potentials():
    var info = "[b][color=cyan]GROWTH POTENTIALS[/color][/b]\n\n"

    if not test_exile.potential:
        info += "[i]No potential system initialized[/i]\n"
    else:
        var entries = test_exile.potential.get_display_entries()

        if entries.is_empty():
            info += "[i]No potentials[/i]\n"
        else:
            info += "[i]Potentials influence the likelihood of seeing related passives[/i]\n\n"

            for entry in entries:
                if entry.is_hidden:
                    info += "[color=gray]??? (Hidden)[/color]\n"
                else:
                    info += "[b]" + entry.tag.capitalize() + ":[/b] "
                    info += str(entry.total_value) + "x weight\n"


                    if not entry.sources.is_empty():
                        for source in entry.sources:
                            var value_sign = "+" if source.value >= 0 else ""
                            info += "  • " + value_sign + str(source.value) + " from " + source.source_name + "\n"
                info += "\n"

    potentials_label.text = info

func display_passives():
    var info = "[b][color=cyan]ALLOCATED PASSIVES[/color][/b]\n\n"

    if test_exile.allocated_passives.is_empty():
        info += "[i]No passives allocated[/i]\n"
        info += "[i]Points available: " + str(test_exile.pending_passive_points) + "[/i]\n"
    else:
        info += "[i]Points available: " + str(test_exile.pending_passive_points) + "[/i]\n\n"

        for passive_id in test_exile.allocated_passives:

            var stack_count = 0
            var passive_data = test_exile.allocated_passives[passive_id]
            if passive_data is int:
                stack_count = passive_data
            elif passive_data is Dictionary:
                stack_count = passive_data.get("count", 0)

            var passive_def = PassiveLibrary.get_passive_by_id(passive_id)

            if passive_def:

                info += "[b]" + passive_def.name + "[/b] x" + str(stack_count) + "/" + str(passive_def.max_stacks) + "\n"


                info += "[i]" + passive_def.description + "[/i]\n"


                var has_rolled_values = passive_data is Dictionary and passive_data.has("rolled_values")


                if not passive_def.stat_bonuses.is_empty():
                    for bonus_idx in range(passive_def.stat_bonuses.size()):
                        var bonus = passive_def.stat_bonuses[bonus_idx]
                        var stat_def = StatDefinitionManager.get_stat_definition(bonus.stat_id)
                        var stat_name = stat_def.display_name if stat_def else bonus.stat_id.capitalize()


                        var total_value = 0.0
                        var per_stack_value = 0.0

                        if has_rolled_values:

                            for stack_idx in range(stack_count):
                                total_value += passive_data["rolled_values"][stack_idx][bonus_idx]

                            if stack_count > 0:
                                per_stack_value = total_value / stack_count
                        else:

                            total_value = bonus.calculate_bonus_value(stack_count)
                            per_stack_value = bonus.value_per_stack


                        var display_text = ""


                        var formatted_value = _format_stat_value(total_value, stat_def, bonus.scaling_type)


                        if bonus.scaling_type == StatDefinition.StatScalingType.FLAT:
                            if total_value >= 0:
                                display_text += "+"
                            display_text += formatted_value
                        else:
                            display_text += formatted_value + "%"


                        match bonus.scaling_type:
                            StatDefinition.StatScalingType.FLAT:
                                display_text += " to "
                            StatDefinition.StatScalingType.INCREASED:
                                display_text += " increased "
                            StatDefinition.StatScalingType.REDUCED:
                                display_text += " reduced "
                            StatDefinition.StatScalingType.MORE:
                                display_text += " more "
                            StatDefinition.StatScalingType.LESS:
                                display_text += " less "

                        display_text += stat_name


                        if stack_count > 1 and per_stack_value != 0:
                            var formatted_per_stack = _format_stat_value(per_stack_value, stat_def, bonus.scaling_type)
                            display_text += " [color=gray](" + formatted_per_stack + " per stack)[/color]"

                        info += "  • " + display_text + "\n"


                if not passive_def.conditional_bonuses.is_empty():
                    for conditional in passive_def.conditional_bonuses:
                        var stat_def = StatDefinitionManager.get_stat_definition(conditional.stat_id)
                        var stat_name = stat_def.display_name if stat_def else conditional.stat_id.capitalize()


                        var total_value = conditional.calculate_bonus_value(stack_count)
                        var per_stack_value = conditional.value_per_stack


                        var display_text = ""


                        var formatted_value = _format_stat_value(total_value, stat_def, conditional.scaling_type)


                        if conditional.scaling_type == StatDefinition.StatScalingType.FLAT:
                            if total_value >= 0:
                                display_text += "+"
                            display_text += formatted_value
                        else:
                            display_text += formatted_value + "%"


                        match conditional.scaling_type:
                            StatDefinition.StatScalingType.FLAT:
                                display_text += " to "
                            StatDefinition.StatScalingType.INCREASED:
                                display_text += " increased "
                            StatDefinition.StatScalingType.REDUCED:
                                display_text += " reduced "
                            StatDefinition.StatScalingType.MORE:
                                display_text += " more "
                            StatDefinition.StatScalingType.LESS:
                                display_text += " less "

                        display_text += stat_name


                        if stack_count > 1 and per_stack_value != 0:
                            var formatted_per_stack = _format_stat_value(per_stack_value, stat_def, conditional.scaling_type)
                            display_text += " [color=gray](" + formatted_per_stack + " per stack)[/color]"


                        display_text += " [color=yellow]" + conditional.get_condition_description() + "[/color]"

                        info += "  • " + display_text + "\n"

                info += "\n"

    passives_label.text = info


func _format_stat_value(value: float, stat_def: StatDefinition, scaling_type: StatDefinition.StatScalingType) -> String:
    var decimal_places = 0

    if stat_def:
        decimal_places = stat_def.decimal_places
    else:

        if scaling_type == StatDefinition.StatScalingType.FLAT:
            decimal_places = 0
        else:
            decimal_places = 1


    if decimal_places == 0:
        return str(int(value))
    else:

        decimal_places = min(decimal_places, 2)
        var format_str = "%." + str(decimal_places) + "f"
        return format_str % value



func _compare_stat(label: String, stat_id: String, suffix: String = "") -> String:
    var base_val = test_exile.base_stats.get(stat_id)
    var current_val = test_exile.current_stats.get(stat_id)


    var stat_def = StatDefinitionManager.get_stat_definition(stat_id)

    var text = "  " + label + ": "

    if stat_def and stat_def.decimal_places == 0:
        text += str(int(current_val)) + suffix
        if base_val != current_val:
            text += " [color=gray](base: " + str(int(base_val)) + suffix + ")[/color]"
    else:
        text += str(current_val) + suffix
        if abs(base_val - current_val) > 0.01:
            text += " [color=gray](base: " + str(base_val) + suffix + ")[/color]"

    return text + "\n"

func _compare_damage_stat(label: String, stat_id: String) -> String:
    var base_val = test_exile.base_stats.get(stat_id) as Vector2
    var current_val = test_exile.current_stats.get(stat_id) as Vector2

    var text = "  " + label + ": " + str(int(current_val.x)) + "-" + str(int(current_val.y))

    if base_val != current_val:
        text += " [color=gray](base: " + str(int(base_val.x)) + "-" + str(int(base_val.y)) + ")[/color]"

    return text + "\n"

func _get_rarity_name(rarity: int) -> String:
    match rarity:
        0: return "Common"
        1: return "Uncommon"
        2: return "Rare"
        3: return "Legendary"
        _: return "Unknown"


func _input(event):
    if event.is_action_pressed("ui_accept"):

        print("\n========== GENERATING NEW EXILE ==========")
        generate_test_exile()
        display_exile_info()

    elif event.is_action_pressed("ui_up"):
        if test_exile:
            print("\n========== LEVELING UP ==========")
            var old_level = test_exile.level


            if test_exile.gain_experience(test_exile.get_exp_for_next_level()):
                print("Leveled up from ", old_level, " to ", test_exile.level)


                var hidden_count = 0
                for tag in test_exile.potential.entries:
                    if test_exile.potential.entries[tag].is_hidden:
                        hidden_count += 1
                print("Hidden potentials remaining: ", hidden_count)


            test_exile.current_stats = StatCalculator.calculate_final_stats(test_exile)
            display_exile_info()

    elif event.is_action_pressed("ui_down"):
        if test_exile and test_exile.pending_passive_points > 0:

            var choices = PassiveSelectionManager.generate_passive_choices(test_exile)
            if not choices.is_empty():
                var chosen = choices[0]
                print("Allocating passive: ", chosen.name)
                test_exile.allocate_passive(chosen.passive_id)


                display_exile_info()

func _compare_resistance_with_cap(label: String, stat_id: String, cap_id: String) -> String:
    var base_val = test_exile.base_stats.get(stat_id)
    var current_val = test_exile.current_stats.get(stat_id)
    var cap_val = test_exile.current_stats.get(cap_id)

    var text = "  " + label + ": " + str(current_val) + "/" + str(cap_val) + "%"

    if abs(base_val - current_val) > 0.01:
        text += " [color=gray](base: " + str(base_val) + "%)[/color]"


    if current_val >= cap_val:
        text += " [color=yellow](CAPPED)[/color]"

    return text + "\n"
