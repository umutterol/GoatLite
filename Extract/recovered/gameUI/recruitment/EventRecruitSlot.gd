







class_name EventRecruitSlot
extends VBoxContainer

signal hire_pressed(recruit_data: RecruitData)

@onready var recruit_card: RecruitCard = $RecruitCard
@onready var cost_label: Label = $FooterPanel / FooterLayout / CostLabel
@onready var hire_button: Button = $FooterPanel / FooterLayout / HireButton

var _recruit_data: RecruitData


func bind(recruit_data: RecruitData) -> void :
    _recruit_data = recruit_data
    if recruit_data == null or recruit_data.exile_data == null:
        push_warning("EventRecruitSlot: bound to null recruit/exile")
        return
    recruit_card.bind(recruit_data.exile_data)
    _refresh_cost_label()
    refresh_buttons()
    if not hire_button.pressed.is_connected(_on_hire_pressed):
        hire_button.pressed.connect(_on_hire_pressed)





func _refresh_cost_label() -> void :
    if not _recruit_data.has_any_cost():
        cost_label.text = "Free"
        cost_label.modulate = Color(0.7, 1.0, 0.7)
        return
    var parts: Array[String] = []
    if _recruit_data.scrap_cost > 0:
        parts.append("%d scrap" % _recruit_data.scrap_cost)
    if _recruit_data.exalt_cost > 0:
        parts.append("%d exalt" % _recruit_data.exalt_cost)
    if _recruit_data.chaos_cost > 0:
        parts.append("%d chaos" % _recruit_data.chaos_cost)
    if _recruit_data.food_cost > 0:
        parts.append("%d food" % _recruit_data.food_cost)
    cost_label.text = " + ".join(parts)
    cost_label.modulate = Color.WHITE




func refresh_buttons() -> void :
    if _recruit_data == null:
        return
    var can_afford: bool = _player_can_afford()


    var roster_room: bool = GameState.get_living_exile_count() < GameState.max_exiles
    hire_button.disabled = not (can_afford and roster_room)
    if not roster_room:
        hire_button.text = "Roster Full"
    elif not can_afford:
        hire_button.text = "Can't Afford"
    else:
        hire_button.text = "Hire"




func lock_as_hired() -> void :
    hire_button.disabled = true
    hire_button.text = "Hired"


func _player_can_afford() -> bool:
    if GameState.food < _recruit_data.food_cost:
        return false
    if GameState.chaos < _recruit_data.chaos_cost:
        return false
    if GameState.scrap < _recruit_data.scrap_cost:
        return false
    if GameState.exalt < _recruit_data.exalt_cost:
        return false
    return true


func _on_hire_pressed() -> void :
    hire_pressed.emit(_recruit_data)




func get_recruit_data() -> RecruitData:
    return _recruit_data
