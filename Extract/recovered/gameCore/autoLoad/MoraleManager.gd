extends Node


enum MoraleChangeReason{

    MISSION_SUCCESS, 
    MISSION_BOREDOM_PENALTY, 
    MISSION_THRILLING_VICTORY, 
    SAFE_RETREAT, 
    RISKY_RETREAT, 


    REST_WITH_FOOD, 
    REST_WITHOUT_FOOD, 
    REST_AT_FULL_VITALITY, 


    RARE_MONSTER_KILL, 
    BOSS_KILL, 
    MORALE_DAMAGE, 


    CUSTOM_EVENT, 
    ITEM_EFFECT, 
    PASSIVE_EFFECT
}


class MoraleChangeRecord:
    var exile_id: int
    var amount: float
    var reason: MoraleChangeReason




    var tick_number: int
    var details: Dictionary = {}
    var final_morale: float

    func get_reason_text() -> String:
        match reason:
            MoraleChangeReason.MISSION_SUCCESS: return "Mission Success"
            MoraleChangeReason.MISSION_BOREDOM_PENALTY: return "Boredom"
            MoraleChangeReason.MISSION_THRILLING_VICTORY: return "Thrilling Victory"
            MoraleChangeReason.SAFE_RETREAT: return "Safe Retreat"
            MoraleChangeReason.RISKY_RETREAT: return "Risky Retreat"
            MoraleChangeReason.REST_WITH_FOOD: return "Rest (Well Fed)"
            MoraleChangeReason.REST_WITHOUT_FOOD: return "Rest (Hungry)"
            MoraleChangeReason.REST_AT_FULL_VITALITY: return "Full Vitality Rest"
            MoraleChangeReason.RARE_MONSTER_KILL: return "Rare Kill"
            MoraleChangeReason.BOSS_KILL: return "Boss Kill"
            MoraleChangeReason.MORALE_DAMAGE: return details.get("source", "Unknown")
            MoraleChangeReason.CUSTOM_EVENT: return details.get("description", "Event")
            MoraleChangeReason.ITEM_EFFECT: return "Item Effect"
            MoraleChangeReason.PASSIVE_EFFECT: return "Passive Effect"
            _: return "Unknown"


class ExileMoraleState:
    var current_morale: float = 100.0





    var ticks_at_zero_morale: int = 0
    var consecutive_rest_without_food: int = 0
    var recent_changes: Array = []

    func add_change_record(record: MoraleChangeRecord):
        recent_changes.append(record)

        if recent_changes.size() > 20:
            recent_changes.pop_front()


signal morale_changed(exile_id: int, old_value: float, new_value: float, change_amount: float, reason: String)
signal morale_state_changed(exile_id: int, state: String)
signal exile_leaving_warning(exile_id: int, leave_chance: float)
signal exile_left_guild(exile_id: int, reason: String)


var exile_morale_states: Dictionary = {}




var current_tick: int = 0






func _ready():

    pass


func _get_exile_state(exile_id: int) -> ExileMoraleState:
    if not exile_morale_states.has(exile_id):
        exile_morale_states[exile_id] = ExileMoraleState.new()
    return exile_morale_states[exile_id]


func change_morale(exile_data: ExileData, base_amount: float, reason: MoraleChangeReason, details: Dictionary = {}):
    if not exile_data:
        return

    var old_morale = exile_data.current_stats.morale
    var state = _get_exile_state(exile_data.id)


    var final_amount = base_amount

    if base_amount > 0:

        var gain_modifier = 1.0 + (exile_data.current_stats.morale_gain / 100.0)
        final_amount *= gain_modifier
    else:

        var resistance = exile_data.current_stats.morale_loss_resistance / 100.0
        final_amount *= (1.0 - resistance)


    var new_morale = old_morale + final_amount
    exile_data.current_stats.morale = new_morale
    exile_data.current_morale = exile_data.current_stats.morale

    GameState.exile_updated.emit(exile_data)


    var record = MoraleChangeRecord.new()
    record.exile_id = exile_data.id
    record.amount = final_amount
    record.reason = reason
    record.tick_number = current_tick
    record.details = details
    record.final_morale = exile_data.current_stats.morale
    state.add_change_record(record)


    morale_changed.emit(exile_data.id, old_morale, exile_data.current_stats.morale, final_amount, record.get_reason_text())


    _check_morale_state_change(exile_data.id, old_morale, exile_data.current_stats.morale)


