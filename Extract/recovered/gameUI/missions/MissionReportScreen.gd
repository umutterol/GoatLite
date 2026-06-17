extends Control














const ANIM_DURATION: float = 3.0

const DeathReportScene: = preload("res://gameUI/missions/DeathReport.tscn")
const ExileCardScene: = preload("res://gameUI/missions/MissionReportExileCard.tscn")





const CurrencyFlyPipScene: PackedScene = preload("res://gameUI/smallComponents/CurrencyFlyPip.tscn")
const ChaosTexture: Texture2D = preload("res://assets/sprites/itemSprites/currencySprites/ChaosShardPhysical.png")
const ScrapTexture: Texture2D = preload("res://assets/sprites/itemSprites/currencySprites/ScrapPhysical.png")
const PIP_SPAWN_STAGGER: float = 0.04

@onready var outcome_banner: Label = %OutcomeBanner
@onready var mission_subtitle: Label = %MissionSubtitle
@onready var rescue_banner: RichTextLabel = %RescueBanner
@onready var summary_label: Label = %SummaryLabel




@onready var scouting_chip: Label = %ScoutingChip
@onready var party_list: VBoxContainer = %PartyList
@onready var found_grid: LootGrid = %FoundGrid
@onready var kept_grid: LootGrid = %KeptGrid
@onready var scrap_button: Button = %ScrapButton
@onready var take_all_button: Button = %TakeAllButton
@onready var return_button: Button = %ReturnButton
@onready var scrap_note: Label = %ScrapNote
@onready var decision_row: HBoxContainer = %DecisionRow
@onready var retreat_button: Button = %RetreatButton
@onready var continue_mission_button: Button = %ContinueMissionButton
@onready var kept_header: Label = %KeptHeader
@onready var kept_grid_wrapper: CenterContainer = %KeptGridWrapper
@onready var retreat_note: Label = %RetreatNote


@onready var discard_zone: IntermissionDiscardZone = %DiscardZone



@onready var currency_row: HBoxContainer = %CurrencyRow
@onready var food_pip: CurrencyDropPip = %FoodPip
@onready var chaos_pip: CurrencyDropPip = %ChaosPip
@onready var scrap_pip: CurrencyDropPip = %ScrapPip
@onready var exalt_pip: CurrencyDropPip = %ExaltPip




enum Mode{FINAL, INTERMISSION}
var _mode: Mode = Mode.FINAL
var _runner: MissionRunner = null



var _retreat_armed: bool = false



var _exile_cards: Array[MissionReportExileCard] = []






func _ready() -> void :




    ToastManager.resume()

    return_button.pressed.connect(_on_return)
    take_all_button.pressed.connect(_on_take_all)
    retreat_button.pressed.connect(_on_retreat)
    continue_mission_button.pressed.connect(_on_continue_mission)
    scrap_button.pressed.connect(_on_scrap_button_pressed)
    discard_zone.item_discarded.connect(_on_item_discarded)


    found_grid.partner_grid = kept_grid
    kept_grid.partner_grid = found_grid



    found_grid.items_changed.connect(_refresh_take_all_state)

    _resolve_mode_and_runner()
    if not _runner:
        _render_missing_runner()
        return




    if _mode == Mode.FINAL:
        _wire_loot_interactions()

    _render(_runner)
    _play_all_animations()





func _resolve_mode_and_runner() -> void :
    var actives: = MissionManager.get_active_missions()
    if not actives.is_empty() and actives[0].status == ActiveMission.STATUS.IN_PROGRESS:
        _mode = Mode.INTERMISSION
        _runner = MissionManager.get_runner(actives[0])
    else:
        _mode = Mode.FINAL
        _runner = MissionManager.last_resolved_runner




