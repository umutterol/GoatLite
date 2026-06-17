class_name IntermissionDiscardZone
extends PanelContainer


















signal item_discarded(item: Item)



@export var idle_modulate: Color = Color(1.0, 1.0, 1.0, 0.85)
@export var hover_modulate: Color = Color(1.0, 0.45, 0.45, 1.0)

var _drag_over: bool = false


func _ready() -> void :
    mouse_filter = Control.MOUSE_FILTER_STOP
    modulate = idle_modulate





func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
    var accept: bool = data is Item
    if accept and not _drag_over:
        _drag_over = true
        modulate = hover_modulate
    return accept


func _drop_data(_at_position: Vector2, data: Variant) -> void :
    if data is Item:
        item_discarded.emit(data)
    _drag_over = false
    modulate = idle_modulate





func _process(_delta: float) -> void :
    if not _drag_over:
        return
    if not get_viewport().gui_is_dragging():
        _drag_over = false
        modulate = idle_modulate
        return



    if not get_global_rect().has_point(get_viewport().get_mouse_position()):
        _drag_over = false
        modulate = idle_modulate
