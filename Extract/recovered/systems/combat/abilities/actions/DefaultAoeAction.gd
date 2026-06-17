class_name DefaultAoeAction
extends AbilityAction


























var cast_origin: Vector2 = Vector2.ZERO





var cast_forward: Vector2 = Vector2.RIGHT






func setup(p_ability: MonsterAbility, p_owner: CombatantData, p_sim, p_target: CombatantData) -> AbilityAction:
    super (p_ability, p_owner, p_sim, p_target)







    var centre_on_target: bool = p_ability.aoe_centred_on_target\
and p_target != null\
and p_ability.shape == CombatEnums.AbilityType.CIRCLE
    cast_origin = p_target.position if centre_on_target else p_owner.position

    if p_target != null:
        var to_target: Vector2 = p_target.position - p_owner.position
        if to_target.length_squared() > 0.0001:
            cast_forward = to_target.normalized()





    phase = AbilityEnums.ActionPhase.TELEGRAPH
    phase_timer = 0.0
    return self






func tick(delta: float) -> Array:
    var events: Array = []
    phase_timer += delta

    match phase:
        AbilityEnums.ActionPhase.TELEGRAPH:
            _tick_telegraph(events)
        AbilityEnums.ActionPhase.EXECUTE:
            _tick_execute(events)
        AbilityEnums.ActionPhase.RECOVERY:
            _tick_recovery(events)
        AbilityEnums.ActionPhase.DONE:
            pass

    return events









func _tick_telegraph(events: Array) -> void :




    if not _telegraph_emitted:
        events.append(CombatEvent.create(sim.current_tick, CombatEnums.CombatEventType.ABILITY_TELEGRAPHED, {
            "actor_id": owner.combatant_id, 
            "ability_id": ability.ability_id, 
            "ability": ability, 
            "shape": ability.shape, 
            "origin": cast_origin, 
            "direction": cast_forward, 



            "aoe_size": ability.aoe_size, 
            "duration": ability.wind_up_seconds, 
        }))
        _telegraph_emitted = true

    if phase_timer >= ability.wind_up_seconds:
        _enter_phase(AbilityEnums.ActionPhase.EXECUTE)







func _tick_execute(events: Array) -> void :
    events.append(CombatEvent.create(sim.current_tick, CombatEnums.CombatEventType.ABILITY_EXECUTED, {
        "actor_id": owner.combatant_id, 
        "ability_id": ability.ability_id, 



        "ability": ability, 
    }))

    var hit_targets: Array[CombatantData] = _resolve_shape_targets()





    var hit_ids: Array[int] = []
    for hit in hit_targets:
        var result: Dictionary = DamagePipeline.resolve_attack(owner, hit, sim.current_tick, sim.rng, ability)
        for sub_event in result["events"]:
            events.append(sub_event)
        hit_ids.append(hit.combatant_id)





    events.append(CombatEvent.create(sim.current_tick, CombatEnums.CombatEventType.AOE_HIT, {
        "actor_id": owner.combatant_id, 
        "ability_id": ability.ability_id, 
        "ability": ability, 
        "origin": cast_origin, 
        "direction": cast_forward, 
        "hit_target_ids": hit_ids, 
    }))

    if ability.recovery_seconds > 0.0:
        _enter_phase(AbilityEnums.ActionPhase.RECOVERY)
    else:
        _enter_phase(AbilityEnums.ActionPhase.DONE)






func _tick_recovery(events: Array) -> void :
    if not _recovery_emitted:
        events.append(CombatEvent.create(sim.current_tick, CombatEnums.CombatEventType.ACTION_RECOVERY, {
            "actor_id": owner.combatant_id, 
            "ability_id": ability.ability_id, 
            "duration": ability.recovery_seconds, 
        }))
        _recovery_emitted = true

    if phase_timer >= ability.recovery_seconds:
        _enter_phase(AbilityEnums.ActionPhase.DONE)










func _resolve_shape_targets() -> Array[CombatantData]:
    var enemies: Array[CombatantData] = _living_enemies()


    var size: float = ability.aoe_size
    match ability.shape:
        CombatEnums.AbilityType.SINGLE_TARGET:




            if target != null and target.is_alive():
                return [target] as Array[CombatantData]
            return [] as Array[CombatantData]
        CombatEnums.AbilityType.LINE:


            return AbilityShapes.line(cast_origin, cast_forward, size, 1.5, enemies)
        CombatEnums.AbilityType.CONE:


            return AbilityShapes.cone(cast_origin, cast_forward, size, PI / 6.0, enemies)
        CombatEnums.AbilityType.CIRCLE:
            return AbilityShapes.circle(cast_origin, size, enemies)
        CombatEnums.AbilityType.RECTANGLE:

            return AbilityShapes.rectangle(cast_origin + cast_forward * (size * 0.5), 
                cast_forward, size, 2.0, enemies)
        _:
            push_warning("DefaultAoeAction: unmapped shape %d on ability '%s' — no targets hit." % [ability.shape, ability.ability_id])
            return [] as Array[CombatantData]




func _living_enemies() -> Array[CombatantData]:
    var result: Array[CombatantData] = []
    for c in sim.combatants:
        if c.is_alive() and owner.is_enemy_of(c):
            result.append(c)
    return result








var _telegraph_emitted: bool = false


var _recovery_emitted: bool = false
