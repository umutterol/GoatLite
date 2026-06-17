class_name CombatSimulation
extends RefCounted











enum SimulationState{
    RUNNING, 
    AWAITING_DECISION, 
    COMPLETE, 
}






const TICK_STEP: float = 0.1



const ARENA_EDGE_INSET: float = 0.5



const BODY_RADIUS: float = 0.8







const KITE_MEANINGFUL_MOVE_THRESHOLD: float = 0.05




const STALL_MIN_COMBAT_DURATION: float = 8.0
const STALL_NO_DAMAGE_THRESHOLD: float = 10.0





var max_duration: float = 60.0








const DESPERATION_EFFECT: StatusEffect = preload("res://systems/combat/statusEffects/desperation.tres")




const DESPERATION_STACK_INTERVAL: float = 5.0





const DEBUG_AI: bool = false




const DEBUG_AI_FILTER_NAME: String = ""





const DEBUG_AI_SAMPLE_INTERVAL: int = 10




const DEBUG_AI_LOG_ON_CHANGE: bool = true



var combatants: Array[CombatantData] = []
var current_tick: float = 0.0
var simulation_state: SimulationState = SimulationState.RUNNING
var combat_result: CombatEnums.CombatResult

var rng: RandomNumberGenerator = RandomNumberGenerator.new()


var initial_seed: int = 0
var event_log: Array[CombatEvent] = []


var _last_damage_tick: float = 0.0



var _overtime_active: bool = false




var _next_desperation_stack_at: float = 0.0



var snapshots: Array[Dictionary] = []



var _next_combatant_id: int = 0
var _encounter: EncounterData = null




var _debug_last_action: Dictionary = {}










func initialize(party: Array[ExileData], encounter: EncounterData, rng_seed: int, mission_level: int = -1) -> void :
    rng.seed = rng_seed
    initial_seed = rng_seed
    _encounter = encounter
    combatants.clear()
    event_log.clear()
    snapshots.clear()
    current_tick = 0.0
    _last_damage_tick = 0.0
    _overtime_active = false
    _next_desperation_stack_at = 0.0
    simulation_state = SimulationState.RUNNING


    for exile in party:
        var combatant: = CombatantData.from_exile(exile, _next_id())
        combatants.append(combatant)

    for spawn_index in encounter.monster_spawns.size():
        var spawn: MonsterSpawn = encounter.monster_spawns[spawn_index]





        if spawn == null or spawn.monster == null:
            push_error(
                "CombatSimulation: encounter '%s' MonsterSpawn[%d] has null monster — fix the .tres" %
                [encounter.encounter_id, spawn_index]
            )
            continue
        for i in spawn.count:
            var combatant: = CombatantData.from_monster(spawn.monster, _next_id(), mission_level)
            if combatant == null:
                continue
            combatant.spawn_group_index = spawn_index
            combatants.append(combatant)





    _disambiguate_monster_names()

    _place_combatants()


    for combatant in combatants:
        combatant.attack_cooldown = 0.0

    event_log.append(CombatEvent.create(0.0, CombatEnums.CombatEventType.COMBAT_START, {
        "exile_count": party.size(), 
        "monster_count": combatants.size() - party.size(), 
    }))
    _save_snapshot()








func advance() -> Dictionary:
    if simulation_state != SimulationState.RUNNING:
        return {"state": simulation_state, "result": combat_result}

    current_tick += TICK_STEP
    _check_overtime_transition()
    _process_tick()








    if _all_dead_on_team(CombatEnums.CombatantTeam.MONSTERS):
        _end_combat(CombatEnums.CombatResult.VICTORY)
    elif _all_downed_on_team(CombatEnums.CombatantTeam.EXILES):
        _end_combat(CombatEnums.CombatResult.DEFEAT)
    elif _is_stalled():
        simulation_state = SimulationState.AWAITING_DECISION
        event_log.append(CombatEvent.create(current_tick, CombatEnums.CombatEventType.DECISION_POINT, {
            "reason": "stall — no damage dealt recently", 
        }))

    return {"state": simulation_state, "result": (combat_result as Variant) if simulation_state == SimulationState.COMPLETE else null}




