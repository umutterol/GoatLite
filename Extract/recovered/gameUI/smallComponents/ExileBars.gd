class_name ExileBars
extends VBoxContainer









const LIFE_COLOR: = Color(0.85, 0.3, 0.3)
const VITALITY_COLOR: = Color(0.95, 0.55, 0.15)
const MORALE_COLOR: = Color(0.3, 0.7, 0.95)




var life_bar: ProgressBar
var vitality_bar: ProgressBar
var morale_bar: ProgressBar




var life_value_label: Label
var vitality_value_label: Label
var morale_value_label: Label

var _initialized: bool = false


func _ready() -> void :
    _ensure_initialized()




func _ensure_initialized() -> void :
    if _initialized:
        return
    life_bar = get_node("LifeBar")
    vitality_bar = get_node("VitalityBar")
    morale_bar = get_node("MoraleBar")
    life_value_label = life_bar.get_node("LifeValueLabel")
    vitality_value_label = vitality_bar.get_node("VitalityValueLabel")
    morale_value_label = morale_bar.get_node("MoraleValueLabel")
    _apply_bar_color(life_bar, LIFE_COLOR)
    _apply_bar_color(vitality_bar, VITALITY_COLOR)
    _apply_bar_color(morale_bar, MORALE_COLOR)
    _initialized = true



func populate_from_exile(exile: ExileData) -> void :
    if not exile:
        return
    populate_from_snapshot({
        "life": exile.current_life, 
        "max_life": exile.current_stats.life, 
        "vitality": exile.current_vitality, 
        "max_vitality": exile.current_stats.max_vitality, 
        "morale": exile.current_stats.morale, 
        "max_morale": exile.current_stats.max_morale, 
    })







func populate_from_snapshot(state: Dictionary) -> void :
    _ensure_initialized()
    var life: float = state.get("life", 0.0)
    var max_life: float = state.get("max_life", 1.0)
    var vitality: float = state.get("vitality", 0.0)
    var max_vitality: float = state.get("max_vitality", 1.0)
    var morale: float = state.get("morale", 0.0)
    var max_morale: float = state.get("max_morale", 1.0)




    life = clampf(life, 0.0, max_life)
    vitality = clampf(vitality, 0.0, max_vitality)
    morale = clampf(morale, 0.0, max_morale)
    life_bar.max_value = max_life
    life_bar.value = life
    vitality_bar.max_value = max_vitality
    vitality_bar.value = vitality
    morale_bar.max_value = max_morale
    morale_bar.value = morale
    life_value_label.text = "Life %d / %d" % [int(round(life)), int(round(max_life))]
    vitality_value_label.text = "Vitality %d / %d" % [int(round(vitality)), int(round(max_vitality))]
    morale_value_label.text = "Morale %d / %d" % [int(round(morale)), int(round(max_morale))]





func set_value_labels_visible(is_visible: bool) -> void :
    _ensure_initialized()
    life_value_label.visible = is_visible
    vitality_value_label.visible = is_visible
    morale_value_label.visible = is_visible


func _apply_bar_color(bar: ProgressBar, color: Color) -> void :
    var fill: = StyleBoxFlat.new()
    fill.bg_color = color
    fill.corner_radius_top_left = 2
    fill.corner_radius_top_right = 2
    fill.corner_radius_bottom_left = 2
    fill.corner_radius_bottom_right = 2
    bar.add_theme_stylebox_override("fill", fill)