func _wire_loot_interactions() -> void :
    if not found_grid.item_right_clicked.is_connected(_on_found_item_right_clicked):
        found_grid.item_right_clicked.connect(_on_found_item_right_clicked)
    if not kept_grid.item_right_clicked.is_connected(_on_kept_item_right_clicked):
        kept_grid.item_right_clicked.connect(_on_kept_item_right_clicked)


func _refresh_take_all_state() -> void :

    var found_empty: bool = found_grid.get_items().is_empty()
    take_all_button.disabled = found_empty
    scrap_button.disabled = found_empty


func _on_found_item_right_clicked(item: Item) -> void :
    found_grid.quick_move_to_partner(item)


func _on_kept_item_right_clicked(item: Item) -> void :
    kept_grid.quick_move_to_partner(item)






func _render(runner: MissionRunner) -> void :
    var mission: MissionData = runner.active_mission.mission_data
    mission_subtitle.text = mission.display_name

    _apply_mode_visibility()

    if _mode == Mode.INTERMISSION:
        _render_intermission(runner)
    else:
        _render_final(runner)




func _apply_mode_visibility() -> void :
    var intermission: bool = _mode == Mode.INTERMISSION


    kept_grid_wrapper.visible = not intermission
    kept_header.visible = not intermission
    take_all_button.visible = not intermission



    scrap_button.visible = not intermission
    return_button.visible = not intermission
    scrap_note.visible = not intermission
    decision_row.visible = intermission
    discard_zone.visible = intermission


func _render_final(runner: MissionRunner) -> void :
    var report: Dictionary = runner.final_report
    outcome_banner.text = _outcome_text(report)
    outcome_banner.modulate = _outcome_color(report)
    summary_label.text = _summary_text(report)
    _apply_scouting_chip(report.get("scouting_gained", 0))
    _apply_rescue_banner(runner, report)
    _render_party(runner, report)
    _render_loot(report)







func _apply_rescue_banner(runner: MissionRunner, _report: Dictionary) -> void :
    if runner == null:
        rescue_banner.visible = false
        return
    var has_capture: bool = false
    for result in runner.defeat_results:
        if result and result.outcome and result.outcome.capture_duration_days > 0:
            has_capture = true
            break
    if not has_capture:
        rescue_banner.visible = false
        return
    var area_key: String = WorldEnum.AREAS.keys()[runner.active_mission.area_id]
    rescue_banner.text = "[center][color=#f55]Rescue Mission Available: %s[/color][/center]" % area_key
    rescue_banner.visible = true





func _apply_scouting_chip(amount: int) -> void :
    if amount <= 0:
        scouting_chip.visible = false
        return
    scouting_chip.text = "Scouting: +%d" % amount
    scouting_chip.visible = true





func _render_intermission(runner: MissionRunner) -> void :


    outcome_banner.text = "VICTORY"
    outcome_banner.modulate = Color(0.5, 1.0, 0.6)
    summary_label.text = _intermission_summary_text(runner)

    scouting_chip.visible = false




    var synthetic_report: Dictionary = {
        "status": ActiveMission.STATUS.IN_PROGRESS, 
        "total_wipe": false, 
        "encounter_outcomes": runner.encounter_outcomes, 
        "defeat_results": runner.defeat_results, 
        "starting_state_by_exile": runner._starting_state_by_exile, 
        "end_of_combat_state_by_exile": runner._end_of_combat_state_by_exile, 
    }
    _render_party(runner, synthetic_report)
    _render_intermission_loot(runner)


func _intermission_summary_text(runner: MissionRunner) -> String:
    var cleared: int = runner.encounter_outcomes.size()
    var total: int = runner.active_mission.total_encounters
    var loot_in: int = runner.holding_bag_items.size()
    return "Encounters Cleared: %d / %d   •   Loot found: %d" % [cleared, total, loot_in]


func _render_intermission_loot(runner: MissionRunner) -> void :
    for item in runner.holding_bag_items:
        if item is Item:
            item.stash_position = Vector2i(-1, -1)
    var typed: Array[Item] = []
    for item in runner.holding_bag_items:
        if item is Item:
            typed.append(item)
    found_grid.populate(typed)
    kept_grid.populate([] as Array[Item])



    _refresh_take_all_state()


