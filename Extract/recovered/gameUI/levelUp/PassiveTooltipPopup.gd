class_name PassiveTooltipPopup
extends Control









const ANCHOR_OFFSET: Vector2 = Vector2(18, 18)
const EDGE_MARGIN: float = 8.0


const RARITY_NAMES: Dictionary = {
    PassiveDefinition.PassiveRarity.COMMON: "Common", 
    PassiveDefinition.PassiveRarity.UNCOMMON: "Uncommon", 
    PassiveDefinition.PassiveRarity.RARE: "Rare", 
    PassiveDefinition.PassiveRarity.LEGENDARY: "Legendary", 
}
const RARITY_HEXES: Dictionary = {
    PassiveDefinition.PassiveRarity.COMMON: "d2d2d2", 
    PassiveDefinition.PassiveRarity.UNCOMMON: "7ab2ff", 
    PassiveDefinition.PassiveRarity.RARE: "ffd852", 
    PassiveDefinition.PassiveRarity.LEGENDARY: "934b1b", 
}
const TYPE_NAMES: Dictionary = {
    PassiveDefinition.PassiveType.PASSIVE: "Passive", 
    PassiveDefinition.PassiveType.NOTABLE_PASSIVE: "Notable", 
    PassiveDefinition.PassiveType.KEYSTONE_PASSIVE: "Keystone", 
}

@onready var icon_rect: TextureRect = $Panel / Margin / VBox / HeaderRow / IconRect
@onready var name_label: RichTextLabel = $Panel / Margin / VBox / HeaderRow / HeaderInfo / NameLabel
@onready var type_rarity_label: RichTextLabel = $Panel / Margin / VBox / HeaderRow / HeaderInfo / TypeRarityLabel
@onready var body_label: RichTextLabel = $Panel / Margin / VBox / BodyLabel


func _ready() -> void :
    visible = false

    z_index = 200





func show_for(passive_def: PassiveDefinition, pos: Vector2, suppress_effects: bool = false) -> void :
    if passive_def == null:
        hide_tooltip()
        return

    _populate(passive_def, suppress_effects)
    visible = true


    call_deferred("_reposition", pos)


func hide_tooltip() -> void :
    visible = false




func _populate(passive_def: PassiveDefinition, suppress_effects: bool) -> void :
    icon_rect.texture = passive_def.icon
    icon_rect.visible = (passive_def.icon != null)


    name_label.text = "[code]%s[/code]" % passive_def.name

    var rarity_name: String = RARITY_NAMES.get(passive_def.rarity, "?")
    var rarity_hex: String = RARITY_HEXES.get(passive_def.rarity, "ffffff")
    var type_name: String = TYPE_NAMES.get(passive_def.passive_type, "?")
    type_rarity_label.text = "[color=#%s]%s[/color]  [color=gray]- %s[/color]" % [
        rarity_hex, rarity_name, type_name
    ]



    if suppress_effects:
        body_label.text = passive_def.description
    else:
        body_label.text = passive_def.get_full_description()




func _reposition(anchor: Vector2) -> void :
    var viewport: Vector2 = get_viewport_rect().size
    var my_size: Vector2 = $Panel.size
    var pos: Vector2 = anchor + ANCHOR_OFFSET


    if pos.x + my_size.x + EDGE_MARGIN > viewport.x:
        pos.x = anchor.x - my_size.x - ANCHOR_OFFSET.x

    if pos.y + my_size.y + EDGE_MARGIN > viewport.y:
        pos.y = anchor.y - my_size.y - ANCHOR_OFFSET.y


    pos.x = max(pos.x, EDGE_MARGIN)
    pos.y = max(pos.y, EDGE_MARGIN)

    global_position = pos
