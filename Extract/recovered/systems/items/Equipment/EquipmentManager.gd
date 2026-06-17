


extends Node


signal equipment_changed(exile: ExileData)




signal equip_rejected_no_space(exile: ExileData, slot: ItemEnums.EquipSlot)









func equip_item(exile: ExileData, item: Item) -> bool:
    if exile == null or item == null or item.base_item == null:
        push_error("EquipmentManager.equip_item: received null exile or item")
        return false





    if item.base_item.category == ItemEnums.ItemCategory.CURRENCY:
        push_warning("EquipmentManager.equip_item: refusing to equip currency item " + item.base_item.item_id)
        return false


    if not GameState.guild_stash.has(item):
        push_warning("EquipmentManager.equip_item: item is not in the guild stash")
        return false

    var slot: ItemEnums.EquipSlot = item.base_item.get_equip_slot()


    if slot == ItemEnums.EquipSlot.BOTH_HANDS:
        slot = ItemEnums.EquipSlot.MAIN_HAND

    return _commit_equip(exile, item, slot)




func equip_item_to_slot(exile: ExileData, item: Item, slot: ItemEnums.EquipSlot) -> bool:
    if exile == null or item == null or item.base_item == null:
        push_error("EquipmentManager.equip_item_to_slot: received null exile or item")
        return false


    if item.base_item.category == ItemEnums.ItemCategory.CURRENCY:
        push_warning("EquipmentManager.equip_item_to_slot: refusing to equip currency item " + item.base_item.item_id)
        return false
    if not GameState.guild_stash.has(item):
        push_warning("EquipmentManager.equip_item_to_slot: item is not in the guild stash")
        return false

    return _commit_equip(exile, item, slot)







func unequip_item(exile: ExileData, slot: ItemEnums.EquipSlot) -> bool:
    if not exile.has_item_in_slot(slot):
        return false

    var slot_key: String = ItemEnums.EquipSlot.keys()[slot]
    var item: Item = exile.equipped_items[slot_key]

    exile.equipped_items.erase(slot_key)
    GameState.add_item_to_stash(item)

    _recalculate_stats(exile)
    equipment_changed.emit(exile)
    return true






func unequip_all(exile: ExileData) -> void :

    var slots_to_clear: Array = exile.equipped_items.keys().duplicate()
    for slot_key in slots_to_clear:
        var item: Item = exile.equipped_items[slot_key]
        exile.equipped_items.erase(slot_key)
        GameState.add_item_to_stash(item)

    _recalculate_stats(exile)
    equipment_changed.emit(exile)








func _commit_equip(exile: ExileData, item: Item, slot: ItemEnums.EquipSlot) -> bool:
    var displaced: Array[Item] = _collect_displacement_targets(exile, item, slot)

    var placements: Array = []
    if not displaced.is_empty():
        placements = _plan_displaced_placements(displaced, item)
        if placements.is_empty():
            push_warning(
                "EquipmentManager: no stash space for displaced item(s) — equip of '%s' aborted"
                %item.get_display_name()
            )
            equip_rejected_no_space.emit(exile, slot)
            return false






    GameState.remove_item_from_stash(item)

    if not displaced.is_empty():
        _apply_displacements(exile, displaced, placements)



    _clear_both_hands_ghost(exile)

    var slot_key: String = ItemEnums.EquipSlot.keys()[slot]
    exile.equipped_items[slot_key] = item

    _recalculate_stats(exile)
    equipment_changed.emit(exile)
    return true








func _collect_displacement_targets(
    exile: ExileData, item: Item, target_slot: ItemEnums.EquipSlot
) -> Array[Item]:
    var displaced: Array[Item] = []
    var is_two_handed: bool = item.base_item.is_two_handed()


    if is_two_handed:
        var off_hand_item: Item = _get_equipped_in_slot(exile, ItemEnums.EquipSlot.OFF_HAND)
        if off_hand_item != null:
            displaced.append(off_hand_item)


    if target_slot == ItemEnums.EquipSlot.OFF_HAND:
        var main_item: Item = _get_equipped_in_slot(exile, ItemEnums.EquipSlot.MAIN_HAND)
        if main_item != null and main_item.base_item.is_two_handed():
            displaced.append(main_item)



    var occupant: Item = _get_equipped_in_slot(exile, target_slot)
    if occupant != null and not displaced.has(occupant):
        displaced.append(occupant)





    var both_hands_item: Item = _get_equipped_in_slot(exile, ItemEnums.EquipSlot.BOTH_HANDS)
    if both_hands_item != null and not displaced.has(both_hands_item):
        displaced.append(both_hands_item)

    return displaced






func _plan_displaced_placements(displaced: Array[Item], ignore_item: Item) -> Array:
    var placements: Array = []
    var virtual_planned: Array = []
    for disp in displaced:
        var slot_info: Dictionary = GameState.find_free_stash_slot(
            disp, ignore_item, virtual_planned
        )
        if slot_info.is_empty():
            return []


        var planned_tab: int = int(slot_info["tab"])
        var planned_pos: Vector2i = slot_info["position"]
        placements.append(slot_info)
        virtual_planned.append({
            "item": disp, 
            "tab": planned_tab, 
            "position": planned_pos, 
        })
    return placements





func _apply_displacements(
    exile: ExileData, displaced: Array[Item], placements: Array
) -> void :
    for i in range(displaced.size()):
        var disp_item: Item = displaced[i]
        var placement: Dictionary = placements[i]


        var new_tab: int = int(placement["tab"])
        var new_pos: Vector2i = placement["position"]
        disp_item.stash_tab = new_tab
        disp_item.stash_position = new_pos
        _erase_item_from_exile_slots(exile, disp_item)
        GameState.add_item_to_stash(disp_item)




func _get_equipped_in_slot(exile: ExileData, slot: ItemEnums.EquipSlot) -> Item:
    var key: String = ItemEnums.EquipSlot.keys()[slot]
    if not exile.equipped_items.has(key):
        return null
    return exile.equipped_items[key]




func _erase_item_from_exile_slots(exile: ExileData, item: Item) -> void :
    for slot_key in exile.equipped_items.keys():
        if exile.equipped_items[slot_key] == item:
            exile.equipped_items.erase(slot_key)
            return




func _clear_both_hands_ghost(exile: ExileData) -> void :
    var key: String = ItemEnums.EquipSlot.keys()[ItemEnums.EquipSlot.BOTH_HANDS]
    if exile.equipped_items.has(key) and exile.equipped_items[key] == null:
        exile.equipped_items.erase(key)









func _recalculate_stats(exile: ExileData) -> void :
    ExileGenerator.recalculate_stats(exile)
    GameState.exile_updated.emit(exile)
