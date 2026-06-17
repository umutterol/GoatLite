class_name CombatResultProcessor
extends RefCounted
















static func process(result: CombatResultData, party: Array[ExileData]) -> void :
    if not result:
        push_warning("CombatResultProcessor: null result")
        return
    _writeback_hp(result, party)
    _apply_per_kill_morale(result)
    _apply_brutal_hit_morale_penalties(result, party)










static func _writeback_hp(result: CombatResultData, party: Array[ExileData]) -> void :
    for exile in party:
        var stats: Dictionary = result.get_exile_stats(exile.id)
        if stats.is_empty():
            continue
        exile.current_life = stats.get("life_remaining", exile.current_life)
        exile.current_vitality = stats.get("vitality_remaining", exile.current_vitality)




        if exile.current_stats != null:
            exile.current_life = min(exile.current_life, exile.current_stats.life)
            exile.current_vitality = min(exile.current_vitality, exile.current_stats.max_vitality)







static func _apply_per_kill_morale(result: CombatResultData) -> void :
    for event in result.event_log:
        if event.event_type != CombatEnums.CombatEventType.DEATH:
            continue
        var killer_id: int = event.data.get("killer_id", -1)
        var victim_id: int = event.data.get("combatant_id", -1)
        if killer_id < 0 or victim_id < 0:
            continue
        var killer_entry: Dictionary = result.combatant_results.get(killer_id, {})
        var victim_entry: Dictionary = result.combatant_results.get(victim_id, {})
        var killer_exile: ExileData = killer_entry.get("source_exile")
        var victim_monster: MonsterData = victim_entry.get("source_monster")
        if not killer_exile or not victim_monster:
            continue
        var monster_type: String = _classify_monster(victim_monster)
        MoraleManager.apply_combat_kill(killer_exile, monster_type, victim_monster.base_level)




static func _classify_monster(monster: MonsterData) -> String:
    if monster.is_unique:
        return "boss"
    return "normal"









static func _apply_brutal_hit_morale_penalties(result: CombatResultData, party: Array[ExileData]) -> void :

    var totals: Dictionary = {}
    for event in result.event_log:
        if event.event_type != CombatEnums.CombatEventType.MORALE_PENALTY:
            continue
        var def_id: int = event.data.get("defender_id", -1)
        if def_id < 0:
            continue
        var amount: int = int(event.data.get("amount", 0))
        totals[def_id] = totals.get(def_id, 0) + amount


    for def_id in totals.keys():
        var entry: Dictionary = result.combatant_results.get(def_id, {})
        var exile: ExileData = entry.get("source_exile")
        if exile == null:
            continue
        var total_lost: int = int(totals[def_id])
        if total_lost <= 0:
            continue



        var is_in_party: bool = false
        for p in party:
            if p.id == exile.id:
                is_in_party = true
                break
        if not is_in_party:
            continue
        MoraleManager.apply_morale_damage(exile, float(total_lost), "Brutal Combat Hits")
