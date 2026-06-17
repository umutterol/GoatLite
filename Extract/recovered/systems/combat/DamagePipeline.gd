class_name DamagePipeline
extends RefCounted









const MELEE_ATTACK_RANGE_THRESHOLD: float = 3.0












const SHOCK_EFFECT: StatusEffect = preload("res://systems/combat/statusEffects/shock.tres")
const CHILL_EFFECT: StatusEffect = preload("res://systems/combat/statusEffects/chill.tres")
const IGNITE_EFFECT: StatusEffect = preload("res://systems/combat/statusEffects/ignite.tres")




const IMPALE_AILMENT_ID: StringName = &"impale"




const POISON_AILMENT_ID: StringName = &"poison"
const POISON_DISPLAY_NAME: String = "Poison"



static func _damage_type_name(type: StatEnums.DamageType) -> String:
    match type:
        StatEnums.DamageType.PHYSICAL: return "physical"
        StatEnums.DamageType.FIRE: return "fire"
        StatEnums.DamageType.COLD: return "cold"
        StatEnums.DamageType.LIGHTNING: return "lightning"
        StatEnums.DamageType.CHAOS: return "chaos"
        _: return ""










static func resolve_attack(
    attacker: CombatantData, 
    defender: CombatantData, 
    tick: float, 
    rng: RandomNumberGenerator, 
    ability: MonsterAbility = null
) -> Dictionary:
    var events: Array[CombatEvent] = []


    var raw: = _roll_raw_damage(attacker, rng)
    var total_raw: = _sum_damage(raw)

    if total_raw <= 0.0:
        return {"events": events, "killed": false}







    if ability != null:
        raw = _apply_ability_scaling_and_conversion(raw, ability)
        total_raw = _sum_damage(raw)


        if total_raw <= 0.0:
            return {"events": events, "killed": false}





    var morale_dmg_more: float = attacker.morale_combat_modifiers.get("damage_dealt_more", 0.0)
    if morale_dmg_more != 0.0:
        var dmg_mult: float = 1.0 + morale_dmg_more / 100.0
        for type in StatEnums.DamageType.values():
            raw[type] *= dmg_mult









    var status_dmg_more: float = attacker.get_aggregate_modifier("damage_dealt_more_pct")
    if status_dmg_more != 0.0:
        var status_mult: float = 1.0 + status_dmg_more / 100.0
        for type in StatEnums.DamageType.values():
            raw[type] *= status_mult




    var base_per_type: Dictionary = raw.duplicate()


    var is_crit: = CombatMath.roll_crit(attacker.stats.critical_chance, rng)
    if is_crit:
        for type in StatEnums.DamageType.values():
            raw[type] = CombatMath.apply_crit_multiplier(raw[type], attacker.stats.critical_multiplier)
        events.append(CombatEvent.create(tick, CombatEnums.CombatEventType.CRITICAL_STRIKE, {
            "attacker_id": attacker.combatant_id, 
            "defender_id": defender.combatant_id, 
        }))




    var evasion_result: = CombatMath.roll_evasion(defender.stats.evasion, rng)

    if evasion_result == "evaded":
        events.append(CombatEvent.create(tick, CombatEnums.CombatEventType.EVASION, {
            "attacker_id": attacker.combatant_id, 
            "defender_id": defender.combatant_id, 
        }))
        return {"events": events, "killed": false}

    if evasion_result == "glancing":
        for type in StatEnums.DamageType.values():
            raw[type] *= 0.5
        events.append(CombatEvent.create(tick, CombatEnums.CombatEventType.GLANCING_BLOW, {
            "attacker_id": attacker.combatant_id, 
            "defender_id": defender.combatant_id, 
        }))













    var impale_bonus_by_type: Dictionary = {"physical": 0.0, "fire": 0.0, "cold": 0.0, "lightning": 0.0, "chaos": 0.0}
    var impale_stacks_consumed: int = 0





    var deferred_post_damage_events: Array[CombatEvent] = []
    if defender.has_impales():
        _consume_impales_for_hit(attacker, defender, raw, impale_bonus_by_type, tick, deferred_post_damage_events)
        impale_stacks_consumed = int(impale_bonus_by_type.get("_count", 0))


        impale_bonus_by_type.erase("_count")







    var raw_incoming: Dictionary = raw.duplicate()






    var mitigation_breakdown: Dictionary = {}


    var snap_pre_block: Dictionary = raw.duplicate()
    var block_result: = CombatMath.calculate_block(
        defender.stats.block_chance, defender.stats.block_amount, rng
    )
    var blocked_amount: = 0.0
    if block_result["blocked"]:

        blocked_amount = _apply_block(raw, block_result["amount"])
        events.append(CombatEvent.create(tick, CombatEnums.CombatEventType.BLOCK, {
            "attacker_id": attacker.combatant_id, 
            "defender_id": defender.combatant_id, 
            "blocked_amount": blocked_amount, 
        }))
    mitigation_breakdown["block"] = _per_type_diff(snap_pre_block, raw)


    var snap_pre_armour: Dictionary = raw.duplicate()
    if raw[StatEnums.DamageType.PHYSICAL] > 0.0:
        var reduction: = CombatMath.calculate_armour_reduction(defender.stats.armour, raw[StatEnums.DamageType.PHYSICAL])
        raw[StatEnums.DamageType.PHYSICAL] *= (1.0 - reduction)
    mitigation_breakdown["armour"] = _per_type_diff(snap_pre_armour, raw)


    var snap_pre_resist: Dictionary = raw.duplicate()
    for type in [StatEnums.DamageType.FIRE, StatEnums.DamageType.COLD, StatEnums.DamageType.LIGHTNING, StatEnums.DamageType.CHAOS]:
        if raw[type] > 0.0:
            var type_name: = _damage_type_name(type)
            var effective_res: = CombatMath.get_effective_resistance(
                defender.get_resistance(type_name), 
                defender.get_resistance_cap(type_name)
            )
            raw[type] *= (1.0 - effective_res / 100.0)
    mitigation_breakdown["resist"] = _per_type_diff(snap_pre_resist, raw)


    var snap_pre_endurance: Dictionary = raw.duplicate()
    var endurance_applied: = false
    if CombatMath.is_endurance_active(
        defender.current_life, defender.max_life, defender.stats.endurance_threshold
    ):
        for type in StatEnums.DamageType.values():
            raw[type] = CombatMath.apply_endurance(raw[type], defender.stats.endurance)
        endurance_applied = true
        events.append(CombatEvent.create(tick, CombatEnums.CombatEventType.ENDURANCE, {
            "defender_id": defender.combatant_id, 
            "endurance_percent": defender.stats.endurance, 
        }))
    mitigation_breakdown["endurance"] = _per_type_diff(snap_pre_endurance, raw)






    var snap_pre_morale: Dictionary = raw.duplicate()
    var morale_dmg_less: float = defender.morale_combat_modifiers.get("damage_taken_less", 0.0)
    if morale_dmg_less != 0.0:
        var taken_mult: float = 1.0 - morale_dmg_less / 100.0
        for type in StatEnums.DamageType.values():
            raw[type] *= taken_mult
    mitigation_breakdown["morale_less"] = _per_type_diff(snap_pre_morale, raw)





    var pre_status_per_type: Dictionary = raw.duplicate()










    var status_dmg_taken_more: float = defender.get_aggregate_modifier("damage_taken_more_pct")
    if status_dmg_taken_more != 0.0:
        var status_taken_mult: float = 1.0 + status_dmg_taken_more / 100.0
        for type in StatEnums.DamageType.values():
            raw[type] *= status_taken_mult



    var total_final: = 0.0
    var shield_damage: = 0.0
    var life_damage: = 0.0


    var non_chaos: float = raw[StatEnums.DamageType.PHYSICAL] + raw[StatEnums.DamageType.FIRE] + raw[StatEnums.DamageType.COLD] + raw[StatEnums.DamageType.LIGHTNING]
    if non_chaos > 0.0 and defender.current_energy_shield > 0.0:
        shield_damage = minf(non_chaos, defender.current_energy_shield)
        defender.current_energy_shield -= shield_damage
        non_chaos -= shield_damage


    life_damage = non_chaos + raw[StatEnums.DamageType.CHAOS]
    total_final = shield_damage + life_damage

    var life_before: = defender.current_life
    defender.current_life = maxf(defender.current_life - life_damage, 0.0)


    attacker.total_damage_dealt += total_final
    defender.total_damage_taken += total_final




    if attacker.combat_behavior and attacker.combat_behavior.attack_range <= MELEE_ATTACK_RANGE_THRESHOLD:
        defender.last_melee_hit_tick = tick


        defender.last_melee_attacker_was_faster = attacker.get_effective_movement_speed() >= defender.get_effective_movement_speed()





    if total_final > 0.0:
        attacker.sticky_target_until = tick + attacker.combat_behavior.get_tactical().sticky_target_duration




    if total_final > 0.0 and attacker.is_alive():
        _apply_attacker_heal(attacker, total_final, tick, events)





    var defender_amplifiers: Array = _collect_damage_taken_amplifiers(defender)









    events.append(CombatEvent.create(tick, CombatEnums.CombatEventType.DAMAGE_DEALT, {
        "attacker_id": attacker.combatant_id, 
        "defender_id": defender.combatant_id, 



        "ability": ability, 
        "physical": raw[StatEnums.DamageType.PHYSICAL], 
        "fire": raw[StatEnums.DamageType.FIRE], 
        "cold": raw[StatEnums.DamageType.COLD], 
        "lightning": raw[StatEnums.DamageType.LIGHTNING], 
        "chaos": raw[StatEnums.DamageType.CHAOS], 
        "raw_physical": raw_incoming[StatEnums.DamageType.PHYSICAL], 
        "raw_fire": raw_incoming[StatEnums.DamageType.FIRE], 
        "raw_cold": raw_incoming[StatEnums.DamageType.COLD], 
        "raw_lightning": raw_incoming[StatEnums.DamageType.LIGHTNING], 
        "raw_chaos": raw_incoming[StatEnums.DamageType.CHAOS], 
        "base_physical": base_per_type[StatEnums.DamageType.PHYSICAL], 
        "base_fire": base_per_type[StatEnums.DamageType.FIRE], 
        "base_cold": base_per_type[StatEnums.DamageType.COLD], 
        "base_lightning": base_per_type[StatEnums.DamageType.LIGHTNING], 
        "base_chaos": base_per_type[StatEnums.DamageType.CHAOS], 
        "pre_status_physical": pre_status_per_type[StatEnums.DamageType.PHYSICAL], 
        "pre_status_fire": pre_status_per_type[StatEnums.DamageType.FIRE], 
        "pre_status_cold": pre_status_per_type[StatEnums.DamageType.COLD], 
        "pre_status_lightning": pre_status_per_type[StatEnums.DamageType.LIGHTNING], 
        "pre_status_chaos": pre_status_per_type[StatEnums.DamageType.CHAOS], 
        "status_taken_more_pct": status_dmg_taken_more, 
        "damage_taken_amplifiers": defender_amplifiers, 



        "impale_bonus_by_type": impale_bonus_by_type, 
        "impale_stacks_consumed": impale_stacks_consumed, 







        "mitigation_breakdown": mitigation_breakdown, 
        "blocked_amount": blocked_amount, 
        "endurance_percent": defender.stats.endurance if endurance_applied else 0.0, 
        "shield_absorbed": shield_damage, 
        "total": total_final, 
        "is_crit": is_crit, 
        "crit_multiplier": attacker.stats.critical_multiplier, 
        "is_glancing": evasion_result == "glancing", 
        "endurance_active": endurance_applied, 
    }))







    if not deferred_post_damage_events.is_empty():
        events.append_array(deferred_post_damage_events)











    if defender.source_exile != null and total_final > 0.0:
        _apply_brutal_hit_morale_penalties(attacker, defender, raw, total_final, is_crit, tick, events)








    if defender.is_alive() and defender.current_life > 0.0:
        _try_apply_shock(attacker, defender, raw[StatEnums.DamageType.LIGHTNING], is_crit, tick, rng, events)



        _try_apply_chill(attacker, defender, raw[StatEnums.DamageType.COLD], tick, events)



        _try_apply_ignite(attacker, defender, raw[StatEnums.DamageType.FIRE], is_crit, tick, rng, events)









        _try_apply_impale(attacker, defender, raw[StatEnums.DamageType.PHYSICAL], tick, rng, events)







        var poison_input: float = raw[StatEnums.DamageType.PHYSICAL] + raw[StatEnums.DamageType.CHAOS]
        _try_apply_poison(attacker, defender, poison_input, is_crit, tick, rng, events)


    if defender.source_exile != null and CombatMath.is_second_wind_eligible(
        life_before, defender.current_life, 
        defender.max_life, defender.stats.second_wind_threshold
    ):
        if not defender.second_wind_triggered:
            if CombatMath.roll_second_wind(defender.stats.second_wind_chance, rng):
                var heal: = CombatMath.get_second_wind_heal(
                    defender.max_life, defender.stats.second_wind_amount
                )
                defender.current_life = minf(defender.current_life + heal, defender.max_life)
                defender.second_wind_triggered = true
                events.append(CombatEvent.create(tick, CombatEnums.CombatEventType.SECOND_WIND, {
                    "combatant_id": defender.combatant_id, 
                    "healed_amount": heal, 
                    "new_life": defender.current_life, 
                }))


    var killed: = false
    if defender.current_life <= 0.0:
        killed = true

        if defender.source_exile != null:
            defender.state = CombatEnums.CombatantState.DOWNED
            defender.was_downed = true
            events.append(CombatEvent.create(tick, CombatEnums.CombatEventType.DOWNED, {
                "combatant_id": defender.combatant_id, 
                "killer_id": attacker.combatant_id, 
            }))
        else:
            defender.state = CombatEnums.CombatantState.DEAD
            events.append(CombatEvent.create(tick, CombatEnums.CombatEventType.DEATH, {
                "combatant_id": defender.combatant_id, 
                "killer_id": attacker.combatant_id, 
            }))
        attacker.kills += 1

    return {"events": events, "killed": killed}










