class_name MissionBoardExileCard
extends PanelContainer














signal clicked(exile_id: int)



@export var style_idle: StyleBox = null
@export var style_idle_hover: StyleBox = null
@export var style_party: StyleBox = null
@export var style_party_hover: StyleBox = null

const _GREY_OUT_MODULATE: = Color(0.55, 0.55, 0.55)

@onready var portrait: ExilePortraitSlot = %Portrait
@onready var info: VBoxContainer = %Info
@onready var header_rich: RichTextLabel = %HeaderRich
@onready var weapon_icon: WeaponTypeIcon = %WeaponIcon
@onready var bars: ExileBars = %Bars
@onready var recovery_icon: PanelContainer = %RecoveryIcon
@onready var starving_icon: StarvingIcon = %StarvingIcon

var _exile_id: int = -1
var _in_party: bool = false
var _hovered: bool = false


func _ready() -> void :
    mouse_filter = Control.MOUSE_FILTER_STOP
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)
    gui_input.connect(_on_gui_input)




func populate(exile: ExileData, in_party: bool) -> void :
    if not is_node_ready():
        await ready
    _exile_id = exile.id
    _in_party = in_party

    header_rich.text = "[b]%s[/b]  -  %s (L%d)" % [
        exile.name, exile.get_class_name(), exile.level, 
    ]
    portrait.paint_exile(exile)
    weapon_icon.populate(ExileWeaponHelper.get_main_weapon(exile))
    bars.populate_from_exile(exile)



    for child in bars.get_children():
        if child is Control:
            (child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE

    var recovering: bool = exile.status == "recovering"
    recovery_icon.visible = recovering


    info.modulate = _GREY_OUT_MODULATE if recovering else Color.WHITE


    starving_icon.bind(exile)

    _apply_stylebox()






func _on_mouse_entered() -> void :
    _hovered = true
    _apply_stylebox()


func _on_mouse_exited() -> void :
    _hovered = false
    _apply_stylebox()


func _on_gui_input(event: InputEvent) -> void :
    if not (event is InputEventMouseButton):
        return
    var mb: InputEventMouseButton = event
    if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
        clicked.emit(_exile_id)






func _apply_stylebox() -> void :
    var sb: StyleBox = _pick_stylebox()
    if sb:
        add_theme_stylebox_override("panel", sb)


func _pick_stylebox() -> StyleBox:
    if _in_party:
        return style_party_hover if _hovered else style_party
    return style_idle_hover if _hovered else style_idle
