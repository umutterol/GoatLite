extends CanvasLayer













signal closed

const ANIM_DURATION: float = 3.0

const RecoveryIconScene: = preload("res://gameUI/smallComponents/RecoveryIcon.tscn")
const StarvingIconScene: = preload("res://gameUI/smallComponents/StarvingIcon.tscn")
const DiffBarScript: = preload("res://gameUI/smallComponents/DiffBar.gd")
const PortraitScene: = preload("res://gameUI/smallComponents/ExilePortraitSlot.tscn")
const WeaponIconScene: = preload("res://gameUI/smallComponents/WeaponTypeIcon.tscn")
const FoodIcon: = preload("res://assets/sprites/itemSprites/currencySprites/food_icon.tres")


const LIFE_COLOR: = Color(0.85, 0.3, 0.3)
const VITALITY_COLOR: = Color(0.95, 0.55, 0.15)
const MORALE_COLOR: = Color(0.3, 0.7, 0.95)
const XP_COLOR: = Color(0.96, 0.8, 0.18)


const BARS_WIDTH: float = 180.0
const BAR_HEIGHT: float = 20.0
const BAR_LABEL_WIDTH: float = 42.0

@onready var header: Label = %Header
@onready var exile_grid: GridContainer = %ExileGrid
@onready var empty_message: Label = %EmptyMessage
@onready var close_button: Button = %CloseButton

var _pre_snapshots: Dictionary = {}
var _active_diff_bars: Array[DiffBar] = []






func _ready() -> void :
    close_button.pressed.connect(_on_close_pressed)


    _pre_snapshots = _snapshot_all_living()



    var prev_day: int = GameState.current_day
    GameState.advance_day()
    header.text = "Day %d → Day %d" % [prev_day, GameState.current_day]

    var post_snapshots: Dictionary = _snapshot_all_living()
    var changed_ids: Array[int] = _ids_that_changed(_pre_snapshots, post_snapshots)

    if changed_ids.is_empty():
        empty_message.visible = true
        return

    for exile_id in changed_ids:
        var exile: ExileData = GameState.get_exile_by_id(exile_id)
        if not exile:
            continue
        exile_grid.add_child(_build_exile_panel(
            exile, 
            _pre_snapshots.get(exile_id, {}), 
            post_snapshots.get(exile_id, {}), 
        ))

    _play_all_animations()


func _on_close_pressed() -> void :
    closed.emit()
    queue_free()





func _input(event: InputEvent) -> void :
    if not (event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE):
        return
    if get_viewport().is_input_handled():
        return
    _on_close_pressed()
    get_viewport().set_input_as_handled()






func _build_exile_panel(exile: ExileData, pre: Dictionary, post: Dictionary) -> PanelContainer:
    var panel: = PanelContainer.new()
    panel.add_theme_stylebox_override("panel", _panel_stylebox())

    var margin: = MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 10)
    margin.add_theme_constant_override("margin_right", 10)
    margin.add_theme_constant_override("margin_top", 8)
    margin.add_theme_constant_override("margin_bottom", 8)
    panel.add_child(margin)

    var row: = HBoxContainer.new()
    row.add_theme_constant_override("separation", 8)
    margin.add_child(row)


    var portrait: ExilePortraitSlot = PortraitScene.instantiate()
    portrait.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    row.add_child(portrait)
    portrait.paint_exile(exile)


    var left_slot: = _build_status_slot()
    row.add_child(left_slot)
    if pre.get("status", "") == "recovering":
        left_slot.add_child(RecoveryIconScene.instantiate())
    var pre_stacks: int = pre.get("hungry_stacks", 0)
    if pre_stacks > 0:
        var left_starv: StarvingIcon = StarvingIconScene.instantiate()
        left_slot.add_child(left_starv)
        left_starv.bind_stacks(pre_stacks)


    var info: = VBoxContainer.new()
    info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    info.add_theme_constant_override("separation", 4)
    row.add_child(info)


    var header_row: = HBoxContainer.new()
    header_row.add_theme_constant_override("separation", 6)
    info.add_child(header_row)

    var header_rich: = RichTextLabel.new()
    header_rich.bbcode_enabled = true
    header_rich.fit_content = true
    header_rich.scroll_active = false
    header_rich.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header_rich.text = "[b]%s[/b]  —  %s (L%d)" % [
        exile.name, exile.get_class_name(), exile.level, 
    ]
    header_row.add_child(header_rich)

    var weapon_icon: WeaponTypeIcon = WeaponIconScene.instantiate()
    weapon_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    header_row.add_child(weapon_icon)
    weapon_icon.populate(ExileWeaponHelper.get_main_weapon(exile))

    info.add_child(_build_bar_row(
        "Life", pre.get("life", 0.0), post.get("life", 0.0), 
        maxf(post.get("max_life", 1.0), 1.0), LIFE_COLOR, 
    ))
    info.add_child(_build_bar_row(
        "Vit", pre.get("vitality", 0.0), post.get("vitality", 0.0), 
        maxf(post.get("max_vitality", 1.0), 1.0), VITALITY_COLOR, 
    ))
    info.add_child(_build_bar_row(
        "Mor", pre.get("morale", 0.0), post.get("morale", 0.0), 
        maxf(post.get("max_morale", 1.0), 1.0), MORALE_COLOR, 
    ))
    info.add_child(_build_bar_row(
        "XP", pre.get("experience", 0.0), post.get("experience", 0.0), 
        maxf(post.get("exp_to_next", 1.0), 1.0), XP_COLOR, 
    ))




    var pre_status: String = pre.get("status", "")
    if pre_status == "idle" or pre_status == "recovering":
        var ration: int = pre.get("food_ration", QuartermasterManager.RATION_FULL)
        var food_cost: int = QuartermasterManager.RATION_COST[ration]
        if food_cost > 0:
            info.add_child(_build_food_row(food_cost))


    var right_slot: = _build_status_slot()
    row.add_child(right_slot)
    if post.get("status", "") == "recovering":
        right_slot.add_child(RecoveryIconScene.instantiate())
    var post_stacks: int = post.get("hungry_stacks", 0)
    if post_stacks > 0:
        var right_starv: StarvingIcon = StarvingIconScene.instantiate()
        right_slot.add_child(right_starv)
        right_starv.bind_stacks(post_stacks)

    return panel





