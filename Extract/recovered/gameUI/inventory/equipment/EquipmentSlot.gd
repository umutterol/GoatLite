







@tool
class_name EquipmentSlot
extends Control

signal item_equip_requested(item: Item, slot: ItemEnums.EquipSlot)
signal item_unequip_requested(slot: ItemEnums.EquipSlot)

const COLOR_EMPTY_BG: Color = Color(0.113, 0.098, 0.097, 1.0)
const COLOR_EMPTY_BORDER: Color = Color(0.392, 0.344, 0.324, 1.0)


const COLOR_FILLED_BG: Color = Color(0.15, 0.17, 0.2, 0.5)
const COLOR_HOVER_TINT: Color = Color(1.0, 1.0, 1.0, 0.1)
const COLOR_DROP_VALID: Color = Color(0.102, 0.851, 0.2, 0.345)
const COLOR_DROP_INVALID: Color = Color(0.9, 0.15, 0.1, 0.3)
const LABEL_COLOR: Color = Color(0.241, 0.222, 0.217, 1.0)
const LABEL_FONT_SIZE: int = 12
const FALLBACK_MIN_SIZE: Vector2 = Vector2(90, 90)



const TWOH_GHOST_MODULATE: Color = Color(0.55, 0.55, 0.6, 0.45)


const FLASH_COLOR: Color = Color(1.8, 0.55, 0.55, 1.0)
const FLASH_RAMP_SECONDS: float = 0.08
const FLASH_FADE_SECONDS: float = 0.4




@export var slot_type: ItemEnums.EquipSlot = ItemEnums.EquipSlot.MAIN_HAND:
    set(value):
        slot_type = value
        queue_redraw()

var exile: ExileData = null
var _equipped: Item = null
var _is_hovering: bool = false
var _drop_state: int = 0


var _blocked_by_2h: bool = false


var _item_label: Label
var _item_icon: TextureRect


func _ready() -> void :



    if custom_minimum_size == Vector2.ZERO:
        custom_minimum_size = FALLBACK_MIN_SIZE
    queue_redraw()




    if Engine.is_editor_hint():
        return


    _item_label = Label.new()
    _item_label.anchor_right = 1.0
    _item_label.anchor_bottom = 1.0
    _item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _item_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _item_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _item_label.add_theme_font_size_override("font_size", 9)
    _item_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _item_label.visible = false
    add_child(_item_label)


    _item_icon = TextureRect.new()
    _item_icon.anchor_right = 1.0
    _item_icon.anchor_bottom = 1.0
    _item_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    _item_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _item_icon.visible = false
    add_child(_item_icon)






func _draw() -> void :
    var rect: = Rect2(Vector2.ZERO, size)

    draw_rect(rect, COLOR_EMPTY_BG)
    if _equipped != null:
        var inset_rect: = Rect2(
            ItemGridVisual.ITEM_BG_INSET, 
            ItemGridVisual.ITEM_BG_INSET, 
            size.x - ItemGridVisual.ITEM_BG_INSET * 2, 
            size.y - ItemGridVisual.ITEM_BG_INSET * 2, 
        )
        draw_rect(inset_rect, _get_rarity_color(_equipped))

    var border_color: = COLOR_EMPTY_BORDER
    if _drop_state == 1:
        draw_rect(rect, COLOR_DROP_VALID)
        border_color = COLOR_DROP_VALID.lightened(0.4)
    elif _drop_state == 2:
        draw_rect(rect, COLOR_DROP_INVALID)
        border_color = COLOR_DROP_INVALID.lightened(0.4)
    elif _is_hovering and _equipped != null:
        draw_rect(rect, COLOR_HOVER_TINT)
    draw_rect(rect, border_color, false, 1.5)




    if _equipped == null and not _blocked_by_2h:
        var font: = get_theme_default_font()
        if font == null:
            return
        var text: = _get_slot_abbreviation()
        var text_size: = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, LABEL_FONT_SIZE)
        var ascent: = font.get_ascent(LABEL_FONT_SIZE)
        var descent: = font.get_descent(LABEL_FONT_SIZE)
        var text_pos: = Vector2(
            (size.x - text_size.x) * 0.5, 
            (size.y + ascent - descent) * 0.5, 
        )
        draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, LABEL_FONT_SIZE, LABEL_COLOR)




func set_exile(p_exile: ExileData) -> void :
    if Engine.is_editor_hint():
        return
    exile = p_exile
    refresh()





func flash_reject() -> void :
    if Engine.is_editor_hint():
        return
    var flash_tween: Tween = create_tween()
    flash_tween.tween_property(self, "modulate", FLASH_COLOR, FLASH_RAMP_SECONDS)
    flash_tween.tween_property(self, "modulate", Color.WHITE, FLASH_FADE_SECONDS)


func refresh() -> void :
    if Engine.is_editor_hint() or exile == null or _item_label == null:
        return
    _equipped = exile.get_equipped_item(slot_type)
    _blocked_by_2h = _check_blocked_by_2h()

    _item_icon.modulate = Color.WHITE
    if _equipped != null:
        if _equipped.base_item.icon != null:
            _item_icon.texture = _equipped.base_item.icon
            _item_icon.visible = true
            _item_label.visible = false
        else:
            _item_icon.visible = false
            _item_label.text = _equipped.get_display_name()
            _item_label.visible = true
    elif _blocked_by_2h:



        var main_hand: Item = exile.get_equipped_item(ItemEnums.EquipSlot.MAIN_HAND)
        if main_hand and main_hand.base_item and main_hand.base_item.icon != null:
            _item_icon.texture = main_hand.base_item.icon
            _item_icon.modulate = TWOH_GHOST_MODULATE
            _item_icon.visible = true
            _item_label.visible = false
        else:
            _item_icon.visible = false
            _item_label.visible = false
    else:
        _item_label.visible = false
        _item_icon.visible = false
    queue_redraw()




