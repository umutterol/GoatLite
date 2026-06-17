class_name HomingVFX
extends AttackVFX


















enum ArcSide{
    ALL_SAME, 
    ALTERNATING, 
    RANDOM, 
}


@export_group("Volley")


@export_range(1, 8, 1) var projectile_count: int = 4





@export_range(0.0, 0.9, 0.05) var sequence_stagger: float = 0.0



@export_range(0.05, 1.0, 0.05) var arrival_fraction: float = 0.6


@export_range(0.5, 5.0, 0.1) var post_arrival_fade_exponent: float = 2.0


@export_group("Arc")




@export_range(0.0, 200.0, 1.0) var arc_offset_magnitude: float = 60.0




@export_range(0.05, 0.95, 0.05) var arc_peak_position: float = 0.35


@export var arc_side: ArcSide = ArcSide.ALTERNATING


@export_group("Twist")




@export_range(0.0, 30.0, 0.5) var twist_amplitude: float = 0.0



@export_range(0.0, 8.0, 0.25) var twist_frequency: float = 2.0


@export_group("Sampling")



@export_range(6, 32, 1) var trajectory_segments: int = 16


@export_group("Pellet")



@export_range(0.5, 12.0, 0.25) var pellet_radius: float = 3.0



@export_range(0.0, 30.0, 0.5) var pellet_length: float = 0.0


@export_range(1.0, 5.0, 0.1) var pellet_glow_radius_mult: float = 2.2


@export_range(0.0, 1.0, 0.05) var pellet_glow_alpha: float = 0.5



@export_range(0.0, 1.0, 0.05) var core_brightness: float = 0.7


@export_group("Trail")



@export_range(0.0, 2.0, 0.05) var trail_length: float = 0.5


@export_range(0.0, 6.0, 0.25) var trail_width: float = 2.0


@export_range(0.0, 1.0, 0.05) var trail_glow_alpha: float = 0.4


func draw(drawer: CanvasItem, atk_pos: Vector2, def_pos: Vector2, ctx: Dictionary) -> void :
    var lifetime_progress: float = ctx.get("lifetime_progress", 0.0)
    var color: Color = _resolve_color(ctx)
    var cast_seed: int = int(ctx.get("seed", 0))

    var to_def: Vector2 = def_pos - atk_pos
    if to_def.length_squared() < 0.01:
        return

    var perpendicular: Vector2 = to_def.orthogonal().normalized()

    var rng: = RandomNumberGenerator.new()
    rng.seed = cast_seed

    var arrival: float = clampf(arrival_fraction, 0.05, 1.0)
    var stagger: float = clampf(sequence_stagger, 0.0, 0.95)


    var post_arrival_window: float = max(1.0 - arrival - stagger, 0.001)

    for i in projectile_count:


        var sign_roll: float = rng.randf()
        var twist_phase: float = rng.randf() * TAU
        var arc_sign: float = _arc_sign_for(i, sign_roll)



        var fire_at: float = 0.0
        if projectile_count > 1 and stagger > 0.0:
            fire_at = (float(i) / float(projectile_count - 1)) * stagger

        var post_fire_t: float = lifetime_progress - fire_at
        if post_fire_t < 0.0:
            continue

        var flight_t: float = clampf(post_fire_t / arrival, 0.0, 1.0)
        var post_arrival_t: float = clampf(
            (post_fire_t - arrival) / post_arrival_window, 0.0, 1.0
        )
        var fade_alpha: float = pow(1.0 - post_arrival_t, post_arrival_fade_exponent)
        if fade_alpha <= 0.001:
            continue

        _draw_projectile(drawer, atk_pos, def_pos, perpendicular, 
                flight_t, fade_alpha, arc_sign, twist_phase, color)


func _arc_sign_for(index: int, sign_roll: float) -> float:
    match arc_side:
        ArcSide.ALTERNATING:
            return 1.0 if index % 2 == 0 else -1.0
        ArcSide.RANDOM:
            return 1.0 if sign_roll > 0.5 else -1.0
        _:
            return 1.0


