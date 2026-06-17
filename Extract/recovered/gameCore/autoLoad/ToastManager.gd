extends CanvasLayer

































const TOAST_SCENE: PackedScene = preload("res://gameUI/smallComponents/Toast.tscn")



var _suspended: bool = false




var _pending: Array[String] = []



var _active: Toast = null


func _ready() -> void :
    layer = 100
    _connect_signals()


func _connect_signals() -> void :

    AreaManager.discovery_made.connect(_on_discovery_made)

    AreaManager.area_unlocked.connect(_on_area_unlocked)

    MissionManager.opportunity_appeared.connect(_on_opportunity_appeared)

    MissionManager.opportunity_last_day.connect(_on_opportunity_last_day)

    MissionManager.boss_cooldown_expired.connect(_on_boss_cooldown_expired)


    GameState.scar_assigned.connect(_on_scar_assigned)



    GameState.exile_lost.connect(_on_exile_lost)
    GameState.exile_long_lost.connect(_on_exile_long_lost)












func show_toast(message: String) -> void :
    if message.is_empty():
        return
    _pending.append(message)
    _try_show_next()





func suspend() -> void :
    _suspended = true




func resume() -> void :
    if not _suspended:
        return
    _suspended = false
    _try_show_next()






func _try_show_next() -> void :
    if _suspended:
        return
    if _active != null:
        return
    if _pending.is_empty():
        return
    var message: String = _pending.pop_front()
    var toast: Toast = TOAST_SCENE.instantiate()
    add_child(toast)
    _active = toast
    toast.finished.connect(_on_toast_finished)
    toast.show_message(message)


func _on_toast_finished() -> void :
    _active = null
    _try_show_next()






func _on_discovery_made(_area_id: WorldEnum.AREAS, mission: MissionData) -> void :


    var body: String = mission.discovery_description if not mission.discovery_description.is_empty() else "%s discovered." % mission.display_name
    show_toast("Discovery: " + body)


func _on_area_unlocked(area_id: WorldEnum.AREAS) -> void :
    var data: AreaData = AreaManager.get_area_data(area_id)
    var label: String = data.display_name if data else "New region"
    show_toast("New area unlocked: " + label)


func _on_opportunity_appeared(_area_id: WorldEnum.AREAS, mission: MissionData) -> void :



    if mission.mission_id.begins_with("rescue_captured_"):
        return
    show_toast("Opportunity: " + mission.display_name)


func _on_opportunity_last_day(_area_id: WorldEnum.AREAS, mission: MissionData, instance: OpportunityInstance) -> void :



    var name: String = mission.display_name
    if instance != null and not instance.display_name_override.is_empty():
        name = instance.display_name_override
    show_toast("Last day: " + name)


func _on_boss_cooldown_expired(_area_id: WorldEnum.AREAS, mission: MissionData) -> void :
    show_toast("Boss returned: " + mission.display_name)


func _on_scar_assigned(exile_data: ExileData, scar_trait: TraitDefinition) -> void :


    if exile_data == null or scar_trait == null:
        return
    show_toast("%s Got a Scar: %s" % [exile_data.name, scar_trait.name])


func _on_exile_lost(exile_data: ExileData, area_id: WorldEnum.AREAS) -> void :
    if exile_data == null:
        return
    var area_name: String = WorldEnum.AREAS.keys()[area_id] if area_id >= 0 else "the area"
    show_toast("Scouts found evidence that %s was captured. Rescue mission posted in %s." % [
        exile_data.name, area_name, 
    ])


func _on_exile_long_lost(exile_data: ExileData, _area_id: WorldEnum.AREAS) -> void :
    if exile_data == null:
        return
    show_toast("Lost the trail of %s. We may never see them again." % exile_data.name)