static func _apply_attacker_heal(
    attacker: CombatantData, 
    damage_dealt: float, 
    tick: float, 
    events: Array[CombatEvent]
) -> void :
    if attacker.current_life >= attacker.max_life:
        return


    var leech_pct: float = attacker.stats.life_leech
    if leech_pct > 0.0:
        var leech_amount: float = damage_dealt * (leech_pct / 100.0)
        var actual_leech: float = attacker.apply_combat_heal(leech_amount)
        if actual_leech > 0.0:
            events.append(CombatEvent.create(tick, CombatEnums.CombatEventType.LIFE_LEECH, {
                "combatant_id": attacker.combatant_id, 
                "amount": actual_leech, 
            }))


    var gain_amount: float = attacker.stats.life_gain_on_hit
    if gain_amount > 0.0:
        var actual_gain: float = attacker.apply_combat_heal(gain_amount)
        if actual_gain > 0.0:
            events.append(CombatEvent.create(tick, CombatEnums.CombatEventType.LIFE_GAIN_ON_HIT, {
                "combatant_id": attacker.combatant_id, 
                "amount": actual_gain, 
            }))

















static func _apply_ability_scaling_and_conversion(raw: Dictionary, ability: MonsterAbility) -> Dictionary:

    var scaled: Dictionary = raw.duplicate()


    if not is_equal_approx(ability.damage_scaling, 1.0):
        for type in StatEnums.DamageType.values():
            scaled[type] *= ability.damage_scaling


    if not ability.has_conversion():
        return scaled

    var ratio_sum: float = ability.convert_to_physical\
