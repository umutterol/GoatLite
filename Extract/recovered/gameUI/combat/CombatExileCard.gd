class_name CombatExileCard
extends Control



































enum PopupSideMode{ALTERNATE, RIGHT_ONLY, LEFT_ONLY}









enum PopupAnchorMode{MOVING_END, BAR_CENTER}

@export_group("Popup Animation")

@export var popup_side_mode: PopupSideMode = PopupSideMode.ALTERNATE


@export var popup_anchor_mode: PopupAnchorMode = PopupAnchorMode.MOVING_END




@export_range(-100.0, 100.0, 1.0) var popup_spawn_y_offset_px: float = 0.0


@export_range(10, 200, 1) var popup_font_size_base: int = 52

@export_range(1.0, 3.0, 0.05) var popup_crit_scale_bonus: float = 1.5

@export_range(0.2, 3.0, 0.01) var popup_lifetime: float = 0.9


@export_range(10.0, 300.0, 1.0) var popup_drift_px: float = 70.0



@export_range(0.0, 200.0, 1.0) var popup_arc_bow_px: float = 65.0




@export_range(0.0, 1.0, 0.01) var popup_arc_upward_bias: float = 0.65




@export var popup_arc_inverted: bool = false




@export var popup_arc_flip_horizontal: bool = false


@export_range(0.0, 45.0, 0.5) var popup_exit_angle_base_deg: float = 8.0


@export_range(0.0, 45.0, 0.5) var popup_exit_angle_scatter_deg: float = 22.5

@export_range(1.0, 4.0, 0.05) var popup_punch_scale: float = 1.9

@export_range(1.0, 4.0, 0.05) var popup_punch_scale_crit: float = 2.4

@export_range(0.02, 0.5, 0.01) var popup_punch_seconds: float = 0.1


@export_range(0.0, 1.0, 0.01) var popup_hold_seconds: float = 0.22

@export_group("Bar Chunk Flash")

@export var bar_flash_color: Color = Color(1.0, 1.0, 1.0, 0.75)

@export var bar_flash_color_crit: Color = Color(1.0, 0.45, 0.25, 0.95)

@export_range(0.05, 1.0, 0.01) var bar_flash_seconds: float = 0.18

@export_range(1.0, 3.0, 0.05) var bar_chunk_scale_y: float = 1.45
@export_range(1.0, 3.0, 0.05) var bar_chunk_scale_y_crit: float = 1.8
@export_range(0.05, 1.0, 0.01) var bar_chunk_seconds: float = 0.22

@export_group("Popup Colours")

@export var popup_color_life: Color = Color(1.0, 0.45, 0.35)

@export var popup_color_morale: Color = Color(0.3, 0.7, 0.95)

@export var popup_color_vitality: Color = Color(0.95, 0.55, 0.15)


@export var popup_color_crit: Color = Color(1.0, 0.85, 0.3)


@onready var background_panel: Panel = %CardBackground
@onready var portrait_slot: ExilePortraitSlot = %CardPortrait
@onready var name_label: Label = %CardExileName
@onready var class_label: Label = %CardClassname
@onready var level_label: Label = %CardLvl
@onready var xp_bar: ProgressBar = %CardXPBar
@onready var xp_value_label: Label = %CardXPValueLabel
@onready var exile_bars: ExileBars = %CardExileBars
@onready var status_strip: HBoxContainer = %CardStatusStrip
@onready var high_morale_icon: MoraleStateIcon = %CardHighMoraleIcon
@onready var low_morale_icon: MoraleStateIcon = %CardLowMoraleIcon





@onready var ailment_strip: AilmentPanelStrip = %CardAilmentStrip

@onready var popup_layer: Control = %CardPopupLayer

var exile_data: ExileData = null











var _in_playback_mode: bool = false
var _playback_level: int = 1
var _playback_xp: int = 0



var _playback_xp_start: int = 0
var _playback_level_start: int = 1


const PLAYBACK_XP_TWEEN_SECONDS: float = 0.25


var _playback_xp_tween: Tween = null




var _popup_alternation: Dictionary = {}












var _active_status_icons: Dictionary = {}
var _active_status_overlays: Dictionary = {}
var _active_status_tints: Dictionary = {}







var _impale_overlay: Node2D = null



const IMPALE_VFX_SCENE: PackedScene = preload("res://systems/combat/vfx/persistentPresets/ImpaleSkewersVFX.tscn")







var _poison_overlay: Node2D = null
const POISON_VFX_SCENE: PackedScene = preload("res://systems/combat/vfx/persistentPresets/PoisonCloudVFX.tscn")






