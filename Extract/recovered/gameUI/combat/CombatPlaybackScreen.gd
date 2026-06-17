class_name CombatPlaybackScreen
extends Control








@export var ally_melee_color: Color = Color("#4aaa6a")
@export var ally_ranged_color: Color = Color("#3a8a5a")
@export var enemy_color: Color = Color("#993333")
@export var enemy_ranged_color: Color = Color("#884444")
@export var enemy_unique_color: Color = Color("#cc6622")
@export var arena_bg: Color = Color("140b03ff")

@export var arena_border: Color = Color("583824ff")
@export var targeting_ally: Color = Color(0.4, 0.78, 0.47, 0.5)
@export var targeting_enemy: Color = Color(0.86, 0.31, 0.31, 0.4)
@export var ally_circle_radius: float = 16.0
@export var enemy_circle_radius: float = 12.0
@export var unique_circle_radius: float = 22.0












@export_group("Dot Body")


@export_range(0.0, 1.0, 0.05) var dot_body_alpha: float = 0.6

@export_range(0.0, 12.0, 0.5) var dot_feather_px: float = 4.0

@export_range(0.0, 1.0, 0.05) var dot_feather_alpha_factor: float = 0.3

@export_group("Icon Orientation")


@export_range(0.0, 60.0, 1.0) var icon_max_tilt_deg: float = 20.0


@export_range(0.0, 2.0, 0.05) var exile_hand_offset_ratio: float = 0.9

@export_group("Monster Overflow")

@export_range(0.5, 5.0, 0.05) var monster_icon_overflow: float = 2.0

@export_group("Exile Weapon Overflow", "weapon_overflow_")
@export_range(0.5, 5.0, 0.05) var weapon_overflow_sword_1h: float = 1.5
@export_range(0.5, 5.0, 0.05) var weapon_overflow_sword_2h: float = 2.4
@export_range(0.5, 5.0, 0.05) var weapon_overflow_axe_1h: float = 1.5
@export_range(0.5, 5.0, 0.05) var weapon_overflow_axe_2h: float = 2.4
@export_range(0.5, 5.0, 0.05) var weapon_overflow_mace_1h: float = 1.5
@export_range(0.5, 5.0, 0.05) var weapon_overflow_mace_2h: float = 2.4
@export_range(0.5, 5.0, 0.05) var weapon_overflow_spear_1h: float = 1.5
@export_range(0.5, 5.0, 0.05) var weapon_overflow_spear_2h: float = 2.4
@export_range(0.5, 5.0, 0.05) var weapon_overflow_dagger: float = 1.3
@export_range(0.5, 5.0, 0.05) var weapon_overflow_wand: float = 1.6
@export_range(0.5, 5.0, 0.05) var weapon_overflow_staff: float = 2.4
@export_range(0.5, 5.0, 0.05) var weapon_overflow_bow: float = 2.4

@export_range(0.5, 5.0, 0.05) var weapon_overflow_default: float = 1.8

@export_group("Exile Offhand Overflow", "offhand_overflow_")
@export_range(0.5, 5.0, 0.05) var offhand_overflow_shield: float = 1.5
@export_range(0.5, 5.0, 0.05) var offhand_overflow_focus: float = 1.5
@export_range(0.5, 5.0, 0.05) var offhand_overflow_sceptre: float = 1.5

@export_range(0.5, 5.0, 0.05) var offhand_overflow_default: float = 1.5


const PLAY_ICON: Texture2D = preload("res://assets/ui/combatUiIcons/PlayIcon.tres")
const PAUSE_ICON: Texture2D = preload("res://assets/ui/combatUiIcons/PauseIcon.tres")

const SPEED_LEVELS: Array[float] = [0.5, 1.0, 2.0, 4.0]





const DROP_SPRITE_CHAOS: Texture2D = preload("res://assets/sprites/itemSprites/currencySprites/ChaosShardPhysical.png")
const DROP_SPRITE_SCRAP: Texture2D = preload("res://assets/sprites/itemSprites/currencySprites/ScrapPhysical.png")
const DROP_SPRITE_FOOD: Texture2D = preload("res://assets/sprites/itemSprites/currencySprites/food_icon.tres")
const DROP_SPRITE_EXALT: Texture2D = preload("res://assets/sprites/itemSprites/currencySprites/ExaltShardPhysical.png")
const DROP_SPRITE_VAAL: Texture2D = preload("res://assets/sprites/itemSprites/currencySprites/VaalIcon.png")




const DEFAULT_IMPACT_FX: HitImpactFX = preload("res://systems/combat/vfx/impactPresets/blood_default.tres")





const IMPALE_VFX_SCENE: PackedScene = preload("res://systems/combat/vfx/persistentPresets/ImpaleSkewersVFX.tscn")




const POISON_VFX_SCENE: PackedScene = preload("res://systems/combat/vfx/persistentPresets/PoisonCloudVFX.tscn")


const FALLBACK_VFX_LIFETIME: float = 0.4



const DROP_FLY_DURATION: float = 0.35


const DROP_PILE_CAP: int = 8

const DROP_PILE_FAN_RADIUS: float = 0.6

const DROP_ARC_HEIGHT: float = 1.4

const DROP_ITEM_RADIUS_PX: float = 4.5

const DROP_CURRENCY_SPRITE_PX: float = 16.0

const DROP_PREMIUM_BEAM_HEIGHT: float = 22.0




@onready var encounter_label: Label = %EncounterLabel


@onready var encounter_name_label: Label = %EncounterName
@onready var arena_drawer: Control = $MarginContainer / VBox / MainSplit / LeftColumn / ArenaPanel / ArenaDrawer
@onready var play_button: Button = $MarginContainer / VBox / MainSplit / LeftColumn / ControlsBar / PlayButton
@onready var reset_button: Button = $MarginContainer / VBox / MainSplit / LeftColumn / ControlsBar / ResetButton
@onready var back_button: Button = $MarginContainer / VBox / MainSplit / LeftColumn / ControlsBar / BackButton
@onready var forward_button: Button = $MarginContainer / VBox / MainSplit / LeftColumn / ControlsBar / ForwardButton
@onready var speed_05x: Button = $MarginContainer / VBox / MainSplit / LeftColumn / ControlsBar / Speed05x
@onready var speed_1x: Button = $MarginContainer / VBox / MainSplit / LeftColumn / ControlsBar / Speed1x
@onready var speed_2x: Button = $MarginContainer / VBox / MainSplit / LeftColumn / ControlsBar / Speed2x
@onready var speed_4x: Button = $MarginContainer / VBox / MainSplit / LeftColumn / ControlsBar / Speed4x



@onready var combat_end_banner: Button = %CombatEndBanner
@onready var hover_tooltip: PanelContainer = $HoverTooltip
@onready var hover_label: Label = $HoverTooltip / MarginContainer / HoverContent / HoverRow / HoverLabel
@onready var hover_weapon_icon: WeaponTypeIcon = %HoverWeaponIcon
@onready var hover_bars: ExileBars = %HoverBars
@onready var hover_description: Label = %HoverDescription




@onready var hover_ailment_strip: AilmentPanelStrip = %HoverAilmentStrip
@onready var damage_tooltip: NonKeywordTooltipPanel = %NonKeywordTooltipPanel
@onready var scrubber: HSlider = $MarginContainer / VBox / MainSplit / LeftColumn / ControlsBar / Scrubber
@onready var tick_label: Label = $MarginContainer / VBox / MainSplit / LeftColumn / ControlsBar / TickLabel
@onready var event_log_view: RichTextLabel = %EventLog


@onready var monster_damage_toggle: CheckBox = %MonsterDamageToggle
@onready var exile_damage_toggle: CheckBox = %ExileDamageToggle
@onready var crits_only_toggle: CheckBox = %NonCrits





@onready var combat_cards: Array[CombatExileCard] = [
    %CombatCard1 as CombatExileCard, 
    %CombatCard2 as CombatExileCard, 
    %CombatCard3 as CombatExileCard, 
    %CombatCard4 as CombatExileCard, 
    %CombatCard5 as CombatExileCard, 
]
@onready var playback_timer: Timer = $PlaybackTimer





@onready var card_popup_overlay: Control = %CardPopupOverlay


var _exile_id_to_card: Dictionary = {}


var _popped_event_ids: Dictionary = {}






var _popup_directions: Dictionary = {}














var _active_monster_overlays: Dictionary = {}



var _status_overlay_layer: Control = null














var _active_ambient_emitters: Dictionary = {}










var _active_status_tints_by_combatant: Dictionary = {}







var _active_impale_overlays: Dictionary = {}






var _active_poison_overlays: Dictionary = {}





























var _playback_ailment_state: Dictionary = {}
















static var sandbox_payload: Dictionary = {}
signal sandbox_continue_pressed
var _is_sandbox: bool = false






const ATTACK_VISUAL_TAIL_DURATION: float = 1.5





















enum PopupSideMode{ALTERNATE, RIGHT_ONLY, LEFT_ONLY}

@export_group("Damage Popup — Motion")

@export var popup_side_mode: PopupSideMode = PopupSideMode.ALTERNATE




@export_range(0.0, 80.0, 1.0) var popup_spawn_above_dot_px: float = 14.0



@export_range(0.2, 3.0, 0.01) var popup_lifetime: float = 0.9

@export_range(0.02, 0.5, 0.01) var popup_pop_in_seconds: float = 0.1

@export_range(0.0, 1.0, 0.01) var popup_hold_seconds: float = 0.22


@export_range(1.0, 3.0, 0.05) var popup_overshoot_scale: float = 1.25

@export_range(0.1, 1.0, 0.05) var popup_start_scale: float = 0.55


@export_range(20.0, 300.0, 1.0) var popup_rise_px: float = 95.0




@export_range(0.0, 200.0, 1.0) var popup_arc_bow_px: float = 70.0




@export_range(0.0, 1.0, 0.01) var popup_arc_upward_bias: float = 0.65




@export var popup_arc_inverted: bool = false




@export var popup_arc_flip_horizontal: bool = false


@export_range(0.0, 45.0, 0.5) var popup_exit_angle_base_deg: float = 8.0



@export_range(0.0, 45.0, 0.5) var popup_exit_angle_scatter_deg: float = 22.5

@export_group("Damage Popup — Size")


@export_range(0.5, 6.0, 0.05) var popup_damage_font_radius_mult: float = 2.34


@export_range(10.0, 120.0, 1.0) var popup_damage_font_min: float = 39.6


@export_range(1.0, 3.0, 0.05) var popup_damage_crit_scale: float = 1.4


@export_range(0.5, 6.0, 0.05) var popup_heal_font_radius_mult: float = 1.89

@export_range(10.0, 120.0, 1.0) var popup_heal_font_min: float = 32.4

@export_group("End Banner Glow")



@export_range(0.0, 40.0, 0.5) var banner_glow_min_px: float = 1.0



@export_range(0.0, 80.0, 0.5) var banner_glow_max_px: float = 4.0


@export_range(0.2, 5.0, 0.05) var banner_glow_pulse_seconds: float = 2.2


var combat_result: CombatResultData = null

var current_sim_time: float = 0.0

var current_tick_idx: int = 0
var playing: bool = false
var speed_multiplier: float = 0.5


var _runner: MissionRunner = null
var _active_mission: ActiveMission = null


var _recent_hits: Array[Dictionary] = []




var _banner_glow_tween: Tween = null





var _visual_tail_seconds: float = ATTACK_VISUAL_TAIL_DURATION














var _drops: Array[Dictionary] = []


var _drop_overflow_labels: Array[Dictionary] = []











var _impact_stains: Array[Dictionary] = []



var _events_by_meta: Dictionary = {}
var _next_meta_id: int = 0




var _alt_held: bool = false






func _ready() -> void :



    _connect_card_ailment_signals()




    if not sandbox_payload.is_empty():
        _is_sandbox = true
        _connect_signals()
        _load_sandbox_result()
        return






    ToastManager.suspend()




    EventRecruitController.suspend()

    _runner = _resolve_runner()
    if not _runner:
        push_error("CombatPlaybackScreen: no active runner found")
        return

    _active_mission = _runner.active_mission
    _connect_signals()


    if _runner.last_combat_result == null:
        _runner.step_next_encounter()

    _load_current_result()






func _load_sandbox_result() -> void :
    combat_result = sandbox_payload.get("combat_result")
    if not combat_result:
        push_warning("CombatPlaybackScreen: sandbox payload has no combat_result")
        return

    current_tick_idx = 0
    playing = false
    _recent_hits.clear()
    _clear_log()
    _visual_tail_seconds = _compute_visual_tail()
    _build_drop_visuals()
    _build_impact_stains()
    _build_popup_directions()
    _populate_combat_cards_from_combat_result()



    var label_text: String = sandbox_payload.get("encounter_label", "Sandbox Combat")
    encounter_name_label.text = label_text
    encounter_label.text = ""

    var max_idx: int = max(0, combat_result.snapshots.size() - 1)
    scrubber.min_value = 0
    scrubber.max_value = max_idx
    scrubber.value = 0




    _set_outcome_banner_content()
    if sandbox_payload.has("continue_text"):
        combat_end_banner.text = String(sandbox_payload["continue_text"])
    _set_banner_visible(false)

    current_sim_time = 0.0
    _apply_user_preferences()
    _update_play_icon()
    _update_tick_label()
    _update_end_state()
    arena_drawer.queue_redraw()
















func _populate_combat_cards_from_runner() -> void :
    _exile_id_to_card.clear()
    if _active_mission == null:
        return
    var party_ids: Array[int] = _active_mission.assigned_exile_ids
    for i in range(combat_cards.size()):
        var card: CombatExileCard = combat_cards[i]
        if i >= party_ids.size():
            card.visible = false
            continue
        var exile: ExileData = GameState.get_exile_by_id(party_ids[i])
        if exile == null:
            card.visible = false
            continue
        card.visible = true
        card.setup(exile)
        card.set_popup_overlay(card_popup_overlay)
        _exile_id_to_card[exile.id] = card



        var combatant: CombatantData = _find_combatant_for_exile(exile.id)
        if combatant != null:
            card.setup_playback_xp(combatant.xp_at_combat_start, combatant.level_at_combat_start)










func _populate_combat_cards_from_combat_result() -> void :
    _exile_id_to_card.clear()
    if combat_result == null:
        return
    var slot: int = 0
    for c in combat_result.combatants:
        if slot >= combat_cards.size():
            break
        if c.team != CombatEnums.CombatantTeam.EXILES or c.source_exile == null:
            continue
        var card: CombatExileCard = combat_cards[slot]
        card.visible = true
        card.setup(c.source_exile)
        card.set_popup_overlay(card_popup_overlay)
        _exile_id_to_card[c.source_exile.id] = card
        card.setup_playback_xp(c.xp_at_combat_start, c.level_at_combat_start)
        slot += 1

    for j in range(slot, combat_cards.size()):
        combat_cards[j].visible = false





func _find_combatant_for_exile(exile_id: int) -> CombatantData:
    if combat_result == null:
        return null
    for c in combat_result.combatants:
        if c.team == CombatEnums.CombatantTeam.EXILES and c.source_exile != null and c.source_exile.id == exile_id:
            return c
    return null




func _card_for_combatant(c: CombatantData) -> CombatExileCard:
    if c == null or c.source_exile == null:
        return null
    return _exile_id_to_card.get(c.source_exile.id, null)








func _refresh_cards_from_snapshot(positions: Array) -> void :
    if _exile_id_to_card.is_empty():
        return





    var current_tick: float = current_sim_time
    for entry in positions:
        var combatant_id: int = entry.get("id", -1)
        if combatant_id < 0 or combatant_id >= combat_result.combatants.size():
            continue
        var c: CombatantData = combat_result.combatants[combatant_id]
        var card: CombatExileCard = _card_for_combatant(c)
        if card == null:
            continue
        var life_pct: float = entry.get("life_pct", 1.0)
        var vitality_pct: float = entry.get("vitality_pct", 1.0)
        var morale_pct: float = entry.get("morale_pct", 1.0)
        card.refresh_from_snapshot(
            life_pct * c.max_life, c.max_life, 
            vitality_pct * c.max_vitality, c.max_vitality, 
            morale_pct * c.max_morale, c.max_morale, 
        )


        card.refresh_ailment_strip(_get_ailment_state_for_display(combatant_id), current_tick)









