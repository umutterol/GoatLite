extends Node

















const RATION_NONE: = 0
const RATION_FULL: = 1
const RATION_DOUBLE: = 2
const RATION_NAMES: = ["None", "Full", "Double"]


const RATION_COST: = [0, 1, 2]







const RATION_REST_MORALE: = [0.0, 2.0, 3.0]

signal ration_changed(exile_id: int, new_ration: int)






func get_ration(exile: ExileData) -> int:
    if exile == null:
        return RATION_FULL
    return clampi(exile.food_ration, RATION_NONE, RATION_DOUBLE)


func get_ration_name(ration: int) -> String:
    if ration < 0 or ration >= RATION_NAMES.size():
        return "Unknown"
    return RATION_NAMES[ration]


func cost_for(exile: ExileData) -> int:
    return RATION_COST[get_ration(exile)]


func vitality_bonus_pct(exile: ExileData) -> float:
    return GameSettings.RATION_VITALITY_BONUS[get_ration(exile)]


func rest_morale_bonus(exile: ExileData) -> float:
    return RATION_REST_MORALE[get_ration(exile)]












func set_ration(exile: ExileData, value: int, manual: bool = true) -> void :
    if exile == null:
        return
    var clamped: int = clampi(value, RATION_NONE, RATION_DOUBLE)
    var ration_unchanged: bool = exile.food_ration == clamped
    exile.food_ration = clamped
    exile.food_ration_locked = manual
    if ration_unchanged:
        return
    ration_changed.emit(exile.id, clamped)







func _resting_exiles() -> Array[ExileData]:
    var result: Array[ExileData] = []
    for exile in GameState.get_living_exiles():
        if exile.status == "idle" or exile.status == "recovering":
            result.append(exile)
    return result



func total_food_cost() -> int:
    var total: = 0
    for exile in _resting_exiles():
        total += cost_for(exile)
    return total


func can_afford_current() -> bool:
    return GameState.food >= total_food_cost()










func rebalance_to_fit_food() -> void :
    var resting: = _resting_exiles()


    if not can_afford_current():
        var doubles: Array = resting.filter( func(e): return e.food_ration == RATION_DOUBLE)
        doubles.sort_custom( func(a, b): return a.id > b.id)
        for exile in doubles:
            if can_afford_current():
                break
            set_ration(exile, RATION_FULL, false)


    if not can_afford_current():
        var fulls: Array = resting.filter( func(e): return e.food_ration == RATION_FULL)
        fulls.sort_custom( func(a, b):
            if a.status != b.status:
                return a.status == "idle"
            return a.id > b.id
        )
        for exile in fulls:
            if can_afford_current():
                break
            set_ration(exile, RATION_NONE, false)





    var nones: Array = resting.filter( func(e):
        return e.food_ration == RATION_NONE and not e.food_ration_locked
    )
    nones.sort_custom( func(a, b): return a.id < b.id)
    var upgrade_cost: int = RATION_COST[RATION_FULL] - RATION_COST[RATION_NONE]
    for exile in nones:
        if GameState.food < total_food_cost() + upgrade_cost:
            break
        set_ration(exile, RATION_FULL, false)
