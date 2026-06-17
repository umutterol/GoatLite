extends Node





signal mission_accepted(active_mission: ActiveMission)
signal mission_completed(active_mission: ActiveMission)
signal mission_failed(active_mission: ActiveMission)
signal opportunity_appeared(area_id: WorldEnum.AREAS, mission: MissionData)
signal opportunity_expired(area_id: WorldEnum.AREAS, mission_id: String)







signal opportunity_last_day(area_id: WorldEnum.AREAS, mission: MissionData, instance: OpportunityInstance)





signal boss_cooldown_expired(area_id: WorldEnum.AREAS, mission: MissionData)



var _mission_registry: Dictionary = {}


var _active_missions: Array[ActiveMission] = []


var _runners: Dictionary = {}




var last_resolved_runner: MissionRunner = null








var pending_rescued_exiles: Array[Dictionary] = []







var pending_long_lost_surfaced: Array[Dictionary] = []





var last_run_mission_id: String = ""



const MISSION_DATA_ROOT: String = "res://systems/mission/"


var _encounter_registry: Array[EncounterData] = []


func _ready() -> void :
    _register_missions()
    _load_encounter_registry()
    _validate_progression_references()
    GameState.day_changed.connect(_on_day_changed)


func _register_missions() -> void :
    _scan_missions_recursive(MISSION_DATA_ROOT)
    print("MissionManager: registered %d missions" % _mission_registry.size())


func _scan_missions_recursive(path: String) -> void :


    var paths: Array[String] = ResourceDirScan.list_tres_files_recursive(path)
    if paths.is_empty() and DirAccess.open(path) == null:
        push_warning("MissionManager: could not open mission path %s" % path)
        return

    for full_path in paths:
        var resource: Resource = load(full_path)
        if not resource is MissionData:
            continue
        var mission: MissionData = resource
        if mission.mission_id == "":
            push_warning("MissionManager: %s has empty mission_id — skipped" % full_path)
            continue
        if _mission_registry.has(mission.mission_id):
            push_error("MissionManager: duplicate mission_id '%s' (file %s)" % [mission.mission_id, full_path])
            continue
        _mission_registry[mission.mission_id] = mission






func _validate_progression_references() -> void :
    for area_data: AreaData in AreaManager.area_data_list:
        for connection: AreaConnection in area_data.connections:
            if connection.trigger_mission_id != "" and not _mission_registry.has(connection.trigger_mission_id):
                push_error(
                    "MissionManager: %s has AreaConnection trigger_mission_id '%s' which is not registered"
                    %[area_data.display_name, connection.trigger_mission_id]
                )
            for req: ProgressionRequirement in connection.requirements:
                if req.type == ProgressionRequirement.TYPE.MISSION_COMPLETED:
                    if not _mission_registry.has(req.mission_id):
                        push_error(
                            "MissionManager: %s AreaConnection requirement references unknown mission '%s'"
                            %[area_data.display_name, req.mission_id]
                        )

    for mission: MissionData in _mission_registry.values():
        match mission.availability_type:
            MissionEnums.AVAILABILITY_TYPE.DISCOVERABLE:
                if mission.discovery_base_chance <= 0.0:
                    push_warning(
                        "MissionManager: DISCOVERABLE mission '%s' has discovery_base_chance=0 — it will never be found"
                        %mission.mission_id
                    )











func get_available_missions(area_id: WorldEnum.AREAS) -> Array[MissionData]:
    var available: Array[MissionData] = []
    var area_progress: AreaProgress = AreaManager.get_area_progress(area_id)
    if not area_progress or not area_progress.unlocked:
        return available

    for mission: MissionData in _mission_registry.values():
        if mission.area_requirement != area_id:
            continue
        if not _is_mission_available(mission, area_progress):
            continue
        available.append(mission)

    return available











func get_available_offerings(area_id: WorldEnum.AREAS) -> Array[Dictionary]:
    var offerings: Array[Dictionary] = []
    var area_progress: AreaProgress = AreaManager.get_area_progress(area_id)
    if not area_progress or not area_progress.unlocked:
        return offerings


    for mission: MissionData in _mission_registry.values():
        if mission.area_requirement != area_id:
            continue
        if mission.availability_type == MissionEnums.AVAILABILITY_TYPE.OPPORTUNITY:
            continue
        if not _is_mission_available(mission, area_progress):
            continue
        offerings.append({"mission": mission, "instance": null})



    for instance_id: String in area_progress.active_opportunities.keys():
        var instance: OpportunityInstance = _resolve_opportunity_instance(area_progress, instance_id)
        if instance == null:
            continue
        var template: MissionData = get_mission_by_id(instance.template_mission_id)
        if not template:
            continue


        if not _check_prerequisites(template):
            continue




        var mission_for_offering: MissionData = template
        if instance.runtime_mission_data != null:
            mission_for_offering = instance.runtime_mission_data
        offerings.append({"mission": mission_for_offering, "instance": instance})

    return offerings