func _route_event_to_card(event: CombatEvent) -> void :
    var event_id: int = event.get_instance_id()
    if _popped_event_ids.has(event_id):
        return
    match event.event_type:
        CombatEnums.CombatEventType.DAMAGE_DEALT:
            _route_damage_to_card(event)
        CombatEnums.CombatEventType.MORALE_PENALTY:
            _route_morale_penalty_to_card(event)
        CombatEnums.CombatEventType.STATUS_EFFECT_APPLIED:
            _route_status_applied(event)
        CombatEnums.CombatEventType.STATUS_EFFECT_EXPIRED:
            _route_status_expired(event)
        CombatEnums.CombatEventType.IMPALE_APPLIED:
            _route_impale_applied(event)
        CombatEnums.CombatEventType.IMPALE_CONSUMED:
            _route_impale_consumed(event)
        CombatEnums.CombatEventType.POISON_APPLIED:
            _route_poison_applied(event)
        CombatEnums.CombatEventType.POISON_EXPIRED:
            _route_poison_expired(event)
        CombatEnums.CombatEventType.EXPERIENCE_GAINED:
            _route_experience_gained(event)
        CombatEnums.CombatEventType.LEVEL_UP:
            _route_level_up(event)
        _:
            return
    _popped_event_ids[event_id] = true





func _route_experience_gained(event: CombatEvent) -> void :
    var combatant_id: int = event.data.get("combatant_id", -1)
    if combatant_id < 0 or combatant_id >= combat_result.combatants.size():
        return
    var c: CombatantData = combat_result.combatants[combatant_id]
    var card: CombatExileCard = _card_for_combatant(c)
    if card == null:
        return
    var amount: int = int(event.data.get("amount", 0))
    card.gain_xp(amount)






func _route_level_up(event: CombatEvent) -> void :
    var combatant_id: int = event.data.get("combatant_id", -1)
    if combatant_id < 0 or combatant_id >= combat_result.combatants.size():
        return
    var c: CombatantData = combat_result.combatants[combatant_id]
    var card: CombatExileCard = _card_for_combatant(c)
    if card == null:
        return
    var new_level: int = int(event.data.get("new_level", c.level_at_combat_start + 1))
    card.on_playback_level_up(new_level)


func _route_damage_to_card(event: CombatEvent) -> void :
    var def_id: int = event.data.get("defender_id", -1)
    if def_id < 0 or def_id >= combat_result.combatants.size():
        return
    var def_c: CombatantData = combat_result.combatants[def_id]
    var card: CombatExileCard = _card_for_combatant(def_c)
    if card == null:
        return
    var dmg: float = event.data.get("total", 0.0)
    var is_crit: bool = bool(event.data.get("is_crit", false))
    card.pop_damage(dmg, "life", is_crit)







func _route_morale_penalty_to_card(event: CombatEvent) -> void :
    var def_id: int = event.data.get("defender_id", -1)
    if def_id < 0 or def_id >= combat_result.combatants.size():
        return
    var def_c: CombatantData = combat_result.combatants[def_id]
    var card: CombatExileCard = _card_for_combatant(def_c)
    if card == null:
        return
    var amount: int = int(event.data.get("amount", 0))
    if amount <= 0:
        return
    var source: String = event.data.get("source", "")


    var emphasised: bool = source == "chaos" or source == "chaos_crit"
    card.pop_damage(float(amount), "morale", emphasised)












func _route_status_applied(event: CombatEvent) -> void :
    var bearer_id: int = event.data.get("combatant_id", -1)
    if bearer_id < 0 or bearer_id >= combat_result.combatants.size():
        return


    _cache_status_applied(event)
    var effect: StatusEffect = event.data.get("effect", null)
    if effect == null or effect.vfx == null:
        return
    var vfx: PersistentVFX = effect.vfx
    var key: String = "%d_%s" % [bearer_id, String(effect.effect_id)]
    var bearer: CombatantData = combat_result.combatants[bearer_id]
    var card: CombatExileCard = _card_for_combatant(bearer)







    if vfx.ambient_impact_fx != null and not _active_ambient_emitters.has(key):
        _active_ambient_emitters[key] = {
            "bearer_id": bearer_id, 
            "fx": vfx.ambient_impact_fx, 
            "interval": vfx.ambient_impact_interval_seconds, 
            "start_tick": event.tick, 
        }
        arena_drawer.queue_redraw()







    if vfx.portrait_tint != Color.WHITE:
        _set_arena_status_tint(bearer_id, effect.effect_id, vfx.portrait_tint)
        arena_drawer.queue_redraw()

    if card != null:

        card.apply_status_vfx(effect)
        return



    _ensure_status_overlay_layer()

    if vfx.overlay_scene != null and not _active_monster_overlays.has(key):
        var overlay: Node = vfx.overlay_scene.instantiate()
        _status_overlay_layer.add_child(overlay)


        var initial_pos: Vector2 = _current_screen_pos_for(bearer_id)
        if overlay is Node2D:
            (overlay as Node2D).position = initial_pos
        elif overlay is Control:
            (overlay as Control).position = initial_pos - (overlay as Control).size * 0.5
        _active_monster_overlays[key] = overlay

    if vfx.application_burst_scene != null:
        _spawn_arena_burst(vfx.application_burst_scene, _current_screen_pos_for(bearer_id))



func _route_status_expired(event: CombatEvent) -> void :
    var bearer_id: int = event.data.get("combatant_id", -1)
    if bearer_id < 0 or bearer_id >= combat_result.combatants.size():
        return

    _cache_status_expired(event)
    var effect: StatusEffect = event.data.get("effect", null)
    if effect == null:
        return
    var effect_id: StringName = event.data.get("effect_id", &"")
    var bearer: CombatantData = combat_result.combatants[bearer_id]
    var card: CombatExileCard = _card_for_combatant(bearer)
    var key: String = "%d_%s" % [bearer_id, String(effect_id)]





    if _active_ambient_emitters.has(key):
        _active_ambient_emitters.erase(key)
        arena_drawer.queue_redraw()



    _erase_arena_status_tint(bearer_id, effect_id)
    arena_drawer.queue_redraw()

    var removal_burst: PackedScene = effect.vfx.removal_burst_scene if effect.vfx != null else null

    if card != null:
        card.remove_status_vfx(effect_id, removal_burst)
        return


    if _active_monster_overlays.has(key):
        var overlay: Node = _active_monster_overlays[key]
        if is_instance_valid(overlay):
            overlay.queue_free()
        _active_monster_overlays.erase(key)
    if removal_burst != null:
        _spawn_arena_burst(removal_burst, _current_screen_pos_for(bearer_id))






func _update_monster_overlay_positions(positions: Array, offset: Vector2, arena_scale: float) -> void :
    if _active_monster_overlays.is_empty():
        return


    var screen_pos_by_id: Dictionary = {}
    for entry in positions:
        var id: int = entry.get("id", -1)
        if id < 0:
            continue
        screen_pos_by_id[id] = _arena_to_screen(entry["pos"], offset, arena_scale)


    var keys_snapshot: Array = _active_monster_overlays.keys()
    for key in keys_snapshot:
        var overlay: Node = _active_monster_overlays[key]
        if not is_instance_valid(overlay):
            _active_monster_overlays.erase(key)
            continue

        var sep_idx: int = String(key).find("_")
        if sep_idx < 0:
            continue
        var bearer_id: int = int(String(key).substr(0, sep_idx))
        if not screen_pos_by_id.has(bearer_id):
            continue
        var screen_pos: Vector2 = screen_pos_by_id[bearer_id]
        if overlay is Node2D:
            (overlay as Node2D).position = screen_pos
        elif overlay is Control:
            (overlay as Control).position = screen_pos - (overlay as Control).size * 0.5







func _route_impale_applied(event: CombatEvent) -> void :
    var bearer_id: int = event.data.get("defender_id", -1)
    if bearer_id < 0 or bearer_id >= combat_result.combatants.size():
        return
    _cache_impale_applied(event)
    var stacks_now: int = int(event.data.get("stacks_now", 0))
    var bearer: CombatantData = combat_result.combatants[bearer_id]
    var card: CombatExileCard = _card_for_combatant(bearer)
    if card != null:

        card.apply_impale_vfx(stacks_now)
        return


    _ensure_status_overlay_layer()
    var overlay: Node2D = _active_impale_overlays.get(bearer_id)
    if overlay == null or not is_instance_valid(overlay):
        overlay = IMPALE_VFX_SCENE.instantiate() as Node2D
        _status_overlay_layer.add_child(overlay)

        overlay.position = _current_screen_pos_for(bearer_id)
        _active_impale_overlays[bearer_id] = overlay

    if overlay.has_method("set_visible_count"):
        overlay.call("set_visible_count", stacks_now)






func _route_impale_consumed(event: CombatEvent) -> void :
    var bearer_id: int = event.data.get("defender_id", -1)
    if bearer_id < 0 or bearer_id >= combat_result.combatants.size():
        return
    _cache_impale_consumed(event)
    var bearer: CombatantData = combat_result.combatants[bearer_id]
    var card: CombatExileCard = _card_for_combatant(bearer)
    if card != null:
        card.play_impale_consume_vfx()
        return


    var overlay: Node2D = _active_impale_overlays.get(bearer_id)
    if overlay == null or not is_instance_valid(overlay):
        return
    if overlay.has_method("play_consume_burst"):
        overlay.call("play_consume_burst")



    _active_impale_overlays.erase(bearer_id)
    get_tree().create_timer(1.2).timeout.connect(_force_free_arena_burst.bind(overlay))






func _update_impale_overlay_positions(positions: Array, offset: Vector2, arena_scale: float) -> void :
    if _active_impale_overlays.is_empty():
        return


    var screen_pos_by_id: Dictionary = {}
    for entry in positions:
        var id: int = entry.get("id", -1)
        if id < 0:
            continue
        screen_pos_by_id[id] = _arena_to_screen(entry["pos"], offset, arena_scale)


    var keys_snapshot: Array = _active_impale_overlays.keys()
    for bearer_id in keys_snapshot:
        var overlay: Node2D = _active_impale_overlays[bearer_id]
        if not is_instance_valid(overlay):
            _active_impale_overlays.erase(bearer_id)
            continue
        if not screen_pos_by_id.has(bearer_id):
            continue
        overlay.position = screen_pos_by_id[bearer_id]




func _clear_all_impale_overlays() -> void :
    for overlay in _active_impale_overlays.values():
        if is_instance_valid(overlay):
            overlay.queue_free()
    _active_impale_overlays.clear()







func _route_poison_applied(event: CombatEvent) -> void :
    var bearer_id: int = event.data.get("defender_id", -1)
    if bearer_id < 0 or bearer_id >= combat_result.combatants.size():
        return
    _cache_poison_applied(event)
    var stacks_now: int = int(event.data.get("stacks_now", 0))
    var bearer: CombatantData = combat_result.combatants[bearer_id]
    var card: CombatExileCard = _card_for_combatant(bearer)
    if card != null:

        card.apply_poison_vfx(stacks_now)
        return


    _ensure_status_overlay_layer()
    var overlay: Node2D = _active_poison_overlays.get(bearer_id)
    if overlay == null or not is_instance_valid(overlay):
        overlay = POISON_VFX_SCENE.instantiate() as Node2D
        _status_overlay_layer.add_child(overlay)
        overlay.position = _current_screen_pos_for(bearer_id)
        _active_poison_overlays[bearer_id] = overlay
    if overlay.has_method("set_visible_count"):
        overlay.call("set_visible_count", stacks_now)





func _route_poison_expired(event: CombatEvent) -> void :
    var bearer_id: int = event.data.get("combatant_id", -1)
    if bearer_id < 0 or bearer_id >= combat_result.combatants.size():
        return
    _cache_poison_expired(event)
    var stacks_remaining: int = int(event.data.get("stacks_remaining", 0))
    var bearer: CombatantData = combat_result.combatants[bearer_id]
    var card: CombatExileCard = _card_for_combatant(bearer)
    if card != null:


        if stacks_remaining <= 0:
            card.clear_poison_vfx()
        else:
            card.apply_poison_vfx(stacks_remaining)
        return


    var overlay: Node2D = _active_poison_overlays.get(bearer_id)
    if overlay == null or not is_instance_valid(overlay):
        return
    if stacks_remaining <= 0:
        overlay.queue_free()
        _active_poison_overlays.erase(bearer_id)
    elif overlay.has_method("set_visible_count"):
        overlay.call("set_visible_count", stacks_remaining)





func _update_poison_overlay_positions(positions: Array, offset: Vector2, arena_scale: float) -> void :
    if _active_poison_overlays.is_empty():
        return
    var screen_pos_by_id: Dictionary = {}
    for entry in positions:
        var id: int = entry.get("id", -1)
        if id < 0:
            continue
        screen_pos_by_id[id] = _arena_to_screen(entry["pos"], offset, arena_scale)
    var keys_snapshot: Array = _active_poison_overlays.keys()
    for bearer_id in keys_snapshot:
        var overlay: Node2D = _active_poison_overlays[bearer_id]
        if not is_instance_valid(overlay):
            _active_poison_overlays.erase(bearer_id)
            continue
        if not screen_pos_by_id.has(bearer_id):
            continue
        overlay.position = screen_pos_by_id[bearer_id]



func _clear_all_poison_overlays() -> void :
    for overlay in _active_poison_overlays.values():
        if is_instance_valid(overlay):
            overlay.queue_free()
    _active_poison_overlays.clear()










func _ensure_ailment_state_for(bearer_id: int) -> Dictionary:
    if not _playback_ailment_state.has(bearer_id):
        _playback_ailment_state[bearer_id] = {
            "status_effects": {}, 
            "impale_stacks": [], 
            "poison_stacks": [], 
        }
    return _playback_ailment_state[bearer_id]






func _cache_status_applied(event: CombatEvent) -> void :
    var bearer_id: int = event.data.get("combatant_id", -1)
    if bearer_id < 0:
        return
    var effect: StatusEffect = event.data.get("effect", null)
    if effect == null:
        return
    var state: Dictionary = _ensure_ailment_state_for(bearer_id)
    var effect_id: StringName = effect.effect_id







    var magnitude_pct: float = float(event.data.get("magnitude_pct", 0.0))
    var stacks: int = int(event.data.get("stacks", 1))
    var modifier_keys: Dictionary = {}
    for key in effect.stat_modifiers.keys():
        var base_val: float = float(effect.stat_modifiers[key])
        modifier_keys[key] = base_val * float(stacks)
    var per_tick_keys: Dictionary = {}
    for key in effect.per_tick_effects.keys():
        var base_tick: float = float(effect.per_tick_effects[key])
        per_tick_keys[key] = base_tick * float(stacks)





    if effect_id == &"ignite" and per_tick_keys.has("fire_damage_per_sec"):
        per_tick_keys["fire_damage_per_sec"] = magnitude_pct
    elif effect_id == &"shock" and modifier_keys.has("damage_taken_more_pct"):
        modifier_keys["damage_taken_more_pct"] = magnitude_pct
    elif effect_id == &"chill" and modifier_keys.has("action_speed_more_pct"):


        modifier_keys["action_speed_more_pct"] = - absf(magnitude_pct)

    state["status_effects"][effect_id] = {
        "effect_id": effect_id, 
        "display_name": String(event.data.get("display_name", effect.display_name)), 
        "stacks": stacks, 
        "expires_at_tick": float(event.data.get("expires_at_tick", INF)), 
        "magnitude_pct": magnitude_pct, 
        "magnitude_label": String(event.data.get("magnitude_label", "")), 
        "duration_seconds": float(event.data.get("duration_seconds", 0.0)), 
        "modifier_keys": modifier_keys, 
        "per_tick_keys": per_tick_keys, 
    }


func _cache_status_expired(event: CombatEvent) -> void :
    var bearer_id: int = event.data.get("combatant_id", -1)
    if bearer_id < 0:
        return
    if not _playback_ailment_state.has(bearer_id):
        return
    var effect_id: StringName = event.data.get("effect_id", &"")
    _playback_ailment_state[bearer_id]["status_effects"].erase(effect_id)





func _cache_impale_applied(event: CombatEvent) -> void :
    var bearer_id: int = event.data.get("defender_id", -1)
    if bearer_id < 0:
        return
    var state: Dictionary = _ensure_ailment_state_for(bearer_id)
    var flat: float = float(event.data.get("flat_damage", 0.0))
    var stacks_added: int = int(event.data.get("stacks_added", 1))
    var max_stacks: int = int(event.data.get("max_stacks", 3))
    var arr: Array = state["impale_stacks"]
    for _i in stacks_added:
        arr.append({"flat_damage": flat})
        while arr.size() > max_stacks:
            arr.pop_front()


