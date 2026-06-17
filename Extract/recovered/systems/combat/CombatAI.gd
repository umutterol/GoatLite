class_name CombatAI
extends RefCounted




enum ActionType{
    IDLE, 
    MOVE_TOWARD, 
    MOVE_AWAY, 
    ATTACK, 
}
























static func pick_target(
    combatant: CombatantData, 
    enemies: Array[CombatantData], 
    rng: RandomNumberGenerator, 
    current_tick: float = 0.0, 
    allies: Array[CombatantData] = []
) -> CombatantData:
    if enemies.is_empty():
        return null







    if current_tick < combatant.sticky_target_until and combatant.current_target_id >= 0:
        if not _threat_within_break_radius(combatant, enemies):
            for enemy in enemies:
                if enemy.combatant_id == combatant.current_target_id:
                    return enemy



    var picked: CombatantData = _select_via_rules(combatant, enemies, allies, rng)
    if picked == null:




        picked = _closest_enemy(combatant, enemies)

    if picked != null:
        combatant.sticky_target_until = current_tick + combatant.combat_behavior.get_tactical().sticky_target_duration
    return picked













static func _threat_within_break_radius(
    combatant: CombatantData, enemies: Array[CombatantData]
) -> bool:
    var radius: float = combatant.combat_behavior.get_tactical().threat_break_radius
    if radius <= 0.0:
        return false
    for enemy in enemies:
        if combatant.distance_to(enemy) < radius:
            return true
    return false








static func _select_via_rules(
    combatant: CombatantData, 
    enemies: Array[CombatantData], 
    allies: Array[CombatantData], 
    rng: RandomNumberGenerator
) -> CombatantData:
    var behavior: = combatant.combat_behavior


    for rule in behavior.target_rules:
        if rule == null:
            continue
        var candidates: Array[CombatantData] = _filter_enemies(combatant, enemies, allies, rule)
        if candidates.is_empty():
            continue
        var pick: CombatantData = _apply_picker(combatant, candidates, rule.picker, rng)
        if pick != null:
            return pick





    if behavior.target_rules.is_empty() and behavior.fallback_picker == TargetRule.Picker.NEAREST:
        var legacy: CombatantData = _select_via_legacy_aggro(combatant, enemies, rng)
        if legacy != null:
            return legacy


    return _apply_picker(combatant, enemies, behavior.fallback_picker, rng)




static func _filter_enemies(
    combatant: CombatantData, 
    enemies: Array[CombatantData], 
    allies: Array[CombatantData], 
    rule: TargetRule
) -> Array[CombatantData]:
    var out: Array[CombatantData] = []
    var attack_range: float = combatant.combat_behavior.attack_range
    for enemy in enemies:
        if not _passes_filter(combatant, enemy, allies, rule):
            continue
        if rule.require_in_range and combatant.distance_to(enemy) > attack_range:
            continue
        out.append(enemy)
    return out





static func _passes_filter(
    combatant: CombatantData, 
    enemy: CombatantData, 
    allies: Array[CombatantData], 
    rule: TargetRule
) -> bool:
    match rule.filter:
        TargetRule.Filter.ALL:


            return true
        TargetRule.Filter.IN_RANGE:



            return true
        TargetRule.Filter.ATTACKING_ME:
            return enemy.current_target_id == combatant.combatant_id
        TargetRule.Filter.ATTACKING_ANY_ALLY:


            if allies.is_empty():
                return enemy.current_target_id == combatant.combatant_id
            for ally in allies:
                if enemy.current_target_id == ally.combatant_id:
                    return true
            return false
        TargetRule.Filter.HAS_STATUS:
            if rule.status_id == &"":
                return true
            return enemy.get_status_effect(rule.status_id) != null
        TargetRule.Filter.LACKS_STATUS:
            if rule.status_id == &"":
                return true
            return enemy.get_status_effect(rule.status_id) == null
    return false






static func _apply_picker(
    combatant: CombatantData, 
    candidates: Array[CombatantData], 
    picker: int, 
    rng: RandomNumberGenerator
) -> CombatantData:
    if candidates.is_empty():
        return null
    match picker:
        TargetRule.Picker.NEAREST:
            return _closest_enemy(combatant, candidates)
        TargetRule.Picker.FARTHEST:
            return _farthest_enemy(combatant, candidates)
        TargetRule.Picker.LOWEST_CURRENT_HP:
            return _lowest_hp_enemy(candidates)
        TargetRule.Picker.HIGHEST_CURRENT_HP:
            return _highest_hp_enemy(candidates)
        TargetRule.Picker.LOWEST_MAX_HP:
            return _lowest_max_hp_enemy(candidates)
        TargetRule.Picker.HIGHEST_MAX_HP:
            return _highest_max_hp_enemy(candidates)
        TargetRule.Picker.FASTEST:
            return _fastest_enemy(candidates)
        TargetRule.Picker.SLOWEST:
            return _slowest_enemy(candidates)
        TargetRule.Picker.RANDOM:
            return candidates[rng.randi_range(0, candidates.size() - 1)]
        TargetRule.Picker.ANY:
            return candidates[0]
    return _closest_enemy(combatant, candidates)





static func _select_via_legacy_aggro(
    combatant: CombatantData, 
    enemies: Array[CombatantData], 
    rng: RandomNumberGenerator
) -> CombatantData:
    match combatant.combat_behavior.aggro_type:
        CombatEnums.AggroType.NEAREST:
            return _closest_enemy(combatant, enemies)
        CombatEnums.AggroType.LOWEST_HP:
            return _lowest_hp_enemy(enemies)
        CombatEnums.AggroType.HIGHEST_HP:
            return _highest_hp_enemy(enemies)
        CombatEnums.AggroType.RANDOM:
            return enemies[rng.randi_range(0, enemies.size() - 1)]
        CombatEnums.AggroType.NONE:
            return null
    return _closest_enemy(combatant, enemies)














