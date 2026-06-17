class_name CraftingBenchSlot
extends Control


















signal item_placed(item: Item)
signal item_right_clicked(item: Item)



var validate_drop_cb: Callable = Callable()


var claim_item_cb: Callable = Callable()

@onready var placeholder_label: Label = $PanelContainer / CenterContainer / PlaceholderLabel
@onready var icon_rect: TextureRect = $PanelContainer / CenterContainer / ItemIcon

var _held_item: Item = null


func _ready() -> void :
    _refresh_visual()


func get_item() -> Item:
    return _held_item




func clear() -> Item:
    var item: Item = _held_item
    _held_item = null
    _refresh_visual()
    return item





func set_item(item: Item) -> void :
    _held_item = item
    _refresh_visual()




func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
    if not data is Item:
        return false
    if _held_item != null:
        return false
    if not validate_drop_cb.is_valid():
        return false
    return bool(validate_drop_cb.call(data))


func _drop_data(_at_position: Vector2, data: Variant) -> void :
    if not data is Item or _held_item != null:
        return
    if not claim_item_cb.is_valid():
        return
    if not bool(claim_item_cb.call(data)):
        return
    _held_item = data
    _refresh_visual()
    item_placed.emit(data)




func _get_drag_data(_at_position: Vector2) -> Variant:
    if _held_item == null:
        return null


    var preview: = TextureRect.new()
    if _held_item.base_item.icon != null:
        preview.texture = _held_item.base_item.icon
    preview.custom_minimum_size = Vector2(48, 48)
    preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    set_drag_preview(preview)




    return _held_item





func release() -> void :
    _held_item = null
    _refresh_visual()




func _gui_input(event: InputEvent) -> void :
    if _held_item == null:
        return
    if event is InputEventMouseButton:
        var mb: InputEventMouseButton = event
        if mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:


            item_right_clicked.emit(_held_item)
            accept_event()




func _refresh_visual() -> void :
    if not is_node_ready():
        return
    var has_item: bool = _held_item != null
    placeholder_label.visible = not has_item
    icon_rect.visible = has_item
    if has_item and _held_item.base_item != null:
        icon_rect.texture = _held_item.base_item.icon
