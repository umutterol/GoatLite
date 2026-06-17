@tool
class_name ItemBase
extends Resource


@export_group("Basic Info")
@export var item_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D


@export_group("Item Type")
@export var category: ItemEnums.ItemCategory = ItemEnums.ItemCategory.WEAPON
@export var armour_type: ItemEnums.ArmourType = ItemEnums.ArmourType.CHEST
@export var jewellery_type: ItemEnums.JewelleryType = ItemEnums.JewelleryType.RING
@export var offhand_type: ItemEnums.OffhandType = ItemEnums.OffhandType.SHIELD
@export var weapon_type: ItemEnums.WeaponType = ItemEnums.WeaponType.SWORD
@export var hand_type: ItemEnums.HandType = ItemEnums.HandType.ONE_HANDED
@export var equip_slot: ItemEnums.EquipSlot = ItemEnums.EquipSlot.MAIN_HAND


@export_group("Level Requirements")
@export_range(1, 100) var min_item_level: int = 1
@export_range(1, 100) var required_level: int = 1


@export_group("Inventory")
@export_range(1, 4) var grid_width: int = 1
@export_range(1, 6) var grid_height: int = 1


@export_group("Base Stats")
@export var movement: int = 0
@export var base_armour_min: int = 0
@export var base_armour_max: int = 0
@export var base_evasion_min: int = 0
@export var base_evasion_max: int = 0
@export var base_physical_damage_min: int = 0
@export var base_physical_damage_max: int = 0
@export var base_fire_damage_min: int = 0
@export var base_fire_damage_max: int = 0
@export var base_cold_damage_min: int = 0
@export var base_cold_damage_max: int = 0
@export var base_lightning_damage_min: int = 0
@export var base_lightning_damage_max: int = 0
@export var base_chaos_damage_min: int = 0
@export var base_chaos_damage_max: int = 0
@export var base_attack_speed: float = 1.0
@export var base_critical_chance: float = 5.0
@export var base_attack_range: float = 1.5
@export var base_block_chance_min: int = 0
@export var base_block_chance_max: int = 0
@export var base_block_amount_min: int = 0
@export var base_block_amount_max: int = 0


@export_group("Implicit Modifiers")
@export var implicit_affixes: Array[AffixBase] = []


@export_group("Ranged Weapon?")
@export var ranged: bool = false




@export_group("Combat VFX")
@export var attack_vfx: AttackVFX = null


@export_group("Drop Control")
@export var drop_tags: Array[String] = []
@export var exclusive_tags: Array[String] = []





@export_group("Monster Infrequent")




@export var is_monster_infrequent: bool = false






@export var monster_infrequent_set: String = ""


func _on_category_changed():

    match category:
        ItemEnums.ItemCategory.ARMOUR:
            match armour_type:
                ItemEnums.ArmourType.HELMET: equip_slot = ItemEnums.EquipSlot.HELMET
                ItemEnums.ArmourType.CHEST: equip_slot = ItemEnums.EquipSlot.CHEST
                ItemEnums.ArmourType.BOOTS: equip_slot = ItemEnums.EquipSlot.BOOTS
                ItemEnums.ArmourType.GLOVES: equip_slot = ItemEnums.EquipSlot.GLOVES
        ItemEnums.ItemCategory.JEWELLERY:
            match jewellery_type:
                ItemEnums.JewelleryType.AMULET: equip_slot = ItemEnums.EquipSlot.AMULET
                ItemEnums.JewelleryType.RING: equip_slot = ItemEnums.EquipSlot.RING_LEFT
                ItemEnums.JewelleryType.BELT: equip_slot = ItemEnums.EquipSlot.BELT
        ItemEnums.ItemCategory.OFFHAND:
            equip_slot = ItemEnums.EquipSlot.OFF_HAND
        ItemEnums.ItemCategory.RUCKSACK:
            equip_slot = ItemEnums.EquipSlot.RUCKSACK
        ItemEnums.ItemCategory.WEAPON:
            if hand_type == ItemEnums.HandType.TWO_HANDED:
                equip_slot = ItemEnums.EquipSlot.BOTH_HANDS
            else:
                equip_slot = ItemEnums.EquipSlot.MAIN_HAND
        ItemEnums.ItemCategory.CURRENCY:




            pass


    _clear_inappropriate_stats()

