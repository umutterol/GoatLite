class_name WeaponTypeIcon
extends PanelContainer














@onready var icon: TextureRect = %Icon
@onready var fallback_glyph: Label = %FallbackGlyph

var _item: Item = null


func _ready() -> void :
    mouse_entered.connect(_on_hover_enter)
    mouse_exited.connect(_on_hover_exit)







func populate(item: Item) -> void :
    if not is_node_ready():
        await ready
    _item = item


    if _item == null or _item.base_item == null:
        visible = true
        icon.texture = null
        icon.visible = false
        fallback_glyph.visible = false
        tooltip_text = "Unarmed"
        return



    if _item.base_item.category != ItemEnums.ItemCategory.WEAPON:
        visible = false
        return

    visible = true
    tooltip_text = ""


    if _item.base_item.icon != null:
        icon.texture = _item.base_item.icon
        icon.visible = true
        fallback_glyph.visible = false
        return


    icon.texture = null
    icon.visible = false
    fallback_glyph.text = ItemEnums.get_weapon_type_glyph(_item.base_item.weapon_type)
    fallback_glyph.visible = true


func _on_hover_enter() -> void :


    if _item:
        ItemTooltip.show_for(_item, get_global_rect())


func _on_hover_exit() -> void :
    if _item:
        ItemTooltip.hide_floating()
