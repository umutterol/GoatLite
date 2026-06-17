class_name LootGrid
extends StashGrid









signal items_changed


@export var partner_grid: LootGrid = null





func _ready() -> void :
    stash_config = null
    super._ready()




func _drop_data(at_position: Vector2, data: Variant) -> void :
    if not data is Item:
        return
    var item: Item = data
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
    elif partner_grid != null and partner_grid.has_item(item):

        partner_grid.remove_item(item)
        _place_item_at(item, grid_pos)
        partner_grid.items_changed.emit()
    else:

        return

    _drop_highlight_pos = Vector2i(-1, -1)
    queue_redraw()
    items_changed.emit()






func has_item(item: Item) -> bool:
    return _get_item_position(item) != Vector2i(-1, -1)


func get_items() -> Array[Item]:
    var result: Array[Item] = []
    for pos in _placed:
        result.append(_placed[pos])
    return result




func take_all() -> Array[Item]:
    var snapshot: Array[Item] = get_items()
    for item in snapshot:
        remove_item(item)
    items_changed.emit()
    return snapshot




func receive_all_from(source: LootGrid) -> void :
    var incoming: Array[Item] = source.take_all()
    for item in incoming:


        item.stash_position = Vector2i(-1, -1)
        add_item(item)
    items_changed.emit()




func quick_move_to_partner(item: Item) -> void :
    if partner_grid == null or not has_item(item):
        return
    remove_item(item)
    item.stash_position = Vector2i(-1, -1)
    if not partner_grid.add_item(item):

        add_item(item)
        return
    items_changed.emit()
    partner_grid.items_changed.emit()
