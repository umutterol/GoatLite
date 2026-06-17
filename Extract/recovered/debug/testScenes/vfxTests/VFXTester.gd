extends Control













const PRESETS_DIR: = "res://systems/combat/vfx/presets/"



const IMPACT_PRESETS_DIR: = "res://systems/combat/vfx/impactPresets/"



const DEFAULT_IMPACT_FX: HitImpactFX = preload("res://systems/combat/vfx/impactPresets/blood_default.tres")



const MAX_TESTER_STAINS: int = 600




const FALLBACK_VFX_WINDOW: float = 0.4





const PLAYBACK_ARENA_BG: = Color("140b03ff")
const PLAYBACK_ARENA_BORDER: = Color("583824ff")
const PLAYBACK_ALLY_MELEE_COLOR: = Color("#4aaa6a")
const PLAYBACK_ALLY_RANGED_COLOR: = Color("#3a8a5a")
const PLAYBACK_ENEMY_COLOR: = Color("#993333")
const PLAYBACK_ENEMY_RANGED_COLOR: = Color("#884444")
const PLAYBACK_ENEMY_UNIQUE_COLOR: = Color("#cc6622")

const PLAYBACK_ALLY_CIRCLE_RADIUS: = 16.0
const PLAYBACK_ENEMY_CIRCLE_RADIUS: = 12.0
const PLAYBACK_UNIQUE_CIRCLE_RADIUS: = 22.0



const PANEL_BG: = Color(0.04, 0.04, 0.05)




const VIRTUAL_ARENA_WIDTH: float = 30.0
const VIRTUAL_ARENA_HEIGHT: float = 20.0




const TESTER_WEAPON_RANGE: float = 6.0


@onready var vfx_list: ItemList = %VfxList
@onready var distance_slider: HSlider = %DistanceSlider
@onready var distance_label: Label = %DistanceLabel
@onready var loop_interval_slider: HSlider = %LoopIntervalSlider
@onready var loop_interval_label: Label = %LoopIntervalLabel
@onready var crit_check: CheckBox = %CritCheck
@onready var team_check: CheckBox = %TeamCheck
@onready var unique_check: CheckBox = %UniqueCheck
@onready var animate_check: CheckBox = %AnimateCheck
@onready var fire_now_button: Button = %FireNowButton
@onready var reload_button: Button = %ReloadButton
@onready var speed_025_button: Button = %Speed025Button
@onready var speed_05_button: Button = %Speed05Button
@onready var speed_1_button: Button = %Speed1Button
@onready var speed_2_button: Button = %Speed2Button
@onready var speed_4_button: Button = %Speed4Button
@onready var lifetime_bar: ProgressBar = %LifetimeBar
@onready var status_label: Label = %StatusLabel
@onready var arena_drawer: Control = %ArenaDrawer
@onready var impact_override_option: OptionButton = %ImpactOverrideOption
@onready var clear_stains_button: Button = %ClearStainsButton
@onready var impact_status_label: Label = %ImpactStatusLabel


var _presets: Array[AttackVFX] = []
var _preset_paths: Array[String] = []
var _selected_vfx: AttackVFX = null


var _attacker_pos: Vector2 = Vector2.ZERO
var _defender_pos: Vector2 = Vector2.ZERO




var _fire_attacker_pos: Vector2 = Vector2.ZERO
var _fire_defender_pos: Vector2 = Vector2.ZERO




var _arena_scale_px_per_unit: float = 1.0
var _arena_screen_offset: Vector2 = Vector2.ZERO
var _arena_size_screen: Vector2 = Vector2.ZERO




var _elapsed_since_fire: float = INF


var _current_seed: int = 0



var _speed_multiplier: float = 1.0



var _animate_elapsed: float = 0.0







var _impact_presets: Array[HitImpactFX] = []
var _impact_preset_paths: Array[String] = []



var _selected_impact_override: HitImpactFX = null



var _global_elapsed: float = 0.0
















var _pending_impacts: Array[Dictionary] = []



