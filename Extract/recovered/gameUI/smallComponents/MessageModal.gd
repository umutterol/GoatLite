
















class_name MessageModal
extends CanvasLayer

signal confirmed
signal cancelled

@onready var title_label: Label = %Title
@onready var body_label: RichTextLabel = %Body
@onready var primary_button: Button = %PrimaryButton
@onready var secondary_button: Button = %SecondaryButton



var _pending_title: String = ""
var _pending_body: String = ""
var _pending_primary: String = "Close"
var _pending_secondary: String = ""




func setup(p_title: String, p_body_bbcode: String, p_primary_label: String = "Close", p_secondary_label: String = "") -> void :
    _pending_title = p_title
    _pending_body = p_body_bbcode
    _pending_primary = p_primary_label
    _pending_secondary = p_secondary_label
    if is_node_ready():
        _apply_config()


func _ready() -> void :
    primary_button.pressed.connect(_on_primary_pressed)
    secondary_button.pressed.connect(_on_cancel_pressed)
    _apply_config()


    if secondary_button.visible:
        secondary_button.grab_focus()
    else:
        primary_button.grab_focus()


func _apply_config() -> void :
    title_label.text = _pending_title
    body_label.text = _pending_body
    primary_button.text = _pending_primary
    var has_secondary: bool = _pending_secondary != ""
    secondary_button.visible = has_secondary
    secondary_button.text = _pending_secondary


func _on_primary_pressed() -> void :
    confirmed.emit()
    queue_free()


func _on_cancel_pressed() -> void :
    cancelled.emit()
    queue_free()
