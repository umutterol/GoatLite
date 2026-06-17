class_name RescuedExileScreen
extends Control

















const FLAVOR_FRESH: String = "[i]Battered and quiet, %s walks back through the gate. Whatever they saw out there, they kept moving long enough to be found.[/i]"
const FLAVOR_LONG_LOST: String = "[i]Against all odds, %s has been found. Long given up for lost, they have nothing on them but their own breath — and the look of someone who's seen too much.[/i]"

@onready var title_label: RichTextLabel = %TitleLabel
@onready var portrait: ExilePortraitSlot = %Portrait
@onready var name_label: Label = %NameLabel
@onready var sub_label: Label = %SubLabel
@onready var flavor_label: RichTextLabel = %FlavorLabel
@onready var exile_bars: ExileBars = %ExileBars
@onready var welcome_button: Button = %WelcomeButton
@onready var dismiss_button: Button = %DismissButton
@onready var queue_label: Label = %QueueLabel




var _queue: Array[Dictionary] = []
var _current: Dictionary = {}


func _ready() -> void :
    welcome_button.pressed.connect(_on_welcome_pressed)
    dismiss_button.pressed.connect(_on_dismiss_pressed)



    _queue = MissionManager.pending_rescued_exiles.duplicate()
    MissionManager.pending_rescued_exiles.clear()

    if _queue.is_empty():



        push_warning("RescuedExileScreen opened with empty queue — routing to guild")
        SceneRouter.to_guild()
        return

    _show_next()


func _show_next() -> void :
    if _queue.is_empty():




        if not MissionManager.pending_long_lost_surfaced.is_empty():
            SceneRouter.to_long_lost_surfaced_modal()
        else:
            SceneRouter.to_guild()
        return

    _current = _queue.pop_front()
    var exile: ExileData = _current.get("exile")
    var origin: String = String(_current.get("origin", "fresh"))
    if exile == null:

        _show_next()
        return

    portrait.paint_exile(exile)
    name_label.text = exile.name
    sub_label.text = "%s  —  Lv %d" % [exile.get_class_name(), exile.level]




    exile_bars.populate_from_exile(exile)

    if origin == "long_lost":
        title_label.text = "[center]Long-Lost Exile Returned[/center]"
        flavor_label.text = FLAVOR_LONG_LOST % exile.name
    else:
        title_label.text = "[center]Rescue Successful[/center]"
        flavor_label.text = FLAVOR_FRESH % exile.name




    if _queue.size() > 0:
        var next: Dictionary = _queue[0]
        var next_exile: ExileData = next.get("exile")
        var next_name: String = next_exile.name if next_exile != null else "another exile"
        queue_label.text = "Next: %s" % next_name
        queue_label.visible = true
    else:
        queue_label.visible = false


func _on_welcome_pressed() -> void :



    _show_next()


func _on_dismiss_pressed() -> void :





    var exile: ExileData = _current.get("exile")
    if exile != null:
        GameState.dismiss_exile(exile.id)
    _show_next()
