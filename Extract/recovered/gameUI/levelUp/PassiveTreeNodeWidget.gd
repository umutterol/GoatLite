class_name PassiveTreeNodeWidget
extends Control









signal clicked(node: PassiveTreeNode, choice_index: int)
signal hovered(passive_def: PassiveDefinition, global_pos: Vector2)
signal unhovered()



const RARITY_COLORS: Dictionary = {
    PassiveDefinition.PassiveRarity.COMMON: Color(0.82, 0.82, 0.82), 
    PassiveDefinition.PassiveRarity.UNCOMMON: Color(0.48, 0.7, 1.0), 
    PassiveDefinition.PassiveRarity.RARE: Color(1.0, 0.85, 0.32), 
    PassiveDefinition.PassiveRarity.LEGENDARY: Color(0.95, 0.5, 0.95), 
}



const TYPE_SIZES: Dictionary = {
    PassiveDefinition.PassiveType.PASSIVE: Vector2(72, 72), 
    PassiveDefinition.PassiveType.NOTABLE_PASSIVE: Vector2(92, 92), 
    PassiveDefinition.PassiveType.KEYSTONE_PASSIVE: Vector2(120, 120), 
}

const DISABLED_TINT: Color = Color(0.45, 0.45, 0.45, 0.85)
const PREVIEW_PULSE: Color = Color(1.05, 1.05, 1.05, 1.0)





const GHOST_SCALE: float = 0.5
const GHOST_MODULATE: Color = Color(0.55, 0.55, 0.55, 0.75)


var tree_node: PassiveTreeNode = null
var choice_index: int = -1
var passive_def: PassiveDefinition = null
var is_pickable: bool = false
var is_ghost: bool = false

@onready var background: Panel = $Background
@onready var icon_rect: TextureRect = $Background / IconRect
@onready var fallback_label: Label = $Background / FallbackLabel


func bind(node: PassiveTreeNode, idx: int, passive: PassiveDefinition, pickable: bool, ghost: bool = false) -> void :
    tree_node = node
    choice_index = idx
    passive_def = passive
    is_pickable = pickable
    is_ghost = ghost

    if passive_def == null:
        _render_missing()
        return

    _render_size_and_color()
    _render_icon()
    _apply_ghost_overlay()
    mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if pickable else Control.CURSOR_ARROW






func _apply_ghost_overlay() -> void :
    if not is_ghost:
        return
    pivot_offset = size * 0.5
    scale = Vector2.ONE * GHOST_SCALE
    modulate = GHOST_MODULATE


func _render_size_and_color() -> void :
    var size_vec: Vector2 = TYPE_SIZES.get(passive_def.passive_type, Vector2(72, 72))
    custom_minimum_size = size_vec
    size = size_vec




    var style_key: String = "_passive_style"
    match passive_def.passive_type:
        PassiveDefinition.PassiveType.NOTABLE_PASSIVE:
            style_key = "_notable_style"
        PassiveDefinition.PassiveType.KEYSTONE_PASSIVE:
            style_key = "_keystone_style"
    if has_meta(style_key):
        var style: StyleBox = get_meta(style_key) as StyleBox
        if style != null:
            background.add_theme_stylebox_override("panel", style)

    var tint: Color = RARITY_COLORS.get(passive_def.rarity, Color.WHITE)
    if not is_pickable and tree_node != null and tree_node.is_pending():


        tint = DISABLED_TINT
    background.self_modulate = tint


func _render_icon() -> void :
    if passive_def.icon != null:
        icon_rect.texture = passive_def.icon
        icon_rect.visible = true
        fallback_label.visible = false
    else:
        icon_rect.visible = false
        fallback_label.visible = true


        fallback_label.text = passive_def.name.substr(0, 1).to_upper() if passive_def.name.length() > 0 else "?"


func _render_missing() -> void :


    custom_minimum_size = Vector2(56, 56)
    size = Vector2(56, 56)
    icon_rect.visible = false
    fallback_label.visible = true
    fallback_label.text = "!"
    background.self_modulate = Color(0.6, 0.2, 0.2)





func _gui_input(event: InputEvent) -> void :
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            if is_pickable and tree_node != null:
                clicked.emit(tree_node, choice_index)
                accept_event()


func _on_mouse_entered() -> void :
    if passive_def != null:
        hovered.emit(passive_def, get_global_mouse_position())


func _on_mouse_exited() -> void :
    unhovered.emit()
