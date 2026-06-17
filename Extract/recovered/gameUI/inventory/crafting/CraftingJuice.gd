class_name CraftingJuice
extends RefCounted











const CurrencyFlyPipScene: PackedScene = preload("res://gameUI/smallComponents/CurrencyFlyPip.tscn")



const SLAM_DURATION: float = 0.34
const SLAM_SCALE_DOWN: Vector2 = Vector2(0.82, 0.82)
const SLAM_SCALE_UP: Vector2 = Vector2(1.18, 1.18)


const GLOW_DURATION: float = 0.9
const GLOW_PEAK_ALPHA: float = 0.45


const PIP_STAGGER: float = 0.05
const PIP_VISUAL_CAP: int = 8


const PARTICLE_COUNT: int = 28
const PARTICLE_LIFETIME: float = 0.6
const PARTICLE_SPEED_MIN: float = 180.0
const PARTICLE_SPEED_MAX: float = 360.0
const PARTICLE_SCALE_MIN: float = 2.0
const PARTICLE_SCALE_MAX: float = 3.2


const SHAKE_DURATION: float = 0.32
const SHAKE_FREQ: float = 36.0
const SHAKE_INTENSITY: float = 9.0


const GLOW_COLOR_COMMON: Color = Color(1.0, 1.0, 1.0)
const GLOW_COLOR_MAGIC: Color = Color(0.31, 0.56, 0.94)
const GLOW_COLOR_RARE: Color = Color(1.0, 0.84, 0.0)
const GLOW_COLOR_CORRUPTED: Color = Color(0.77, 0.22, 0.22)














static func fly_currency(host: Node, start_global: Vector2, end_global: Vector2, texture: Texture2D, count: int, on_final_arrival: Callable, per_pip_arrival: Callable = Callable()) -> void :
    if host == null or count <= 0 or texture == null:
        if on_final_arrival.is_valid():
            on_final_arrival.call()
        return
    var pip_count: int = mini(count, PIP_VISUAL_CAP)
    for i in pip_count:
        var is_last: bool = i == pip_count - 1
        var delay: float = float(i) * PIP_STAGGER


        var on_arrive: Callable = func() -> void :
            if per_pip_arrival.is_valid():
                per_pip_arrival.call()
            if is_last and on_final_arrival.is_valid():
                on_final_arrival.call()
        _spawn_pip_deferred(host, start_global, end_global, texture, on_arrive, delay)


static func _spawn_pip_deferred(host: Node, start: Vector2, end: Vector2, texture: Texture2D, on_arrive: Callable, delay: float) -> void :
    if delay <= 0.0:
        _spawn_pip(host, start, end, texture, on_arrive)
        return
    host.get_tree().create_timer(delay).timeout.connect( func() -> void :
        _spawn_pip(host, start, end, texture, on_arrive)
    )


static func _spawn_pip(host: Node, start: Vector2, end: Vector2, texture: Texture2D, on_arrive: Callable) -> void :
    var pip: Node = CurrencyFlyPipScene.instantiate()
    host.add_child(pip)
    if pip.has_method("spawn"):
        pip.spawn(start, end, texture, on_arrive)
        return
    if on_arrive.is_valid():
        on_arrive.call()





static func slam_punch(target: Control) -> Tween:
    if target == null:
        return null
    target.pivot_offset = target.size * 0.5
    target.scale = Vector2.ONE
    var tween: Tween = target.create_tween()
    tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
    tween.tween_property(target, "scale", SLAM_SCALE_DOWN, SLAM_DURATION * 0.25)
    tween.tween_property(target, "scale", SLAM_SCALE_UP, SLAM_DURATION * 0.35)
    tween.tween_property(target, "scale", Vector2.ONE, SLAM_DURATION * 0.4)
    return tween





static func rarity_glow(target: Control, rarity: int, corrupted: bool) -> void :
    if target == null:
        return
    var color: Color = glow_color_for(rarity, corrupted)
    var overlay: = ColorRect.new()
    overlay.color = Color(color.r, color.g, color.b, 0.0)
    overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    overlay.anchor_right = 1.0
    overlay.anchor_bottom = 1.0
    target.add_child(overlay)
    var tween: Tween = overlay.create_tween()
    tween.tween_property(overlay, "color:a", GLOW_PEAK_ALPHA, GLOW_DURATION * 0.3)
    tween.tween_property(overlay, "color:a", 0.0, GLOW_DURATION * 0.7)
    tween.tween_callback(overlay.queue_free)




static func particle_burst(host: Node, global_pos: Vector2, rarity: int, corrupted: bool) -> void :
    if host == null:
        return
    var color: Color = glow_color_for(rarity, corrupted)
    var burst: = CPUParticles2D.new()
    host.add_child(burst)



    burst.global_position = global_pos
    burst.emitting = false
    burst.one_shot = true
    burst.explosiveness = 1.0
    burst.amount = PARTICLE_COUNT
    burst.lifetime = PARTICLE_LIFETIME
    burst.direction = Vector2.ZERO
    burst.spread = 180.0
    burst.initial_velocity_min = PARTICLE_SPEED_MIN
    burst.initial_velocity_max = PARTICLE_SPEED_MAX
    burst.gravity = Vector2(0, 180)
    burst.scale_amount_min = PARTICLE_SCALE_MIN
    burst.scale_amount_max = PARTICLE_SCALE_MAX
    burst.color = color


    burst.modulate = Color(1, 1, 1, 1)
    var fade: Tween = burst.create_tween()
    fade.tween_interval(PARTICLE_LIFETIME * 0.5)
    fade.tween_property(burst, "modulate:a", 0.0, PARTICLE_LIFETIME * 0.5)
    fade.tween_callback(burst.queue_free)
    burst.emitting = true






static func panel_shake(panel: Control) -> void :
    if panel == null:
        return
    var origin_l: float = panel.offset_left
    var origin_t: float = panel.offset_top
    var origin_r: float = panel.offset_right
    var origin_b: float = panel.offset_bottom
    var tween: Tween = panel.create_tween()
    var steps: int = int(SHAKE_DURATION * SHAKE_FREQ)
    var step_dur: float = 1.0 / SHAKE_FREQ
    for i in steps:
        var falloff: float = 1.0 - (float(i) / float(steps))
        var dx: float = randf_range(-1, 1) * SHAKE_INTENSITY * falloff
        var dy: float = randf_range(-1, 1) * SHAKE_INTENSITY * falloff
        tween.parallel().tween_property(panel, "offset_left", origin_l + dx, step_dur)
        tween.parallel().tween_property(panel, "offset_top", origin_t + dy, step_dur)
        tween.parallel().tween_property(panel, "offset_right", origin_r + dx, step_dur)
        tween.parallel().tween_property(panel, "offset_bottom", origin_b + dy, step_dur)
    tween.parallel().tween_property(panel, "offset_left", origin_l, 0.05)
    tween.parallel().tween_property(panel, "offset_top", origin_t, 0.05)
    tween.parallel().tween_property(panel, "offset_right", origin_r, 0.05)
    tween.parallel().tween_property(panel, "offset_bottom", origin_b, 0.05)



static func glow_color_for(rarity: int, corrupted: bool) -> Color:
    if corrupted:
        return GLOW_COLOR_CORRUPTED
    match rarity:
        Item.Rarity.RARE:
            return GLOW_COLOR_RARE
        Item.Rarity.UNCOMMON:
            return GLOW_COLOR_MAGIC
        _:
            return GLOW_COLOR_COMMON
