class_name AilmentMiniPanel
extends PanelContainer
























signal panel_hovered(bbcode: String, anchor_rect: Rect2)
signal panel_unhovered




const PANEL_SIZE: Vector2 = Vector2(28, 22)





const PANEL_BG_ALPHA: float = 0.9



const PANEL_CORNER_RADIUS: int = 4
const PANEL_BORDER_WIDTH: int = 1
const PANEL_BORDER_COLOR: Color = Color(0.549, 0.408, 0.322, 0.875)

@onready var primary_label: Label = $PrimaryLabel


var _tooltip_bbcode: String = ""





var _is_hovered: bool = false


func _ready() -> void :
    custom_minimum_size = PANEL_SIZE



    mouse_filter = Control.MOUSE_FILTER_STOP
    mouse_entered.connect(_on_enter)
    mouse_exited.connect(_on_exit)







func populate(panel_color: Color, primary_text: String, tooltip_bbcode: String) -> void :
    if not is_node_ready():
        await ready



    var box: StyleBoxFlat = StyleBoxFlat.new()
    box.bg_color = Color(panel_color.r, panel_color.g, panel_color.b, PANEL_BG_ALPHA)
    box.corner_radius_top_left = PANEL_CORNER_RADIUS
    box.corner_radius_top_right = PANEL_CORNER_RADIUS
    box.corner_radius_bottom_left = PANEL_CORNER_RADIUS
    box.corner_radius_bottom_right = PANEL_CORNER_RADIUS
    box.border_width_left = PANEL_BORDER_WIDTH
    box.border_width_top = PANEL_BORDER_WIDTH
    box.border_width_right = PANEL_BORDER_WIDTH
    box.border_width_bottom = PANEL_BORDER_WIDTH
    box.border_color = PANEL_BORDER_COLOR


    box.content_margin_left = 2.0
    box.content_margin_right = 2.0
    box.content_margin_top = 0.0
    box.content_margin_bottom = 0.0
    add_theme_stylebox_override("panel", box)

    var bbcode_changed: bool = tooltip_bbcode != _tooltip_bbcode
    _tooltip_bbcode = tooltip_bbcode
    if primary_text.is_empty():
        primary_label.visible = false
    else:
        primary_label.text = primary_text
        primary_label.visible = true





    if _is_hovered and bbcode_changed and not _tooltip_bbcode.is_empty():
        panel_hovered.emit(_tooltip_bbcode, get_global_rect())


func _on_enter() -> void :
    _is_hovered = true
    if _tooltip_bbcode.is_empty():
        return
    panel_hovered.emit(_tooltip_bbcode, get_global_rect())


func _on_exit() -> void :
    _is_hovered = false
    panel_unhovered.emit()
