@tool
class_name GlowifyNode
extends Node
























@export var target: Control = null



@export var auto_start: bool = false






@export var disable_on_click: bool = false







@export var only_when_enabled: bool = false




@export var base_color: Color = Color.WHITE




@export var peak_color: Color = Color(0, 0, 0, 0)




@export var tint_multiplier: Color = Color(1.315, 1.198, 0.802, 1.0)


@export_range(0.1, 5.0, 0.05) var duration: float = 1.375


var _tween: Tween = null


var _click_listener: Control = null



var _wants_running: bool = false


func _ready() -> void :


    if Engine.is_editor_hint():
        return



    set_process(only_when_enabled)
    if auto_start:
        start()







func start() -> void :
    _wants_running = true
    _apply_state()





func stop() -> void :
    _wants_running = false
    _apply_state()





func is_running() -> bool:
    return _tween != null and _tween.is_valid()





func is_armed() -> bool:
    return _wants_running





func set_base_color(color: Color) -> void :
    base_color = color
    if is_running():
        _play_tween()




func _apply_state() -> void :
    var t: Control = _resolve_target()
    if t == null:
        _halt_tween()
        return
    var should_run: bool = _wants_running and _gate_allows_running(t)
    if should_run:
        if not is_running():
            _play_tween()
    else:
        if is_running():
            _halt_tween()




func _process(_delta: float) -> void :
    if not _wants_running:
        return
    _apply_state()




func _gate_allows_running(t: Control) -> bool:
    if not only_when_enabled:
        return true
    if t is BaseButton:
        return not (t as BaseButton).disabled
    return true





func _play_tween() -> void :
    var t: Control = _resolve_target()
    if t == null:
        return
    _halt_tween()
    var peak: Color = _resolve_peak_color()


    t.modulate = base_color
    _tween = t.create_tween()
    _tween.set_loops()
    _tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    _tween.tween_property(t, "modulate", peak, duration * 0.5)
    _tween.tween_property(t, "modulate", base_color, duration * 0.5)
    if disable_on_click:
        _attach_click_listener(t)





func _halt_tween() -> void :
    _detach_click_listener()
    if _tween != null and _tween.is_valid():
        _tween.kill()
    _tween = null
    var t: Control = _resolve_target()
    if t != null:
        t.modulate = base_color


func _resolve_target() -> Control:
    if target != null:
        return target
    var p: Node = get_parent()
    return p as Control


func _resolve_peak_color() -> Color:
    if peak_color.a > 0.0:
        return peak_color


    return Color(
        clampf(base_color.r * tint_multiplier.r, 0.0, 2.0), 
        clampf(base_color.g * tint_multiplier.g, 0.0, 2.0), 
        clampf(base_color.b * tint_multiplier.b, 0.0, 2.0), 
        base_color.a, 
    )








func _attach_click_listener(t: Control) -> void :


    if _click_listener == t:
        return
    _detach_click_listener()
    t.gui_input.connect(_on_target_gui_input)
    _click_listener = t


func _detach_click_listener() -> void :
    if _click_listener == null:
        return
    if is_instance_valid(_click_listener) and _click_listener.gui_input.is_connected(_on_target_gui_input):
        _click_listener.gui_input.disconnect(_on_target_gui_input)
    _click_listener = null


func _on_target_gui_input(event: InputEvent) -> void :
    if not event is InputEventMouseButton:
        return
    var mb: InputEventMouseButton = event
    if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
        stop()


func _exit_tree() -> void :
    stop()
