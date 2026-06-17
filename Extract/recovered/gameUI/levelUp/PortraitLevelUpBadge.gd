class_name PortraitLevelUpBadge
extends Control






signal clicked(exile: ExileData)



var exile: ExileData = null




const PULSE_DURATION: float = 1.45
const PULSE_PEAK_MODULATE: Color = Color(1.35, 1.1, 0.82, 1.0)
const PULSE_PEAK_SCALE: float = 1.08

var _pulse_tween: Tween = null

@onready var background: Panel = $Background
@onready var icon_label: Label = $Background / IconLabel


func _ready() -> void :


    GameState.exile_updated.connect(_on_exile_updated)


    GameState.exile_added.connect(_on_exile_added)
    _refresh_visibility()




func set_exile(new_exile: ExileData) -> void :
    exile = new_exile
    _refresh_visibility()


func _on_exile_updated(updated_exile: ExileData) -> void :
    if updated_exile != exile:
        return
    _refresh_visibility()


func _on_exile_added(added_exile: ExileData) -> void :
    if added_exile != exile:
        return
    _refresh_visibility()


func _refresh_visibility() -> void :
    if exile == null:
        visible = false
        _stop_pulse()
        return




    if GameState.get_exile_by_id(exile.id) == null:
        visible = false
        _stop_pulse()
        return
    var should_show: bool = exile.has_pending_passive_pick()
    visible = should_show
    if should_show:
        _start_pulse()
    else:
        _stop_pulse()




func _start_pulse() -> void :
    if _pulse_tween != null and _pulse_tween.is_valid():
        return

    pivot_offset = size * 0.5
    var half: float = PULSE_DURATION * 0.5
    _pulse_tween = create_tween().set_loops()
    _pulse_tween.set_trans(Tween.TRANS_SINE)
    _pulse_tween.set_ease(Tween.EASE_IN_OUT)
    _pulse_tween.tween_property(self, "modulate", PULSE_PEAK_MODULATE, half)
    _pulse_tween.parallel().tween_property(self, "scale", Vector2.ONE * PULSE_PEAK_SCALE, half)
    _pulse_tween.tween_property(self, "modulate", Color.WHITE, half)
    _pulse_tween.parallel().tween_property(self, "scale", Vector2.ONE, half)


func _stop_pulse() -> void :
    if _pulse_tween != null and _pulse_tween.is_valid():
        _pulse_tween.kill()
    _pulse_tween = null
    modulate = Color.WHITE
    scale = Vector2.ONE






func _gui_input(event: InputEvent) -> void :
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            if exile != null:
                clicked.emit(exile)
                accept_event()