func _draw_projectile(
        drawer: CanvasItem, atk_pos: Vector2, def_pos: Vector2, 
        perpendicular: Vector2, flight_t: float, fade_alpha: float, 
        arc_sign: float, twist_phase: float, color: Color) -> void :




    if trail_length > 0.0 and trail_width > 0.0 and flight_t > 0.0:
        var n: int = trajectory_segments
        var points: = PackedVector2Array()
        var inner_colors: = PackedColorArray()
        var glow_colors: = PackedColorArray()
        points.resize(n + 1)
        inner_colors.resize(n + 1)
        glow_colors.resize(n + 1)
        for j in n + 1:
            var u: float = float(j) / float(n) * flight_t
            points[j] = _trajectory_point(atk_pos, def_pos, perpendicular, 
                    u, arc_sign, twist_phase)
            var trail_a: float = _pulse_vertex_alpha(
                    u, flight_t, trail_length, fade_alpha)
            var inner_c: Color = color
            inner_c.a = color.a * trail_a
            inner_colors[j] = inner_c
            var glow_c: Color = inner_c
            glow_c.a *= trail_glow_alpha
            glow_colors[j] = glow_c
        drawer.draw_polyline_colors(points, glow_colors, trail_width * 2.0, true)
        drawer.draw_polyline_colors(points, inner_colors, trail_width, true)


    var head_pos: Vector2 = _trajectory_point(atk_pos, def_pos, perpendicular, 
            flight_t, arc_sign, twist_phase)

    var glow: Color = color
    glow.a = color.a * pellet_glow_alpha * fade_alpha
    drawer.draw_circle(head_pos, pellet_radius * pellet_glow_radius_mult, glow)

    if pellet_length > 0.0:
        var vel_angle: float = _trajectory_velocity_angle(atk_pos, def_pos, 
                perpendicular, flight_t, arc_sign, twist_phase)
        var vel_dir: Vector2 = Vector2.from_angle(vel_angle)
        var half_extent: Vector2 = vel_dir * (pellet_length * 0.5)
        var body_color: Color = color
        body_color.a = color.a * fade_alpha
        drawer.draw_line(head_pos - half_extent, head_pos + half_extent, 
                body_color, pellet_radius * 2.0)
        var core_color: Color = color.lerp(Color.WHITE, core_brightness)
        core_color.a = color.a * fade_alpha
        drawer.draw_line(
                head_pos - half_extent * 0.6, 
                head_pos + half_extent * 0.6, 
                core_color, pellet_radius, 
        )
    else:
        var body_color: Color = color
        body_color.a = color.a * fade_alpha
        drawer.draw_circle(head_pos, pellet_radius, body_color)
        var core_color: Color = color.lerp(Color.WHITE, core_brightness)
        core_color.a = color.a * fade_alpha
        drawer.draw_circle(head_pos, pellet_radius * 0.55, core_color)




func _trajectory_point(
        atk_pos: Vector2, def_pos: Vector2, perpendicular: Vector2, 
        u: float, arc_sign: float, twist_phase: float) -> Vector2:
    var base: Vector2 = atk_pos.lerp(def_pos, u)
    var arc_offset: Vector2 = perpendicular * (_arc_curve(u) * arc_offset_magnitude * arc_sign)

    var twist_taper: float = sin(PI * u)
    var twist_offset: Vector2 = perpendicular * (
            sin(u * twist_frequency * TAU + twist_phase) * twist_amplitude * twist_taper
    )
    return base + arc_offset + twist_offset





func _arc_curve(u: float) -> float:
    if u <= 0.0 or u >= 1.0:
        return 0.0
    var peak: float = clampf(arc_peak_position, 0.01, 0.99)
    var theta: float
    if u <= peak:

        theta = (u / peak) * (PI * 0.5)
    else:

        theta = PI * 0.5 + ((u - peak) / (1.0 - peak)) * (PI * 0.5)
    return sin(theta)




func _trajectory_velocity_angle(
        atk_pos: Vector2, def_pos: Vector2, perpendicular: Vector2, 
        u: float, arc_sign: float, twist_phase: float) -> float:
    var eps: float = 0.01
    var p1: Vector2 = _trajectory_point(atk_pos, def_pos, perpendicular, 
            clampf(u - eps, 0.0, 1.0), arc_sign, twist_phase)
    var p2: Vector2 = _trajectory_point(atk_pos, def_pos, perpendicular, 
            clampf(u + eps, 0.0, 1.0), arc_sign, twist_phase)
    return (p2 - p1).angle()