func is_mission_unlockable(mission: MissionData, area_progress: AreaProgress) -> bool:

    if mission.boss_mission and area_progress.boss_defeated:
        var days_since: int = GameState.current_day - area_progress.boss_last_completed_day
        if days_since < mission.boss_cooldown_days:
            return false
    if not _check_prerequisites(mission):
        return false
    return true


func _is_mission_available(mission: MissionData, area_progress: AreaProgress) -> bool:

    if mission.availability_type == MissionEnums.AVAILABILITY_TYPE.STANDARD:
        if mission.mission_id in area_progress.completed_mission_ids:
            return false


    if mission.availability_type == MissionEnums.AVAILABILITY_TYPE.DISCOVERABLE:
        if mission.mission_id not in area_progress.discovered_mission_ids:
            return false


    if mission.availability_type == MissionEnums.AVAILABILITY_TYPE.OPPORTUNITY:
        if mission.mission_id not in area_progress.active_opportunities:
            return false


    if mission.boss_mission and area_progress.boss_defeated:
        var days_since: int = GameState.current_day - area_progress.boss_last_completed_day
        if days_since < mission.boss_cooldown_days:
            return false


    if not _check_prerequisites(mission):
        return false

    return true


func _check_prerequisites(mission: MissionData) -> bool:
    for req: ProgressionRequirement in mission.prerequisites:

        var req_progress: AreaProgress = AreaManager.get_area_progress(req.area)
        if not req_progress:
            return false
        if not _evaluate_requirement(req, req_progress):
            return false
    return true


func _evaluate_requirement(req: ProgressionRequirement, progress: AreaProgress) -> bool:
    match req.type:
        ProgressionRequirement.TYPE.MISSION_COMPLETED:
            return req.mission_id in progress.completed_mission_ids
        ProgressionRequirement.TYPE.MISSION_TAG_COUNT:
            var count: int = progress.tag_completion_counts.get(req.tag, 0)
            return count >= int(req.required_value)
        ProgressionRequirement.TYPE.TOTAL_MISSIONS_IN_AREA:
            return progress.total_missions_completed >= int(req.required_value)
        ProgressionRequirement.TYPE.SCOUTING_PERCENT:


            return AreaManager.get_scouting_percent(progress.area_id) >= req.required_value
        ProgressionRequirement.TYPE.BOSS_DEFEATED:
            return progress.boss_defeated
        _:
            push_warning("MissionManager: unknown requirement type %s" % req.type)
            return false






func get_discoverable_missions_in_area(area_id: WorldEnum.AREAS) -> Array[MissionData]:
    var result: Array[MissionData] = []
    for mission: MissionData in _mission_registry.values():
        if mission.area_requirement != area_id:
            continue
        if mission.availability_type != MissionEnums.AVAILABILITY_TYPE.DISCOVERABLE:
            continue
        result.append(mission)
    return result


func get_mission_by_id(mission_id: String) -> MissionData:
    return _mission_registry.get(mission_id, null)


func get_active_missions() -> Array[ActiveMission]:
    return _active_missions


func has_active_mission() -> bool:
    return _active_missions.size() > 0













func accept_mission(
    mission: MissionData, 
    exile_ids: Array[int], 
    opportunity_instance: OpportunityInstance = null
) -> ActiveMission:
    if not mission:
        push_warning("MissionManager: tried to accept null mission")
        return null


    if has_active_mission():
        push_warning("MissionManager: already have an active mission")
        return null


    last_resolved_runner = null
    last_run_mission_id = mission.mission_id


    pending_rescued_exiles.clear()
    pending_long_lost_surfaced.clear()






    for exile_id: int in exile_ids:
        var exile: ExileData = GameState.get_exile_by_id(exile_id)
        if not exile:
            push_warning("MissionManager: exile %d not found" % exile_id)
            return null
        if not exile.is_embark_ready():
            push_warning(
                "MissionManager: exile %d not embark-ready (status: %s, life: %.1f)"
                %[exile_id, exile.status, exile.current_life]
            )
            return null

    var active: ActiveMission = ActiveMission.create(mission, mission.area_requirement)
    active.assigned_exile_ids = exile_ids
    active.day_started = GameState.current_day





    if opportunity_instance == null and mission.availability_type == MissionEnums.AVAILABILITY_TYPE.OPPORTUNITY:
        var area_progress: AreaProgress = AreaManager.get_area_progress(mission.area_requirement)


        opportunity_instance = _resolve_opportunity_instance(area_progress, mission.mission_id)
    active.opportunity_instance = opportunity_instance


    for exile_id: int in exile_ids:
        var exile: ExileData = GameState.get_exile_by_id(exile_id)
        exile.status = "on_mission"

    _active_missions.append(active)
    mission_accepted.emit(active)
    return active




