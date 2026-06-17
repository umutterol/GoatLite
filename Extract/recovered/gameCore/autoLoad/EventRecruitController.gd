














extends Node

const EVENT_RECRUIT_MODAL_SCENE: PackedScene = preload("res://gameUI/recruitment/EventRecruitModal.tscn")



var _suspended: bool = false




var _pending: Array[Dictionary] = []



var _active: EventRecruitModal = null


func _ready() -> void :
    GameState.event_recruits_offered.connect(_on_event_recruits_offered)









func suspend() -> void :
    _suspended = true





func resume() -> void :
    if not _suspended:

        _try_show_next()
        return
    _suspended = false
    _try_show_next()






func _on_event_recruits_offered(recruits: Array[RecruitData], source: String) -> void :
    if recruits.is_empty():
        return
    _pending.append({"recruits": recruits, "source": source})
    _try_show_next()






func _try_show_next() -> void :
    if _suspended:
        return
    if _active != null:
        return
    if _pending.is_empty():
        return
    var offer: Dictionary = _pending.pop_front()
    var recruits: Array[RecruitData] = offer["recruits"]
    var source: String = offer["source"]

    var modal: EventRecruitModal = EVENT_RECRUIT_MODAL_SCENE.instantiate()
    _active = modal
    modal.tree_exited.connect(_on_modal_closed)




    get_tree().root.add_child.call_deferred(modal)
    _populate_when_ready(modal, recruits, source)


func _populate_when_ready(modal: EventRecruitModal, recruits: Array[RecruitData], source: String) -> void :

    await modal.ready
    modal.populate(recruits, source)


func _on_modal_closed() -> void :
    _active = null


    _try_show_next()