func apply_mission_victory(exile_data: ExileData, mission_level: int, damage_taken_percent: float):
    if not exile_data:
        return

    var morale_change = GameSettings.MORALE_MISSION_SUCCESS_BASE
    var details = {"mission_level": mission_level}




    var level_diff: int = exile_data.level - mission_level
    if level_diff >= 2:
        var boredom: float = max(float( - (level_diff - 1)), GameSettings.MORALE_BOREDOM_PENALTY_CAP)
        morale_change += boredom
        details["boredom_penalty"] = boredom





    if damage_taken_percent >= GameSettings.MORALE_THRILLING_VICTORY_DAMAGE_PCT:
        details["thrilling"] = true
        change_morale(exile_data, GameSettings.MORALE_THRILLING_VICTORY_BONUS, MoraleChangeReason.MISSION_THRILLING_VICTORY, details)


    morale_change += exile_data.current_stats.victory_morale_bonus

    change_morale(exile_data, morale_change, MoraleChangeReason.MISSION_SUCCESS, details)

func apply_retreat_penalty(exile_data: ExileData, is_risky: bool):
    var penalty = GameSettings.MORALE_RISKY_RETREAT_PENALTY if is_risky else GameSettings.MORALE_SAFE_RETREAT_PENALTY
    var reason = MoraleChangeReason.RISKY_RETREAT if is_risky else MoraleChangeReason.SAFE_RETREAT
    change_morale(exile_data, penalty, reason)






func apply_rest_morale(exile_data: ExileData, ration: int, is_at_full_vitality: bool):
    if not exile_data:
        return
    var state = _get_exile_state(exile_data.id)

    var morale_change: = 0.0
    var details = {}
    var has_food: = ration != QuartermasterManager.RATION_NONE

    if has_food:
        state.consecutive_rest_without_food = 0
        morale_change = QuartermasterManager.RATION_REST_MORALE[ration]
        morale_change += exile_data.current_stats.well_fed_rest_morale_bonus
        details["well_fed"] = true
        details["ration"] = ration
    else:
        state.consecutive_rest_without_food += 1
        morale_change = GameSettings.MORALE_REST_WITHOUT_FOOD_BASE * state.consecutive_rest_without_food
        details["hungry_days"] = state.consecutive_rest_without_food


    if is_at_full_vitality:
        morale_change += GameSettings.MORALE_REST_FULL_VITALITY_BONUS
        details["full_vitality"] = true
        if has_food:
            change_morale(exile_data, GameSettings.MORALE_REST_FULL_VITALITY_BONUS, MoraleChangeReason.REST_AT_FULL_VITALITY, details)

    var reason = MoraleChangeReason.REST_WITH_FOOD if has_food else MoraleChangeReason.REST_WITHOUT_FOOD
    change_morale(exile_data, morale_change, reason, details)




func get_hungry_stacks(exile_data: ExileData) -> int:
    if exile_data == null:
        return 0
    if not exile_morale_states.has(exile_data.id):
        return 0
    return exile_morale_states[exile_data.id].consecutive_rest_without_food

func apply_combat_kill(exile_data: ExileData, monster_type: String, monster_level: int):
    if not exile_data or monster_level < exile_data.level:
        return

    var details = {"monster": monster_type, "level": monster_level}

    if monster_type == "boss":
        change_morale(exile_data, GameSettings.MORALE_BOSS_KILL_BONUS, MoraleChangeReason.BOSS_KILL, details)
    elif monster_type == "rare":
        change_morale(exile_data, GameSettings.MORALE_RARE_KILL_BONUS, MoraleChangeReason.RARE_MONSTER_KILL, details)

func apply_morale_damage(exile_data: ExileData, damage: float, source: String):
    change_morale(exile_data, - damage, MoraleChangeReason.MORALE_DAMAGE, {"source": source})

func apply_custom_event(exile_data: ExileData, amount: float, event_description: String):
    change_morale(exile_data, amount, MoraleChangeReason.CUSTOM_EVENT, {"description": event_description})







func get_morale_percent(exile_data: ExileData) -> float:
    if exile_data == null:
        return 0.0
    var max_m: float = exile_data.current_stats.max_morale
    if max_m <= 0.0:
        return 0.0
    return (exile_data.current_stats.morale / max_m) * 100.0