func resolve_decision(decision: CombatEnums.CombatResult) -> void :
    if simulation_state != SimulationState.AWAITING_DECISION:
        push_warning("CombatSimulation.resolve_decision: not awaiting a decision")
        return
    _end_combat(decision)



func run_to_completion() -> CombatResultData:
    while simulation_state == SimulationState.RUNNING:
        advance()

    if simulation_state == SimulationState.AWAITING_DECISION:
        resolve_decision(CombatEnums.CombatResult.RETREAT)
    return get_result()




func get_result() -> CombatResultData:
    return CombatResultData.from_simulation(self, _encounter)















func _disambiguate_monster_names() -> void :
    var counts: Dictionary = {}
    for c in combatants:
        if c == null or c.source_monster == null:
            continue
        counts[c.display_name] = int(counts.get(c.display_name, 0)) + 1


    var has_dupes: bool = false
    for v in counts.values():
        if int(v) > 1:
            has_dupes = true
            break
    if not has_dupes:
        return

    var indices: Dictionary = {}
    for c in combatants:
        if c == null or c.source_monster == null:
            continue
        var base_name: String = c.display_name
        if int(counts.get(base_name, 0)) <= 1:
            continue
        var idx: int = int(indices.get(base_name, 0)) + 1
        indices[base_name] = idx
        c.display_name = "%s %d" % [base_name, idx]






func _process_tick() -> void :



    _apply_life_regen()
    _tick_status_effect_expiries()
    _tick_desperation_stacks()
    _apply_status_effect_drains()
    _check_drain_deaths()

    for combatant in combatants:
        if not combatant.is_alive():
            continue




        var movement_locked: bool = _tick_action_slots(combatant)




        _sync_legacy_attack_cooldown(combatant)

        var enemies: = _get_living_enemies(combatant)
        var allies: = _get_living_allies(combatant)
        var target: = CombatAI.pick_target(combatant, enemies, rng, current_tick, allies)
        if target == null:
            combatant.state = CombatEnums.CombatantState.IDLE
            combatant.current_target_id = -1
            _debug_log_ai(combatant, null, -1)
            continue

        combatant.current_target_id = target.combatant_id


        if movement_locked:
            _debug_log_ai(combatant, target, -2)
            continue

        var action: Dictionary = CombatAI.decide_action(combatant, target, current_tick)
        _debug_log_ai(combatant, target, action.type)

        match action.type:
            CombatAI.ActionType.ATTACK:
                _try_start_slot_ability(combatant, target)
            CombatAI.ActionType.MOVE_TOWARD:
                _move_toward(combatant, target)
            CombatAI.ActionType.MOVE_AWAY:
                _move_away_from(combatant, target)
            CombatAI.ActionType.IDLE:
                combatant.state = CombatEnums.CombatantState.IDLE

    _resolve_overlaps()
    _save_snapshot()










func _tick_action_slots(combatant: CombatantData) -> bool:
    var movement_locked: bool = false
    for slot in combatant.action_slots:
        slot.decrement_cooldowns(TICK_STEP)

        if slot.current_action != null:
            var events: Array = slot.current_action.tick(TICK_STEP)
            _process_action_events(events, slot.current_action.target)
            if slot.current_action.is_finished():
                var ability: MonsterAbility = slot.current_action.ability
                slot.cooldowns[ability.ability_id] = ability.get_effective_cooldown(combatant)







                if ability.wind_up_seconds > 0.0 or ability.recovery_seconds > 0.0:
                    _gap_basic_attack(slot, combatant)
                slot.current_action = null

        if slot.current_action != null:
            if slot.locks_owner_movement or slot.current_action.locks_owner_movement:
                movement_locked = true

    return movement_locked