var _popup_overlay: Control = null



@export var popup_font: Font = null






func _ready() -> void :

    popup_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE


    exile_bars.set_value_labels_visible(true)



func setup(data: ExileData) -> void :
    exile_data = data


    _in_playback_mode = false
    if _playback_xp_tween and _playback_xp_tween.is_valid():
        _playback_xp_tween.kill()
    _playback_xp_tween = null
    if not is_node_ready():
        await ready
    _refresh_header()
    _refresh_bars_from_exile()
    _refresh_status_icons()








func setup_playback_xp(pre_combat_xp: int, pre_combat_level: int) -> void :
    _in_playback_mode = true
    _playback_xp_start = max(pre_combat_xp, 0)
    _playback_level_start = max(pre_combat_level, 1)
    _playback_xp = _playback_xp_start
    _playback_level = _playback_level_start
    if not is_node_ready():
        await ready
    level_label.text = "L%d" % _playback_level
    _refresh_playback_xp_display()






func reset_playback_xp_to_start() -> void :
    if not _in_playback_mode or not is_node_ready():
        return
    if _playback_xp_tween and _playback_xp_tween.is_valid():
        _playback_xp_tween.kill()
    _playback_xp_tween = null
    _playback_xp = _playback_xp_start
    _playback_level = _playback_level_start
    level_label.text = "L%d" % _playback_level
    _refresh_playback_xp_display()











func gain_xp(amount: int) -> void :
    if not _in_playback_mode or amount <= 0 or not is_node_ready():
        return
    if _playback_xp_tween and _playback_xp_tween.is_valid():
        _playback_xp_tween.kill()
    var target_xp: int = _playback_xp + amount
    _playback_xp = target_xp
    var exp_to_next: int = ExileData.exp_for_level(_playback_level)
    xp_bar.max_value = maxi(exp_to_next, 1)
    xp_value_label.text = "XP %d / %d" % [target_xp, exp_to_next]
    _playback_xp_tween = create_tween()
    _playback_xp_tween.tween_property(xp_bar, "value", float(target_xp), PLAYBACK_XP_TWEEN_SECONDS)\
.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)









func on_playback_level_up(new_level: int) -> void :
    if not _in_playback_mode or not is_node_ready():
        return

    if _playback_xp_tween and _playback_xp_tween.is_valid():
        _playback_xp_tween.kill()
    _playback_xp_tween = null




    var old_threshold: int = ExileData.exp_for_level(_playback_level)
    _playback_xp = max(_playback_xp - old_threshold, 0)
    _playback_level = new_level
    level_label.text = "L%d" % _playback_level
    _refresh_playback_xp_display()




func _refresh_playback_xp_display() -> void :
    var exp_to_next: int = ExileData.exp_for_level(_playback_level)
    xp_bar.max_value = maxi(exp_to_next, 1)
    xp_bar.value = float(_playback_xp)
    xp_value_label.text = "XP %d / %d" % [_playback_xp, exp_to_next]





func set_popup_overlay(overlay: Control) -> void :
    _popup_overlay = overlay





func refresh_from_snapshot(
        life: float, max_life: float, 
        vitality: float, max_vitality: float, 
        morale: float, max_morale: float) -> void :
    if not is_node_ready():
        return
    exile_bars.populate_from_snapshot({
        "life": life, 
        "max_life": max_life, 
        "vitality": vitality, 
        "max_vitality": max_vitality, 
        "morale": morale, 
        "max_morale": max_morale, 
    })








func refresh_ailment_strip(state: Dictionary, current_tick: float) -> void :
    if not is_node_ready():
        return
    if ailment_strip == null:
        return
    ailment_strip.refresh_from_state(state, current_tick)