var _impact_stains_tester: Array[Dictionary] = []




var _last_fire_impact_fx: HitImpactFX = null






func _ready() -> void :
    _load_presets()
    _populate_list()
    _load_impact_presets()
    _populate_impact_options()

    distance_slider.value_changed.connect(_on_distance_changed)
    loop_interval_slider.value_changed.connect(_on_interval_changed)
    vfx_list.item_selected.connect(_on_vfx_selected)
    fire_now_button.pressed.connect(_fire_now)
    reload_button.pressed.connect(_reload)
    animate_check.toggled.connect(_on_animate_toggled)

    team_check.toggled.connect( func(_b): _update_live_positions();_fire_now())
    unique_check.toggled.connect( func(_b): _update_live_positions();_fire_now())
    arena_drawer.draw.connect(_draw_arena)
    arena_drawer.resized.connect(_update_live_positions)



    impact_override_option.item_selected.connect(_on_impact_override_selected)
    clear_stains_button.pressed.connect(_on_clear_stains)



    speed_025_button.pressed.connect(_set_speed.bind(0.25))
    speed_05_button.pressed.connect(_set_speed.bind(0.5))
    speed_1_button.pressed.connect(_set_speed.bind(1.0))
    speed_2_button.pressed.connect(_set_speed.bind(2.0))
    speed_4_button.pressed.connect(_set_speed.bind(4.0))

    _on_distance_changed(distance_slider.value)
    _on_interval_changed(loop_interval_slider.value)

    if _presets.size() > 0:
        vfx_list.select(0)
        _on_vfx_selected(0)
    else:
        status_label.text = "No .tres files found in %s" % PRESETS_DIR





    call_deferred("_update_live_positions")


func _process(delta: float) -> void :


    var scaled_delta: float = delta * _speed_multiplier
    _elapsed_since_fire += scaled_delta

    _global_elapsed += scaled_delta

    if animate_check.button_pressed:
        _animate_elapsed += scaled_delta





    _update_live_positions()



    _prune_pending_impacts()

    if _elapsed_since_fire >= loop_interval_slider.value:
        _fire_now()


    var window: float = _selected_vfx.lifetime_seconds if _selected_vfx else FALLBACK_VFX_WINDOW
    lifetime_bar.value = clampf(_elapsed_since_fire / window, 0.0, 1.0) * 100.0


    arena_drawer.queue_redraw()









func _load_presets() -> void :
    _presets.clear()
    _preset_paths.clear()

    var dir: = DirAccess.open(PRESETS_DIR)
    if dir == null:
        push_warning("VFXTester: could not open %s — does the folder exist?" % PRESETS_DIR)
        return

    dir.list_dir_begin()
    var fname: String = dir.get_next()
    while fname != "":
        if not dir.current_is_dir() and fname.ends_with(".tres"):
            var path: String = PRESETS_DIR + fname
            var res: Resource = load(path)
            if res is AttackVFX:
                _presets.append(res)
                _preset_paths.append(path)
        fname = dir.get_next()
    dir.list_dir_end()


func _populate_list() -> void :
    vfx_list.clear()
    for i in _presets.size():
        var path: String = _preset_paths[i]
        var basename: String = path.get_file().get_basename()
        var script: Script = _presets[i].get_script()

        var class_label: String = String(script.get_global_name()) if script else "AttackVFX"
        vfx_list.add_item("%s  (%s)" % [basename, class_label])






func _on_vfx_selected(idx: int) -> void :
    if idx < 0 or idx >= _presets.size():
        return
    _selected_vfx = _presets[idx]
    status_label.text = "Playing: %s" % _preset_paths[idx].get_file()


    _on_clear_stains()
    _fire_now()


func _on_distance_changed(value: float) -> void :
    distance_label.text = "Distance: %.1f units" % value
    _update_live_positions()


func _on_interval_changed(value: float) -> void :
    loop_interval_label.text = "Loop interval: %.2f s" % value