func _gap_basic_attack(slot: ActionSlot, combatant: CombatantData) -> void :
    for ability in slot.abilities:
        if ability == null or ability.ability_id != "basic_attack":
            continue
        if slot.cooldowns.get(ability.ability_id, 0.0) > 0.0:
            return
        slot.cooldowns[ability.ability_id] = ability.get_effective_cooldown(combatant)
        return






func _sync_legacy_attack_cooldown(combatant: CombatantData) -> void :
    if combatant.action_slots.is_empty():
        combatant.attack_cooldown = INF
        return
    var primary: ActionSlot = combatant.action_slots[0]
    if primary.current_action != null:
        combatant.attack_cooldown = INF
        return
    combatant.attack_cooldown = primary.cooldowns.get("basic_attack", 0.0)






func _try_start_slot_ability(combatant: CombatantData, target: CombatantData) -> bool:
    var hysteresis: float = combatant.combat_behavior.get_tactical().attack_range_hysteresis
    for slot in combatant.action_slots:
        if slot.current_action != null:
            continue
        for ability in slot.abilities:
            if ability == null:
                continue
            if not slot.is_ready(ability):
                continue
            var effective_range: float = ability.get_effective_range(combatant)
            if combatant.distance_to(target) > effective_range + hysteresis:
                continue
            if not ability.can_use(combatant, self):
                continue
            var action: AbilityAction = ability.create_action(combatant, self, target)
            if action == null:



                continue
            slot.current_action = action
            var events: Array = action.tick(TICK_STEP)
            _process_action_events(events, action.target)
            if action.is_finished():
                slot.cooldowns[ability.ability_id] = ability.get_effective_cooldown(combatant)
                slot.current_action = null
            return true
    return false








func _process_action_events(events: Array, _defender: CombatantData) -> void :
    for event in events:
        event_log.append(event)
        if event.event_type == CombatEnums.CombatEventType.DAMAGE_DEALT:
            _last_damage_tick = current_tick
        if event.event_type == CombatEnums.CombatEventType.DEATH:
            var dead_id: int = event.data.get("combatant_id", -1)
            if dead_id < 0 or dead_id >= combatants.size():
                continue
            var dead: CombatantData = combatants[dead_id]
            if dead != null and dead.source_monster != null:
                _award_xp_for_kill(dead)





func _resolve_overlaps() -> void :
    for i in range(combatants.size()):
        var a: CombatantData = combatants[i]
        if not a.is_alive():
            continue
        for j in range(i + 1, combatants.size()):
            var b: CombatantData = combatants[j]
            if not b.is_alive():
                continue
            var diff: Vector2 = b.position - a.position
            var dist: float = diff.length()
            if dist >= BODY_RADIUS:
                continue

            if dist < 0.001:
                a.position = _clamp_to_arena(a.position + Vector2( - BODY_RADIUS * 0.5, 0))
                b.position = _clamp_to_arena(b.position + Vector2(BODY_RADIUS * 0.5, 0))
                continue
            var push: float = (BODY_RADIUS - dist) * 0.5
            var dir: Vector2 = diff / dist
            a.position = _clamp_to_arena(a.position - dir * push)
            b.position = _clamp_to_arena(b.position + dir * push)







func _move_toward(combatant: CombatantData, target: CombatantData) -> void :
    var direction: = (target.position - combatant.position).normalized()
    var move_distance: = combatant.get_effective_movement_speed() * TICK_STEP
    var distance_to_target: = combatant.distance_to(target)
    var attack_range: = combatant.combat_behavior.attack_range


    var max_move: = maxf(distance_to_target - attack_range, 0.0)
    move_distance = minf(move_distance, max_move)

    if move_distance <= 0.0:
        return

    var old_position: = combatant.position
    combatant.position = _clamp_to_arena(combatant.position + direction * move_distance)
    combatant.last_move_tick = current_tick


    if combatant.state != CombatEnums.CombatantState.MOVING:
        combatant.state = CombatEnums.CombatantState.MOVING
        event_log.append(CombatEvent.create(current_tick, CombatEnums.CombatEventType.MOVEMENT, {
            "combatant_id": combatant.combatant_id, 
            "from": old_position, 
            "to": combatant.position, 
            "target_id": target.combatant_id, 
        }))


