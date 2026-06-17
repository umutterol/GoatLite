class_name SwooshVFX
extends AttackVFX












@export_group("Geometry")


@export_range(0.0, 1.5, 0.05) var pivot_offset_in_def_radii: float = 0.2



@export_range(0.0, 2.0, 0.05) var radius_scale_from_range: float = 0.6



@export_range(0.0, 1.0, 0.05) var radius_min_dist_frac: float = 0.4



@export_range(0.0, 1.0, 0.05) var radius_max_dist_frac: float = 0.7










@export_range(0.0, 5.0, 0.1) var min_radius_in_def_radii: float = 0.0


@export_range(0.1, 3.14, 0.05) var max_spread: float = PI * 0.6




@export_range(0.0, 1.0, 0.05) var tip_taper: float = 0.3

@export_group("Trail width")

@export_range(2, 16, 1) var bands: int = 7


@export_range(0.05, 1.0, 0.05) var trail_thickness_frac: float = 0.5



@export_range(0.5, 4.0, 0.1) var band_width_mult: float = 1.8


@export_range(6, 48, 1) var arc_segments: int = 18

@export_group("Alpha falloff")


@export_range(0.5, 5.0, 0.1) var inner_fade_exponent: float = 2.8



@export_range(0.5, 5.0, 0.1) var trail_fade_exponent: float = 2.5


func draw(drawer: CanvasItem, atk_pos: Vector2, def_pos: Vector2, ctx: Dictionary) -> void :
    var lifetime_progress: float = ctx.get("lifetime_progress", 0.0)
    var fade: float = 1.0 - lifetime_progress
    var color: Color = _resolve_color(ctx)
    var weapon_range: float = ctx.get("weapon_range", 1.5)
    var arena_scale: float = ctx.get("arena_scale", 1.0)
    var def_radius: float = ctx.get("def_radius", 8.0)

    var to_def: Vector2 = def_pos - atk_pos
    var dist: float = to_def.length()
    if dist < 0.01:
        return
    var direction: Vector2 = to_def.normalized()



    var pivot: Vector2 = atk_pos + direction * (def_radius * pivot_offset_in_def_radii)





    var radius_outer: float = clampf(
        weapon_range * arena_scale * radius_scale_from_range, 
        dist * radius_min_dist_frac, 
        dist * radius_max_dist_frac, 
    )
    if min_radius_in_def_radii > 0.0:
        radius_outer = max(radius_outer, def_radius * min_radius_in_def_radii)

    var base_angle: float = direction.angle()
    var trail_thickness: float = radius_outer * trail_thickness_frac
    var band_step: float = trail_thickness / float(bands - 1)
    var band_width: float = band_step * band_width_mult

    for i in bands:
        var t: float = float(i) / float(bands - 1)
        var r: float = radius_outer - t * trail_thickness
        var spread: float = max_spread * (1.0 - t * tip_taper)
        var start_angle: float = base_angle - spread * 0.5
        var end_angle: float = base_angle + spread * 0.5
        var inner_alpha_mult: float = pow(1.0 - t, inner_fade_exponent)



        var points: = PackedVector2Array()
        var colors: = PackedColorArray()
        points.resize(arc_segments + 1)
        colors.resize(arc_segments + 1)
        for j in arc_segments + 1:
            var u: float = float(j) / float(arc_segments)
            var angle: float = lerp(start_angle, end_angle, u)
            points[j] = pivot + Vector2.from_angle(angle) * r
            var length_alpha: float = pow(fade + u * (1.0 - fade), trail_fade_exponent)
            var vert_color: Color = color
            vert_color.a = color.a * inner_alpha_mult * length_alpha
            colors[j] = vert_color
        drawer.draw_polyline_colors(points, colors, band_width, true)