func _on_animate_toggled(enabled: bool) -> void :


    if enabled:
        _animate_elapsed = 0.0
    _update_live_positions()


func _set_speed(mult: float) -> void :
    _speed_multiplier = mult


func _fire_now() -> void :
    _elapsed_since_fire = 0.0
    _current_seed = randi()



    _fire_attacker_pos = _attacker_pos
    _fire_defender_pos = _defender_pos
    _bake_impact_fire()










func _bake_impact_fire() -> void :
    var impact_fx: HitImpactFX = _resolve_effective_impact_fx()
    _last_fire_impact_fx = impact_fx
    _update_impact_status_label()
    if impact_fx == null:
        return



    var landing_offset: float = 0.0
    if _selected_vfx != null:
        landing_offset = _selected_vfx.lifetime_seconds * _selected_vfx.impact_landing_progress



    var fire_entry: Dictionary = {
        "impact_fx": impact_fx, 
        "fire_time": _global_elapsed, 
        "landing_offset": landing_offset, 
        "atk_units": _screen_to_arena(_fire_attacker_pos), 
        "def_units": _screen_to_arena(_fire_defender_pos), 
        "seed": _current_seed, 
        "is_crit": crit_check.button_pressed, 
    }
    _pending_impacts.append(fire_entry)
    _bake_stains_for_fire(fire_entry)




func _prune_pending_impacts() -> void :
    var alive: Array[Dictionary] = []
    for entry in _pending_impacts:
        var impact_fx: HitImpactFX = entry["impact_fx"]
        var landed_at: float = entry["fire_time"] + entry["landing_offset"]


        var window_end: float = landed_at + impact_fx.lifetime_seconds + 0.05
        if _global_elapsed < window_end:
            alive.append(entry)
    _pending_impacts = alive









func _bake_stains_for_fire(entry: Dictionary) -> void :
    var impact_fx: HitImpactFX = entry["impact_fx"]
    if impact_fx == null:
        return
    if impact_fx.decay_mode == HitImpactFX.DecayMode.FADE_WITH_PARTICLE:
        return

    var impact_tick_global: float = entry["fire_time"] + entry["landing_offset"]
    var stain_spawn_time: float = impact_tick_global + impact_fx.lifetime_seconds

    var atk_units: Vector2 = entry["atk_units"]
    var def_units: Vector2 = entry["def_units"]
    var attack_dir: Vector2 = (def_units - atk_units).normalized()
    if attack_dir.length_squared() < 0.001:
        attack_dir = Vector2(0, 1)
    var base_angle: float = attack_dir.angle() + impact_fx.direction_bias_radians

    var is_crit: bool = entry["is_crit"]
    var count: int = impact_fx.get_effective_particle_count(is_crit)
    var speed_max_eff: float = impact_fx.get_effective_speed_max(is_crit)



    var rng: = RandomNumberGenerator.new()
    rng.seed = hash([entry["seed"], int(entry["fire_time"] * 1000.0)])

    for _i in count:
        var spread: float = rng.randf_range(
            - impact_fx.angle_spread_radians / 2.0, 
            impact_fx.angle_spread_radians / 2.0, 
        )
        var angle: float = base_angle + spread
        var speed: float = rng.randf_range(impact_fx.speed_min, speed_max_eff)
        var velocity: = Vector2(cos(angle), sin(angle)) * speed
        var t: float = impact_fx.lifetime_seconds
        var final_pos: Vector2 = def_units + velocity * t + Vector2(0, 0.5 * impact_fx.gravity * t * t)
        var stain_radius: float = rng.randf_range(impact_fx.particle_radius_min, impact_fx.particle_radius_max)
        _impact_stains_tester.append({
            "spawn_time": stain_spawn_time, 
            "pos_units": final_pos, 
            "color": impact_fx.color_outer, 
            "radius_px": stain_radius, 
            "decay_mode": impact_fx.decay_mode, 
        })


    if _impact_stains_tester.size() > MAX_TESTER_STAINS:
        _impact_stains_tester = _impact_stains_tester.slice(_impact_stains_tester.size() - MAX_TESTER_STAINS)





