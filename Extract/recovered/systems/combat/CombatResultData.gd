class_name CombatResultData
extends RefCounted








var outcome: CombatEnums.CombatResult
var duration: float = 0.0
var initial_seed: int = 0



var event_log: Array[CombatEvent] = []
var snapshots: Array[Dictionary] = []
var combatants: Array[CombatantData] = []



var encounter: EncounterData = null




var combatant_results: Dictionary = {}



var defeated_monsters: Array[CombatantData] = []
var surviving_party: Array[CombatantData] = []
var downed_party: Array[CombatantData] = []






static func from_simulation(sim: CombatSimulation, encounter_data: EncounterData) -> CombatResultData:
    var result: = CombatResultData.new()
    result.outcome = sim.combat_result
    result.duration = sim.current_tick
    result.initial_seed = sim.initial_seed
    result.event_log = sim.event_log
    result.snapshots = sim.snapshots
    result.combatants = sim.combatants
    result.encounter = encounter_data

    for combatant in sim.combatants:
        result.combatant_results[combatant.combatant_id] = {
            "damage_dealt": combatant.total_damage_dealt, 
            "damage_taken": combatant.total_damage_taken, 
            "kills": combatant.kills, 
            "life_remaining": combatant.current_life, 
            "max_life": combatant.max_life, 
            "vitality_remaining": combatant.current_vitality, 
            "was_downed": combatant.was_downed, 
            "source_exile": combatant.source_exile, 
            "source_monster": combatant.source_monster, 
            "xp_earned": combatant.xp_earned_this_combat, 
            "leveled_up": combatant.level_up_pending, 
        }

        if combatant.team == CombatEnums.CombatantTeam.EXILES:
            if combatant.was_downed:
                result.downed_party.append(combatant)
            else:
                result.surviving_party.append(combatant)
        else:
            if not combatant.is_alive():
                result.defeated_monsters.append(combatant)

    return result







func get_exile_stats(exile_id: int) -> Dictionary:
    for cid in combatant_results:
        var entry: Dictionary = combatant_results[cid]
        var exile: ExileData = entry.get("source_exile")
        if exile and exile.id == exile_id:
            return entry
    return {}