func _build_status_slot() -> Control:
    var slot: = VBoxContainer.new()
    slot.custom_minimum_size = Vector2(28, 28)
    slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    slot.add_theme_constant_override("separation", 2)
    return slot




func _build_food_row(cost: int) -> HBoxContainer:
    var row: = HBoxContainer.new()
    row.add_theme_constant_override("separation", 4)

    var label: = Label.new()
    label.text = "Food"
    label.custom_minimum_size = Vector2(BAR_LABEL_WIDTH, 0)
    label.add_theme_font_size_override("font_size", 12)
    label.add_theme_color_override("font_color", Color(0.78, 0.74, 0.66))
    row.add_child(label)

    var icon: = TextureRect.new()
    icon.texture = FoodIcon
    icon.custom_minimum_size = Vector2(16, 16)
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    row.add_child(icon)

    var cost_label: = Label.new()
    cost_label.text = "-%d" % cost
    cost_label.add_theme_font_size_override("font_size", 12)
    cost_label.add_theme_color_override("font_color", Color(0.95, 0.55, 0.15))
    row.add_child(cost_label)

    return row




func _build_bar_row(label_text: String, start: float, end: float, max_v: float, color: Color) -> HBoxContainer:
    var row: = HBoxContainer.new()
    row.add_theme_constant_override("separation", 8)

    var label: = Label.new()
    label.text = label_text
    label.custom_minimum_size = Vector2(BAR_LABEL_WIDTH, 0)
    label.add_theme_font_size_override("font_size", 12)
    label.add_theme_color_override("font_color", Color(0.78, 0.74, 0.66))
    row.add_child(label)

    var bar: DiffBar = DiffBarScript.new()
    bar.bar_height = BAR_HEIGHT
    bar.custom_minimum_size = Vector2(BARS_WIDTH, BAR_HEIGHT)
    bar.configure(start, end, max_v, color)
    row.add_child(bar)
    _active_diff_bars.append(bar)
    return row


func _play_all_animations() -> void :
    for bar in _active_diff_bars:
        if is_instance_valid(bar):
            bar.play_animation(ANIM_DURATION)












func _snapshot_all_living() -> Dictionary:
    var result: Dictionary = {}
    for exile in GameState.get_living_exiles():
        if exile.status != "idle" and exile.status != "recovering":
            continue
        result[exile.id] = _snapshot_one(exile)
    return result


func _snapshot_one(exile: ExileData) -> Dictionary:
    return {
        "life": exile.current_life, 
        "max_life": exile.current_stats.life, 
        "vitality": exile.current_vitality, 
        "max_vitality": exile.current_stats.max_vitality, 
        "morale": exile.current_stats.morale, 
        "max_morale": exile.current_stats.max_morale, 
        "experience": float(exile.experience), 
        "exp_to_next": float(exile.get_exp_for_next_level()), 
        "status": exile.status, 
        "food_ration": exile.food_ration, 
        "hungry_stacks": MoraleManager.get_hungry_stacks(exile), 
    }


func _ids_that_changed(pre: Dictionary, post: Dictionary) -> Array[int]:


    var ids: Array[int] = []
    for exile_id in post.keys():
        var p: Dictionary = pre.get(exile_id, {})
        var q: Dictionary = post[exile_id]
        if _snapshots_differ(p, q):
            ids.append(exile_id)


    ids.sort()
    return ids


func _snapshots_differ(a: Dictionary, b: Dictionary) -> bool:
    if a.is_empty() and not b.is_empty():
        return true
    for key in ["life", "vitality", "morale", "experience"]:
        if not is_equal_approx(a.get(key, 0.0), b.get(key, 0.0)):
            return true
    if a.get("status", "") != b.get("status", ""):
        return true
    if int(a.get("hungry_stacks", 0)) != int(b.get("hungry_stacks", 0)):
        return true


    var status: String = a.get("status", "")
    if status == "idle" or status == "recovering":
        if int(a.get("food_ration", QuartermasterManager.RATION_FULL)) > 0:
            return true
    return false






func _panel_stylebox() -> StyleBoxFlat:
    var box: = StyleBoxFlat.new()
    box.bg_color = Color(0.11, 0.1, 0.08, 0.95)
    box.border_color = Color(0.35, 0.3, 0.22, 0.9)
    box.border_width_left = 1
    box.border_width_top = 1
    box.border_width_right = 1
    box.border_width_bottom = 1
    box.corner_radius_top_left = 4
    box.corner_radius_top_right = 4
    box.corner_radius_bottom_left = 4
    box.corner_radius_bottom_right = 4
    return box
