extends Control













const FALLBACK_AREA: WorldEnum.AREAS = WorldEnum.AREAS.COAST




const STATUS_LABEL_DEFAULT_COLOR: = Color(0.85, 0.8, 0.7, 1.0)
const STATUS_LABEL_REJECT_COLOR: = Color(1.0, 0.4, 0.4, 1.0)


const REJECT_SHAKE_AMPLITUDE: float = 8.0
const REJECT_SHAKE_STEP: float = 0.045
const REJECT_FLASH_COLOR: = Color(1.6, 0.5, 0.5, 1.0)
const REJECT_FLASH_IN: float = 0.08
const REJECT_FLASH_OUT: float = 0.3





const ExileCardScene: = preload("res://gameUI/guild/exileGuildCard/ExileGuildCard.tscn")
const MissionCardScene: = preload("res://gameUI/missions/MissionCard.tscn")
const MonsterTooltipScene: = preload("res://gameUI/tooltips/NonKeywordTooltipPanel.tscn")



@onready var mission_list: VBoxContainer = %MissionList
@onready var party_list: VBoxContainer = %PartyList
@onready var party_header: Label = %PartyHeader
@onready var clear_button: Button = %ClearButton
@onready var status_label: Label = %StatusLabel
@onready var back_button: Button = %BackButton
@onready var day_label: Label = %DayLabel
@onready var area_selector: OptionButton = %AreaSelector
@onready var scouting_bar: ProgressBar = %ScoutingBar
@onready var speed_button: Button = %SpeedButton
@onready var auto_start_check: CheckBox = %AutoStartCheck

var _cards: Array[MissionCard] = []


var _current_area: WorldEnum.AREAS = FALLBACK_AREA


var _selector_area_ids: Array[WorldEnum.AREAS] = []



var _monster_tooltip: NonKeywordTooltipPanel = null






func _ready() -> void :

    GameState.prune_invalid_party_members()

    back_button.pressed.connect(_on_back)
    clear_button.pressed.connect(GameState.clear_party)



    GameState.party_changed.connect(_refresh_party)
    GameState.exile_updated.connect(_on_exile_updated)


    area_selector.item_selected.connect(_on_area_selected)
    AreaManager.area_unlocked.connect(_on_area_unlocked)
    AreaManager.scouting_updated.connect(_on_scouting_updated)



    speed_button.pressed.connect(_on_speed_button_pressed)
    auto_start_check.toggled.connect(_on_auto_start_toggled)
    _refresh_playback_pref_controls()


    _monster_tooltip = MonsterTooltipScene.instantiate()
    add_child(_monster_tooltip)



    _current_area = GameState.selected_mission_board_area

    day_label.text = "Day %d" % GameState.current_day
    _populate_area_selector()
    _refresh_missions()
    _refresh_scouting_bar()
    _refresh_party()
    _update_action_state()









func _populate_area_selector() -> void :
    area_selector.clear()
    _selector_area_ids.clear()

    var unlocked: Array[WorldEnum.AREAS] = AreaManager.get_unlocked_area_ids()
    if unlocked.is_empty():

        _selector_area_ids.append(FALLBACK_AREA)
        area_selector.add_item(_area_display_name(FALLBACK_AREA))
        _current_area = FALLBACK_AREA
        area_selector.disabled = true
        return




    if not unlocked.has(_current_area):
        _current_area = unlocked[0]
        GameState.selected_mission_board_area = _current_area

    var selected_index: int = 0
    for i in unlocked.size():
        var area_id: WorldEnum.AREAS = unlocked[i]
        _selector_area_ids.append(area_id)
        area_selector.add_item(_area_display_name(area_id))
        if area_id == _current_area:
            selected_index = i

    area_selector.select(selected_index)
    area_selector.disabled = unlocked.size() <= 1


func _area_display_name(area_id: WorldEnum.AREAS) -> String:
    var data: AreaData = AreaManager.get_area_data(area_id)
    if data and not data.display_name.is_empty():
        return data.display_name
    return WorldEnum.AREAS.keys()[area_id]


