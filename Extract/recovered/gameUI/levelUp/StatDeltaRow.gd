class_name StatDeltaRow
extends HBoxContainer





const POSITIVE_COLOR: Color = Color(0.55, 0.95, 0.55)
const NEGATIVE_COLOR: Color = Color(0.95, 0.45, 0.45)
const NEUTRAL_COLOR: Color = Color(0.85, 0.85, 0.85)

@onready var name_label: Label = $NameLabel
@onready var old_value_label: Label = $OldValueLabel
@onready var arrow_label: Label = $ArrowLabel
@onready var new_value_label: Label = $NewValueLabel
@onready var delta_label: Label = $DeltaLabel







func bind(display_name: String, old_text: String, new_text: String, delta_text: String, sign: int) -> void :
    name_label.text = display_name
    old_value_label.text = old_text
    new_value_label.text = new_text
    delta_label.text = delta_text
    delta_label.modulate = _color_for_sign(sign)


static func _color_for_sign(sign: int) -> Color:
    if sign > 0:
        return POSITIVE_COLOR
    if sign < 0:
        return NEGATIVE_COLOR
    return NEUTRAL_COLOR
