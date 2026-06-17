















class_name ExileGuildCard
extends Control


signal card_clicked(exile_data: ExileData, card: ExileGuildCard)
signal card_double_clicked(exile_data: ExileData, card: ExileGuildCard)
signal button_pressed(window_id: String, exile_data: ExileData, card: ExileGuildCard)





@export var card_style_normal: StyleBox
@export var card_style_selected: StyleBox


@onready var background_panel: Panel = %BackgroundPanel
@onready var portrait_slot: ExilePortraitSlot = %ExilePortraitSlot
@onready var name_label: Label = %ExileName
@onready var class_label: Label = %Classname
@onready var level_label: Label = %Lvl
@onready var notifs_grid: GridContainer = %Notifs
@onready var recovery_icon: PanelContainer = %RecoveryIcon
@onready var starving_icon: StarvingIcon = %StarvingIcon
@onready var battered_icon: PanelContainer = %BatteredIcon
@onready var downed_icon: PanelContainer = %DownedIcon

@onready var xp_bar: ProgressBar = %XPBar
@onready var xp_value_label: Label = %XPValueLabel
@onready var exile_bars: ExileBars = %ExileBars
@onready var equipped_weapon_panel: Panel = %EquippedWeapon
@onready var equipped_weapon_icon: TextureRect = %WeaponIcon



@onready var life_value_label: Label = exile_bars.life_value_label
@onready var vitality_value_label: Label = exile_bars.vitality_value_label
@onready var morale_value_label: Label = exile_bars.morale_value_label

@onready var sheet_button: PanelButton = %SheetButton
@onready var stash_button: PanelButton = %StashButton
@onready var quartermaster_button: PanelButton = %QuartermasterButton
@onready var passives_button: PanelButton = %PassivesButton
@onready var tactics_button: PanelButton = %TacticsButton




@onready var ration_alert_glow: Panel = %RationAlertGlow




@onready var resting_overlay: Control = %RestingOverlay


@onready var idle_overlay: Control = %IdleOverlay



@onready var buttons_row: HBoxContainer = $OuterMargin / BackgroundPanel / InnerMargin / InfovBarsRows / Buttons



const COMPACT_MIN_HEIGHT: int = 155
const STANDARD_MIN_HEIGHT: int = 190








const PARTY_PICK_UNSELECTED_SCALE: = Vector2(0.92, 0.92)



var _current_weapon: Item = null

var exile_data: ExileData = null



var _active_windows: Dictionary = {
    "sheet": false, 
    "stash": false, 
    "quartermaster": false, 
    "passives": false, 
    "tactics": false, 
}

var _is_selected: bool = false


var _is_compact_mode: bool = false





var _is_backbench_mode: bool = false


const BACKBENCH_DIM: float = 0.65



const RATION_ALERT_PULSE_SECONDS: float = 0.9
const RATION_ALERT_ALPHA_MIN: float = 0.35
const RATION_ALERT_ALPHA_MAX: float = 1.0


var _ration_alert_tween: Tween = null


func _ready() -> void :
    gui_input.connect(_on_card_gui_input)





    _wire_bar_hover(xp_bar, xp_value_label)
    _wire_bar_hover(exile_bars.life_bar, life_value_label)
    _wire_bar_hover(exile_bars.vitality_bar, vitality_value_label)
    _wire_bar_hover(exile_bars.morale_bar, morale_value_label)




    sheet_button.pressed.connect(_on_button_pressed.bind("sheet"))
    stash_button.pressed.connect(_on_button_pressed.bind("stash"))
    quartermaster_button.pressed.connect(_on_button_pressed.bind("quartermaster"))
    passives_button.pressed.connect(_on_button_pressed.bind("passives"))
    tactics_button.pressed.connect(_on_button_pressed.bind("tactics"))



    equipped_weapon_panel.mouse_entered.connect(_on_weapon_panel_mouse_entered)
    equipped_weapon_panel.mouse_exited.connect(_on_weapon_panel_mouse_exited)


    GameState.exile_updated.connect(_on_exile_updated)


    QuartermasterManager.ration_changed.connect(_on_ration_changed)



    resized.connect(_update_pivot_offset)
    _update_pivot_offset()


    _apply_card_style()
    sheet_button.set_active(false)
    stash_button.set_active(false)
    quartermaster_button.set_active(false)
    passives_button.set_active(false)
    tactics_button.set_active(false)