func _move_away_from(combatant: CombatantData, target: CombatantData) -> void :
    var preferred: = combatant.combat_behavior.preferred_distance
    var distance: = combatant.distance_to(target)
    if distance >= preferred:
        return

    var base_away: = (combatant.position - target.position).normalized()
    var retreat_distance: = minf(combatant.get_effective_movement_speed() * TICK_STEP, preferred - distance)






    if is_nan(combatant.kite_deviation_radians):
        combatant.kite_deviation_radians = _pick_kite_deviation(combatant, base_away, retreat_distance)
    var direction: = base_away.rotated(combatant.kite_deviation_radians)

    var old_position: = combatant.position
    var desired: = combatant.position + direction * retreat_distance
    var clamped: = _clamp_to_arena(desired)




    if old_position.distance_to(clamped) < retreat_distance * 0.5:
        var perp_ccw: = Vector2( - direction.y, direction.x)
        var perp_cw: = Vector2(direction.y, - direction.x)
        var clamped_ccw: = _clamp_to_arena(old_position + perp_ccw * retreat_distance)
        var clamped_cw: = _clamp_to_arena(old_position + perp_cw * retreat_distance)
        if old_position.distance_to(clamped_ccw) >= old_position.distance_to(clamped_cw):
            clamped = clamped_ccw
        else:
            clamped = clamped_cw

    combatant.position = clamped






    if old_position.distance_to(clamped) < KITE_MEANINGFUL_MOVE_THRESHOLD:
        combatant.state = CombatEnums.CombatantState.IDLE
        combatant.kite_deviation_radians = NAN
        return

    combatant.last_move_tick = current_tick

    if combatant.state != CombatEnums.CombatantState.MOVING:
        combatant.state = CombatEnums.CombatantState.MOVING
        event_log.append(CombatEvent.create(current_tick, CombatEnums.CombatEventType.MOVEMENT, {
            "combatant_id": combatant.combatant_id, 
            "from": old_position, 
            "to": combatant.position, 
            "target_id": target.combatant_id, 
        }))





func _place_combatants() -> void :
    var arena_w: = _encounter.arena_width
    var arena_h: = _encounter.arena_height



    var jitter_small: = arena_h * 0.04
    var jitter_large: = arena_h * 0.06
    var vertical_gap: = arena_h * 0.12


    var exiles: Array[CombatantData] = []
    for c in combatants:
        if c.team == CombatEnums.CombatantTeam.EXILES:
            exiles.append(c)

    var base_exile_x: = arena_w * 0.33
    var base_exile_y: = arena_h / 2.0

    for i in exiles.size():
        var jx: = rng.randf_range( - jitter_small, jitter_small)
        var jy: = rng.randf_range( - jitter_small, jitter_small)
        var offset_y: = (i - (exiles.size() - 1) / 2.0) * vertical_gap

        exiles[i].position = Vector2(
            base_exile_x + jx, 
            base_exile_y + offset_y + jy
        )


    for spawn_index in _encounter.monster_spawns.size():
        var spawn: MonsterSpawn = _encounter.monster_spawns[spawn_index]
        var spawn_combatants: Array[CombatantData] = _get_combatants_for_spawn(spawn_index)
        var base_x: = _hint_to_x(spawn.position_hint, arena_w)
        var base_y: = arena_h / 2.0

        var hint = spawn.position_hint

        for i in spawn_combatants.size():
            var final_x: float
            var final_y: float

            match hint:
                MonsterSpawn.PositionHint.SPREAD:

                    final_x = rng.randf_range(arena_w * 0.1, arena_w * 0.9)
                    final_y = rng.randf_range(arena_h * 0.1, arena_h * 0.9)

                MonsterSpawn.PositionHint.FLANK:

                    var is_top_flank: bool = (i % 2 == 0)
                    var flank_base_y: = arena_h * 0.2 if is_top_flank else arena_h * 0.8

                    final_x = base_x + rng.randf_range( - jitter_large, jitter_large)
                    final_y = flank_base_y + rng.randf_range( - jitter_large, jitter_large)

                _:

                    var jx: = rng.randf_range( - jitter_large, jitter_large)
                    var jy: = rng.randf_range( - jitter_large, jitter_large)
                    var offset_y: = (i - (spawn_combatants.size() - 1) / 2.0) * vertical_gap

                    final_x = base_x + jx
                    final_y = base_y + offset_y + jy

            spawn_combatants[i].position = Vector2(final_x, final_y)


