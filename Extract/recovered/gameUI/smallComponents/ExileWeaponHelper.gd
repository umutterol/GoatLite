class_name ExileWeaponHelper
extends RefCounted






static func get_main_weapon(exile: ExileData) -> Item:
    if exile == null:
        return null
    var w: Item = exile.get_equipped_item(ItemEnums.EquipSlot.MAIN_HAND)
    if w == null:
        w = exile.get_equipped_item(ItemEnums.EquipSlot.BOTH_HANDS)
    return w
