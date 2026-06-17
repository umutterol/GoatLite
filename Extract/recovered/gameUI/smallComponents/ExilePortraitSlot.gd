















class_name ExilePortraitSlot
extends PanelContainer





@export var show_level_up_badge: bool = true

@onready var class_icon: TextureRect = $Inner / ClassIcon
@onready var placeholder: Label = $Inner / Placeholder
@onready var level_up_badge: PortraitLevelUpBadge = $Inner / LevelUpBadge


var _current_exile: ExileData = null


func _ready() -> void :



    level_up_badge.clicked.connect(_on_badge_clicked)


func paint_exile(exile: ExileData) -> void :
    _current_exile = exile
    if exile == null:
        clear()
        return
    paint_class(exile.class_definition)
    if not is_node_ready():
        await ready



    level_up_badge.set_exile(exile if show_level_up_badge else null)


func paint_class(class_def: ClassDefinition) -> void :

    if not is_node_ready():
        await ready
    var texture: Texture2D = class_def.icon if class_def != null else null
    _apply_texture(texture)


func clear() -> void :
    if not is_node_ready():
        await ready
    _apply_texture(null)
    level_up_badge.set_exile(null)



func _apply_texture(texture: Texture2D) -> void :
    class_icon.texture = texture
    class_icon.visible = texture != null
    placeholder.visible = texture == null


func _on_badge_clicked(clicked_exile: ExileData) -> void :
    LevelUpModalLauncher.launch_for(clicked_exile)
