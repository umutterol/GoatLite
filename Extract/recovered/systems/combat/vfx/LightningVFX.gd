class_name LightningVFX
extends AttackVFX








@export_group("Timing")


@export_range(0.05, 1.0, 0.05) var arrival_fraction: float = 0.25



@export_range(0.1, 2.0, 0.05) var trail_length: float = 0.7

@export_group("Width")

@export_range(0.5, 6.0, 0.25) var width_base: float = 1.0


@export_range(0.0, 8.0, 0.25) var width_pulse: float = 2.5


@export_range(1.0, 5.0, 0.1) var glow_width_mult: float = 2.5


@export_range(0.0, 1.0, 0.05) var glow_alpha: float = 0.4

@export_group("Bolt shape")

@export_range(4, 32, 1) var segments: int = 12


@export_range(0.0, 30.0, 0.5) var jitter_magnitude: float = 7.0



@export_range(0.0, 20.0, 0.5) var strand_spacing: float = 4.0



@export_range(0.25, 4.0, 0.25) var taper_power: float = 1.0


func draw(drawer: CanvasItem, atk_pos: Vector2, def_pos: Vector2, ctx: Dictionary) -> void :
    var lifetime_progress: float = ctx.get("lifetime_progress", 0.0)
    var color: Color = _resolve_color(ctx)
    var cast_seed: int = int(ctx.get("seed", 0))

    var head: float = clampf(lifetime_progress / arrival_fraction, 0.0, 1.0)
    var post_arrival_t: float = clampf(
        (lifetime_progress - arrival_fraction) / max(1.0 - arrival_fraction, 0.001), 
        0.0, 1.0, 
    )
    var overall_fade: float = 1.0 - post_arrival_t
    var inner_width: float = width_base + (1.0 - lifetime_progress) * width_pulse

    var to_def: Vector2 = def_pos - atk_pos
    if to_def.length_squared() < 0.01:
        return

    var perpendicular: Vector2 = to_def.orthogonal().normalized()


    _draw_strand(
        drawer, atk_pos, def_pos, perpendicular, strand_spacing * 0.5, 
        cast_seed, head, overall_fade, inner_width, color, 
    )
    _draw_strand(
        drawer, atk_pos, def_pos, perpendicular, - strand_spacing * 0.5, 


        cast_seed ^ 1540483477, 
        head, overall_fade, inner_width, color, 
    )


func _draw_strand(
        drawer: CanvasItem, atk_pos: Vector2, def_pos: Vector2, 
        perpendicular: Vector2, base_offset: float, strand_seed: int, 
        head: float, overall_fade: float, inner_width: float, color: Color) -> void :
    var rng: = RandomNumberGenerator.new()
    rng.seed = strand_seed

    var points: = PackedVector2Array()
    var inner_colors: = PackedColorArray()
    var glow_colors: = PackedColorArray()
    points.resize(segments + 1)
    inner_colors.resize(segments + 1)
    glow_colors.resize(segments + 1)

    for i in segments + 1:
        var u: float = float(i) / float(segments)
        var base_point: Vector2 = atk_pos.lerp(def_pos, u)

        var taper: float = pow(sin(PI * u), taper_power)
        var jitter_amount: float = rng.randf_range(-1.0, 1.0) * jitter_magnitude * taper
        points[i] = base_point + perpendicular * (base_offset + jitter_amount)
        var vert_alpha: float = _pulse_vertex_alpha(u, head, trail_length, overall_fade)
        var inner_c: Color = color
        inner_c.a = color.a * vert_alpha
        inner_colors[i] = inner_c
        var glow_c: Color = inner_c
        glow_c.a *= glow_alpha
        glow_colors[i] = glow_c

    drawer.draw_polyline_colors(points, glow_colors, inner_width * glow_width_mult, true)
    drawer.draw_polyline_colors(points, inner_colors, inner_width, true)