+ ability.convert_to_fire\
+ ability.convert_to_cold\
+ ability.convert_to_lightning\
+ ability.convert_to_chaos


    if ratio_sum <= 0.0:
        return scaled


    var pool: float = _sum_damage(scaled)
    var converted: Dictionary = {
        StatEnums.DamageType.PHYSICAL: pool * (ability.convert_to_physical / ratio_sum), 
        StatEnums.DamageType.FIRE: pool * (ability.convert_to_fire / ratio_sum), 
        StatEnums.DamageType.COLD: pool * (ability.convert_to_cold / ratio_sum), 
        StatEnums.DamageType.LIGHTNING: pool * (ability.convert_to_lightning / ratio_sum), 
        StatEnums.DamageType.CHAOS: pool * (ability.convert_to_chaos / ratio_sum), 
    }
    return converted



static func _roll_raw_damage(attacker: CombatantData, rng: RandomNumberGenerator) -> Dictionary:
    var result: = {}
    for type in StatEnums.DamageType.values():
        var stat_name: = _damage_type_name(type) + "_damage"
        var range_vec: Vector2 = attacker.stats.get(stat_name)
        if range_vec == null or range_vec == Vector2.ZERO:
            result[type] = 0.0
        else:
            result[type] = rng.randf_range(range_vec.x, range_vec.y)
    return result




