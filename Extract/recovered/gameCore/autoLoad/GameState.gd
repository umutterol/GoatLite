extends Node



const STASH_CONFIG: StashConfig = preload("res://systems/items/Equipment/stash_config.tres")


var current_day: int = 1
var current_turn: int = 0




var next_event_recruit_day: int = -1





var _wandering_offer_pending: bool = false



var chaos: int = GameSettings.STARTING_CHAOS
var food: int = GameSettings.STARTING_FOOD
var scrap: int = GameSettings.STARTING_SCRAP





var exalt: int = GameSettings.STARTING_EXALT


var exiles: Dictionary = {}
var next_exile_id: int = 1



var max_exiles: int = 13







const CORE_SEAT_COUNT: int = 5
const BACKBENCH_SEAT_COUNT: int = 8
var core_exile_ids: Array[int] = []
var backbench_exile_ids: Array[int] = []
var current_recruits: Array[RecruitData] = []
var guild_stash: Array[Item] = []






var stash_tab_names: Array[String] = []




var current_party_ids: Array[int] = []







var selected_mission_board_area: WorldEnum.AREAS = WorldEnum.AREAS.COAST





const MAX_PARTY_SIZE: int = 5






var _party_auto_dropped_recovering: Array[int] = []





var pending_intro_fade: bool = false


signal turn_advanced(new_turn: int)
signal day_changed(new_day: int)
signal resource_changed(resource_type: String, old_value: int, new_value: int)
signal recruitment_phase_started()




@warning_ignore("unused_signal")
signal event_recruits_offered(recruits: Array[RecruitData], source: String)
signal exile_added(exile_data: ExileData)



@warning_ignore("unused_signal")
signal seats_changed()
@warning_ignore("unused_signal")
signal exile_updated(exile_data: ExileData)
signal exile_removed(exile_id: int)
signal exile_died(exile_id: int)




@warning_ignore("unused_signal")
signal exile_dismissed(exile_data: ExileData)



@warning_ignore("unused_signal")
signal exile_lost(exile_data: ExileData, area_id: WorldEnum.AREAS)
@warning_ignore("unused_signal")
signal exile_long_lost(exile_data: ExileData, area_id: WorldEnum.AREAS)
@warning_ignore("unused_signal")
signal exile_rescued(exile_data: ExileData, origin: String)


@warning_ignore("unused_signal")
signal long_lost_rescue_surfaced(exile_data: ExileData, area_id: WorldEnum.AREAS)



@warning_ignore("unused_signal")
signal level_up_queued(exile_data: ExileData, node: PassiveTreeNode)
@warning_ignore("unused_signal")
signal level_up_growth_resolved(exile_data: ExileData, resolved_levels: Array)
@warning_ignore("unused_signal")
signal potential_discovered(exile_data: ExileData, potential_tag: String)
@warning_ignore("unused_signal")
signal trait_learned(exile_data: ExileData, trait_id: String)




@warning_ignore("unused_signal")
signal scar_assigned(exile_data: ExileData, scar_trait: TraitDefinition)
signal stash_changed()
signal party_changed()




@warning_ignore("unused_signal")
signal game_loaded()





signal end_of_day_completed(new_day: int)

func _ready():
    print("GameState initialized")
    TestItemSeeder.seed_starting_stash()


    resource_changed.connect(_on_resource_changed_for_rations)


    exile_died.connect(_remove_exile_from_seats)



    exile_died.connect(_maybe_offer_wandering_exile)




    seats_changed.connect(_prune_party_of_non_core)

    game_loaded.connect(_on_game_loaded_check_wandering)
    exile_added.connect(_on_exile_added_clear_wandering_flag)


func _on_resource_changed_for_rations(resource_type: String, _old: int, _new: int) -> void :
    if resource_type == "food":
        QuartermasterManager.rebalance_to_fit_food()








