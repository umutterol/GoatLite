




class_name PotentialCardPanel
extends PanelContainer

@onready var value_label: Label = $MarginContainer / Layout / ValueLabel
@onready var tag_label: Label = $MarginContainer / Layout / TagLabel
@onready var tooltip_hover: TooltipHover = $TooltipHover


func bind(entry: PotentialEntry) -> void :
    if entry == null:
        return
    if entry.is_hidden:
        value_label.text = "???"
        tag_label.text = "Unknown"
        tooltip_hover.keyword = "potential_unknown"
        modulate = Color(0.7, 0.7, 0.75)
    else:
        value_label.text = _format_value(entry.total_value)
        tag_label.text = _format_tag(entry.tag)

        tooltip_hover.keyword = "potential_system"
        modulate = Color.WHITE



static func _format_value(v: float) -> String:
    if absf(v - roundf(v)) < 0.001:
        return "%d" % int(roundf(v))
    var text: = "%.2f" % v
    text = text.rstrip("0")
    if text.ends_with("."):
        text = text.substr(0, text.length() - 1)
    return text


static func _format_tag(tag: String) -> String:
    return tag.capitalize().replace("_", " ")
