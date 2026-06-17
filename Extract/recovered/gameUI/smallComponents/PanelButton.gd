@tool
class_name PanelButton
extends Panel















signal pressed




@export var text: String = "Button":
    set(value):
        text = value
        _apply_text()



@export var disabled: bool = false:
    set(value):
        disabled = value
        _apply_style()


@export_group("Styles")

@export var style_normal: StyleBox:
    set(value):
        style_normal = value
        _apply_style()
@export var style_hover: StyleBox:
    set(value):
        style_hover = value
        _apply_style()
@export var style_pressed: StyleBox:
    set(value):
        style_pressed = value
        _apply_style()
@export var style_disabled: StyleBox:
    set(value):
        style_disabled = value
        _apply_style()


@export var style_active: StyleBox:
    set(value):
        style_active = value
        _apply_style()


@export_group("Text")
@export var font: Font:
    set(value):
        font = value
        _apply_font()
@export var font_size: int = 13:
    set(value):
        font_size = value
        _apply_font()
@export var font_color: Color = Color(0.675, 0.525, 0.43, 0.765):
    set(value):
        font_color = value
        _apply_font()







const PRESS_PUNCH_SECONDS: float = 0.12
const PRESS_PUNCH_SCALE: float = 1.08




var _active: bool = false
var _hovered: bool = false
var _down: bool = false
var _punch_tween: Tween = null




func _ready() -> void :
    mouse_filter = Control.MOUSE_FILTER_STOP
    if not mouse_entered.is_connected(_on_mouse_entered):
        mouse_entered.connect(_on_mouse_entered)
    if not mouse_exited.is_connected(_on_mouse_exited):
        mouse_exited.connect(_on_mouse_exited)


    _apply_text()
    _apply_font()
    _apply_style()






func set_active(p_active: bool) -> void :
    if _active == p_active:
        return
    _active = p_active
    _apply_style()


func is_active() -> bool:
    return _active




func _gui_input(event: InputEvent) -> void :
    if disabled:
        return
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        var mb: InputEventMouseButton = event
        if mb.pressed:
            _down = true
            _apply_style()
            _play_press_punch()
        else:

            var was_down: bool = _down
            _down = false
            _apply_style()
            if was_down and _hovered:
                pressed.emit()
        accept_event()




func _play_press_punch() -> void :
    if _punch_tween and _punch_tween.is_valid():
        _punch_tween.kill()
    pivot_offset = size / 2.0
    scale = Vector2.ONE
    _punch_tween = create_tween()
    _punch_tween.tween_property(self, "scale", 
        Vector2(PRESS_PUNCH_SCALE, PRESS_PUNCH_SCALE), PRESS_PUNCH_SECONDS / 2.0)
    _punch_tween.tween_property(self, "scale", 
        Vector2.ONE, PRESS_PUNCH_SECONDS / 2.0)


func _on_mouse_entered() -> void :
    _hovered = true
    _apply_style()


func _on_mouse_exited() -> void :
    _hovered = false

    _down = false
    _apply_style()




func _apply_style() -> void :
    var style: StyleBox = _resolve_style()
    if style != null:
        add_theme_stylebox_override("panel", style)





func _resolve_style() -> StyleBox:
    if disabled and style_disabled != null:
        return style_disabled
    if _down and style_pressed != null:
        return style_pressed
    if _hovered and style_hover != null:
        return style_hover
    if _active and style_active != null:
        return style_active
    return style_normal


func _apply_text() -> void :
    var label: Label = _get_label()
    if label != null:
        label.text = text


func _apply_font() -> void :
    var label: Label = _get_label()
    if label == null:
        return
    if font != null:
        label.add_theme_font_override("font", font)
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", font_color)


func _get_label() -> Label:
    if not is_inside_tree():
        return null
    return get_node_or_null("MarginContainer/Label") as Label