func reset_for_new_game() -> void :
    current_day = 1
    current_turn = 0
    next_event_recruit_day = -1
    _wandering_offer_pending = false
    chaos = GameSettings.STARTING_CHAOS
    food = GameSettings.STARTING_FOOD
    scrap = GameSettings.STARTING_SCRAP
    exalt = GameSettings.STARTING_EXALT
    exiles.clear()
    next_exile_id = 1
    core_exile_ids.clear()
    backbench_exile_ids.clear()
    _ensure_seats_sized()
    current_recruits.clear()
    guild_stash.clear()
    stash_tab_names.clear()
    current_party_ids.clear()
    _party_auto_dropped_recovering.clear()
    selected_mission_board_area = WorldEnum.AREAS.COAST
    pending_intro_fade = false


    resource_changed.emit("chaos", chaos, chaos)
    resource_changed.emit("food", food, food)
    resource_changed.emit("scrap", scrap, scrap)
    resource_changed.emit("exalt", exalt, exalt)
    stash_changed.emit()
    party_changed.emit()
    seats_changed.emit()





func add_exile(exile_data: ExileData) -> bool:


    if get_living_exile_count() >= max_exiles:
        push_error("Cannot add exile: roster full")
        return false


    if exile_data.id == -1:
        exile_data.id = next_exile_id
        next_exile_id += 1

    exiles[exile_data.id] = exile_data

    ExileGenerator.recalculate_stats(exile_data)




    _assign_exile_to_first_open_seat(exile_data.id)
    exile_added.emit(exile_data)


    QuartermasterManager.rebalance_to_fit_food()
    return true

func remove_exile(exile_id: int):
    if not exiles.has(exile_id):
        return



    _remove_exile_from_seats(exile_id)
    exiles.erase(exile_id)
    exile_removed.emit(exile_id)

func get_exile_by_id(exile_id: int) -> ExileData:
    return exiles.get(exile_id, null)

func get_all_exile_ids() -> Array:
    return exiles.keys()

func get_all_exiles() -> Array[ExileData]:
    var result: Array[ExileData] = []
    for exile in exiles.values():
        result.append(exile)
    return result







func get_living_exiles() -> Array[ExileData]:
    var result: Array[ExileData] = []
    for exile in exiles.values():
        if exile.status == "dead" or exile.status == "dismissed":
            continue
        result.append(exile)
    return result





func get_living_exile_count() -> int:
    var count: int = 0
    for exile in exiles.values():
        if exile.status == "dead" or exile.status == "dismissed":
            continue
        count += 1
    return count

func get_available_exiles() -> Array[ExileData]:
    var result: Array[ExileData] = []
    for exile in exiles.values():
        if exile.status == "idle":
            result.append(exile)
    return result






















func _ensure_seats_sized() -> void :
    while core_exile_ids.size() < CORE_SEAT_COUNT:
        core_exile_ids.append(-1)
    while backbench_exile_ids.size() < BACKBENCH_SEAT_COUNT:
        backbench_exile_ids.append(-1)
    if core_exile_ids.size() > CORE_SEAT_COUNT:
        var overflow: Array[int] = []
        for i in range(CORE_SEAT_COUNT, core_exile_ids.size()):
            var oid: int = core_exile_ids[i]
            if oid != -1:
                overflow.append(oid)
        core_exile_ids.resize(CORE_SEAT_COUNT)
        for overflow_id in overflow:
            var placed: bool = false
            for i in range(backbench_exile_ids.size()):
                if backbench_exile_ids[i] == -1:
                    backbench_exile_ids[i] = overflow_id
                    placed = true
                    break
            if not placed:
                push_warning(
                    "_ensure_seats_sized: backbench full, dropping exile id %d on core trim"
                    %overflow_id
                )
    if backbench_exile_ids.size() > BACKBENCH_SEAT_COUNT:
        backbench_exile_ids.resize(BACKBENCH_SEAT_COUNT)




func is_in_core(exile_id: int) -> bool:
    _ensure_seats_sized()
    return core_exile_ids.has(exile_id)



func is_in_backbench(exile_id: int) -> bool:
    _ensure_seats_sized()
    return backbench_exile_ids.has(exile_id)




func is_seated(exile_id: int) -> bool:
    return is_in_core(exile_id) or is_in_backbench(exile_id)




func get_core_exiles() -> Array[ExileData]:
    _ensure_seats_sized()
    var result: Array[ExileData] = []
    for exile_id in core_exile_ids:
        if exile_id == -1:
            continue
        var exile: ExileData = exiles.get(exile_id, null)
        if exile and exile.status != "dead":
            result.append(exile)
    return result



