class_name LevelUpModal
extends CanvasLayer






















const STAT_DELTA_ROW_SCENE: PackedScene = preload("res://gameUI/levelUp/StatDeltaRow.tscn")
const PASSIVE_TREE_VIEW_SCENE: PackedScene = preload("res://gameUI/levelUp/PassiveTreeView.tscn")
const PASSIVE_TOOLTIP_SCENE: PackedScene = preload("res://gameUI/levelUp/PassiveTooltipPopup.tscn")

const POP_DURATION: float = 0.32
const POP_START_SCALE: float = 0.4
const FLASH_DURATION: float = 0.28
const FLASH_TINT: Color = Color(1.6, 1.5, 0.9)


const STAT_CATALOG: Array = [
    {"id": "life", "name": "Life", "fmt": "%.0f"}, 
    {"id": "vitality", "name": "Vitality", "fmt": "%.0f"}, 
    {"id": "max_morale", "name": "Max Morale", "fmt": "%.0f"}, 
    {"id": "armour", "name": "Armour", "fmt": "%.0f"}, 
    {"id": "evasion", "name": "Evasion", "fmt": "%.1f%%"}, 
    {"id": "energy_shield", "name": "Energy Shield", "fmt": "%.0f"}, 
    {"id": "block_chance", "name": "Block Chance", "fmt": "%.0f%%"}, 
    {"id": "block_amount", "name": "Block Amount", "fmt": "%.0f"}, 
    {"id": "endurance", "name": "Endurance", "fmt": "%.0f%%"}, 
    {"id": "fire_resistance", "name": "Fire Resistance", "fmt": "%.0f%%"}, 
    {"id": "cold_resistance", "name": "Cold Resistance", "fmt": "%.0f%%"}, 
    {"id": "lightning_resistance", "name": "Lightning Resistance", "fmt": "%.0f%%"}, 
    {"id": "chaos_resistance", "name": "Chaos Resistance", "fmt": "%.0f%%"}, 
    {"id": "life_regen", "name": "Life Regen", "fmt": "%.1f /s"}, 
    {"id": "life_leech", "name": "Life Leech", "fmt": "%.1f%%"}, 
    {"id": "life_gain_on_hit", "name": "Life on Hit", "fmt": "%.0f"}, 
    {"id": "physical_damage", "name": "Physical Damage", "fmt": "%.0f", "is_vector2": true}, 
    {"id": "fire_damage", "name": "Fire Damage", "fmt": "%.0f", "is_vector2": true}, 
    {"id": "cold_damage", "name": "Cold Damage", "fmt": "%.0f", "is_vector2": true}, 
    {"id": "lightning_damage", "name": "Lightning Damage", "fmt": "%.0f", "is_vector2": true}, 
    {"id": "chaos_damage", "name": "Chaos Damage", "fmt": "%.0f", "is_vector2": true}, 
    {"id": "critical_chance", "name": "Crit Chance", "fmt": "%.1f%%"}, 
    {"id": "critical_multiplier", "name": "Crit Multiplier", "fmt": "%.0f%%"}, 
    {"id": "attack_speed", "name": "Attack Speed", "fmt": "%.2f"}, 
    {"id": "movement", "name": "Movement", "fmt": "%+.0f%%"}, 
    {"id": "scouting", "name": "Scouting", "fmt": "%.1f"}, 
    {"id": "survival", "name": "Survival", "fmt": "%.1f"}, 
    {"id": "scavenging", "name": "Scavenging", "fmt": "%.1f"}, 
]


var exile: ExileData = null


var _tree_view: PassiveTreeView = null
var _tooltip: PassiveTooltipPopup = null




var _baseline_pre: ExileStats = null


var _last_post: ExileStats = null

var _rows_by_stat: Dictionary = {}

@onready var backdrop: ColorRect = %Backdrop
@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var class_icon: TextureRect = %ClassIcon
@onready var class_fallback_label: Label = %ClassFallbackLabel
@onready var stat_deltas_container: VBoxContainer = %StatDeltasContainer
@onready var no_changes_label: Label = %NoChangesLabel
@onready var passive_choices_area: Control = %PassiveChoicesArea
@onready var close_button: Button = %CloseButton
@onready var pending_pill: Label = %PendingPill