func _clear_inappropriate_stats():

    match category:
        ItemEnums.ItemCategory.WEAPON:
            base_armour_min = 0
            base_armour_max = 0
            base_evasion_min = 0
            base_evasion_max = 0
            base_block_chance_min = 0
            base_block_chance_max = 0
            base_block_amount_min = 0
            base_block_amount_max = 0
        ItemEnums.ItemCategory.ARMOUR:
            base_physical_damage_min = 0
            base_physical_damage_max = 0
            base_cold_damage_min = 0
            base_cold_damage_max = 0
            base_lightning_damage_min = 0
            base_lightning_damage_max = 0
            base_fire_damage_min = 0
            base_fire_damage_max = 0
            base_chaos_damage_min = 0
            base_chaos_damage_max = 0
            base_attack_speed = 1.0
            base_critical_chance = 5.0
            base_block_chance_min = 0
            base_block_chance_max = 0
            base_block_amount_min = 0
            base_block_amount_max = 0
        ItemEnums.ItemCategory.JEWELLERY, ItemEnums.ItemCategory.RUCKSACK:

            base_armour_min = 0
            base_armour_max = 0
            base_evasion_min = 0
            base_evasion_max = 0
            base_physical_damage_min = 0
            base_physical_damage_max = 0
            base_cold_damage_min = 0
            base_cold_damage_max = 0
            base_lightning_damage_min = 0
            base_lightning_damage_max = 0
            base_fire_damage_min = 0
            base_fire_damage_max = 0
            base_chaos_damage_min = 0
            base_attack_speed = 1.0
            base_critical_chance = 5.0
            base_block_chance_min = 0
            base_block_chance_max = 0
            base_block_amount_min = 0
            base_block_amount_max = 0
        ItemEnums.ItemCategory.OFFHAND:
            base_physical_damage_min = 0
            base_physical_damage_max = 0
            base_cold_damage_min = 0
            base_cold_damage_max = 0
            base_lightning_damage_min = 0
            base_lightning_damage_max = 0
            base_fire_damage_min = 0
            base_fire_damage_max = 0
            base_chaos_damage_min = 0
            base_attack_speed = 1.0
            base_critical_chance = 5.0
            if offhand_type != ItemEnums.OffhandType.SHIELD:
                base_block_chance_min = 0
                base_block_chance_max = 0
                base_block_amount_min = 0
                base_block_amount_max = 0
        ItemEnums.ItemCategory.CURRENCY:

            base_armour_min = 0
            base_armour_max = 0
            base_evasion_min = 0
            base_evasion_max = 0
            base_physical_damage_min = 0
            base_physical_damage_max = 0
            base_cold_damage_min = 0
            base_cold_damage_max = 0
            base_lightning_damage_min = 0
            base_lightning_damage_max = 0
            base_fire_damage_min = 0
            base_fire_damage_max = 0
            base_chaos_damage_min = 0
            base_chaos_damage_max = 0
            base_attack_speed = 1.0
            base_critical_chance = 0.0
            base_block_chance_min = 0
            base_block_chance_max = 0
            base_block_amount_min = 0
            base_block_amount_max = 0


func _validate_property(property: Dictionary) -> void :

    if property.name in ["armour_type", "jewellery_type", "offhand_type", "weapon_type", "hand_type"]:
        property.usage = PROPERTY_USAGE_NO_EDITOR


    match category:
        ItemEnums.ItemCategory.ARMOUR:
            if property.name == "armour_type":
                property.usage = PROPERTY_USAGE_DEFAULT
        ItemEnums.ItemCategory.JEWELLERY:
            if property.name == "jewellery_type":
                property.usage = PROPERTY_USAGE_DEFAULT
        ItemEnums.ItemCategory.OFFHAND:
            if property.name == "offhand_type":
                property.usage = PROPERTY_USAGE_DEFAULT
        ItemEnums.ItemCategory.WEAPON:
            if property.name in ["weapon_type", "hand_type"]:
                property.usage = PROPERTY_USAGE_DEFAULT
        ItemEnums.ItemCategory.RUCKSACK:
            pass


    if property.name == "equip_slot":
        property.usage = PROPERTY_USAGE_STORAGE


    match property.name:
        "base_physical_damage_min", "base_physical_damage_max", "base_attack_speed", "base_critical_chance", "base_attack_range", \
