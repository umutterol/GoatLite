class_name PassiveChoiceDetailCard
extends Control



















signal clicked(node: PassiveTreeNode, choice_index: int, immediate: bool)



const RARITY_COLORS: Dictionary = {
    PassiveDefinition.PassiveRarity.COMMON: Color(0.82, 0.82, 0.82), 
    PassiveDefinition.PassiveRarity.UNCOMMON: Color(0.48, 0.7, 1.0), 
    PassiveDefinition.PassiveRarity.RARE: Color(1.0, 0.85, 0.32), 
    PassiveDefinition.PassiveRarity.LEGENDARY: Color(0.82, 0.435, 0.11), 
}

const RARITY_NAMES: Dictionary = {
    PassiveDefinition.PassiveRarity.COMMON: "Common", 
    PassiveDefinition.PassiveRarity.UNCOMMON: "Uncommon", 
    PassiveDefinition.PassiveRarity.RARE: "Rare", 
    PassiveDefinition.PassiveRarity.LEGENDARY: "Legendary", 
}

const TYPE_NAMES: Dictionary = {
    PassiveDefinition.PassiveType.PASSIVE: "Passive", 
    PassiveDefinition.PassiveType.NOTABLE_PASSIVE: "Notable", 
    PassiveDefinition.PassiveType.KEYSTONE_PASSIVE: "Keystone", 
}


const STATE_IDLE_BG: Color = Color(0.13, 0.13, 0.16, 1.0)
const STATE_HOVER_BG: Color = Color(0.18, 0.18, 0.22, 1.0)
const STATE_SELECTED_BG: Color = Color(0.22, 0.2, 0.1, 1.0)
const STATE_SELECTED_SCALE: float = 1.04


var tree_node: PassiveTreeNode = null
var choice_index: int = -1
var passive_def: PassiveDefinition = null
var _is_selected: bool = false
var _is_hovered: bool = false

@onready var background: Panel = $Background
@onready var icon_rect: TextureRect = $Background / Margin / Content / HeaderRow / IconRect
@onready var name_label: RichTextLabel = $Background / Margin / Content / HeaderRow / HeaderInfo / NameLabel
@onready var type_rarity_label: RichTextLabel = $Background / Margin / Content / HeaderRow / HeaderInfo / TypeRarityLabel
@onready var body_label: RichTextLabel = $Background / Margin / Content / BodyLabel


func _ready() -> void :
    pivot_offset = size * 0.5
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)




func bind(node: PassiveTreeNode, idx: int, passive: PassiveDefinition, suppress_effects: bool) -> void :
    tree_node = node
    choice_index = idx
    passive_def = passive

    if passive_def == null:
        _render_missing()
        return






    _apply_type_stylebox()

    icon_rect.texture = passive_def.icon
    icon_rect.visible = (passive_def.icon != null)


    name_label.text = "[code]%s[/code]" % passive_def.name

    var rarity_color: Color = RARITY_COLORS.get(passive_def.rarity, Color.WHITE)
    var rarity_hex: String = "%02x%02x%02x" % [
        int(rarity_color.r * 255), int(rarity_color.g * 255), int(rarity_color.b * 255)
    ]
    var rarity_name: String = RARITY_NAMES.get(passive_def.rarity, "?")
    var type_name: String = TYPE_NAMES.get(passive_def.passive_type, "?")
    type_rarity_label.text = "[color=#%s]%s[/color]  [color=gray]- %s[/color]" % [
        rarity_hex, rarity_name, type_name
    ]


    if suppress_effects:
        body_label.text = passive_def.description
    else:
        body_label.text = passive_def.get_full_description()




    background.self_modulate = rarity_color
    _refresh_state_visuals()


func set_selected(selected: bool) -> void :
    if _is_selected == selected:
        return
    _is_selected = selected
    _refresh_state_visuals()








func _apply_type_stylebox() -> void :
    var style_key: String = "_passive_style"
    match passive_def.passive_type:
        PassiveDefinition.PassiveType.NOTABLE_PASSIVE:
            style_key = "_notable_style"
        PassiveDefinition.PassiveType.KEYSTONE_PASSIVE:
            style_key = "_keystone_style"
    if not has_meta(style_key):
        return
    var type_style: StyleBox = get_meta(style_key) as StyleBox
    if type_style != null:
        background.add_theme_stylebox_override("panel", type_style)


func _refresh_state_visuals() -> void :
    var target_scale: Vector2 = Vector2.ONE * (STATE_SELECTED_SCALE if _is_selected else 1.0)

    pivot_offset = size * 0.5
    scale = target_scale


    var style: StyleBoxFlat = background.get_theme_stylebox("panel") as StyleBoxFlat
    if style != null:
        var dup_style: StyleBoxFlat = style.duplicate()
        if _is_selected:
            dup_style.bg_color = STATE_SELECTED_BG
        elif _is_hovered:
            dup_style.bg_color = STATE_HOVER_BG
        else:
            dup_style.bg_color = STATE_IDLE_BG
        background.add_theme_stylebox_override("panel", dup_style)


func _render_missing() -> void :
    icon_rect.visible = false
    name_label.text = "[code]Missing Passive[/code]"
    type_rarity_label.text = "[color=red]passive_id not found[/color]"
    body_label.text = "The baked passive id couldn't be resolved in PassiveLibrary."
    background.self_modulate = Color(0.6, 0.2, 0.2)




func _gui_input(event: InputEvent) -> void :
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        if tree_node != null:

            var immediate: bool = event.ctrl_pressed or event.meta_pressed
            clicked.emit(tree_node, choice_index, immediate)
            accept_event()


func _on_mouse_entered() -> void :
    _is_hovered = true
    _refresh_state_visuals()


func _on_mouse_exited() -> void :
    _is_hovered = false
    _refresh_state_visuals()
