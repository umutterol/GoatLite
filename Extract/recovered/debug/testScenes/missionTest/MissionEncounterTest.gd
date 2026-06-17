extends Node







const MISSION_PATH: = "res://systems/mission/explore_coast.tres"
const ENCOUNTER_BASE_PATH: = "res://systems/combat/encounters/"
const RANDOM_RESOLUTION_RUNS: = 20




var all_encounters: Array[EncounterData] = []
var pass_count: int = 0
var fail_count: int = 0
var warn_count: int = 0


func _ready() -> void :
    print("\n========== MISSION / ENCOUNTER / MONSTER TEST ==========\n")

    _load_encounter_pool()
    _test_mission_loads()
    _test_encounter_data_integrity()
    _test_slot_resolution()
    _test_monster_spawn_integrity()

    print("\n========== RESULTS: %d passed, %d failed, %d warnings ==========" % [
        pass_count, fail_count, warn_count
    ])






func _load_encounter_pool() -> void :
    print("[SETUP] Loading encounter pool from: %s" % ENCOUNTER_BASE_PATH)
    var files: Array[String] = []
    _scan_directory_recursive(ENCOUNTER_BASE_PATH, files)

    for file_path in files:
        if not file_path.ends_with(".tres"):
            continue
        var resource = load(file_path)
        if resource is EncounterData:
            all_encounters.append(resource)

    print("[SETUP] Loaded %d encounters\n" % all_encounters.size())

    if all_encounters.is_empty():
        _fail("Encounter pool is empty — no .tres files found or none are EncounterData")




func _test_mission_loads() -> void :
    print("--- TEST 1: Mission Loading ---")

    var mission: = load(MISSION_PATH) as MissionData
    if not mission:
        _fail("Could not load mission at: %s" % MISSION_PATH)
        return

    _pass("Mission loaded: '%s' (id: %s)" % [mission.display_name, mission.mission_id])

    if mission.mission_id == "":
        _fail("Mission has empty mission_id")

    if mission.encounter_slots.is_empty():
        _fail("Mission has zero encounter_slots")
    else:
        _pass("Mission has %d encounter slot(s)" % mission.encounter_slots.size())


    for i in range(mission.encounter_slots.size()):
        var slot: MissionConundrumsSlot = mission.encounter_slots[i]
        var type_name: String = MissionConundrumsSlot.SlotType.keys()[slot.slot_type]
        var detail: = ""

        match slot.slot_type:
            MissionConundrumsSlot.SlotType.MANDATORY_COMBAT:
                if slot.encounter:
                    detail = " → %s" % slot.encounter.display_name
                else:
                    _fail("Slot %d is MANDATORY_COMBAT but has no encounter assigned" % i)
            MissionConundrumsSlot.SlotType.RANDOM_COMBAT:
                detail = " | area_filter: %s, required_tags: %s, excluded_tags: %s" % [
                    str(slot.area_filter), str(slot.required_tags), str(slot.excluded_tags)
                ]

        print("  Slot %d: %s%s" % [i, type_name, detail])

    print("")




func _test_encounter_data_integrity() -> void :
    print("--- TEST 2: Encounter Data Integrity ---")

    for encounter in all_encounters:
        var label: = "'%s' (%s)" % [encounter.display_name, encounter.encounter_id]

        if encounter.encounter_id == "":
            _fail("Encounter with display_name '%s' has empty encounter_id" % encounter.display_name)

        if encounter.area_tags.is_empty():
            _warn("%s has no area_tags — won't match any area filter" % label)

        if encounter.monster_spawns.is_empty():
            _warn("%s has ZERO monster_spawns — encounter would spawn nothing" % label)
        else:
            var total_monsters: = 0
            for spawn in encounter.monster_spawns:
                total_monsters += spawn.count
            _pass("%s → %d spawn group(s), %d total monsters" % [
                label, encounter.monster_spawns.size(), total_monsters
            ])

    print("")




