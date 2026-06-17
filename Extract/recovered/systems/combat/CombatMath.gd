class_name CombatMath
extends RefCounted









static func calculate_armour_reduction(armour_value: float, incoming_damage: float) -> float:
    if armour_value <= 0.0 or incoming_damage <= 0.0:
        return 0.0

    var ratio: = armour_value / incoming_damage
    var reduction: = ratio / (ratio + 10.0)
    return clampf(reduction, 0.0, 0.9)






static func roll_evasion(evasion_chance: float, rng: RandomNumberGenerator = null) -> String:
    var roll_1: = _randf_100(rng)
    var roll_2: = _randf_100(rng)

    if roll_1 < evasion_chance and roll_2 < evasion_chance:
        return "evaded"
    elif roll_1 < evasion_chance or roll_2 < evasion_chance:
        return "glancing"
    else:
        return "hit"





static func calculate_block(block_chance: float, block_amount: float, rng: RandomNumberGenerator = null) -> Dictionary:
    var roll: = _randf_100(rng)
    if roll < block_chance:
        return {"blocked": true, "amount": block_amount}
    return {"blocked": false, "amount": 0.0}





static func get_effective_resistance(resistance: float, cap: float) -> float:
    return minf(resistance, cap)





static func is_endurance_active(current_life: float, max_life: float, threshold_percent: float) -> bool:
    if max_life <= 0.0:
        return false
    return current_life <= max_life * (threshold_percent / 100.0)


static func apply_endurance(damage: float, endurance_percent: float) -> float:
    return damage * (1.0 - endurance_percent / 100.0)














static func calculate_shock_base_magnitude(damage: float, max_life: float) -> float:
    if max_life <= 0.0 or damage <= 0.0:
        return 0.0
    var damage_ratio: float = damage / max_life
    var curve_input: float = clampf(damage_ratio / GameSettings.SHOCK_REFERENCE_DAMAGE_PCT, 0.0, 1.0)
    return GameSettings.SHOCK_MAX_BASE_MAGNITUDE * pow(curve_input, GameSettings.SHOCK_CURVE_EXPONENT)

















static func calculate_shock_magnitude(damage: float, max_life: float, effect_more_pct: float) -> float:
    return calculate_shock_base_magnitude(damage, max_life) * (1.0 + effect_more_pct / 100.0)
















static func calculate_chill_base_magnitude(damage: float, max_life: float) -> float:
    if max_life <= 0.0 or damage <= 0.0:
        return 0.0
    var damage_ratio: float = damage / max_life
    var curve_input: float = clampf(damage_ratio / GameSettings.CHILL_REFERENCE_DAMAGE_PCT, 0.0, 1.0)
    return GameSettings.CHILL_MAX_BASE_MAGNITUDE * pow(curve_input, GameSettings.CHILL_CURVE_EXPONENT)

















static func calculate_chill_magnitude(damage: float, max_life: float, effect_more_pct: float) -> float:
    return calculate_chill_base_magnitude(damage, max_life) * (1.0 + effect_more_pct / 100.0)


















static func calculate_ignite_dps(
    fire_damage_post_mitigation: float, 
    ignite_effect_more_pct: float, 
    damage_over_time_more_pct: float, 
) -> float:
    if fire_damage_post_mitigation <= 0.0:
        return 0.0
    var base_dps: float = fire_damage_post_mitigation * GameSettings.IGNITE_BASE_DAMAGE_FRACTION
    var ailment_mult: float = 1.0 + ignite_effect_more_pct / 100.0
    var dot_mult: float = 1.0 + damage_over_time_more_pct / 100.0
    return base_dps * ailment_mult * dot_mult


















static func calculate_poison_dps(
    combined_phys_chaos_post_mitigation: float, 
    poison_effect_more_pct: float, 
    damage_over_time_more_pct: float, 
) -> float:
    if combined_phys_chaos_post_mitigation <= 0.0:
        return 0.0
    var base_dps: float = combined_phys_chaos_post_mitigation * GameSettings.POISON_BASE_DAMAGE_FRACTION
    var ailment_mult: float = 1.0 + poison_effect_more_pct / 100.0
    var dot_mult: float = 1.0 + damage_over_time_more_pct / 100.0
    return base_dps * ailment_mult * dot_mult





static func roll_second_wind(chance: float, rng: RandomNumberGenerator = null) -> bool:
    return _randf_100(rng) < chance


static func get_second_wind_heal(max_life: float, heal_percent: float) -> float:
    return max_life * (heal_percent / 100.0)



static func is_second_wind_eligible(life_before: float, life_after: float, max_life: float, threshold_percent: float) -> bool:
    if max_life <= 0.0:
        return false
    var threshold: = max_life * (threshold_percent / 100.0)

    return life_before > threshold and life_after <= threshold and life_after > 0.0





static func roll_crit(crit_chance: float, rng: RandomNumberGenerator = null) -> bool:
    return _randf_100(rng) < crit_chance


static func apply_crit_multiplier(damage: float, crit_multiplier_percent: float) -> float:
    return damage * (crit_multiplier_percent / 100.0)





static func _randf_100(rng: RandomNumberGenerator = null) -> float:
    if rng != null:
        return rng.randf() * 100.0
    return randf() * 100.0