static func _apply_block(damage: Dictionary, block_amount: float) -> float:
    var total: = _sum_damage(damage)
    if total <= 0.0:
        return 0.0

    var actual_block: = minf(block_amount, total)

    for type in StatEnums.DamageType.values():
        if damage[type] > 0.0:
            var proportion: float = damage[type] / total
            damage[type] = maxf(damage[type] - actual_block * proportion, 0.0)
    return actual_block



static func _sum_damage(damage: Dictionary) -> float:
    var total: = 0.0
    for type in StatEnums.DamageType.values():
        total += damage[type]
    return total






static func _per_type_diff(before: Dictionary, after: Dictionary) -> Dictionary:
    return {
        "physical": before[StatEnums.DamageType.PHYSICAL] - after[StatEnums.DamageType.PHYSICAL], 
        "fire": before[StatEnums.DamageType.FIRE] - after[StatEnums.DamageType.FIRE], 
        "cold": before[StatEnums.DamageType.COLD] - after[StatEnums.DamageType.COLD], 
        "lightning": before[StatEnums.DamageType.LIGHTNING] - after[StatEnums.DamageType.LIGHTNING], 
        "chaos": before[StatEnums.DamageType.CHAOS] - after[StatEnums.DamageType.CHAOS], 
    }


















static func _morale_penalty_tier(life_pct: float) -> int:
    if life_pct < GameSettings.MORALE_BRUTAL_HIT_THRESHOLD:
        return 0



    var bucket: float = GameSettings.MORALE_BRUTAL_HIT_BUCKET
    if bucket <= 0.0:
        return GameSettings.MORALE_BRUTAL_HIT_PENALTY_MAX
    var tier: int = int(floor(life_pct / bucket))
    return clampi(tier, 0, GameSettings.MORALE_BRUTAL_HIT_PENALTY_MAX)








static func _apply_brutal_hit_morale_penalties(
    attacker: CombatantData, 
    defender: CombatantData, 
    raw: Dictionary, 
    total_final: float, 
    is_crit: bool, 
    tick: float, 
    events: Array[CombatEvent], 
) -> void :

    var max_life_safe: float = maxf(defender.max_life, 1.0)



    var per_tier: int = GameSettings.MORALE_BRUTAL_HIT_PENALTY_PER_TIER


    if is_crit:
        var crit_life_pct: float = total_final / max_life_safe
        var crit_tier: int = _morale_penalty_tier(crit_life_pct)
        if crit_tier > 0:
            _emit_morale_penalty(attacker, defender, crit_tier * per_tier, "crit", crit_life_pct, tick, events)






    var chaos_final: float = raw[StatEnums.DamageType.CHAOS]
    if chaos_final > 0.0:
        var chaos_life_pct: float = chaos_final / max_life_safe
        var chaos_tier: int = _morale_penalty_tier(chaos_life_pct)
        if chaos_tier > 0:
            _emit_morale_penalty(attacker, defender, chaos_tier * per_tier, "chaos", chaos_life_pct, tick, events)







