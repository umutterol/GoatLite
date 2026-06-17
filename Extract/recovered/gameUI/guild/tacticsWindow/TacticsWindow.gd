class_name TacticsWindow
extends CanvasLayer



















@onready var backdrop: ColorRect = %Backdrop
@onready var title_label: RichTextLabel = %TacticsTitleLabel
@onready var close_button: Button = %TacticsCloseButton
@onready var reset_button: Button = %TacticsResetButton
@onready var target_lock_option: OptionButton = %TargetLockOption
@onready var kite_profile_option: OptionButton = %KiteProfileOption
@onready var rules_vbox: VBoxContainer = %RulesVBox
@onready var rules_scroll: ScrollContainer = %RulesScroll
@onready var no_rules_placeholder: Label = %NoRulesPlaceholder
@onready var add_rule_button: Button = %AddRuleButton
@onready var fallback_picker_option: OptionButton = %FallbackPickerOption



const TARGET_RULE_ROW_SCENE: PackedScene = preload("res://gameUI/guild/tacticsWindow/TargetRuleRow.tscn")

var exile_data: ExileData = null



var _populating: bool = false

const _DEBUG_TACTICS: bool = false




const _LOCK_ON_OPTIONS: Array = [
    {"label": "Let Them Decide", "value": -1.0}, 








    {"label": "Off (re-evaluate every attack)", "value": 0.2}, 
    {"label": "Short (1s)", "value": 1.0}, 
    {"label": "Long (2.5s)", "value": 2.5}, 
]


const _KITE_PROFILE_OPTIONS: Array = [
    {"label": "Let Them Decide", "value": KiteProfile.Profile.INHERIT}, 
    {"label": "Evasive Melee", "value": KiteProfile.Profile.EVASIVE_MELEE}, 
    {"label": "Careful Sniper", "value": KiteProfile.Profile.CAREFUL_SNIPER}, 
    {"label": "Balanced Aggressive", "value": KiteProfile.Profile.BALANCED_AGGRESSIVE}, 
    {"label": "Reckless", "value": KiteProfile.Profile.RECKLESS}, 
    {"label": "No Kiting", "value": KiteProfile.Profile.NO_KITING}, 
]



const _FALLBACK_OPTIONS: Array = [
    {"label": "Nearest", "value": TargetRule.Picker.NEAREST}, 
    {"label": "Farthest", "value": TargetRule.Picker.FARTHEST}, 
    {"label": "Lowest current HP", "value": TargetRule.Picker.LOWEST_CURRENT_HP}, 
    {"label": "Highest current HP", "value": TargetRule.Picker.HIGHEST_CURRENT_HP}, 
    {"label": "Lowest max HP", "value": TargetRule.Picker.LOWEST_MAX_HP}, 
    {"label": "Highest max HP", "value": TargetRule.Picker.HIGHEST_MAX_HP}, 
    {"label": "Fastest", "value": TargetRule.Picker.FASTEST}, 
    {"label": "Slowest", "value": TargetRule.Picker.SLOWEST}, 
    {"label": "Random", "value": TargetRule.Picker.RANDOM}, 
]


func _ready() -> void :
    close_button.pressed.connect(_close)
    reset_button.pressed.connect(_on_reset_pressed)
    target_lock_option.item_selected.connect(_on_target_lock_selected)
    kite_profile_option.item_selected.connect(_on_kite_profile_selected)
    fallback_picker_option.item_selected.connect(_on_fallback_picker_selected)
    add_rule_button.pressed.connect(_on_add_rule_pressed)


    backdrop.gui_input.connect(_on_backdrop_input)
    _populate_option_button(target_lock_option, _LOCK_ON_OPTIONS)
    _populate_option_button(kite_profile_option, _KITE_PROFILE_OPTIONS)
    _populate_option_button(fallback_picker_option, _FALLBACK_OPTIONS)
    hide()




func _on_backdrop_input(event: InputEvent) -> void :
    if event is InputEventMouseButton:
        var mb: InputEventMouseButton = event
        if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
            _close()


func populate(data: ExileData) -> void :
    exile_data = data
    _refresh()
    show()


func _close() -> void :
    hide()
    exile_data = null






func _refresh() -> void :
    if exile_data == null:
        return
    _populating = true
    title_label.text = "[code]Tactics — %s[/code]" % exile_data.name
    _refresh_lock_on_selection()
    _refresh_kite_profile_selection()
    _refresh_fallback_selection()
    _rebuild_rule_rows()
    _populating = false
    if _DEBUG_TACTICS:
        _debug_dump("populate")


func _refresh_lock_on_selection() -> void :
    var current: float = -1.0
    if exile_data.tactics_override != null:
        current = exile_data.tactics_override.target_lock_seconds
    for i in target_lock_option.item_count:
        if is_equal_approx(target_lock_option.get_item_metadata(i), current):
            target_lock_option.select(i)
            return
    target_lock_option.select(0)


