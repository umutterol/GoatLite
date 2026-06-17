extends Node




signal area_unlocked(area_id: WorldEnum.AREAS)
signal scouting_updated(area_id: WorldEnum.AREAS, new_percent: float)
signal discovery_made(area_id: WorldEnum.AREAS, mission: MissionData)
signal area_connection_found(from_area: WorldEnum.AREAS, to_area: WorldEnum.AREAS)


var area_data_list: Array[AreaData] = [
    preload("res://systems/world/areas/coast.tres"), 
    preload("res://systems/world/areas/mud_flats.tres"), 
]



var area_progress: Dictionary = {}


var _area_data_lookup: Dictionary = {}


func _ready() -> void :
    _build_lookup()
    _initialize_progress()


func _build_lookup() -> void :
    for data: AreaData in area_data_list:
        _area_data_lookup[data.area_id] = data


func _initialize_progress() -> void :
    for data: AreaData in area_data_list:
        var progress: = AreaProgress.new()
        progress.area_id = data.area_id
        progress.unlocked = data.starts_unlocked
        area_progress[data.area_id] = progress










func restore_area_progress(saved_progress: Dictionary) -> void :
    area_progress.clear()

    for data: AreaData in area_data_list:
        if saved_progress.has(data.area_id):
            var loaded: AreaProgress = saved_progress[data.area_id]
            if loaded == null:
                push_warning("AreaManager.restore_area_progress: null progress for area %s, using defaults" % data.area_id)
                _init_single_area(data)
                continue

            loaded.area_id = data.area_id
            area_progress[data.area_id] = loaded
        else:

            _init_single_area(data)


func _init_single_area(data: AreaData) -> void :
    var progress: = AreaProgress.new()
    progress.area_id = data.area_id
    progress.unlocked = data.starts_unlocked
    area_progress[data.area_id] = progress






func reset_for_new_game() -> void :
    area_progress.clear()
    _initialize_progress()




func is_area_unlocked(area_id: WorldEnum.AREAS) -> bool:
    if not area_progress.has(area_id):
        return false
    var progress: AreaProgress = area_progress[area_id]
    return progress.unlocked


func get_scouting_percent(area_id: WorldEnum.AREAS) -> float:
    if not area_progress.has(area_id):
        return 0.0
    var progress: AreaProgress = area_progress[area_id]
    var data: AreaData = _area_data_lookup[area_id]
    if data.max_scouting_progress <= 0.0:
        return 100.0
    return (progress.scouting_progress / data.max_scouting_progress) * 100.0


func get_area_progress(area_id: WorldEnum.AREAS) -> AreaProgress:
    return area_progress.get(area_id)


func get_area_data(area_id: WorldEnum.AREAS) -> AreaData:
    return _area_data_lookup.get(area_id)




func get_unlocked_area_ids() -> Array[WorldEnum.AREAS]:
    var result: Array[WorldEnum.AREAS] = []
    for data: AreaData in area_data_list:
        if is_area_unlocked(data.area_id):
            result.append(data.area_id)
    return result








func mark_monsters_seen(area_id: WorldEnum.AREAS, monster_ids: Array[String]) -> void :
    var progress: AreaProgress = area_progress.get(area_id)
    if not progress:
        return
    for monster_id: String in monster_ids:
        if monster_id.is_empty():
            continue
        if not progress.seen_monster_ids.has(monster_id):
            progress.seen_monster_ids.append(monster_id)


func is_monster_seen(area_id: WorldEnum.AREAS, monster_id: String) -> bool:
    var progress: AreaProgress = area_progress.get(area_id)
    if not progress:
        return false
    return progress.seen_monster_ids.has(monster_id)







func record_mission_completion(
    area_id: WorldEnum.AREAS, 
    mission: MissionData, 
    completion_percent: float, 
    party_scouting_bonus: float, 
    succeeded: bool
) -> float:
    var progress: AreaProgress = area_progress.get(area_id)
    if not progress:
        push_error("AreaManager: No progress found for area %s" % area_id)
        return 0.0





    if succeeded:
        _record_completion_stats(progress, mission)
        if mission.boss_mission:
            progress.boss_defeated = true
            progress.boss_last_completed_day = GameState.current_day




    var scouting_gain: float = mission.scouting_reward * completion_percent * (1.0 + party_scouting_bonus)
    var applied: float = _add_scouting_progress(area_id, progress, scouting_gain)

    _check_discoveries(area_id, party_scouting_bonus)
    _check_area_connections(area_id, mission)





    MissionManager.try_roll_long_lost_rescue(scouting_gain)

    return applied


