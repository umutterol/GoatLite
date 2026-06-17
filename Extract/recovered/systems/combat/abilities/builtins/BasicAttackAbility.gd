class_name BasicAttackAbility
extends MonsterAbility































func get_effective_range(p_owner: CombatantData) -> float:
    if p_owner.combat_behavior == null:


        return ability_range
    return p_owner.combat_behavior.attack_range





func get_effective_cooldown(p_owner: CombatantData) -> float:
    return p_owner.get_attack_interval()




func create_action(p_owner: CombatantData, p_sim, p_target: CombatantData) -> AbilityAction:
    var action: = BasicAttackAction.new()
    action.setup(self, p_owner, p_sim, p_target)
    return action
