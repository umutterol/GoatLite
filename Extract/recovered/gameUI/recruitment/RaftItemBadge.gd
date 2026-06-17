





class_name RaftItemBadge
extends PanelContainer

@onready var icon_rect: TextureRect = $Layout / IconRect
@onready var name_label: Label = $Layout / NameLabel

var _item: Item


func _ready() -> void :
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)


func bind(item: Item) -> void :
    _item = item
    if item == null:
        name_label.text = "(empty)"
        icon_rect.texture = null
        return

    name_label.text = item.get_display_name()

    name_label.modulate = _rarity_color(item.rarity)

    if item.base_item and item.base_item.icon:
        icon_rect.texture = item.base_item.icon
        icon_rect.visible = true
    else:
        icon_rect.visible = false


func _on_mouse_entered() -> void :
    if _item == null:
        return
    ItemTooltip.show_for(_item, get_global_rect())


func _on_mouse_exited() -> void :
    ItemTooltip.hide_floating()





static func _rarity_color(rarity: int) -> Color:
    match rarity:
        Item.Rarity.UNCOMMON:
            return Color(0.4, 0.7, 1.0)
        Item.Rarity.RARE:
            return Color(0.95, 0.85, 0.3)
        _:
            return Color.WHITE
