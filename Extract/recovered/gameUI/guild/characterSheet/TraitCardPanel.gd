









class_name TraitCardPanel
extends PanelContainer



const SCAR_BG_COLOR: Color = Color(0.35, 0.08, 0.08, 1.0)




const _NAME_FONT_SIZE_BRACKETS: Array = [
    {"max_chars": 7, "size": 18}, 
    {"max_chars": 11, "size": 15}, 
    {"max_chars": 16, "size": 13}, 
    {"max_chars": 24, "size": 11}, 
    {"max_chars": 9999, "size": 9}, 
]

signal trait_hovered(trait_def: TraitDefinition)
signal trait_unhovered()

@onready var icon_rect: TextureRect = $Margin / Content / IconRect
@onready var name_label: Label = $Margin / Content / NameLabel

var _trait_def: TraitDefinition


func _ready() -> void :
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)


func bind(def: TraitDefinition) -> void :
    _trait_def = def


    if def.icon != null:
        icon_rect.texture = def.icon
        icon_rect.visible = true
        name_label.visible = false
    else:
        icon_rect.texture = null
        icon_rect.visible = false
        name_label.text = def.name
        name_label.add_theme_font_size_override("font_size", _pick_font_size_for_name(def.name))
        name_label.visible = true





    var sb_source: = get_theme_stylebox("panel")
    if sb_source is StyleBoxFlat:
        var sb: StyleBoxFlat = sb_source.duplicate()
        sb.border_color = RarityColors.get_color(def.rarity)
        if def.category == TraitDefinition.TraitCategory.SCAR:
            sb.bg_color = SCAR_BG_COLOR
        add_theme_stylebox_override("panel", sb)






func _pick_font_size_for_name(text: String) -> int:
    var length: = text.length()
    for bracket in _NAME_FONT_SIZE_BRACKETS:
        if length <= int(bracket["max_chars"]):
            return int(bracket["size"])
    return 9


func _on_mouse_entered() -> void :
    if _trait_def == null:
        return
    trait_hovered.emit(_trait_def)


func _on_mouse_exited() -> void :
    trait_unhovered.emit()