@onready var cancel_button: Panel = %CancelButton
@onready var confirm_button: Panel = %ConfirmButton



var _cancel_normal_style: StyleBox = null
var _cancel_hover_style: StyleBox = null
var _confirm_normal_style: StyleBox = null
var _confirm_hover_style: StyleBox = null




func _ready() -> void :
    if exile == null:
        push_error("LevelUpModal opened with no exile bound")
        queue_free()
        return

    close_button.pressed.connect(_close)


    _cancel_normal_style = cancel_button.get_theme_stylebox("panel")
    _confirm_normal_style = confirm_button.get_theme_stylebox("panel")
    _cancel_hover_style = $PanelButtonStyleNormal.get_meta("_hover_style") as StyleBox
    _confirm_hover_style = _cancel_hover_style
    cancel_button.gui_input.connect(_on_cancel_input)
    confirm_button.gui_input.connect(_on_confirm_input)
    cancel_button.mouse_entered.connect(_on_cancel_hover.bind(true))
    cancel_button.mouse_exited.connect(_on_cancel_hover.bind(false))
    confirm_button.mouse_entered.connect(_on_confirm_hover.bind(true))
    confirm_button.mouse_exited.connect(_on_confirm_hover.bind(false))
    GameState.exile_updated.connect(_on_exile_updated)

    _render_for_current_exile()





func rebind(new_exile: ExileData) -> void :
    if new_exile == null:
        return
    exile = new_exile
    if _tree_view != null and is_instance_valid(_tree_view):
        _tree_view.queue_free()
        _tree_view = null
    if _tooltip != null and is_instance_valid(_tooltip):
        _tooltip.queue_free()
        _tooltip = null
    _render_for_current_exile()


func _render_for_current_exile() -> void :


    _baseline_pre = LevelUpSystem.snapshot_stats(exile)
    var resolved_levels: Array[int] = LevelUpSystem.resolve_pending_growth(exile)
    _last_post = LevelUpSystem.snapshot_stats(exile)
    _rows_by_stat.clear()

    _populate_header(resolved_levels)
    _populate_class_portrait()
    _rebuild_all_deltas(_baseline_pre, _last_post)
    _mount_tree_view()
    _refresh_pending_pill()
    _set_confirm_cancel_visible(false)




func _populate_header(_resolved_levels: Array[int]) -> void :
    title_label.text = exile.name


    var class_text: String = "Unknown Class"
    if exile.class_definition != null and exile.class_definition.name != "":
        class_text = exile.class_definition.name
    subtitle_label.text = "%s - Level %d" % [class_text, exile.level]


func _populate_class_portrait() -> void :
    if exile.class_definition == null:
        class_icon.visible = false
        class_fallback_label.visible = true
        class_fallback_label.text = "?"
        return
    var icon: Texture2D = exile.class_definition.icon
    if icon != null:
        class_icon.texture = icon
        class_icon.visible = true
        class_fallback_label.visible = false
    else:
        class_icon.texture = null
        class_icon.visible = false
        class_fallback_label.visible = true
        class_fallback_label.text = "?"




func _rebuild_all_deltas(pre: ExileStats, post: ExileStats) -> void :
    for child in stat_deltas_container.get_children():
        child.queue_free()
    _rows_by_stat.clear()

    if pre == null or post == null:
        no_changes_label.visible = true
        return

    var added: int = 0
    for entry: Dictionary in STAT_CATALOG:
        var row_data: Dictionary = _compute_delta(entry, pre, post)
        if row_data.is_empty():
            continue
        var row: StatDeltaRow = _spawn_row()
        row.bind(row_data["name"], row_data["old"], row_data["new"], row_data["delta"], row_data["sign"])
        _rows_by_stat[entry["id"]] = row
        added += 1

    no_changes_label.visible = (added == 0)