func _hint_to_x(hint: MonsterSpawn.PositionHint, arena_width: float) -> float:
    match hint:
        MonsterSpawn.PositionHint.FRONTLINE:
            return arena_width * 0.65
        MonsterSpawn.PositionHint.VANGUARD:
            return arena_width * 0.5
        MonsterSpawn.PositionHint.BACKLINE:
            return arena_width * 0.8
        MonsterSpawn.PositionHint.REAR:

            return arena_width * 0.1
        MonsterSpawn.PositionHint.FLANK:
            return arena_width * 0.5
        MonsterSpawn.PositionHint.SPREAD:
            return arena_width * 0.6
        _:
            return arena_width * 0.55


func _get_combatants_for_spawn(spawn_index: int) -> Array[CombatantData]:
    var result: Array[CombatantData] = []
    for c in combatants:
        if c.spawn_group_index == spawn_index:
            result.append(c)
    return result






func _save_snapshot() -> void :
    var positions: Array[Dictionary] = []
    for c in combatants:
        positions.append({
            "id": c.combatant_id, 
            "pos": c.position, 
            "state": c.state, 
            "life_pct": c.current_life / maxf(c.max_life, 1.0), 



            "vitality_pct": c.current_vitality / maxf(c.max_vitality, 1.0), 




            "morale_pct": c.current_morale / maxf(c.max_morale, 1.0) if c.max_morale > 0.0 else 0.0, 
            "target_id": c.current_target_id, 
        })
    snapshots.append({
        "tick": current_tick, 
        "positions": positions, 
    })








func _clamp_to_arena(pos: Vector2) -> Vector2:
    return Vector2(
        clampf(pos.x, ARENA_EDGE_INSET, _encounter.arena_width - ARENA_EDGE_INSET), 
        clampf(pos.y, ARENA_EDGE_INSET, _encounter.arena_height - ARENA_EDGE_INSET), 
    )






func _apply_life_regen() -> void :
    for combatant in combatants:
        if not combatant.is_alive():
            continue
        var regen_rate: float = combatant.stats.life_regen
        if regen_rate <= 0.0:
            continue
        var heal: float = regen_rate * TICK_STEP
        combatant.apply_combat_heal(heal)










func _award_xp_for_kill(victim: CombatantData) -> void :
    if victim.scaled_experience_value <= 0:
        return
    var living: Array[CombatantData] = []
    for c in combatants:
        if c.team == CombatEnums.CombatantTeam.EXILES and c.is_alive() and c.source_exile != null:
            living.append(c)
    if living.is_empty():
        return

    var per_exile: int = victim.scaled_experience_value / living.size()
    if per_exile <= 0:


        per_exile = 1

    for c in living:



        var xp_more: float = c.morale_combat_modifiers.get("experience_more", 0.0)
        var awarded_xp: int = per_exile
        if xp_more != 0.0:
            awarded_xp = int(round(per_exile * (1.0 + xp_more / 100.0)))
            awarded_xp = maxi(awarded_xp, 1)
        var level_before: int = c.source_exile.level
        c.source_exile.gain_experience(awarded_xp)
        c.xp_earned_this_combat += awarded_xp



        event_log.append(CombatEvent.create(current_tick, CombatEnums.CombatEventType.EXPERIENCE_GAINED, {
            "combatant_id": c.combatant_id, 
            "amount": awarded_xp, 
        }))
        var levels_gained: int = c.source_exile.level - level_before
        if levels_gained <= 0:
            continue


        c.current_life = c.max_life
        c.level_up_pending = true
        event_log.append(CombatEvent.create(current_tick, CombatEnums.CombatEventType.LEVEL_UP, {
            "combatant_id": c.combatant_id, 
            "new_level": c.source_exile.level, 
            "levels_gained": levels_gained, 
        }))






