
extends HBoxContainer


const TICK_DURATION: float = 0.5
const PULSE_GAIN_COLOR: Color = Color("#FFD700")
const PULSE_LOSS_COLOR: Color = Color("#FF4444")

const PULSE_HOLD_RATIO: float = 0.25

@onready var chaos_label: RichTextLabel = $ChaosPanel / HBoxContainer / CurrentChaos
@onready var food_label: RichTextLabel = $FoodPanel / HBoxContainer / CurrentFood
@onready var scrap_label: RichTextLabel = $ScrapPanel / HBoxContainer / CurrentScrap
@onready var exalt_label: RichTextLabel = $ExaltPanel / HBoxContainer / CurrentExalt
@onready var day_label: RichTextLabel = $Day / Day



var _active_tweens: Dictionary = {}

func _ready():

    chaos_label.bbcode_enabled = true
    food_label.bbcode_enabled = true
    scrap_label.bbcode_enabled = true
    exalt_label.bbcode_enabled = true
    day_label.bbcode_enabled = true


    GameState.resource_changed.connect(_on_resource_changed)
    GameState.day_changed.connect(_on_day_changed)


    _update_display()

func _update_display():
    _update_chaos_display(GameState.chaos)
    _update_food_display(GameState.food)
    _update_scrap_display(GameState.scrap)
    _update_exalt_display(GameState.exalt)
    day_label.text = "Day %d" % GameState.current_day

func _on_resource_changed(resource_type: String, old_value: int, new_value: int):
    var label: RichTextLabel
    var settle_fn: Callable
    match resource_type:
        "chaos":
            label = chaos_label
            settle_fn = _update_chaos_display
        "food":
            label = food_label
            settle_fn = _update_food_display
        "scrap":
            label = scrap_label
            settle_fn = _update_scrap_display
        "exalt":
            label = exalt_label
            settle_fn = _update_exalt_display
        _:
            return
    _animate_value_change(resource_type, label, old_value, new_value, settle_fn)

func _animate_value_change(key: String, label: RichTextLabel, from: int, to: int, settle_fn: Callable):


    if _active_tweens.has(key):
        var prior: Variant = _active_tweens[key]
        if prior is Tween and (prior as Tween).is_valid():
            (prior as Tween).kill()


    if from == to:
        settle_fn.call(to)
        return

    var pulse_color: Color = PULSE_GAIN_COLOR if to > from else PULSE_LOSS_COLOR
    var tween: Tween = create_tween()
    _active_tweens[key] = tween
    tween.tween_method(
        _apply_pulse_step.bind(label, from, to, pulse_color), 
        0.0, 1.0, TICK_DURATION
    )

    tween.tween_callback(settle_fn.bind(to))

func _apply_pulse_step(progress: float, label: RichTextLabel, from: int, to: int, pulse_color: Color) -> void :
    var current_value: int = int(round(lerp(float(from), float(to), progress)))


    var fade_progress: float = clamp((progress - PULSE_HOLD_RATIO) / (1.0 - PULSE_HOLD_RATIO), 0.0, 1.0)
    var current_color: Color = pulse_color.lerp(Color.WHITE, fade_progress)
    label.text = "[color=#%s]%d[/color]" % [current_color.to_html(false), current_value]

func _update_chaos_display(value: int):
    if value <= 0:
        chaos_label.text = "[color=#FF0000]%d[/color]" % value
    elif value < 10:
        chaos_label.text = "[color=#FF6B6B]%d[/color]" % value
    else:
        chaos_label.text = "%d" % value

func _update_food_display(value: int):
    if value <= 0:
        food_label.text = "[color=#FF0000]%d[/color]" % value
    elif value < 5:
        food_label.text = "[color=#FFA500]%d[/color]" % value
    else:
        food_label.text = "%d" % value

func _update_scrap_display(value: int):
    if value <= 0:
        scrap_label.text = "[color=#FF0000]%d[/color]" % value
    elif value < 5:
        scrap_label.text = "[color=#FF6B6B]%d[/color]" % value
    else:
        scrap_label.text = "%d" % value

func _update_exalt_display(value: int):


    if value <= 0:
        exalt_label.text = "[color=#666666]%d[/color]" % value
    else:
        exalt_label.text = "[color=#FFD700]%d[/color]" % value

func _on_day_changed(new_day: int):
    day_label.text = "Day %d" % new_day
