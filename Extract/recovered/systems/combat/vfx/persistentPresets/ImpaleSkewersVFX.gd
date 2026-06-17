@tool
class_name ImpaleSkewersVFX
extends Node2D

















@export var tint_color: Color = Color(0.78, 0.78, 0.82, 1.0):
    set(value):
        tint_color = value
        _apply_to_skewers()



@export_range(0.4, 3.0, 0.05) var skewer_scale: float = 1.0:
    set(value):
        skewer_scale = maxf(value, 0.1)
        _apply_to_skewers()



@export_range(0, 80, 1) var burst_particle_count: int = 18:
    set(value):
        burst_particle_count = maxi(value, 0)



@export var burst_color: Color = Color(1.0, 0.65, 0.3, 0.9)




const SKEWER_NAMES: Array[String] = ["Skewer1", "Skewer2", "Skewer3"]


func _ready() -> void :
    _apply_to_skewers()



    if not Engine.is_editor_hint():
        set_visible_count(0)





func set_visible_count(n: int) -> void :
    var max_count: int = SKEWER_NAMES.size()
    var visible_count: int = clampi(n, 0, max_count)
    for i in range(max_count):
        var node: Node = get_node_or_null(SKEWER_NAMES[i])
        if node is Node2D:
            (node as Node2D).visible = i < visible_count






func play_consume_burst() -> void :
    var burst: CPUParticles2D = get_node_or_null("ConsumeBurst") as CPUParticles2D
    if burst != null and burst_particle_count > 0:
        burst.amount = burst_particle_count
        burst.color = burst_color
        burst.emitting = true



    set_visible_count(0)


func _apply_to_skewers() -> void :


    for skewer_name in SKEWER_NAMES:
        var node: Node = get_node_or_null(skewer_name)
        if node == null:
            continue
        if node is Polygon2D:
            (node as Polygon2D).color = tint_color
        if node is Node2D:
            (node as Node2D).scale = Vector2.ONE * skewer_scale