func _resolve_effective_impact_fx() -> HitImpactFX:
    if _selected_impact_override != null:
        return _selected_impact_override
    if _selected_vfx != null and _selected_vfx.impact_fx != null:
        return _selected_vfx.impact_fx
    return DEFAULT_IMPACT_FX





func _screen_to_arena(screen_pos: Vector2) -> Vector2:
    if _arena_scale_px_per_unit <= 0.0:
        return Vector2.ZERO
    return (screen_pos - _arena_screen_offset) / _arena_scale_px_per_unit


func _reload() -> void :
    _load_presets()
    _populate_list()

    _load_impact_presets()
    _populate_impact_options()
    _on_clear_stains()
    _selected_vfx = null
    if _presets.size() > 0:
        vfx_list.select(0)
        _on_vfx_selected(0)
    else:
        status_label.text = "No .tres files found in %s" % PRESETS_DIR













func _update_live_positions() -> void :

    var view_size: Vector2 = arena_drawer.size
    _arena_scale_px_per_unit = min(
            view_size.x / VIRTUAL_ARENA_WIDTH, 
            view_size.y / VIRTUAL_ARENA_HEIGHT, 
    )
    _arena_size_screen = Vector2(
            VIRTUAL_ARENA_WIDTH * _arena_scale_px_per_unit, 
            VIRTUAL_ARENA_HEIGHT * _arena_scale_px_per_unit, 
    )
    _arena_screen_offset = (view_size - _arena_size_screen) * 0.5


    var arena_centre: = Vector2(VIRTUAL_ARENA_WIDTH * 0.5, VIRTUAL_ARENA_HEIGHT * 0.5)
    var half_dist: float = distance_slider.value * 0.5
    var rest_atk_units: Vector2 = arena_centre - Vector2(half_dist, 0.0)
    var rest_def_units: Vector2 = arena_centre + Vector2(half_dist, 0.0)



    if animate_check and animate_check.button_pressed:
        var amp: float = 2.0
        var t: float = _animate_elapsed
        rest_atk_units += Vector2(
                cos(t * 1.5) * amp, 
                sin(t * 2.1) * amp * 0.5, 
        )
        rest_def_units += Vector2(
                cos(t * 1.2 + 1.7) * amp, 
                sin(t * 1.8 + 0.3) * amp * 0.5, 
        )

    _attacker_pos = _arena_to_screen(rest_atk_units)
    _defender_pos = _arena_to_screen(rest_def_units)
    arena_drawer.queue_redraw()



func _arena_to_screen(arena_pos: Vector2) -> Vector2:
    return _arena_screen_offset + arena_pos * _arena_scale_px_per_unit


func _draw_arena() -> void :


    arena_drawer.draw_rect(Rect2(Vector2.ZERO, arena_drawer.size), PANEL_BG, true)


    arena_drawer.draw_rect(Rect2(_arena_screen_offset, _arena_size_screen), 
            PLAYBACK_ARENA_BG, true)
    arena_drawer.draw_rect(Rect2(_arena_screen_offset, _arena_size_screen), 
            PLAYBACK_ARENA_BORDER, false, 2.0)



    _draw_impact_stains_tester()




    var atk_radius: float
    var def_radius: float
    var atk_color: Color
    var def_color: Color
    if team_check.button_pressed:

        atk_radius = PLAYBACK_ENEMY_CIRCLE_RADIUS
        atk_color = PLAYBACK_ENEMY_COLOR
        def_radius = PLAYBACK_ALLY_CIRCLE_RADIUS
        def_color = PLAYBACK_ALLY_MELEE_COLOR
    else:
        atk_radius = PLAYBACK_ALLY_CIRCLE_RADIUS
        atk_color = PLAYBACK_ALLY_MELEE_COLOR
        def_radius = PLAYBACK_ENEMY_CIRCLE_RADIUS
        def_color = PLAYBACK_ENEMY_COLOR
    if unique_check.button_pressed:
        def_radius = PLAYBACK_UNIQUE_CIRCLE_RADIUS
        def_color = PLAYBACK_ENEMY_UNIQUE_COLOR
    arena_drawer.draw_circle(_attacker_pos, atk_radius, atk_color)
    arena_drawer.draw_circle(_defender_pos, def_radius, def_color)



    if _selected_vfx != null:


        var vfx_window: float = _selected_vfx.lifetime_seconds
        if _elapsed_since_fire < vfx_window:
            var ctx: = {
                "lifetime_progress": _elapsed_since_fire / vfx_window, 
                "weapon_range": TESTER_WEAPON_RANGE, 
                "arena_scale": _arena_scale_px_per_unit, 
                "def_radius": def_radius, 
                "color": _resolve_team_color(), 
                "crit": crit_check.button_pressed, 
                "seed": _current_seed, 
            }




            var def_for_vfx: Vector2 = _defender_pos if _selected_vfx.homes_on_target\