func _refresh_scouting_bar() -> void :
    scouting_bar.value = AreaManager.get_scouting_percent(_current_area)


func _on_area_selected(index: int) -> void :
    if index < 0 or index >= _selector_area_ids.size():
        return
    var new_area: WorldEnum.AREAS = _selector_area_ids[index]
    if new_area == _current_area:
        return
    _current_area = new_area


    GameState.selected_mission_board_area = new_area
    _refresh_missions()
    _refresh_scouting_bar()
    _update_action_state()


func _on_area_unlocked(_area_id: WorldEnum.AREAS) -> void :

    _populate_area_selector()


func _on_scouting_updated(area_id: WorldEnum.AREAS, _new_percent: float) -> void :
    if area_id == _current_area:
        _refresh_scouting_bar()










func _refresh_playback_pref_controls() -> void :
    speed_button.text = _format_speed_label(UserPreferences.default_playback_speed)
    auto_start_check.set_pressed_no_signal(UserPreferences.auto_start_playback)




func _on_speed_button_pressed() -> void :
    var levels: Array[float] = UserPreferences.ALLOWED_PLAYBACK_SPEEDS
    var current_idx: int = UserPreferences.get_default_playback_speed_index()
    var next_idx: int = (current_idx + 1) % levels.size()
    UserPreferences.set_default_playback_speed(levels[next_idx])
    _refresh_playback_pref_controls()


func _on_auto_start_toggled(button_pressed: bool) -> void :
    UserPreferences.set_auto_start_playback(button_pressed)




func _format_speed_label(speed: float) -> String:
    if is_equal_approx(speed, round(speed)):
        return "%dx" % int(round(speed))
    return "%.1fx" % speed


func _unhandled_input(event: InputEvent) -> void :
    if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
        get_viewport().set_input_as_handled()
        _on_back()






func _refresh_missions() -> void :
    for child in mission_list.get_children():
        child.queue_free()
    _cards.clear()





    var offerings: Array[Dictionary] = MissionManager.get_available_offerings(_current_area)
    if offerings.is_empty():
        var empty: = Label.new()
        empty.text = "No missions available in this area."
        empty.modulate = Color(0.7, 0.7, 0.7)
        mission_list.add_child(empty)
        return




    offerings.sort_custom(
        func(a: Dictionary, b: Dictionary) -> bool:
            return (a.mission as MissionData).level > (b.mission as MissionData).level
    )

    for offering in offerings:
        var mission: MissionData = offering.mission
        var instance: OpportunityInstance = offering.instance
        var card: MissionCard = MissionCardScene.instantiate()
        mission_list.add_child(card)





        card.populate(mission, _current_area, _monster_tooltip, instance)
        card.embark_requested.connect(_on_embark)
        _cards.append(card)






func _on_exile_updated(_exile: ExileData) -> void :


    _refresh_party()


func _refresh_party() -> void :
    for child in party_list.get_children():
        child.queue_free()




    var roster: Array[ExileData] = _get_selectable_exiles()
    if roster.is_empty():
        var empty: = Label.new()
        empty.text = "No exiles available."
        empty.modulate = Color(0.7, 0.7, 0.7)
        party_list.add_child(empty)
    else:
        roster.sort_custom( func(a, b): return a.id < b.id)
        for exile in roster:



            var card: ExileGuildCard = ExileCardScene.instantiate()
            party_list.add_child(card)
            card.set_compact_mode(true)
            card.setup(exile)
            card.set_selected(GameState.is_in_party(exile.id))
            card.card_clicked.connect(_on_party_card_clicked)

    party_header.text = "Party (%d/%d)" % [GameState.current_party_ids.size(), GameState.MAX_PARTY_SIZE]
    clear_button.disabled = GameState.current_party_ids.is_empty()
    _update_action_state()