func _is_stalled() -> bool:
    if _overtime_active:
        return false
    if current_tick < STALL_MIN_COMBAT_DURATION:
        return false
    return (current_tick - _last_damage_tick) >= STALL_NO_DAMAGE_THRESHOLD









func _check_overtime_transition() -> void :
    if _overtime_active:
        return
    if current_tick < max_duration:
        return
    _overtime_active = true
    _next_desperation_stack_at = current_tick
    event_log.append(CombatEvent.create(current_tick, CombatEnums.CombatEventType.OVERTIME_BEGAN, {
        "duration_so_far": current_tick, 
    }))








func _tick_desperation_stacks() -> void :
    if not _overtime_active:
        return
    if current_tick < _next_desperation_stack_at:
        return
    _next_desperation_stack_at += DESPERATION_STACK_INTERVAL

    var resulting_stacks: int = 0
    for combatant in combatants:
        if not combatant.is_alive():
            continue
        var active: ActiveStatusEffect = combatant.apply_status_effect(DESPERATION_EFFECT, current_tick, 1)
        if active != null:
            resulting_stacks = active.stacks


    if resulting_stacks <= 0:
        return

    var damage_per_stack: float = float(DESPERATION_EFFECT.stat_modifiers.get("damage_dealt_more_pct", 0.0))
    var drain_per_stack: float = float(DESPERATION_EFFECT.per_tick_effects.get("vitality_drain_per_sec", 0.0))
    event_log.append(CombatEvent.create(current_tick, CombatEnums.CombatEventType.DESPERATION_INCREASED, {
        "stacks": resulting_stacks, 
        "damage_more_pct": damage_per_stack * float(resulting_stacks), 
        "vitality_drain_per_sec": drain_per_stack * float(resulting_stacks), 
    }))















func _apply_status_effect_drains() -> void :
    for combatant in combatants:
        if not combatant.is_alive():
            continue

        if not combatant.active_status_effects.is_empty():

            var drain_per_sec: float = 0.0
            for active in combatant.active_status_effects:
                drain_per_sec += active.get_per_tick_total("vitality_drain_per_sec")
            if drain_per_sec > 0.0:
                combatant.apply_drain(drain_per_sec * TICK_STEP)




            for active in combatant.active_status_effects:
                var dot_per_sec: float = active.get_per_tick_total("fire_damage_per_sec")
                if dot_per_sec > 0.0:
                    combatant.apply_dot_damage(dot_per_sec * TICK_STEP, active.applier_id)







        if combatant.has_poisons():
            for stack in combatant.poison_stacks:
                if stack == null or stack.damage_per_sec <= 0.0:
                    continue
                combatant.apply_dot_damage(stack.damage_per_sec * TICK_STEP, stack.applier_id)
















