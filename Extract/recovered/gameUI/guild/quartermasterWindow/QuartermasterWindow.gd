class_name QuartermasterWindow
extends PanelContainer














const _SELECTED_MODULATE: = Color(1.0, 0.85, 0.3)

@onready var title_label: RichTextLabel = %TitleLabel
@onready var close_button: Button = %CloseButton

@onready var none_button: Button = %NoneButton
@onready var none_cost_label: Label = %NoneCost
@onready var none_effects: RichTextLabel = %NoneEffects

@onready var full_button: Button = %FullButton
@onready var full_cost_label: Label = %FullCost
@onready var full_effects: RichTextLabel = %FullEffects

@onready var double_button: Button = %DoubleButton
@onready var double_cost_label: Label = %DoubleCost
@onready var double_effects: RichTextLabel = %DoubleEffects

var exile_data: ExileData = null


func _ready() -> void :
    close_button.pressed.connect(_close)
    none_button.pressed.connect( func(): _on_ration_pressed(QuartermasterManager.RATION_NONE))
    full_button.pressed.connect( func(): _on_ration_pressed(QuartermasterManager.RATION_FULL))
    double_button.pressed.connect( func(): _on_ration_pressed(QuartermasterManager.RATION_DOUBLE))


    QuartermasterManager.ration_changed.connect(_on_ration_changed_anywhere)
    GameState.resource_changed.connect(_on_resource_changed)
    hide()


func populate(data: ExileData) -> void :
    exile_data = data
    _refresh()
    show()


func _close() -> void :
    hide()
    exile_data = null






func _refresh() -> void :
    if exile_data == null:
        return
    title_label.text = "[code]Rations — %s[/code]" % exile_data.name
    _populate_col(
        none_button, none_cost_label, none_effects, 
        QuartermasterManager.RATION_NONE, 
    )
    _populate_col(
        full_button, full_cost_label, full_effects, 
        QuartermasterManager.RATION_FULL, 
    )
    _populate_col(
        double_button, double_cost_label, double_effects, 
        QuartermasterManager.RATION_DOUBLE, 
    )
    _highlight_selected()


func _populate_col(btn: Button, cost_label: Label, effects: RichTextLabel, ration: int) -> void :
    var cost: int = QuartermasterManager.RATION_COST[ration]
    cost_label.text = "%d" % cost



    var affordable: bool = _can_afford_change(ration)
    btn.disabled = not affordable
    cost_label.modulate = Color.WHITE if affordable else Color(1, 0.4, 0.4)

    effects.text = _effects_text(ration)




func _can_afford_change(target_ration: int) -> bool:
    if exile_data == null:
        return false
    var current_cost: int = QuartermasterManager.cost_for(exile_data)
    var target_cost: int = QuartermasterManager.RATION_COST[target_ration]
    var delta: int = target_cost - current_cost
    if delta <= 0:
        return true
    return GameState.food >= QuartermasterManager.total_food_cost() + delta


func _effects_text(ration: int) -> String:
    var vit_bonus_pct: float = GameSettings.RATION_VITALITY_BONUS[ration] * 100.0
    var lines: Array[String] = []
    lines.append("[b]Vitality[/b]: +%.1f%%" % vit_bonus_pct)
    if ration == QuartermasterManager.RATION_NONE:
        lines.append("[b]Morale[/b]: −1 per day")
    else:
        var morale_bonus: int = int(QuartermasterManager.RATION_REST_MORALE[ration])
        lines.append("[b]Morale[/b]: +%d" % morale_bonus)
    return "\n".join(lines)


func _highlight_selected() -> void :
    var current: int = QuartermasterManager.get_ration(exile_data)
    none_button.modulate = _SELECTED_MODULATE if current == QuartermasterManager.RATION_NONE else Color.WHITE
    full_button.modulate = _SELECTED_MODULATE if current == QuartermasterManager.RATION_FULL else Color.WHITE
    double_button.modulate = _SELECTED_MODULATE if current == QuartermasterManager.RATION_DOUBLE else Color.WHITE






func _on_ration_pressed(ration: int) -> void :
    if exile_data == null:
        return
    QuartermasterManager.set_ration(exile_data, ration)

    QuartermasterManager.rebalance_to_fit_food()
    _refresh()


func _on_ration_changed_anywhere(_exile_id: int, _new_ration: int) -> void :
    if visible:
        _refresh()


func _on_resource_changed(resource_type: String, _old: int, _new: int) -> void :
    if resource_type == "food" and visible:
        _refresh()