func setup(data: ExileData) -> void :
    exile_data = data
    if not is_node_ready():
        await ready
    _refresh_all()



func _refresh_all() -> void :
    if exile_data == null:
        return
    _refresh_header()
    _refresh_bars()
    _refresh_notifs()
    _refresh_weapon()


func _refresh_header() -> void :
    name_label.text = exile_data.name
    var class_text: String = exile_data.class_definition.name if exile_data.class_definition else exile_data.class_id
    class_label.text = class_text
    level_label.text = str(exile_data.level)
    portrait_slot.paint_exile(exile_data)


func _refresh_bars() -> void :

    var exp_to_next: int = exile_data.get_exp_for_next_level()
    xp_bar.max_value = max(exp_to_next, 1)
    xp_bar.value = exile_data.experience
    xp_value_label.text = "XP %d / %d" % [exile_data.experience, exp_to_next]


    exile_bars.populate_from_exile(exile_data)
    var stats: ExileStats = exile_data.current_stats
    life_value_label.text = "Life %d / %d" % [int(round(exile_data.current_life)), int(round(stats.life))]
    vitality_value_label.text = "Vitality %d / %d" % [int(round(exile_data.current_vitality)), int(round(stats.max_vitality))]
    morale_value_label.text = "Morale %d / %d" % [int(round(stats.morale)), int(round(stats.max_morale))]







func _refresh_weapon() -> void :
    _current_weapon = ExileWeaponHelper.get_main_weapon(exile_data)
    if _current_weapon and _current_weapon.base_item and _current_weapon.base_item.icon:
        equipped_weapon_icon.texture = _current_weapon.base_item.icon
        equipped_weapon_icon.visible = true
    else:
        equipped_weapon_icon.texture = null
        equipped_weapon_icon.visible = false


func _refresh_notifs() -> void :



    recovery_icon.visible = exile_data.status == "recovering"
    starving_icon.bind(exile_data)


    battered_icon.visible = false
    downed_icon.visible = false




    _apply_resting_overlay()
    _apply_idle_overlay()
    _apply_ration_alert()




func set_selected(is_selected: bool) -> void :



    if not is_node_ready():
        await ready
    if _is_selected == is_selected:
        return
    _is_selected = is_selected
    _apply_card_style()


    _apply_party_pick_scale()
    _apply_idle_overlay()


func set_window_active(window_id: String, active: bool) -> void :
    if not _active_windows.has(window_id):
        return
    if _active_windows[window_id] == active:
        return
    _active_windows[window_id] = active
    var btn: = _button_for_window(window_id)
    if btn:
        btn.set_active(active)




func _on_card_gui_input(event: InputEvent) -> void :


    if _is_backbench_mode:
        return
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        if event.double_click:
            card_double_clicked.emit(exile_data, self)
        else:
            card_clicked.emit(exile_data, self)





func _on_button_pressed(window_id: String) -> void :
    button_pressed.emit(window_id, exile_data, self)


func _wire_bar_hover(bar: ProgressBar, label: Label) -> void :
    if bar == null or label == null:
        return

    bar.mouse_filter = Control.MOUSE_FILTER_PASS
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    bar.mouse_entered.connect( func(): label.visible = true)
    bar.mouse_exited.connect( func(): label.visible = false)


func _apply_card_style() -> void :
    var style: StyleBox = card_style_selected if _is_selected else card_style_normal
    if style == null:
        return
    background_panel.add_theme_stylebox_override("panel", style)


func _button_for_window(window_id: String) -> PanelButton:
    match window_id:
        "sheet": return sheet_button
        "stash": return stash_button
        "quartermaster": return quartermaster_button
        "passives": return passives_button
        "tactics": return tactics_button
        _: return null


func _on_exile_updated(updated: ExileData) -> void :
    if exile_data and updated and exile_data.id == updated.id:
        _refresh_all()




func _on_weapon_panel_mouse_entered() -> void :
    if _current_weapon != null:
        ItemTooltip.show_for(_current_weapon, equipped_weapon_panel.get_global_rect())


func _on_weapon_panel_mouse_exited() -> void :
    if _current_weapon != null:
        ItemTooltip.hide_floating()








