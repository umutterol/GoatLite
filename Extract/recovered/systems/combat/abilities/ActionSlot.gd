class_name ActionSlot
extends RefCounted













var slot_id: int = 0


var slot_name: String = "body"









var abilities: Array[MonsterAbility] = []





var locks_owner_movement: bool = true






var cooldowns: Dictionary = {}




var current_action: AbilityAction = null










const BASIC_ATTACK_ABILITY: MonsterAbility = preload("res://systems/combat/abilities/resources/basic_attack.tres")










static func from_config(config: ActionSlotConfig, p_slot_id: int) -> ActionSlot:
    var slot: = ActionSlot.new()
    slot.slot_id = p_slot_id
    slot.slot_name = config.slot_name
    slot.locks_owner_movement = config.locks_owner_movement


    slot.abilities = config.abilities.duplicate()




    if config.include_basic_attack and not _list_contains_basic_attack(slot.abilities):
        slot.abilities.append(BASIC_ATTACK_ABILITY)
    for ability in slot.abilities:
        if ability == null:
            push_warning("ActionSlot.from_config: null ability in slot '%s' — fix the .tres." % config.slot_name)
            continue
        slot.cooldowns[ability.ability_id] = 0.0
    return slot





static func _list_contains_basic_attack(abilities: Array[MonsterAbility]) -> bool:
    for ability in abilities:
        if ability != null and ability.ability_id == BASIC_ATTACK_ABILITY.ability_id:
            return true
    return false








func is_free() -> bool:
    return current_action == null



func decrement_cooldowns(delta: float) -> void :
    for key in cooldowns.keys():
        cooldowns[key] = maxf(cooldowns[key] - delta, 0.0)



func is_ready(ability: MonsterAbility) -> bool:
    return cooldowns.get(ability.ability_id, 0.0) <= 0.0
