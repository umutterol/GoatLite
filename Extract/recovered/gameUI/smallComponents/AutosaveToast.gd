












class_name AutosaveToast
extends Label



const COLOR_BASE: Color = Color(1.0, 0.84, 0.2, 1.0)



const COLOR_SHIMMER: Color = Color(1.6, 1.4, 0.7, 1.0)

const FADE_IN_SECONDS: float = 0.3


const SHIMMER_HALF_SECONDS: float = 0.18
const SHIMMER_CYCLES: int = 2
const HOLD_SECONDS: float = 0.5
const FADE_OUT_SECONDS: float = 0.6



var _tween: Tween = null


func _ready() -> void :


    modulate = Color(COLOR_BASE.r, COLOR_BASE.g, COLOR_BASE.b, 0.0)
    visible = false





func show_notification(message: String = "Game Saved") -> void :
    text = message
    visible = true


    if _tween != null and _tween.is_valid():
        _tween.kill()
    _tween = create_tween()



    modulate = Color(COLOR_BASE.r, COLOR_BASE.g, COLOR_BASE.b, 0.0)
    _tween.tween_property(self, "modulate:a", 1.0, FADE_IN_SECONDS)


    for _i in range(SHIMMER_CYCLES):
        _tween.tween_property(self, "modulate", COLOR_SHIMMER, SHIMMER_HALF_SECONDS)
        _tween.tween_property(self, "modulate", COLOR_BASE, SHIMMER_HALF_SECONDS)


    _tween.tween_interval(HOLD_SECONDS)


    _tween.tween_property(self, "modulate:a", 0.0, FADE_OUT_SECONDS)
    _tween.tween_callback( func(): visible = false)
