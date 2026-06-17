class_name CurrencyButton
extends Button












const COLOR_LABEL_TITLE: Color = Color(0.92, 0.88, 0.78)



@export var currency_id: String = "exalt"
@export var icon_texture: Texture2D = null
@export var title_text: String = "EXALT"



@onready var icon_rect: TextureRect = $Margin / HBox / Icon
@onready var title_label: Label = $Margin / HBox / VBox / TitleLabel
@onready var held_label: Label = $Margin / HBox / VBox / CountLine / HeldLabel
@onready var expense_label: Label = $Margin / HBox / VBox / CountLine / ExpenseLabel

var _held: int = 0
var _expense: int = 0
var _show_expense: bool = false


func _ready() -> void :
    toggle_mode = true
    if icon_texture != null:
        icon_rect.texture = icon_texture
    title_label.text = title_text
    title_label.modulate = COLOR_LABEL_TITLE
    _refresh_labels()






func set_state(held: int, expense: int, show_expense: bool = false) -> void :
    _held = maxi(0, held)
    _expense = maxi(0, expense)
    _show_expense = show_expense
    _refresh_labels()






func tick_held_visual() -> void :
    _held = maxi(0, _held - 1)
    _refresh_labels()


func _refresh_labels() -> void :
    held_label.text = str(_held)
    if _show_expense and _expense > 0:
        expense_label.text = "-%d" % _expense
        expense_label.visible = true
    else:
        expense_label.text = ""
        expense_label.visible = false
