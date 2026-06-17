class_name SalvageCalculator
extends RefCounted




















static func salvage_yield(item: Item) -> Dictionary:
    if item == null or item.base_item == null:
        push_warning("SalvageCalculator: tried to salvage null item / base_item")
        return {"scrap": 0, "chaos": 0}



    if item.base_item.category == ItemEnums.ItemCategory.CURRENCY:
        return {"scrap": 0, "chaos": 0}
    return {
        "scrap": scrap_for(item), 
        "chaos": chaos_for(item), 
    }




static func scrap_for(item: Item) -> int:
    if item == null or item.base_item == null:
        return 0
    var base: ItemBase = item.base_item
    if _is_two_handed_weapon(base) or _is_chest_armour(base):
        return 2
    return 1



static func chaos_for(item: Item) -> int:
    if item == null:
        return 0
    var score: int = affix_score(item)
    if score <= 0:
        return 0
    return maxi(1, score / 4)





static func affix_score(item: Item) -> int:
    if item == null:
        return 0
    var total: int = 0
    for affix_instance in item.prefix_affixes:
        total += _tier_level_of(affix_instance)
    for affix_instance in item.suffix_affixes:
        total += _tier_level_of(affix_instance)
    return total




static func _is_two_handed_weapon(base: ItemBase) -> bool:
    return base.category == ItemEnums.ItemCategory.WEAPON\
and base.hand_type == ItemEnums.HandType.TWO_HANDED


static func _is_chest_armour(base: ItemBase) -> bool:
    return base.category == ItemEnums.ItemCategory.ARMOUR\
and base.armour_type == ItemEnums.ArmourType.CHEST





static func _tier_level_of(affix_instance) -> int:
    if affix_instance == null:
        return 0
    var tier: int = int(affix_instance.tier_level)
    return maxi(1, tier)