func start_runner(active: ActiveMission, seed_value: int = 0) -> MissionRunner:
    if not active:
        push_warning("MissionManager.start_runner: null active mission")
        return null
    if _runners.has(active):
        return _runners[active]
    var runner: = MissionRunner.new(active, seed_value)
    _runners[active] = runner
    return runner


func get_runner(active: ActiveMission) -> MissionRunner:
    return _runners.get(active, null)



func advance_encounter(active_mission: ActiveMission) -> bool:
    if not active_mission or active_mission.status != ActiveMission.STATUS.IN_PROGRESS:
        return false

    active_mission.current_encounter_index += 1

    if active_mission.current_encounter_index >= active_mission.total_encounters:
        _resolve_mission(active_mission, ActiveMission.STATUS.COMPLETED)
        return false

    return true



func end_mission_early(active_mission: ActiveMission, retreated: bool = false) -> void :
    if not active_mission:
        return
    var end_status: ActiveMission.STATUS
    if retreated:
        end_status = ActiveMission.STATUS.RETREATED
    else:
        end_status = ActiveMission.STATUS.FAILED
    _resolve_mission(active_mission, end_status)


func _resolve_mission(active_mission: ActiveMission, end_status: ActiveMission.STATUS) -> void :
    active_mission.status = end_status




    var party_scouting_bonus: float = _compute_party_scouting_bonus(active_mission.assigned_exile_ids)

    var succeeded: bool = end_status == ActiveMission.STATUS.COMPLETED






    var scouting_gained: float = AreaManager.record_mission_completion(
        active_mission.area_id, 
        active_mission.mission_data, 
        active_mission.completion_percent, 
        party_scouting_bonus, 
        succeeded
    )



    var resolving_runner: MissionRunner = _runners.get(active_mission)
    if resolving_runner:
        resolving_runner.last_scouting_gained = scouting_gained




    _handle_captures(active_mission)
    _handle_rescue_completion(active_mission, end_status)





    if succeeded and active_mission.mission_data.availability_type == MissionEnums.AVAILABILITY_TYPE.OPPORTUNITY:
        var area_progress: AreaProgress = AreaManager.get_area_progress(active_mission.area_id)
        if area_progress:




            var erase_id: String = active_mission.mission_data.mission_id
            if active_mission.opportunity_instance != null:
                erase_id = active_mission.opportunity_instance.instance_id
            area_progress.active_opportunities.erase(erase_id)


    for exile_id: int in active_mission.assigned_exile_ids:
        var exile: ExileData = GameState.get_exile_by_id(exile_id)
        if exile and exile.status == "on_mission":
            exile.status = "idle"




    GameState.prune_invalid_party_members()

    _active_missions.erase(active_mission)
    _runners.erase(active_mission)

    if end_status == ActiveMission.STATUS.COMPLETED:
        mission_completed.emit(active_mission)




        _maybe_offer_mission_recruit(active_mission)
    else:
        mission_failed.emit(active_mission)






