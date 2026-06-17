



class_name StashGrid
extends Control

signal item_clicked(item: Item)
signal item_tab_changed(item: Item)
signal equipped_item_dropped(item: Item)
signal item_right_clicked(item: Item)






@export var stash_config: StashConfig = preload("res://systems/items/Equipment/stash_config.tres")



@export var cell_size: int = 50
@export var columns: int = 12
@export var rows: int = 8
const COLOR_CELL_BG: Color = Color(0.08, 0.08, 0.1, 1.0)
const COLOR_GRID_LINE: Color = Color(0.2, 0.2, 0.23, 1.0)


const COLOR_DROP_VALID: Color = Color(0.1, 0.85, 0.2, 0.5)
const COLOR_DROP_INVALID: Color = Color(0.9, 0.15, 0.1, 0.3)


var tab_index: int = 0


var _placed: Dictionary = {}
var _occupied: Array = []
var _item_layer: Control = null


var _drop_highlight_pos: Vector2i = Vector2i(-1, -1)
var _drop_highlight_size: Vector2i = Vector2i.ONE
var _drop_valid: bool = false

func _ready() -> void :


    if stash_config != null:
        columns = stash_config.columns
        rows = stash_config.rows
        cell_size = stash_config.cell_size_px
    custom_minimum_size = Vector2(columns * cell_size, rows * cell_size)
    size = custom_minimum_size
    _item_layer = Control.new()
    _item_layer.name = "ItemLayer"
    _item_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _item_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(_item_layer)
    _reset_occupied()

func _draw() -> void :

    for col in range(columns):
        for row in range(rows):
            var rect = Rect2(col * cell_size, row * cell_size, cell_size, cell_size)
            draw_rect(rect, COLOR_CELL_BG)
            draw_rect(rect, COLOR_GRID_LINE, false)

    if _drop_highlight_pos != Vector2i(-1, -1):
        var hl = Rect2(
            _drop_highlight_pos.x * cell_size, 
            _drop_highlight_pos.y * cell_size, 
            _drop_highlight_size.x * cell_size, 
            _drop_highlight_size.y * cell_size
        )
        var col = COLOR_DROP_VALID if _drop_valid else COLOR_DROP_INVALID
        draw_rect(hl, col)
        draw_rect(hl, col.lightened(0.4), false, 2.0)

func _notification(what: int) -> void :

    if what == NOTIFICATION_DRAG_END:
        _drop_highlight_pos = Vector2i(-1, -1)
        queue_redraw()



func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
    if not data is Item:
        return false
    var item: Item = data
    var grid_pos = _pixel_to_grid_clamped(at_position, item)


    var current_pos = _get_item_position(item)
    if current_pos != Vector2i(-1, -1):
        _mark_rect(current_pos.x, current_pos.y, 
            item.base_item.grid_width, item.base_item.grid_height, false)

    _drop_valid = _is_rect_free(grid_pos.x, grid_pos.y, 
        item.base_item.grid_width, item.base_item.grid_height)


    if current_pos != Vector2i(-1, -1):
        _mark_rect(current_pos.x, current_pos.y, 
            item.base_item.grid_width, item.base_item.grid_height, true)

    _drop_highlight_pos = grid_pos
    _drop_highlight_size = Vector2i(item.base_item.grid_width, item.base_item.grid_height)
    queue_redraw()
    return _drop_valid

func _drop_data(at_position: Vector2, data: Variant) -> void :
    if not data is Item:
        return
    var item: Item = data
    var grid_pos = _drop_highlight_pos
    if grid_pos == Vector2i(-1, -1):
        grid_pos = _pixel_to_grid_clamped(at_position, item)

    var current_pos = _get_item_position(item)

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

        item.stash_tab = tab_index
        item.stash_position = grid_pos
        item_tab_changed.emit(item)
    else:

        item.stash_tab = tab_index
        item.stash_position = grid_pos
        equipped_item_dropped.emit(item)

    _drop_highlight_pos = Vector2i(-1, -1)
    queue_redraw()



