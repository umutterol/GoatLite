class_name StarvingIcon
extends PanelContainer












@onready var glyph: Label = $Glyph





var _pending_stacks: int = -1


func _ready() -> void :
    if _pending_stacks >= 0:
        bind_stacks(_pending_stacks)
        _pending_stacks = -1


func bind(exile: ExileData) -> void :
    if exile == null:
        visible = false
        return
    bind_stacks(MoraleManager.get_hungry_stacks(exile))




func bind_stacks(stacks: int) -> void :
    visible = stacks > 0
    if stacks <= 0:
        return
    if glyph == null:

        _pending_stacks = stacks
        return
    glyph.text = "x%d" % stacks
