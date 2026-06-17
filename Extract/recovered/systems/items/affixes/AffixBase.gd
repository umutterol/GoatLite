class_name AffixBase
extends Resource


@export var affix_id: String = ""
@export var display_name: String = ""


@export_group("Affix Type")
@export var is_implicit: bool = false
@export var is_prefix: bool = false
@export var is_suffix: bool = false


@export_group("Valid Item Types")
@export var valid_on_helmet: bool = false
@export var valid_on_gloves: bool = false
@export var valid_on_boots: bool = false
@export var valid_on_chest: bool = false
@export var valid_on_1h_weapon: bool = false
@export var valid_on_2h_weapon: bool = false
@export var valid_on_ring: bool = false
@export var valid_on_amulet: bool = false
@export var valid_on_belt: bool = false
@export var valid_on_rucksack: bool = false
@export_subgroup("Weapon Types")
@export var valid_on_sword: bool = false
@export var valid_on_mace: bool = false
@export var valid_on_axe: bool = false
@export var valid_on_bow: bool = false
@export var valid_on_staff: bool = false
@export var valid_on_wand: bool = false
@export var valid_on_focus: bool = false
@export var valid_on_sceptre: bool = false
@export var valid_on_shield: bool = false
@export var valid_on_spear: bool = false
@export var valid_on_dagger: bool = false


@export_group("Custom Tags")
@export var custom_tags: Array[String] = []


@export_group("Spawn Weight")







@export_range(0, 1000) var spawn_weight: int = 100


@export_group("Stat Configuration")

@export var stat_type: String = ""


enum ModifierType{
    FLAT_ADDED, 
    PERCENT_INCREASED, 
    PERCENT_REDUCED, 
    PERCENT_MORE, 
    PERCENT_LESS, 
    FLAT_OVERRIDE
}
@export var modifier_type: ModifierType = ModifierType.FLAT_ADDED


@export var min_value: float = 0.0
@export var max_value: float = 0.0


@export var value_prefix: String = "+"
@export var value_suffix: String = ""


@export var min_item_level: int = 1
@export var max_item_level: int = 100

@export var global_damage_flag: bool = false







@export var is_local: bool = false




@export var value_by_level: Dictionary = {}


@export_group("Value Tiers (Editor Helper)")
@export var use_tier_helper: bool = false
@export var value_tiers: Array[AffixValueTier] = []


@export var tags: Array[String] = []


func _validate_property(property: Dictionary) -> void :
    if property.name == "value_tiers":
        property.usage = PROPERTY_USAGE_DEFAULT if use_tier_helper else PROPERTY_USAGE_NO_EDITOR

    if property.name == "value_by_level":
        property.usage = PROPERTY_USAGE_DEFAULT if not use_tier_helper else PROPERTY_USAGE_NO_EDITOR


func _set(property: StringName, value: Variant) -> bool:
    if property == "value_tiers" and use_tier_helper:

        var new_dict = {}
        for tier in value:
            if tier != null:
                new_dict[tier.item_level] = tier.to_dictionary()
        value_by_level = new_dict
        return true
    return false


func can_appear_on_item(item: ItemBase) -> bool:


    if item.category == ItemEnums.ItemCategory.CURRENCY:
        return false

    match item.category:
        ItemEnums.ItemCategory.ARMOUR:
            match item.armour_type:
                ItemEnums.ArmourType.HELMET:
                    if not valid_on_helmet: return false
                ItemEnums.ArmourType.GLOVES:
                    if not valid_on_gloves: return false
                ItemEnums.ArmourType.BOOTS:
                    if not valid_on_boots: return false
                ItemEnums.ArmourType.CHEST:
                    if not valid_on_chest: return false

        ItemEnums.ItemCategory.JEWELLERY:
            match item.jewellery_type:
                ItemEnums.JewelleryType.RING:
                    if not valid_on_ring: return false
                ItemEnums.JewelleryType.AMULET:
                    if not valid_on_amulet: return false
                ItemEnums.JewelleryType.BELT:
                    if not valid_on_belt: return false

        ItemEnums.ItemCategory.WEAPON:

            if item.hand_type == ItemEnums.HandType.ONE_HANDED:
                if not valid_on_1h_weapon: return false
            else:
                if not valid_on_2h_weapon: return false


            match item.weapon_type:
                ItemEnums.WeaponType.SWORD:
                    if not valid_on_sword: return false
                ItemEnums.WeaponType.MACE:
                    if not valid_on_mace: return false
                ItemEnums.WeaponType.AXE:
                    if not valid_on_axe: return false
                ItemEnums.WeaponType.BOW:
                    if not valid_on_bow: return false
                ItemEnums.WeaponType.STAFF:
                    if not valid_on_staff: return false
                ItemEnums.WeaponType.WAND:
                    if not valid_on_wand: return false
                ItemEnums.WeaponType.SPEAR:
                    if not valid_on_spear: return false
                ItemEnums.WeaponType.DAGGER:
                    if not valid_on_dagger: return false

        ItemEnums.ItemCategory.OFFHAND:
            match item.offhand_type:
                ItemEnums.OffhandType.FOCUS:
                    if not valid_on_focus: return false
                ItemEnums.OffhandType.SCEPTRE:
                    if not valid_on_sceptre: return false
                ItemEnums.OffhandType.SHIELD:
                    if not valid_on_shield: return false

        ItemEnums.ItemCategory.RUCKSACK:
            if not valid_on_rucksack: return false

    return true