func _cache_impale_consumed(event: CombatEvent) -> void :
    var bearer_id: int = event.data.get("defender_id", -1)
    if bearer_id < 0:
        return
    if not _playback_ailment_state.has(bearer_id):
        return
    (_playback_ailment_state[bearer_id]["impale_stacks"] as Array).clear()





func _cache_poison_applied(event: CombatEvent) -> void :
    var bearer_id: int = event.data.get("defender_id", -1)
    if bearer_id < 0:
        return
    var state: Dictionary = _ensure_ailment_state_for(bearer_id)
    var arr: Array = state["poison_stacks"]
    arr.append({
        "damage_per_sec": float(event.data.get("damage_per_sec", 0.0)), 
        "expires_at_tick": float(event.data.get("expires_at_tick", 0.0)), 
    })



    while arr.size() > 999:
        arr.pop_front()





func _cache_poison_expired(event: CombatEvent) -> void :
    var bearer_id: int = event.data.get("combatant_id", -1)
    if bearer_id < 0:
        return
    if not _playback_ailment_state.has(bearer_id):
        return
    var arr: Array = _playback_ailment_state[bearer_id]["poison_stacks"]
    if arr.is_empty():
        return
    var earliest_idx: int = 0
    var earliest_expiry: float = INF
    for i in arr.size():
        var stack_expiry: float = float(arr[i].get("expires_at_tick", 0.0))
        if stack_expiry < earliest_expiry:
            earliest_expiry = stack_expiry
            earliest_idx = i
    arr.remove_at(earliest_idx)




func _get_ailment_state_for_display(bearer_id: int) -> Dictionary:
    if _playback_ailment_state.has(bearer_id):
        return _playback_ailment_state[bearer_id]
    return {"status_effects": {}, "impale_stacks": [], "poison_stacks": []}





func _spawn_arena_burst(burst_scene: PackedScene, screen_pos: Vector2) -> void :
    _ensure_status_overlay_layer()
    var burst: Node = burst_scene.instantiate()
    _status_overlay_layer.add_child(burst)
    if burst is Node2D:
        (burst as Node2D).position = screen_pos
    elif burst is Control:
        (burst as Control).position = screen_pos - (burst as Control).size * 0.5
    get_tree().create_timer(3.0).timeout.connect(_force_free_arena_burst.bind(burst))




func _force_free_arena_burst(burst: Node) -> void :
    if is_instance_valid(burst):
        burst.queue_free()





func _current_screen_pos_for(combatant_id: int) -> Vector2:
    if not arena_drawer:
        return Vector2.ZERO
    var view_size: Vector2 = arena_drawer.size
    var aw: float = combat_result.encounter.arena_width
    var ah: float = combat_result.encounter.arena_height
    var arena_scale: float = min(view_size.x / aw, view_size.y / ah)
    var arena_w_screen: float = aw * arena_scale
    var arena_h_screen: float = ah * arena_scale
    var offset: = Vector2(
        (view_size.x - arena_w_screen) / 2.0, 
        (view_size.y - arena_h_screen) / 2.0, 
    )


    var snap: Dictionary = combat_result.snapshots[current_tick_idx]
    var positions_in_snap: Array = snap.get("positions", [])
    for entry in positions_in_snap:
        if entry.get("id", -1) == combatant_id:
            return _arena_to_screen(entry["pos"], offset, arena_scale)
    return Vector2.ZERO




func _ensure_status_overlay_layer() -> void :
    if _status_overlay_layer != null and is_instance_valid(_status_overlay_layer):
        return
    _status_overlay_layer = Control.new()
    _status_overlay_layer.name = "StatusOverlayLayer"
    _status_overlay_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE

    _status_overlay_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    arena_drawer.add_child(_status_overlay_layer)





func _clear_all_monster_overlays() -> void :
    for overlay in _active_monster_overlays.values():
        if is_instance_valid(overlay):
            overlay.queue_free()
    _active_monster_overlays.clear()






func _set_arena_status_tint(combatant_id: int, effect_id: StringName, tint: Color) -> void :
    if not _active_status_tints_by_combatant.has(combatant_id):
        _active_status_tints_by_combatant[combatant_id] = {}
    _active_status_tints_by_combatant[combatant_id][effect_id] = tint




func _erase_arena_status_tint(combatant_id: int, effect_id: StringName) -> void :
    if not _active_status_tints_by_combatant.has(combatant_id):
        return
    var contribs: Dictionary = _active_status_tints_by_combatant[combatant_id]
    contribs.erase(effect_id)
    if contribs.is_empty():
        _active_status_tints_by_combatant.erase(combatant_id)






func _combatant_arena_tint(combatant_id: int) -> Color:
    if not _active_status_tints_by_combatant.has(combatant_id):
        return Color.WHITE
    var combined: Color = Color.WHITE
    for tint in _active_status_tints_by_combatant[combatant_id].values():
        combined = combined * tint
    return combined





func _exit_tree() -> void :



    if _is_sandbox:
        sandbox_payload = {}
        return








func _resolve_runner() -> MissionRunner:
    var actives: = MissionManager.get_active_missions()
    if not actives.is_empty():
        return MissionManager.get_runner(actives[0])




    return MissionManager.last_resolved_runner













func _unhandled_input(event: InputEvent) -> void :
    if not (event is InputEventKey):
        return

    if not event.pressed or event.echo:
        return

    match event.keycode:
        KEY_ALT:
            _alt_held = not _alt_held
            if arena_drawer:
                arena_drawer.queue_redraw()
            accept_event()
        KEY_SPACE:
            _on_play_pause()
            accept_event()
        KEY_LEFT:
            _on_step_back()
            accept_event()
        KEY_RIGHT:
            _on_step_forward()
            accept_event()
        KEY_UP:
            _cycle_speed(1)
            accept_event()
        KEY_DOWN:
            _cycle_speed(-1)
            accept_event()
        KEY_1:
            _set_speed_by_index(0)
            accept_event()
        KEY_2:
            _set_speed_by_index(1)
            accept_event()
        KEY_3:
            _set_speed_by_index(2)
            accept_event()
        KEY_4:
            _set_speed_by_index(3)
            accept_event()
        KEY_BACKSPACE:
            _on_reset()
            accept_event()
        KEY_ENTER, KEY_KP_ENTER:
            _on_continue()
            accept_event()


func _connect_signals() -> void :
    play_button.pressed.connect(_on_play_pause)
    reset_button.pressed.connect(_on_reset)
    back_button.pressed.connect(_on_step_back)
    forward_button.pressed.connect(_on_step_forward)
    speed_05x.pressed.connect(_set_speed.bind(0.5))
    speed_1x.pressed.connect(_set_speed.bind(1.0))
    speed_2x.pressed.connect(_set_speed.bind(2.0))
    speed_4x.pressed.connect(_set_speed.bind(4.0))
    scrubber.value_changed.connect(_on_scrub)
    combat_end_banner.pressed.connect(_on_continue)

    event_log_view.meta_hover_started.connect(_on_log_meta_hover_started)
    event_log_view.meta_hover_ended.connect(_on_log_meta_hover_ended)




    monster_damage_toggle.toggled.connect(_on_log_filter_changed)
    exile_damage_toggle.toggled.connect(_on_log_filter_changed)
    crits_only_toggle.toggled.connect(_on_log_filter_changed)






func _load_current_result() -> void :
    combat_result = _runner.last_combat_result
    if not combat_result:
        push_warning("CombatPlaybackScreen: no combat result on runner")
        return

    current_tick_idx = 0
    playing = false
    _recent_hits.clear()
    _clear_log()
    _visual_tail_seconds = _compute_visual_tail()
    _build_drop_visuals()
    _build_impact_stains()
    _build_popup_directions()
    _populate_combat_cards_from_runner()





    var total: int = _active_mission.mission_data.encounter_slots.size()
    var played_idx: int = _active_mission.current_encounter_index
    if combat_result.outcome == CombatEnums.CombatResult.VICTORY:
        played_idx -= 1
    played_idx = clampi(played_idx, 0, total - 1)



    encounter_name_label.text = combat_result.encounter.display_name
    encounter_label.text = "Encounter %d of %d" % [played_idx + 1, total]


    var max_idx: int = max(0, combat_result.snapshots.size() - 1)
    scrubber.min_value = 0
    scrubber.max_value = max_idx
    scrubber.value = 0



    _set_outcome_banner_content()
    _set_banner_visible(false)

    current_sim_time = 0.0
    _apply_user_preferences()
    _update_play_icon()
    _update_tick_label()
    _update_end_state()
    arena_drawer.queue_redraw()






func _on_play_pause() -> void :
    if not combat_result or combat_result.snapshots.is_empty():
        return


    if current_sim_time >= _playback_end_time():
        current_sim_time = 0.0
        current_tick_idx = 0
        _recent_hits.clear()



        _clear_log()
        _set_banner_visible(false)
    playing = not playing
    _update_play_icon()


func _on_reset() -> void :
    current_tick_idx = 0
    current_sim_time = 0.0
    playing = false
    _recent_hits.clear()
    _clear_log()
    scrubber.set_value_no_signal(0)
    _update_play_icon()
    _update_tick_label()
    _update_end_state()
    arena_drawer.queue_redraw()


func _on_step_back() -> void :
    playing = false
    current_tick_idx = max(0, current_tick_idx - 1)
    current_sim_time = current_tick_idx * CombatSimulation.TICK_STEP
    scrubber.set_value_no_signal(current_tick_idx)
    _rebuild_event_log()
    _update_play_icon()
    _update_tick_label()
    _update_end_state()
    arena_drawer.queue_redraw()


func _on_step_forward() -> void :
    playing = false
    var max_idx: int = combat_result.snapshots.size() - 1
    current_tick_idx = min(max_idx, current_tick_idx + 1)
    current_sim_time = current_tick_idx * CombatSimulation.TICK_STEP
    scrubber.set_value_no_signal(current_tick_idx)
    _rebuild_event_log()
    _update_play_icon()
    _update_tick_label()
    _update_end_state()
    arena_drawer.queue_redraw()


func _set_speed(mult: float) -> void :
    speed_multiplier = mult




func _cycle_speed(direction: int) -> void :
    var idx: int = SPEED_LEVELS.find(speed_multiplier)
    if idx < 0:
        idx = 0
    idx = clampi(idx + direction, 0, SPEED_LEVELS.size() - 1)
    _set_speed_by_index(idx)





func _set_speed_by_index(idx: int) -> void :
    if idx < 0 or idx >= SPEED_LEVELS.size():
        return
    var new_speed: float = SPEED_LEVELS[idx]
    _set_speed(new_speed)
    var buttons: Array[Button] = [speed_05x, speed_1x, speed_2x, speed_4x]
    buttons[idx].button_pressed = true








func _apply_user_preferences() -> void :
    var preferred_idx: int = SPEED_LEVELS.find(UserPreferences.default_playback_speed)
    if preferred_idx < 0:
        preferred_idx = 0
    _set_speed_by_index(preferred_idx)

    if not UserPreferences.auto_start_playback:
        return
    if combat_result == null or combat_result.snapshots.is_empty():
        return
    playing = true


func _update_play_icon() -> void :
    play_button.icon = PAUSE_ICON if playing else PLAY_ICON


func _on_scrub(value: float) -> void :
    playing = false
    _update_play_icon()
    current_tick_idx = int(value)
    current_sim_time = current_tick_idx * CombatSimulation.TICK_STEP
    _rebuild_event_log()
    _update_tick_label()
    _update_end_state()
    arena_drawer.queue_redraw()







func _process(delta: float) -> void :

    _update_hover()

    if not playing or not combat_result or combat_result.snapshots.is_empty():
        return





    var playback_end: float = _playback_end_time()
    current_sim_time = min(current_sim_time + delta * speed_multiplier, playback_end)




    var max_idx: int = combat_result.snapshots.size() - 1
    var new_tick_idx: int = mini(int(current_sim_time / CombatSimulation.TICK_STEP), max_idx)
    if new_tick_idx > current_tick_idx:

        for crossed in range(current_tick_idx + 1, new_tick_idx + 1):
            _append_events_at_tick(crossed)
        current_tick_idx = new_tick_idx
        scrubber.set_value_no_signal(current_tick_idx)

    _update_tick_label()
    arena_drawer.queue_redraw()


    if current_sim_time >= playback_end:
        playing = false
        _update_play_icon()

    _update_end_state()


func _max_sim_time() -> float:
    return max(0.0, (combat_result.snapshots.size() - 1) * CombatSimulation.TICK_STEP)






func _playback_end_time() -> float:
    return _max_sim_time() + _visual_tail_seconds











func _compute_visual_tail() -> float:
    if not combat_result:
        return ATTACK_VISUAL_TAIL_DURATION
    var combat_end: float = _max_sim_time()
    var max_overshoot: float = ATTACK_VISUAL_TAIL_DURATION
    for event in combat_result.event_log:
        if event.event_type != CombatEnums.CombatEventType.DAMAGE_DEALT:
            continue
        var attacker_id: int = event.data.get("attacker_id", -1)
        if attacker_id < 0:
            continue
        var atk_c: CombatantData = combat_result.combatants[attacker_id]


        var ability_resource: MonsterAbility = event.data.get("ability")
        var attacker_vfx: AttackVFX = atk_c.get_ability_vfx(ability_resource) if atk_c else null
        var impact_fx: HitImpactFX = _impact_fx_for_event(attacker_vfx)


        var attack_end: float = event.tick + (attacker_vfx.lifetime_seconds if attacker_vfx else FALLBACK_VFX_LIFETIME)
        var impact_tick: float = _impact_tick_for_event(event, attacker_vfx)
        var impact_end: float = impact_tick + (impact_fx.lifetime_seconds if impact_fx else 0.0)
        var visual_end: float = maxf(attack_end, impact_end)
        var overshoot: float = visual_end - combat_end
        if overshoot > max_overshoot:
            max_overshoot = overshoot
    return max_overshoot







func _set_outcome_banner_content() -> void :
    if not combat_end_banner or not combat_result:
        return
    match combat_result.outcome:
        CombatEnums.CombatResult.VICTORY:
            combat_end_banner.text = "VICTORY"
            combat_end_banner.modulate = Color(0.55, 1.0, 0.65)
        CombatEnums.CombatResult.DEFEAT:
            combat_end_banner.text = "DEFEAT"
            combat_end_banner.modulate = Color(1.0, 0.35, 0.35)
        CombatEnums.CombatResult.RETREAT:
            combat_end_banner.text = "RETREATED"
            combat_end_banner.modulate = Color(0.95, 0.85, 0.4)
        _:
            combat_end_banner.text = "COMBAT ENDED"
            combat_end_banner.modulate = Color(0.8, 0.8, 0.8)





func _update_end_state() -> void :
    if not combat_result or combat_result.snapshots.is_empty():
        return
    var at_end: bool = current_sim_time >= _max_sim_time()
    if combat_end_banner:
        _set_banner_visible(at_end)





func _set_banner_visible(value: bool) -> void :
    if combat_end_banner == null:
        return
    combat_end_banner.visible = value
    if value:
        _start_banner_glow()
    else:
        _stop_banner_glow()








func _start_banner_glow() -> void :
    if _banner_glow_tween and _banner_glow_tween.is_valid():
        return
    _banner_glow_tween = create_tween()
    _banner_glow_tween.set_loops()
    _banner_glow_tween.set_trans(Tween.TRANS_SINE)
    _banner_glow_tween.set_ease(Tween.EASE_IN_OUT)
    var half: float = banner_glow_pulse_seconds * 0.5
    _banner_glow_tween.tween_method(_set_banner_glow_size, banner_glow_min_px, banner_glow_max_px, half)
    _banner_glow_tween.tween_method(_set_banner_glow_size, banner_glow_max_px, banner_glow_min_px, half)




func _stop_banner_glow() -> void :
    if _banner_glow_tween and _banner_glow_tween.is_valid():
        _banner_glow_tween.kill()
    _banner_glow_tween = null
    _set_banner_glow_size(0.0)