func pop_damage(amount: float, kind: String, is_crit: bool) -> void :
    if not is_node_ready():
        return
    var rounded: int = int(round(amount))
    if rounded <= 0:
        return

    var color: Color = _popup_color_for_kind(kind, is_crit)
    var bar: ProgressBar = _bar_for_kind(kind)
    if bar == null:
        return
    var bar_rect_in_card: Rect2 = _bar_rect_for_kind(kind)
    if bar_rect_in_card.size == Vector2.ZERO:
        return

    var popup: = Label.new()
    popup.text = "-%d" % rounded
    popup.add_theme_color_override("font_color", color)
    popup.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
    popup.add_theme_constant_override("outline_size", 4)
    var font_size: int = popup_font_size_base
    if is_crit:
        font_size = int(popup_font_size_base * popup_crit_scale_bonus)
    popup.add_theme_font_size_override("font_size", font_size)
    if popup_font != null:
        popup.add_theme_font_override("font", popup_font)
    popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    popup.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


    popup.mouse_filter = Control.MOUSE_FILTER_IGNORE



    var spawn_parent: Control = _popup_overlay if _popup_overlay != null else popup_layer
    spawn_parent.add_child(popup)



    popup.reset_size()
    popup.pivot_offset = popup.size / 2.0







    var anchor_card_local: Vector2 = _resolve_bar_anchor(bar, bar_rect_in_card)
    var anchor_global: Vector2 = global_position + anchor_card_local
    var anchor_in_parent: Vector2 = anchor_global - spawn_parent.global_position
    popup.position = anchor_in_parent - popup.size * 0.5

    popup.position.y += popup_spawn_y_offset_px



    var scatter_x: float = randf_range(-5.0, 5.0)
    popup.position.x += scatter_x





    var alt_idx: int = _popup_alternation.get(kind, 0)
    var direction: int = _resolve_popup_direction(alt_idx)
    _popup_alternation[kind] = alt_idx + 1

    _animate_popup(popup, is_crit, direction)
    chunk_bar(kind, is_crit)





func _resolve_popup_direction(alt_idx: int) -> int:
    match popup_side_mode:
        PopupSideMode.RIGHT_ONLY:
            return 1
        PopupSideMode.LEFT_ONLY:
            return -1
        PopupSideMode.ALTERNATE:
            return 1 if (alt_idx % 2 == 0) else -1
    return 1










func _resolve_bar_anchor(bar: ProgressBar, bar_rect_in_card: Rect2) -> Vector2:
    var centre: Vector2 = bar_rect_in_card.position + bar_rect_in_card.size * 0.5
    if popup_anchor_mode == PopupAnchorMode.BAR_CENTER:
        return centre
    if bar.max_value <= 0.0:
        return centre
    var ratio: float = clampf(bar.value / bar.max_value, 0.0, 1.0)
    var anchor: Vector2 = centre



    match bar.fill_mode:
        ProgressBar.FILL_BEGIN_TO_END:
            anchor.x = bar_rect_in_card.position.x + bar_rect_in_card.size.x * ratio
        ProgressBar.FILL_END_TO_BEGIN:
            anchor.x = bar_rect_in_card.position.x + bar_rect_in_card.size.x * (1.0 - ratio)
        ProgressBar.FILL_TOP_TO_BOTTOM:
            anchor.y = bar_rect_in_card.position.y + bar_rect_in_card.size.y * ratio
        ProgressBar.FILL_BOTTOM_TO_TOP:
            anchor.y = bar_rect_in_card.position.y + bar_rect_in_card.size.y * (1.0 - ratio)
    return anchor




func chunk_bar(kind: String, is_crit: bool) -> void :
    if not is_node_ready():
        return
    var bar: ProgressBar = _bar_for_kind(kind)
    if bar == null:
        return


    bar.pivot_offset = Vector2(bar.size.x * 0.5, bar.size.y * 0.5)
    var target_scale_y: float = bar_chunk_scale_y_crit if is_crit else bar_chunk_scale_y
    var scale_tween: Tween = create_tween()
    scale_tween.tween_property(bar, "scale", Vector2(1.0, target_scale_y), bar_chunk_seconds * 0.4)
    scale_tween.tween_property(bar, "scale", Vector2.ONE, bar_chunk_seconds * 0.6)


    var flash_color: Color = bar_flash_color_crit if is_crit else bar_flash_color
    var original_modulate: Color = bar.modulate
    var flash_tween: Tween = create_tween()
    flash_tween.tween_property(bar, "modulate", flash_color, bar_flash_seconds * 0.4)
    flash_tween.tween_property(bar, "modulate", original_modulate, bar_flash_seconds * 0.6)






func _refresh_header() -> void :
    if exile_data == null:
        return
    name_label.text = exile_data.name
    var class_text: String = exile_data.class_definition.name if exile_data.class_definition else exile_data.class_id
    class_label.text = class_text
    level_label.text = "L%d" % exile_data.level
    portrait_slot.paint_exile(exile_data)


func _refresh_bars_from_exile() -> void :
    if exile_data == null:
        return


    var exp_to_next: int = exile_data.get_exp_for_next_level()
    xp_bar.max_value = maxi(exp_to_next, 1)
    xp_bar.value = exile_data.experience
    xp_value_label.text = "XP %d / %d" % [exile_data.experience, exp_to_next]
    exile_bars.populate_from_exile(exile_data)


