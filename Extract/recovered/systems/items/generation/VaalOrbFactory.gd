class_name VaalOrbFactory
extends RefCounted














const VAAL_ORB_BASE: ItemBase = preload("res://systems/items/itemBases/currency/vaal_orb.tres")





static func make() -> Item:
    var item: = Item.new(VAAL_ORB_BASE, 1)
    item.rarity = Item.Rarity.COMMON
    return item
