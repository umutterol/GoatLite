



extends Node

const TOOLTIP_SCENE = preload("res://gameUI/inventory/itemDetails/itemLabel/ItemLabel.tscn")



const COMPARISON_HEADER_SCENE = preload("res://gameUI/inventory/itemDetails/itemLabel/CurrentlyEquippedHeader.tscn")


const CLOSE_X_ICON = preload("res://assets/sprites/uiSprites/CloseXIcon.tres")
const OFFSET_X: int = 8
const PIN_BAR_H: int = 28


const COMPARISON_GAP_X: int = 8


const COMPARISON_HEADER_GAP_Y: int = 4





const FLOATING_FONT_SCALE: float = 1.5

var _floating: ItemLabel = null
var _source_rect: Rect2 = Rect2()
var _current_item: Item = null
var _pinned: Array = []
var _canvas_layer: CanvasLayer = null
var _layout_frames: int = 0






var _comparison_exile: ExileData = null



var _comparison_label: ItemLabel = null
var _comparison_header: Control = null
var _with_comparison: bool = true
var _last_alt_held: bool = false

func _ready() -> void :

    _canvas_layer = CanvasLayer.new()
    _canvas_layer.name = "ItemTooltipLayer"
    _canvas_layer.layer = 200
    get_tree().root.call_deferred("add_child", _canvas_layer)

    _floating = TOOLTIP_SCENE.instantiate()
    _floating.name = "FloatingTooltip"
    _floating.visible = false
    _floating.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _canvas_layer.call_deferred("add_child", _floating)





    SceneRouter.scene_about_to_change.connect(_on_scene_about_to_change)

    set_process(false)


func _on_scene_about_to_change() -> void :
    hide_floating()



func _unhandled_input(event: InputEvent) -> void :
    if event is InputEventKey and event.pressed and not event.echo:
        if event.physical_keycode == KEY_T and _floating.visible and _current_item != null:
            _pin_current()
            get_viewport().set_input_as_handled()







func show_for(item: Item, source_global_rect: Rect2, with_comparison: bool = true) -> void :
    _current_item = item
    _source_rect = source_global_rect
    _with_comparison = with_comparison
    _last_alt_held = Input.is_key_pressed(KEY_ALT)


    if _floating:
        _floating.queue_free()

    _floating = TOOLTIP_SCENE.instantiate()
    _floating.name = "FloatingTooltip"
    _floating.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _canvas_layer.add_child(_floating)
    _floating.populate(item)
    _floating.set_font_scale(FLOATING_FONT_SCALE)
    _floating.visible = false


    _clear_comparison_panels()
    if _with_comparison and _comparison_exile != null and item != null:
        var equipped: Item = _resolve_comparison_item(item, _last_alt_held)
        if equipped != null:
            _build_comparison_panels(equipped)

    _layout_frames = 2
    set_process(true)




func set_comparison_context(p_exile: ExileData) -> void :
    _comparison_exile = p_exile


func clear_comparison_context() -> void :
    _comparison_exile = null
    _clear_comparison_panels()


func hide_floating() -> void :
    _floating.visible = false
    _current_item = null
    _layout_frames = 0
    _clear_comparison_panels()
    set_process(false)

func _process(_delta: float) -> void :



    if _with_comparison and _comparison_exile != null and _current_item != null:
        var alt_held: bool = Input.is_key_pressed(KEY_ALT)
        if alt_held != _last_alt_held:
            _last_alt_held = alt_held
            _rebuild_comparison_for_alt_toggle()

    if _layout_frames > 0:
        _layout_frames -= 1
        if _layout_frames == 0:
            _floating.visible = true
            if _comparison_label != null:
                _comparison_label.visible = true
            if _comparison_header != null:
                _comparison_header.visible = true
            _reposition()
    elif _floating.visible:
        _reposition()










func _resolve_comparison_item(hovered: Item, alt_held: bool) -> Item:
    if hovered == null or hovered.base_item == null:
        return null
    var category: int = hovered.base_item.category
    if category == ItemEnums.ItemCategory.CURRENCY or category == ItemEnums.ItemCategory.RUCKSACK:
        return null
    var slot: ItemEnums.EquipSlot = hovered.base_item.get_equip_slot()
    if slot == ItemEnums.EquipSlot.BOTH_HANDS:
        slot = ItemEnums.EquipSlot.MAIN_HAND
    if slot == ItemEnums.EquipSlot.RING_LEFT and alt_held:
        slot = ItemEnums.EquipSlot.RING_RIGHT
    return _comparison_exile.get_equipped_item(slot)






func _build_comparison_panels(equipped: Item) -> void :
    _comparison_label = TOOLTIP_SCENE.instantiate()
    _comparison_label.name = "ComparisonTooltip"
    _comparison_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _canvas_layer.add_child(_comparison_label)
    _comparison_label.populate(equipped)
    _comparison_label.set_font_scale(FLOATING_FONT_SCALE)
    _comparison_label.visible = false

    _comparison_header = COMPARISON_HEADER_SCENE.instantiate()
    _comparison_header.name = "ComparisonHeader"
    _comparison_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _canvas_layer.add_child(_comparison_header)
    _comparison_header.visible = false


func _clear_comparison_panels() -> void :
    if _comparison_label != null:
        _comparison_label.queue_free()
        _comparison_label = null
    if _comparison_header != null:
        _comparison_header.queue_free()
        _comparison_header = null





func _rebuild_comparison_for_alt_toggle() -> void :
    if _current_item == null or _current_item.base_item == null:
        return
    if _current_item.base_item.get_equip_slot() != ItemEnums.EquipSlot.RING_LEFT:
        return
    _clear_comparison_panels()
    var equipped: Item = _resolve_comparison_item(_current_item, _last_alt_held)
    if equipped != null:
        _build_comparison_panels(equipped)

        _layout_frames = maxi(_layout_frames, 2)




