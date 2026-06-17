












class_name EventRecruitModal
extends CanvasLayer

const EVENT_RECRUIT_SLOT_SCENE: PackedScene = preload("res://gameUI/recruitment/EventRecruitSlot.tscn")

@onready var dim: ColorRect = $Dim
@onready var title_label: Label = $Dim / Panel / Layout / Header / TitleLabel
@onready var subtitle_label: Label = $Dim / Panel / Layout / SubtitleLabel
@onready var cards_row: HBoxContainer = $Dim / Panel / Layout / ScrollContainer / CardsRow
@onready var done_button: Button = $Dim / Panel / Layout / Footer / DoneButton
@onready var minimize_button: Button = $Dim / Panel / Layout / Header / MinimizeButton
@onready var minimized_badge: Control = $MinimizedBadge
@onready var expand_button: Button = $MinimizedBadge / PulseRoot / ExpandButton

var _slots: Array[EventRecruitSlot] = []


func _ready() -> void :
    done_button.pressed.connect(_close)
    minimize_button.pressed.connect(_minimize)
    expand_button.pressed.connect(_expand)


    GameState.resource_changed.connect(_on_resource_changed)




func populate(recruits: Array[RecruitData], source: String) -> void :
    _set_flavour_text(source)
    for child in cards_row.get_children():
        child.queue_free()
    _slots.clear()
    for recruit in recruits:
        var slot: EventRecruitSlot = EVENT_RECRUIT_SLOT_SCENE.instantiate()
        cards_row.add_child(slot)
        slot.bind(recruit)
        slot.hire_pressed.connect(_on_slot_hire)
        _slots.append(slot)


func _set_flavour_text(source: String) -> void :
    match source:
        "passing_boat":
            title_label.text = "A Passing Boat"
            subtitle_label.text = "Wanderers offering their service. Pay their price and they'll join the guild."
        "mission_recruit":
            title_label.text = "Saved Survivor"
            subtitle_label.text = "Spared from the mission's perils — they wish to join the guild."
        "wandering_exile":
            title_label.text = "A Wandering Exile"
            subtitle_label.text = "A random wandering exile offers to join — to help you restart."
        _:
            title_label.text = "Recruit Offer"
            subtitle_label.text = ""


func _on_slot_hire(recruit: RecruitData) -> void :
    var success: bool = RecruitmentManager.recruit_exile(recruit)
    if not success:

        _refresh_all_slots()
        return


    for slot in _slots:
        if slot.get_recruit_data() == recruit:
            slot.lock_as_hired()
        else:
            slot.refresh_buttons()


func _on_resource_changed(_resource_type: String, _old: int, _new: int) -> void :
    _refresh_all_slots()


func _refresh_all_slots() -> void :
    for slot in _slots:

        if not slot.hire_button.disabled or slot.hire_button.text != "Hired":
            slot.refresh_buttons()


func _close() -> void :
    queue_free()






func _minimize() -> void :
    dim.visible = false
    minimized_badge.visible = true


func _expand() -> void :
    dim.visible = true
    minimized_badge.visible = false
