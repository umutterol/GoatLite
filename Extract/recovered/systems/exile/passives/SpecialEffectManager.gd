class_name SpecialEffectManager
extends RefCounted









const SPECIAL_EFFECT_DISPLAY: Dictionary = {
    "unbreakable": {
        "name": "Unbreakable", 
        "description": "Cannot leave the guild from broken Morale, no matter how low it falls."
    }, 

    "cannot_be_stunned": {"name": "Stalwart", "description": "Cannot be stunned."}, 
    "cannot_be_slowed": {"name": "Unhindered", "description": "Cannot be slowed."}, 
    "cannot_gain_life": {"name": "Lifebound", "description": "Cannot gain Life through any means."}, 
    "reflect_damage": {"name": "Thorns", "description": "Reflects a portion of incoming damage back to the attacker."}, 
    "reduced_stun_duration": {"name": "Resolute", "description": "Stuns wear off twice as fast."}, 
    "increased_stun_duration": {"name": "Brittle Mind", "description": "Stuns last 50% longer."}, 
}





static func get_effect_display(effect_id: String) -> String:
    if not SPECIAL_EFFECT_DISPLAY.has(effect_id):
        push_warning("SpecialEffectManager: no display entry for special_effect '%s' — add one to SPECIAL_EFFECT_DISPLAY." % effect_id)
        return "[code]%s[/code] — [color=red][unknown effect][/color]" % effect_id
    var entry: Dictionary = SPECIAL_EFFECT_DISPLAY[effect_id]
    return "[code]%s[/code] — %s" % [entry["name"], entry["description"]]




static func get_all_special_effects(exile_data: ExileData) -> Array[String]:
    var effects: Array[String] = []


    if exile_data.class_definition:
        for effect in exile_data.class_definition.special_effects:
            if effect not in effects:
                effects.append(effect)


    for passive_id in exile_data.allocated_passives:
        var passive_def = PassiveLibrary.get_passive_by_id(passive_id)
        if passive_def:
            for effect in passive_def.special_effects:
                if effect not in effects:
                    effects.append(effect)


    for trait_id in exile_data.traits:
        var trait_def = TraitLibrary.get_trait_by_id(trait_id)
        if trait_def:
            for effect in trait_def.special_effects:
                if effect not in effects:
                    effects.append(effect)

    return effects


static func has_special_effect(exile_data: ExileData, effect_id: String) -> bool:
    return effect_id in get_all_special_effects(exile_data)




static func get_active_conditionals(exile_data: ExileData) -> Array[Dictionary]:
    var active_conditionals: Array[Dictionary] = []


    if exile_data.class_definition:
        for conditional in exile_data.class_definition.conditional_bonuses:
            if conditional.is_condition_met(exile_data, exile_data.current_stats):
                active_conditionals.append({
                    "source": "Class: " + exile_data.class_definition.name, 
                    "bonus": conditional, 
                    "text": conditional.get_display_text()
                })


    for passive_id in exile_data.allocated_passives:
        var stack_count = exile_data.allocated_passives[passive_id]
        var passive_def = PassiveLibrary.get_passive_by_id(passive_id)
        if passive_def:
            for conditional in passive_def.conditional_bonuses:
                if conditional.is_condition_met(exile_data, exile_data.current_stats):
                    active_conditionals.append({
                        "source": "Passive: " + passive_def.name, 
                        "bonus": conditional, 
                        "text": conditional.get_display_text(stack_count), 
                        "stacks": stack_count
                    })


    for trait_id in exile_data.traits:
        var trait_def = TraitLibrary.get_trait_by_id(trait_id)
        if trait_def:
            for conditional in trait_def.conditional_bonuses:
                if conditional.is_condition_met(exile_data, exile_data.current_stats):
                    active_conditionals.append({
                        "source": "Trait: " + trait_def.name, 
                        "bonus": conditional, 
                        "text": conditional.get_display_text()
                    })

    return active_conditionals


static func get_active_conditionals_text(exile_data: ExileData) -> Array[String]:
    var descriptions: Array[String] = []
    var active = get_active_conditionals(exile_data)

    for conditional_data in active:
        descriptions.append(conditional_data.text)

    return descriptions




static func is_immune_to_status(exile_data: ExileData, status: String) -> bool:
    var immunity_effect = "immune_to_" + status
    return has_special_effect(exile_data, immunity_effect)

static func can_be_stunned(exile_data: ExileData) -> bool:
    return not has_special_effect(exile_data, "cannot_be_stunned")

static func can_be_slowed(exile_data: ExileData) -> bool:
    return not has_special_effect(exile_data, "cannot_be_slowed")

static func has_life_gain_prevention(exile_data: ExileData) -> bool:
    return has_special_effect(exile_data, "cannot_gain_life")

static func triggers_on_kill_effects(exile_data: ExileData) -> bool:
    return has_special_effect(exile_data, "trigger_on_kill")

static func has_damage_reflection(exile_data: ExileData) -> bool:
    return has_special_effect(exile_data, "reflect_damage")




static func get_stun_duration_modifier(exile_data: ExileData) -> float:
    if has_special_effect(exile_data, "reduced_stun_duration"):
        return 0.5
    elif has_special_effect(exile_data, "increased_stun_duration"):
        return 1.5
    return 1.0

static func get_ailment_chance_modifier(exile_data: ExileData, ailment: String) -> float:
    var reduced_effect = "reduced_" + ailment + "_chance"
    var increased_effect = "increased_" + ailment + "_chance"

    if has_special_effect(exile_data, reduced_effect):
        return 0.5
    elif has_special_effect(exile_data, increased_effect):
        return 1.5
    return 1.0



static func debug_print_all_effects(exile_data: ExileData):
    print("\n=== Special Effects for %s ===" % exile_data.name)

    var effects = get_all_special_effects(exile_data)
    if effects.is_empty():
        print("No special effects")
    else:
        print("Special Effects:")
        for effect in effects:
            print("  - " + effect)

    var conditionals = get_active_conditionals(exile_data)
    if conditionals.is_empty():
        print("No active conditional bonuses")
    else:
        print("\nActive Conditional Bonuses:")
        for cond in conditionals:
            print("  - %s: %s" % [cond.source, cond.text])




static func get_damage_conversion(exile_data: ExileData) -> Dictionary:

    var conversions = {}

    if has_special_effect(exile_data, "phys_to_fire_conversion"):
        conversions["physical_to_fire"] = 0.5

    return conversions

static func get_on_hit_effects(exile_data: ExileData) -> Array[String]:

    var on_hit_effects: Array[String] = []

    if has_special_effect(exile_data, "poison_on_hit"):
        on_hit_effects.append("poison")
    if has_special_effect(exile_data, "blind_on_hit"):
        on_hit_effects.append("blind")

    return on_hit_effects

static func get_aura_effects(exile_data: ExileData) -> Array[String]:

    var auras: Array[String] = []

    if has_special_effect(exile_data, "vitality_aura"):
        auras.append("vitality_aura")
    if has_special_effect(exile_data, "intimidation_aura"):
        auras.append("intimidation_aura")

    return auras