else _fire_defender_pos
            _selected_vfx.draw(arena_drawer, _fire_attacker_pos, def_for_vfx, ctx)



    _draw_impact_particles_tester()






func _resolve_team_color() -> Color:
    var base: Color
    if team_check.button_pressed:
        base = Color(1.0, 0.45, 0.4)
    else:
        base = Color(0.6, 1.0, 0.7)
    if crit_check.button_pressed:
        base = base.lerp(Color(1.0, 0.85, 0.3), 0.5)
    return base









func _load_impact_presets() -> void :
    _impact_presets.clear()
    _impact_preset_paths.clear()

    var dir: = DirAccess.open(IMPACT_PRESETS_DIR)
    if dir == null:
        push_warning("VFXTester: could not open %s — does the folder exist?" % IMPACT_PRESETS_DIR)
        return

    dir.list_dir_begin()
    var fname: String = dir.get_next()
    while fname != "":
        if not dir.current_is_dir() and fname.ends_with(".tres"):
            var path: String = IMPACT_PRESETS_DIR + fname
            var res: Resource = load(path)
            if res is HitImpactFX:
                _impact_presets.append(res)
                _impact_preset_paths.append(path)
        fname = dir.get_next()
    dir.list_dir_end()




func _populate_impact_options() -> void :
    impact_override_option.clear()
    impact_override_option.add_item("(use AttackVFX default)")



    impact_override_option.set_item_id(0, 0)
    for i in _impact_presets.size():
        var path: String = _impact_preset_paths[i]
        impact_override_option.add_item(path.get_file().get_basename())
        impact_override_option.set_item_id(i + 1, i + 1)
    impact_override_option.select(0)
    _selected_impact_override = null




func _on_impact_override_selected(idx: int) -> void :
    var id: int = impact_override_option.get_item_id(idx)
    if id == 0:
        _selected_impact_override = null
    else:
        var preset_idx: int = id - 1
        if preset_idx >= 0 and preset_idx < _impact_presets.size():
            _selected_impact_override = _impact_presets[preset_idx]
        else:
            _selected_impact_override = null
    _on_clear_stains()
    _fire_now()






func _on_clear_stains() -> void :
    _impact_stains_tester.clear()
    _pending_impacts.clear()
    arena_drawer.queue_redraw()





func _update_impact_status_label() -> void :
    if impact_status_label == null:
        return
    if _last_fire_impact_fx == null:
        impact_status_label.text = "No impact FX active."
        return
    var src: String = "override"
    if _selected_impact_override == null:
        if _selected_vfx != null and _selected_vfx.impact_fx != null:
            src = "from AttackVFX"
        else:
            src = "global default"
    var lock_str: String = "ON" if _last_fire_impact_fx.lock_to_target else "OFF"
    impact_status_label.text = "Impact: %s\nDecay: %s, Style: %s\nLock to target: %s" % [
        src, 
        HitImpactFX.DecayMode.keys()[_last_fire_impact_fx.decay_mode], 
        HitImpactFX.ParticleStyle.keys()[_last_fire_impact_fx.particle_style], 
        lock_str, 
    ]










