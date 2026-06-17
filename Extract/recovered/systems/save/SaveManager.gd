extends Node


























const SAVES_DIR: String = "user://saves"
const SAVE_EXTENSION: String = ".res"




const AUTOSAVE_SLOT: int = 0
const MANUAL_SLOT_DEFAULT: int = 1





const SAFE_SAVE_SCENES: Array[String] = [
    "res://gameUI/guild/GuildScene.tscn", 


]




signal save_started(slot: int)
signal save_completed(slot: int)
signal save_failed(slot: int, reason: String)
signal load_started(slot: int)
signal load_completed(slot: int)
signal load_failed(slot: int, reason: String)




func _ready() -> void :






    GameState.end_of_day_completed.connect(_on_end_of_day_autosave)


func _on_end_of_day_autosave(new_day: int) -> void :
    var label: String = "Day %d autosave" % new_day
    save_to_slot(AUTOSAVE_SLOT, label, true)











func save_to_slot(slot: int, save_label: String = "", bypass_scene_check: bool = false) -> bool:
    return save_to_path(_slot_path(slot), slot, save_label, bypass_scene_check)




func load_from_slot(slot: int) -> bool:
    return load_from_path(_slot_path(slot), slot)



func slot_exists(slot: int) -> bool:
    return FileAccess.file_exists(_slot_path(slot))








func most_recent_slot() -> int:
    var candidates: Array[int] = []
    if slot_exists(MANUAL_SLOT_DEFAULT):
        candidates.append(MANUAL_SLOT_DEFAULT)
    if slot_exists(AUTOSAVE_SLOT):
        candidates.append(AUTOSAVE_SLOT)
    if candidates.is_empty():
        return -1
    if candidates.size() == 1:
        return candidates[0]




    var best_slot: int = candidates[0]
    var best_time: int = FileAccess.get_modified_time(_slot_path(best_slot))
    for slot in candidates.slice(1):
        var slot_time: int = FileAccess.get_modified_time(_slot_path(slot))
        if slot_time > best_time:
            best_time = slot_time
            best_slot = slot
    return best_slot




func delete_slot(slot: int) -> bool:
    var path: String = _slot_path(slot)
    if not FileAccess.file_exists(path):
        return true
    var err: int = DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    if err != OK:


        var dir: DirAccess = DirAccess.open(SAVES_DIR)
        if dir == null:
            push_error("SaveManager.delete_slot: cannot open saves dir")
            return false
        err = dir.remove(_slot_filename(slot))
    return err == OK






func save_to_path(path: String, slot: int = -1, save_label: String = "", bypass_scene_check: bool = false) -> bool:
    save_started.emit(slot)

    if not bypass_scene_check and not can_save_now():
        var reason: String = "Cannot save outside of the guild scene"
        save_failed.emit(slot, reason)
        return false

    _ensure_saves_dir()

    var save_data: GameSaveData = _build_save_data(save_label)
    var err: int = ResourceSaver.save(save_data, path)
    if err != OK:
        var reason: String = "ResourceSaver.save returned error %d" % err
        push_error("SaveManager.save_to_path: " + reason)
        save_failed.emit(slot, reason)
        return false

    save_completed.emit(slot)
    return true



func load_from_path(path: String, slot: int = -1) -> bool:
    load_started.emit(slot)

    if not FileAccess.file_exists(path):
        var reason: String = "Save file not found: " + path
        load_failed.emit(slot, reason)
        return false









    var resource: Resource = ResourceLoader.load(
        path, "", ResourceLoader.CACHE_MODE_REPLACE
    )
    if resource == null:
        var reason: String = "ResourceLoader returned null for " + path
        load_failed.emit(slot, reason)
        return false
    if not (resource is GameSaveData):
        var reason: String = "Save file at %s is not a GameSaveData (got %s)" % [path, resource.get_class()]
        load_failed.emit(slot, reason)
        return false

    var save_data: GameSaveData = resource as GameSaveData
    save_data = SaveMigrator.migrate(save_data)
    if save_data == null:
        load_failed.emit(slot, "Migration failed")
        return false

    _apply_save_data(save_data)
    load_completed.emit(slot)
    return true






func can_save_now() -> bool:



    var tree: SceneTree = get_tree()
    if tree == null or tree.current_scene == null:
        return true
    var scene_path: String = tree.current_scene.scene_file_path
    if scene_path.is_empty():

        return true
    return SAFE_SAVE_SCENES.has(scene_path)





func get_slot_bytes(slot: int) -> PackedByteArray:
    var path: String = _slot_path(slot)
    if not FileAccess.file_exists(path):
        return PackedByteArray()
    return FileAccess.get_file_as_bytes(path)




func import_bytes_into_slot(bytes: PackedByteArray, slot: int) -> bool:
    _ensure_saves_dir()
    var path: String = _slot_path(slot)
    var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        push_error("SaveManager.import_bytes_into_slot: cannot open %s for write" % path)
        return false
    file.store_buffer(bytes)
    file.close()
    return load_from_slot(slot)




func _build_save_data(save_label: String) -> GameSaveData:
    var save_data: = GameSaveData.new()
    save_data.save_version = GameSaveData.CURRENT_VERSION
    save_data.saved_at_iso = Time.get_datetime_string_from_system(false, true)
    save_data.save_label = save_label
    save_data.snapshot = _capture_game_state()
    save_data.area_progress = _capture_area_progress()
    return save_data