static func _collect_damage_taken_amplifiers(defender: CombatantData) -> Array:
    var amplifiers: Array = []
    for active in defender.active_status_effects:
        if active == null or active.effect == null:
            continue
        var contribution: float = active.get_modifier_total("damage_taken_more_pct")
        if contribution == 0.0:
            continue
        amplifiers.append({
            "name": active.effect.display_name, 
            "magnitude_pct": contribution, 
        })
    return amplifiers




















static func _try_apply_shock(
    attacker: CombatantData, 
    defender: CombatantData, 
    lightning_damage: float, 
    is_crit: bool, 
    tick: float, 
    rng: RandomNumberGenerator, 
    events: Array[CombatEvent], 
) -> void :
    if lightning_damage <= 0.0:
        return





    if defender.is_immune_to_ailment(SHOCK_EFFECT.effect_id):
        return



    var chance_pct: float = GameSettings.SHOCK_BASE_CHANCE + attacker.stats.shock_chance
    var roll_value: float = -1.0


    if is_crit:
        chance_pct = 100.0
    else:
        roll_value = rng.randf() * 100.0
        if roll_value >= chance_pct:






            return





    var effect_more: float = attacker.stats.shock_effect_more_pct
    var base_magnitude: float = CombatMath.calculate_shock_base_magnitude(
        lightning_damage, defender.max_life
    )
    var final_magnitude: float = base_magnitude * (1.0 + effect_more / 100.0)






    var effect_reduction: float = clampf(defender.stats.shock_effect_reduction_pct, 0.0, 100.0)
    if effect_reduction > 0.0:
        final_magnitude *= (1.0 - effect_reduction / 100.0)






    if final_magnitude < GameSettings.SHOCK_MIN_APPLIED_MAGNITUDE:
        events.append(CombatEvent.create(tick, CombatEnums.CombatEventType.AILMENT_ROLL, {
            "attacker_id": attacker.combatant_id, 
            "defender_id": defender.combatant_id, 
            "ailment_id": SHOCK_EFFECT.effect_id, 
            "ailment_name": SHOCK_EFFECT.display_name, 
            "chance_pct": chance_pct, 
            "was_crit": is_crit, 
            "roll_value": roll_value, 
            "result": "discarded_below_min", 
            "magnitude_pct": final_magnitude, 
            "magnitude_label": "inc dmg taken", 

            "magnitude_damage": lightning_damage, 
            "magnitude_max_life": defender.max_life, 
            "magnitude_base_pct": base_magnitude, 
            "magnitude_effect_more_pct": effect_more, 
        }))
        return





    var base_mag: float = float(SHOCK_EFFECT.stat_modifiers.get("damage_taken_more_pct", 0.0))
    var mag_mult: float = final_magnitude / base_mag if base_mag > 0.0 else 1.0


    var dur_mult: float = 1.0 + attacker.stats.shock_duration_more_pct / 100.0



    var dur_reduction: float = clampf(defender.stats.shock_duration_reduction_pct, 0.0, 100.0)
    if dur_reduction > 0.0:
        dur_mult *= (1.0 - dur_reduction / 100.0)








    var active: ActiveStatusEffect = defender.apply_status_effect(
        SHOCK_EFFECT, tick, 1, mag_mult, dur_mult
    )
    if active == null:
        return




    events.append(CombatEvent.create(tick, CombatEnums.CombatEventType.STATUS_EFFECT_APPLIED, {
        "combatant_id": defender.combatant_id, 




        "attacker_id": attacker.combatant_id, 
        "defender_id": defender.combatant_id, 
        "inline_with_hit": true, 
        "effect_id": SHOCK_EFFECT.effect_id, 



        "effect": SHOCK_EFFECT, 
        "display_name": SHOCK_EFFECT.display_name, 
        "stacks": active.stacks, 
        "expires_at_tick": active.expires_at_tick, 
        "magnitude_pct": final_magnitude, 
        "magnitude_label": "inc dmg taken", 
        "duration_seconds": SHOCK_EFFECT.duration_seconds * dur_mult, 


        "chance_pct": chance_pct, 
        "was_crit": is_crit, 
        "roll_value": roll_value, 



        "magnitude_damage": lightning_damage, 
        "magnitude_max_life": defender.max_life, 
        "magnitude_base_pct": base_magnitude, 
        "magnitude_effect_more_pct": effect_more, 
    }))
