"base_fire_damage_min", "base_fire_damage_max", "base_cold_damage_min", "base_cold_damage_max", \
"base_lightning_damage_min", "base_lightning_damage_max", "base_chaos_damage_min", "base_chaos_damage_max":
            if category != ItemEnums.ItemCategory.WEAPON:
                property.usage = PROPERTY_USAGE_NO_EDITOR
        "base_armour_min", "base_armour_max", "base_evasion_min", "base_evasion_max":
            if category != ItemEnums.ItemCategory.ARMOUR:
                property.usage = PROPERTY_USAGE_NO_EDITOR
        "base_block_chance_min", "base_block_chance_max", "base_block_amount_min", "base_block_amount_max":
            if not (category == ItemEnums.ItemCategory.OFFHAND and offhand_type == ItemEnums.OffhandType.SHIELD):

                if not (category == ItemEnums.ItemCategory.ARMOUR and armour_type == ItemEnums.ArmourType.GLOVES):
                    property.usage = PROPERTY_USAGE_NO_EDITOR


func _set(property: StringName, value: Variant) -> bool:
    var old_value = get(property)

    match property:
        "category":
            if old_value != value:
                category = value
                _on_category_changed()

                set_meta("_dummy", randf())
            return true
        "armour_type", "jewellery_type", "offhand_type", "weapon_type", "hand_type":
            if old_value != value:
                set(property, value)
                _on_category_changed()
                set_meta("_dummy", randf())
            return true
    return false


func get_item_type() -> int:
    match category:
        ItemEnums.ItemCategory.ARMOUR:
            return armour_type
        ItemEnums.ItemCategory.JEWELLERY:
            return jewellery_type
        ItemEnums.ItemCategory.OFFHAND:
            return offhand_type
        ItemEnums.ItemCategory.WEAPON:
            return weapon_type
        ItemEnums.ItemCategory.RUCKSACK:
            return 0
        ItemEnums.ItemCategory.CURRENCY:
            return 0
        _:
            return -1


func get_type_name() -> String:
    match category:
        ItemEnums.ItemCategory.ARMOUR:
            return ["Boots", "Chest", "Helmet", "Gloves"][armour_type]
        ItemEnums.ItemCategory.JEWELLERY:
            return ["Ring", "Amulet", "Belt"][jewellery_type]
        ItemEnums.ItemCategory.OFFHAND:
            return ["Focus", "Sceptre", "Shield"][offhand_type]
        ItemEnums.ItemCategory.WEAPON:
            var weapon_name = ["Axe", "Bow", "Mace", "Spear", "Staff", "Sword", "Wand", "Dagger"][weapon_type]
            if hand_type == ItemEnums.HandType.TWO_HANDED:
                return "Two-Handed " + weapon_name
            return weapon_name
        ItemEnums.ItemCategory.RUCKSACK:
            return "Rucksack"
        ItemEnums.ItemCategory.CURRENCY:
            return "Currency"
        _:
            return "Unknown"

func get_equip_slot() -> ItemEnums.EquipSlot:
    match category:
        ItemEnums.ItemCategory.ARMOUR:
            match armour_type:
                ItemEnums.ArmourType.HELMET: return ItemEnums.EquipSlot.HELMET
                ItemEnums.ArmourType.CHEST: return ItemEnums.EquipSlot.CHEST
                ItemEnums.ArmourType.BOOTS: return ItemEnums.EquipSlot.BOOTS
                ItemEnums.ArmourType.GLOVES: return ItemEnums.EquipSlot.GLOVES
        ItemEnums.ItemCategory.JEWELLERY:
            match jewellery_type:
                ItemEnums.JewelleryType.RING: return ItemEnums.EquipSlot.RING_LEFT
                ItemEnums.JewelleryType.AMULET: return ItemEnums.EquipSlot.AMULET
                ItemEnums.JewelleryType.BELT: return ItemEnums.EquipSlot.BELT
        ItemEnums.ItemCategory.OFFHAND:
            return ItemEnums.EquipSlot.OFF_HAND
        ItemEnums.ItemCategory.RUCKSACK:
            return ItemEnums.EquipSlot.RUCKSACK
        ItemEnums.ItemCategory.WEAPON:
            if hand_type == ItemEnums.HandType.TWO_HANDED:
                return ItemEnums.EquipSlot.BOTH_HANDS
            return ItemEnums.EquipSlot.MAIN_HAND
    push_error("ItemBase.get_equip_slot: unhandled category on item: " + item_id)
    return ItemEnums.EquipSlot.MAIN_HAND


func can_drop_with_tags(active_tags: Array[String]) -> bool:

    if exclusive_tags.size() > 0:
        var has_exclusive = false
        for tag in exclusive_tags:
            if tag in active_tags:
                has_exclusive = true
                break
        return has_exclusive


    return true


func is_two_handed() -> bool:
    return category == ItemEnums.ItemCategory.WEAPON and hand_type == ItemEnums.HandType.TWO_HANDED
