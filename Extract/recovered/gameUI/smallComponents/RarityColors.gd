class_name RarityColors
extends RefCounted


const COMMON = Color(0.5, 0.5, 0.5)
const UNCOMMON = Color(0.2, 0.804, 1)
const RARE = Color(0.851, 0.729, 0.071)
const LEGENDARY = Color(0.82, 0.435, 0.11)


const COMMON_HEX = "#808080"
const UNCOMMON_HEX = "#33ccff"
const RARE_HEX = "#d9ba12"
const LEGENDARY_HEX = "#d16f1c"


static func get_color(rarity: int) -> Color:
    match rarity:
        ClassDefinition.ClassRarity.COMMON:
            return COMMON
        ClassDefinition.ClassRarity.UNCOMMON:
            return UNCOMMON
        ClassDefinition.ClassRarity.RARE:
            return RARE
        ClassDefinition.ClassRarity.LEGENDARY:
            return LEGENDARY
        _:
            return Color.WHITE


static func get_hex(rarity: int) -> String:
    match rarity:
        ClassDefinition.ClassRarity.COMMON:
            return COMMON_HEX
        ClassDefinition.ClassRarity.UNCOMMON:
            return UNCOMMON_HEX
        ClassDefinition.ClassRarity.RARE:
            return RARE_HEX
        ClassDefinition.ClassRarity.LEGENDARY:
            return LEGENDARY_HEX
        _:
            return "#FFFFFF"


static func get_rarity_name(rarity: int) -> String:
    match rarity:
        ClassDefinition.ClassRarity.COMMON:
            return "Common"
        ClassDefinition.ClassRarity.UNCOMMON:
            return "Uncommon"
        ClassDefinition.ClassRarity.RARE:
            return "Rare"
        ClassDefinition.ClassRarity.LEGENDARY:
            return "Legendary"
        _:
            return "Unknown"












static func get_item_color(item_rarity: int) -> Color:
    match item_rarity:
        Item.Rarity.COMMON:
            return COMMON
        Item.Rarity.UNCOMMON:
            return UNCOMMON
        Item.Rarity.RARE:
            return RARE
        Item.Rarity.UNIQUE:
            return LEGENDARY
        _:
            return Color.WHITE



static func get_item_hex(item_rarity: int) -> String:
    match item_rarity:
        Item.Rarity.COMMON:
            return COMMON_HEX
        Item.Rarity.UNCOMMON:
            return UNCOMMON_HEX
        Item.Rarity.RARE:
            return RARE_HEX
        Item.Rarity.UNIQUE:
            return LEGENDARY_HEX
        _:
            return "#FFFFFF"
