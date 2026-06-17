@tool
class_name TextGlowifyNode
extends Node



















@export var target: Control = null


@export var auto_start: bool = false



@export_range(0.0, 1.0, 0.01) var low_alpha: float = 0.62



@export_range(0.0, 1.0, 0.01) var high_alpha: float = 1.0


@export_range(0.1, 5.0, 0.05) var duration: float = 1.49


var _tween: Tween = null


func _ready() -> void :
    if Engine.is_editor_hint():
        return
    if auto_start:
        start()



func start() -> void :
    var t: Control = _resolve_target()
    if t == null:
        return
    stop()


    var seeded: = t.modulate
    seeded.a = high_alpha
    t.modulate = seeded
    _tween = t.create_tween()
    _tween.set_loops()
    _tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    _tween.tween_property(t, "modulate:a", low_alpha, duration * 0.5)
    _tween.tween_property(t, "modulate:a", high_alpha, duration * 0.5)




func stop() -> void :
    if _tween != null and _tween.is_valid():
        _tween.kill()
    _tween = null
    var t: Control = _resolve_target()
    if t != null:
        var restored: = t.modulate
        restored.a = high_alpha
        t.modulate = restored



func is_running() -> bool:
    return _tween != null and _tween.is_valid()


func _resolve_target() -> Control:
    if target != null:
        return target
    var p: Node = get_parent()
    return p as Control


func _exit_tree() -> void :
    stop()
