class_name PassiveDefinition
extends Resource





enum PassiveType{
    PASSIVE, 
    NOTABLE_PASSIVE, 
    KEYSTONE_PASSIVE
}








enum PassiveRarity{
    COMMON, 
    UNCOMMON, 
    RARE, 
    LEGENDARY
}





@export var passive_id: String = ""


@export var name: String = ""




@export_multiline var description: String = ""




@export var passive_type: PassiveType = PassiveType.PASSIVE



@export var rarity: PassiveRarity = PassiveRarity.COMMON


@export var icon: Texture2D





@export var max_stacks: int = 1




@export var requires_previous: Array[String] = []




@export var mutually_exclusive: Array[String] = []




@export var class_restricted: Array[String] = []



@export var min_level: int = 1

















@export var stat_tags: Array[String] = []



@export var theme_tags: Array[String] = []



@export var category_tags: Array[String] = []





@export var primary_tag: String = ""







@export var required_passive_ids: Array[String] = []


@export var required_stack_counts: Array[int] = []




@export var stat_bonuses: Array[PassiveStatBonus] = []




@export var conditional_bonuses: Array[ConditionalStatBonus] = []






@export var special_effects: Array[String] = []



func get_drop_weight() -> float:
    var base_weights = {
        PassiveRarity.COMMON: GameSettings.PASSIVE_RARITY_WEIGHTS["COMMON"], 
        PassiveRarity.UNCOMMON: GameSettings.PASSIVE_RARITY_WEIGHTS["UNCOMMON"], 
        PassiveRarity.RARE: GameSettings.PASSIVE_RARITY_WEIGHTS["RARE"], 
        PassiveRarity.LEGENDARY: GameSettings.PASSIVE_RARITY_WEIGHTS["LEGENDARY"]
    }

    var type_multiplier = 1.0
    match passive_type:
        PassiveType.PASSIVE:
            type_multiplier = 1.0
        PassiveType.NOTABLE_PASSIVE:
            type_multiplier = 0.3
        PassiveType.KEYSTONE_PASSIVE:
            type_multiplier = 0.1
        _:
            type_multiplier = 1.0

    return base_weights[rarity] * type_multiplier

func get_all_tags() -> Array[String]:
    var all_tags: Array[String] = []
    all_tags.append_array(stat_tags)
    all_tags.append_array(theme_tags)
    all_tags.append_array(category_tags)
    return all_tags

func has_tag(tag: String) -> bool:
    return tag in get_all_tags() or tag == primary_tag






func get_full_description(stack_count: int = 1) -> String:
    var text = description + "\n\n"

    for bonus in stat_bonuses:
        text += bonus.get_display_text(stack_count) + "\n"



    for conditional in conditional_bonuses:
        text += conditional.get_display_text(stack_count) + "\n"



    if not special_effects.is_empty():
        text += "\n[color=cyan]Grants:[/color]\n"
        for effect_id in special_effects:
            text += "  " + SpecialEffectManager.get_effect_display(effect_id) + "\n"

    return text.strip_edges()