func _maybe_offer_mission_recruit(active_mission: ActiveMission) -> void :
    var data: MissionData = active_mission.mission_data
    if data == null:
        return
    if not data.mission_tags.has(MissionEnums.MISSION_TAGS.RECRUIT):
        return




    var quality_bonus: float = data.recruit_quality_bonus
    if quality_bonus < 0.0:
        quality_bonus = GameSettings.MISSION_RECRUIT_QUALITY_BONUS

    var level_margin: float = data.recruit_level_margin
    if level_margin < 0.0:
        level_margin = GameSettings.MISSION_RECRUIT_LEVEL_MARGIN
    level_margin = clampf(level_margin, 0.0, 1.0)

    var min_class_rarity: int = data.recruit_min_class_rarity
    if min_class_rarity < 0:
        min_class_rarity = GameSettings.MISSION_RECRUIT_MIN_CLASS_RARITY

    var min_trait_rarity: int = data.recruit_min_trait_rarity
    if min_trait_rarity < 0:
        min_trait_rarity = GameSettings.MISSION_RECRUIT_MIN_TRAIT_RARITY



    var count: int = max(1, data.recruit_count)

    var ceiling: int = max(1, data.level)
    var floor_level: int = max(1, int(round(float(ceiling) * (1.0 - level_margin))))

    var recruits: Array[RecruitData] = RecruitmentManager.generate_event_recruits({
        "count": count, 
        "level_min": floor_level, 
        "level_max": ceiling, 
        "quality_bonus": quality_bonus, 
        "min_class_rarity": min_class_rarity, 
        "min_trait_rarity": min_trait_rarity, 
        "free": true, 
    })

    if recruits.is_empty():
        push_warning("MissionManager: RECRUIT-tag mission '%s' produced no recruit" % data.mission_id)
        return

    GameState.event_recruits_offered.emit(recruits, "mission_recruit")






func _compute_party_scouting_bonus(exile_ids: Array[int]) -> float:
    var total_points: float = 0.0
    for exile_id: int in exile_ids:
        var exile: ExileData = GameState.get_exile_by_id(exile_id)
        if not exile or not exile.current_stats:
            continue
        total_points += exile.current_stats.scouting
    return total_points / 100.0










func _make_opportunity_instance(mission_id: String) -> OpportunityInstance:
    var instance: = OpportunityInstance.new()
    instance.instance_id = mission_id
    instance.template_mission_id = mission_id
    instance.day_appeared = GameState.current_day
    return instance








func _resolve_opportunity_instance(progress: AreaProgress, key: String) -> OpportunityInstance:
    if progress == null:
        return null
    if not progress.active_opportunities.has(key):
        return null
    var value: Variant = progress.active_opportunities[key]
    if value is OpportunityInstance:
        return value
    if value is int or value is float:
        var instance: = OpportunityInstance.new()
        instance.instance_id = key
        instance.template_mission_id = key
        instance.day_appeared = int(value)
        progress.active_opportunities[key] = instance
        return instance
    push_warning(
        "MissionManager: active_opportunities[%s] is unexpected type %s — skipping"
        %[key, typeof(value)]
    )
    return null













func _handle_captures(active_mission: ActiveMission) -> void :
    var runner: MissionRunner = _runners.get(active_mission)
    if not runner:
        return

    var area_progress: AreaProgress = AreaManager.get_area_progress(active_mission.area_id)
    if not area_progress:
        return

    var rescue_template_id: String = _rescue_mission_id_for_area(active_mission.area_id)
    if rescue_template_id.is_empty() or not _mission_registry.has(rescue_template_id):

        var orphan_count: int = 0
        for result in runner.defeat_results:
            if result.outcome and result.outcome.capture_duration_days > 0:
                orphan_count += 1
        if orphan_count > 0:
            push_warning(
                "MissionManager: no rescue mission registered for area %s — %d exile(s) captured with no recovery path"
                %[active_mission.area_id, orphan_count]
            )
        return

    for result in runner.defeat_results:
        if not result.outcome or result.outcome.capture_duration_days <= 0:
            continue
        var exile: ExileData = result.exile_data
        if not exile:
            continue
        if area_progress.captured_exile_ids.has(exile.id):
            continue

        area_progress.captured_exile_ids.append(exile.id)
        _spawn_rescue_instance(
            active_mission.area_id, area_progress, exile, "fresh", 
            result.outcome.rescue_timeout_days
        )
        GameState.exile_lost.emit(exile, active_mission.area_id)












func _spawn_rescue_instance(
    area_id: WorldEnum.AREAS, 
    area_progress: AreaProgress, 
    exile: ExileData, 
    origin: String, 
    timeout_days: int, 
) -> OpportunityInstance:
    var rescue_template_id: String = _rescue_mission_id_for_area(area_id)
    if rescue_template_id.is_empty() or not _mission_registry.has(rescue_template_id):
        push_warning(
            "MissionManager: no rescue mission registered for area %s — cannot spawn rescue for %s"
            %[area_id, exile.name]
        )
        return null

    var instance: = OpportunityInstance.new()
    instance.instance_id = "rescue_%d" % exile.id
    instance.template_mission_id = rescue_template_id
    instance.day_appeared = GameState.current_day
    instance.timeout_days_override = timeout_days
    instance.display_name_override = "Rescue %s" % exile.name
    instance.context = {"exile_id": exile.id, "origin": origin}






    var template: MissionData = _mission_registry[rescue_template_id]
    var effective_level: int = _compute_rescue_effective_level(area_id, exile, template)
    if effective_level != template.level:
        var runtime: MissionData = template.duplicate(true) as MissionData
        runtime.level = effective_level
        instance.runtime_mission_data = runtime

    area_progress.active_opportunities[instance.instance_id] = instance
    opportunity_appeared.emit(area_id, _mission_registry[rescue_template_id])
    return instance