func _outcome_text(report: Dictionary) -> String:
    if report.get("total_wipe", false):
        return "DEFEAT"
    match report.get("status", -1):
        ActiveMission.STATUS.COMPLETED: return "VICTORY"
        ActiveMission.STATUS.RETREATED: return "RETREATED"
        ActiveMission.STATUS.FAILED: return "FAILED"
        _: return "MISSION ENDED"


func _outcome_color(report: Dictionary) -> Color:
    if report.get("total_wipe", false):
        return Color(1.0, 0.4, 0.4)
    match report.get("status", -1):
        ActiveMission.STATUS.COMPLETED: return Color(0.5, 1.0, 0.6)
        ActiveMission.STATUS.RETREATED: return Color(0.9, 0.85, 0.4)
        _: return Color(1.0, 0.4, 0.4)


func _summary_text(report: Dictionary) -> String:
    var pct: float = report.get("completion_percent", 0.0) * 100.0
    var enc: int = report.get("encounter_outcomes", []).size()
    var loot_in: int = report.get("loot_found", 0)
    var loot_out: int = report.get("loot_lost", 0)
    var xp: int = report.get("xp_distributed", 0)
    var loot_text: String = "Loot found: %d" % loot_in
    if loot_out > 0:
        loot_text = "Loot LOST: %d (party wipe)" % loot_out
    return "Completion: %.0f%%   •   Encounters: %d   •   %s   •   XP shared: %d" % [
        pct, enc, loot_text, xp, 
    ]








func _render_party(runner: MissionRunner, report: Dictionary) -> void :
    _clear(party_list)
    _exile_cards.clear()
    var defeat_results: Array = report.get("defeat_results", [])


    var party_totals: Dictionary = _compute_party_totals(runner)
    for exile_id in runner.active_mission.assigned_exile_ids:
        var exile: ExileData = GameState.get_exile_by_id(exile_id)
        if not exile:
            continue
        var card: MissionReportExileCard = ExileCardScene.instantiate()
        party_list.add_child(card)
        card.populate(
            exile, 
            runner._mission_stats_by_exile.get(exile_id, {}), 
            party_totals, 
            report.get("starting_state_by_exile", {}).get(exile_id, {}), 
            report.get("end_of_combat_state_by_exile", {}).get(exile_id, {}), 
            _find_defeat_result(defeat_results, exile_id), 
        )

        card.death_report_pressed.connect(_open_death_report)
        _exile_cards.append(card)




func _compute_party_totals(runner: MissionRunner) -> Dictionary:
    var totals: Dictionary = {
        "damage_taken": 0.0, 
        "damage_dealt": 0.0, 
        "kills": 0, 
    }
    for stats in runner._mission_stats_by_exile.values():
        totals["damage_taken"] += float(stats.get("damage_taken", 0.0))
        totals["damage_dealt"] += float(stats.get("damage_dealt", 0.0))
        totals["kills"] += int(stats.get("kills", 0))
    return totals


func _play_all_animations() -> void :

    for card in _exile_cards:
        if is_instance_valid(card):
            card.play_animation(ANIM_DURATION)


    _play_currency_animations()


    if _exile_cards.any( func(c): return c._is_dead):
        get_tree().create_timer(ANIM_DURATION).timeout.connect(_reveal_dead_state)