func get_backbench_exiles() -> Array[ExileData]:
    _ensure_seats_sized()
    var result: Array[ExileData] = []
    for exile_id in backbench_exile_ids:
        if exile_id == -1:
            continue
        var exile: ExileData = exiles.get(exile_id, null)
        if exile and exile.status != "dead":
            result.append(exile)
    return result






func swap_seats(zone_a: String, idx_a: int, zone_b: String, idx_b: int) -> void :
    _ensure_seats_sized()
    if not _is_valid_zone(zone_a) or not _is_valid_zone(zone_b):
        push_warning("swap_seats: unknown zone (%s / %s)" % [zone_a, zone_b])
        return
    var size_a: int = _zone_size(zone_a)
    var size_b: int = _zone_size(zone_b)
    if idx_a < 0 or idx_a >= size_a:
        return
    if idx_b < 0 or idx_b >= size_b:
        return


    var val_a: int = _read_seat(zone_a, idx_a)
    var val_b: int = _read_seat(zone_b, idx_b)
    _write_seat(zone_a, idx_a, val_b)
    _write_seat(zone_b, idx_b, val_a)
    seats_changed.emit()





func vacate_seat_for_exile(exile_id: int) -> void :
    _remove_exile_from_seats(exile_id)






func swap_seats_by_exile_id(source_exile_id: int, target_zone: String, target_index: int) -> void :
    _ensure_seats_sized()
    var src_zone: String = ""
    var src_index: int = -1
    for i in core_exile_ids.size():
        if core_exile_ids[i] == source_exile_id:
            src_zone = "core"
            src_index = i
            break
    if src_index == -1:
        for i in backbench_exile_ids.size():
            if backbench_exile_ids[i] == source_exile_id:
                src_zone = "backbench"
                src_index = i
                break
    if src_index == -1:
        return
    if src_zone == target_zone and src_index == target_index:
        return
    swap_seats(src_zone, src_index, target_zone, target_index)







func _is_valid_zone(zone: String) -> bool:
    return zone == "core" or zone == "backbench"


func _zone_size(zone: String) -> int:
    if zone == "core":
        return core_exile_ids.size()
    if zone == "backbench":
        return backbench_exile_ids.size()
    return 0


func _read_seat(zone: String, index: int) -> int:
    if zone == "core" and index >= 0 and index < core_exile_ids.size():
        return core_exile_ids[index]
    if zone == "backbench" and index >= 0 and index < backbench_exile_ids.size():
        return backbench_exile_ids[index]
    return -1


func _write_seat(zone: String, index: int, value: int) -> void :
    if zone == "core" and index >= 0 and index < core_exile_ids.size():
        core_exile_ids[index] = value
    elif zone == "backbench" and index >= 0 and index < backbench_exile_ids.size():
        backbench_exile_ids[index] = value






func _assign_exile_to_first_open_seat(exile_id: int) -> void :
    _ensure_seats_sized()


    if is_seated(exile_id):
        return
    for i in core_exile_ids.size():
        if core_exile_ids[i] == -1:
            core_exile_ids[i] = exile_id
            seats_changed.emit()
            return
    for i in backbench_exile_ids.size():
        if backbench_exile_ids[i] == -1:
            backbench_exile_ids[i] = exile_id
            seats_changed.emit()
            return
    push_warning("GameState: no open seat for exile id %d (core + bench full)" % exile_id)






func _prune_party_of_non_core() -> void :
    if current_party_ids.is_empty():
        return
    var removed: bool = false
    for i in range(current_party_ids.size() - 1, -1, -1):
        var pid: int = current_party_ids[i]
        if not is_in_core(pid):
            current_party_ids.remove_at(i)
            removed = true
    if removed:
        party_changed.emit()





func _remove_exile_from_seats(exile_id: int) -> void :
    _ensure_seats_sized()
    var changed: bool = false
    for i in core_exile_ids.size():
        if core_exile_ids[i] == exile_id:
            core_exile_ids[i] = -1
            changed = true
    for i in backbench_exile_ids.size():
        if backbench_exile_ids[i] == exile_id:
            backbench_exile_ids[i] = -1
            changed = true
    if changed:
        seats_changed.emit()

