class_name ItemEnums
extends RefCounted





enum ItemCategory{
    ARMOUR, 
    JEWELLERY, 
    OFFHAND, 
    RUCKSACK, 
    WEAPON, 




    CURRENCY, 
}


enum ArmourType{
    BOOTS, 
    CHEST, 
    HELMET, 
    GLOVES
}

enum JewelleryType{
    RING, 
    AMULET, 
    BELT
}

enum OffhandType{
    FOCUS, 
    SCEPTRE, 
    SHIELD
}

enum WeaponType{
    AXE, 
    BOW, 
    MACE, 
    SPEAR, 
    STAFF, 
    SWORD, 
    WAND, 
    DAGGER, 



    UNARMED, 
}










const WEAPON_TYPE_GLYPHS: = {
    WeaponType.AXE: "A", 
    WeaponType.BOW: "B", 
    WeaponType.MACE: "M", 
    WeaponType.SPEAR: "P", 
    WeaponType.STAFF: "T", 
    WeaponType.SWORD: "S", 
    WeaponType.WAND: "W", 
    WeaponType.DAGGER: "D", 
    WeaponType.UNARMED: "U", 
}


static func get_weapon_type_glyph(type: WeaponType) -> String:
    return WEAPON_TYPE_GLYPHS.get(type, "?")


static func get_weapon_type_name(type: WeaponType) -> String:
    match type:
        WeaponType.AXE: return "Axe"
        WeaponType.BOW: return "Bow"
        WeaponType.MACE: return "Mace"
        WeaponType.SPEAR: return "Spear"
        WeaponType.STAFF: return "Staff"
        WeaponType.SWORD: return "Sword"
        WeaponType.WAND: return "Wand"
        WeaponType.DAGGER: return "Dagger"
        WeaponType.UNARMED: return "Unarmed"
        _: return "Unknown"


enum HandType{
    ONE_HANDED, 
    TWO_HANDED
}


enum EquipSlot{
    HELMET, 
    CHEST, 
    BOOTS, 
    GLOVES, 
    MAIN_HAND, 
    OFF_HAND, 
    BOTH_HANDS, 
    AMULET, 
    RING_LEFT, 
    RING_RIGHT, 
    BELT, 
    RUCKSACK
}




static func get_category_from_equip_slot(slot: EquipSlot) -> ItemCategory:
    match slot:
        EquipSlot.HELMET, EquipSlot.CHEST, EquipSlot.BOOTS, EquipSlot.GLOVES:
            return ItemCategory.ARMOUR
        EquipSlot.AMULET, EquipSlot.RING_LEFT, EquipSlot.RING_RIGHT, EquipSlot.BELT:
            return ItemCategory.JEWELLERY
        EquipSlot.OFF_HAND:
            return ItemCategory.OFFHAND
        EquipSlot.RUCKSACK:
            return ItemCategory.RUCKSACK
        EquipSlot.MAIN_HAND, EquipSlot.BOTH_HANDS:
            return ItemCategory.WEAPON
        _:
            push_error("Unknown equip slot: " + str(slot))
            return ItemCategory.WEAPON


static func get_category_name(category: ItemCategory) -> String:
    match category:
        ItemCategory.ARMOUR: return "Armour"
        ItemCategory.JEWELLERY: return "Jewellery"
        ItemCategory.OFFHAND: return "Offhand"
        ItemCategory.RUCKSACK: return "Rucksack"
        ItemCategory.WEAPON: return "Weapon"
        ItemCategory.CURRENCY: return "Currency"
        _: return "Unknown"

static func get_equip_slot_name(slot: EquipSlot) -> String:
    match slot:
        EquipSlot.HELMET: return "Helmet"
        EquipSlot.CHEST: return "Chest"
        EquipSlot.BOOTS: return "Boots"
        EquipSlot.GLOVES: return "Gloves"
        EquipSlot.MAIN_HAND: return "Main Hand"
        EquipSlot.OFF_HAND: return "Off Hand"
        EquipSlot.BOTH_HANDS: return "Two-Handed"
        EquipSlot.AMULET: return "Amulet"
        EquipSlot.RING_LEFT: return "Left Ring"
        EquipSlot.RING_RIGHT: return "Right Ring"
        EquipSlot.BELT: return "Belt"
        EquipSlot.RUCKSACK: return "Rucksack"
        _: return "Unknown"
