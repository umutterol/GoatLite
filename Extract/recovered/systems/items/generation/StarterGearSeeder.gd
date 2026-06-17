







class_name StarterGearSeeder
extends RefCounted



const STARTER_BASES: Dictionary = {
    "ranger": "res://systems/items/itemBases/weapon/bow/sapling_bow.tres", 
    "warrior": "res://systems/items/itemBases/weapon/axe/2h/rusty_cleaver.tres", 
    "witch": "res://systems/items/itemBases/weapon/wand/ash_twigwand.tres", 
    "duelist": "res://systems/items/itemBases/weapon/sword/1h/scrap_short_sword.tres", 
    "templar": "res://systems/items/itemBases/weapon/staff/2h/driftwood_staff.tres", 
    "twisted": "res://systems/items/itemBases/offhand/shield/cooking_pot_lid.tres", 
    "ascendant": "res://systems/items/itemBases/weapon/dagger/glass_shank.tres", 
}
const FALLBACK_BASE_PATH: String = "res://systems/items/itemBases/weapon/spear/1h/stickspear.tres"




static func seed_for_exiles(exiles: Array[ExileData]) -> void :
    if exiles.is_empty():
        return




    var generator: ItemGenerator = ItemGenerator.new()

    for exile in exiles:
        if exile == null:
            continue
        _seed_for_exile(exile, generator)


static func _seed_for_exile(exile: ExileData, generator: ItemGenerator) -> void :
    var base_path: String = STARTER_BASES.get(exile.class_id, FALLBACK_BASE_PATH)
    var item_base: ItemBase = load(base_path) as ItemBase
    if item_base == null:
        push_error("StarterGearSeeder: failed to load ItemBase at %s for class '%s'"
            %[base_path, exile.class_id])
        return

    var item: Item = generator.generate_item_with_rarity(1, Item.Rarity.COMMON, item_base)
    if item == null:
        push_error("StarterGearSeeder: failed to generate starter item for %s (%s)"
            %[exile.name, exile.class_id])
        return





    _place_in_stash(item)



    EquipmentManager.equip_item(exile, item)





static func _place_in_stash(item: Item) -> void :
    item.stash_position = Vector2i(-1, -1)
    item.stash_tab = 0
    var slot: Dictionary = GameState.find_free_stash_slot(item)
    if slot.is_empty():
        push_warning("StarterGearSeeder: no free stash slot for '%s' at game start"
            %item.get_display_name())
        GameState.add_item_to_stash(item)
        return
    item.stash_tab = int(slot.get("tab", 0))
    item.stash_position = slot.get("position", Vector2i(-1, -1))
    GameState.add_item_to_stash(item)