func mark_exile_dead(exile_id: int):
    var exile = get_exile_by_id(exile_id)
    if exile:
        exile.status = "dead"

        if exile_id in current_party_ids:
            current_party_ids.erase(exile_id)
            party_changed.emit()

        _party_auto_dropped_recovering.erase(exile_id)



        exile_died.emit(exile_id)














func dismiss_exile(exile_id: int) -> bool:
    var exile: ExileData = get_exile_by_id(exile_id)
    if exile == null:
        return false



    _return_equipped_to_stash(exile)
    exile.equipped_items.clear()


    if exile_id in current_party_ids:
        current_party_ids.erase(exile_id)
        party_changed.emit()
    _party_auto_dropped_recovering.erase(exile_id)




    exile_dismissed.emit(exile)



    remove_exile(exile_id)
    return true






func _return_equipped_to_stash(exile: ExileData) -> void :
    for slot_key in exile.equipped_items.keys():
        var item: Item = exile.equipped_items[slot_key]
        if item == null:
            continue
        item.stash_position = Vector2i(-1, -1)
        item.stash_tab = 0
        var slot: Dictionary = find_free_stash_slot(item)
        if slot.is_empty():
            push_warning(
                "GameState.dismiss_exile: stash full, dropping '%s' from %s"
                %[item.get_display_name(), exile.name]
            )
            continue
        item.stash_tab = int(slot.get("tab", 0))
        item.stash_position = slot.get("position", Vector2i(-1, -1))
        add_item_to_stash(item)







func is_in_party(exile_id: int) -> bool:
    return exile_id in current_party_ids


func add_to_party(exile_id: int) -> void :

    _party_auto_dropped_recovering.erase(exile_id)
    if exile_id in current_party_ids:
        return



    if current_party_ids.size() >= MAX_PARTY_SIZE:
        push_warning(
            "GameState.add_to_party: refused exile id %d — party at cap (%d)"
            %[exile_id, MAX_PARTY_SIZE]
        )
        return
    current_party_ids.append(exile_id)
    party_changed.emit()


func remove_from_party(exile_id: int) -> void :


    _party_auto_dropped_recovering.erase(exile_id)
    if exile_id not in current_party_ids:
        return
    current_party_ids.erase(exile_id)
    party_changed.emit()


func toggle_party_member(exile_id: int) -> void :
    if is_in_party(exile_id):
        remove_from_party(exile_id)
    else:
        add_to_party(exile_id)


func clear_party() -> void :


    _party_auto_dropped_recovering.clear()
    if current_party_ids.is_empty():
        return
    current_party_ids.clear()
    party_changed.emit()












func prune_invalid_party_members() -> bool:
    const NON_DEPLOYABLE: = ["dead", "dismissed", "captured", "lost", "long_lost", "on_mission", "recovering"]
    var kept: Array[int] = []
    for exile_id in current_party_ids:
        var exile: ExileData = get_exile_by_id(exile_id)
        if exile == null:
            continue
        if exile.status in NON_DEPLOYABLE:


            if exile.status == "recovering" and exile_id not in _party_auto_dropped_recovering:
                _party_auto_dropped_recovering.append(exile_id)
            continue
        kept.append(exile_id)
    if kept.size() == current_party_ids.size():
        return false
    current_party_ids = kept
    party_changed.emit()
    return true


func get_party_exiles() -> Array[ExileData]:
    var result: Array[ExileData] = []
    for exile_id in current_party_ids:
        var exile: ExileData = get_exile_by_id(exile_id)
        if exile:
            result.append(exile)
    return result







func _restore_auto_dropped_recovering_members() -> void :
    if _party_auto_dropped_recovering.is_empty():
        return
    var still_pending: Array[int] = []
    for exile_id in _party_auto_dropped_recovering:
        var exile: ExileData = get_exile_by_id(exile_id)

        if exile == null:
            continue

        if exile_id in current_party_ids:
            continue







        if exile.status == "idle":
            if current_party_ids.size() < MAX_PARTY_SIZE:
                add_to_party(exile_id)
            continue



        if exile.status == "recovering":
            still_pending.append(exile_id)
    _party_auto_dropped_recovering = still_pending


func add_item_to_stash(item: Item) -> void :
    guild_stash.append(item)
    stash_changed.emit()

func remove_item_from_stash(item: Item) -> bool:
    var idx = guild_stash.find(item)
    if idx == -1:
        push_warning("Tried to remove item from stash that wasn't there: " + str(item))
        return false
    guild_stash.remove_at(idx)
    stash_changed.emit()
    return true

