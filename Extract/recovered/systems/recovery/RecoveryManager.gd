class_name RecoveryManager
extends RefCounted


































static func daily_rest_idle(exile: ExileData) -> void :
    if not exile or exile.status != "idle":
        return
    _regen_vitality(exile, 0.0)


    var max_life: float = exile.current_stats.life
    var life_deficit: float = maxf(max_life - exile.current_life, 0.0)
    if life_deficit > 0.0 and exile.current_vitality > 0.0:
        var vit_needed: float = life_deficit / GameSettings.LIFE_PER_VITALITY
        var vit_spent: float = minf(vit_needed, exile.current_vitality)
        exile.current_vitality = maxf(exile.current_vitality - vit_spent, 0.0)
        exile.current_life = minf(exile.current_life + vit_spent * GameSettings.LIFE_PER_VITALITY, max_life)
        GameState.exile_updated.emit(exile)









static func daily_rest_recovering(exile: ExileData) -> void :
    if not exile or exile.status != "recovering":
        return


    _regen_vitality(exile, GameSettings.RECOVERY_VITALITY_REGEN_BONUS_PCT)


    var max_life: float = exile.current_stats.life
    var life_deficit: float = maxf(max_life - exile.current_life, 0.0)
    if life_deficit > 0.0 and exile.current_vitality > 0.0:
        var vit_needed: float = life_deficit / GameSettings.LIFE_PER_VITALITY
        var vit_spent: float = minf(vit_needed, exile.current_vitality)
        exile.current_vitality = maxf(exile.current_vitality - vit_spent, 0.0)
        exile.current_life = minf(exile.current_life + vit_spent * GameSettings.LIFE_PER_VITALITY, max_life)


    if exile.current_life >= max_life:
        exile.status = "idle"

    GameState.exile_updated.emit(exile)
















static func _regen_vitality(exile: ExileData, extra_bonus_pct: float) -> void :
    var max_vit: float = exile.current_stats.max_vitality




    var ration: int = QuartermasterManager.get_ration(exile)
    var cost: int = QuartermasterManager.RATION_COST[ration]
    if cost > 0 and GameState.food < cost:
        ration = QuartermasterManager.RATION_NONE
        cost = 0
    if cost > 0:
        GameState.spend_food(cost)



    if exile.current_vitality < max_vit:
        var ration_bonus: float = GameSettings.RATION_VITALITY_BONUS[ration]
        var regen_pct: float = GameSettings.REST_VITALITY_REGEN_PCT + extra_bonus_pct + ration_bonus
        var regen_amount: float = max_vit * regen_pct
        exile.current_vitality = minf(exile.current_vitality + regen_amount, max_vit)



    var at_full: bool = exile.current_vitality >= max_vit
    MoraleManager.apply_rest_morale(exile, ration, at_full)