func _draw_impact_stains_tester() -> void :
    for stain in _impact_stains_tester:
        var age: float = _global_elapsed - stain["spawn_time"]
        if age < 0.0:
            continue
        var alpha_mult: float = 1.0
        if stain["decay_mode"] == HitImpactFX.DecayMode.BRIEF_GROUND_STAIN:
            if age > HitImpactFX.BRIEF_STAIN_LIFETIME:
                continue
            alpha_mult = 1.0 - age / HitImpactFX.BRIEF_STAIN_LIFETIME
        var screen_pos: = _arena_to_screen(stain["pos_units"])
        var base_color: Color = stain["color"]
        var draw_color: = Color(base_color.r, base_color.g, base_color.b, base_color.a * alpha_mult)
        arena_drawer.draw_circle(screen_pos, stain["radius_px"], draw_color)




















func _draw_impact_particles_tester() -> void :
    for entry in _pending_impacts:
        var impact_fx: HitImpactFX = entry["impact_fx"]
        if impact_fx == null:
            continue
        var impact_tick_global: float = entry["fire_time"] + entry["landing_offset"]
        var age: float = _global_elapsed - impact_tick_global
        if age < 0.0 or age >= impact_fx.lifetime_seconds:
            continue

        var def_units: Vector2 = entry["def_units"]
        var atk_units: Vector2 = entry["atk_units"]

        var anchor_units: Vector2 = def_units
        if impact_fx.lock_to_target:
            anchor_units = _screen_to_arena(_defender_pos)

        var attack_dir: Vector2 = (anchor_units - atk_units).normalized()
        if attack_dir.length_squared() < 0.001:
            attack_dir = Vector2(0, 1)

        _render_impact_burst_tester(entry, impact_fx, anchor_units, attack_dir, age)






func _render_impact_burst_tester(entry: Dictionary, impact_fx: HitImpactFX, def_pos_units: Vector2, attack_dir: Vector2, age: float) -> void :
    var is_crit: bool = entry["is_crit"]
    var count: int = impact_fx.get_effective_particle_count(is_crit)
    var speed_max_eff: float = impact_fx.get_effective_speed_max(is_crit)
    var color_inner_eff: Color = impact_fx.get_effective_color_inner(is_crit)
    var base_angle: float = attack_dir.angle() + impact_fx.direction_bias_radians

    var rng: = RandomNumberGenerator.new()
    rng.seed = hash([entry["seed"], int(entry["fire_time"] * 1000.0)])

    var fade: float = age / impact_fx.lifetime_seconds
    var particle_color: Color = color_inner_eff.lerp(impact_fx.color_outer, fade)



    if impact_fx.particle_style == HitImpactFX.ParticleStyle.STATIC_ARC:
        _render_static_arc_burst_tester(impact_fx, def_pos_units, rng, 
                count, color_inner_eff, age)
        return

    for _i in count:
        var spread: float = rng.randf_range(
            - impact_fx.angle_spread_radians / 2.0, 
            impact_fx.angle_spread_radians / 2.0, 
        )
        var angle: float = base_angle + spread
        var speed: float = rng.randf_range(impact_fx.speed_min, speed_max_eff)
        var velocity: = Vector2(cos(angle), sin(angle)) * speed
        var pos_units: Vector2 = def_pos_units + velocity * age + Vector2(0, 0.5 * impact_fx.gravity * age * age)
        var radius_px: float = rng.randf_range(impact_fx.particle_radius_min, impact_fx.particle_radius_max)

        var curl_phase: float = rng.randf_range(0.0, TAU) if impact_fx.particle_style == HitImpactFX.ParticleStyle.CURL else 0.0
        if impact_fx.particle_style == HitImpactFX.ParticleStyle.CURL:
            var perp: = Vector2( - velocity.y, velocity.x).normalized()
            var curl_offset: float = sin(impact_fx.curl_frequency * age + curl_phase) * impact_fx.curl_amplitude
            pos_units += perp * curl_offset

        var screen_pos: = _arena_to_screen(pos_units)

        match impact_fx.particle_style:
            HitImpactFX.ParticleStyle.DOT:
                _draw_particle_dot_tester(screen_pos, radius_px, particle_color, impact_fx.glow)
            HitImpactFX.ParticleStyle.STREAK:
                var streak_dt: float = minf(0.06, age)
                var past_age: float = age - streak_dt
                var past_pos_units: Vector2 = def_pos_units + velocity * past_age + Vector2(0, 0.5 * impact_fx.gravity * past_age * past_age)
                var past_screen: = _arena_to_screen(past_pos_units)
                _draw_particle_streak_tester(past_screen, screen_pos, radius_px, particle_color, impact_fx.glow)
            HitImpactFX.ParticleStyle.CURL:
                _draw_particle_curl_tester(impact_fx, def_pos_units, velocity, curl_phase, age, particle_color, radius_px)