func _play_currency_animations() -> void :
    if _mode != Mode.FINAL or not _runner:
        currency_row.visible = false
        return

    var grants: Dictionary = _runner.final_report.get("resource_grants", {})
    var food_amt: int = int(grants.get("food", 0))
    var chaos_amt: int = int(grants.get("chaos", 0))
    var scrap_amt: int = int(grants.get("scrap", 0))
    var exalt_amt: int = int(grants.get("exalt", 0))



    currency_row.visible = food_amt > 0 or chaos_amt > 0 or scrap_amt > 0 or exalt_amt > 0

    food_pip.play_to(food_amt, ANIM_DURATION)
    chaos_pip.play_to(chaos_amt, ANIM_DURATION)
    scrap_pip.play_to(scrap_amt, ANIM_DURATION)
    exalt_pip.play_to(exalt_amt, ANIM_DURATION)





func _reveal_dead_state() -> void :
    for card in _exile_cards:
        if is_instance_valid(card):
            card.reveal_dead_state()


func _open_death_report(exile: ExileData) -> void :


    if not _runner:
        return
    var exiles: Array[ExileData] = [exile]
    var report: = DeathReportScene.instantiate()
    add_child(report)
    report.populate(exiles, _runner.encounter_outcomes)









func _render_loot(report: Dictionary) -> void :
    var pending: Array = report.get("pending_loot", [])


    for item in pending:
        if item is Item:
            item.stash_position = Vector2i(-1, -1)

    var typed: Array[Item] = []
    for item in pending:
        if item is Item:
            typed.append(item)
    found_grid.populate(typed)
    kept_grid.populate([] as Array[Item])
    take_all_button.disabled = typed.is_empty()
    scrap_button.disabled = typed.is_empty()


func _on_take_all() -> void :


    kept_grid.receive_all_from(found_grid)








func _on_item_discarded(item: Item) -> void :
    if item == null:
        return
    if found_grid.has_item(item):
        found_grid.remove_item(item)
    elif kept_grid.has_item(item):
        kept_grid.remove_item(item)
    if _runner != null:
        _runner.holding_bag_items.erase(item)


    found_grid.items_changed.emit()






func _on_return() -> void :




    _scrap_grid_items(found_grid)


    for item in kept_grid.get_items():


        item.stash_position = Vector2i(-1, -1)
        item.stash_tab = 0
        var slot: Dictionary = GameState.find_free_stash_slot(item)
        if slot.is_empty():
            push_warning("MissionReportScreen: stash full, dropping '%s'" % item.get_display_name())

            continue
        item.stash_tab = int(slot.get("tab", 0))
        item.stash_position = slot.get("position", Vector2i(-1, -1))
        GameState.add_item_to_stash(item)






    if not MissionManager.pending_rescued_exiles.is_empty():
        SceneRouter.to_rescued_exile_screen()
    elif not MissionManager.pending_long_lost_surfaced.is_empty():
        SceneRouter.to_long_lost_surfaced_modal()
    else:
        SceneRouter.to_guild()






func _on_scrap_button_pressed() -> void :
    _scrap_grid_items_animated(found_grid)







func _scrap_grid_items_animated(grid: LootGrid) -> void :
    if grid == null:
        return
    var items: Array[Item] = grid.get_items()
    if items.is_empty():
        return


    currency_row.visible = true
    var vfx_host: Node = _vfx_host()
    var delay: float = 0.0

    for item in items:
        var item_origin: Vector2 = _item_global_centroid(item, grid)
        var yields: Dictionary = SalvageCalculator.salvage_yield(item)
        var scrap_count: int = int(yields.get("scrap", 0))
        var chaos_count: int = int(yields.get("chaos", 0))

        for i in scrap_count:
            _spawn_fly_pip(vfx_host, item_origin, 
                _pip_global_center(scrap_pip), ScrapTexture, 
                _on_scrap_pip_arrived, delay)
            delay += PIP_SPAWN_STAGGER

        for i in chaos_count:
            _spawn_fly_pip(vfx_host, item_origin, 
                _pip_global_center(chaos_pip), ChaosTexture, 
                _on_chaos_pip_arrived, delay)
            delay += PIP_SPAWN_STAGGER

        grid.remove_item(item)

    grid.items_changed.emit()





