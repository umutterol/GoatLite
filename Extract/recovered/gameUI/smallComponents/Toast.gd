class_name Toast
extends PanelContainer















signal finished


@export var slide_in_seconds: float = 0.35
@export var linger_seconds: float = 5.0
@export var slide_out_seconds: float = 0.35


@export var resting_offset_from_bottom: float = 24.0

@onready var message_label: Label = %MessageLabel

var _tween: Tween = null


func show_message(text: String) -> void :
    if not is_node_ready():
        await ready
    message_label.text = text
    _play_animation()

















func _play_animation() -> void :




    var height: float = offset_bottom - offset_top
    var resting_top: float = - (height + resting_offset_from_bottom)
    var resting_bottom: float = - resting_offset_from_bottom
    var hidden_top: float = 0.0
    var hidden_bottom: float = height



    offset_top = hidden_top
    offset_bottom = hidden_bottom

    if _tween != null and _tween.is_valid():
        _tween.kill()
    _tween = create_tween()



    _tween.tween_property(self, "offset_top", resting_top, slide_in_seconds)\
.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    _tween.parallel().tween_property(self, "offset_bottom", resting_bottom, slide_in_seconds)\
.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


    _tween.tween_interval(linger_seconds)


    _tween.tween_property(self, "offset_top", hidden_top, slide_out_seconds)\
.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    _tween.parallel().tween_property(self, "offset_bottom", hidden_bottom, slide_out_seconds)\
.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


    _tween.tween_callback( func() -> void :
        finished.emit()
        queue_free()
    )
