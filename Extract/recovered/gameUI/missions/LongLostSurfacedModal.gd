class_name LongLostSurfacedModal
extends Control

















const FLAVOR: String = "[i]A whisper from %s. Someone with %s's face was seen — a lead, fragile, fading fast. If you move on this now, you might bring them home.[/i]"

@onready var title_label: RichTextLabel = %TitleLabel
@onready var portrait: ExilePortraitSlot = %Portrait
@onready var name_label: Label = %NameLabel
@onready var sub_label: Label = %SubLabel
@onready var flavor_label: RichTextLabel = %FlavorLabel
@onready var open_board_button: Button = %OpenBoardButton
@onready var later_button: Button = %LaterButton
@onready var queue_label: Label = %QueueLabel



var _queue: Array[Dictionary] = []
var _current: Dictionary = {}


func _ready() -> void :
    open_board_button.pressed.connect(_on_open_board_pressed)
    later_button.pressed.connect(_on_later_pressed)

    _queue = MissionManager.pending_long_lost_surfaced.duplicate()
    MissionManager.pending_long_lost_surfaced.clear()

    if _queue.is_empty():


        push_warning("LongLostSurfacedModal opened with empty queue — routing to guild")
        SceneRouter.to_guild()
        return

    _show_next()


func _show_next() -> void :
    if _queue.is_empty():
        SceneRouter.to_guild()
        return

    _current = _queue.pop_front()
    var exile: ExileData = _current.get("exile")
    var area_id: int = int(_current.get("area_id", -1))
    if exile == null:
        _show_next()
        return

    var area_name: String = "the wilds"
    if area_id >= 0 and area_id < WorldEnum.AREAS.keys().size():
        area_name = WorldEnum.AREAS.keys()[area_id]

    title_label.text = "[center]A whisper from %s...[/center]" % area_name
    portrait.paint_exile(exile)
    name_label.text = exile.name
    sub_label.text = "Lost in %s" % area_name
    flavor_label.text = FLAVOR % [area_name, exile.name]

    if _queue.size() > 0:
        queue_label.text = "Another lead awaits..."
        queue_label.visible = true
    else:
        queue_label.visible = false


func _on_open_board_pressed() -> void :






    var area_id: int = int(_current.get("area_id", -1))
    if area_id >= 0:
        GameState.selected_mission_board_area = area_id as WorldEnum.AREAS
    _queue.clear()
    SceneRouter.to_mission_board()


func _on_later_pressed() -> void :



    _show_next()