func _compute_rescue_effective_level(
    area_id: WorldEnum.AREAS, exile: ExileData, template: MissionData
) -> int:
    var area_max: int = _max_non_rescue_mission_level_in_area(area_id)
    var capped: int = mini(exile.level, area_max)
    return maxi(capped, template.level)






func _max_non_rescue_mission_level_in_area(area_id: WorldEnum.AREAS) -> int:
    var max_level: int = 1
    for mission: MissionData in _mission_registry.values():
        if mission.area_requirement != area_id:
            continue
        if mission.mission_id.begins_with("rescue_captured_"):
            continue
        if mission.level > max_level:
            max_level = mission.level
    return max_level









func _handle_rescue_completion(active_mission: ActiveMission, end_status: ActiveMission.STATUS) -> void :
    if end_status != ActiveMission.STATUS.COMPLETED:
        return
    if not active_mission.mission_data.mission_id.begins_with("rescue_captured_"):
        return

    var instance: OpportunityInstance = active_mission.opportunity_instance
    if instance == null:
        push_warning("MissionManager: rescue completed without an OpportunityInstance — cannot identify captive")
        return

    var area_progress: AreaProgress = AreaManager.get_area_progress(active_mission.area_id)
    if not area_progress:
        return





    var exile_id: int = int(instance.context.get("exile_id", -1))
    if exile_id < 0:
        _apply_legacy_rescue_completion(area_progress, instance)
        return

    var exile: ExileData = GameState.get_exile_by_id(exile_id)
    if not exile:
        return





    if exile.status != "lost" and exile.status != "long_lost":
        push_warning(
            "MissionManager: rescue %s completed but exile %d is %s, not lost/long_lost — skipping heal"
            %[instance.instance_id, exile_id, exile.status]
        )
        area_progress.active_opportunities.erase(instance.instance_id)
        return









    var origin: String = String(instance.context.get("origin", "fresh"))
    exile.status = "recovering"
    if origin == "long_lost":
        exile.current_life = exile.current_stats.life * 0.2
        exile.current_vitality = exile.current_stats.max_vitality * 0.2





        exile.current_stats.morale = exile.current_stats.max_morale * 0.6
        exile.current_morale = exile.current_stats.morale
    else:
        exile.current_vitality = exile.current_stats.vitality
    GameState.exile_updated.emit(exile)
    GameState.exile_rescued.emit(exile, origin)


    pending_rescued_exiles.append({"exile": exile, "origin": origin})

    area_progress.captured_exile_ids.erase(exile_id)
    area_progress.long_lost_exile_ids.erase(exile_id)
    area_progress.active_opportunities.erase(instance.instance_id)






func _apply_legacy_rescue_completion(area_progress: AreaProgress, instance: OpportunityInstance) -> void :
    for exile_id_legacy in area_progress.captured_exile_ids:
        var exile: ExileData = GameState.get_exile_by_id(exile_id_legacy)
        if not exile:
            continue
        if exile.status != "lost" and exile.status != "captured":
            continue
        exile.status = "recovering"
        exile.current_vitality = exile.current_stats.vitality
        GameState.exile_updated.emit(exile)
        GameState.exile_rescued.emit(exile, "fresh")


        pending_rescued_exiles.append({"exile": exile, "origin": "fresh"})
    area_progress.captured_exile_ids.clear()
    area_progress.active_opportunities.erase(instance.instance_id)











func _handle_rescue_expiry(
    area_id: WorldEnum.AREAS, 
    area_progress: AreaProgress, 
    instance: OpportunityInstance
) -> void :
    var exile_id: int = int(instance.context.get("exile_id", -1))
    if exile_id < 0:
        return

    var exile: ExileData = GameState.get_exile_by_id(exile_id)
    if not exile:
        return





    var origin: String = String(instance.context.get("origin", "fresh"))
    if origin == "fresh":
        exile.status = "long_lost"
        if exile.lifecycle == null:
            exile.lifecycle = ExileLifecycleState.new()
        exile.lifecycle.lost_day = GameState.current_day


        exile.equipped_items.clear()

        area_progress.captured_exile_ids.erase(exile_id)
        if not area_progress.long_lost_exile_ids.has(exile_id):
            area_progress.long_lost_exile_ids.append(exile_id)
        GameState.exile_updated.emit(exile)
        GameState.exile_long_lost.emit(exile, area_id)







