class_name ShotgunVFX
extends AttackVFX























@export_group("Spread")


@export_range(1, 32, 1) var pellet_count: int = 8



@export_range(0.0, 180.0, 1.0) var spread_angle_deg: float = 45.0



@export_range(0.0, 30.0, 0.5) var aim_jitter_deg: float = 4.0



@export_range(0.0, 1.0, 0.05) var range_jitter: float = 0.25




@export_range(0.1, 3.0, 0.05) var range_factor_base: float = 1.1


@export_group("Timing")



@export_range(0.05, 1.0, 0.05) var arrival_fraction: float = 0.5



@export_range(0.5, 5.0, 0.1) var post_arrival_fade_exponent: float = 2.0


@export_group("Pellet")



@export_range(0.25, 12.0, 0.25) var pellet_radius: float = 2.5




@export_range(0.0, 30.0, 0.5) var pellet_length: float = 0.0


@export_range(1.0, 5.0, 0.1) var pellet_glow_radius_mult: float = 2.0


@export_range(0.0, 1.0, 0.05) var pellet_glow_alpha: float = 0.4



@export_range(0.0, 1.0, 0.05) var core_brightness: float = 0.5


@export_group("Per-pellet trail")




@export_range(0.0, 2.0, 0.05) var trail_length: float = 0.0


@export_range(0.0, 6.0, 0.25) var trail_width: float = 1.5


@export_range(0.0, 1.0, 0.05) var trail_glow_alpha: float = 0.35


@export_range(4, 16, 1) var trail_segments: int = 6


func draw(drawer: CanvasItem, atk_pos: Vector2, def_pos: Vector2, ctx: Dictionary) -> void :
    var lifetime_progress: float = ctx.get("lifetime_progress", 0.0)
    var color: Color = _resolve_color(ctx)
    var cast_seed: int = int(ctx.get("seed", 0))

    var to_def: Vector2 = def_pos - atk_pos
    var dist_to_def: float = to_def.length()
    if dist_to_def < 0.01:
        return
    var base_angle: float = to_def.angle()


    var rng: = RandomNumberGenerator.new()
    rng.seed = cast_seed

    var arrival: float = max(arrival_fraction, 0.001)
    var flight_progress: float = clampf(lifetime_progress / arrival, 0.0, 1.0)

    var post_t: float = clampf(
        (lifetime_progress - arrival) / max(1.0 - arrival, 0.001), 
        0.0, 1.0, 
    )
    var fade_alpha: float = pow(1.0 - post_t, post_arrival_fade_exponent)

    var spread_rad: float = deg_to_rad(spread_angle_deg)
    var aim_jitter_rad: float = deg_to_rad(aim_jitter_deg)

    for i in pellet_count:

        var even_frac: float
        if pellet_count <= 1:
            even_frac = 0.0
        else:
            even_frac = float(i) / float(pellet_count - 1) - 0.5
        var pellet_angle: float = base_angle\
+ even_frac * spread_rad\
+ rng.randf_range( - aim_jitter_rad, aim_jitter_rad)
        var pellet_range: float = dist_to_def * range_factor_base\
* (1.0 + rng.randf_range( - range_jitter, range_jitter))
        var endpoint: Vector2 = atk_pos + Vector2.from_angle(pellet_angle) * pellet_range
        var pellet_pos: Vector2 = atk_pos.lerp(endpoint, flight_progress)

        _draw_pellet(drawer, atk_pos, endpoint, pellet_pos, flight_progress, 
                pellet_angle, fade_alpha, color)




func _draw_pellet(
        drawer: CanvasItem, atk_pos: Vector2, endpoint: Vector2, 
        pellet_pos: Vector2, flight_progress: float, velocity_angle: float, 
        fade_alpha: float, color: Color) -> void :


    if trail_length > 0.0 and trail_width > 0.0:
        var points: = PackedVector2Array()
        var inner_colors: = PackedColorArray()
        var glow_colors: = PackedColorArray()
        points.resize(trail_segments + 1)
        inner_colors.resize(trail_segments + 1)
        glow_colors.resize(trail_segments + 1)
        for j in trail_segments + 1:
            var u: float = float(j) / float(trail_segments)
            points[j] = atk_pos.lerp(endpoint, u)
            var trail_a: float = _pulse_vertex_alpha(u, flight_progress, 
                    trail_length, fade_alpha)
            var inner_c: Color = color
            inner_c.a = color.a * trail_a
            inner_colors[j] = inner_c
            var glow_c: Color = inner_c
            glow_c.a *= trail_glow_alpha
            glow_colors[j] = glow_c
        drawer.draw_polyline_colors(points, glow_colors, trail_width * 2.0, true)
        drawer.draw_polyline_colors(points, inner_colors, trail_width, true)


    var glow: Color = color
    glow.a = color.a * pellet_glow_alpha * fade_alpha
    drawer.draw_circle(pellet_pos, pellet_radius * pellet_glow_radius_mult, glow)


    if pellet_length > 0.0:
        var vel_dir: Vector2 = Vector2.from_angle(velocity_angle)
        var half_extent: Vector2 = vel_dir * (pellet_length * 0.5)
        var body_color: Color = color
        body_color.a = color.a * fade_alpha
        drawer.draw_line(pellet_pos - half_extent, pellet_pos + half_extent, 
                body_color, pellet_radius * 2.0)
        var core_color: Color = color.lerp(Color.WHITE, core_brightness)
        core_color.a = color.a * fade_alpha
        drawer.draw_line(
                pellet_pos - half_extent * 0.6, 
                pellet_pos + half_extent * 0.6, 
                core_color, pellet_radius, 
        )
    else:
        var body_color: Color = color
        body_color.a = color.a * fade_alpha
        drawer.draw_circle(pellet_pos, pellet_radius, body_color)
        var core_color: Color = color.lerp(Color.WHITE, core_brightness)
        core_color.a = color.a * fade_alpha
        drawer.draw_circle(pellet_pos, pellet_radius * 0.55, core_color)
