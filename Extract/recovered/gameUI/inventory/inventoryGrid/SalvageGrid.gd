class_name SalvageGrid
extends LootGrid






















func _drop_data(at_position: Vector2, data: Variant) -> void :
    if not data is Item:
        return
    var item: Item = data





    if item.base_item and item.base_item.category == ItemEnums.ItemCategory.CURRENCY:
        return
    var grid_pos: Vector2i = _drop_highlight_pos
    if grid_pos == Vector2i(-1, -1):
        grid_pos = _pixel_to_grid_clamped(at_position, item)

    var current_pos: Vector2i = _get_item_position(item)
    if current_pos != Vector2i(-1, -1):

        _mark_rect(current_pos.x, current_pos.y, 
            item.base_item.grid_width, item.base_item.grid_height, false)
        _placed.erase(current_pos)
        for child in _item_layer.get_children():
            if child is ItemGridVisual and child.item == item:
                child.queue_free()
                break
        _place_item_at(item, grid_pos)
    elif GameState.guild_stash.has(item):

        GameState.remove_item_from_stash(item)
        item.stash_position = Vector2i(-1, -1)
        _place_item_at(item, grid_pos)
    else:

        return

    _drop_highlight_pos = Vector2i(-1, -1)
    queue_redraw()
    items_changed.emit()





func receive_from_stash(item: Item) -> bool:
    if item == null or not GameState.guild_stash.has(item):
        return false


    if item.base_item and item.base_item.category == ItemEnums.ItemCategory.CURRENCY:
        return false
    var pos: Vector2i = _find_free_position(
        item.base_item.grid_width, item.base_item.grid_height
    )
    if pos == Vector2i(-1, -1):
        return false
    GameState.remove_item_from_stash(item)
    item.stash_position = Vector2i(-1, -1)
    _place_item_at(item, pos)
    items_changed.emit()
    return true