func _refresh_kite_profile_selection() -> void :
    var current: int = KiteProfile.Profile.INHERIT
    if exile_data.tactics_override != null:
        current = exile_data.tactics_override.kite_profile
    _select_by_metadata(kite_profile_option, current)


func _refresh_fallback_selection() -> void :
    var current: int = TargetRule.Picker.NEAREST
    if exile_data.tactics_override != null:
        current = exile_data.tactics_override.fallback_picker
    _select_by_metadata(fallback_picker_option, current)









func _rebuild_rule_rows() -> void :
    for child in rules_vbox.get_children():
        if child == no_rules_placeholder:
            continue
        child.queue_free()

    var rules: Array[TargetRule] = []
    if exile_data.tactics_override != null:
        rules = exile_data.tactics_override.target_rules

    no_rules_placeholder.visible = rules.is_empty()

    for i in rules.size():
        var row: TargetRuleRow = TARGET_RULE_ROW_SCENE.instantiate()
        rules_vbox.add_child(row)
        row.bind(rules[i])
        row.set_boundary_flags(i == 0, i == rules.size() - 1)

        var captured_index: int = i
        row.rule_changed.connect( func(): _on_rule_changed(captured_index))
        row.move_up_requested.connect( func(): _on_rule_move(captured_index, -1))
        row.move_down_requested.connect( func(): _on_rule_move(captured_index, 1))
        row.remove_requested.connect( func(): _on_rule_remove(captured_index))






func _on_target_lock_selected(index: int) -> void :
    if exile_data == null or _populating:
        return
    var value: float = target_lock_option.get_item_metadata(index)
    _ensure_override()
    exile_data.tactics_override.target_lock_seconds = value
    _after_edit()


func _on_kite_profile_selected(index: int) -> void :
    if exile_data == null or _populating:
        return
    var value: int = kite_profile_option.get_item_metadata(index)
    _ensure_override()
    exile_data.tactics_override.kite_profile = value
    _after_edit()


func _on_fallback_picker_selected(index: int) -> void :
    if exile_data == null or _populating:
        return
    var value: int = fallback_picker_option.get_item_metadata(index)
    _ensure_override()
    exile_data.tactics_override.fallback_picker = value
    _after_edit()






func _on_add_rule_pressed() -> void :
    if exile_data == null:
        return
    _ensure_override()
    var rule: = TargetRule.new()



    rule.filter = TargetRule.Filter.IN_RANGE
    rule.picker = TargetRule.Picker.LOWEST_CURRENT_HP
    rule.require_in_range = true
    exile_data.tactics_override.target_rules.append(rule)
    _after_edit()
    _rebuild_rule_rows()


func _on_rule_changed(_index: int) -> void :


    _after_edit()


func _on_rule_move(index: int, direction: int) -> void :
    if exile_data == null or exile_data.tactics_override == null:
        return
    var rules: Array[TargetRule] = exile_data.tactics_override.target_rules
    var new_index: int = index + direction
    if new_index < 0 or new_index >= rules.size():
        return
    var moved: TargetRule = rules[index]
    rules.remove_at(index)
    rules.insert(new_index, moved)
    _after_edit()
    _rebuild_rule_rows()


func _on_rule_remove(index: int) -> void :
    if exile_data == null or exile_data.tactics_override == null:
        return
    var rules: Array[TargetRule] = exile_data.tactics_override.target_rules
    if index < 0 or index >= rules.size():
        return
    rules.remove_at(index)
    _after_edit()
    _rebuild_rule_rows()






func _on_reset_pressed() -> void :
    if exile_data == null:
        return
    exile_data.tactics_override = null
    GameState.exile_updated.emit(exile_data)
    _refresh()




func _ensure_override() -> void :
    if exile_data.tactics_override == null:
        exile_data.tactics_override = ExileTacticsOverride.new()





func _after_edit() -> void :
    if exile_data.tactics_override != null and not exile_data.tactics_override.has_any_override():
        exile_data.tactics_override = null
    GameState.exile_updated.emit(exile_data)
    if _DEBUG_TACTICS:
        _debug_dump("WRITE")








func _populate_option_button(option: OptionButton, entries: Array) -> void :
    option.clear()
    for i in entries.size():
        var entry: Dictionary = entries[i]
        option.add_item(entry["label"], i)
        option.set_item_metadata(i, entry["value"])



func _select_by_metadata(option: OptionButton, value: Variant) -> void :
    for i in option.item_count:
        if option.get_item_metadata(i) == value:
            option.select(i)
            return
    if option.item_count > 0:
        option.select(0)


func _debug_dump(label: String) -> void :
    var state: String = "null"
    if exile_data.tactics_override != null:
        var ov: ExileTacticsOverride = exile_data.tactics_override
        state = "rules=%d, fallback=%d, lock=%.2f, kite=%d" % [
            ov.target_rules.size(), ov.fallback_picker, ov.target_lock_seconds, ov.kite_profile
        ]
    print("[Tactics] %s %s (id=%d) override={%s}" % [label, exile_data.name, exile_data.id, state])