func _get_selectable_exiles() -> Array[ExileData]:



    var result: Array[ExileData] = []
    for exile in GameState.get_core_exiles():
        if exile.status == "idle" or exile.status == "recovering":
            result.append(exile)
    return result










func _update_action_state() -> void :
    var party_ids: Array[int] = GameState.current_party_ids
    var has_party: bool = party_ids.size() > 0





    var blocked_names: Array[String] = []
    for exile_id in party_ids:
        var exile: ExileData = GameState.get_exile_by_id(exile_id)
        if exile == null:
            continue
        if not exile.is_embark_ready():
            blocked_names.append(exile.name)
    var all_ready: bool = blocked_names.is_empty()


    var legal: bool = has_party and all_ready
    var status_text: String
    var reason: String

    if not has_party:
        status_text = "Add at least one exile to the party."
        reason = "No party selected."
    elif not all_ready:
        status_text = "Waiting on recovery: %s" % ", ".join(blocked_names)
        reason = "Party member(s) recovering: %s" % ", ".join(blocked_names)
    else:
        status_text = "Ready - %d exile(s) embarking." % party_ids.size()
        reason = ""

    status_label.text = status_text


    status_label.modulate = STATUS_LABEL_DEFAULT_COLOR
    for card in _cards:
        if is_instance_valid(card):
            card.set_can_embark(legal, reason)


func _on_embark(mission: MissionData, instance: OpportunityInstance) -> void :

    for exile_id in GameState.current_party_ids:
        var exile: ExileData = GameState.get_exile_by_id(exile_id)
        if not exile or not exile.is_embark_ready():
            status_label.text = "Cannot embark — one or more exiles aren't ready."
            return





    var ids_snapshot: Array[int] = []
    ids_snapshot.assign(GameState.current_party_ids)
    var active: ActiveMission = MissionManager.accept_mission(mission, ids_snapshot, instance)
    if not active:
        status_label.text = "Failed to start mission. (See log.)"
        return
    MissionManager.start_runner(active)
    SceneRouter.to_combat_playback()








func _on_party_card_clicked(exile: ExileData, card: ExileGuildCard) -> void :
    if exile == null:
        return
    var would_add: bool = not GameState.is_in_party(exile.id)
    var at_cap: bool = GameState.current_party_ids.size() >= GameState.MAX_PARTY_SIZE
    if would_add and at_cap:
        _play_party_full_rejection(card)
        return
    GameState.toggle_party_member(exile.id)










func _play_party_full_rejection(card: ExileGuildCard) -> void :
    status_label.text = "Party full (%d/%d) — remove someone first." % [
        GameState.current_party_ids.size(), 
        GameState.MAX_PARTY_SIZE, 
    ]
    status_label.modulate = STATUS_LABEL_REJECT_COLOR

    if not is_instance_valid(card):
        return


    var origin_x: float = card.position.x
    var shake: = create_tween()
    shake.tween_property(card, "position:x", origin_x + REJECT_SHAKE_AMPLITUDE, REJECT_SHAKE_STEP)
    shake.tween_property(card, "position:x", origin_x - REJECT_SHAKE_AMPLITUDE, REJECT_SHAKE_STEP)
    shake.tween_property(card, "position:x", origin_x + REJECT_SHAKE_AMPLITUDE * 0.75, REJECT_SHAKE_STEP)
    shake.tween_property(card, "position:x", origin_x - REJECT_SHAKE_AMPLITUDE * 0.75, REJECT_SHAKE_STEP)
    shake.tween_property(card, "position:x", origin_x, REJECT_SHAKE_STEP)



    var origin_mod: Color = card.modulate
    var flash: = create_tween()
    flash.tween_property(card, "modulate", REJECT_FLASH_COLOR, REJECT_FLASH_IN)
    flash.tween_property(card, "modulate", origin_mod, REJECT_FLASH_OUT)


func _on_back() -> void :
    SceneRouter.to_guild()