static func _try_apply_chill(
    attacker: CombatantData, 
    defender: CombatantData, 
    cold_damage: float, 
    tick: float, 
    events: Array[CombatEvent], 
) -> void :
    if cold_damage <= 0.0:
        return





    if defender.is_immune_to_ailment(CHILL_EFFECT.effect_id):
        return




    var effect_more: float = attacker.stats.chill_effect_more_pct
    var base_magnitude: float = CombatMath.calculate_chill_base_magnitude(
        cold_damage, defender.max_life
    )
    var final_magnitude: float = base_magnitude * (1.0 + effect_more / 100.0)





    var effect_reduction: float = clampf(defender.stats.chill_effect_reduction_pct, 0.0, 100.0)
    if effect_reduction > 0.0:
        final_magnitude *= (1.0 - effect_reduction / 100.0)






    if final_magnitude < GameSettings.CHILL_MIN_APPLIED_MAGNITUDE:
        events.append(CombatEvent.create(tick, CombatEnums.CombatEventType.AILMENT_ROLL, {
            "attacker_id": attacker.combatant_id, 
            "defender_id": defender.combatant_id, 
            "ailment_id": CHILL_EFFECT.effect_id, 
            "ailment_name": CHILL_EFFECT.display_name, 
            "result": "discarded_below_min", 
            "magnitude_pct": final_magnitude, 
            "magnitude_label": "reduced action speed", 
            "magnitude_damage": cold_damage, 
            "magnitude_max_life": defender.max_life, 
            "magnitude_base_pct": base_magnitude, 
            "magnitude_effect_more_pct": effect_more, 



        }))
        return






    var base_mag: float = float(CHILL_EFFECT.stat_modifiers.get("action_speed_more_pct", 0.0))
    var mag_mult: float = final_magnitude / absf(base_mag) if absf(base_mag) > 0.0 else 1.0

    var dur_mult: float = 1.0 + attacker.stats.chill_duration_more_pct / 100.0

    var dur_reduction: float = clampf(defender.stats.chill_duration_reduction_pct, 0.0, 100.0)
    if dur_reduction > 0.0:
        dur_mult *= (1.0 - dur_reduction / 100.0)

    var active: ActiveStatusEffect = defender.apply_status_effect(
        CHILL_EFFECT, tick, 1, mag_mult, dur_mult
    )
    if active == null:
        return

    events.append(CombatEvent.create(tick, CombatEnums.CombatEventType.STATUS_EFFECT_APPLIED, {
        "combatant_id": defender.combatant_id, 


        "attacker_id": attacker.combatant_id, 
        "defender_id": defender.combatant_id, 
        "inline_with_hit": true, 
        "effect_id": CHILL_EFFECT.effect_id, 

        "effect": CHILL_EFFECT, 
        "display_name": CHILL_EFFECT.display_name, 
        "stacks": active.stacks, 
        "expires_at_tick": active.expires_at_tick, 
        "magnitude_pct": final_magnitude, 




        "magnitude_label": "reduced action speed", 
        "duration_seconds": CHILL_EFFECT.duration_seconds * dur_mult, 
        "magnitude_damage": cold_damage, 
        "magnitude_max_life": defender.max_life, 
        "magnitude_base_pct": base_magnitude, 
        "magnitude_effect_more_pct": effect_more, 

    }))


























static func _try_apply_ignite(
    attacker: CombatantData, 
    defender: CombatantData, 
    fire_damage: float, 
    is_crit: bool, 
    tick: float, 
    rng: RandomNumberGenerator, 
    events: Array[CombatEvent], 
) -> void :
    if fire_damage <= 0.0:
        return





    if defender.is_immune_to_ailment(IGNITE_EFFECT.effect_id):
        return


    var chance_pct: float = GameSettings.IGNITE_BASE_CHANCE + attacker.stats.ignite_chance
    var roll_value: float = -1.0


    if is_crit:
        chance_pct = 100.0
    else:
        roll_value = rng.randf() * 100.0
        if roll_value >= chance_pct:

            return




    var effect_more: float = attacker.stats.ignite_effect_more_pct
    var dot_more: float = attacker.stats.damage_over_time_more_pct if IGNITE_EFFECT.is_damage_over_time else 0.0
    var final_dps: float = CombatMath.calculate_ignite_dps(fire_damage, effect_more, dot_more)


    if final_dps < GameSettings.IGNITE_MIN_APPLIED_DPS:
        events.append(CombatEvent.create(tick, CombatEnums.CombatEventType.AILMENT_ROLL, {
            "attacker_id": attacker.combatant_id, 
            "defender_id": defender.combatant_id, 
            "ailment_id": IGNITE_EFFECT.effect_id, 
            "ailment_name": IGNITE_EFFECT.display_name, 
            "chance_pct": chance_pct, 
            "was_crit": is_crit, 
            "roll_value": roll_value, 
            "result": "discarded_below_min", 
            "magnitude_pct": final_dps, 
            "magnitude_label": "fire dmg/sec", 
            "magnitude_damage": fire_damage, 
            "magnitude_max_life": defender.max_life, 



            "magnitude_base_pct": fire_damage * GameSettings.IGNITE_BASE_DAMAGE_FRACTION, 
            "magnitude_effect_more_pct": effect_more, 
        }))
        return





    var base_dps: float = float(IGNITE_EFFECT.per_tick_effects.get("fire_damage_per_sec", 0.0))
    var mag_mult: float = final_dps / base_dps if base_dps > 0.0 else 1.0


    var dur_mult: float = 1.0 + attacker.stats.ignite_duration_more_pct / 100.0




    var dur_reduction: float = clampf(defender.stats.ignite_duration_reduction_pct, 0.0, 100.0)
    if dur_reduction > 0.0:
        dur_mult *= (1.0 - dur_reduction / 100.0)



    var active: ActiveStatusEffect = defender.apply_status_effect(
        IGNITE_EFFECT, tick, 1, mag_mult, dur_mult, attacker.combatant_id
    )
    if active == null:
        return

    events.append(CombatEvent.create(tick, CombatEnums.CombatEventType.STATUS_EFFECT_APPLIED, {
        "combatant_id": defender.combatant_id, 


        "attacker_id": attacker.combatant_id, 
        "defender_id": defender.combatant_id, 
        "inline_with_hit": true, 
        "effect_id": IGNITE_EFFECT.effect_id, 
        "effect": IGNITE_EFFECT, 
        "display_name": IGNITE_EFFECT.display_name, 
        "stacks": active.stacks, 
        "expires_at_tick": active.expires_at_tick, 
        "magnitude_pct": final_dps, 
        "magnitude_label": "fire dmg/sec", 
        "duration_seconds": IGNITE_EFFECT.duration_seconds * dur_mult, 
        "chance_pct": chance_pct, 
        "was_crit": is_crit, 
        "roll_value": roll_value, 
        "magnitude_damage": fire_damage, 
        "magnitude_max_life": defender.max_life, 
        "magnitude_base_pct": fire_damage * GameSettings.IGNITE_BASE_DAMAGE_FRACTION, 
        "magnitude_effect_more_pct": effect_more, 
    }))






