func _record_completion_stats(progress: AreaProgress, mission: MissionData) -> void :
    if not progress.completed_mission_ids.has(mission.mission_id):
        progress.completed_mission_ids.append(mission.mission_id)
    progress.total_missions_completed += 1

    for tag: MissionEnums.MISSION_TAGS in mission.mission_tags:
        var current_count: int = progress.tag_completion_counts.get(tag, 0)
        progress.tag_completion_counts[tag] = current_count + 1



    if mission.availability_type == MissionEnums.AVAILABILITY_TYPE.OPPORTUNITY:
        progress.last_opportunity_completion_day[mission.mission_id] = GameState.current_day





func _add_scouting_progress(
    area_id: WorldEnum.AREAS, 
    progress: AreaProgress, 
    amount: float
) -> float:
    if amount <= 0.0:
        return 0.0
    var data: AreaData = _area_data_lookup[area_id]
    var before: float = progress.scouting_progress
    progress.scouting_progress = minf(progress.scouting_progress + amount, data.max_scouting_progress)
    scouting_updated.emit(area_id, get_scouting_percent(area_id))
    return progress.scouting_progress - before










func _check_discoveries(area_id: WorldEnum.AREAS, party_scouting_bonus: float) -> void :
    var progress: AreaProgress = area_progress[area_id]
    var scouting_percent: float = get_scouting_percent(area_id)

    for mission: MissionData in MissionManager.get_discoverable_missions_in_area(area_id):

        if progress.discovered_mission_ids.has(mission.mission_id):
            continue





        if not MissionManager.is_mission_unlockable(mission, progress):
            continue


        if scouting_percent < mission.scouting_threshold_percent:
            continue


        var modified_chance: float = mission.discovery_base_chance * (1.0 + party_scouting_bonus)
        if randf() <= modified_chance:
            progress.discovered_mission_ids.append(mission.mission_id)
            discovery_made.emit(area_id, mission)




func _check_area_connections(area_id: WorldEnum.AREAS, mission: MissionData) -> void :
    var data: AreaData = _area_data_lookup[area_id]
    var progress: AreaProgress = area_progress[area_id]

    for connection: AreaConnection in data.connections:

        if is_area_unlocked(connection.target_area):
            continue


        if not _mission_triggers_connection(mission, connection):
            continue


        if not _check_requirements(connection.requirements, progress):
            continue


        if connection.discovery_chance <= 0.0:
            _unlock_area(connection.target_area, area_id)
        else:
            var modified_chance: float = connection.discovery_chance
            if connection.scouting_modifies_chance:
                var scouting_percent: float = get_scouting_percent(area_id)
                modified_chance *= (1.0 + scouting_percent / 100.0)
            if randf() <= modified_chance:
                _unlock_area(connection.target_area, area_id)


func _mission_triggers_connection(mission: MissionData, connection: AreaConnection) -> bool:

    if connection.trigger_mission_id.is_empty() and connection.trigger_mission_tags.is_empty():
        return true


    if not connection.trigger_mission_id.is_empty():
        return mission.mission_id == connection.trigger_mission_id


    for tag: MissionEnums.MISSION_TAGS in connection.trigger_mission_tags:
        if mission.mission_tags.has(tag):
            return true

    return false


func _check_requirements(requirements: Array[ProgressionRequirement], progress: AreaProgress) -> bool:
    for requirement: ProgressionRequirement in requirements:
        if not _check_single_requirement(requirement, progress):
            return false
    return true


func _check_single_requirement(requirement: ProgressionRequirement, progress: AreaProgress) -> bool:

    var target_progress: AreaProgress = progress
    if requirement.area != progress.area_id:
        target_progress = area_progress.get(requirement.area)
        if not target_progress:
            return false

    match requirement.type:
        ProgressionRequirement.TYPE.MISSION_COMPLETED:
            return target_progress.completed_mission_ids.has(requirement.mission_id)

        ProgressionRequirement.TYPE.MISSION_TAG_COUNT:
            var count: int = target_progress.tag_completion_counts.get(requirement.tag, 0)
            return count >= int(requirement.required_value)

        ProgressionRequirement.TYPE.TOTAL_MISSIONS_IN_AREA:
            return target_progress.total_missions_completed >= int(requirement.required_value)

        ProgressionRequirement.TYPE.SCOUTING_PERCENT:
            return get_scouting_percent(target_progress.area_id) >= requirement.required_value

        ProgressionRequirement.TYPE.BOSS_DEFEATED:
            return target_progress.boss_defeated

    return false


func _unlock_area(area_id: WorldEnum.AREAS, from_area: WorldEnum.AREAS) -> void :
    var progress: AreaProgress = area_progress.get(area_id)
    if not progress:
        push_error("AreaManager: Cannot unlock unknown area %s" % area_id)
        return
    progress.unlocked = true
    area_unlocked.emit(area_id)
    area_connection_found.emit(from_area, area_id)