func _render_static_arc_burst_tester(
    impact_fx: HitImpactFX, 
    anchor_units: Vector2, 
    rng: RandomNumberGenerator, 
    count: int, 
    color_inner_eff: Color, 
    age: float, 
) -> void :
    var lifetime: float = impact_fx.lifetime_seconds
    var flash: float = impact_fx.arc_flash_duration if impact_fx.arcs_sequenced else lifetime

    for i in count:

        var arc_angle: float = rng.randf_range(0.0, TAU)
        var arc_distance: float = rng.randf_range(
            impact_fx.arc_endpoint_distance_min, 
            impact_fx.arc_endpoint_distance_max, 
        )
        var jitter_seed: int = rng.randi()
        var branch_seed: int = rng.randi()

        var window_start: float = 0.0
        if impact_fx.arcs_sequenced and count > 1:
            window_start = (float(i) / float(count - 1)) * max(0.0, lifetime - flash)
        var window_end: float = window_start + flash
        if age < window_start or age >= window_end:
            continue

        var local_age: float = age - window_start
        var alpha: float = sin(local_age / flash * PI)
        var arc_color: = Color(
            color_inner_eff.r, color_inner_eff.g, color_inner_eff.b, 
            color_inner_eff.a * alpha, 
        )

        var endpoint_units: Vector2 = anchor_units + Vector2(cos(arc_angle), sin(arc_angle)) * arc_distance
        var anchor_screen: Vector2 = _arena_to_screen(anchor_units)
        var endpoint_screen: Vector2 = _arena_to_screen(endpoint_units)

        var arc_points: PackedVector2Array = _build_arc_polyline_tester(
            anchor_screen, endpoint_screen, 
            impact_fx.arc_segments, impact_fx.arc_jitter, jitter_seed, 
        )
        _draw_arc_polyline_tester(arc_points, impact_fx.arc_stroke_width, arc_color, impact_fx.glow)

        if impact_fx.arc_branch_count > 0:
            var branch_rng: = RandomNumberGenerator.new()
            branch_rng.seed = branch_seed
            var mid_idx: int = arc_points.size() / 2
            var branch_start: Vector2 = arc_points[mid_idx]
            for b in impact_fx.arc_branch_count:
                var branch_angle: float = arc_angle + branch_rng.randf_range( - PI * 0.35, PI * 0.35)
                var branch_dist: float = arc_distance * branch_rng.randf_range(0.4, 0.75)
                var branch_end_units: Vector2 = anchor_units + Vector2(cos(branch_angle), sin(branch_angle)) * branch_dist
                var branch_end_screen: Vector2 = _arena_to_screen(branch_end_units)
                var branch_segments: int = maxi(3, impact_fx.arc_segments / 2)
                var branch_points: PackedVector2Array = _build_arc_polyline_tester(
                    branch_start, branch_end_screen, 
                    branch_segments, impact_fx.arc_jitter * 1.4, 
                    branch_seed + b * 17 + 1, 
                )
                _draw_arc_polyline_tester(
                    branch_points, 
                    impact_fx.arc_stroke_width * 0.7, arc_color, impact_fx.glow, 
                )


