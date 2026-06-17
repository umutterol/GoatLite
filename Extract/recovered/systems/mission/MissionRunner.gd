class_name MissionRunner
extends RefCounted









signal encounter_started(index: int, encounter: EncounterData)


signal encounter_resolved(index: int, combat_result: CombatResultData, encounter_loot: LootResolver.EncounterLoot)
signal mission_resolved(report: Dictionary)


var holding_bag_items: Array[Item] = []
var holding_bag_xp: int = 0




var holding_bag_food: int = 0
var holding_bag_scrap: int = 0
var holding_bag_chaos: int = 0


var holding_bag_exalt: int = 0






var encounter_outcomes: Array[Dictionary] = []
var defeat_contexts: Array[DefeatContext] = []




var defeat_results: Array = []




var _mission_stats_by_exile: Dictionary = {}



var _starting_state_by_exile: Dictionary = {}



var _end_of_combat_state_by_exile: Dictionary = {}


var active_mission: ActiveMission

var last_combat_result: CombatResultData = null

var final_report: Dictionary = {}





var last_scouting_gained: float = 0.0

var _rng: = RandomNumberGenerator.new()
var _item_generator: ItemGenerator
var _last_combat_result: int = -1






var _retreat_was_player_initiated: bool = false


func _init(mission: ActiveMission, seed_value: int = 0) -> void :
    active_mission = mission
    if seed_value != 0:
        _rng.seed = seed_value
    else:
        _rng.randomize()
    _item_generator = ItemGenerator.new()
    _item_generator.load_item_bases()
    _capture_starting_state()









func run_all_encounters() -> Dictionary:
    while active_mission.status == ActiveMission.STATUS.IN_PROGRESS:
        if not step_next_encounter():
            break
    return final_report








func retreat() -> void :
    if not active_mission or active_mission.status != ActiveMission.STATUS.IN_PROGRESS:
        return
    _retreat_was_player_initiated = true
    _last_combat_result = CombatEnums.CombatResult.RETREAT
    MissionManager.end_mission_early(active_mission, true)
    _finalize()




func step_next_encounter() -> bool:
    var slot_index: int = active_mission.current_encounter_index
    var slot: MissionConundrumsSlot = active_mission.mission_data.encounter_slots[slot_index]
    var encounter: EncounterData = MissionManager.resolve_encounter_slot(
        slot, active_mission.area_id, active_mission.mission_data.level, _rng
    )
    if not encounter:
        push_error("MissionRunner: encounter resolution returned null at slot %d" % slot_index)
        return false




    _mark_encounter_monsters_seen(encounter)

    encounter_started.emit(slot_index, encounter)

    var party: Array[ExileData] = _build_party()
    if party.is_empty():



        _last_combat_result = CombatEnums.CombatResult.DEFEAT
        MissionManager.end_mission_early(active_mission, false)
        _finalize()
        return false



    var sim: = CombatSimulation.new()



    sim.initialize(party, encounter, _rng.randi(), active_mission.mission_data.level)
    var combat_result: CombatResultData = sim.run_to_completion()
    last_combat_result = combat_result
    _last_combat_result = combat_result.outcome


    CombatResultProcessor.process(combat_result, party)

    _accumulate_mission_stats(combat_result)

    var encounter_loot: = LootResolver.resolve_encounter(
        combat_result.defeated_monsters, 
        active_mission.mission_data, 
        _item_generator, 
        _rng, 
    )
    holding_bag_items.append_array(encounter_loot.items)
    holding_bag_xp += encounter_loot.experience_total
    holding_bag_food += encounter_loot.food
    holding_bag_scrap += encounter_loot.scrap
    holding_bag_chaos += encounter_loot.chaos
    holding_bag_exalt += encounter_loot.exalt






    _resolve_new_defeats(combat_result, encounter)

    encounter_outcomes.append({
        "index": slot_index, 
        "encounter_id": encounter.encounter_id, 
        "result": _last_combat_result, 
        "loot": encounter_loot, 


        "combat_result": combat_result, 
    })
    encounter_resolved.emit(slot_index, combat_result, encounter_loot)

    match _last_combat_result:
        CombatEnums.CombatResult.VICTORY:



            _capture_end_of_combat_state()
            var more_encounters: bool = MissionManager.advance_encounter(active_mission)
            if not more_encounters:
                _finalize()
            return more_encounters
        CombatEnums.CombatResult.DEFEAT:
            MissionManager.end_mission_early(active_mission, false)
            _finalize()
            return false
        CombatEnums.CombatResult.RETREAT:
            MissionManager.end_mission_early(active_mission, true)
            _finalize()
            return false
        _:
            return false









