class_name FireboltVFX
extends AttackVFX
















@export_group("Projectile flight")




@export_range(0.05, 0.95, 0.05) var arrival_fraction: float = 0.35


@export_range(1.0, 20.0, 0.5) var head_radius: float = 5.0


@export_range(1.0, 5.0, 0.1) var head_glow_radius_mult: float = 2.5


@export_range(0.0, 1.0, 0.05) var head_glow_alpha: float = 0.45



@export_range(0.0, 1.0, 0.05) var core_brightness: float = 0.85


@export_range(0.0, 1.0, 0.05) var core_radius_frac: float = 0.45


@export_group("Comet trail")



@export_range(0.0, 2.0, 0.05) var trail_length: float = 0.4


@export_range(0.0, 8.0, 0.25) var trail_width: float = 2.5


@export_range(0.0, 1.0, 0.05) var trail_glow_alpha: float = 0.35


@export_range(4, 24, 1) var trail_segments: int = 10


@export_group("Explosion")





@export_range(0.5, 30.0, 0.1) var explosion_radius_max_in_def_radii: float = 2.8




@export_range(0.0, 30.0, 0.05) var explosion_radius_start_in_def_radii: float = 0.6




@export_range(0.5, 50.0, 0.25) var explosion_ring_width: float = 2.5










@export_range(0.0, 30.0, 0.5) var explosion_ring_feather: float = 0.0



@export_range(0.5, 5.0, 0.1) var explosion_fade_exponent: float = 1.8



@export var explosion_filled_flash: bool = true


@export_range(0.0, 1.0, 0.05) var explosion_flash_alpha: float = 0.85


func draw(drawer: CanvasItem, atk_pos: Vector2, def_pos: Vector2, ctx: Dictionary) -> void :
    var lifetime_progress: float = ctx.get("lifetime_progress", 0.0)
    var color: Color = _resolve_color(ctx)
    var def_radius: float = ctx.get("def_radius", 8.0)

    if lifetime_progress < arrival_fraction:
        _draw_flight(drawer, atk_pos, def_pos, lifetime_progress, color)
    else:
        _draw_explosion(drawer, def_pos, lifetime_progress, color, def_radius)



func _draw_flight(drawer: CanvasItem, atk_pos: Vector2, def_pos: Vector2, 
        lifetime_progress: float, color: Color) -> void :
    var head_progress: float = clampf(lifetime_progress / arrival_fraction, 0.0, 1.0)
    var head_pos: Vector2 = atk_pos.lerp(def_pos, head_progress)



    var points: = PackedVector2Array()
    var inner_colors: = PackedColorArray()
    var glow_colors: = PackedColorArray()
    points.resize(trail_segments + 1)
    inner_colors.resize(trail_segments + 1)
    glow_colors.resize(trail_segments + 1)
    for i in trail_segments + 1:
        var u: float = float(i) / float(trail_segments)
        points[i] = atk_pos.lerp(def_pos, u)
        var vert_alpha: float = _pulse_vertex_alpha(u, head_progress, trail_length, 1.0)
        var inner_c: Color = color
        inner_c.a = color.a * vert_alpha
        inner_colors[i] = inner_c
        var glow_c: Color = inner_c
        glow_c.a *= trail_glow_alpha
        glow_colors[i] = glow_c
    drawer.draw_polyline_colors(points, glow_colors, trail_width * 2.0, true)
    drawer.draw_polyline_colors(points, inner_colors, trail_width, true)


    var orb_glow: Color = color
    orb_glow.a = color.a * head_glow_alpha
    drawer.draw_circle(head_pos, head_radius * head_glow_radius_mult, orb_glow)
    drawer.draw_circle(head_pos, head_radius, color)
    var core_color: Color = color.lerp(Color.WHITE, core_brightness)
    core_color.a = color.a
    drawer.draw_circle(head_pos, head_radius * core_radius_frac, core_color)



func _draw_explosion(drawer: CanvasItem, def_pos: Vector2, 
        lifetime_progress: float, color: Color, def_radius: float) -> void :
    var explosion_t: float = clampf(
        (lifetime_progress - arrival_fraction) / max(1.0 - arrival_fraction, 0.001), 
        0.0, 1.0, 
    )
    var fade: float = pow(1.0 - explosion_t, explosion_fade_exponent)

    var radius_start: float = def_radius * explosion_radius_start_in_def_radii
    var radius_max: float = def_radius * explosion_radius_max_in_def_radii
    var wave_radius: float = lerp(radius_start, radius_max, explosion_t)







    var ring_color: Color = color
    ring_color.a = color.a * fade
    if explosion_ring_feather <= 0.0:
        var ring_glow: Color = ring_color
        ring_glow.a *= 0.4
        drawer.draw_arc(def_pos, wave_radius, 0.0, TAU, 48, 
                ring_glow, explosion_ring_width * 2.5, true)
        drawer.draw_arc(def_pos, wave_radius, 0.0, TAU, 48, 
                ring_color, explosion_ring_width, true)
    else:
        _draw_feathered_ring(drawer, def_pos, wave_radius, ring_color)



    if explosion_filled_flash:
        var flash_radius: float = radius_start * (1.0 + explosion_t * 0.5)
        var flash_color: Color = color.lerp(Color.WHITE, core_brightness)
        flash_color.a = explosion_flash_alpha * pow(1.0 - explosion_t, explosion_fade_exponent * 1.5)
        drawer.draw_circle(def_pos, flash_radius, flash_color)










func _draw_feathered_ring(drawer: CanvasItem, pos: Vector2, radius: float, ring_color: Color) -> void :
    const SUBRING_COUNT: int = 10
    var total_width: float = explosion_ring_width + 2.0 * explosion_ring_feather
    var step_width: float = total_width / float(SUBRING_COUNT)
    var core_half: float = explosion_ring_width * 0.5
    for i in SUBRING_COUNT:

        var offset_from_center: float = (float(i) + 0.5) * step_width - total_width * 0.5
        var dist_from_center: float = absf(offset_from_center)
        var alpha_mult: float
        if dist_from_center <= core_half:
            alpha_mult = 1.0
        else:

            alpha_mult = 1.0 - (dist_from_center - core_half) / maxf(explosion_ring_feather, 0.001)
        var step_color: Color = ring_color
        step_color.a = ring_color.a * alpha_mult
        var step_radius: float = radius + offset_from_center
        if step_radius <= 0.0:
            continue
        drawer.draw_arc(pos, step_radius, 0.0, TAU, 48, step_color, step_width * 1.2, true)
