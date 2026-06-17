class_name CharacterStatRow
extends HBoxContainer








@export var stat_name: String = ""
@export var name_color: Color = Color(1, 1, 1)

@export var tooltip_keyword: String = ""

@onready var name_label: Label = $NameLabel
@onready var value_label: Label = $ValueLabel
@onready var tooltip_hover: TooltipHover = $TooltipHover


func _ready() -> void :
    name_label.text = stat_name
    name_label.add_theme_color_override("font_color", name_color)
    tooltip_hover.keyword = tooltip_keyword



func populate(value_text: String) -> void :
    value_label.text = value_text
    visible = true


func hide_row() -> void :
    visible = false




func set_value_or_hide(value: float, default_value: float, format: String) -> void :
    if is_equal_approx(value, default_value):
        hide_row()
        return
    populate(format % value)



func set_int_or_hide(value: int, default_value: int, format: String) -> void :
    if value == default_value:
        hide_row()
        return
    populate(format % value)