func _set_banner_glow_size(value: float) -> void :
    if combat_end_banner == null:
        return
    for style_name in ["normal", "hover", "pressed"]:
        var sb: StyleBoxFlat = combat_end_banner.get_theme_stylebox(style_name) as StyleBoxFlat
        if sb != null:
            sb.shadow_size = int(round(value))


func _on_continue() -> void :



    if _is_sandbox:
        sandbox_continue_pressed.emit()
        return


    SceneRouter.to_mission_report()






func _append_events_at_tick(tick_idx: int) -> void :
    if not combat_result:
        return
    var current_tick_time: float = tick_idx * CombatSimulation.TICK_STEP
    var prev_tick_time: float = (tick_idx - 1) * CombatSimulation.TICK_STEP


    for i in range(combat_result.event_log.size()):
        var event: CombatEvent = combat_result.event_log[i]
        if event.tick > prev_tick_time and event.tick <= current_tick_time:
            _print_event(event, combat_result.event_log, i)


            _route_event_to_card(event)


func _rebuild_event_log() -> void :
    _clear_log()
    if not combat_result:
        return
    var current_tick_time: float = current_tick_idx * CombatSimulation.TICK_STEP
    for i in range(combat_result.event_log.size()):
        var event: CombatEvent = combat_result.event_log[i]
        if event.tick <= current_tick_time:
            _print_event(event, combat_result.event_log, i)






            match event.event_type:
                CombatEnums.CombatEventType.STATUS_EFFECT_APPLIED, \
CombatEnums.CombatEventType.STATUS_EFFECT_EXPIRED, \
CombatEnums.CombatEventType.IMPALE_APPLIED, \
CombatEnums.CombatEventType.IMPALE_CONSUMED, \
CombatEnums.CombatEventType.POISON_APPLIED, \
CombatEnums.CombatEventType.POISON_EXPIRED, \
CombatEnums.CombatEventType.EXPERIENCE_GAINED, \
CombatEnums.CombatEventType.LEVEL_UP:





                    _route_event_to_card(event)




















func _print_event(event: CombatEvent, event_log: Array, event_idx: int) -> void :
    if not _is_event_visible(event):
        return

    var meta_id: String = ""
    var inline_chunks: Array = []

    if event.event_type == CombatEnums.CombatEventType.DAMAGE_DEALT:
        meta_id = "evt:%d" % _next_meta_id
        _events_by_meta[meta_id] = event
        _next_meta_id += 1
        inline_chunks = _collect_inline_chunks(event, event_log, event_idx)

    var line: String = CombatLogFormatter.format_event(
        event, combat_result.combatants, 
        {"meta_id": meta_id, "inline_chunks": inline_chunks}, 
    )
    if line.is_empty():
        return
    event_log_view.append_text(line + "\n")










func _collect_inline_chunks(damage_event: CombatEvent, event_log: Array, event_idx: int) -> Array:
    var chunks: Array = []
    var atk_id: int = int(damage_event.data.get("attacker_id", -1))
    var def_id: int = int(damage_event.data.get("defender_id", -1))
    var damage_tick: float = damage_event.tick

    var j: int = event_idx + 1
    while j < event_log.size():
        var next_event: CombatEvent = event_log[j]
        if next_event.tick != damage_tick:
            break
        if _is_inline_ailment_event(next_event)\
and bool(next_event.data.get("inline_with_hit", false))\
and int(next_event.data.get("attacker_id", -2)) == atk_id\
and int(next_event.data.get("defender_id", -2)) == def_id:
            var chunk_meta: String = "evt:%d" % _next_meta_id
            _events_by_meta[chunk_meta] = next_event
            _next_meta_id += 1
            chunks.append({"meta_id": chunk_meta, "event": next_event})
        j += 1
    return chunks





func _is_inline_ailment_event(event: CombatEvent) -> bool:
    match event.event_type:
        CombatEnums.CombatEventType.IMPALE_APPLIED, \
CombatEnums.CombatEventType.IMPALE_CONSUMED, \
CombatEnums.CombatEventType.STATUS_EFFECT_APPLIED, \
CombatEnums.CombatEventType.POISON_APPLIED:
            return true
        _:
            return false











func _is_event_visible(event: CombatEvent) -> bool:
    if combat_result == null:
        return true



    var attacker_id: int = event.data.get("attacker_id", -1)
    if attacker_id < 0 or attacker_id >= combat_result.combatants.size():
        return true
    var attacker: CombatantData = combat_result.combatants[attacker_id]
    var is_exile_attacker: bool = attacker.team == CombatEnums.CombatantTeam.EXILES

    if event.event_type == CombatEnums.CombatEventType.DAMAGE_DEALT:
        if is_exile_attacker and not exile_damage_toggle.button_pressed:
            return false
        if not is_exile_attacker and not monster_damage_toggle.button_pressed:
            return false
        if crits_only_toggle.button_pressed and not bool(event.data.get("is_crit", false)):
            return false
        return true





    match event.event_type:
        CombatEnums.CombatEventType.CRITICAL_STRIKE, \
CombatEnums.CombatEventType.EVASION, \
CombatEnums.CombatEventType.GLANCING_BLOW, \
CombatEnums.CombatEventType.BLOCK, \
CombatEnums.CombatEventType.ENDURANCE, \
CombatEnums.CombatEventType.MORALE_PENALTY:
            if is_exile_attacker and not exile_damage_toggle.button_pressed:
                return false
            if not is_exile_attacker and not monster_damage_toggle.button_pressed:
                return false
    return true





func _on_log_filter_changed(_pressed: bool) -> void :
    _rebuild_event_log()





func _clear_log() -> void :
    event_log_view.clear()
    _events_by_meta.clear()
    _next_meta_id = 0
    _popped_event_ids.clear()



    _clear_all_monster_overlays()
    _clear_all_impale_overlays()
    _clear_all_poison_overlays()
    _active_ambient_emitters.clear()
    _active_status_tints_by_combatant.clear()



    _playback_ailment_state.clear()
    for card in combat_cards:
        if card != null:
            card.clear_all_status_vfx()
            card.clear_impale_vfx()
            card.clear_poison_vfx()



            card.reset_playback_xp_to_start()






func _on_log_meta_hover_started(meta: Variant) -> void :
    var event: CombatEvent = _events_by_meta.get(str(meta), null)
    if not event:
        return
    damage_tooltip.show_breakdown(
        CombatLogFormatter.format_breakdown_bbcode(event), 
        get_global_mouse_position(), 
    )


func _on_log_meta_hover_ended(_meta: Variant) -> void :
    damage_tooltip.hide_tooltip()

















func _connect_card_ailment_signals() -> void :
    for card in combat_cards:
        if card == null:
            continue
        var strip: AilmentPanelStrip = card.ailment_strip
        if strip == null:
            continue
        strip.panel_hovered.connect(_on_ailment_panel_hovered)
        strip.panel_unhovered.connect(_on_ailment_panel_unhovered)




    if hover_ailment_strip != null:
        hover_ailment_strip.panel_hovered.connect(_on_ailment_panel_hovered)
        hover_ailment_strip.panel_unhovered.connect(_on_ailment_panel_unhovered)


func _on_ailment_panel_hovered(bbcode: String, _anchor_rect: Rect2) -> void :



    damage_tooltip.show_breakdown(bbcode, get_global_mouse_position())


func _on_ailment_panel_unhovered() -> void :
    damage_tooltip.hide_tooltip()






func draw_arena(drawer: Control) -> void :
    if not combat_result or combat_result.snapshots.is_empty():
        return

    var view_size: Vector2 = drawer.size
    var aw: float = combat_result.encounter.arena_width
    var ah: float = combat_result.encounter.arena_height
    var arena_scale: float = min(view_size.x / aw, view_size.y / ah)
    var arena_w_screen: float = aw * arena_scale
    var arena_h_screen: float = ah * arena_scale
    var offset: = Vector2((view_size.x - arena_w_screen) / 2.0, (view_size.y - arena_h_screen) / 2.0)


    drawer.draw_rect(Rect2(offset, Vector2(arena_w_screen, arena_h_screen)), arena_bg, true)
    drawer.draw_rect(Rect2(offset, Vector2(arena_w_screen, arena_h_screen)), arena_border, false, 2.0)
















    var max_idx: int = combat_result.snapshots.size() - 1
    var snap_a: Dictionary = combat_result.snapshots[current_tick_idx]
    var snap_b_idx: int = min(current_tick_idx + 1, max_idx)
    var snap_b: Dictionary = combat_result.snapshots[snap_b_idx]
    var frac: float = clampf(
        (current_sim_time / CombatSimulation.TICK_STEP) - float(current_tick_idx), 
        0.0, 1.0, 
    )
    var positions: Array = _build_interpolated_positions(snap_a, snap_b, frac)



    _refresh_cards_from_snapshot(positions)



    _update_monster_overlay_positions(positions, offset, arena_scale)


    _update_impale_overlay_positions(positions, offset, arena_scale)

    _update_poison_overlay_positions(positions, offset, arena_scale)


    for entry in positions:
        var entry_state: int = entry.get("state", -1)
        if entry_state != CombatEnums.CombatantState.ATTACKING:
            continue
        var target_id: int = entry.get("target_id", -1)
        if target_id < 0:
            continue
        var target_entry: Dictionary = _find_position_entry(positions, target_id)
        if target_entry.is_empty():
            continue
        var c: CombatantData = combat_result.combatants[entry["id"]]
        var from_pos: = _arena_to_screen(entry["pos"], offset, arena_scale)
        var to_pos: = _arena_to_screen(target_entry["pos"], offset, arena_scale)
        var color: Color = targeting_ally if c.team == CombatEnums.CombatantTeam.EXILES else targeting_enemy
        drawer.draw_dashed_line(from_pos, to_pos, color, 1.0, 4.0)


    for entry in positions:
        if not entry.get("state") == CombatEnums.CombatantState.DEAD:
            continue
        var c_dead: CombatantData = combat_result.combatants[entry["id"]]
        var pos: = _arena_to_screen(entry["pos"], offset, arena_scale)
        var dead_color: = Color(0.4, 0.4, 0.4, 0.4)
        var x_arm: float = _radius_for(c_dead) * 0.65
        var x_width: float = maxf(x_arm * 0.18, 1.5)
        drawer.draw_line(pos + Vector2( - x_arm, - x_arm), pos + Vector2(x_arm, x_arm), dead_color, x_width)
        drawer.draw_line(pos + Vector2(x_arm, - x_arm), pos + Vector2( - x_arm, x_arm), dead_color, x_width)



    _draw_impact_stains(drawer, offset, arena_scale)



    _draw_item_drops(drawer, offset, arena_scale)


    for entry in positions:
        var c: CombatantData = combat_result.combatants[entry["id"]]
        if entry.get("state") == CombatEnums.CombatantState.DEAD:
            continue
        var pos: = _arena_to_screen(entry["pos"], offset, arena_scale)
        var radius: float = _radius_for(c)
        var color: Color = _color_for(c, entry["state"])






        var status_tint: Color = _combatant_arena_tint(entry["id"])
        var tinted_color: Color = color * status_tint


        if entry.get("state") == CombatEnums.CombatantState.ATTACKING:
            var glow_color: Color = tinted_color
            glow_color.a = 0.25
            drawer.draw_circle(pos, radius + 4, glow_color)

        _draw_dot_body(drawer, pos, radius, tinted_color)







        var facing_dir: Vector2 = _facing_dir_for_combatant(entry, positions)
        if c.team == CombatEnums.CombatantTeam.EXILES:
            _draw_exile_center_glyph(drawer, c, pos, radius, entry.get("state"), facing_dir, status_tint)
        elif c.source_monster and c.source_monster.icon:
            _draw_oriented_dot_icon(drawer, c.source_monster.icon, pos, radius, facing_dir, monster_icon_overflow, 0.0, status_tint)


        var life_pct: float = entry.get("life_pct", 1.0)
        var bar_w: float = radius * 2.5
        var bar_h: float = maxf(radius * 0.35, 4.0)
        var bar_y_offset: float = - radius - bar_h * 2.0
        var bar_pos: = pos + Vector2( - bar_w / 2.0, bar_y_offset)
        drawer.draw_rect(Rect2(bar_pos - Vector2(1, 1), Vector2(bar_w + 2, bar_h + 2)), Color(0, 0, 0, 0.6), true)
        drawer.draw_rect(Rect2(bar_pos, Vector2(bar_w * life_pct, bar_h)), _hp_color(life_pct), true)




        if _alt_held:
            _draw_combatant_name(drawer, c, pos, radius, bar_y_offset)


    _draw_facing_pips(drawer, positions, offset, arena_scale)





    if debug_draw_aoe_outline:
        _draw_aoe_debug_overlay(drawer, offset, arena_scale)


    _draw_attack_pulses(drawer, positions, offset, arena_scale)




    _draw_aoe_ability_vfx(drawer, offset, arena_scale)





    _draw_hit_impact_fx(drawer, positions, offset, arena_scale)




    _render_ambient_emitters(drawer, positions, offset, arena_scale)


    _draw_heal_popups(drawer, positions, offset, arena_scale)


    _draw_second_wind_fx(drawer, positions, offset, arena_scale)
    _draw_level_up_fx(drawer, positions, offset, arena_scale)





func _build_interpolated_positions(snap_a: Dictionary, snap_b: Dictionary, frac: float) -> Array:
    var positions_a: Array = snap_a.get("positions", [])
    var positions_b: Array = snap_b.get("positions", [])

    var b_by_id: Dictionary = {}
    for entry in positions_b:
        b_by_id[entry["id"]] = entry

    var result: Array = []
    for entry_a in positions_a:
        var pos_a: Vector2 = entry_a["pos"]
        var entry_b: Dictionary = b_by_id.get(entry_a["id"], entry_a)
        var pos_b: Vector2 = entry_b.get("pos", pos_a)
        var interpolated: Dictionary = entry_a.duplicate()
        interpolated["pos"] = pos_a.lerp(pos_b, frac)
        result.append(interpolated)
    return result


func _arena_to_screen(arena_pos: Vector2, offset: Vector2, arena_scale: float) -> Vector2:
    return offset + arena_pos * arena_scale













func _draw_exile_center_glyph(drawer: Control, c: CombatantData, pos: Vector2, radius: float, state, facing_dir: Vector2, modulate: Color = Color.WHITE) -> void :
    if state == CombatEnums.CombatantState.DOWNED:
        var arm: float = radius * 0.6
        var width: float = maxf(arm * 0.22, 2.0)


        var red: = Color(1.0, 0.25, 0.25) * modulate
        drawer.draw_line(pos + Vector2( - arm, - arm), pos + Vector2(arm, arm), red, width)
        drawer.draw_line(pos + Vector2(arm, - arm), pos + Vector2( - arm, arm), red, width)
        return

    var main_weapon: Item = ExileWeaponHelper.get_main_weapon(c.source_exile)
    var offhand: Item = null
    if c.source_exile:
        offhand = c.source_exile.get_equipped_item(ItemEnums.EquipSlot.OFF_HAND)

    var main_icon: Texture2D = null
    if main_weapon and main_weapon.base_item:
        main_icon = main_weapon.base_item.icon
    var off_icon: Texture2D = null
    if offhand and offhand.base_item:
        off_icon = offhand.base_item.icon




    if main_icon != null or off_icon != null:
        var main_is_two_handed: bool = main_weapon != null and main_weapon.base_item != null\
and main_weapon.base_item.hand_type == ItemEnums.HandType.TWO_HANDED
        var hand_shift: float = radius * exile_hand_offset_ratio
        var main_overflow: float = _overflow_for_weapon(main_weapon)
        var off_overflow: float = _overflow_for_offhand(offhand)




        if main_icon != null and main_is_two_handed:
            _draw_oriented_dot_icon(drawer, main_icon, pos, radius, facing_dir, main_overflow, 0.0, modulate)
        else:


            if off_icon != null:
                _draw_oriented_dot_icon(drawer, off_icon, pos, radius, facing_dir, off_overflow, hand_shift, modulate)
            if main_icon != null:
                _draw_oriented_dot_icon(drawer, main_icon, pos, radius, facing_dir, main_overflow, - hand_shift, modulate)
        return


    var glyph_type: int = ItemEnums.WeaponType.UNARMED
    if main_weapon and main_weapon.base_item and main_weapon.base_item.category == ItemEnums.ItemCategory.WEAPON:
        glyph_type = main_weapon.base_item.weapon_type
    var glyph: String = ItemEnums.get_weapon_type_glyph(glyph_type)

    var font: Font = ThemeDB.fallback_font
    var font_size: int = int(radius * 1.0)
    var text_size: Vector2 = font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)

    var draw_pos: Vector2 = pos - Vector2(text_size.x * 0.5, - text_size.y * 0.3)



    drawer.draw_string(font, draw_pos, glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.95, 0.95, 0.95) * modulate)