func _capture_game_state() -> GameStateSnapshot:
    var snap: = GameStateSnapshot.new()
    snap.current_day = GameState.current_day
    snap.current_turn = GameState.current_turn
    snap.chaos = GameState.chaos
    snap.food = GameState.food
    snap.scrap = GameState.scrap
    snap.exalt = GameState.exalt
    snap.next_exile_id = GameState.next_exile_id



    var roster: Array[ExileData] = []
    for exile in GameState.exiles.values():
        roster.append(exile)
    snap.exiles = roster


    snap.guild_stash = GameState.guild_stash.duplicate()
    snap.stash_tab_names = GameState.stash_tab_names.duplicate()
    snap.current_recruits = GameState.current_recruits.duplicate()


    snap.next_event_recruit_day = GameState.next_event_recruit_day
    snap.current_party_ids = GameState.current_party_ids.duplicate()
    snap.selected_mission_board_area = GameState.selected_mission_board_area


    snap.core_exile_ids = GameState.core_exile_ids.duplicate()
    snap.backbench_exile_ids = GameState.backbench_exile_ids.duplicate()



    snap.party_auto_dropped_recovering = GameState._party_auto_dropped_recovering.duplicate()
    return snap


func _capture_area_progress() -> Dictionary:




    if AreaManager == null:
        return {}
    return AreaManager.area_progress.duplicate()




func _apply_save_data(save_data: GameSaveData) -> void :
    _apply_game_state(save_data.snapshot)
    _apply_area_progress(save_data.area_progress)
    _post_load_fixup()



    GameState.game_loaded.emit()


func _apply_game_state(snap: GameStateSnapshot) -> void :
    if snap == null:
        push_error("SaveManager._apply_game_state: null snapshot")
        return

    GameState.current_day = snap.current_day
    GameState.current_turn = snap.current_turn
    GameState.chaos = snap.chaos
    GameState.food = snap.food
    GameState.scrap = snap.scrap
    GameState.exalt = snap.exalt
    GameState.next_exile_id = snap.next_exile_id


    GameState.exiles.clear()
    for exile in snap.exiles:
        if exile == null or exile.id < 0:
            push_warning("SaveManager: skipping invalid exile in save")
            continue
        GameState.exiles[exile.id] = exile


    GameState.guild_stash = snap.guild_stash.duplicate()
    GameState.stash_tab_names = snap.stash_tab_names.duplicate()
    GameState.current_recruits = snap.current_recruits.duplicate()



    GameState.next_event_recruit_day = snap.next_event_recruit_day
    GameState.current_party_ids = snap.current_party_ids.duplicate()
    GameState._party_auto_dropped_recovering = snap.party_auto_dropped_recovering.duplicate()
    GameState.selected_mission_board_area = snap.selected_mission_board_area


    GameState.core_exile_ids = snap.core_exile_ids.duplicate()
    GameState.backbench_exile_ids = snap.backbench_exile_ids.duplicate()




    GameState.resource_changed.emit("chaos", GameState.chaos, GameState.chaos)
    GameState.resource_changed.emit("food", GameState.food, GameState.food)
    GameState.resource_changed.emit("scrap", GameState.scrap, GameState.scrap)
    GameState.resource_changed.emit("exalt", GameState.exalt, GameState.exalt)
    GameState.stash_changed.emit()
    GameState.party_changed.emit()


func _apply_area_progress(progress_dict: Dictionary) -> void :
    if AreaManager == null:
        push_warning("SaveManager: AreaManager not available; skipping area progress restore")
        return
    AreaManager.restore_area_progress(progress_dict)










func _post_load_fixup() -> void :
    for exile in GameState.exiles.values():
        ExileGenerator.restore_exile_from_save(exile)
        ExileGenerator.recalculate_stats(exile)
    _prune_dismissed_exiles()
    _migrate_seats_if_legacy()







func _prune_dismissed_exiles() -> void :
    var to_remove: Array[int] = []
    for exile in GameState.exiles.values():
        if exile and exile.status == "dismissed":
            to_remove.append(exile.id)
    for id in to_remove:


        GameState.remove_exile(id)







func _migrate_seats_if_legacy() -> void :
    GameState._ensure_seats_sized()




    for id in GameState.core_exile_ids:
        if id != -1:
            return
    for id in GameState.backbench_exile_ids:
        if id != -1:
            return




    var ids: Array = []
    for exile in GameState.exiles.values():
        if exile and exile.status != "dead":
            ids.append(exile.id)
    ids.sort()
    for exile_id in ids:
        GameState._assign_exile_to_first_open_seat(exile_id)




func _slot_filename(slot: int) -> String:
    return "slot_%d%s" % [slot, SAVE_EXTENSION]


func _slot_path(slot: int) -> String:
    return "%s/%s" % [SAVES_DIR, _slot_filename(slot)]


func _ensure_saves_dir() -> void :
    if DirAccess.dir_exists_absolute(SAVES_DIR):
        return
    var err: int = DirAccess.make_dir_recursive_absolute(SAVES_DIR)
    if err != OK:
        push_error("SaveManager: failed to create saves dir (error %d)" % err)