func _refresh_status_icons() -> void :


    high_morale_icon.bind(exile_data)
    low_morale_icon.bind(exile_data)














func _animate_popup(popup: Label, is_crit: bool, direction: int) -> void :
    var punch_scale: float = popup_punch_scale_crit if is_crit else popup_punch_scale

    popup.scale = Vector2(punch_scale * 0.45, punch_scale * 0.45)
    popup.modulate.a = 1.0


    var anchor: Vector2 = popup.position




    var scale_tween: Tween = popup.create_tween()
    scale_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
    scale_tween.tween_property(popup, "scale", 
        Vector2(punch_scale, punch_scale), popup_punch_seconds)
    scale_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
    scale_tween.tween_property(popup, "scale", Vector2.ONE, popup_hold_seconds)


    var exit_delay: float = popup_punch_seconds + popup_hold_seconds
    var exit_duration: float = maxf(popup_lifetime - exit_delay, 0.01)


    var seed_value: float = anchor.x + Time.get_ticks_msec() * 0.001



    var arc_tween: Tween = popup.create_tween()
    arc_tween.tween_interval(exit_delay)
    arc_tween.tween_method(
        _drive_popup_arc.bind(popup, anchor, direction, seed_value), 
        0.0, 1.0, exit_duration, 
    ).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)



    var fade_tween: Tween = popup.create_tween()
    fade_tween.tween_interval(exit_delay)
    fade_tween.tween_property(popup, "modulate:a", 0.0, exit_duration)\
.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    fade_tween.tween_callback(popup.queue_free)








func _drive_popup_arc(t: float, popup: Label, anchor: Vector2, direction: int, seed_value: float) -> void :
    if not is_instance_valid(popup):
        return



    var vertical_sign: float = 1.0 if popup_arc_inverted else -1.0
    var scatter_deg: float = fposmod(seed_value * 7.31, popup_exit_angle_scatter_deg)
    var lean_deg: float = popup_exit_angle_base_deg + scatter_deg
    var base_angle_deg: float = 90.0 * vertical_sign
    var angle_rad: float = deg_to_rad(base_angle_deg + float(direction) * lean_deg)
    var exit_dir: Vector2 = Vector2(cos(angle_rad), sin(angle_rad))
    var travel: Vector2 = exit_dir * (popup_drift_px * t)







    var horizontal_sign: float = -1.0 if popup_arc_flip_horizontal else 1.0
    var perp_outward: Vector2 = Vector2( - exit_dir.y, exit_dir.x) * float(direction) * horizontal_sign
    var bow_dir_raw: Vector2 = perp_outward * (1.0 - popup_arc_upward_bias)\
+ Vector2(0.0, vertical_sign) * popup_arc_upward_bias
    var bow_dir: Vector2 = bow_dir_raw.normalized()
    var bow_magnitude: float = sin(t * PI) * popup_arc_bow_px
    popup.position = anchor + travel + bow_dir * bow_magnitude




func _popup_color_for_kind(kind: String, is_crit: bool) -> Color:
    if is_crit:
        return popup_color_crit
    match kind:
        "life": return popup_color_life
        "morale": return popup_color_morale
        "vitality": return popup_color_vitality

    return Color.MAGENTA


func _bar_for_kind(kind: String) -> ProgressBar:
    match kind:
        "life": return exile_bars.life_bar
        "morale": return exile_bars.morale_bar
        "vitality": return exile_bars.vitality_bar
    return null




func _bar_rect_for_kind(kind: String) -> Rect2:
    var bar: ProgressBar = _bar_for_kind(kind)
    if bar == null:
        return Rect2()
    var top_left_in_card: Vector2 = bar.global_position - global_position
    return Rect2(top_left_in_card, bar.size)



























func apply_status_vfx(effect: StatusEffect) -> Node:
    if not is_node_ready():
        await ready
    if effect == null or effect.vfx == null:
        return null
    var key: StringName = effect.effect_id
    var vfx: PersistentVFX = effect.vfx


    if vfx.icon != null and not _active_status_icons.has(key):
        var icon_rect: = TextureRect.new()
        icon_rect.texture = vfx.icon
        icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        icon_rect.custom_minimum_size = Vector2(22, 22)


        icon_rect.mouse_filter = Control.MOUSE_FILTER_PASS
        var hover: = TooltipHover.new()


        hover.keyword = String(key)
        icon_rect.add_child(hover)
        status_strip.add_child(icon_rect)
        _active_status_icons[key] = icon_rect


    if vfx.overlay_scene != null and not _active_status_overlays.has(key):
        var overlay: Node = vfx.overlay_scene.instantiate()


        popup_layer.add_child(overlay)






        var portrait_centre: Vector2 = _portrait_centre_in_popup_layer()
        if overlay is Node2D:
            (overlay as Node2D).position = portrait_centre
        elif overlay is Control:
            (overlay as Control).position = portrait_centre - (overlay as Control).size * 0.5
        _active_status_overlays[key] = overlay


    if vfx.portrait_tint != Color.WHITE and not _active_status_tints.has(key):
        _active_status_tints[key] = vfx.portrait_tint
        _recompute_portrait_tint()





    if vfx.application_burst_scene != null:
        _spawn_burst(vfx.application_burst_scene)

    return _active_status_overlays.get(key, null)