func _tick_status_effect_expiries() -> void :
    for combatant in combatants:
        if combatant.active_status_effects.is_empty():
            continue
        var i: int = combatant.active_status_effects.size() - 1
        while i >= 0:
            var active: ActiveStatusEffect = combatant.active_status_effects[i]
            if active != null and active.expires_at_tick <= current_tick:
                var expired_effect: StatusEffect = active.effect
                var expired_id: StringName = expired_effect.effect_id if expired_effect != null else &""




                var expired_display: String = expired_effect.display_name if expired_effect != null else ""
                combatant.active_status_effects.remove_at(i)




                event_log.append(CombatEvent.create(current_tick, CombatEnums.CombatEventType.STATUS_EFFECT_EXPIRED, {
                    "combatant_id": combatant.combatant_id, 
                    "effect_id": expired_id, 
                    "display_name": expired_display, 
                    "effect": expired_effect, 
                }))
            i -= 1





    for combatant in combatants:
        if not combatant.has_poisons():
            continue
        var expired_stacks: Array[PoisonStack] = combatant.tick_poison_expiries(current_tick)
        if expired_stacks.is_empty():
            continue
        var remaining: int = combatant.poison_stacks.size()
        for _stack in expired_stacks:
            event_log.append(CombatEvent.create(current_tick, CombatEnums.CombatEventType.POISON_EXPIRED, {
                "combatant_id": combatant.combatant_id, 
                "stacks_remaining": remaining, 
            }))


















func _check_drain_deaths() -> void :
    for combatant in combatants:
        if not combatant.is_alive():
            continue
        if combatant.current_life > 0.0:
            continue

        var dot_applier: int = combatant.last_dot_damage_applier_id
        var source: String = "desperation_drain"
        var killer_id: int = -1




        if dot_applier >= 0 and _has_active_dot(combatant):
            killer_id = dot_applier





            source = "poison_dot" if _has_only_poison_dot(combatant) else "ignite_dot"

        if combatant.source_exile != null:
            combatant.state = CombatEnums.CombatantState.DOWNED
            combatant.was_downed = true
            event_log.append(CombatEvent.create(current_tick, CombatEnums.CombatEventType.DOWNED, {
                "combatant_id": combatant.combatant_id, 
                "killer_id": killer_id, 
                "source": source, 
            }))
        else:
            combatant.state = CombatEnums.CombatantState.DEAD
            event_log.append(CombatEvent.create(current_tick, CombatEnums.CombatEventType.DEATH, {
                "combatant_id": combatant.combatant_id, 
                "killer_id": killer_id, 
                "source": source, 
            }))







func _has_active_dot(combatant: CombatantData) -> bool:
    for active in combatant.active_status_effects:
        if active != null and active.effect != null and active.effect.is_damage_over_time:
            return true

    if combatant.has_poisons():
        return true
    return false







func _has_only_poison_dot(combatant: CombatantData) -> bool:
    if not combatant.has_poisons():
        return false
    for active in combatant.active_status_effects:
        if active != null and active.effect != null and active.effect.is_damage_over_time:
            return false
    return true


func _get_living_enemies(combatant: CombatantData) -> Array[CombatantData]:
    var enemies: Array[CombatantData] = []
    for other in combatants:
        if other.is_alive() and combatant.is_enemy_of(other):
            enemies.append(other)
    return enemies






func _get_living_allies(combatant: CombatantData) -> Array[CombatantData]:
    var allies: Array[CombatantData] = []
    for other in combatants:
        if other.is_alive() and not combatant.is_enemy_of(other):
            allies.append(other)
    return allies


func _next_id() -> int:
    var id: = _next_combatant_id
    _next_combatant_id += 1
    return id


func _all_dead_on_team(team: CombatEnums.CombatantTeam) -> bool:
    for c in combatants:
        if c.team == team and c.is_alive():
            return false
    return true


func _all_downed_on_team(team: CombatEnums.CombatantTeam) -> bool:
    for c in combatants:
        if c.team == team and c.is_alive():
            return false
    return true


func _end_combat(result: CombatEnums.CombatResult) -> void :
    combat_result = result
    simulation_state = SimulationState.COMPLETE
    event_log.append(CombatEvent.create(current_tick, CombatEnums.CombatEventType.COMBAT_END, {
        "result": result, 
        "duration": current_tick, 
    }))