func _spawn_fly_pip(
    host: Node, 
    start_global: Vector2, 
    end_global: Vector2, 
    texture: Texture2D, 
    on_arrive: Callable, 
    delay: float, 
) -> void :
    if host == null:
        on_arrive.call()
        return
    var spawn: = func() -> void :
        var pip: CurrencyFlyPip = CurrencyFlyPipScene.instantiate()
        host.add_child(pip)
        pip.spawn(start_global, end_global, texture, on_arrive)
    if delay <= 0.0:
        spawn.call()
        return


    create_tween().tween_callback(spawn).set_delay(delay)




func _vfx_host() -> Node:
    return self





func _item_global_centroid(item: Item, grid: LootGrid) -> Vector2:
    if item == null or item.base_item == null or grid == null:
        return global_position
    var origin: Vector2 = grid.global_position
    var cell: int = grid.cell_size
    var pos: Vector2i = item.stash_position
    if pos == Vector2i(-1, -1):
        return origin + Vector2(grid.columns * cell * 0.5, grid.rows * cell * 0.5)
    return origin + Vector2(
        (pos.x + item.base_item.grid_width * 0.5) * cell, 
        (pos.y + item.base_item.grid_height * 0.5) * cell, 
    )




func _pip_global_center(pip: CurrencyDropPip) -> Vector2:
    if pip == null:
        return get_viewport_rect().size * Vector2(0.5, 0.1)
    return pip.global_position + pip.size * 0.5





func _on_scrap_pip_arrived() -> void :
    GameState.add_scrap(1)
    if is_instance_valid(scrap_pip):
        scrap_pip.bump(1)


func _on_chaos_pip_arrived() -> void :
    GameState.add_chaos(1)
    if is_instance_valid(chaos_pip):
        chaos_pip.bump(1)





func _scrap_grid_items(grid: LootGrid) -> void :
    if grid == null:
        return
    var items: Array[Item] = grid.get_items()
    var total_scrap: int = 0
    var total_chaos: int = 0
    for item in items:
        var yields: Dictionary = SalvageCalculator.salvage_yield(item)
        total_scrap += int(yields.get("scrap", 0))
        total_chaos += int(yields.get("chaos", 0))
        grid.remove_item(item)
    if total_scrap > 0:
        GameState.add_scrap(total_scrap)
    if total_chaos > 0:
        GameState.add_chaos(total_chaos)
    if not items.is_empty():
        grid.items_changed.emit()














func _on_continue_mission() -> void :
    if not _runner:
        return


    _disarm_retreat()
    ToastManager.suspend()
    EventRecruitController.suspend()
    _runner.step_next_encounter()
    SceneRouter.to_combat_playback()




func _on_retreat() -> void :
    if not _runner:
        return
    if not _retreat_armed:
        _arm_retreat()
        return
    _runner.retreat()
    _mode = Mode.FINAL
    _retreat_armed = false
    _wire_loot_interactions()
    _render(_runner)
    _play_all_animations()


func _arm_retreat() -> void :
    _retreat_armed = true
    retreat_button.text = "Confirm Retreat?"

    retreat_button.modulate = Color(1.0, 0.75, 0.4)


func _disarm_retreat() -> void :
    if not _retreat_armed:
        return
    _retreat_armed = false
    retreat_button.text = "Retreat"
    retreat_button.modulate = Color(1.0, 1.0, 1.0)


func _find_defeat_result(defeats: Array, exile_id: int):
    for r in defeats:
        if r.exile_data and r.exile_data.id == exile_id:
            return r
    return null


func _clear(container: Node) -> void :
    for child in container.get_children():
        child.queue_free()


func _render_missing_runner() -> void :
    outcome_banner.text = "NO REPORT AVAILABLE"
    outcome_banner.modulate = Color(0.7, 0.7, 0.7)
    mission_subtitle.text = ""
    summary_label.text = "No mission has been resolved this session."
    scouting_chip.visible = false
