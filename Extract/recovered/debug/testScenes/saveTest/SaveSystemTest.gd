extends Node

















const TEST_SLOT: int = 99


var _initial_day: int = 0
var _initial_chaos: int = 0
var _initial_food: int = 0
var _initial_scrap: int = 0
var _initial_exile_count: int = 0
var _initial_exile_ids: Array[int] = []
var _initial_stash_count: int = 0
var _initial_party_ids: Array[int] = []
var _initial_unlocked_areas: Array = []


const _RESCUE_TEST_INSTANCE_ID: String = "__savetest_rescue_instance__"
const _RESCUE_TEST_AREA: WorldEnum.AREAS = WorldEnum.AREAS.COAST
const _RESCUE_TEST_DAY_APPEARED: int = 5
const _RESCUE_TEST_LOST_DAY: int = 3


const _RESCUE_TEST_RUNTIME_LEVEL: int = 17


var _passes: int = 0
var _fails: int = 0


func _ready() -> void :
    print("\n========== SAVE SYSTEM TEST ==========")
    print("Test slot: %d (user://saves/slot_%d.res)\n" % [TEST_SLOT, TEST_SLOT])



    await get_tree().process_frame

    _seed_test_state()
    _capture_initial()


    if not _step_save():
        _finish()
        return



    _mutate_live_state()





    _debug_list_saves_dir()

    if not _step_load():
        _finish()
        return

    _compare_state()
    _finish()







func _seed_test_state() -> void :

    GameState.current_day = 7
    GameState.chaos = 123
    GameState.food = 45
    GameState.scrap = 9




    if GameState.exiles.is_empty():
        var exile: ExileData = ExileGenerator.create_exile()
        if exile != null:
            GameState.add_exile(exile)
            GameState.add_to_party(exile.id)





    var coast_progress: AreaProgress = AreaManager.get_area_progress(_RESCUE_TEST_AREA)
    if coast_progress != null:
        var instance: = OpportunityInstance.new()
        instance.instance_id = _RESCUE_TEST_INSTANCE_ID
        instance.template_mission_id = _RESCUE_TEST_INSTANCE_ID
        instance.day_appeared = _RESCUE_TEST_DAY_APPEARED



        var runtime: = MissionData.new()
        runtime.mission_id = "__savetest_runtime__"
        runtime.level = _RESCUE_TEST_RUNTIME_LEVEL
        instance.runtime_mission_data = runtime
        coast_progress.active_opportunities[_RESCUE_TEST_INSTANCE_ID] = instance
    if not GameState.exiles.is_empty():
        var first_exile: ExileData = GameState.exiles.values()[0]
        if first_exile.lifecycle == null:
            first_exile.lifecycle = ExileLifecycleState.new()
        first_exile.lifecycle.lost_day = _RESCUE_TEST_LOST_DAY

    print("[SETUP] day=%d chaos=%d food=%d scrap=%d exiles=%d stash=%d" % [
        GameState.current_day, GameState.chaos, GameState.food, GameState.scrap, 
        GameState.exiles.size(), GameState.guild_stash.size()
    ])


func _capture_initial() -> void :
    _initial_day = GameState.current_day
    _initial_chaos = GameState.chaos
    _initial_food = GameState.food
    _initial_scrap = GameState.scrap
    _initial_exile_count = GameState.exiles.size()


    _initial_exile_ids = _to_int_array(GameState.exiles.keys())
    _initial_exile_ids.sort()
    _initial_stash_count = GameState.guild_stash.size()
    _initial_party_ids = GameState.current_party_ids.duplicate()
    _initial_party_ids.sort()
    _initial_unlocked_areas = AreaManager.get_unlocked_area_ids()
    print("[CAPTURE] initial state recorded\n")





func _to_int_array(source: Array) -> Array[int]:
    var out: Array[int] = []
    for value in source:
        out.append(int(value))
    return out


func _debug_list_saves_dir() -> void :
    const SAVES_DIR: = "user://saves"
    print("[DEBUG] listing %s :" % SAVES_DIR)
    var dir: DirAccess = DirAccess.open(SAVES_DIR)
    if dir == null:
        print("  (directory does not exist or could not be opened)")
        return
    dir.list_dir_begin()
    var file_name: String = dir.get_next()
    var any: bool = false
    while file_name != "":
        if not file_name.begins_with("."):
            any = true
            var full_path: String = SAVES_DIR + "/" + file_name
            var size: int = FileAccess.get_file_as_bytes(full_path).size()
            print("  - %s (%d bytes)" % [file_name, size])
        file_name = dir.get_next()
    if not any:
        print("  (empty)")


    print("  (user:// absolute = %s)" % ProjectSettings.globalize_path(SAVES_DIR))
    print()