func get_stash_items() -> Array[Item]:
    return guild_stash


















func find_free_stash_slot(item: Item, ignore_item: Item = null, extra_planned: Array = []) -> Dictionary:
    if item == null or item.base_item == null:
        return {}
    var item_w: int = item.base_item.grid_width
    var item_h: int = item.base_item.grid_height
    for tab_index in range(STASH_CONFIG.tab_count):
        var occupancy: Array = _build_stash_occupancy(tab_index, ignore_item, extra_planned)
        var placement: Vector2i = _find_free_rect_in_occupancy(
            occupancy, item_w, item_h
        )
        if placement != Vector2i(-1, -1):
            return {"tab": tab_index, "position": placement}
    return {}






func _build_stash_occupancy(tab_index: int, ignore_item: Item, extra_planned: Array = []) -> Array:
    var grid: Array = []
    for _col in range(STASH_CONFIG.columns):
        var col_arr: Array = []
        for _row in range(STASH_CONFIG.rows):
            col_arr.append(false)
        grid.append(col_arr)
    for stash_item in guild_stash:
        if stash_item == ignore_item:
            continue
        if stash_item.stash_tab != tab_index:
            continue
        _stamp_item_into_grid(grid, stash_item, stash_item.stash_position)
    for entry in extra_planned:


        var planned_item: Item = entry.get("item", null)
        if planned_item == null or planned_item == ignore_item:
            continue
        var planned_tab: int = int(entry.get("tab", -1))
        if planned_tab != tab_index:
            continue
        var planned_pos: Vector2i = entry.get("position", Vector2i(-1, -1))
        _stamp_item_into_grid(grid, planned_item, planned_pos)
    return grid



func _stamp_item_into_grid(grid: Array, item: Item, pos: Vector2i) -> void :
    if item == null or item.base_item == null:
        return
    if pos == Vector2i(-1, -1):
        return
    var w: int = item.base_item.grid_width
    var h: int = item.base_item.grid_height
    for dc in range(w):
        for dr in range(h):
            var c: int = pos.x + dc
            var r: int = pos.y + dr
            if c >= 0 and c < STASH_CONFIG.columns and r >= 0 and r < STASH_CONFIG.rows:
                grid[c][r] = true




func _find_free_rect_in_occupancy(occupancy: Array, w: int, h: int) -> Vector2i:
    var max_col: int = STASH_CONFIG.columns - w
    var max_row: int = STASH_CONFIG.rows - h
    for row in range(max_row + 1):
        for col in range(max_col + 1):
            var fits: bool = true
            for dc in range(w):
                for dr in range(h):
                    if occupancy[col + dc][row + dr]:
                        fits = false
                        break
                if not fits:
                    break
            if fits:
                return Vector2i(col, row)
    return Vector2i(-1, -1)






func add_chaos(amount: int):
    var old_value = chaos
    chaos = max(0, chaos + amount)
    if chaos != old_value:
        resource_changed.emit("chaos", old_value, chaos)

func spend_chaos(amount: int) -> bool:
    if chaos >= amount:
        add_chaos( - amount)
        return true
    return false

func add_food(amount: int):
    var old_value = food
    food = max(0, food + amount)
    if food != old_value:
        resource_changed.emit("food", old_value, food)

func spend_food(amount: int) -> bool:
    if food >= amount:
        add_food( - amount)
        return true
    return false

func add_scrap(amount: int):
    var old_value = scrap
    scrap = max(0, scrap + amount)
    if scrap != old_value:
        resource_changed.emit("scrap", old_value, scrap)

func spend_scrap(amount: int) -> bool:
    if scrap >= amount:
        add_scrap( - amount)
        return true
    return false

func add_exalt(amount: int):
    var old_value = exalt
    exalt = max(0, exalt + amount)
    if exalt != old_value:
        resource_changed.emit("exalt", old_value, exalt)

func spend_exalt(amount: int) -> bool:
    if exalt >= amount:
        add_exalt( - amount)
        return true
    return false






func count_vaal_orbs() -> int:
    var n: int = 0
    for item in guild_stash:
        if item and item.base_item and item.base_item.item_id == "vaal_orb":
            n += 1
    return n