func _draw_combatant_name(drawer: Control, c: CombatantData, pos: Vector2, _radius: float, bar_y_offset: float) -> void :
    if c.display_name.is_empty():
        return
    var font: Font = ThemeDB.fallback_font
    var font_size: int = 12
    var text_size: Vector2 = font.get_string_size(c.display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)

    var draw_pos: Vector2 = pos + Vector2( - text_size.x * 0.5, bar_y_offset - 6.0)
    drawer.draw_string_outline(font, draw_pos, c.display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, Color(0, 0, 0, 0.9))
    drawer.draw_string(font, draw_pos, c.display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1, 1, 1, 0.95))





func _icon_draw_rect_for_dot(icon: Texture2D, radius: float, overflow: float) -> Rect2:
    var tex_size: Vector2 = icon.get_size()
    var bound: float = radius * 2.0 * overflow
    var fit_scale: float = bound / maxf(tex_size.x, tex_size.y)
    var draw_size: Vector2 = tex_size * fit_scale
    return Rect2( - draw_size * 0.5, draw_size)






func _draw_oriented_dot_icon(
        drawer: Control, 
        icon: Texture2D, 
        pos: Vector2, 
        radius: float, 
        facing_dir: Vector2, 
        overflow: float, 
        local_x_offset: float = 0.0, 
        modulate: Color = Color.WHITE, 
) -> void :
    if icon.get_size().x <= 0.0 or icon.get_size().y <= 0.0:
        return
    var rect: Rect2 = _icon_draw_rect_for_dot(icon, radius, overflow)
    rect.position += Vector2(local_x_offset, 0.0)



    var flip_x: float = -1.0 if facing_dir.x > 0.0 else 1.0



    var max_tilt_rad: float = deg_to_rad(icon_max_tilt_deg)
    var raw_tilt: float = atan2(facing_dir.y, absf(facing_dir.x))
    raw_tilt = clampf(raw_tilt, - max_tilt_rad, max_tilt_rad)
    var tilt: float = - raw_tilt * flip_x

    drawer.draw_set_transform(pos, tilt, Vector2(flip_x, 1.0))




    drawer.draw_texture_rect(icon, rect, false, modulate)

    drawer.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)





func _draw_dot_body(drawer: Control, pos: Vector2, radius: float, base_color: Color) -> void :
    var body_color: Color = base_color
    body_color.a *= dot_body_alpha
    var feather_color: Color = body_color
    feather_color.a *= dot_feather_alpha_factor

    drawer.draw_circle(pos, radius + dot_feather_px, feather_color, true, -1.0, true)
    drawer.draw_circle(pos, radius, body_color, true, -1.0, true)






func _overflow_for_weapon(weapon: Item) -> float:
    if weapon == null or weapon.base_item == null:
        return weapon_overflow_default
    var is_two_handed: bool = weapon.base_item.hand_type == ItemEnums.HandType.TWO_HANDED
    match weapon.base_item.weapon_type:
        ItemEnums.WeaponType.SWORD:
            return weapon_overflow_sword_2h if is_two_handed else weapon_overflow_sword_1h
        ItemEnums.WeaponType.AXE:
            return weapon_overflow_axe_2h if is_two_handed else weapon_overflow_axe_1h
        ItemEnums.WeaponType.MACE:
            return weapon_overflow_mace_2h if is_two_handed else weapon_overflow_mace_1h
        ItemEnums.WeaponType.SPEAR:
            return weapon_overflow_spear_2h if is_two_handed else weapon_overflow_spear_1h
        ItemEnums.WeaponType.DAGGER:
            return weapon_overflow_dagger
        ItemEnums.WeaponType.WAND:
            return weapon_overflow_wand
        ItemEnums.WeaponType.STAFF:
            return weapon_overflow_staff
        ItemEnums.WeaponType.BOW:
            return weapon_overflow_bow
    return weapon_overflow_default




func _overflow_for_offhand(offhand: Item) -> float:
    if offhand == null or offhand.base_item == null:
        return offhand_overflow_default
    match offhand.base_item.offhand_type:
        ItemEnums.OffhandType.SHIELD: return offhand_overflow_shield
        ItemEnums.OffhandType.FOCUS: return offhand_overflow_focus
        ItemEnums.OffhandType.SCEPTRE: return offhand_overflow_sceptre
    return offhand_overflow_default






func _facing_dir_for_combatant(entry: Dictionary, positions: Array) -> Vector2:
    var target_id: int = entry.get("target_id", -1)
    if target_id < 0:
        return Vector2.LEFT

    var c: CombatantData = combat_result.combatants[entry["id"]]
    if c.source_monster and not c.source_monster.faces_target:
        return Vector2.LEFT
    var target_entry: Dictionary = _find_position_entry(positions, target_id)
    if target_entry.is_empty():
        return Vector2.LEFT
    var diff: Vector2 = target_entry["pos"] - entry["pos"]
    if diff.length_squared() < 0.0001:
        return Vector2.LEFT
    return diff.normalized()


func _find_position_entry(positions: Array, combatant_id: int) -> Dictionary:
    for entry in positions:
        if entry.get("id") == combatant_id:
            return entry
    return {}





func _snapshot_positions_at_tick(tick_seconds: float) -> Array:
    if combat_result == null or combat_result.snapshots.is_empty():
        return []
    var idx: int = clampi(
        int(floor(tick_seconds / CombatSimulation.TICK_STEP)), 
        0, 
        combat_result.snapshots.size() - 1, 
    )
    var snap: Dictionary = combat_result.snapshots[idx]
    return snap.get("positions", [])


func _radius_for(c: CombatantData) -> float:
    if c.source_monster and c.source_monster.is_unique:
        return unique_circle_radius
    if c.team == CombatEnums.CombatantTeam.EXILES:
        return ally_circle_radius
    return enemy_circle_radius


func _color_for(c: CombatantData, _state) -> Color:
    if c.team == CombatEnums.CombatantTeam.EXILES:

        if c.combat_behavior and c.combat_behavior.attack_range > 4.0:
            return ally_ranged_color
        return ally_melee_color
    if c.source_monster and c.source_monster.is_unique:
        return enemy_unique_color
    if c.combat_behavior and c.combat_behavior.attack_range > 4.0:
        return enemy_ranged_color
    return enemy_color


func _hp_color(pct: float) -> Color:
    if pct > 0.6:
        return Color("#4aaa55")
    if pct > 0.3:
        return Color("#aaaa44")
    return Color("#aa4444")













func _draw_aoe_ability_vfx(drawer: Control, offset: Vector2, arena_scale: float) -> void :
    for event in combat_result.event_log:
        if event.event_type != CombatEnums.CombatEventType.AOE_HIT:
            continue
        var age: float = current_sim_time - event.tick
        if age < 0.0 or age > ATTACK_VISUAL_TAIL_DURATION:
            continue

        var ability_ref: MonsterAbility = event.data.get("ability")
        if ability_ref == null or ability_ref.execute_vfx == null:
            continue

        var atk_id: int = event.data.get("actor_id", -1)
        var atk_c: CombatantData = combat_result.combatants[atk_id] if atk_id >= 0 else null
        if atk_c == null:
            continue

        var vfx: AttackVFX = ability_ref.execute_vfx
        var vfx_window: float = vfx.lifetime_seconds
        if age > vfx_window:
            continue



        var event_positions: Array = _snapshot_positions_at_tick(event.tick)
        var atk_entry: Dictionary = _find_position_entry(event_positions, atk_id)
        if atk_entry.is_empty():
            continue
        var atk_pos: = _arena_to_screen(atk_entry["pos"], offset, arena_scale)
        var origin: Vector2 = event.data.get("origin", Vector2.ZERO)
        var origin_screen: = _arena_to_screen(origin, offset, arena_scale)










        var shape_kind: int = ability_ref.shape
        var is_directional_shape: bool = (
            shape_kind == CombatEnums.AbilityType.LINE
            or shape_kind == CombatEnums.AbilityType.CONE
            or shape_kind == CombatEnums.AbilityType.RECTANGLE
        )
        if is_directional_shape and ability_ref.aoe_size > 0.0:
            var direction: Vector2 = event.data.get("direction", Vector2.RIGHT)
            if direction.length_squared() > 0.0001:
                var tip_units: Vector2 = origin + direction.normalized() * ability_ref.aoe_size
                origin_screen = _arena_to_screen(tip_units, offset, arena_scale)

        var fade: float = 1.0 - (age / vfx_window)





        var ctx: = {
            "lifetime_progress": age / vfx_window, 
            "weapon_range": atk_c.combat_behavior.attack_range\
if atk_c.combat_behavior else 1.5, 
            "arena_scale": arena_scale, 
            "def_radius": _radius_for(atk_c), 
            "color": _pulse_color_for(atk_c, false, fade), 
            "crit": false, 
            "seed": int(event.tick * 1000.0) ^ (atk_id << 16), 
        }
        vfx.draw(drawer, atk_pos, origin_screen, ctx)













static var debug_draw_aoe_outline: bool = false



const DEBUG_AOE_OUTLINE_LIFETIME: float = 1.0







const DEBUG_AOE_LINE_WIDTH_UNITS: float = 1.5
const DEBUG_AOE_RECT_WIDTH_UNITS: float = 2.0
const DEBUG_AOE_CONE_HALF_ANGLE_RAD: float = PI / 6.0










func _draw_aoe_debug_overlay(drawer: Control, offset: Vector2, arena_scale: float) -> void :
    for event in combat_result.event_log:
        if event.event_type != CombatEnums.CombatEventType.AOE_HIT:
            continue
        var age: float = current_sim_time - event.tick
        if age < 0.0 or age > DEBUG_AOE_OUTLINE_LIFETIME:
            continue

        var ability_ref: MonsterAbility = event.data.get("ability")
        if ability_ref == null:
            continue
        var aoe_size: float = ability_ref.aoe_size
        if aoe_size <= 0.0:
            continue

        var origin: Vector2 = event.data.get("origin", Vector2.ZERO)
        var origin_screen: Vector2 = _arena_to_screen(origin, offset, arena_scale)



        var fade: float = 1.0
        var hold_seconds: float = 0.5
        if age > hold_seconds:
            fade = 1.0 - (age - hold_seconds) / (DEBUG_AOE_OUTLINE_LIFETIME - hold_seconds)
        var color: = Color(1.0, 0.0, 1.0, 0.85 * fade)
        var stroke_width: float = 1.5
        var crosshair_px: float = 6.0
        var label: String = "%s (%.1fm)" % [ability_ref.ability_id, aoe_size]
        var label_anchor: Vector2 = origin_screen

        match ability_ref.shape:
            CombatEnums.AbilityType.CIRCLE:
                var radius_screen: float = aoe_size * arena_scale
                drawer.draw_arc(origin_screen, radius_screen, 0.0, TAU, 64, color, stroke_width)
                label_anchor = origin_screen + Vector2(radius_screen + 6.0, 4.0)

            CombatEnums.AbilityType.CONE:



                var direction: Vector2 = event.data.get("direction", Vector2.RIGHT)
                if direction.length_squared() < 0.0001:
                    direction = Vector2.RIGHT
                var base_angle: float = direction.angle()
                var left_angle: float = base_angle - DEBUG_AOE_CONE_HALF_ANGLE_RAD
                var right_angle: float = base_angle + DEBUG_AOE_CONE_HALF_ANGLE_RAD
                var length_screen: float = aoe_size * arena_scale
                var left_tip: Vector2 = origin_screen + Vector2.from_angle(left_angle) * length_screen
                var right_tip: Vector2 = origin_screen + Vector2.from_angle(right_angle) * length_screen
                drawer.draw_line(origin_screen, left_tip, color, stroke_width)
                drawer.draw_line(origin_screen, right_tip, color, stroke_width)

                drawer.draw_arc(origin_screen, length_screen, left_angle, right_angle, 
                    24, color, stroke_width)

                var tip_centre: Vector2 = origin_screen + Vector2.from_angle(base_angle) * length_screen
                label_anchor = tip_centre + Vector2(6.0, 4.0)

            CombatEnums.AbilityType.LINE:



                var direction: Vector2 = event.data.get("direction", Vector2.RIGHT)
                if direction.length_squared() < 0.0001:
                    direction = Vector2.RIGHT
                direction = direction.normalized()
                var centre_units: Vector2 = origin + direction * (aoe_size * 0.5)
                _draw_aoe_debug_rectangle(drawer, centre_units, direction, aoe_size, 
                    DEBUG_AOE_LINE_WIDTH_UNITS, offset, arena_scale, color, stroke_width)
                var line_tip_screen: Vector2 = _arena_to_screen(
                    origin + direction * aoe_size, offset, arena_scale)
                label_anchor = line_tip_screen + Vector2(6.0, 4.0)

            CombatEnums.AbilityType.RECTANGLE:



                var direction: Vector2 = event.data.get("direction", Vector2.RIGHT)
                if direction.length_squared() < 0.0001:
                    direction = Vector2.RIGHT
                direction = direction.normalized()
                var centre_units: Vector2 = origin + direction * (aoe_size * 0.5)
                _draw_aoe_debug_rectangle(drawer, centre_units, direction, aoe_size, 
                    DEBUG_AOE_RECT_WIDTH_UNITS, offset, arena_scale, color, stroke_width)
                var rect_tip_screen: Vector2 = _arena_to_screen(
                    origin + direction * aoe_size, offset, arena_scale)
                label_anchor = rect_tip_screen + Vector2(6.0, 4.0)

            _:


                label_anchor = origin_screen + Vector2(crosshair_px + 4.0, 4.0)


        drawer.draw_line(origin_screen + Vector2( - crosshair_px, 0), 
            origin_screen + Vector2(crosshair_px, 0), color, 1.0)
        drawer.draw_line(origin_screen + Vector2(0, - crosshair_px), 
            origin_screen + Vector2(0, crosshair_px), color, 1.0)

        drawer.draw_string(ThemeDB.fallback_font, label_anchor, 
            label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, color)






func _draw_aoe_debug_rectangle(drawer: Control, centre_units: Vector2, forward: Vector2, 
        length_units: float, width_units: float, offset: Vector2, arena_scale: float, 
        color: Color, stroke_width: float) -> void :

    var side: Vector2 = Vector2( - forward.y, forward.x)
    var half_len: float = length_units * 0.5
    var half_wid: float = width_units * 0.5
    var c0_units: Vector2 = centre_units + forward * half_len + side * half_wid
    var c1_units: Vector2 = centre_units + forward * half_len - side * half_wid
    var c2_units: Vector2 = centre_units - forward * half_len - side * half_wid
    var c3_units: Vector2 = centre_units - forward * half_len + side * half_wid
    var c0: Vector2 = _arena_to_screen(c0_units, offset, arena_scale)
    var c1: Vector2 = _arena_to_screen(c1_units, offset, arena_scale)
    var c2: Vector2 = _arena_to_screen(c2_units, offset, arena_scale)
    var c3: Vector2 = _arena_to_screen(c3_units, offset, arena_scale)
    drawer.draw_line(c0, c1, color, stroke_width)
    drawer.draw_line(c1, c2, color, stroke_width)
    drawer.draw_line(c2, c3, color, stroke_width)
    drawer.draw_line(c3, c0, color, stroke_width)









