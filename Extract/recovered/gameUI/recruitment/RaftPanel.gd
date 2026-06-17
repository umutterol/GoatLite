








class_name RaftPanel
extends PanelContainer

signal join_confirmed(raft: RaftPanel)

const RECRUIT_CARD_SCENE: PackedScene = preload("res://gameUI/recruitment/RecruitCard.tscn")

const CONFIRM_RESET_SECONDS: float = 3.0
const CONFIRM_TEXT: String = "Are you sure?"
const DEFAULT_TEXT: String = "Join This Raft"
const CONFIRM_MODULATE: = Color(1.0, 0.8, 0.0)

@onready var title_label: Label = $Layout / TitleLabel
@onready var recruits_row: HBoxContainer = $Layout / RecruitsRow
@onready var join_button: Button = $Layout / JoinButton

var exiles: Array[ExileData] = []

var _is_confirming: bool = false
var _confirm_timer: SceneTreeTimer = null


func _ready() -> void :
    join_button.pressed.connect(_on_join_pressed)



func setup(p_title: String, p_exiles: Array[ExileData]) -> void :
    title_label.text = p_title
    exiles = p_exiles

    _render_recruits()
    _reset_confirm_state()




func set_locked(locked: bool) -> void :
    join_button.disabled = locked
    if locked:
        _reset_confirm_state()




func _render_recruits() -> void :
    for child in recruits_row.get_children():
        child.queue_free()
    for exile in exiles:
        var card: RecruitCard = RECRUIT_CARD_SCENE.instantiate()
        recruits_row.add_child(card)



        card.call_deferred("bind", exile)




func _on_join_pressed() -> void :
    if not _is_confirming:
        _is_confirming = true
        join_button.text = CONFIRM_TEXT
        join_button.modulate = CONFIRM_MODULATE

        _confirm_timer = get_tree().create_timer(CONFIRM_RESET_SECONDS)


        var armed_timer: = _confirm_timer
        await armed_timer.timeout
        if _is_confirming and _confirm_timer == armed_timer:
            _reset_confirm_state()
        return


    join_confirmed.emit(self)


func _reset_confirm_state() -> void :
    _is_confirming = false
    _confirm_timer = null
    if is_inside_tree() and join_button:
        join_button.text = DEFAULT_TEXT
        join_button.modulate = Color.WHITE