func _reposition() -> void :
    if not _floating.visible or _floating.size == Vector2.ZERO:
        return
    var viewport_size: Vector2 = get_viewport().get_visible_rect().size
    var tip_size: Vector2 = _floating.size



    var compare_active: bool = _comparison_label != null and _comparison_label.visible
    var compare_size: Vector2 = Vector2.ZERO
    if compare_active:
        compare_size = _comparison_label.size
        if compare_size == Vector2.ZERO:
            return




    var src_left: float = _source_rect.position.x
    var src_right: float = _source_rect.position.x + _source_rect.size.x

    var tip_x_left: float = src_left - OFFSET_X - tip_size.x
    var pair_left_edge: float = tip_x_left
    if compare_active:
        pair_left_edge = tip_x_left - COMPARISON_GAP_X - compare_size.x

    var place_left: bool = pair_left_edge >= 0.0

    var tip_x: float
    var compare_x: float = 0.0
    if place_left:
        tip_x = tip_x_left
        if compare_active:
            compare_x = tip_x - COMPARISON_GAP_X - compare_size.x
    else:
        tip_x = src_right + OFFSET_X
        if compare_active:
            compare_x = tip_x + tip_size.x + COMPARISON_GAP_X




    var src_mid_y: float = _source_rect.position.y + _source_rect.size.y * 0.5

    var tip_y: float = src_mid_y - tip_size.y * 0.5




    tip_y = minf(tip_y, viewport_size.y - tip_size.y)
    if tip_size.y <= viewport_size.y:
        tip_y = maxf(tip_y, 0.0)
    tip_x = clampf(tip_x, 0.0, viewport_size.x - tip_size.x)
    _floating.global_position = Vector2(tip_x, tip_y)

    if compare_active:
        var compare_y: float = src_mid_y - compare_size.y * 0.5
        compare_y = minf(compare_y, viewport_size.y - compare_size.y)
        if compare_size.y <= viewport_size.y:
            compare_y = maxf(compare_y, 0.0)
        compare_x = clampf(compare_x, 0.0, viewport_size.x - compare_size.x)
        _comparison_label.global_position = Vector2(compare_x, compare_y)






        if _comparison_header != null and _comparison_header.visible:
            var header_size: Vector2 = _comparison_header.size
            if header_size != Vector2.ZERO:
                var header_x: float = compare_x + (compare_size.x - header_size.x) * 0.5
                var header_y: float = compare_y - header_size.y - COMPARISON_HEADER_GAP_Y
                header_x = clampf(header_x, 0.0, viewport_size.x - header_size.x)
                header_y = clampf(header_y, 0.0, viewport_size.y - header_size.y)
                _comparison_header.global_position = Vector2(header_x, header_y)



func _pin_current() -> void :
    var item = _current_item
    var spawn_pos = _floating.global_position
    hide_floating()

    var window = await _make_pinned_window(item)
    _canvas_layer.add_child(window)
    window.global_position = spawn_pos
    _pinned.append(window)

func _make_pinned_window(item: Item) -> Panel:
    var panel = Panel.new()
    panel.name = "PinnedTooltip"
    panel.mouse_filter = Control.MOUSE_FILTER_STOP

    var vbox = VBoxContainer.new()
    vbox.anchor_right = 1.0
    vbox.anchor_bottom = 1.0
    panel.add_child(vbox)


    var bar = HBoxContainer.new()
    bar.name = "DragBar"
    bar.custom_minimum_size = Vector2(0, PIN_BAR_H)
    bar.mouse_filter = Control.MOUSE_FILTER_STOP
    vbox.add_child(bar)

    var title = Label.new()
    title.text = item.get_display_name()
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.add_theme_font_size_override("font_size", 12)
    title.mouse_filter = Control.MOUSE_FILTER_IGNORE
    bar.add_child(title)

    var close_btn = Button.new()
    close_btn.icon = CLOSE_X_ICON
    close_btn.flat = true
    close_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
    close_btn.custom_minimum_size = Vector2(PIN_BAR_H, PIN_BAR_H)
    bar.add_child(close_btn)


    var label_instance: ItemLabel = TOOLTIP_SCENE.instantiate()
    label_instance.mouse_filter = Control.MOUSE_FILTER_IGNORE
    vbox.add_child(label_instance)

    label_instance.call_deferred("populate", item)


    await get_tree().process_frame
    panel.size = vbox.size + Vector2(0, PIN_BAR_H)


    close_btn.pressed.connect( func():
        _pinned.erase(panel)
        panel.queue_free()
    )






    var drag_state = {"dragging": false, "offset": Vector2.ZERO}
    const SCREEN_EDGE_KEEP_IN_VIEW: = 32.0

    bar.gui_input.connect( func(event: InputEvent):
        if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
            drag_state.dragging = event.pressed
            if event.pressed:
                drag_state.offset = panel.global_position - panel.get_global_mouse_position()
        elif event is InputEventMouseMotion and drag_state.dragging:
            var raw: Vector2 = panel.get_global_mouse_position() + drag_state.offset
            var vp: Vector2 = get_viewport().get_visible_rect().size
            raw.x = clampf(raw.x, SCREEN_EDGE_KEEP_IN_VIEW - panel.size.x, vp.x - SCREEN_EDGE_KEEP_IN_VIEW)
            raw.y = clampf(raw.y, 0.0, vp.y - SCREEN_EDGE_KEEP_IN_VIEW)
            panel.global_position = raw
    )

    return panel