func _build_arc_polyline_tester(start: Vector2, end: Vector2, segments: int, jitter_frac: float, jitter_seed: int) -> PackedVector2Array:
    var points: = PackedVector2Array()
    var diff: Vector2 = end - start
    var arc_length: float = diff.length()
    if arc_length < 0.001:
        points.append(start)
        points.append(end)
        return points
    var perp: Vector2 = diff.orthogonal().normalized()

    var rng: = RandomNumberGenerator.new()
    rng.seed = jitter_seed

    for i in segments + 1:
        var t: float = float(i) / float(segments)
        var base: Vector2 = start.lerp(end, t)
        var taper: float = sin(t * PI)
        var offset_amount: float = rng.randf_range(-1.0, 1.0) * jitter_frac * arc_length * taper
        points.append(base + perp * offset_amount)
    return points


func _draw_arc_polyline_tester(points: PackedVector2Array, width: float, color: Color, glow: bool) -> void :
    if points.size() < 2:
        return
    if glow:
        var halo_color: = Color(color.r, color.g, color.b, color.a * 0.45)
        for i in range(points.size() - 1):
            arena_drawer.draw_line(points[i], points[i + 1], halo_color, width * 2.4)
    for i in range(points.size() - 1):
        arena_drawer.draw_line(points[i], points[i + 1], color, width)



func _draw_particle_dot_tester(screen_pos: Vector2, radius_px: float, color: Color, glow: bool) -> void :
    if glow:
        var halo_color: = Color(color.r, color.g, color.b, color.a * 0.45)
        arena_drawer.draw_circle(screen_pos, radius_px * 2.4, halo_color)
    arena_drawer.draw_circle(screen_pos, radius_px, color)



func _draw_particle_streak_tester(past_pos: Vector2, head_pos: Vector2, radius_px: float, color: Color, glow: bool) -> void :
    if glow:
        var halo_color: = Color(color.r, color.g, color.b, color.a * 0.4)
        arena_drawer.draw_line(past_pos, head_pos, halo_color, radius_px * 2.4)
    arena_drawer.draw_line(past_pos, head_pos, color, radius_px)
    arena_drawer.draw_circle(head_pos, radius_px * 0.7, color)



func _draw_particle_curl_tester(
    impact_fx: HitImpactFX, 
    def_pos_units: Vector2, 
    velocity: Vector2, 
    curl_phase: float, 
    age: float, 
    color: Color, 
    radius_px: float, 
) -> void :
    var sample_count: int = 8
    var trail_span: float = minf(0.12, age)
    var perp: = Vector2( - velocity.y, velocity.x).normalized()

    var points: = PackedVector2Array()
    for i in sample_count:
        var sample_age: float = age - (trail_span * float(i) / float(sample_count - 1))
        if sample_age < 0.0:
            sample_age = 0.0
        var base_pos: Vector2 = def_pos_units + velocity * sample_age + Vector2(0, 0.5 * impact_fx.gravity * sample_age * sample_age)
        var curl_offset: float = sin(impact_fx.curl_frequency * sample_age + curl_phase) * impact_fx.curl_amplitude
        base_pos += perp * curl_offset
        points.append(_arena_to_screen(base_pos))

    for i in range(sample_count - 1):
        var t: float = float(i) / float(sample_count - 1)
        var seg_alpha: float = (1.0 - t) * color.a
        var seg_color: = Color(color.r, color.g, color.b, seg_alpha)
        var seg_width: float = lerpf(radius_px, radius_px * 0.4, t)
        arena_drawer.draw_line(points[i], points[i + 1], seg_color, seg_width)
    arena_drawer.draw_circle(points[0], radius_px * 0.85, color)
