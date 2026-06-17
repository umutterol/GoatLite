class_name TargetRuleRow
extends HBoxContainer
















signal rule_changed
signal move_up_requested
signal move_down_requested
signal remove_requested


@onready var filter_option: OptionButton = %FilterOption
@onready var status_option: OptionButton = %StatusOption
@onready var range_check: CheckBox = %RangeCheck
@onready var picker_option: OptionButton = %PickerOption
@onready var up_button: Button = %UpButton
@onready var down_button: Button = %DownButton
@onready var remove_button: Button = %RemoveButton

var rule: TargetRule = null



var _populating: bool = false




const _FILTER_OPTIONS: Array = [
    {"label": "Any in range", "value": TargetRule.Filter.IN_RANGE}, 
    {"label": "Attacking me", "value": TargetRule.Filter.ATTACKING_ME}, 
    {"label": "Attacking an ally", "value": TargetRule.Filter.ATTACKING_ANY_ALLY}, 
    {"label": "With status", "value": TargetRule.Filter.HAS_STATUS}, 
    {"label": "Without status", "value": TargetRule.Filter.LACKS_STATUS}, 
]

const _PICKER_OPTIONS: Array = [
    {"label": "Nearest", "value": TargetRule.Picker.NEAREST}, 
    {"label": "Farthest", "value": TargetRule.Picker.FARTHEST}, 
    {"label": "Lowest current HP", "value": TargetRule.Picker.LOWEST_CURRENT_HP}, 
    {"label": "Highest current HP", "value": TargetRule.Picker.HIGHEST_CURRENT_HP}, 
    {"label": "Lowest max HP", "value": TargetRule.Picker.LOWEST_MAX_HP}, 
    {"label": "Highest max HP", "value": TargetRule.Picker.HIGHEST_MAX_HP}, 
    {"label": "Fastest", "value": TargetRule.Picker.FASTEST}, 
    {"label": "Slowest", "value": TargetRule.Picker.SLOWEST}, 
    {"label": "Random", "value": TargetRule.Picker.RANDOM}, 
    {"label": "First match", "value": TargetRule.Picker.ANY}, 
]


func _ready() -> void :
    _populate_filter_options()
    _populate_status_options()
    _populate_picker_options()
    filter_option.item_selected.connect(_on_filter_selected)
    status_option.item_selected.connect(_on_status_selected)
    range_check.toggled.connect(_on_range_toggled)
    picker_option.item_selected.connect(_on_picker_selected)
    up_button.pressed.connect( func(): move_up_requested.emit())
    down_button.pressed.connect( func(): move_down_requested.emit())
    remove_button.pressed.connect( func(): remove_requested.emit())









func bind(target_rule: TargetRule) -> void :
    rule = target_rule
    _refresh_ui()


func _refresh_ui() -> void :
    if rule == null:
        return
    _populating = true
    _select_by_metadata(filter_option, rule.filter)
    _select_status_id(rule.status_id)
    range_check.button_pressed = rule.require_in_range
    _select_by_metadata(picker_option, rule.picker)
    _refresh_conditional_visibility()
    _populating = false






func _refresh_conditional_visibility() -> void :
    if rule == null:
        return
    var needs_status: bool = (
        rule.filter == TargetRule.Filter.HAS_STATUS
        or rule.filter == TargetRule.Filter.LACKS_STATUS
    )
    status_option.visible = needs_status

    var range_makes_sense: bool = rule.filter != TargetRule.Filter.IN_RANGE
    range_check.visible = range_makes_sense






func _populate_filter_options() -> void :
    filter_option.clear()
    for i in _FILTER_OPTIONS.size():
        var entry: Dictionary = _FILTER_OPTIONS[i]
        filter_option.add_item(entry["label"], i)
        filter_option.set_item_metadata(i, entry["value"])


func _populate_picker_options() -> void :
    picker_option.clear()
    for i in _PICKER_OPTIONS.size():
        var entry: Dictionary = _PICKER_OPTIONS[i]
        picker_option.add_item(entry["label"], i)
        picker_option.set_item_metadata(i, entry["value"])





func _populate_status_options() -> void :
    status_option.clear()
    var effects: Array[StatusEffect] = StatusEffectRegistry.for_target_filters()
    for i in effects.size():
        var effect: StatusEffect = effects[i]
        if effect == null or effect.effect_id == &"":
            continue
        var label: String = effect.display_name if effect.display_name != "" else String(effect.effect_id)
        status_option.add_item(label, i)
        status_option.set_item_metadata(i, effect.effect_id)






func _on_filter_selected(index: int) -> void :
    if rule == null or _populating:
        return
    rule.filter = filter_option.get_item_metadata(index)




    if rule.filter == TargetRule.Filter.IN_RANGE:
        rule.require_in_range = true
        range_check.button_pressed = true
    _refresh_conditional_visibility()
    rule_changed.emit()


func _on_status_selected(index: int) -> void :
    if rule == null or _populating:
        return
    rule.status_id = status_option.get_item_metadata(index)
    rule_changed.emit()


func _on_range_toggled(pressed: bool) -> void :
    if rule == null or _populating:
        return
    rule.require_in_range = pressed
    rule_changed.emit()


func _on_picker_selected(index: int) -> void :
    if rule == null or _populating:
        return
    rule.picker = picker_option.get_item_metadata(index)
    rule_changed.emit()








func _select_by_metadata(option: OptionButton, value: int) -> void :
    for i in option.item_count:
        if option.get_item_metadata(i) == value:
            option.select(i)
            return
    if option.item_count > 0:
        option.select(0)




func _select_status_id(id: StringName) -> void :
    if id == &"":
        if status_option.item_count > 0:
            status_option.select(0)
        return
    for i in status_option.item_count:
        if status_option.get_item_metadata(i) == id:
            status_option.select(i)
            return
    if status_option.item_count > 0:
        status_option.select(0)




func set_boundary_flags(is_first: bool, is_last: bool) -> void :
    up_button.disabled = is_first
    down_button.disabled = is_last