func remove_status_vfx(effect_id: StringName, removal_burst_scene: PackedScene = null) -> void :
    if not is_node_ready():
        return

    if _active_status_overlays.has(effect_id):
        var overlay: Node = _active_status_overlays[effect_id]
        if is_instance_valid(overlay):
            overlay.queue_free()
        _active_status_overlays.erase(effect_id)

    if _active_status_icons.has(effect_id):
        var icon_rect: TextureRect = _active_status_icons[effect_id]
        if is_instance_valid(icon_rect):
            icon_rect.queue_free()
        _active_status_icons.erase(effect_id)

    if _active_status_tints.has(effect_id):
        _active_status_tints.erase(effect_id)
        _recompute_portrait_tint()

    if removal_burst_scene != null:
        _spawn_burst(removal_burst_scene)





func clear_all_status_vfx() -> void :
    if not is_node_ready():
        return
    for overlay in _active_status_overlays.values():
        if is_instance_valid(overlay):
            overlay.queue_free()
    _active_status_overlays.clear()
    for icon_rect in _active_status_icons.values():
        if is_instance_valid(icon_rect):
            icon_rect.queue_free()
    _active_status_icons.clear()
    _active_status_tints.clear()
    _recompute_portrait_tint()





func _recompute_portrait_tint() -> void :
    if portrait_slot == null:
        return
    var combined: Color = Color.WHITE
    for tint in _active_status_tints.values():
        combined = combined * tint
    portrait_slot.modulate = combined







func _spawn_burst(burst_scene: PackedScene) -> void :
    var burst: Node = burst_scene.instantiate()
    popup_layer.add_child(burst)


    get_tree().create_timer(3.0).timeout.connect(_force_free_burst.bind(burst))






func _force_free_burst(burst: Node) -> void :
    if is_instance_valid(burst):
        burst.queue_free()







func _portrait_centre_in_popup_layer() -> Vector2:
    if portrait_slot == null:
        return Vector2.ZERO
    return portrait_slot.position + portrait_slot.size * 0.5














func apply_impale_vfx(stacks_now: int) -> void :
    if not is_node_ready():
        await ready
    if _impale_overlay == null or not is_instance_valid(_impale_overlay):
        _impale_overlay = IMPALE_VFX_SCENE.instantiate() as Node2D
        popup_layer.add_child(_impale_overlay)
        _impale_overlay.position = _portrait_centre_in_popup_layer()
    if _impale_overlay.has_method("set_visible_count"):
        _impale_overlay.call("set_visible_count", stacks_now)





func play_impale_consume_vfx() -> void :
    if not is_node_ready():
        return
    if _impale_overlay == null or not is_instance_valid(_impale_overlay):
        return
    if _impale_overlay.has_method("play_consume_burst"):
        _impale_overlay.call("play_consume_burst")



    get_tree().create_timer(1.2).timeout.connect(_force_free_burst.bind(_impale_overlay))
    _impale_overlay = null




func clear_impale_vfx() -> void :
    if _impale_overlay != null and is_instance_valid(_impale_overlay):
        _impale_overlay.queue_free()
    _impale_overlay = null



















func apply_poison_vfx(stacks_now: int) -> void :
    if not is_node_ready():
        await ready
    if _poison_overlay == null or not is_instance_valid(_poison_overlay):
        _poison_overlay = POISON_VFX_SCENE.instantiate() as Node2D
        popup_layer.add_child(_poison_overlay)
        _poison_overlay.position = _portrait_centre_in_popup_layer()
    if _poison_overlay.has_method("set_visible_count"):
        _poison_overlay.call("set_visible_count", stacks_now)





func clear_poison_vfx() -> void :
    if _poison_overlay != null and is_instance_valid(_poison_overlay):
        _poison_overlay.queue_free()
    _poison_overlay = null