func get_display_text(value: float) -> String:
    var formatted_value = str(int(value)) if value == int(value) else "%.1f" % value
    var is_percent_mod: = modifier_type in [
        ModifierType.PERCENT_INCREASED, 
        ModifierType.PERCENT_REDUCED, 
        ModifierType.PERCENT_MORE, 
        ModifierType.PERCENT_LESS, 
    ]
    var effective_prefix: = "" if is_percent_mod else value_prefix

    match modifier_type:
        ModifierType.PERCENT_INCREASED:
            return effective_prefix + formatted_value + "% increased " + value_suffix
        ModifierType.PERCENT_REDUCED:
            return effective_prefix + formatted_value + "% reduced " + value_suffix
        ModifierType.PERCENT_MORE:
            return effective_prefix + formatted_value + "% more " + value_suffix
        ModifierType.PERCENT_LESS:
            return effective_prefix + formatted_value + "% less " + value_suffix
        ModifierType.FLAT_OVERRIDE:
            return value_suffix + " is always " + formatted_value
        _:


            return effective_prefix + formatted_value + value_suffix + " to " + display_name


func get_display_text_range(min_val: float, max_val: float) -> String:
    var min_formatted = str(int(min_val)) if min_val == int(min_val) else "%.1f" % min_val
    var max_formatted = str(int(max_val)) if max_val == int(max_val) else "%.1f" % max_val
    var is_percent_mod: = modifier_type in [
        ModifierType.PERCENT_INCREASED, 
        ModifierType.PERCENT_REDUCED, 
        ModifierType.PERCENT_MORE, 
        ModifierType.PERCENT_LESS, 
    ]
    var effective_prefix: = "" if is_percent_mod else value_prefix
    return effective_prefix + min_formatted + "-" + max_formatted + value_suffix


func get_value_range_at_level(item_level: int) -> Dictionary:

    if use_tier_helper and not value_by_level.is_empty():

        var best_level = 0
        var best_values = {}

        for level in value_by_level.keys():
            if level <= item_level and level > best_level:
                best_level = level
                best_values = value_by_level[level]


        if best_values.has("min") and best_values.has("max"):

            return {"min": best_values["min"], "max": best_values["max"]}
        elif best_values.has("min_low") and best_values.has("max_high"):

            return best_values
        elif best_values.has("value"):

            return {"min": best_values["value"], "max": best_values["value"]}
        else:




            push_warning("AffixBase '%s': no tier matched item_level=%d — falling back to base min/max (%s/%s). Author a tier at or below min_item_level=%d." % [affix_id, item_level, str(min_value), str(max_value), min_item_level])
            return {"min": min_value, "max": max_value}


    return {"min": min_value, "max": max_value}


func roll_value_at_level(item_level: int) -> Variant:
    var range = get_value_range_at_level(item_level)


    if range.has("min_low") and range.has("max_high"):

        var rolled_min = randf_range(range["min_low"], range["min_high"])
        var rolled_max = randf_range(range["max_low"], range["max_high"])
        return {"min": rolled_min, "max": rolled_max}
    else:

        return randf_range(range["min"], range["max"])


func get_value_at_level(item_level: int) -> float:
    var range = get_value_range_at_level(item_level)

    return range.get("max", max_value)


func is_range_affix() -> bool:
    if value_by_level.is_empty():
        return false


    var first_tier = value_by_level.values()[0]
    return first_tier.has("min_low") and first_tier.has("max_high")
