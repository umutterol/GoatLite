


class_name ItemGridVisual
extends Control

signal item_clicked(item: Item)
signal item_right_clicked(item: Item)




const RARITY_COLORS: Dictionary = {
    Item.Rarity.COMMON: Color(0.15, 0.17, 0.2, 0.2), 
    Item.Rarity.UNCOMMON: Color(0.08, 0.35, 0.6, 0.2), 
    Item.Rarity.RARE: Color(0.5, 0.42, 0.05, 0.2), 
}
const HOVER_TINT: Color = Color(1.0, 1.0, 1.0, 0.12)



const ITEM_BG_INSET: int = 1

var item: Item = null
var _cell_size: int = 50
var _is_hovering: bool = false
var _bg: ColorRect
var _label: Label

func setup(p_item: Item, grid_pos: Vector2i, cell_size: int) -> void :
    item = p_item
    _cell_size = cell_size

    var px_w = item.base_item.grid_width * cell_size
    var px_h = item.base_item.grid_height * cell_size
    position = Vector2(grid_pos.x * cell_size, grid_pos.y * cell_size)
    size = Vector2(px_w, px_h)
    mouse_filter = Control.MOUSE_FILTER_STOP




    var rarity_color: Color = RARITY_COLORS.get(item.rarity, RARITY_COLORS[Item.Rarity.COMMON])
    _bg = ColorRect.new()
    _bg.anchor_right = 1.0
    _bg.anchor_bottom = 1.0
    _bg.offset_left = ITEM_BG_INSET
    _bg.offset_top = ITEM_BG_INSET
    _bg.offset_right = - ITEM_BG_INSET
    _bg.offset_bottom = - ITEM_BG_INSET
    _bg.color = rarity_color
    _bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_bg)

    if item.base_item.icon != null:
        var icon = TextureRect.new()
        icon.texture = item.base_item.icon
        icon.anchor_right = 1.0
        icon.anchor_bottom = 1.0
        icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(icon)
    else:
        _label = Label.new()
        _label.anchor_right = 1.0
        _label.anchor_bottom = 1.0
        _label.text = item.get_display_name()
        _label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        _label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        _label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        _label.add_theme_font_size_override("font_size", 10)
        _label.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(_label)

func _draw() -> void :

    if _is_hovering:
        draw_rect(Rect2(Vector2.ZERO, size), HOVER_TINT)



func _get_drag_data(_at_position: Vector2) -> Variant:
    set_drag_preview(_make_drag_preview())
    return item

func _make_drag_preview() -> Control:
    var preview = ColorRect.new()
    preview.size = size
    preview.color = RARITY_COLORS.get(item.rarity, RARITY_COLORS[Item.Rarity.COMMON])
    preview.modulate.a = 0.75

    if item.base_item.icon != null:
        var tex = TextureRect.new()
        tex.texture = item.base_item.icon
        tex.anchor_right = 1.0
        tex.anchor_bottom = 1.0
        tex.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
        tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
        preview.add_child(tex)
    else:
        var lbl = Label.new()
        lbl.anchor_right = 1.0
        lbl.anchor_bottom = 1.0
        lbl.text = item.get_display_name()
        lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        lbl.add_theme_font_size_override("font_size", 10)
        preview.add_child(lbl)

    return preview

func _gui_input(event: InputEvent) -> void :
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            item_clicked.emit(item)
            get_viewport().set_input_as_handled()
        elif event.button_index == MOUSE_BUTTON_RIGHT:
            item_right_clicked.emit(item)
            get_viewport().set_input_as_handled()
    elif event is InputEventMouseMotion:
        if not _is_hovering:
            _is_hovering = true
            queue_redraw()
            ItemTooltip.show_for(item, get_global_rect())

func _notification(what: int) -> void :
    if what == NOTIFICATION_MOUSE_EXIT:
        _is_hovering = false
        queue_redraw()
        ItemTooltip.hide_floating()