func _compute_delta(entry: Dictionary, pre: ExileStats, post: ExileStats) -> Dictionary:
    var stat_id: String = entry.get("id", "")
    var display_name: String = entry.get("name", stat_id)
    var fmt: String = entry.get("fmt", "%.1f")
    var is_vector2: bool = entry.get("is_vector2", false)

    var old_value = pre.get(stat_id)
    var new_value = post.get(stat_id)

    if is_vector2:
        var old_v: Vector2 = old_value
        var new_v: Vector2 = new_value
        if old_v == new_v:
            return {}
        var delta_min: float = new_v.x - old_v.x
        var delta_max: float = new_v.y - old_v.y
        return {
            "name": display_name, 
            "old": "%s-%s" % [fmt % old_v.x, fmt % old_v.y], 
            "new": "%s-%s" % [fmt % new_v.x, fmt % new_v.y], 
            "delta": "%+.0f / %+.0f" % [delta_min, delta_max], 
            "sign": _vector2_sign(delta_min, delta_max), 
        }

    var old_f: float = float(old_value)
    var new_f: float = float(new_value)
    if is_equal_approx(old_f, new_f):
        return {}
    var delta: float = new_f - old_f
    var signed_fmt: String = "%+" + fmt.substr(1)
    return {
        "name": display_name, 
        "old": fmt % old_f, 
        "new": fmt % new_f, 
        "delta": signed_fmt % delta, 
        "sign": _scalar_sign(delta), 
    }


func _spawn_row() -> StatDeltaRow:
    var row: StatDeltaRow = STAT_DELTA_ROW_SCENE.instantiate()
    stat_deltas_container.add_child(row)
    return row


static func _scalar_sign(delta: float) -> int:
    if delta > 0.0001:
        return 1
    if delta < -0.0001:
        return -1
    return 0


static func _vector2_sign(dmin: float, dmax: float) -> int:
    return _scalar_sign((dmin + dmax) * 0.5)






func _refresh_deltas_animated(new_post: ExileStats) -> void :

    if no_changes_label.visible:
        no_changes_label.visible = false

    for entry: Dictionary in STAT_CATALOG:
        var stat_id: String = entry.get("id", "")
        var row_data: Dictionary = _compute_delta(entry, _baseline_pre, new_post)
        var existing_row: StatDeltaRow = _rows_by_stat.get(stat_id, null)



        var changed_now: bool = _stat_changed_between(entry, _last_post, new_post)

        if row_data.is_empty():


            continue

        if existing_row == null:
            var row: StatDeltaRow = _spawn_row()
            row.bind(row_data["name"], row_data["old"], row_data["new"], row_data["delta"], row_data["sign"])
            _rows_by_stat[stat_id] = row
            _animate_pop_in(row)
        else:
            existing_row.bind(row_data["name"], row_data["old"], row_data["new"], row_data["delta"], row_data["sign"])
            if changed_now:
                _animate_flash(existing_row)


static func _stat_changed_between(entry: Dictionary, a: ExileStats, b: ExileStats) -> bool:
    if a == null or b == null:
        return true
    var stat_id: String = entry.get("id", "")
    var is_vector2: bool = entry.get("is_vector2", false)
    if is_vector2:
        return (a.get(stat_id) as Vector2) != (b.get(stat_id) as Vector2)
    return not is_equal_approx(float(a.get(stat_id)), float(b.get(stat_id)))




func _animate_pop_in(row: Control) -> void :

    await get_tree().process_frame
    if not is_instance_valid(row):
        return
    row.pivot_offset = row.size * 0.5
    row.scale = Vector2(POP_START_SCALE, POP_START_SCALE)
    row.modulate = Color.WHITE
    var tween: Tween = create_tween()
    tween.set_trans(Tween.TRANS_BACK)
    tween.set_ease(Tween.EASE_OUT)
    tween.tween_property(row, "scale", Vector2.ONE, POP_DURATION)


func _animate_flash(row: Control) -> void :
    if not is_instance_valid(row):
        return
    var tween: Tween = create_tween()
    tween.tween_property(row, "modulate", FLASH_TINT, FLASH_DURATION * 0.4)
    tween.tween_property(row, "modulate", Color.WHITE, FLASH_DURATION * 0.6)




