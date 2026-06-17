@tool
class_name CurrencyDropPip
extends HBoxContainer
















const POP_PEAK_SCALE: float = 1.35

const POP_UP_TIME: float = 0.06

const POP_DOWN_TIME: float = 0.2






@export var icon_texture: Texture2D:
    set(value):
        icon_texture = value
        _apply_icon_texture()



@export var tooltip_keyword: String = "":
    set(value):
        tooltip_keyword = value
        _apply_tooltip_keyword()


@export var icon_size: Vector2 = Vector2(24, 24):
    set(value):
        icon_size = value
        _apply_icon_size()




var _value_tween: Tween = null
var _pop_tween: Tween = null
var _last_shown: int = -1


func _ready() -> void :



    _apply_icon_texture()
    _apply_tooltip_keyword()
    _apply_icon_size()
    if Engine.is_editor_hint():
        return
    var label: = _amount_label()
    if label:
        label.text = "0"





func play_to(target: int, duration: float) -> void :
    if not is_node_ready():
        await ready
    _stop_tweens()

    if target <= 0:
        visible = false
        return
    visible = true

    var label: Label = _amount_label()
    if not label:
        return
    label.text = "0"
    _last_shown = 0
    label.scale = Vector2.ONE

    _value_tween = create_tween()
    _value_tween.tween_method(_on_tick, 0.0, float(target), maxf(duration, 0.001))






func bump(amount: int = 1) -> void :
    if not is_node_ready():
        await ready
    if amount <= 0:
        return
    visible = true
    var label: Label = _amount_label()
    if not label:
        return


    if _last_shown < 0:
        _last_shown = int(label.text) if label.text.is_valid_int() else 0
    _last_shown += amount
    label.text = str(_last_shown)
    _pop(label)




func _on_tick(value: float) -> void :
    var label: Label = _amount_label()
    if not label:
        return


    var as_int: int = int(round(value))
    if as_int == _last_shown:
        return
    _last_shown = as_int
    label.text = str(as_int)
    _pop(label)


func _pop(label: Label) -> void :
    if _pop_tween and _pop_tween.is_valid():
        _pop_tween.kill()



    label.pivot_offset = label.size / 2.0
    label.scale = Vector2.ONE
    _pop_tween = create_tween()
    _pop_tween.tween_property(label, "scale", 
        Vector2(POP_PEAK_SCALE, POP_PEAK_SCALE), POP_UP_TIME)\
.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


    _pop_tween.tween_property(label, "scale", 
        Vector2.ONE, POP_DOWN_TIME)\
.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _stop_tweens() -> void :
    if _value_tween and _value_tween.is_valid():
        _value_tween.kill()
    _value_tween = null
    if _pop_tween and _pop_tween.is_valid():
        _pop_tween.kill()
    _pop_tween = null






func _apply_icon_texture() -> void :
    if not is_inside_tree():
        return
    var rect: = _icon_rect()
    if rect:
        rect.texture = icon_texture


func _apply_tooltip_keyword() -> void :
    if not is_inside_tree():
        return
    var hover: = _tooltip_hover()
    if hover:
        hover.keyword = tooltip_keyword


func _apply_icon_size() -> void :
    if not is_inside_tree():
        return
    var rect: = _icon_rect()
    if rect:
        rect.custom_minimum_size = icon_size




func _icon_rect() -> TextureRect:
    return get_node_or_null("Icon") as TextureRect


func _amount_label() -> Label:
    return get_node_or_null("Amount") as Label


func _tooltip_hover() -> TooltipHover:
    return get_node_or_null("TooltipHover") as TooltipHover