func _draw_attack_pulses(drawer: Control, positions: Array, offset: Vector2, arena_scale: float) -> void :


    for event in combat_result.event_log:
        if event.event_type != CombatEnums.CombatEventType.DAMAGE_DEALT:
            continue
        var age: float = current_sim_time - event.tick
        if age < 0.0 or age > ATTACK_VISUAL_TAIL_DURATION:
            continue

        var atk_id: int = event.data.get("attacker_id", -1)
        var def_id: int = event.data.get("defender_id", -1)



        var event_positions: Array = _snapshot_positions_at_tick(event.tick)
        var atk_entry: Dictionary = _find_position_entry(event_positions, atk_id)
        var def_entry: Dictionary = _find_position_entry(event_positions, def_id)
        if def_entry.is_empty():
            continue




        var atk_c: CombatantData = combat_result.combatants[atk_id] if atk_id >= 0 else null


        var ability_resource: MonsterAbility = event.data.get("ability")
        var vfx: AttackVFX = atk_c.get_ability_vfx(ability_resource) if atk_c else null
        var vfx_window: float = vfx.lifetime_seconds if vfx else 0.4



        var vfx_visible: bool = age <= vfx_window
        var popup_visible: bool = age <= popup_lifetime
        if not vfx_visible and not popup_visible:
            continue





        var def_pos_units: Vector2 = def_entry["pos"]
        var def_pos_live_units: Vector2 = def_pos_units
        if vfx != null and vfx.homes_on_target:
            var live_def_entry: Dictionary = _find_position_entry(positions, def_id)
            if not live_def_entry.is_empty():
                def_pos_live_units = live_def_entry["pos"]
        var def_pos: = _arena_to_screen(def_pos_units, offset, arena_scale)
        var def_pos_live: = _arena_to_screen(def_pos_live_units, offset, arena_scale)
        var vfx_fade: float = 1.0 - clampf(age / maxf(vfx_window, 0.0001), 0.0, 1.0)
        var crit: bool = event.data.get("is_crit", false)
        var dmg: float = event.data.get("total", 0.0)



        var def_c: CombatantData = combat_result.combatants[def_id]
        var def_radius: float = _radius_for(def_c)







        var is_aoe_hit: bool = ability_resource != null\
and ability_resource.shape != CombatEnums.AbilityType.SINGLE_TARGET





        if vfx_visible and vfx != null and not atk_entry.is_empty() and not is_aoe_hit:
            var atk_pos: = _arena_to_screen(atk_entry["pos"], offset, arena_scale)
            var pulse_color: Color = _pulse_color_for(atk_c, crit, vfx_fade)
            var ctx: = {
                "lifetime_progress": age / vfx_window, 
                "weapon_range": atk_c.combat_behavior.attack_range\
if atk_c.combat_behavior else 1.5, 
                "arena_scale": arena_scale, 
                "def_radius": def_radius, 
                "color": pulse_color, 
                "crit": crit, 

                "seed": int(event.tick * 1000.0) ^ (atk_id << 16), 
            }


            vfx.draw(drawer, atk_pos, def_pos_live, ctx)




        if not popup_visible:
            continue






        var rounded_dmg: int = int(round(dmg))
        if rounded_dmg <= 0:
            continue

        var base_font: int = int(maxf(def_radius * popup_damage_font_radius_mult, popup_damage_font_min))
        var crit_scale_factor: float = popup_damage_crit_scale if crit else 1.0
        var direction: int = _popup_directions.get(event.get_instance_id(), 1)


        var motion: Dictionary = _popup_motion(age, direction, event.tick + float(def_id) * 0.137)
        if motion.is_empty():
            continue
        var pop_scale: float = motion["scale"]
        var alpha: float = motion["alpha"]
        var arc_offset: Vector2 = motion["offset"]
        var font_size: int = int(base_font * crit_scale_factor * pop_scale)



        var spawn_jitter: Vector2 = _popup_scatter(event.tick, def_id) * 0.5
        var anchor_offset: Vector2 = Vector2( - font_size * 0.35, - def_radius - popup_spawn_above_dot_px) + spawn_jitter
        var float_offset: Vector2 = anchor_offset + arc_offset
        var text_color: Color
        if crit:

            var pop_in_norm: float = clampf(age / popup_pop_in_seconds, 0.0, 1.0)
            text_color = Color(1.0, 1.0, 0.8, alpha).lerp(Color(1.0, 0.85, 0.3, alpha), pop_in_norm)
        else:
            text_color = Color(1.0, 0.92, 0.78, alpha * 0.95)
        var text: String = ("%d!" % rounded_dmg) if crit else ("%d" % rounded_dmg)


        var outline_color: = Color(0, 0, 0, text_color.a * 0.85)
        drawer.draw_string_outline(
            ThemeDB.fallback_font, def_pos + float_offset, 
            text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, 5, outline_color, 
        )
        drawer.draw_string(
            ThemeDB.fallback_font, def_pos + float_offset, 
            text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, text_color, 
        )







func _popup_scatter(event_tick: float, combatant_id: int) -> Vector2:

    var x_jitter: float = fposmod(event_tick * 137.0 + combatant_id * 41.0, 24.0) - 12.0
    var y_jitter: float = fposmod(event_tick * 91.0 + combatant_id * 17.0, 10.0) - 5.0
    return Vector2(x_jitter, y_jitter)








func _build_popup_directions() -> void :
    _popup_directions.clear()
    if not combat_result:
        return
    var target_counts: Dictionary = {}
    for event in combat_result.event_log:
        var target_id: int = -1
        match event.event_type:
            CombatEnums.CombatEventType.DAMAGE_DEALT:
                target_id = event.data.get("defender_id", -1)
            CombatEnums.CombatEventType.LIFE_LEECH, \
CombatEnums.CombatEventType.LIFE_GAIN_ON_HIT:
                target_id = event.data.get("combatant_id", -1)
            _:
                continue
        if target_id < 0:
            continue
        var idx: int = target_counts.get(target_id, 0)



        _popup_directions[event.get_instance_id()] = _resolve_popup_direction(idx)
        target_counts[target_id] = idx + 1





func _resolve_popup_direction(alt_idx: int) -> int:
    match popup_side_mode:
        PopupSideMode.RIGHT_ONLY:
            return 1
        PopupSideMode.LEFT_ONLY:
            return -1
        PopupSideMode.ALTERNATE:
            return 1 if (alt_idx % 2 == 0) else -1
    return 1














func _popup_motion(age: float, direction: int, seed_value: float) -> Dictionary:
    if age < 0.0 or age > popup_lifetime:
        return {}

    var pop_in_end: float = popup_pop_in_seconds
    var hold_end: float = pop_in_end + popup_hold_seconds


    var pop_scale: float
    var alpha: float = 1.0
    var exit_progress: float = 0.0

    if age < pop_in_end:

        var pop_t: float = age / pop_in_end
        pop_scale = lerp(popup_start_scale, popup_overshoot_scale, ease(pop_t, 0.35))
    elif age < hold_end:

        var hold_t: float = (age - pop_in_end) / popup_hold_seconds
        pop_scale = lerp(popup_overshoot_scale, 1.0, ease(hold_t, 0.4))
    else:


        pop_scale = 1.0
        var exit_window: float = popup_lifetime - hold_end
        exit_progress = clampf((age - hold_end) / exit_window, 0.0, 1.0)
        alpha = 1.0 - ease(exit_progress, 0.25)





    var vertical_sign: float = 1.0 if popup_arc_inverted else -1.0
    var scatter_deg: float = fposmod(seed_value * 7.31, popup_exit_angle_scatter_deg)
    var lean_deg: float = popup_exit_angle_base_deg + scatter_deg
    var base_angle_deg: float = 90.0 * vertical_sign
    var angle_rad: float = deg_to_rad(base_angle_deg + float(direction) * lean_deg)
    var exit_dir: Vector2 = Vector2(cos(angle_rad), sin(angle_rad))




    var eased_t: float = ease(exit_progress, 0.3)
    var travel: Vector2 = exit_dir * (popup_rise_px * eased_t)







    var horizontal_sign: float = -1.0 if popup_arc_flip_horizontal else 1.0
    var perp_outward: Vector2 = Vector2( - exit_dir.y, exit_dir.x) * float(direction) * horizontal_sign
    var bow_dir_raw: Vector2 = perp_outward * (1.0 - popup_arc_upward_bias)\
+ Vector2(0.0, vertical_sign) * popup_arc_upward_bias
    var bow_dir: Vector2 = bow_dir_raw.normalized()




    var bow_magnitude: float = sin(exit_progress * PI) * popup_arc_bow_px
    var motion_offset: Vector2 = travel + bow_dir * bow_magnitude

    return {"scale": pop_scale, "offset": motion_offset, "alpha": alpha}







func _draw_heal_popups(drawer: Control, positions: Array, offset: Vector2, arena_scale: float) -> void :
    for event in combat_result.event_log:
        if event.event_type != CombatEnums.CombatEventType.LIFE_LEECH\
and event.event_type != CombatEnums.CombatEventType.LIFE_GAIN_ON_HIT:
            continue
        var age: float = current_sim_time - event.tick
        if age < 0.0 or age > popup_lifetime:
            continue
        var combatant_id: int = event.data.get("combatant_id", -1)
        var entry: Dictionary = _find_position_entry(positions, combatant_id)
        if entry.is_empty():
            continue
        var c: CombatantData = combat_result.combatants[combatant_id]
        var pos: = _arena_to_screen(entry["pos"], offset, arena_scale)
        var radius: float = _radius_for(c)
        var amount: float = event.data.get("amount", 0.0)
        var rounded_amount: int = int(round(amount))
        if rounded_amount <= 0:
            continue

        var base_font: int = int(maxf(radius * popup_heal_font_radius_mult, popup_heal_font_min))
        var direction: int = _popup_directions.get(event.get_instance_id(), 1)
        var motion: Dictionary = _popup_motion(age, direction, event.tick + float(combatant_id) * 0.191)
        if motion.is_empty():
            continue
        var pop_scale: float = motion["scale"]
        var alpha: float = motion["alpha"]
        var arc_offset: Vector2 = motion["offset"]
        var font_size: int = int(base_font * pop_scale)
        var spawn_jitter: Vector2 = _popup_scatter(event.tick, combatant_id) * 0.5
        var anchor_offset: Vector2 = Vector2( - font_size * 0.35, - radius - popup_spawn_above_dot_px) + spawn_jitter
        var float_offset: Vector2 = anchor_offset + arc_offset
        var heal_color: = Color(0.55, 1.0, 0.55, alpha * 0.95)
        var outline_color: = Color(0, 0, 0, heal_color.a * 0.85)
        drawer.draw_string_outline(
            ThemeDB.fallback_font, pos + float_offset, 
            "+%d" % rounded_amount, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, 4, outline_color, 
        )
        drawer.draw_string(
            ThemeDB.fallback_font, pos + float_offset, 
            "+%d" % rounded_amount, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, heal_color, 
        )



func _pulse_color_for(attacker: CombatantData, crit: bool, fade: float) -> Color:
    var base: Color
    if attacker.team == CombatEnums.CombatantTeam.EXILES:
        base = Color(0.6, 1.0, 0.7)
    else:
        base = Color(1.0, 0.45, 0.4)
    if crit:
        base = base.lerp(Color(1.0, 0.85, 0.3), 0.5)
    base.a = fade
    return base




func _draw_second_wind_fx(drawer: Control, positions: Array, offset: Vector2, arena_scale: float) -> void :
    var window: float = 0.6
    for event in combat_result.event_log:
        if event.event_type != CombatEnums.CombatEventType.SECOND_WIND:
            continue
        var age: float = current_sim_time - event.tick
        if age < 0.0 or age > window:
            continue
        var combatant_id: int = event.data.get("combatant_id", -1)
        var entry: Dictionary = _find_position_entry(positions, combatant_id)
        if entry.is_empty():
            continue
        var c: CombatantData = combat_result.combatants[combatant_id]
        var pos: = _arena_to_screen(entry["pos"], offset, arena_scale)
        var radius: float = _radius_for(c)
        var phase: float = age / window
        var fade: float = 1.0 - phase


        var halo_radius: float = radius * (1.0 + phase * 0.4)
        var halo_thickness: float = maxf(radius * 0.18, 3.0)
        var halo_color: = Color(0.55, 1.0, 0.65, fade * 0.7)
        drawer.draw_arc(pos, halo_radius, 0.0, TAU, 48, halo_color, halo_thickness)


        var inner_color: = Color(0.7, 1.0, 0.75, fade * 0.3)
        drawer.draw_circle(pos, radius + 1.5, inner_color)


        var bar_w: float = radius * 2.5
        var bar_h: float = maxf(radius * 0.35, 4.0)
        var bar_y_offset: float = - radius - bar_h * 2.0
        var bar_top_left: = pos + Vector2( - bar_w / 2.0, bar_y_offset)
        var overlay_color: = Color(0.55, 1.0, 0.65, fade * 0.55)
        drawer.draw_rect(Rect2(bar_top_left, Vector2(bar_w, bar_h)), overlay_color, true)




func _draw_level_up_fx(drawer: Control, positions: Array, offset: Vector2, arena_scale: float) -> void :
    var window: float = 0.5
    for event in combat_result.event_log:
        if event.event_type != CombatEnums.CombatEventType.LEVEL_UP:
            continue
        var age: float = current_sim_time - event.tick
        if age < 0.0 or age > window:
            continue
        var combatant_id: int = event.data.get("combatant_id", -1)
        var entry: Dictionary = _find_position_entry(positions, combatant_id)
        if entry.is_empty():
            continue
        var c: CombatantData = combat_result.combatants[combatant_id]
        var pos: = _arena_to_screen(entry["pos"], offset, arena_scale)
        var radius: float = _radius_for(c)
        var phase: float = age / window
        var fade: float = 1.0 - phase


        var ring_thickness: float = maxf(radius * 0.18, 3.0)
        for i in range(3):
            var ring_phase: float = phase + (i * 0.18)
            if ring_phase > 1.0:
                continue
            var ring_radius: float = radius * (1.0 + ring_phase * 1.6)
            var ring_alpha: float = (1.0 - ring_phase) * 0.85
            var ring_color: = Color(1.0, 0.85, 0.3, ring_alpha)
            drawer.draw_arc(pos, ring_radius, 0.0, TAU, 48, ring_color, ring_thickness)


        var glow_color: = Color(1.0, 0.9, 0.45, fade * 0.85)
        drawer.draw_circle(pos, radius + fade * (radius * 0.25), glow_color)


        var text_alpha: float = clampf(minf(phase * 4.0, 1.0), 0.0, 1.0) * fade
        var text_color: = Color(1.0, 0.85, 0.3, text_alpha)
        var text_font_size: int = int(maxf(radius * 1.3, 24.0))
        var text_rise: float = phase * (radius * 1.5)
        var text_offset: = Vector2( - text_font_size * 1.8, - radius * 1.8 - text_rise)
        drawer.draw_string(
            ThemeDB.fallback_font, pos + text_offset, 
            "LEVEL UP!", HORIZONTAL_ALIGNMENT_LEFT, -1.0, text_font_size, text_color, 
        )





















func _build_drop_visuals() -> void :
    _drops.clear()
    _drop_overflow_labels.clear()
    if not combat_result:
        return

    var encounter_loot: LootResolver.EncounterLoot = _get_current_encounter_loot()
    if not encounter_loot:
        return


    for event in combat_result.event_log:
        if event.event_type != CombatEnums.CombatEventType.DEATH:
            continue
        var combatant_id: int = event.data.get("combatant_id", -1)
        if combatant_id < 0:
            continue

        var victim: CombatantData = combat_result.combatants[combatant_id]
        if not victim or victim.team != CombatEnums.CombatantTeam.MONSTERS:
            continue
        var per_kill: Dictionary = encounter_loot.per_kill_drops.get(combatant_id, {})
        if per_kill.is_empty():
            continue
        var spawn_pos: Vector2 = _resolve_corpse_position(combatant_id, event.tick)
        _emit_drop_pile(per_kill, event.tick, spawn_pos, combatant_id, victim)



    if encounter_loot.bonus_source_combatant_id >= 0 and not encounter_loot.bonus_drops.is_empty():
        var src_id: int = encounter_loot.bonus_source_combatant_id
        var src_combatant: CombatantData = combat_result.combatants[src_id]


        var bonus_tick: float = _max_sim_time()
        var bonus_pos: Vector2 = _resolve_corpse_position(src_id, bonus_tick)
        _emit_drop_pile(encounter_loot.bonus_drops, bonus_tick, bonus_pos, src_id, src_combatant)






func _get_current_encounter_loot() -> LootResolver.EncounterLoot:
    if not _runner or not combat_result:
        return null
    for outcome in _runner.encounter_outcomes:
        if outcome.get("combat_result") == combat_result:
            return outcome.get("loot")
    return null





func _resolve_corpse_position(combatant_id: int, at_tick: float) -> Vector2:
    var snap_positions: Array = _snapshot_positions_at_tick(at_tick)
    var entry: Dictionary = _find_position_entry(snap_positions, combatant_id)
    if entry.is_empty():


        return Vector2(combat_result.encounter.arena_width * 0.5, combat_result.encounter.arena_height * 0.5)
    return entry["pos"]