static func _consume_impales_for_hit(
    attacker: CombatantData, 
    defender: CombatantData, 
    raw: Dictionary, 
    bonus_out: Dictionary, 
    tick: float, 
    events: Array[CombatEvent], 
) -> void :

    var elem_total: float = raw[StatEnums.DamageType.FIRE]\
+ raw[StatEnums.DamageType.COLD]\
+ raw[StatEnums.DamageType.LIGHTNING]
    if elem_total <= 0.0:



        return

    var consumption: Dictionary = defender.consume_impales()
    var total_flat: float = consumption.get("total", 0.0)
    var count: int = consumption.get("count", 0)
    if total_flat <= 0.0 or count <= 0:
        return


    for type in [StatEnums.DamageType.FIRE, StatEnums.DamageType.COLD, StatEnums.DamageType.LIGHTNING]:
        var amount: float = raw[type]
        if amount <= 0.0:
            continue
        var share: float = (amount / elem_total) * total_flat
        raw[type] += share
        bonus_out[_damage_type_name(type)] = share




    bonus_out["_count"] = count

    events.append(CombatEvent.create(tick, CombatEnums.CombatEventType.IMPALE_CONSUMED, {
        "attacker_id": attacker.combatant_id, 
        "defender_id": defender.combatant_id, 




        "inline_with_hit": true, 
        "stacks_consumed": count, 
        "total_flat": total_flat, 


        "per_element": {
            "fire": bonus_out.get("fire", 0.0), 
            "cold": bonus_out.get("cold", 0.0), 
            "lightning": bonus_out.get("lightning", 0.0), 
        }, 
    }))













static func _try_apply_impale(
    attacker: CombatantData, 
    defender: CombatantData, 
    phys_dealt: float, 
    tick: float, 
    rng: RandomNumberGenerator, 
    events: Array[CombatEvent], 
) -> void :
    if phys_dealt <= 0.0:
        return




    if defender.is_immune_to_ailment(IMPALE_AILMENT_ID):
        return












    var chance_pct: float = GameSettings.IMPALE_BASE_CHANCE + attacker.stats.impale_chance
    if chance_pct <= 0.0:
        return
    var guaranteed_stacks: int = int(chance_pct / 100.0)
    var remainder_pct: float = chance_pct - float(guaranteed_stacks) * 100.0
    var stacks_to_add: int = guaranteed_stacks
    if remainder_pct > 0.0 and rng.randf() * 100.0 < remainder_pct:
        stacks_to_add += 1
    if stacks_to_add <= 0:
        return

    var capture_pct: float = GameSettings.IMPALE_BASE_CAPTURE_PCT + attacker.stats.impale_effect_pct
    if capture_pct <= 0.0:
        return

    var flat: float = phys_dealt * (capture_pct / 100.0)



    if flat < 1.0:
        return

    var max_stacks: int = GameSettings.IMPALE_BASE_MAX_STACKS + attacker.stats.max_impales_bonus



    var stacks_now: int = defender.impale_stacks.size()
    for _i in stacks_to_add:
        stacks_now = defender.add_impale(flat, attacker.combatant_id, tick, max_stacks)

    events.append(CombatEvent.create(tick, CombatEnums.CombatEventType.IMPALE_APPLIED, {
        "attacker_id": attacker.combatant_id, 
        "defender_id": defender.combatant_id, 



        "inline_with_hit": true, 
        "flat_damage": flat, 
        "stacks_now": stacks_now, 



        "stacks_added": stacks_to_add, 
        "max_stacks": max_stacks, 



        "phys_dealt": phys_dealt, 
        "capture_pct": capture_pct, 
    }))

