static func decide_action(combatant: CombatantData, target: CombatantData, current_tick: float = 0.0) -> Dictionary:
    var behavior: = combatant.combat_behavior
    var distance: = combatant.distance_to(target)




    var attack_range: float = _engagement_range(combatant)



    if distance > attack_range + behavior.get_tactical().attack_range_hysteresis:
        return {type = ActionType.MOVE_TOWARD, target = target}




    if combatant.attack_cooldown <= 0.0:
        var since_moved: float = current_tick - combatant.last_move_tick
        if since_moved < behavior.get_tactical().kite_settle_duration:
            return {type = ActionType.IDLE, target = target}
        return {type = ActionType.ATTACK, target = target}



    if _should_kite(combatant, target, current_tick):
        return {type = ActionType.MOVE_AWAY, target = target}

    return {type = ActionType.IDLE, target = target}


















static func _engagement_range(combatant: CombatantData) -> float:
    var best: float = combatant.combat_behavior.attack_range
    for slot in combatant.action_slots:
        if slot.current_action != null:
            continue
        for ability in slot.abilities:
            if ability == null:
                continue
            if not slot.is_ready(ability):
                continue
            if not ability.can_use(combatant, null):
                continue
            best = maxf(best, ability.get_effective_range(combatant))
    return best











static func _should_kite(combatant: CombatantData, target: CombatantData, current_tick: float = 0.0) -> bool:
    var behavior: = combatant.combat_behavior
    match behavior.kite_mode:
        CombatEnums.KiteMode.NONE, CombatEnums.KiteMode.MOVEMENT_SKILL_ONLY:
            return false
        CombatEnums.KiteMode.KITE_BETWEEN_ATTACKS:
            return _kite_between_attacks(combatant, target, current_tick)
        CombatEnums.KiteMode.KITE_ONLY_VS_SLOWER_MELEE:
            return _kite_only_vs_slower_melee(combatant, target)
    return false





static func _kite_between_attacks(combatant: CombatantData, target: CombatantData, current_tick: float) -> bool:
    var behavior: = combatant.combat_behavior
    if behavior.preferred_distance <= 0.0:
        return false



    var since_melee_hit: float = current_tick - combatant.last_melee_hit_tick
    if since_melee_hit < behavior.get_tactical().melee_threat_memory_duration and combatant.last_melee_attacker_was_faster:
        return false

    var distance: = combatant.distance_to(target)
    return distance < behavior.preferred_distance













static func _kite_only_vs_slower_melee(combatant: CombatantData, target: CombatantData) -> bool:
    var behavior: = combatant.combat_behavior
    if behavior.preferred_distance <= 0.0:
        return false
    var distance: = combatant.distance_to(target)
    if distance >= behavior.preferred_distance:
        return false
    if target.combat_behavior == null:
        return false



    if target.combat_behavior.attack_range > CombatBehavior.MELEE_ATTACK_RANGE_DEFAULT * 1.5:
        return false
    return combatant.get_effective_movement_speed() > target.get_effective_movement_speed()






static func _closest_enemy(
    combatant: CombatantData, 
    enemies: Array[CombatantData]
) -> CombatantData:
    var best: CombatantData = null
    var best_dist: = INF
    var discount: float = combatant.combat_behavior.get_tactical().engaged_target_distance_discount
    for enemy in enemies:
        var dist: = combatant.distance_to(enemy)


        if enemy.combatant_id == combatant.current_target_id:
            dist *= discount
        if dist < best_dist:
            best_dist = dist
            best = enemy
    return best


static func _farthest_enemy(
    combatant: CombatantData, 
    enemies: Array[CombatantData]
) -> CombatantData:
    var best: CombatantData = null
    var best_dist: float = -1.0
    for enemy in enemies:
        var dist: = combatant.distance_to(enemy)
        if dist > best_dist:
            best_dist = dist
            best = enemy
    return best


static func _lowest_hp_enemy(enemies: Array[CombatantData]) -> CombatantData:
    var best: CombatantData = null
    var lowest: = INF
    for enemy in enemies:
        if enemy.current_life < lowest:
            lowest = enemy.current_life
            best = enemy
    return best


static func _highest_hp_enemy(enemies: Array[CombatantData]) -> CombatantData:
    var best: CombatantData = null
    var highest: = -1.0
    for enemy in enemies:
        if enemy.current_life > highest:
            highest = enemy.current_life
            best = enemy
    return best


static func _lowest_max_hp_enemy(enemies: Array[CombatantData]) -> CombatantData:
    var best: CombatantData = null
    var lowest: = INF
    for enemy in enemies:
        if enemy.max_life < lowest:
            lowest = enemy.max_life
            best = enemy
    return best


static func _highest_max_hp_enemy(enemies: Array[CombatantData]) -> CombatantData:
    var best: CombatantData = null
    var highest: = -1.0
    for enemy in enemies:
        if enemy.max_life > highest:
            highest = enemy.max_life
            best = enemy
    return best


static func _fastest_enemy(enemies: Array[CombatantData]) -> CombatantData:
    var best: CombatantData = null
    var fastest: float = -1.0
    for enemy in enemies:
        var speed: float = enemy.get_effective_movement_speed()
        if speed > fastest:
            fastest = speed
            best = enemy
    return best


static func _slowest_enemy(enemies: Array[CombatantData]) -> CombatantData:
    var best: CombatantData = null
    var slowest: = INF
    for enemy in enemies:
        var speed: float = enemy.get_effective_movement_speed()
        if speed < slowest:
            slowest = speed
            best = enemy
    return best