func set_compact_mode(compact: bool) -> void :
    if not is_node_ready():
        await ready
    _is_compact_mode = compact
    buttons_row.visible = not compact
    custom_minimum_size.y = COMPACT_MIN_HEIGHT if compact else STANDARD_MIN_HEIGHT


    _apply_party_pick_scale()
    _apply_resting_overlay()
    _apply_idle_overlay()





func _update_pivot_offset() -> void :
    pivot_offset = size * 0.5




func _apply_party_pick_scale() -> void :
    if not _is_compact_mode:
        scale = Vector2.ONE
        return

    _update_pivot_offset()
    scale = Vector2.ONE if _is_selected else PARTY_PICK_UNSELECTED_SCALE





func _apply_resting_overlay() -> void :
    if resting_overlay == null:
        return
    var should_show: bool = (
        _is_compact_mode
        and exile_data != null
        and exile_data.status == "recovering"
    )
    resting_overlay.visible = should_show








func _apply_idle_overlay() -> void :
    if idle_overlay == null:
        return
    var should_show: bool = (
        _is_compact_mode
        and exile_data != null
        and not _is_selected
        and exile_data.status != "recovering"
    )
    idle_overlay.visible = should_show






func _apply_ration_alert() -> void :
    if ration_alert_glow == null:
        return
    var should_show: bool = (
        exile_data != null
        and exile_data.food_ration == QuartermasterManager.RATION_NONE
    )
    ration_alert_glow.visible = should_show
    if should_show:
        _start_ration_alert_pulse()
    else:
        _stop_ration_alert_pulse()


func _start_ration_alert_pulse() -> void :

    if _ration_alert_tween and _ration_alert_tween.is_valid():
        return
    ration_alert_glow.modulate.a = RATION_ALERT_ALPHA_MAX
    _ration_alert_tween = create_tween().set_loops()
    _ration_alert_tween.tween_property(ration_alert_glow, "modulate:a", 
        RATION_ALERT_ALPHA_MIN, RATION_ALERT_PULSE_SECONDS).set_trans(Tween.TRANS_SINE)
    _ration_alert_tween.tween_property(ration_alert_glow, "modulate:a", 
        RATION_ALERT_ALPHA_MAX, RATION_ALERT_PULSE_SECONDS).set_trans(Tween.TRANS_SINE)


func _stop_ration_alert_pulse() -> void :
    if _ration_alert_tween and _ration_alert_tween.is_valid():
        _ration_alert_tween.kill()
    _ration_alert_tween = null
    if ration_alert_glow:
        ration_alert_glow.modulate.a = 1.0


func _on_ration_changed(exile_id: int, _new_ration: int) -> void :
    if exile_data and exile_data.id == exile_id:
        _apply_ration_alert()









func _can_drop_data(at_position: Vector2, data) -> bool:
    var slot: SeatSlot = _get_host_slot()
    if slot == null:
        return false



    var local_in_slot: Vector2 = at_position + position
    return slot._can_drop_data(local_in_slot, data)


func _drop_data(at_position: Vector2, data) -> void :
    var slot: SeatSlot = _get_host_slot()
    if slot == null:
        return
    var local_in_slot: Vector2 = at_position + position
    slot._drop_data(local_in_slot, data)





func _get_host_slot() -> SeatSlot:
    var node: Node = get_parent()
    while node != null:
        if node is SeatSlot:
            return node
        node = node.get_parent()
    return null






func set_backbench_mode(enabled: bool) -> void :
    if not is_node_ready():
        await ready
    _is_backbench_mode = enabled
    sheet_button.disabled = enabled
    stash_button.disabled = enabled
    passives_button.disabled = enabled
    tactics_button.disabled = enabled


    modulate = Color(BACKBENCH_DIM, BACKBENCH_DIM, BACKBENCH_DIM, 1.0) if enabled else Color.WHITE








func _get_drag_data(_at_position: Vector2):
    if exile_data == null:
        return null



    var icon: Texture2D = exile_data.class_definition.icon if exile_data.class_definition else null
    var preview: = TextureRect.new()
    preview.texture = icon
    preview.custom_minimum_size = Vector2(96, 96)
    preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    preview.modulate = Color(1, 1, 1, 0.85)
    var wrapper: = Control.new()
    wrapper.add_child(preview)
    set_drag_preview(wrapper)
    return {
        "type": "exile_card", 
        "exile_id": exile_data.id, 
    }