func _mount_tree_view() -> void :
    for child in passive_choices_area.get_children():
        child.queue_free()

    _tree_view = PASSIVE_TREE_VIEW_SCENE.instantiate()
    _tree_view.anchor_right = 1.0
    _tree_view.anchor_bottom = 1.0
    _tree_view.grow_horizontal = Control.GROW_DIRECTION_BOTH
    _tree_view.grow_vertical = Control.GROW_DIRECTION_BOTH
    passive_choices_area.add_child(_tree_view)
    _tree_view.bind(exile)

    _tooltip = PASSIVE_TOOLTIP_SCENE.instantiate()
    add_child(_tooltip)

    _tree_view.passive_hovered.connect(_on_passive_hovered)
    _tree_view.passive_unhovered.connect(_on_passive_unhovered)
    _tree_view.choice_selected.connect(_on_choice_selected)
    _tree_view.choice_deselected.connect(_on_choice_deselected)
    _tree_view.choice_committed.connect(_on_choice_committed)


func _on_passive_hovered(passive_def: PassiveDefinition, global_pos: Vector2, suppress_effects: bool) -> void :
    if _tooltip != null:
        _tooltip.show_for(passive_def, global_pos, suppress_effects)


func _on_passive_unhovered() -> void :
    if _tooltip != null:
        _tooltip.hide_tooltip()




func _on_choice_selected(_passive_def: PassiveDefinition) -> void :
    _set_confirm_cancel_visible(true)


func _on_choice_deselected() -> void :
    _set_confirm_cancel_visible(false)


func _on_confirm_pressed() -> void :
    if _tree_view == null:
        return

    _tree_view.confirm_selection()
    _set_confirm_cancel_visible(false)


func _on_cancel_pressed() -> void :
    if _tree_view == null:
        return
    _tree_view.cancel_selection()
    _set_confirm_cancel_visible(false)


func _on_choice_committed(_passive_def: PassiveDefinition) -> void :



    _set_confirm_cancel_visible(false)



    var new_post: ExileStats = LevelUpSystem.snapshot_stats(exile)
    _refresh_deltas_animated(new_post)
    _last_post = new_post
    _refresh_pending_pill()





func _set_confirm_cancel_visible(visible_state: bool) -> void :
    var alpha: float = 1.0 if visible_state else 0.0
    cancel_button.modulate.a = alpha
    confirm_button.modulate.a = alpha
    var filter: = Control.MOUSE_FILTER_STOP if visible_state else Control.MOUSE_FILTER_IGNORE
    cancel_button.mouse_filter = filter
    confirm_button.mouse_filter = filter




func _on_cancel_input(event: InputEvent) -> void :
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        _on_cancel_pressed()


func _on_confirm_input(event: InputEvent) -> void :
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        _on_confirm_pressed()


func _on_cancel_hover(entering: bool) -> void :


    if cancel_button.modulate.a <= 0.01:
        return
    cancel_button.add_theme_stylebox_override("panel", _cancel_hover_style if entering else _cancel_normal_style)


func _on_confirm_hover(entering: bool) -> void :
    if confirm_button.modulate.a <= 0.01:
        return
    confirm_button.add_theme_stylebox_override("panel", _confirm_hover_style if entering else _confirm_normal_style)




func _refresh_pending_pill() -> void :
    var pending: int = exile.get_pending_passive_nodes().size()
    if pending <= 0:
        pending_pill.visible = false
        return
    pending_pill.visible = true
    pending_pill.text = "+%d" % pending




func _on_exile_updated(updated_exile: ExileData) -> void :
    if updated_exile != exile:
        return



    if _baseline_pre == null or _last_post == null:
        return

    LevelUpSystem.resolve_pending_growth(exile)

    var new_post: ExileStats = LevelUpSystem.snapshot_stats(exile)
    if not _stats_identical(new_post, _last_post):
        _refresh_deltas_animated(new_post)
        _last_post = new_post
    _refresh_pending_pill()


static func _stats_identical(a: ExileStats, b: ExileStats) -> bool:
    if a == null or b == null:
        return false
    for entry: Dictionary in STAT_CATALOG:
        if _stat_changed_between(entry, a, b):
            return false
    return true









func _input(event: InputEvent) -> void :
    if not (event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE):
        return
    if get_viewport().is_input_handled():
        return
    _close()
    get_viewport().set_input_as_handled()




func _close() -> void :
    if GameState.exile_updated.is_connected(_on_exile_updated):
        GameState.exile_updated.disconnect(_on_exile_updated)
    queue_free()