static func _try_apply_poison(
    attacker: CombatantData, 
    defender: CombatantData, 
    combined_phys_chaos: float, 
    is_crit: bool, 
    tick: float, 
    rng: RandomNumberGenerator, 
    events: Array[CombatEvent], 
) -> void :
    if combined_phys_chaos <= 0.0:
        return


    if defender.is_immune_to_ailment(POISON_AILMENT_ID):
        return






    var chance_pct: float = GameSettings.POISON_BASE_CHANCE + attacker.stats.poison_chance
    var roll_value: float = -1.0
    if chance_pct <= 0.0:
        return

    var guaranteed_stacks: int = int(chance_pct / 100.0)
    var remainder_pct: float = chance_pct - float(guaranteed_stacks) * 100.0
    var stacks_to_add: int = guaranteed_stacks
    if remainder_pct > 0.0:
        roll_value = rng.randf() * 100.0
        if roll_value < remainder_pct:
            stacks_to_add += 1
    if stacks_to_add <= 0:
        return





    var effect_more: float = attacker.stats.poison_effect_more_pct
    var dot_more: float = attacker.stats.damage_over_time_more_pct
    var final_dps: float = CombatMath.calculate_poison_dps(combined_phys_chaos, effect_more, dot_more)


    if final_dps < GameSettings.POISON_MIN_APPLIED_DPS:
        events.append(CombatEvent.create(tick, CombatEnums.CombatEventType.AILMENT_ROLL, {
            "attacker_id": attacker.combatant_id, 
            "defender_id": defender.combatant_id, 
            "ailment_id": POISON_AILMENT_ID, 
            "ailment_name": POISON_DISPLAY_NAME, 
            "chance_pct": chance_pct, 
            "was_crit": is_crit, 
            "roll_value": roll_value, 
            "result": "discarded_below_min", 
            "magnitude_pct": final_dps, 
            "magnitude_label": "chaos dmg/sec", 
            "magnitude_damage": combined_phys_chaos, 
            "magnitude_max_life": defender.max_life, 
            "magnitude_base_pct": combined_phys_chaos * GameSettings.POISON_BASE_DAMAGE_FRACTION, 
            "magnitude_effect_more_pct": effect_more, 
        }))
        return





    var dur_mult: float = 1.0 + attacker.stats.poison_duration_more_pct / 100.0
    var dur_reduction: float = clampf(defender.stats.poison_duration_reduction_pct, 0.0, 100.0)
    if dur_reduction > 0.0:
        dur_mult *= (1.0 - dur_reduction / 100.0)
    var duration_seconds: float = GameSettings.POISON_BASE_DURATION * dur_mult
    if duration_seconds <= 0.0:
        return
    var expires_at_tick: float = tick + duration_seconds






    var stacks_now: int = defender.poison_stacks.size()
    for _i in stacks_to_add:
        stacks_now = defender.add_poison(
            final_dps, attacker.combatant_id, tick, expires_at_tick, GameSettings.POISON_MAX_STACKS
        )
        events.append(CombatEvent.create(tick, CombatEnums.CombatEventType.POISON_APPLIED, {
            "attacker_id": attacker.combatant_id, 
            "defender_id": defender.combatant_id, 


            "inline_with_hit": true, 
            "damage_per_sec": final_dps, 
            "stacks_now": stacks_now, 



            "stacks_added": stacks_to_add, 
            "duration_seconds": duration_seconds, 
            "expires_at_tick": expires_at_tick, 



            "magnitude_pct": final_dps, 
            "magnitude_label": "chaos dmg/sec", 
            "chance_pct": chance_pct, 
            "was_crit": is_crit, 
            "roll_value": roll_value, 
            "magnitude_damage": combined_phys_chaos, 
            "magnitude_max_life": defender.max_life, 
            "magnitude_base_pct": combined_phys_chaos * GameSettings.POISON_BASE_DAMAGE_FRACTION, 
            "magnitude_effect_more_pct": effect_more, 
        }))





static func _emit_morale_penalty(
    attacker: CombatantData, 
    defender: CombatantData, 
    amount: int, 
    source: String, 
    life_pct: float, 
    tick: float, 
    events: Array[CombatEvent], 
) -> void :



    defender.current_morale = maxf(defender.current_morale - float(amount), 0.0)
    defender.total_morale_lost += amount
    events.append(CombatEvent.create(tick, CombatEnums.CombatEventType.MORALE_PENALTY, {
        "defender_id": defender.combatant_id, 


        "attacker_id": attacker.combatant_id, 
        "amount": amount, 
        "source": source, 
        "life_pct": life_pct, 
    }))