func _mark_encounter_monsters_seen(encounter: EncounterData) -> void :
    var ids: Array[String] = []
    for spawn: MonsterSpawn in encounter.monster_spawns:
        if spawn == null or spawn.monster == null:
            continue
        var mid: String = spawn.monster.monster_id
        if mid.is_empty() or ids.has(mid):
            continue
        ids.append(mid)
    if not ids.is_empty():
        AreaManager.mark_monsters_seen(active_mission.area_id, ids)






func _build_party() -> Array[ExileData]:
    var party: Array[ExileData] = []
    for exile_id in active_mission.assigned_exile_ids:
        var exile: = GameState.get_exile_by_id(exile_id)
        if not exile or exile.status != "on_mission":
            continue
        if exile.current_life <= 0.0:
            continue
        party.append(exile)
    return party






func _resolve_new_defeats(combat_result: CombatResultData, encounter: EncounterData) -> void :
    if combat_result.downed_party.is_empty():
        return
    var was_wipe: bool = combat_result.outcome == CombatEnums.CombatResult.DEFEAT
    var was_solo: bool = active_mission.assigned_exile_ids.size() == 1
    var new_contexts: Array[DefeatContext] = []
    for c in combat_result.downed_party:
        if not c.source_exile:
            continue
        var ctx: = DefeatContext.create(c.source_exile, "combat", encounter.display_name)
        ctx.zone_danger = encounter.recommended_level
        ctx.total_wipe = was_wipe
        ctx.allies_survived = not was_wipe
        ctx.was_solo = was_solo
        defeat_contexts.append(ctx)
        new_contexts.append(ctx)
    var results: Array = DefeatResolver.resolve_all(new_contexts)
    for r in results:
        if r.died:
            _recover_dead_gear(r.exile_data)
        defeat_results.append(r)





func _recover_dead_gear(exile: ExileData) -> void :
    if not exile:
        return
    for slot_key in exile.equipped_items.keys():
        var item: Item = exile.equipped_items[slot_key]
        if item:
            holding_bag_items.append(item)
    exile.equipped_items.clear()





func _accumulate_mission_stats(combat_result: CombatResultData) -> void :
    for cid in combat_result.combatant_results:
        var entry: Dictionary = combat_result.combatant_results[cid]
        var exile: ExileData = entry.get("source_exile")
        if not exile:
            continue
        var running: Dictionary = _mission_stats_by_exile.get(exile.id, {
            "damage_dealt": 0.0, 
            "damage_taken": 0.0, 
            "max_life": entry.get("max_life", 0.0), 
            "kills": 0, 
            "xp_earned": 0, 
            "leveled_up": false, 
        })
        running["damage_dealt"] += entry.get("damage_dealt", 0.0)
        running["damage_taken"] += entry.get("damage_taken", 0.0)
        running["kills"] += entry.get("kills", 0)
        running["xp_earned"] += entry.get("xp_earned", 0)
        running["leveled_up"] = running["leveled_up"] or entry.get("leveled_up", false)
        _mission_stats_by_exile[exile.id] = running






func _finalize() -> Dictionary:
    var total_wipe: bool = _last_combat_result == CombatEnums.CombatResult.DEFEAT




    _capture_end_of_combat_state()







    if not total_wipe:
        _apply_mission_level_morale()

    var completion_items: Array[Item] = []

    var resource_grants: = {"chaos": 0, "food": 0, "scrap": 0, "exalt": 0}
    var pending_loot: Array[Item] = []
    var lost_items: int = 0

    if total_wipe:
        lost_items = holding_bag_items.size()
    else:
        completion_items = LootResolver.resolve_completion(
            active_mission.mission_data, 
            active_mission.completion_percent, 
            _item_generator, 
            _rng, 
        )
        var completion_resource_grants: Dictionary = _grant_completion_resources(resource_grants)




        pending_loot.append_array(holding_bag_items)
        pending_loot.append_array(completion_items)






        _attach_bonus_drops_to_final_encounter(completion_items, completion_resource_grants)







    var xp_awarded_total: int = _sum_xp_awarded()

    var report: = {
        "mission_id": active_mission.mission_data.mission_id, 
        "status": active_mission.status, 
        "total_wipe": total_wipe, 
        "completion_percent": active_mission.completion_percent, 
        "encounter_outcomes": encounter_outcomes, 
        "loot_found": pending_loot.size(), 
        "pending_loot": pending_loot, 
        "loot_lost": lost_items, 
        "xp_distributed": xp_awarded_total, 


        "scouting_gained": int(round(last_scouting_gained)), 
        "defeat_results": defeat_results, 
        "resource_grants": resource_grants, 


        "starting_state_by_exile": _starting_state_by_exile, 
        "end_of_combat_state_by_exile": _end_of_combat_state_by_exile, 
    }
    final_report = report


    MissionManager.last_resolved_runner = self
    mission_resolved.emit(report)
    return report