func _step_save() -> bool:
    print("[STEP] Saving to slot %d..." % TEST_SLOT)



    var ok: bool = SaveManager.save_to_slot(TEST_SLOT, "smoke test", true)
    if not ok:
        _record(false, "save_to_slot returned false")
        return false
    if not SaveManager.slot_exists(TEST_SLOT):
        _record(false, "slot_exists returned false after save")
        return false
    _record(true, "save wrote file to disk")
    return true





func _mutate_live_state() -> void :
    GameState.current_day = 999
    GameState.chaos = 0
    GameState.food = 0
    GameState.scrap = 0
    GameState.exiles.clear()
    GameState.guild_stash.clear()
    GameState.current_party_ids.clear()



    for key in AreaManager.area_progress.keys():
        var progress: AreaProgress = AreaManager.area_progress[key]
        if progress != null:
            progress.unlocked = false
            progress.active_opportunities.clear()
    print("[MUTATE] live state trashed (day=999, no exiles, no stash, all areas locked)\n")


func _step_load() -> bool:
    print("[STEP] Loading from slot %d..." % TEST_SLOT)
    var ok: bool = SaveManager.load_from_slot(TEST_SLOT)
    if not ok:
        _record(false, "load_from_slot returned false")
        return false
    _record(true, "load returned success")
    return true




func _compare_state() -> void :
    print("\n[COMPARE] post-load vs initial")
    _check_eq("current_day", _initial_day, GameState.current_day)
    _check_eq("chaos", _initial_chaos, GameState.chaos)
    _check_eq("food", _initial_food, GameState.food)
    _check_eq("scrap", _initial_scrap, GameState.scrap)
    _check_eq("exile count", _initial_exile_count, GameState.exiles.size())

    var post_ids: Array[int] = _to_int_array(GameState.exiles.keys())
    post_ids.sort()
    _check_eq("exile ids", _initial_exile_ids, post_ids)

    _check_eq("stash count", _initial_stash_count, GameState.guild_stash.size())

    var post_party: Array = GameState.current_party_ids.duplicate()
    post_party.sort()
    _check_eq("party ids", _initial_party_ids, post_party)

    _check_eq("unlocked area count", _initial_unlocked_areas.size(), AreaManager.get_unlocked_area_ids().size())





    for exile in GameState.exiles.values():
        _check_truthy("exile %s class_definition" % exile.name, exile.class_definition != null)
        _check_truthy("exile %s current_stats" % exile.name, exile.current_stats != null)

        _check_truthy("exile %s lifecycle non-null" % exile.name, exile.lifecycle != null)


    var coast_progress: AreaProgress = AreaManager.get_area_progress(_RESCUE_TEST_AREA)
    _check_truthy(
        "coast active_opportunities has %s" % _RESCUE_TEST_INSTANCE_ID, 
        coast_progress != null and coast_progress.active_opportunities.has(_RESCUE_TEST_INSTANCE_ID)
    )
    if coast_progress != null and coast_progress.active_opportunities.has(_RESCUE_TEST_INSTANCE_ID):
        var loaded_instance: OpportunityInstance = coast_progress.active_opportunities[_RESCUE_TEST_INSTANCE_ID]
        _check_truthy("OpportunityInstance is OpportunityInstance", loaded_instance is OpportunityInstance)
        if loaded_instance != null:
            _check_eq("OpportunityInstance.day_appeared", _RESCUE_TEST_DAY_APPEARED, loaded_instance.day_appeared)
            _check_eq("OpportunityInstance.instance_id", _RESCUE_TEST_INSTANCE_ID, loaded_instance.instance_id)



            _check_truthy("OpportunityInstance.runtime_mission_data non-null", loaded_instance.runtime_mission_data != null)
            if loaded_instance.runtime_mission_data != null:
                _check_eq(
                    "runtime_mission_data.level", 
                    _RESCUE_TEST_RUNTIME_LEVEL, 
                    loaded_instance.runtime_mission_data.level
                )

    if not GameState.exiles.is_empty():
        var first_exile: ExileData = GameState.exiles.values()[0]
        if first_exile.lifecycle != null:
            _check_eq("first exile lifecycle.lost_day", _RESCUE_TEST_LOST_DAY, first_exile.lifecycle.lost_day)


func _check_eq(label: String, expected, actual) -> void :
    if expected == actual:
        _record(true, "%s: %s" % [label, str(actual)])
    else:
        _record(false, "%s: expected %s, got %s" % [label, str(expected), str(actual)])


func _check_truthy(label: String, condition: bool) -> void :
    _record(condition, label)


func _record(ok: bool, msg: String) -> void :
    if ok:
        _passes += 1
        print("  PASS  " + msg)
    else:
        _fails += 1
        print("  FAIL  " + msg)


func _finish() -> void :
    print("\n========== RESULT: %d passed, %d failed ==========\n" % [_passes, _fails])
