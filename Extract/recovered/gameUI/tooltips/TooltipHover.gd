@tool
class_name TooltipHover
extends Node








@export var keyword: String = "":
    set(value):
        keyword = value
        update_configuration_warnings()

var _control: Control


func _ready() -> void :
    if Engine.is_editor_hint():
        return

    _control = get_parent() as Control
    if _control == null:
        push_error("TooltipHover must be a child of a Control node. Parent: %s" % str(get_parent()))
        return


    if _control.mouse_filter == Control.MOUSE_FILTER_IGNORE:
        _control.mouse_filter = Control.MOUSE_FILTER_PASS

    _control.mouse_entered.connect(_on_enter)
    _control.mouse_exited.connect(_on_exit)


func _on_enter() -> void :
    if keyword.is_empty() or _control == null:
        return
    TooltipController.notify_anchor_entered(_control)
    TooltipController.request_show(keyword, _control.get_global_rect(), _control)


func _on_exit() -> void :
    if _control == null:
        return
    TooltipController.notify_anchor_exited(_control)


func _get_configuration_warnings() -> PackedStringArray:
    var warnings: PackedStringArray = []
    if not (get_parent() is Control):
        warnings.append("TooltipHover must be a child of a Control node.")
    if keyword.is_empty():
        warnings.append("Keyword is empty — set it to a key from TooltipDefinitions.TOOLTIPS.")
    return warnings