func _apply_mission_level_morale() -> void :
    var mission_level: int = active_mission.mission_data.level
    var is_risky_retreat: bool = not _retreat_was_player_initiated
    for exile_id in active_mission.assigned_exile_ids:
        var exile: ExileData = GameState.get_exile_by_id(exile_id)
        if not exile or exile.status == "dead":
            continue
        var stats: Dictionary = _mission_stats_by_exile.get(exile_id, {})
        var taken: float = stats.get("damage_taken", 0.0)
        var max_life: float = maxf(stats.get("max_life", 1.0), 1.0)
        var damage_pct: float = (taken / max_life) * 100.0

        match active_mission.status:
            ActiveMission.STATUS.COMPLETED:
                MoraleManager.apply_mission_victory(exile, mission_level, damage_pct)
            ActiveMission.STATUS.RETREATED:
                MoraleManager.apply_retreat_penalty(exile, is_risky_retreat)
























func _attach_bonus_drops_to_final_encounter(
    completion_items: Array[Item], 
    completion_only_grants: Dictionary, 
) -> void :
    if encounter_outcomes.is_empty():
        return
    var final_outcome: Dictionary = encounter_outcomes[-1]
    var final_loot: LootResolver.EncounterLoot = final_outcome.get("loot")
    var final_combat: CombatResultData = final_outcome.get("combat_result")
    if not final_loot or not final_combat:
        return

    var source_id: int = _resolve_bonus_source_combatant_id(final_combat)
    if source_id < 0:
        return

    final_loot.bonus_source_combatant_id = source_id
    final_loot.bonus_drops = {
        "food": int(completion_only_grants.get("food", 0)), 
        "scrap": int(completion_only_grants.get("scrap", 0)), 
        "chaos": int(completion_only_grants.get("chaos", 0)), 



        "exalt": int(completion_only_grants.get("exalt", 0)), 
        "items": completion_items.duplicate(), 
    }




func _resolve_bonus_source_combatant_id(combat_result: CombatResultData) -> int:
    var last_death_id: int = -1
    for event in combat_result.event_log:
        if event.event_type != CombatEnums.CombatEventType.DEATH:
            continue
        var victim_id: int = event.data.get("combatant_id", -1)
        if victim_id < 0:
            continue
        var victim: CombatantData = combat_result.combatants[victim_id]

        if victim and victim.source_monster and victim.source_monster.is_unique:
            return victim_id

        if victim and victim.team == CombatEnums.CombatantTeam.MONSTERS:
            last_death_id = victim_id
    return last_death_id




func _capture_starting_state() -> void :
    for exile_id in active_mission.assigned_exile_ids:
        var exile: = GameState.get_exile_by_id(exile_id)
        if exile:
            _starting_state_by_exile[exile_id] = _snapshot_state(exile)


func _capture_end_of_combat_state() -> void :
    for exile_id in active_mission.assigned_exile_ids:
        var exile: = GameState.get_exile_by_id(exile_id)
        if exile:
            _end_of_combat_state_by_exile[exile_id] = _snapshot_state(exile)


static func _snapshot_state(exile: ExileData) -> Dictionary:
    return {
        "life": exile.current_life, 
        "max_life": exile.current_stats.life, 
        "vitality": exile.current_vitality, 
        "max_vitality": exile.current_stats.max_vitality, 
        "morale": exile.current_stats.morale, 
        "max_morale": exile.current_stats.max_morale, 
    }





func _sum_xp_awarded() -> int:
    var total: int = 0
    for exile_id in _mission_stats_by_exile:
        var stats: Dictionary = _mission_stats_by_exile[exile_id]
        total += stats.get("xp_earned", 0)
    return total














func _grant_completion_resources(grants: Dictionary) -> Dictionary:


    grants["chaos"] = holding_bag_chaos
    grants["food"] = holding_bag_food
    grants["scrap"] = holding_bag_scrap
    grants["exalt"] = holding_bag_exalt



    var completion_only: = {"chaos": 0, "food": 0, "scrap": 0, "exalt": 0}








    if active_mission.mission_data.mission_rewards:
        var rewards: MissionReward = active_mission.mission_data.mission_rewards
        var pct: float = active_mission.completion_percent
        completion_only["chaos"] = int(round(rewards.chaos_amount * pct))
        completion_only["food"] = int(round(rewards.food_amount * pct))
        completion_only["scrap"] = int(round(rewards.scrap_amount * pct))
        completion_only["exalt"] = int(round(rewards.exalt_amount * pct))
        grants["chaos"] += completion_only["chaos"]
        grants["food"] += completion_only["food"]
        grants["scrap"] += completion_only["scrap"]
        grants["exalt"] += completion_only["exalt"]

    GameState.add_chaos(grants["chaos"])
    GameState.add_food(grants["food"])
    GameState.add_scrap(grants["scrap"])
    GameState.add_exalt(grants["exalt"])

    return completion_only