func _emit_drop_pile(
    bundle: Dictionary, 
    spawn_tick: float, 
    spawn_pos: Vector2, 
    source_id: int, 
    src_combatant: CombatantData, 
) -> void :


    var rng_seed: int = hash([source_id, int(spawn_tick * 1000.0)])

    var pile_index: int = 0
    pile_index = _push_currency_drops(
        "chaos", int(bundle.get("chaos", 0)), DROP_SPRITE_CHAOS, 
        spawn_tick, spawn_pos, rng_seed, pile_index, true, 
    )


    pile_index = _push_currency_drops(
        "exalt", int(bundle.get("exalt", 0)), DROP_SPRITE_EXALT, 
        spawn_tick, spawn_pos, rng_seed, pile_index, true, 
    )
    pile_index = _push_currency_drops(
        "scrap", int(bundle.get("scrap", 0)), DROP_SPRITE_SCRAP, 
        spawn_tick, spawn_pos, rng_seed, pile_index, false, 
    )
    pile_index = _push_currency_drops(
        "food", int(bundle.get("food", 0)), DROP_SPRITE_FOOD, 
        spawn_tick, spawn_pos, rng_seed, pile_index, false, 
    )

    var items: Array = bundle.get("items", [])
    var unique_source: bool = src_combatant != null and src_combatant.source_monster != null\
and src_combatant.source_monster.is_unique
    pile_index = _push_item_drops(items, spawn_tick, spawn_pos, rng_seed, pile_index, unique_source)





func _push_currency_drops(
    kind: String, 
    count: int, 
    texture: Texture2D, 
    spawn_tick: float, 
    spawn_pos: Vector2, 
    rng_seed: int, 
    pile_index: int, 
    is_premium: bool, 
) -> int:
    if count <= 0:
        return pile_index
    var color: Color = _currency_drop_color(kind)
    var visible_count: int = mini(count, DROP_PILE_CAP)
    for i in visible_count:
        _drops.append({
            "spawn_tick": spawn_tick, 
            "spawn_pos": spawn_pos, 
            "settle_offset": _deterministic_fan_offset(rng_seed, pile_index), 
            "kind": kind, 
            "color": color, 
            "is_premium": is_premium, 
            "texture": texture, 
        })
        pile_index += 1
    if count > visible_count:
        _drop_overflow_labels.append({
            "spawn_tick": spawn_tick, 
            "pos": spawn_pos, 
            "text": "+%d %s" % [count - visible_count, kind], 
            "color": color, 
        })
    return pile_index




func _push_item_drops(
    items: Array, 
    spawn_tick: float, 
    spawn_pos: Vector2, 
    rng_seed: int, 
    pile_index: int, 
    unique_source_monster: bool, 
) -> int:
    if items.is_empty():
        return pile_index
    var visible_count: int = mini(items.size(), DROP_PILE_CAP)
    for i in visible_count:
        var item: Item = items[i]




        var is_currency_item: bool = item.base_item != null\
and item.base_item.category == ItemEnums.ItemCategory.CURRENCY
        if is_currency_item:



            var currency_kind: String = "vaal" if item.base_item.item_id == "vaal_orb" else "currency"
            _drops.append({
                "spawn_tick": spawn_tick, 
                "spawn_pos": spawn_pos, 
                "settle_offset": _deterministic_fan_offset(rng_seed, pile_index), 
                "kind": currency_kind, 
                "color": _currency_drop_color(currency_kind), 
                "is_premium": true, 
                "is_monster_infrequent": false, 
                "texture": item.base_item.icon, 
            })
            pile_index += 1
            continue




        var effective_rarity: int = item.rarity
        if unique_source_monster:
            effective_rarity = Item.Rarity.UNIQUE
        var color: Color = RarityColors.get_item_color(effective_rarity)
        var premium: bool = effective_rarity >= Item.Rarity.RARE


        var mi_drop: bool = item.base_item != null and item.base_item.is_monster_infrequent
        _drops.append({
            "spawn_tick": spawn_tick, 
            "spawn_pos": spawn_pos, 
            "settle_offset": _deterministic_fan_offset(rng_seed, pile_index), 
            "kind": "item", 
            "color": color, 
            "is_premium": premium, 
            "is_monster_infrequent": mi_drop, 
            "texture": null, 
        })
        pile_index += 1
    if items.size() > visible_count:
        _drop_overflow_labels.append({
            "spawn_tick": spawn_tick, 
            "pos": spawn_pos, 
            "text": "+%d items" % (items.size() - visible_count), 
            "color": Color(0.9, 0.85, 0.7), 
        })
    return pile_index








func _currency_drop_color(kind: String) -> Color:
    match kind:
        "chaos":
            return RarityColors.RARE
        "exalt":
            return Color(0.4, 0.65, 1.0)
        "vaal":
            return Color(0.95, 0.2, 0.25)
        "scrap":
            return Color(0.78, 0.78, 0.82)
        "food":
            return Color(0.85, 0.65, 0.4)
        _:
            return Color.WHITE





func _deterministic_fan_offset(rng_seed: int, pile_index: int) -> Vector2:


    var golden_angle: float = 2.39996323

    var seed_angle: float = float(rng_seed & 65535) / 65535.0 * TAU
    var radius: float = sqrt(float(pile_index) + 0.5) * (DROP_PILE_FAN_RADIUS / sqrt(float(DROP_PILE_CAP)))
    var angle: float = seed_angle + float(pile_index) * golden_angle
    return Vector2(cos(angle), sin(angle)) * radius






