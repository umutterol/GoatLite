class_name AttackVFX
extends Resource





























@export var color_override: Color = Color(0, 0, 0, 0)











@export_range(0.1, 3.0, 0.05) var lifetime_seconds: float = 0.4














@export var homes_on_target: bool = false







@export var impact_fx: HitImpactFX = null













@export_range(0.0, 1.0, 0.05) var impact_landing_progress: float = 1.0




func draw(_drawer: CanvasItem, _atk_pos: Vector2, _def_pos: Vector2, _ctx: Dictionary) -> void :
    push_error("AttackVFX.draw() is abstract — %s must override" % get_script().resource_path)




func _resolve_color(ctx: Dictionary) -> Color:
    if color_override.a > 0.0:
        return color_override
    return ctx.get("color", Color.WHITE)















func _pulse_vertex_alpha(u: float, head: float, trail_length: float, overall_fade: float) -> float:
    if u > head:
        return 0.0
    var dist_behind: float = head - u
    var trail_alpha: float = clampf(1.0 - dist_behind / trail_length, 0.0, 1.0)
    return trail_alpha * overall_fade
