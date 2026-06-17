class_name CraftingDefinitions
extends RefCounted


























enum CraftType{EXALT, CHAOS, VAAL}

enum CorruptOutcome{
    REROLL_AFFIXES, 
    REROLL_RANGES, 
    SHIFT_TIERS, 
    ADD_CORRUPTED_MOD, 
}





const CRAFTS: = {
    CraftType.EXALT: {
        "id": "exalt", 
        "display_name": "Exalted Orb", 
        "short_blurb": "Adds a random affix to a Magic or Rare item, upgrading rarity as needed.", 
        "long_blurb": "Adds one new affix to the item, randomly choosing prefix or suffix from the open slots. Normal items become Magic on the first affix; Magic items become Rare on the third. Caps at 4 affixes (2 prefix + 2 suffix) per Rare rules. Does not interact with implicit modifiers.", 
        "cost_currency": "exalt", 
        "cost_per_item_level": 1, 
        "flat_cost": 0, 
        "requires_open_slot": true, 
        "requires_existing_affix": false, 
    }, 
    CraftType.CHAOS: {
        "id": "chaos", 
        "display_name": "Chaos Orb", 
        "short_blurb": "Replaces one affix with a different one of the same kind.", 
        "long_blurb": "Removes a chosen affix and rolls a new one in its place. The new affix is always a different modifier of the same slot kind (prefix→prefix, suffix→suffix). Does not interact with implicit modifiers.", 
        "cost_currency": "chaos", 
        "cost_per_item_level": 1, 
        "flat_cost": 0, 
        "requires_open_slot": false, 
        "requires_existing_affix": true, 
    }, 
    CraftType.VAAL: {
        "id": "vaal", 
        "display_name": "Vaal Orb", 
        "short_blurb": "Corrupts the item with one of four unpredictable outcomes. Locks the item from further crafting.", 
        "long_blurb": "Applies one of four outcomes with even weighting. The item becomes Corrupted and can no longer be crafted with any orb afterwards.\n\n• Reroll all affixes — same number of affixes, fresh random selection (can repeat).\n• Reroll affix values — keep affixes, re-roll their values within their current tier (affects implicits too).\n• Tier shift — each explicit affix shifts ±1 tier (independent rolls, can exceed normal item level caps).\n• Corrupted modifier — adds one new corruption-only modifier on top of the existing affixes.", 
        "cost_currency": "vaal_orb", 
        "cost_per_item_level": 0, 
        "flat_cost": 1, 
        "requires_open_slot": false, 
        "requires_existing_affix": false, 
    }, 
}





const CORRUPT_OUTCOMES: = {
    CorruptOutcome.REROLL_AFFIXES: {
        "display_name": "Reroll Affixes", 
        "blurb": "Same number of affixes, fresh roll. Affixes may repeat by chance.", 
    }, 
    CorruptOutcome.REROLL_RANGES: {
        "display_name": "Reroll Values", 
        "blurb": "Affixes stay; their values re-roll within the current tier. Affects implicits.", 
    }, 
    CorruptOutcome.SHIFT_TIERS: {
        "display_name": "Tier Shift", 
        "blurb": "Each explicit affix shifts ±1 tier (independent rolls). Can exceed item level caps.", 
    }, 
    CorruptOutcome.ADD_CORRUPTED_MOD: {
        "display_name": "Corrupted Modifier", 
        "blurb": "A new corruption-only modifier is added to the item.", 
    }, 
}







static func get_cost_for_item(type: CraftType, item: Item) -> int:
    var def: Dictionary = CRAFTS.get(type, {})
    if def.is_empty() or item == null:
        return 0
    var per_ilvl: int = int(def.get("cost_per_item_level", 0))
    var flat: int = int(def.get("flat_cost", 0))
    return flat + per_ilvl * item.item_level






static func get_cost_label(type: CraftType, item: Item) -> String:
    var def: Dictionary = CRAFTS.get(type, {})
    if def.is_empty():
        return ""
    var cost: int = get_cost_for_item(type, item)
    var noun: String = def.get("display_name", "Orb")


    var plural: String = noun + "s"
    return "%d %s" % [cost, noun if cost == 1 else plural]




static func get_type_by_id(craft_id: String) -> int:
    for type in CRAFTS.keys():
        if CRAFTS[type].get("id", "") == craft_id:
            return type
    return -1