func _check_blocked_by_2h() -> bool:
    if slot_type != ItemEnums.EquipSlot.OFF_HAND or exile == null:
        return false
    var main_hand: Item = exile.get_equipped_item(ItemEnums.EquipSlot.MAIN_HAND)
    if main_hand == null or main_hand.base_item == null:
        return false
    return main_hand.base_item.get_equip_slot() == ItemEnums.EquipSlot.BOTH_HANDS




func _get_drag_data(_at_position: Vector2) -> Variant:
    if Engine.is_editor_hint() or _equipped == null:
        return null
    set_drag_preview(_make_drag_preview(_equipped))
    return _equipped


func _make_drag_preview(item: Item) -> Control:
    var preview = ColorRect.new()
    preview.size = Vector2(
        item.base_item.grid_width * 50, 
        item.base_item.grid_height * 50
    )
    preview.color = Color(0.15, 0.17, 0.2, 0.75)

    if item.base_item.icon != null:
        var tex = TextureRect.new()
        tex.texture = item.base_item.icon
        tex.anchor_right = 1.0
        tex.anchor_bottom = 1.0
        tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
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




func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
    if Engine.is_editor_hint():
        return false
    if not data is Item or exile == null:
        _drop_state = 0
        queue_redraw()
        return false
    var item: Item = data
    var valid = _is_valid_for_slot(item)




    if valid and _equipped != null and _is_from_bench(item):
        valid = false
    _drop_state = 1 if valid else 2
    queue_redraw()
    return valid







func _is_from_bench(item: Item) -> bool:
    if GameState.guild_stash.has(item):
        return false
    if exile == null:
        return false
    for slot_key in exile.equipped_items:
        if exile.equipped_items[slot_key] == item:
            return false
    return true


func _drop_data(_at_position: Vector2, data: Variant) -> void :
    if Engine.is_editor_hint():
        return
    if not data is Item or exile == null:
        return
    _drop_state = 0


    item_equip_requested.emit(data as Item, slot_type)
    queue_redraw()


func _notification(what: int) -> void :
    if Engine.is_editor_hint():
        return
    if what == NOTIFICATION_MOUSE_ENTER:
        _mouse_enter()
    elif what == NOTIFICATION_MOUSE_EXIT:
        _mouse_exit()
    elif what == NOTIFICATION_DRAG_END:
        _drop_state = 0
        if exile != null:
            refresh()
        queue_redraw()


func _process(_delta: float) -> void :
    if Engine.is_editor_hint() or _drop_state == 0:
        return
    if not get_viewport().gui_is_dragging():

        _drop_state = 0
        queue_redraw()
        return

    if not get_global_rect().has_point(get_viewport().get_mouse_position()):
        _drop_state = 0
        queue_redraw()




func _gui_input(event: InputEvent) -> void :
    if Engine.is_editor_hint():
        return
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_RIGHT and _equipped != null:
            item_unequip_requested.emit(slot_type)


func _mouse_enter() -> void :
    _is_hovering = true
    queue_redraw()
    if _equipped != null:


        ItemTooltip.show_for(_equipped, get_global_rect(), false)


func _mouse_exit() -> void :
    _is_hovering = false
    _drop_state = 0
    queue_redraw()
    ItemTooltip.hide_floating()




func _is_valid_for_slot(item: Item) -> bool:




    if _blocked_by_2h:
        return false




    if item.base_item == null or item.base_item.category == ItemEnums.ItemCategory.CURRENCY:
        return false
    var item_slot = item.base_item.get_equip_slot()

    if item_slot == slot_type:
        return true

    if item_slot == ItemEnums.EquipSlot.RING_LEFT and slot_type == ItemEnums.EquipSlot.RING_RIGHT:
        return true
    if item_slot == ItemEnums.EquipSlot.RING_LEFT and slot_type == ItemEnums.EquipSlot.RING_LEFT:
        return true

    if item_slot == ItemEnums.EquipSlot.BOTH_HANDS and slot_type == ItemEnums.EquipSlot.MAIN_HAND:
        return true
    return false


func _get_slot_abbreviation() -> String:
    match slot_type:
        ItemEnums.EquipSlot.HELMET: return "Head"
        ItemEnums.EquipSlot.CHEST: return "Body"
        ItemEnums.EquipSlot.GLOVES: return "Gloves"
        ItemEnums.EquipSlot.BOOTS: return "Boots"
        ItemEnums.EquipSlot.MAIN_HAND: return "Weapon"
        ItemEnums.EquipSlot.OFF_HAND: return "Shield"
        ItemEnums.EquipSlot.AMULET: return "Amulet"
        ItemEnums.EquipSlot.RING_LEFT: return "Ring"
        ItemEnums.EquipSlot.RING_RIGHT: return "Ring"
        ItemEnums.EquipSlot.BELT: return "Belt"
        _: return "?"


func _get_rarity_color(item: Item) -> Color:



    return ItemGridVisual.RARITY_COLORS.get(
        item.rarity, 
        ItemGridVisual.RARITY_COLORS[Item.Rarity.COMMON], 
    )