func _rescue_mission_id_for_area(area_id: WorldEnum.AREAS) -> String:
    var keys: Array = WorldEnum.AREAS.keys()
    if area_id < 0 or area_id >= keys.size():
        return ""
    return "rescue_captured_" + (keys[area_id] as String).to_lower()


















func try_roll_long_lost_rescue(scouting_gain: float) -> void :
    if scouting_gain <= 0.0:
        return
    var chance: float = scouting_gain * GameSettings.LONG_LOST_ROLL_PER_SCOUTING
    if randf() >= chance:
        return
    if _has_any_active_long_lost_rescue():
        return

    var pool: Array[Dictionary] = _collect_eligible_long_lost()
    if pool.is_empty():
        return

    var pick: Dictionary = _weighted_pick_by_level(pool)
    var exile: ExileData = pick.exile
    var area_id: WorldEnum.AREAS = pick.area_id
    var area_progress: AreaProgress = AreaManager.get_area_progress(area_id)
    if area_progress == null:
        return

    var instance: OpportunityInstance = _spawn_rescue_instance(
        area_id, area_progress, exile, "long_lost", 
        GameSettings.LONG_LOST_RESCUE_TIMEOUT
    )
    if instance != null:
        GameState.long_lost_rescue_surfaced.emit(exile, area_id)


        pending_long_lost_surfaced.append({"exile": exile, "area_id": area_id})







func _collect_eligible_long_lost() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for area_enum_value: int in WorldEnum.AREAS.values():
        var area_id: WorldEnum.AREAS = area_enum_value as WorldEnum.AREAS
        var progress: AreaProgress = AreaManager.get_area_progress(area_id)
        if progress == null:
            continue
        for exile_id in progress.long_lost_exile_ids:
            var exile: ExileData = GameState.get_exile_by_id(exile_id)
            if exile == null:
                continue
            if exile.lifecycle == null or exile.lifecycle.lost_day < 0:
                continue
            var days_lost: int = GameState.current_day - exile.lifecycle.lost_day
            if days_lost < GameSettings.LONG_LOST_ELIGIBILITY_DAYS:
                continue


            var instance_id: String = "rescue_%d" % exile_id
            if progress.active_opportunities.has(instance_id):
                continue
            result.append({
                "exile": exile, 
                "area_id": area_id, 
                "weight": float(maxi(exile.level, 1)), 
            })
    return result





func _weighted_pick_by_level(pool: Array[Dictionary]) -> Dictionary:
    var total: float = 0.0
    for entry in pool:
        total += float(entry.weight)
    if total <= 0.0:
        return pool[0]
    var roll: float = randf() * total
    var current: float = 0.0
    for entry in pool:
        current += float(entry.weight)
        if roll <= current:
            return entry
    return pool[pool.size() - 1]





func _has_any_active_long_lost_rescue() -> bool:
    for area_enum_value: int in WorldEnum.AREAS.values():
        var area_id: WorldEnum.AREAS = area_enum_value as WorldEnum.AREAS
        var progress: AreaProgress = AreaManager.get_area_progress(area_id)
        if progress == null:
            continue
        for instance_id: String in progress.active_opportunities.keys():
            var instance: OpportunityInstance = _resolve_opportunity_instance(progress, instance_id)
            if instance == null:
                continue
            if String(instance.context.get("origin", "")) == "long_lost":
                return true
    return false






func _on_day_changed(_new_day: int) -> void :



    _cleanup_expired_opportunities()
    _emit_last_day_warnings()
    _emit_boss_cooldown_returns()
    _roll_new_opportunities()






func _emit_last_day_warnings() -> void :
    for area_enum_value: int in WorldEnum.AREAS.values():
        var area_id: WorldEnum.AREAS = area_enum_value as WorldEnum.AREAS
        var progress: AreaProgress = AreaManager.get_area_progress(area_id)
        if not progress:
            continue
        for instance_id: String in progress.active_opportunities.keys():
            var instance: OpportunityInstance = _resolve_opportunity_instance(progress, instance_id)
            if instance == null:
                continue
            var mission: MissionData = get_mission_by_id(instance.template_mission_id)
            if not mission:
                continue
            var timeout: int = instance.get_effective_timeout_days(mission)
            if timeout <= 0:
                continue
            var days_remaining: int = timeout - (GameState.current_day - instance.day_appeared)
            if days_remaining == 1:
                opportunity_last_day.emit(area_id, mission, instance)