func _draw_item_drops(drawer: Control, offset: Vector2, arena_scale: float) -> void :
    for drop in _drops:
        var drop_age: float = current_sim_time - drop["spawn_tick"]
        if drop_age < 0.0:
            continue
        _render_one_drop(drawer, drop, drop_age, offset, arena_scale)




    for overflow in _drop_overflow_labels:
        var overflow_age: float = current_sim_time - overflow["spawn_tick"]
        if overflow_age < DROP_FLY_DURATION:
            continue
        var screen_pos: = _arena_to_screen(overflow["pos"], offset, arena_scale)
        var overflow_text: String = overflow["text"]
        var overflow_color: Color = overflow["color"]
        var font: Font = ThemeDB.fallback_font
        var font_size: int = 11
        var text_size: Vector2 = font.get_string_size(overflow_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
        var draw_pos: Vector2 = screen_pos + Vector2( - text_size.x * 0.5, - DROP_PREMIUM_BEAM_HEIGHT - 4.0)
        drawer.draw_string_outline(font, draw_pos, overflow_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 2, Color(0, 0, 0, 0.85))
        drawer.draw_string(font, draw_pos, overflow_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, overflow_color)







func _render_one_drop(drawer: Control, drop: Dictionary, age: float, offset: Vector2, arena_scale: float) -> void :
    var spawn_units: Vector2 = drop["spawn_pos"]
    var landing_units: Vector2 = spawn_units + drop["settle_offset"]
    var pos_units: Vector2
    var arc_lift_px: float = 0.0

    if age < DROP_FLY_DURATION:

        var t: float = age / DROP_FLY_DURATION
        pos_units = spawn_units.lerp(landing_units, t)

        arc_lift_px = 4.0 * t * (1.0 - t) * DROP_ARC_HEIGHT * arena_scale
    else:
        pos_units = landing_units

    var screen_pos: = _arena_to_screen(pos_units, offset, arena_scale)
    screen_pos.y -= arc_lift_px

    var color: Color = drop["color"]
    var settled: bool = age >= DROP_FLY_DURATION
    var is_premium: bool = drop["is_premium"]




    if settled and is_premium:
        _draw_premium_beam(drawer, screen_pos, color)
        _draw_premium_glow(drawer, screen_pos, color)




    if settled and drop.get("is_monster_infrequent", false):
        _draw_monster_infrequent_halo(drawer, screen_pos)


    var texture: Texture2D = drop.get("texture")
    if texture != null:


        var sprite_size: Vector2 = Vector2(DROP_CURRENCY_SPRITE_PX, DROP_CURRENCY_SPRITE_PX)
        var rect: = Rect2(screen_pos - sprite_size * 0.5, sprite_size)
        drawer.draw_texture_rect(texture, rect, false, Color(1, 1, 1, 1))
    else:

        var core_color: Color = color.lerp(Color.WHITE, 0.45)
        drawer.draw_circle(screen_pos, DROP_ITEM_RADIUS_PX + 1.5, Color(color.r, color.g, color.b, 0.55))
        drawer.draw_circle(screen_pos, DROP_ITEM_RADIUS_PX, color)
        drawer.draw_circle(screen_pos, DROP_ITEM_RADIUS_PX * 0.45, core_color)



    if settled:
        _draw_sparkle(drawer, drop, screen_pos)





func _draw_premium_beam(drawer: Control, screen_pos: Vector2, color: Color) -> void :

    var pulse: float = 0.85 + 0.15 * sin(current_sim_time * 4.5)
    var slice_count: int = 8
    var beam_width: float = 2.5
    for i in slice_count:
        var t: float = float(i) / float(slice_count - 1)
        var slice_alpha: float = (1.0 - t) * 0.55 * pulse
        var slice_y: float = screen_pos.y - t * DROP_PREMIUM_BEAM_HEIGHT
        drawer.draw_rect(
            Rect2(screen_pos.x - beam_width * 0.5, slice_y, beam_width, DROP_PREMIUM_BEAM_HEIGHT / float(slice_count) + 0.5), 
            Color(color.r, color.g, color.b, slice_alpha), 
            true, 
        )



func _draw_premium_glow(drawer: Control, screen_pos: Vector2, color: Color) -> void :
    var pulse: float = 0.7 + 0.3 * sin(current_sim_time * 3.2)

    drawer.draw_circle(screen_pos, 10.0, Color(color.r, color.g, color.b, 0.1 * pulse))
    drawer.draw_circle(screen_pos, 6.0, Color(color.r, color.g, color.b, 0.2 * pulse))






const MI_HALO_COLOR: = Color(0.69, 0.125, 0.847)
func _draw_monster_infrequent_halo(drawer: Control, screen_pos: Vector2) -> void :
    var pulse: float = 0.65 + 0.35 * sin(current_sim_time * 2.1)


    drawer.draw_circle(screen_pos, 16.0, Color(MI_HALO_COLOR.r, MI_HALO_COLOR.g, MI_HALO_COLOR.b, 0.08 * pulse))
    drawer.draw_circle(screen_pos, 13.0, Color(MI_HALO_COLOR.r, MI_HALO_COLOR.g, MI_HALO_COLOR.b, 0.14 * pulse))
    drawer.draw_circle(screen_pos, 10.5, Color(MI_HALO_COLOR.r, MI_HALO_COLOR.g, MI_HALO_COLOR.b, 0.22 * pulse))





func _draw_sparkle(drawer: Control, drop: Dictionary, screen_pos: Vector2) -> void :
    var cadence_seed: float = drop["spawn_tick"] + drop["settle_offset"].x * 7.3 + drop["settle_offset"].y * 3.1

    var phase: float = fposmod(current_sim_time + cadence_seed, 2.0)
    if phase > 0.4:
        return

    var sparkle_offset: = Vector2(
        3.0 + drop["settle_offset"].x * 4.0, 
        -3.0 - drop["settle_offset"].y * 4.0, 
    )
    var sparkle_alpha: float = sin(phase / 0.4 * PI)
    drawer.draw_circle(screen_pos + sparkle_offset, 1.4, Color(1, 1, 1, sparkle_alpha * 0.9))






















func _impact_tick_for_event(event: CombatEvent, attacker_vfx: AttackVFX) -> float:
    var lifetime: float = FALLBACK_VFX_LIFETIME
    var landing: float = 1.0
    if attacker_vfx != null:
        lifetime = attacker_vfx.lifetime_seconds
        landing = attacker_vfx.impact_landing_progress
    return event.tick + lifetime * landing




func _impact_fx_for_event(attacker_vfx: AttackVFX) -> HitImpactFX:
    if attacker_vfx != null and attacker_vfx.impact_fx != null:
        return attacker_vfx.impact_fx
    return DEFAULT_IMPACT_FX








func _build_impact_stains() -> void :
    _impact_stains.clear()
    if not combat_result:
        return

    for event in combat_result.event_log:
        if event.event_type != CombatEnums.CombatEventType.DAMAGE_DEALT:
            continue
        var attacker_id: int = event.data.get("attacker_id", -1)
        var defender_id: int = event.data.get("defender_id", -1)
        if attacker_id < 0 or defender_id < 0:
            continue

        var atk_c: CombatantData = combat_result.combatants[attacker_id]


        var ability_resource: MonsterAbility = event.data.get("ability")
        var attacker_vfx: AttackVFX = atk_c.get_ability_vfx(ability_resource) if atk_c else null
        var impact_fx: HitImpactFX = _impact_fx_for_event(attacker_vfx)
        if impact_fx == null or impact_fx.decay_mode == HitImpactFX.DecayMode.FADE_WITH_PARTICLE:
            continue



        if impact_fx.particle_style == HitImpactFX.ParticleStyle.STATIC_ARC:
            continue


        var event_positions: Array = _snapshot_positions_at_tick(event.tick)
        var atk_entry: Dictionary = _find_position_entry(event_positions, attacker_id)
        var def_entry: Dictionary = _find_position_entry(event_positions, defender_id)
        if atk_entry.is_empty() or def_entry.is_empty():
            continue

        var atk_pos: Vector2 = atk_entry["pos"]
        var def_pos: Vector2 = def_entry["pos"]

        var impact_tick: float = _impact_tick_for_event(event, attacker_vfx)
        var stain_tick: float = impact_tick + impact_fx.lifetime_seconds




        var attack_dir: Vector2 = (def_pos - atk_pos).normalized()
        if attack_dir.length_squared() < 0.001:


            attack_dir = Vector2(0, 1)





        if impact_fx.lock_to_target:
            var impact_positions: Array = _snapshot_positions_at_tick(impact_tick)
            var impact_def_entry: Dictionary = _find_position_entry(impact_positions, defender_id)
            if not impact_def_entry.is_empty():
                def_pos = impact_def_entry["pos"]

        var base_angle: float = attack_dir.angle() + impact_fx.direction_bias_radians

        var is_crit: bool = bool(event.data.get("is_crit", false))
        var count: int = impact_fx.get_effective_particle_count(is_crit)
        var speed_max_eff: float = impact_fx.get_effective_speed_max(is_crit)



        var rng: = RandomNumberGenerator.new()
        rng.seed = hash([int(event.tick * 1000.0), defender_id])

        for _i in count:
            var spread: float = rng.randf_range(
                - impact_fx.angle_spread_radians / 2.0, 
                impact_fx.angle_spread_radians / 2.0, 
            )
            var angle: float = base_angle + spread
            var speed: float = rng.randf_range(impact_fx.speed_min, speed_max_eff)
            var velocity: = Vector2(cos(angle), sin(angle)) * speed
            var t: float = impact_fx.lifetime_seconds

            var final_pos: Vector2 = def_pos + velocity * t + Vector2(0, 0.5 * impact_fx.gravity * t * t)
            var stain_radius: float = rng.randf_range(impact_fx.particle_radius_min, impact_fx.particle_radius_max)
            _impact_stains.append({
                "spawn_tick": stain_tick, 
                "pos": final_pos, 
                "color": impact_fx.color_outer, 
                "radius_px": stain_radius, 
                "decay_mode": impact_fx.decay_mode, 
            })





func _draw_impact_stains(drawer: Control, offset: Vector2, arena_scale: float) -> void :
    for stain in _impact_stains:
        var age: float = current_sim_time - stain["spawn_tick"]
        if age < 0.0:
            continue
        var alpha_mult: float = 1.0
        if stain["decay_mode"] == HitImpactFX.DecayMode.BRIEF_GROUND_STAIN:
            if age > HitImpactFX.BRIEF_STAIN_LIFETIME:
                continue
            alpha_mult = 1.0 - age / HitImpactFX.BRIEF_STAIN_LIFETIME
        var screen_pos: = _arena_to_screen(stain["pos"], offset, arena_scale)
        var base_color: Color = stain["color"]
        var draw_color: = Color(base_color.r, base_color.g, base_color.b, base_color.a * alpha_mult)
        drawer.draw_circle(screen_pos, stain["radius_px"], draw_color)










func _draw_hit_impact_fx(drawer: Control, positions: Array, offset: Vector2, arena_scale: float) -> void :




    var widest_window: float = _visual_tail_seconds + 1.0

    for event in combat_result.event_log:
        if event.event_type != CombatEnums.CombatEventType.DAMAGE_DEALT:
            continue
        if current_sim_time - event.tick > widest_window:
            continue

        var attacker_id: int = event.data.get("attacker_id", -1)
        var defender_id: int = event.data.get("defender_id", -1)
        if attacker_id < 0 or defender_id < 0:
            continue

        var atk_c: CombatantData = combat_result.combatants[attacker_id]

        var ability_resource: MonsterAbility = event.data.get("ability")
        var attacker_vfx: AttackVFX = atk_c.get_ability_vfx(ability_resource) if atk_c else null
        var impact_fx: HitImpactFX = _impact_fx_for_event(attacker_vfx)
        if impact_fx == null:
            continue

        var impact_tick: float = _impact_tick_for_event(event, attacker_vfx)
        var age: float = current_sim_time - impact_tick

        if age < 0.0 or age >= impact_fx.lifetime_seconds:
            continue




        var event_positions: Array = _snapshot_positions_at_tick(event.tick)
        var atk_entry: Dictionary = _find_position_entry(event_positions, attacker_id)
        var def_entry: Dictionary = _find_position_entry(event_positions, defender_id)
        if atk_entry.is_empty() or def_entry.is_empty():
            continue
        var atk_pos_units: Vector2 = atk_entry["pos"]
        var def_pos_units: Vector2 = def_entry["pos"]




        var attack_dir: Vector2 = (def_pos_units - atk_pos_units).normalized()
        if attack_dir.length_squared() < 0.001:
            attack_dir = Vector2(0, 1)





        if impact_fx.lock_to_target:
            var live_def_entry: Dictionary = _find_position_entry(positions, defender_id)
            if not live_def_entry.is_empty():
                def_pos_units = live_def_entry["pos"]

        _render_impact_burst(drawer, event, impact_fx, def_pos_units, attack_dir, age, offset, arena_scale)













func _render_ambient_emitters(drawer: Control, positions: Array, offset: Vector2, arena_scale: float) -> void :
    if _active_ambient_emitters.is_empty():
        return



    var pos_by_id: Dictionary = {}
    for entry in positions:
        var id: int = entry.get("id", -1)
        if id < 0:
            continue
        pos_by_id[id] = entry["pos"]




    var keys_snapshot: Array = _active_ambient_emitters.keys()
    for key in keys_snapshot:
        var emitter: Dictionary = _active_ambient_emitters[key]
        var fx: HitImpactFX = emitter.get("fx", null)
        if fx == null:
            continue
        var bearer_id: int = emitter.get("bearer_id", -1)
        if not pos_by_id.has(bearer_id):
            continue
        var bearer_pos_units: Vector2 = pos_by_id[bearer_id]

        var interval: float = float(emitter.get("interval", 0.4))
        var start_tick: float = float(emitter.get("start_tick", 0.0))
        var lifetime: float = fx.lifetime_seconds
        var since_start: float = current_sim_time - start_tick
        if since_start < 0.0 or interval <= 0.0:
            continue









        var hi: int = int(floor(since_start / interval))
        var lo: int = int(ceil((since_start - lifetime) / interval))
        lo = maxi(lo, 0)

        for i in range(lo, hi + 1):
            var burst_start: float = start_tick + float(i) * interval
            var age: float = current_sim_time - burst_start
            if age < 0.0 or age >= lifetime:
                continue



            var rng: = RandomNumberGenerator.new()
            rng.seed = hash([key, i])
            var color_inner_eff: Color = fx.color_inner



            _render_static_arc_burst(
                drawer, fx, bearer_pos_units, rng, 
                fx.particle_count, color_inner_eff, age, 
                offset, arena_scale, 
            )




func _render_impact_burst(
    drawer: Control, 
    event: CombatEvent, 
    impact_fx: HitImpactFX, 
    def_pos_units: Vector2, 
    attack_dir: Vector2, 
    age: float, 
    offset: Vector2, 
    arena_scale: float, 
) -> void :
    var defender_id: int = event.data.get("defender_id", -1)
    var is_crit: bool = bool(event.data.get("is_crit", false))
    var count: int = impact_fx.get_effective_particle_count(is_crit)
    var speed_max_eff: float = impact_fx.get_effective_speed_max(is_crit)
    var color_inner_eff: Color = impact_fx.get_effective_color_inner(is_crit)
    var base_angle: float = attack_dir.angle() + impact_fx.direction_bias_radians


    var rng: = RandomNumberGenerator.new()
    rng.seed = hash([int(event.tick * 1000.0), defender_id])


    var fade: float = age / impact_fx.lifetime_seconds
    var particle_color: Color = color_inner_eff.lerp(impact_fx.color_outer, fade)




    if impact_fx.particle_style == HitImpactFX.ParticleStyle.STATIC_ARC:
        _render_static_arc_burst(drawer, impact_fx, def_pos_units, rng, 
                count, color_inner_eff, age, offset, arena_scale)
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

        var screen_pos: = _arena_to_screen(pos_units, offset, arena_scale)

        match impact_fx.particle_style:
            HitImpactFX.ParticleStyle.DOT:
                _draw_particle_dot(drawer, screen_pos, radius_px, particle_color, impact_fx.glow)
            HitImpactFX.ParticleStyle.STREAK:



                var streak_dt: float = minf(0.06, age)
                var past_age: float = age - streak_dt
                var past_pos_units: Vector2 = def_pos_units + velocity * past_age + Vector2(0, 0.5 * impact_fx.gravity * past_age * past_age)
                var past_screen: = _arena_to_screen(past_pos_units, offset, arena_scale)
                _draw_particle_streak(drawer, past_screen, screen_pos, radius_px, particle_color, impact_fx.glow)
            HitImpactFX.ParticleStyle.CURL:

                _draw_particle_curl(
                    drawer, impact_fx, def_pos_units, 
                    velocity, curl_phase, age, particle_color, 
                    radius_px, offset, arena_scale, 
                )










func _render_static_arc_burst(
    drawer: Control, 
    impact_fx: HitImpactFX, 
    anchor_units: Vector2, 
    rng: RandomNumberGenerator, 
    count: int, 
    color_inner_eff: Color, 
    age: float, 
    offset: Vector2, 
    arena_scale: float, 
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
        var anchor_screen: Vector2 = _arena_to_screen(anchor_units, offset, arena_scale)
        var endpoint_screen: Vector2 = _arena_to_screen(endpoint_units, offset, arena_scale)

        var arc_points: PackedVector2Array = _build_arc_polyline(
            anchor_screen, endpoint_screen, 
            impact_fx.arc_segments, impact_fx.arc_jitter, jitter_seed, 
        )
        _draw_arc_polyline(drawer, arc_points, impact_fx.arc_stroke_width, arc_color, impact_fx.glow)




        if impact_fx.arc_branch_count > 0:
            var branch_rng: = RandomNumberGenerator.new()
            branch_rng.seed = branch_seed
            @warning_ignore("integer_division")
            var mid_idx: int = arc_points.size() / 2
            var branch_start: Vector2 = arc_points[mid_idx]
            for b in impact_fx.arc_branch_count:
                var branch_angle: float = arc_angle + branch_rng.randf_range( - PI * 0.35, PI * 0.35)
                var branch_dist: float = arc_distance * branch_rng.randf_range(0.4, 0.75)
                var branch_end_units: Vector2 = anchor_units + Vector2(cos(branch_angle), sin(branch_angle)) * branch_dist
                var branch_end_screen: Vector2 = _arena_to_screen(branch_end_units, offset, arena_scale)
                @warning_ignore("integer_division")
                var branch_segments: int = maxi(3, impact_fx.arc_segments / 2)
                var branch_points: PackedVector2Array = _build_arc_polyline(
                    branch_start, branch_end_screen, 
                    branch_segments, impact_fx.arc_jitter * 1.4, 
                    branch_seed + b * 17 + 1, 
                )
                _draw_arc_polyline(
                    drawer, branch_points, 
                    impact_fx.arc_stroke_width * 0.7, arc_color, impact_fx.glow, 
                )










func _build_arc_polyline(start: Vector2, end: Vector2, segments: int, jitter_frac: float, jitter_seed: int) -> PackedVector2Array:
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






func _draw_arc_polyline(drawer: Control, points: PackedVector2Array, width: float, color: Color, glow: bool) -> void :
    if points.size() < 2:
        return
    if glow:
        var halo_color: = Color(color.r, color.g, color.b, color.a * 0.45)
        for i in range(points.size() - 1):
            drawer.draw_line(points[i], points[i + 1], halo_color, width * 2.4)
    for i in range(points.size() - 1):
        drawer.draw_line(points[i], points[i + 1], color, width)



func _draw_particle_dot(drawer: Control, screen_pos: Vector2, radius_px: float, color: Color, glow: bool) -> void :
    if glow:

        var halo_color: = Color(color.r, color.g, color.b, color.a * 0.45)
        drawer.draw_circle(screen_pos, radius_px * 2.4, halo_color)
    drawer.draw_circle(screen_pos, radius_px, color)



func _draw_particle_streak(drawer: Control, past_pos: Vector2, head_pos: Vector2, radius_px: float, color: Color, glow: bool) -> void :
    if glow:
        var halo_color: = Color(color.r, color.g, color.b, color.a * 0.4)
        drawer.draw_line(past_pos, head_pos, halo_color, radius_px * 2.4)
    drawer.draw_line(past_pos, head_pos, color, radius_px)
    drawer.draw_circle(head_pos, radius_px * 0.7, color)





func _draw_particle_curl(
    drawer: Control, 
    impact_fx: HitImpactFX, 
    def_pos_units: Vector2, 
    velocity: Vector2, 
    curl_phase: float, 
    age: float, 
    color: Color, 
    radius_px: float, 
    offset: Vector2, 
    arena_scale: float, 
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
        points.append(_arena_to_screen(base_pos, offset, arena_scale))



    for i in range(sample_count - 1):
        var t: float = float(i) / float(sample_count - 1)
        var seg_alpha: float = (1.0 - t) * color.a
        var seg_color: = Color(color.r, color.g, color.b, seg_alpha)
        var seg_width: float = lerpf(radius_px, radius_px * 0.4, t)
        drawer.draw_line(points[i], points[i + 1], seg_color, seg_width)

    drawer.draw_circle(points[0], radius_px * 0.85, color)




func _draw_facing_pips(drawer: Control, positions: Array, offset: Vector2, arena_scale: float) -> void :
    for entry in positions:
        if entry.get("state") == CombatEnums.CombatantState.DEAD:
            continue
        var target_id: int = entry.get("target_id", -1)
        if target_id < 0:
            continue
        var target_entry: Dictionary = _find_position_entry(positions, target_id)
        if target_entry.is_empty():
            continue
        var c: CombatantData = combat_result.combatants[entry["id"]]

        if c.source_monster and not c.source_monster.faces_target:
            continue
        var pos: = _arena_to_screen(entry["pos"], offset, arena_scale)
        var target_pos: = _arena_to_screen(target_entry["pos"], offset, arena_scale)
        var dir: = target_pos - pos
        if dir.length_squared() < 0.001:
            continue
        dir = dir.normalized()
        var radius: float = _radius_for(c)
        var pip_pos: = pos + dir * (radius * 0.9)
        var pip_radius: float = maxf(radius * 0.28, 2.5)

        var body_color: Color = _color_for(c, entry["state"])
        var pip_color: Color = body_color.lerp(Color.WHITE, 0.55)
        drawer.draw_circle(pip_pos, pip_radius, pip_color)






func _update_tick_label() -> void :
    var t: float = current_tick_idx * CombatSimulation.TICK_STEP
    tick_label.text = "%.1fs" % t






func _update_hover() -> void :
    if not hover_tooltip:
        return
    if not combat_result or combat_result.snapshots.is_empty() or not arena_drawer:
        hover_tooltip.visible = false
        return

    var mouse_local: Vector2 = arena_drawer.get_local_mouse_position()
    if not Rect2(Vector2.ZERO, arena_drawer.size).has_point(mouse_local):
        hover_tooltip.visible = false
        return


    var view_size: Vector2 = arena_drawer.size
    var aw: float = combat_result.encounter.arena_width
    var ah: float = combat_result.encounter.arena_height
    var arena_scale: float = min(view_size.x / aw, view_size.y / ah)
    var arena_w_screen: float = aw * arena_scale
    var arena_h_screen: float = ah * arena_scale
    var offset: = Vector2((view_size.x - arena_w_screen) / 2.0, (view_size.y - arena_h_screen) / 2.0)


    var max_idx: int = combat_result.snapshots.size() - 1
    var snap_a: Dictionary = combat_result.snapshots[current_tick_idx]
    var snap_b: Dictionary = combat_result.snapshots[min(current_tick_idx + 1, max_idx)]
    var frac: float = clampf(
        (current_sim_time / CombatSimulation.TICK_STEP) - float(current_tick_idx), 
        0.0, 1.0, 
    )
    var positions: Array = _build_interpolated_positions(snap_a, snap_b, frac)

    for entry in positions:
        if entry.get("state") == CombatEnums.CombatantState.DEAD:
            continue
        var c: CombatantData = combat_result.combatants[entry["id"]]
        var screen_pos: Vector2 = _arena_to_screen(entry["pos"], offset, arena_scale)
        var radius: float = _radius_for(c)

        if mouse_local.distance_to(screen_pos) <= radius + 3.0:
            _show_hover_for(c, entry, screen_pos)
            return

    hover_tooltip.visible = false








func _show_hover_for(c: CombatantData, entry: Dictionary, screen_pos: Vector2) -> void :
    var is_exile: bool = c.team == CombatEnums.CombatantTeam.EXILES and c.source_exile != null

    if is_exile:
        _populate_exile_hover(c, entry)
    else:
        _populate_enemy_hover(c)

    hover_tooltip.visible = true

    var pad: Vector2 = Vector2(12, -28)
    hover_tooltip.global_position = arena_drawer.global_position + screen_pos + pad


func _populate_exile_hover(c: CombatantData, entry: Dictionary) -> void :


    var role_text: String = c.source_exile.get_class_name()
    hover_label.text = "%s\n%s" % [c.display_name, role_text]

    hover_weapon_icon.visible = true
    hover_weapon_icon.populate(ExileWeaponHelper.get_main_weapon(c.source_exile))



    var life_pct: float = entry.get("life_pct", 0.0)
    var vitality_pct: float = entry.get("vitality_pct", 0.0)
    var exile: ExileData = c.source_exile
    hover_bars.populate_from_snapshot({
        "life": life_pct * c.max_life, 
        "max_life": c.max_life, 
        "vitality": vitality_pct * c.max_vitality, 
        "max_vitality": c.max_vitality, 
        "morale": exile.current_stats.morale, 
        "max_morale": exile.current_stats.max_morale, 
    })
    hover_bars.set_value_labels_visible(true)
    hover_bars.visible = true
    hover_description.visible = false
    _refresh_hover_ailment_strip(c)


func _populate_enemy_hover(c: CombatantData) -> void :
    hover_label.text = c.display_name
    hover_weapon_icon.visible = false
    hover_bars.visible = false

    var desc: String = ""
    if c.source_monster:
        desc = c.source_monster.description
    hover_description.text = desc
    hover_description.visible = not desc.is_empty()
    _refresh_hover_ailment_strip(c)









func _refresh_hover_ailment_strip(c: CombatantData) -> void :
    if hover_ailment_strip == null:
        return
    if c == null:
        hover_ailment_strip.visible = false
        hover_ailment_strip.refresh_from_state({}, 0.0)
        return
    var state: Dictionary = _get_ailment_state_for_display(c.combatant_id)
    var has_any: bool = (
        not (state["status_effects"] as Dictionary).is_empty()
        or not (state["impale_stacks"] as Array).is_empty()
        or not (state["poison_stacks"] as Array).is_empty()
    )
    if not has_any:
        hover_ailment_strip.visible = false
        hover_ailment_strip.refresh_from_state({}, 0.0)
        return



    hover_ailment_strip.refresh_from_state(state, current_sim_time)
    hover_ailment_strip.visible = true