func advance_turn():
    current_turn += 1
    turn_advanced.emit(current_turn)


    if current_turn % GameSettings.TURNS_PER_DAY == 0:
        advance_day()


    _process_end_of_turn()

func advance_day():
    current_day += 1

    day_changed.emit(current_day)


    _generate_daily_recruits()




    _wandering_offer_pending = false
    _emit_wandering_offer_if_needed()




    _maybe_offer_passing_boat()


    _process_end_of_day()

func _generate_daily_recruits():
    current_recruits = RecruitmentManager.generate_daily_recruits()
    recruitment_phase_started.emit()










func _maybe_offer_passing_boat() -> void :

    if next_event_recruit_day <= 0:
        next_event_recruit_day = current_day + randi_range(
            GameSettings.RECRUIT_OFFER_DAYS_MIN, GameSettings.RECRUIT_OFFER_DAYS_MAX
        )
        return

    if current_day < next_event_recruit_day:
        return

    var ceiling: int = max(1, _max_guild_exile_level())
    var margin: float = clampf(GameSettings.EVENT_RECRUIT_LEVEL_MARGIN, 0.0, 1.0)
    var floor_level: int = max(1, int(round(float(ceiling) * (1.0 - margin))))
    var count: int = randi_range(
        GameSettings.EVENT_RECRUIT_COUNT_MIN, GameSettings.EVENT_RECRUIT_COUNT_MAX
    )

    var recruits: Array[RecruitData] = RecruitmentManager.generate_event_recruits({
        "count": count, 
        "level_min": floor_level, 
        "level_max": ceiling, 
        "quality_bonus": GameSettings.EVENT_RECRUIT_QUALITY_BONUS, 
        "min_class_rarity": GameSettings.EVENT_RECRUIT_MIN_CLASS_RARITY, 
        "min_trait_rarity": GameSettings.EVENT_RECRUIT_MIN_TRAIT_RARITY, 
        "free": false, 
    })

    if recruits.is_empty():
        push_warning("GameState: passing-boat roll produced no recruits")
    else:
        event_recruits_offered.emit(recruits, "passing_boat")


    next_event_recruit_day = current_day + randi_range(
        GameSettings.RECRUIT_OFFER_DAYS_MIN, GameSettings.RECRUIT_OFFER_DAYS_MAX
    )















func _maybe_offer_wandering_exile(_exile_id: int) -> void :
    _emit_wandering_offer_if_needed()


func _on_game_loaded_check_wandering() -> void :
    _emit_wandering_offer_if_needed()




func _on_exile_added_clear_wandering_flag(_exile_data: ExileData) -> void :
    if get_living_exile_count() > 0:
        _wandering_offer_pending = false


func _emit_wandering_offer_if_needed() -> void :
    if _wandering_offer_pending:
        return
    if get_living_exile_count() > 0:
        return
    var recruits: Array[RecruitData] = RecruitmentManager.generate_event_recruits({
        "count": 1, 
        "level_min": 1, 
        "level_max": 1, 
        "free": true, 
    })
    if recruits.is_empty():
        push_warning("GameState: wandering-exile fallback produced no recruit")
        return
    _wandering_offer_pending = true
    event_recruits_offered.emit(recruits, "wandering_exile")




func _max_guild_exile_level() -> int:
    var max_level: int = 1
    for exile in get_living_exiles():
        if exile.level > max_level:
            max_level = exile.level
    return max_level

func _process_end_of_turn():

    MoraleManager.process_end_turn(get_living_exiles())

func _process_end_of_day():





    const KNOWN_NON_RESTING: = ["on_mission", "captured", "lost", "long_lost", "dismissed", "dead"]
    for exile in get_living_exiles():
        match exile.status:
            "idle":
                RecoveryManager.daily_rest_idle(exile)
            "recovering":
                RecoveryManager.daily_rest_recovering(exile)
            _:
                if exile.status not in KNOWN_NON_RESTING:
                    push_warning(
                        "GameState._process_end_of_day: exile %d (%s) has unknown status '%s' — no daily rest applied"
                        %[exile.id, exile.name, exile.status]
                    )



    QuartermasterManager.rebalance_to_fit_food()



    _restore_auto_dropped_recovering_members()


    end_of_day_completed.emit(current_day)