func _emit_boss_cooldown_returns() -> void :
    for mission: MissionData in _mission_registry.values():
        if not mission.boss_mission or mission.boss_cooldown_days <= 0:
            continue
        var progress: AreaProgress = AreaManager.get_area_progress(mission.area_requirement)
        if not progress or not progress.boss_defeated:
            continue
        var days_since: int = GameState.current_day - progress.boss_last_completed_day
        if days_since == mission.boss_cooldown_days:
            boss_cooldown_expired.emit(mission.area_requirement, mission)


func _cleanup_expired_opportunities() -> void :
    for area_enum_value: int in WorldEnum.AREAS.values():
        var area_id: WorldEnum.AREAS = area_enum_value as WorldEnum.AREAS
        var progress: AreaProgress = AreaManager.get_area_progress(area_id)
        if not progress:
            continue




        var expired_instances: Array[OpportunityInstance] = []
        for instance_id: String in progress.active_opportunities.keys():
            var instance: OpportunityInstance = _resolve_opportunity_instance(progress, instance_id)
            if instance == null:
                continue
            var mission: MissionData = get_mission_by_id(instance.template_mission_id)
            if not mission:
                continue
            var timeout: int = instance.get_effective_timeout_days(mission)
            if timeout < 0:
                continue
            if GameState.current_day - instance.day_appeared >= timeout:
                expired_instances.append(instance)

        for instance in expired_instances:


            if instance.template_mission_id.begins_with("rescue_captured_"):
                _handle_rescue_expiry(area_id, progress, instance)
            progress.active_opportunities.erase(instance.instance_id)




            opportunity_expired.emit(area_id, instance.instance_id)













func _roll_new_opportunities() -> void :
    for area_enum_value: int in WorldEnum.AREAS.values():
        var area_id: WorldEnum.AREAS = area_enum_value as WorldEnum.AREAS
        var progress: AreaProgress = AreaManager.get_area_progress(area_id)
        if not progress or not progress.unlocked:
            continue
        _roll_one_opportunity_for_area(area_id, progress)


func _roll_one_opportunity_for_area(area_id: WorldEnum.AREAS, progress: AreaProgress) -> void :
    var candidates: Array[MissionData] = []
    for mission: MissionData in _mission_registry.values():
        if mission.area_requirement != area_id:
            continue
        if mission.availability_type != MissionEnums.AVAILABILITY_TYPE.OPPORTUNITY:
            continue
        if mission.opportunity_chance <= 0.0:
            continue
        if not _is_opportunity_eligible(mission, progress):
            continue
        candidates.append(mission)

    if candidates.is_empty():
        return




    candidates.shuffle()
    for mission: MissionData in candidates:
        if randf() <= mission.opportunity_chance:
            var instance: OpportunityInstance = _make_opportunity_instance(mission.mission_id)
            progress.active_opportunities[mission.mission_id] = instance
            opportunity_appeared.emit(area_id, mission)
            return





func _is_opportunity_eligible(mission: MissionData, progress: AreaProgress) -> bool:

    if progress.active_opportunities.has(mission.mission_id):
        return false


    if mission.one_time_only and progress.completed_mission_ids.has(mission.mission_id):
        return false


    if mission.opportunity_cooldown_days > 0:
        var last_day: int = progress.last_opportunity_completion_day.get(mission.mission_id, -1)
        if last_day >= 0 and GameState.current_day - last_day < mission.opportunity_cooldown_days:
            return false


    if not _check_prerequisites(mission):
        return false

    return true






func _load_encounter_registry() -> void :
    var base_path: String = "res://systems/combat/encounters/"
    _scan_encounters_recursive(base_path)
    print("MissionManager: loaded %d encounters into registry" % _encounter_registry.size())


func _scan_encounters_recursive(path: String) -> void :

    var paths: Array[String] = ResourceDirScan.list_tres_files_recursive(path)
    if paths.is_empty() and DirAccess.open(path) == null:
        push_warning("MissionManager: could not open encounter path %s" % path)
        return

    for full_path in paths:
        var resource: Resource = load(full_path)
        if resource is EncounterData:
            _encounter_registry.append(resource)











func get_encounters_for_area(area_id: WorldEnum.AREAS) -> Array[EncounterData]:
    var result: Array[EncounterData] = []
    for encounter: EncounterData in _encounter_registry:
        if encounter.area_tags.has(area_id):
            result.append(encounter)
    return result