func get_morale_combat_modifiers(exile_data: ExileData) -> Dictionary:
    var modifiers = {
        "damage_dealt_more": 0.0, 
        "damage_taken_less": 0.0, 
        "experience_more": 0.0
    }
    if exile_data == null:
        return modifiers

    if is_morale_high(exile_data):
        modifiers.damage_dealt_more = GameSettings.MORALE_HIGH_DAMAGE_DEALT_MORE
        modifiers.damage_taken_less = GameSettings.MORALE_HIGH_DAMAGE_TAKEN_LESS
        modifiers.experience_more = GameSettings.MORALE_HIGH_XP_MORE
    elif is_morale_low(exile_data):


        modifiers.damage_dealt_more = - GameSettings.MORALE_HIGH_DAMAGE_DEALT_MORE
        modifiers.damage_taken_less = - GameSettings.MORALE_HIGH_DAMAGE_TAKEN_LESS
        modifiers.experience_more = - GameSettings.MORALE_HIGH_XP_MORE

    return modifiers

func is_morale_high(exile_data: ExileData) -> bool:
    return exile_data != null and get_morale_percent(exile_data) >= GameSettings.MORALE_HIGH_THRESHOLD_PERCENT

func is_morale_low(exile_data: ExileData) -> bool:
    return exile_data != null and get_morale_percent(exile_data) <= GameSettings.MORALE_LOW_THRESHOLD_PERCENT

func is_morale_broken(exile_data: ExileData) -> bool:
    return exile_data and exile_data.current_stats.morale <= 0.0

func get_leave_chance(exile_id: int) -> float:
    var state = _get_exile_state(exile_id)
    if state.ticks_at_zero_morale <= 0:
        return 0.0




    var ramp: float = float(state.ticks_at_zero_morale - 1) * GameSettings.MORALE_LEAVE_CHANCE_PER_TURN
    return min(ramp, GameSettings.MORALE_LEAVE_CHANCE_CAP)

func can_exile_leave(exile_data: ExileData) -> bool:
    if not exile_data:
        return false


    return not SpecialEffectManager.has_special_effect(exile_data, "unbreakable")

func get_morale_history(exile_id: int, count: int = 10) -> Array:
    var state = _get_exile_state(exile_id)
    var history = state.recent_changes.duplicate()


    if history.size() > count:
        return history.slice( - count)
    return history




func process_end_turn(all_exiles: Array = []):
    current_tick += 1

    for exile_data in all_exiles:
        if not exile_data or exile_data.status == "dead":
            continue

        var state = _get_exile_state(exile_data.id)


        if exile_data.current_stats.morale_per_turn != 0:
            change_morale(exile_data, exile_data.current_stats.morale_per_turn, 
                         MoraleChangeReason.PASSIVE_EFFECT, {"source": "Morale per Turn"})





        if is_morale_broken(exile_data):
            state.ticks_at_zero_morale += 1
            if GameSettings.MORALE_BROKEN_LEAVE_ENABLED and can_exile_leave(exile_data):
                var leave_chance = get_leave_chance(exile_data.id)
                if leave_chance > 0:
                    exile_leaving_warning.emit(exile_data.id, leave_chance)

                    if randf() * 100.0 < leave_chance:
                        _process_exile_leaving(exile_data)
        else:
            state.ticks_at_zero_morale = 0


func _check_morale_state_change(exile_id: int, old_morale: float, new_morale: float):



    var max_m: float = 100.0
    var exile: ExileData = GameState.get_exile_by_id(exile_id)
    if exile != null and exile.current_stats != null:
        max_m = exile.current_stats.max_morale
    var old_state = _get_morale_state_string(old_morale, max_m)
    var new_state = _get_morale_state_string(new_morale, max_m)

    if old_state != new_state:
        morale_state_changed.emit(exile_id, new_state)




func _get_morale_state_string(morale: float, max_morale: float) -> String:
    if morale <= 0.0:
        return "broken"
    if max_morale <= 0.0:
        return "normal"
    var pct: float = (morale / max_morale) * 100.0
    if pct >= GameSettings.MORALE_HIGH_THRESHOLD_PERCENT:
        return "high"
    elif pct <= GameSettings.MORALE_LOW_THRESHOLD_PERCENT:
        return "low"
    else:
        return "normal"

func _process_exile_leaving(exile_data: ExileData):


    exile_left_guild.emit(exile_data.id, "Broken morale")