func _pick_kite_deviation(combatant: CombatantData, base_away: Vector2, retreat_distance: float) -> float:
    var profile: TacticalProfile = combatant.combat_behavior.get_tactical()
    var max_dev_rad: float = deg_to_rad(profile.kite_max_deviation_degrees)
    var jitter_rad: float = deg_to_rad(profile.kite_angle_jitter_degrees)



    var biased_dev: float = 0.0
    if profile.kite_open_space_weight > 0.0 and profile.kite_candidate_count >= 2 and max_dev_rad > 0.0:
        var best_score: float = - INF
        var best_dev: float = 0.0
        var n: int = profile.kite_candidate_count
        for i in n:
            var t: float = float(i) / float(n - 1)
            var dev: float = lerpf( - max_dev_rad, max_dev_rad, t)
            var dest: Vector2 = combatant.position + base_away.rotated(dev) * retreat_distance
            var score: float = _score_kite_destination(combatant, dest)
            if score > best_score:
                best_score = score
                best_dev = dev


        biased_dev = best_dev * profile.kite_open_space_weight


    var jitter: float = rng.randf_range( - jitter_rad, jitter_rad)
    return clampf(biased_dev + jitter, - max_dev_rad, max_dev_rad)






func _score_kite_destination(combatant: CombatantData, dest: Vector2) -> float:
    var arena_w: float = _encounter.arena_width
    var arena_h: float = _encounter.arena_height

    var edge_score: float = minf(
        minf(dest.x - ARENA_EDGE_INSET, arena_w - ARENA_EDGE_INSET - dest.x), 
        minf(dest.y - ARENA_EDGE_INSET, arena_h - ARENA_EDGE_INSET - dest.y)
    )

    var avoid_radius: float = combatant.combat_behavior.preferred_distance
    if avoid_radius <= 0.0:
        return edge_score

    var enemy_penalty: float = 0.0
    for other in combatants:
        if not other.is_alive():
            continue
        if not combatant.is_enemy_of(other):
            continue
        if other.combatant_id == combatant.current_target_id:
            continue
        var dist: float = dest.distance_to(other.position)
        if dist < avoid_radius:
            enemy_penalty += (avoid_radius - dist)

    return edge_score - enemy_penalty










func _debug_log_ai(combatant: CombatantData, target: CombatantData, action_type: int) -> void :
    if not DEBUG_AI:
        return
    if not DEBUG_AI_FILTER_NAME.is_empty():

        if not combatant.display_name.to_lower().contains(DEBUG_AI_FILTER_NAME.to_lower()):
            return


    var prev_action: int = _debug_last_action.get(combatant.combatant_id, -999)
    var action_changed: bool = action_type != prev_action
    _debug_last_action[combatant.combatant_id] = action_type


    var tick_idx: int = roundi(current_tick / TICK_STEP)
    var sample_due: bool = DEBUG_AI_SAMPLE_INTERVAL > 0 and tick_idx % DEBUG_AI_SAMPLE_INTERVAL == 0


    if not sample_due and not (DEBUG_AI_LOG_ON_CHANGE and action_changed):
        return

    var state_name: String = CombatEnums.CombatantState.keys()[combatant.state]
    var move_str: String = "never" if combatant.last_move_tick <= -999.0 else ("%.2f" % combatant.last_move_tick)
    var change_marker: String = "*" if action_changed else " "

    var line: String = "[t=%.1f]%s %s state=%s cd=%.2f move=%s" % [
        current_tick, change_marker, combatant.display_name, state_name, 
        combatant.attack_cooldown, move_str, 
    ]
    if target == null:
        line += " action=<no-target>"
    else:
        var behavior: CombatBehavior = combatant.combat_behavior
        line += " action=%s target=%s dist=%.2f range=%.1f pref=%.1f" % [
            CombatAI.ActionType.keys()[action_type], 
            target.display_name, 
            combatant.distance_to(target), 
            behavior.attack_range, 
            behavior.preferred_distance, 
        ]
    print(line)