func populate(items: Array[Item]) -> void :
    _clear_visuals()
    _reset_occupied()
    _placed.clear()
    for item in items:
        var pos: Vector2i
        if item.stash_position != Vector2i(-1, -1):

            pos = item.stash_position

            if not _is_rect_free(pos.x, pos.y, item.base_item.grid_width, item.base_item.grid_height):
                push_warning("StashGrid: saved position blocked for '%s', auto-placing" % item.get_display_name())
                pos = _find_free_position(item.base_item.grid_width, item.base_item.grid_height)
        else:

            pos = _find_free_position(item.base_item.grid_width, item.base_item.grid_height)
        if pos == Vector2i(-1, -1):
            push_warning("StashGrid: no room for '%s'" % item.get_display_name())
            continue
        _place_item_at(item, pos)

func add_item(item: Item) -> bool:
    var pos = _find_free_position(item.base_item.grid_width, item.base_item.grid_height)
    if pos == Vector2i(-1, -1):
        return false
    _place_item_at(item, pos)
    return true

func remove_item(item: Item) -> void :
    var target_pos = _get_item_position(item)
    if target_pos == Vector2i(-1, -1):
        return
    _mark_rect(target_pos.x, target_pos.y, 
        item.base_item.grid_width, item.base_item.grid_height, false)
    _placed.erase(target_pos)
    for child in _item_layer.get_children():
        if child is ItemGridVisual and child.item == item:
            child.queue_free()
            return






func sort_tab() -> void :
    var items: Array[Item] = []
    for pos in _placed:
        items.append(_placed[pos])
    items.sort_custom(_sort_comparator)
    for item in items:
        item.stash_position = Vector2i(-1, -1)
    populate(items)

func _sort_comparator(a: Item, b: Item) -> bool:

    var area_a: int = a.base_item.grid_width * a.base_item.grid_height
    var area_b: int = b.base_item.grid_width * b.base_item.grid_height
    if area_a != area_b:
        return area_a > area_b
    if a.base_item.category != b.base_item.category:
        return a.base_item.category < b.base_item.category
    if a.rarity != b.rarity:
        return a.rarity > b.rarity
    return a.base_item.display_name < b.base_item.display_name



func _reset_occupied() -> void :
    _occupied = []
    for _col in range(columns):
        var col_arr: Array = []
        for _row in range(rows):
            col_arr.append(false)
        _occupied.append(col_arr)

func _find_free_position(w: int, h: int) -> Vector2i:
    for row in range(rows - h + 1):
        for col in range(columns - w + 1):
            if _is_rect_free(col, row, w, h):
                return Vector2i(col, row)
    return Vector2i(-1, -1)

func _is_rect_free(col: int, row: int, w: int, h: int) -> bool:



    if col < 0 or row < 0 or col + w > columns or row + h > rows:
        return false
    for dc in range(w):
        for dr in range(h):
            if _occupied[col + dc][row + dr]:
                return false
    return true

func _mark_rect(col: int, row: int, w: int, h: int, value: bool) -> void :
    for dc in range(w):
        for dr in range(h):
            _occupied[col + dc][row + dr] = value

func _place_item_at(item: Item, grid_pos: Vector2i) -> void :
    _mark_rect(grid_pos.x, grid_pos.y, 
        item.base_item.grid_width, item.base_item.grid_height, true)
    _placed[grid_pos] = item
    item.stash_position = grid_pos
    var visual = ItemGridVisual.new()
    visual.setup(item, grid_pos, cell_size)
    visual.item_clicked.connect(_on_item_clicked)
    visual.item_right_clicked.connect(_on_item_right_clicked)
    _item_layer.add_child(visual)

func _clear_visuals() -> void :
    for child in _item_layer.get_children():
        child.queue_free()

func _get_item_position(item: Item) -> Vector2i:
    for pos in _placed:
        if _placed[pos] == item:
            return pos
    return Vector2i(-1, -1)

func _pixel_to_grid_clamped(local_pos: Vector2, item: Item) -> Vector2i:
    var col = int(local_pos.x / cell_size)
    var row = int(local_pos.y / cell_size)
    col = clampi(col, 0, columns - item.base_item.grid_width)
    row = clampi(row, 0, rows - item.base_item.grid_height)
    return Vector2i(col, row)

func _on_item_clicked(item: Item) -> void :
    item_clicked.emit(item)

func _on_item_right_clicked(item: Item) -> void :
    item_right_clicked.emit(item)