func _test_slot_resolution() -> void :
    print("--- TEST 3: Random Slot Resolution (%d runs) ---" % RANDOM_RESOLUTION_RUNS)

    var mission: = load(MISSION_PATH) as MissionData
    if not mission:
        _fail("Cannot run slot resolution — mission failed to load")
        return

    for i in range(mission.encounter_slots.size()):
        var slot: MissionConundrumsSlot = mission.encounter_slots[i]

        if slot.slot_type != MissionConundrumsSlot.SlotType.RANDOM_COMBAT:
            print("  Slot %d: Skipping (not RANDOM_COMBAT)" % i)
            continue


        var filtered: = _filter_encounters(slot)

        if filtered.is_empty():
            _fail("Slot %d: RANDOM_COMBAT returned ZERO valid encounters after filtering" % i)
            continue

        _pass("Slot %d: %d encounter(s) match filters" % [i, filtered.size()])


        var selection_counts: Dictionary = {}
        for _run in range(RANDOM_RESOLUTION_RUNS):
            var picked: = _weighted_pick(filtered)
            if picked:
                selection_counts[picked.encounter_id] = selection_counts.get(picked.encounter_id, 0) + 1

        print("  Distribution over %d rolls:" % RANDOM_RESOLUTION_RUNS)
        for encounter_id in selection_counts:
            var count: int = selection_counts[encounter_id]
            var percent: = (float(count) / RANDOM_RESOLUTION_RUNS) * 100.0
            print("    %s: %d (%.0f%%)" % [encounter_id, count, percent])


        if filtered.size() > 1 and selection_counts.size() == 1:
            _warn("Slot %d: Only 1 unique encounter selected across %d runs — weights may be skewed" % [
                i, RANDOM_RESOLUTION_RUNS
            ])
        elif selection_counts.size() > 1:
            _pass("Slot %d: Multiple distinct encounters selected — variety confirmed" % i)

    print("")




func _test_monster_spawn_integrity() -> void :
    print("--- TEST 4: Monster Spawn Integrity ---")

    for encounter in all_encounters:
        for spawn_index in range(encounter.monster_spawns.size()):
            var spawn: MonsterSpawn = encounter.monster_spawns[spawn_index]
            var label: = "%s spawn[%d]" % [encounter.encounter_id, spawn_index]

            if not spawn.monster:
                _fail("%s: MonsterData is null" % label)
                continue

            if spawn.monster.monster_id == "":
                _fail("%s: MonsterData has empty monster_id" % label)

            if spawn.count < 1:
                _fail("%s: count is %d (should be >= 1)" % [label, spawn.count])

            if not spawn.monster.base_stats:
                _fail("%s: monster '%s' has null base_stats" % [label, spawn.monster.monster_id])
            else:
                var stats: ExileStats = spawn.monster.base_stats
                if stats.life <= 0.0:
                    _warn("%s: monster '%s' has %.1f life" % [label, spawn.monster.monster_id, stats.life])

            if not spawn.monster.combat_behavior:
                _warn("%s: monster '%s' has no combat_behavior" % [label, spawn.monster.monster_id])

            _pass("%s: %dx %s (position: %s)" % [
                label, 
                spawn.count, 
                spawn.monster.display_name, 
                MonsterSpawn.PositionHint.keys()[spawn.position_hint]
            ])

    print("")




func _filter_encounters(slot: MissionConundrumsSlot) -> Array[EncounterData]:
    var result: Array[EncounterData] = []

    for encounter in all_encounters:

        if not slot.area_filter.is_empty():
            var area_match: = false
            for area in slot.area_filter:
                if area in encounter.area_tags:
                    area_match = true
                    break
            if not area_match:
                continue


        if not slot.required_tags.is_empty():
            var has_all: = true
            for tag in slot.required_tags:
                if tag not in encounter.tags:
                    has_all = false
                    break
            if not has_all:
                continue


        var has_excluded: = false
        for tag in slot.excluded_tags:
            if tag in encounter.tags:
                has_excluded = true
                break
        if has_excluded:
            continue

        result.append(encounter)

    return result


func _weighted_pick(pool: Array[EncounterData]) -> EncounterData:
    if pool.is_empty():
        return null

    var total_weight: = 0.0
    for encounter in pool:
        total_weight += encounter.selection_weight

    var roll: = randf() * total_weight
    var current: = 0.0

    for encounter in pool:
        current += encounter.selection_weight
        if roll <= current:
            return encounter

    return pool[-1]




func _pass(message: String) -> void :
    pass_count += 1
    print("  ✓ %s" % message)


func _fail(message: String) -> void :
    fail_count += 1
    print("  ✗ FAIL: %s" % message)


func _warn(message: String) -> void :
    warn_count += 1
    print("  ⚠ WARN: %s" % message)


func _scan_directory_recursive(path: String, file_list: Array[String]) -> void :
    var dir: = DirAccess.open(path)
    if not dir:
        return

    dir.list_dir_begin()
    var file_name: = dir.get_next()

    while file_name != "":
        var full_path: = path + file_name
        if dir.current_is_dir() and file_name != "." and file_name != "..":
            _scan_directory_recursive(full_path + "/", file_list)
        else:
            file_list.append(full_path)
        file_name = dir.get_next()
