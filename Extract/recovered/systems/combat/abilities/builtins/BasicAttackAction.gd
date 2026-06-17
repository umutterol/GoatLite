class_name BasicAttackAction
extends AbilityAction

















func tick(_delta: float) -> Array:
    var events: Array = []



    if target == null or not target.is_alive():
        phase = AbilityEnums.ActionPhase.DONE
        return events



    owner.state = CombatEnums.CombatantState.ATTACKING

    events.append(CombatEvent.create(sim.current_tick, CombatEnums.CombatEventType.ATTACK_START, {
        "attacker_id": owner.combatant_id, 
        "defender_id": target.combatant_id, 
    }))





    var result: Dictionary = DamagePipeline.resolve_attack(owner, target, sim.current_tick, sim.rng, ability)
    for event in result["events"]:
        events.append(event)



    owner.kite_deviation_radians = NAN

    owner.state = CombatEnums.CombatantState.IDLE
    phase = AbilityEnums.ActionPhase.DONE
    return events
