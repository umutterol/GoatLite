





















class_name SeatSlot
extends PanelContainer


@export var zone: String = "core"






@export var slot_index: int = 0


@export var style_empty: StyleBox
@export var style_occupied: StyleBox


@export var style_drop_hover: StyleBox


@export var style_hidden: StyleBox

@onready var placeholder_label: Label = $PlaceholderLabel

var _card: ExileGuildCard = null



var _drag_active: bool = false



var _drop_hover_active: bool = false


func _ready() -> void :

    set_process(false)
    _refresh_visual()




func host_card(card: ExileGuildCard) -> void :
    clear_card()
    _card = card
    add_child(card)
    _refresh_visual()



func clear_card() -> void :
    if _card and is_instance_valid(_card):
        _card.queue_free()
    _card = null
    _refresh_visual()



func has_card() -> bool:
    return _card != null and is_instance_valid(_card)



func get_card() -> ExileGuildCard:
    return _card







func _notification(what: int) -> void :
    if what == NOTIFICATION_DRAG_BEGIN:
        _drag_active = true
        _drop_hover_active = false
        set_process(true)
        _refresh_visual()
    elif what == NOTIFICATION_DRAG_END:
        _drag_active = false
        _drop_hover_active = false
        set_process(false)
        _refresh_visual()







func _process(_delta: float) -> void :
    if not _drop_hover_active:
        return
    if get_global_rect().has_point(get_global_mouse_position()):
        return
    _drop_hover_active = false
    _refresh_visual()




func _can_drop_data(_at_position: Vector2, data) -> bool:


    if not (data is Dictionary):
        return false
    if data.get("type", "") != "exile_card":
        return false

    var src_id: int = int(data.get("exile_id", -1))
    if src_id < 0:
        return false
    if has_card() and _card.exile_data and _card.exile_data.id == src_id:
        return false


    if not _drop_hover_active:
        _drop_hover_active = true
        _refresh_visual()
    return true


func _drop_data(_at_position: Vector2, data) -> void :



    _drop_hover_active = false
    _drag_active = false
    set_process(false)
    _refresh_visual()
    var src_id: int = int(data.get("exile_id", -1))
    if src_id < 0:
        return
    GameState.swap_seats_by_exile_id(src_id, zone, slot_index)













func _refresh_visual() -> void :
    var style: StyleBox
    var show_placeholder: bool
    if has_card():
        style = style_drop_hover if _drop_hover_active else style_occupied
        show_placeholder = false
    else:
        if _drag_active:
            style = style_drop_hover if _drop_hover_active else style_empty
            show_placeholder = true
        else:
            style = style_hidden
            show_placeholder = false
    _apply_style(style)
    if placeholder_label != null:
        placeholder_label.visible = show_placeholder


func _apply_style(style: StyleBox) -> void :
    if style == null:
        return
    add_theme_stylebox_override("panel", style)
