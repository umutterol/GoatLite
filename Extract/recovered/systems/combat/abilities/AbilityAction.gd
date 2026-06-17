class_name AbilityAction
extends RefCounted























var ability: MonsterAbility = null


var owner: CombatantData = null



var sim = null




var target: CombatantData = null





var phase: AbilityEnums.ActionPhase = AbilityEnums.ActionPhase.TELEGRAPH



var phase_timer: float = 0.0




var locks_owner_movement: bool = true








func setup(p_ability: MonsterAbility, p_owner: CombatantData, p_sim, p_target: CombatantData) -> AbilityAction:
    ability = p_ability
    owner = p_owner
    sim = p_sim
    target = p_target
    phase = AbilityEnums.ActionPhase.TELEGRAPH
    phase_timer = 0.0
    return self



















func tick(_delta: float) -> Array:
    push_warning("AbilityAction.tick called on base class — subclass should override. ability=%s" % (ability.ability_id if ability else "<null>"))
    phase = AbilityEnums.ActionPhase.DONE
    return []









func _enter_phase(new_phase: AbilityEnums.ActionPhase) -> void :
    phase = new_phase
    phase_timer = 0.0



func is_finished() -> bool:
    return phase == AbilityEnums.ActionPhase.DONE