func get_mission_monster_pool(mission: MissionData, fallback_area: WorldEnum.AREAS) -> Array[MonsterData]:
    var result: Array[MonsterData] = []
    var seen_ids: Dictionary = {}

    for slot: MissionConundrumsSlot in mission.encounter_slots:
        match slot.slot_type:
            MissionConundrumsSlot.SlotType.MANDATORY_COMBAT:
                if slot.encounter:
                    _collect_monsters_from_encounter(slot.encounter, result, seen_ids)
            MissionConundrumsSlot.SlotType.RANDOM_COMBAT:
                var areas: Array[WorldEnum.AREAS] = slot.area_filter
                if areas.is_empty():
                    areas = [fallback_area]
                var pool: Array[EncounterData] = _build_encounter_pool(
                    areas, slot.required_tags, slot.excluded_tags, mission.level
                )
                for encounter: EncounterData in pool:
                    _collect_monsters_from_encounter(encounter, result, seen_ids)

            _:
                continue

    return result





func _collect_monsters_from_encounter(
    encounter: EncounterData, 
    out: Array[MonsterData], 
    seen_ids: Dictionary, 
) -> void :
    for spawn: MonsterSpawn in encounter.monster_spawns:
        if spawn == null or spawn.monster == null:
            continue
        var mid: String = spawn.monster.monster_id
        if mid.is_empty() or seen_ids.has(mid):
            continue
        seen_ids[mid] = true
        out.append(spawn.monster)


func resolve_encounter_slot(
    slot: MissionConundrumsSlot, 
    fallback_area: WorldEnum.AREAS, 
    mission_level: int, 
    rng: RandomNumberGenerator
) -> EncounterData:
    match slot.slot_type:
        MissionConundrumsSlot.SlotType.MANDATORY_COMBAT:
            return slot.encounter
        MissionConundrumsSlot.SlotType.RANDOM_COMBAT:
            return _pick_random_encounter(slot, fallback_area, mission_level, rng)
        _:

            push_warning("MissionManager: unhandled slot type %s" % slot.slot_type)
            return null


func _pick_random_encounter(
    slot: MissionConundrumsSlot, 
    fallback_area: WorldEnum.AREAS, 
    mission_level: int, 
    rng: RandomNumberGenerator
) -> EncounterData:
    var areas: Array[WorldEnum.AREAS] = slot.area_filter
    if areas.is_empty():
        areas = [fallback_area]

    var pool: Array[EncounterData] = _build_encounter_pool(
        areas, slot.required_tags, slot.excluded_tags, mission_level
    )
    if pool.is_empty():
        push_warning("MissionManager: no encounters match filters — areas=%s required=%s excluded=%s max_lvl=%d" % [areas, slot.required_tags, slot.excluded_tags, mission_level])
        return null

    return _weighted_encounter_pick(pool, rng)


func _build_encounter_pool(
    areas: Array[WorldEnum.AREAS], 
    required: Array[MissionEnums.ENCOUNTER_TAGS], 
    excluded: Array[MissionEnums.ENCOUNTER_TAGS], 
    max_level: int
) -> Array[EncounterData]:
    var result: Array[EncounterData] = []
    for encounter: EncounterData in _encounter_registry:

        if encounter.encounter_type == EncounterData.EncounterType.BOSS:
            continue



        if encounter.recommended_level > max_level:
            continue
        var area_match: bool = false
        for area: WorldEnum.AREAS in areas:
            if encounter.area_tags.has(area):
                area_match = true
                break
        if not area_match:
            continue

        var missing_required: bool = false
        for tag: MissionEnums.ENCOUNTER_TAGS in required:
            if not encounter.tags.has(tag):
                missing_required = true
                break
        if missing_required:
            continue

        var has_excluded: bool = false
        for tag: MissionEnums.ENCOUNTER_TAGS in excluded:
            if encounter.tags.has(tag):
                has_excluded = true
                break
        if has_excluded:
            continue

        result.append(encounter)
    return result


func _weighted_encounter_pick(pool: Array[EncounterData], rng: RandomNumberGenerator) -> EncounterData:
    var total_weight: float = 0.0
    for encounter: EncounterData in pool:
        total_weight += encounter.selection_weight
    var roll: float = rng.randf() * total_weight
    for encounter: EncounterData in pool:
        roll -= encounter.selection_weight
        if roll <= 0.0:
            return encounter
    return pool.back()
