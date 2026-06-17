class_name DiffBar
extends Control















const ANIM_DURATION_DEFAULT: float = 5.0

@export var bar_color: Color = Color(0.85, 0.3, 0.3)
@export var bar_height: float = 18.0

@export_range(0.0, 1.0) var gain_brighten: float = 0.55

@export_range(0.0, 1.0) var loss_darken: float = 0.55

@export_range(0.0, 8.0) var corner_radius: float = 2.0

@export var hover_font_size: int = 15

var max_value: float = 100.0
var start_value: float = 0.0
var end_value: float = 0.0
var current_value: float = 0.0

var _hover_label: Label
var _tween: Tween


var _bg_box: StyleBoxFlat = null


func _ready() -> void :
    custom_minimum_size.y = bar_height

    mouse_filter = MOUSE_FILTER_PASS

    _bg_box = StyleBoxFlat.new()
    _bg_box.corner_radius_top_left = int(corner_radius)
    _bg_box.corner_radius_top_right = int(corner_radius)
    _bg_box.corner_radius_bottom_left = int(corner_radius)
    _bg_box.corner_radius_bottom_right = int(corner_radius)

    _hover_label = Label.new()
    _hover_label.visible = false
    _hover_label.mouse_filter = MOUSE_FILTER_IGNORE
    _hover_label.set_anchors_preset(Control.PRESET_FULL_RECT)
    _hover_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _hover_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _hover_label.add_theme_font_size_override("font_size", hover_font_size)
    _hover_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.98))

    _hover_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
    _hover_label.add_theme_constant_override("outline_size", 4)
    add_child(_hover_label)

    mouse_entered.connect(_show_numbers)
    mouse_exited.connect(_hide_numbers)








func configure(start: float, end: float, max_v: float, color: Color) -> void :





    max_value = maxf(max_v, 0.001)
    start_value = clampf(start, 0.0, max_value)
    end_value = clampf(end, 0.0, max_value)
    current_value = start_value
    bar_color = color
    queue_redraw()



func play_animation(duration: float = ANIM_DURATION_DEFAULT) -> void :
    _kill_tween()
    if is_equal_approx(start_value, end_value):

        current_value = end_value
        queue_redraw()
        return
    _tween = create_tween()
    _tween.tween_method(_set_current, start_value, end_value, duration)



func snap_to_end() -> void :
    _kill_tween()
    current_value = end_value
    queue_redraw()






func _kill_tween() -> void :
    if _tween and _tween.is_valid() and _tween.is_running():
        _tween.kill()
    _tween = null


func _set_current(v: float) -> void :
    current_value = v
    queue_redraw()
    if _hover_label and _hover_label.visible:
        _update_hover_text()


func _show_numbers() -> void :
    _hover_label.visible = true
    _update_hover_text()


func _hide_numbers() -> void :
    _hover_label.visible = false


func _update_hover_text() -> void :
    _hover_label.text = "%d / %d" % [int(round(current_value)), int(round(max_value))]


func _draw() -> void :
    var w: float = size.x
    var h: float = size.y
    if w <= 0.0 or h <= 0.0:
        return
    var is_gain: bool = end_value > start_value


    _bg_box.bg_color = Color(0.0, 0.0, 0.0, 0.5)
    draw_style_box(_bg_box, Rect2(0, 0, w, h))

    if is_gain:

        if start_value > 0.0:
            var start_w: float = (start_value / max_value) * w
            _bg_box.bg_color = bar_color
            draw_style_box(_bg_box, Rect2(0, 0, start_w, h))

        if current_value > start_value:
            var x_a: float = (start_value / max_value) * w
            var x_b: float = (current_value / max_value) * w
            _bg_box.bg_color = bar_color.lerp(Color(1, 1, 1, 1), gain_brighten)
            draw_style_box(_bg_box, Rect2(x_a, 0, x_b - x_a, h))
    else:

        if current_value > 0.0:
            var current_w: float = (current_value / max_value) * w
            _bg_box.bg_color = bar_color
            draw_style_box(_bg_box, Rect2(0, 0, current_w, h))

        if start_value > current_value:
            var x_a: float = (current_value / max_value) * w
            var x_b: float = (start_value / max_value) * w
            _bg_box.bg_color = bar_color.darkened(loss_darken)
            draw_style_box(_bg_box, Rect2(x_a, 0, x_b - x_a, h))


    draw_rect(Rect2(0, 0, w, h), Color(0.0, 0.0, 0.0, 0.75), false, 1.0)
