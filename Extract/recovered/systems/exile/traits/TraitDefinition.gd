class_name TraitDefinition
extends Resource







enum TraitCategory{
    BACKGROUND, 
    LEARNED, 
    SCAR
}




enum TraitRarity{
    COMMON, 
    UNCOMMON, 
    RARE, 
    LEGENDARY
}







@export var trait_id: String = ""



@export var name: String = ""




@export_multiline var description: String = ""



@export var category: TraitCategory = TraitCategory.BACKGROUND



@export var rarity: TraitRarity = TraitRarity.COMMON



@export var icon: Texture2D






@export var allowed_classes: Array[String] = []




@export var forbidden_classes: Array[String] = []







@export var stat_bonuses: Array[PassiveStatBonus] = []




@export var conditional_bonuses: Array[ConditionalStatBonus] = []





@export var special_effects: Array[String] = []











@export var potential_tags: Array[String] = []





@export var potential_values: Array[float] = []






@export var incompatible_traits: Array[String] = []




@export var required_level: int = 1





@export var unique: bool = true




@export var hidden: bool = false


func get_drop_weight() -> float:
    var base_weights = {
        TraitRarity.COMMON: GameSettings.TRAIT_RARITY_WEIGHTS["COMMON"], 
        TraitRarity.UNCOMMON: GameSettings.TRAIT_RARITY_WEIGHTS["UNCOMMON"], 
        TraitRarity.RARE: GameSettings.TRAIT_RARITY_WEIGHTS["RARE"], 
        TraitRarity.LEGENDARY: GameSettings.TRAIT_RARITY_WEIGHTS["LEGENDARY"]
    }

    return base_weights[rarity]


func is_class_compatible(exile_class: String) -> bool:

    if forbidden_classes.has(exile_class):
        return false


    if allowed_classes.is_empty():
        return true


    return allowed_classes.has(exile_class)


func get_potential_modifiers() -> Dictionary:
    var result = {}
    var i = 0
    while i < potential_tags.size() and i < potential_values.size():
        result[potential_tags[i]] = potential_values[i]
        i += 1
    return result


func get_full_description() -> String:
    var text = description + "\n\n"


    var i = 0
    while i < stat_bonuses.size():
        text += stat_bonuses[i].get_display_text(1) + "\n"
        i += 1


    i = 0
    while i < conditional_bonuses.size():
        text += conditional_bonuses[i].get_display_text(1) + "\n"
        i += 1




    if not special_effects.is_empty():
        text += "\n[color=cyan]Grants:[/color]\n"
        for effect_id in special_effects:
            text += "  " + SpecialEffectManager.get_effect_display(effect_id) + "\n"


    if not potential_tags.is_empty():
        text += "\n[color=cyan]Growth Potentials:[/color]\n"
        i = 0
        while i < potential_tags.size() and i < potential_values.size():
            var tag = potential_tags[i]
            var modifier = potential_values[i]
            var value_sign = "+" if modifier > 0 else ""
            text += "  " + value_sign + str(modifier) + " to " + tag + " potential\n"
            i += 1

    return text.strip_edges()
