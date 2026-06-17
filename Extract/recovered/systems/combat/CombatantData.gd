class_name CombatantData
extends RefCounted








var combatant_id: int = -1
var display_name: String = ""
var team: CombatEnums.CombatantTeam = CombatEnums.CombatantTeam.EXILES





var source_exile: ExileData = null
var source_monster: MonsterData = null





var stats: ExileStats = null



var position: Vector2 = Vector2.ZERO



var state: CombatEnums.CombatantState = CombatEnums.CombatantState.IDLE
var current_target_id: int = -1



var spawn_group_index: int = -1





var current_life: float = 0.0
var max_life: float = 0.0
var current_energy_shield: float = 0.0
var max_energy_shield: float = 0.0








var current_vitality: float = 0.0
var max_vitality: float = 0.0








var current_morale: float = 0.0
var max_morale: float = 0.0



var total_morale_lost: int = 0









var attack_cooldown: float = 0.0


const BASE_MOVEMENT_RATE: float = 5.0








var base_movement_speed: float = 5.0




var combat_behavior: CombatBehavior = null








var action_slots: Array[ActionSlot] = []



var total_damage_dealt: float = 0.0
var total_damage_taken: float = 0.0
var kills: int = 0
var was_downed: bool = false
var second_wind_triggered: bool = false






var sticky_target_until: float = -1.0



var last_melee_hit_tick: float = -1000.0


var last_melee_attacker_was_faster: bool = false




var last_move_tick: float = -1000.0






var kite_deviation_radians: float = NAN








var scaled_experience_value: int = 0



var xp_earned_this_combat: int = 0








var xp_at_combat_start: int = 0


var level_at_combat_start: int = 1




var level_up_pending: bool = false








var morale_combat_modifiers: Dictionary = {
    "damage_dealt_more": 0.0, 
    "damage_taken_less": 0.0, 
    "experience_more": 0.0, 
}








var active_status_effects: Array[ActiveStatusEffect] = []















var impale_stacks: Array[ImpaleStack] = []















var poison_stacks: Array[PoisonStack] = []








static func from_exile(exile: ExileData, id: int) -> CombatantData:
    var c: = CombatantData.new()
    c.combatant_id = id
    c.display_name = exile.name
    c.team = CombatEnums.CombatantTeam.EXILES
    c.source_exile = exile



    c.xp_at_combat_start = exile.experience
    c.level_at_combat_start = exile.level


    var source_stats: ExileStats = exile.current_stats
    if source_stats == null:
        push_warning("CombatantData.from_exile: exile '%s' has null current_stats" % exile.name)
        source_stats = exile.base_stats
    c.stats = source_stats.duplicate()


    c.max_life = c.stats.life
    c.current_life = exile.current_life
    c.max_energy_shield = c.stats.energy_shield
    c.current_energy_shield = c.stats.energy_shield





    c.max_vitality = c.stats.vitality
    c.current_vitality = exile.current_vitality




    c.max_morale = exile.current_stats.max_morale
    c.current_morale = exile.current_stats.morale

    c.base_movement_speed = BASE_MOVEMENT_RATE * (1.0 + c.stats.movement / 100.0) * c.stats.action_speed
    c.combat_behavior = CombatBehavior.resolve_for_exile(exile)





    c.morale_combat_modifiers = MoraleManager.get_morale_combat_modifiers(exile)




    c.action_slots.append(_build_default_basic_attack_slot())
    return c













static func from_monster(monster: MonsterData, id: int, mission_level: int = -1) -> CombatantData:
    if monster == null:
        push_error("CombatantData.from_monster: null MonsterData (id=%d). Check the encounter's monster_spawns for missing references." % id)
        return null
    var c: = CombatantData.new()
    c.combatant_id = id
    c.display_name = monster.display_name
    c.team = CombatEnums.CombatantTeam.MONSTERS
    c.source_monster = monster

    var source_stats: ExileStats = monster.base_stats
    if source_stats == null:
        push_warning("CombatantData.from_monster: monster '%s' has null base_stats" % monster.display_name)
        source_stats = ExileStats.new()
    c.stats = source_stats.duplicate()



    _apply_monster_level_scaling(c.stats, monster.base_level, mission_level)




    var xp_mult: float = _compute_level_scale_multiplier(
        monster.base_level, mission_level, GameSettings.MONSTER_XP_PCT_PER_LEVEL
    )
    c.scaled_experience_value = int(round(monster.experience_value * xp_mult))


    c.max_life = c.stats.life
    c.current_life = c.stats.life
    c.max_energy_shield = c.stats.energy_shield
    c.current_energy_shield = c.stats.energy_shield


    c.max_vitality = c.stats.vitality
    c.current_vitality = c.stats.vitality

    c.base_movement_speed = BASE_MOVEMENT_RATE * (1.0 + c.stats.movement / 100.0) * c.stats.action_speed

    if monster.combat_behavior != null:
        c.combat_behavior = monster.combat_behavior
    else:
        c.combat_behavior = CombatBehavior.new()




    if monster.action_slot_configs.is_empty():
        c.action_slots.append(_build_default_basic_attack_slot())
    else:
        for slot_index in monster.action_slot_configs.size():
            var config: ActionSlotConfig = monster.action_slot_configs[slot_index]
            if config == null:
                push_warning(
                    "CombatantData.from_monster: monster '%s' has null ActionSlotConfig at index %d — skipping." %
                    [monster.display_name, slot_index]
                )
                continue
            c.action_slots.append(ActionSlot.from_config(config, slot_index))

    return c







static func _build_default_basic_attack_slot() -> ActionSlot:
    var default_config: = ActionSlotConfig.new()



    return ActionSlot.from_config(default_config, 0)










static func _apply_monster_level_scaling(
    stats: ExileStats, base_level: int, mission_level: int
) -> void :
    if mission_level <= base_level:
        return
    var life_mult: float = _compute_level_scale_multiplier(
        base_level, mission_level, GameSettings.MONSTER_LIFE_PCT_PER_LEVEL
    )
    var vitality_mult: float = _compute_level_scale_multiplier(
        base_level, mission_level, GameSettings.MONSTER_VITALITY_PCT_PER_LEVEL
    )
    var damage_mult: float = _compute_level_scale_multiplier(
        base_level, mission_level, GameSettings.MONSTER_DAMAGE_PCT_PER_LEVEL
    )
    stats.life *= life_mult
    stats.vitality *= vitality_mult
    stats.physical_damage *= damage_mult
    stats.fire_damage *= damage_mult
    stats.cold_damage *= damage_mult
    stats.lightning_damage *= damage_mult
    stats.chaos_damage *= damage_mult






static func _compute_level_scale_multiplier(
    base_level: int, mission_level: int, pct_per_level: float
) -> float:
    if mission_level <= base_level:
        return 1.0
    var level_diff: int = mission_level - base_level
    return 1.0 + (level_diff * pct_per_level / 100.0)






func is_alive() -> bool:
    return state != CombatEnums.CombatantState.DEAD and state != CombatEnums.CombatantState.DOWNED


func is_enemy_of(other: CombatantData) -> bool:

    if team == CombatEnums.CombatantTeam.EXILES or team == CombatEnums.CombatantTeam.EXILES_ALLIES:
        return other.team == CombatEnums.CombatantTeam.MONSTERS or other.team == CombatEnums.CombatantTeam.ROGUE_EXILES
    if team == CombatEnums.CombatantTeam.MONSTERS:
        return other.team == CombatEnums.CombatantTeam.EXILES or other.team == CombatEnums.CombatantTeam.EXILES_ALLIES

    return other.team != team


func distance_to(other: CombatantData) -> float:
    return position.distance_to(other.position)










func _status_action_speed_multiplier() -> float:
    var more_pct: float = get_aggregate_modifier("action_speed_more_pct")
    return maxf(1.0 + more_pct / 100.0, 0.0)





func get_effective_movement_speed() -> float:
    return base_movement_speed * _status_action_speed_multiplier()


func get_attack_interval() -> float:
    var effective_speed: = stats.attack_speed * stats.action_speed * _status_action_speed_multiplier()
    if effective_speed <= 0.0:
        return INF
    return 1.0 / effective_speed





const _VFX_SWING_DEFAULT: Resource = preload("res://systems/combat/vfx/presets/swing_default.tres")
const _VFX_LINE_DEFAULT: Resource = preload("res://systems/combat/vfx/presets/line_default.tres")
const _VFX_LIGHTNING_DEFAULT: Resource = preload("res://systems/combat/vfx/presets/lightning_default.tres")











func get_ability_vfx(ability: MonsterAbility) -> AttackVFX:
    if ability != null and ability.execute_vfx != null:
        return ability.execute_vfx
    return get_attack_vfx()














func get_attack_vfx() -> AttackVFX:
    if source_exile != null:
        return _vfx_for_exile(source_exile)
    if combat_behavior != null and combat_behavior.basic_attack_vfx_override != null:
        return combat_behavior.basic_attack_vfx_override
    if combat_behavior != null and combat_behavior.attack_range > 4.0:
        return _VFX_LINE_DEFAULT
    return _VFX_SWING_DEFAULT


static func _vfx_for_exile(exile: ExileData) -> AttackVFX:
    var weapon: Item = exile.get_equipped_item(ItemEnums.EquipSlot.MAIN_HAND)
    if weapon == null:
        weapon = exile.get_equipped_item(ItemEnums.EquipSlot.BOTH_HANDS)
    if weapon == null or weapon.base_item == null:
        return _VFX_SWING_DEFAULT
    var base: ItemBase = weapon.base_item
    if base.attack_vfx != null:
        return base.attack_vfx
    if base.ranged:

        if base.weapon_type == ItemEnums.WeaponType.WAND:
            return _VFX_LIGHTNING_DEFAULT
        return _VFX_LINE_DEFAULT


    match base.weapon_type:
        ItemEnums.WeaponType.SPEAR, ItemEnums.WeaponType.DAGGER:
            return _VFX_LINE_DEFAULT
        ItemEnums.WeaponType.SWORD, ItemEnums.WeaponType.AXE, \
ItemEnums.WeaponType.MACE, ItemEnums.WeaponType.STAFF, \
ItemEnums.WeaponType.UNARMED:
            return _VFX_SWING_DEFAULT
        _:
            push_warning(
                "CombatantData._vfx_for_exile: unmapped weapon_type %d on '%s' — defaulting to swing. Classify it in this match."
                %[base.weapon_type, base.resource_path]
            )
            return _VFX_SWING_DEFAULT


func get_resistance(damage_type: String) -> float:
    return stats.get_resistance(damage_type)


func get_resistance_cap(damage_type: String) -> float:
    return stats.get_resistance_cap(damage_type)
























func apply_combat_heal(requested: float) -> float:
    if requested <= 0.0:
        return 0.0
    var headroom: float = max_life - current_life
    if headroom <= 0.0:
        return 0.0

    var actual: float = minf(requested, headroom)




    var vitality_budget: float = current_vitality / GameSettings.VITALITY_PER_LIFE_HEALED
    actual = minf(actual, vitality_budget)
    if actual <= 0.0:
        return 0.0
    current_vitality = maxf(current_vitality - actual * GameSettings.VITALITY_PER_LIFE_HEALED, 0.0)

    current_life += actual
    return actual



































func apply_status_effect(
    effect: StatusEffect, 
    current_tick: float, 
    stacks_to_add: int = 1, 
    magnitude_multiplier: float = 1.0, 
    duration_multiplier: float = 1.0, 
    applier_id: int = -1, 
) -> ActiveStatusEffect:
    if effect == null or stacks_to_add <= 0:
        return null
    var cap: int = effect.max_stacks if effect.max_stacks > 0 else 100
    var fresh_expiry: float = _compute_expiry(effect, current_tick, duration_multiplier)
    var existing: ActiveStatusEffect = get_status_effect(effect.effect_id)
    if existing == null:
        existing = ActiveStatusEffect.new()
        existing.effect = effect
        existing.stacks = mini(stacks_to_add, cap)
        existing.applied_at_tick = current_tick
        existing.expires_at_tick = fresh_expiry
        existing.magnitude_multiplier = magnitude_multiplier
        existing.applier_id = applier_id
        active_status_effects.append(existing)
        return existing






    match effect.refresh_mode:
        StatusEffect.RefreshMode.REPLACE:
            existing.stacks = mini(stacks_to_add, cap)
            existing.applied_at_tick = current_tick
            existing.expires_at_tick = fresh_expiry
            existing.magnitude_multiplier = magnitude_multiplier
            existing.applier_id = applier_id
        StatusEffect.RefreshMode.REFRESH_DURATION:
            existing.stacks = mini(existing.stacks + stacks_to_add, cap)
            existing.applied_at_tick = current_tick
            existing.expires_at_tick = fresh_expiry
            existing.magnitude_multiplier = magnitude_multiplier
            existing.applier_id = applier_id
        StatusEffect.RefreshMode.IGNORE:
            pass
        StatusEffect.RefreshMode.REPLACE_IF_STRONGER:















            if magnitude_multiplier > existing.magnitude_multiplier:
                existing.stacks = mini(stacks_to_add, cap)
                existing.applied_at_tick = current_tick
                existing.expires_at_tick = fresh_expiry
                existing.magnitude_multiplier = magnitude_multiplier
                existing.applier_id = applier_id
    return existing





static func _compute_expiry(effect: StatusEffect, current_tick: float, duration_multiplier: float = 1.0) -> float:
    if effect.duration_seconds <= 0.0:
        return INF
    return current_tick + effect.duration_seconds * duration_multiplier





func remove_status_effect(effect_id: StringName) -> bool:
    for i in range(active_status_effects.size()):
        var active: ActiveStatusEffect = active_status_effects[i]
        if active != null and active.effect != null and active.effect.effect_id == effect_id:
            active_status_effects.remove_at(i)
            return true
    return false














func is_immune_to_ailment(effect_id: StringName) -> bool:
    if stats == null:
        return false
    return effect_id in stats.ailment_immunities





func get_status_effect(effect_id: StringName) -> ActiveStatusEffect:
    for active in active_status_effects:
        if active != null and active.effect != null and active.effect.effect_id == effect_id:
            return active
    return null






func get_aggregate_modifier(key: String) -> float:
    var total: float = 0.0
    for active in active_status_effects:
        total += active.get_modifier_total(key)
    return total








func apply_drain(amount: float) -> void :
    if amount <= 0.0:
        return
    var vit_spent: float = minf(amount, current_vitality)
    current_vitality -= vit_spent
    var remaining: float = amount - vit_spent
    if remaining > 0.0:
        current_life = maxf(current_life - remaining, 0.0)







var last_dot_damage_applier_id: int = -1















func apply_dot_damage(amount: float, applier_id: int) -> void :
    if amount <= 0.0:
        return
    var shield_taken: float = minf(amount, current_energy_shield)
    current_energy_shield -= shield_taken
    var life_taken: float = amount - shield_taken
    if life_taken > 0.0:
        current_life = maxf(current_life - life_taken, 0.0)



    last_dot_damage_applier_id = applier_id








func has_impales() -> bool:
    return not impale_stacks.is_empty()



















func add_impale(flat_damage: float, applier_id: int, current_tick: float, max_stacks: int) -> int:



    if flat_damage <= 0.0 or max_stacks <= 0:
        return impale_stacks.size()





    while impale_stacks.size() >= max_stacks:
        impale_stacks.pop_front()

    var stack: = ImpaleStack.new()
    stack.flat_damage = flat_damage
    stack.applier_id = applier_id
    stack.applied_at_tick = current_tick
    impale_stacks.append(stack)
    return impale_stacks.size()










func consume_impales() -> Dictionary:
    var total: float = 0.0
    var count: int = impale_stacks.size()
    for stack in impale_stacks:
        total += stack.flat_damage
    impale_stacks.clear()
    return {"total": total, "count": count}









func has_poisons() -> bool:
    return not poison_stacks.is_empty()
















func add_poison(
    damage_per_sec: float, 
    applier_id: int, 
    current_tick: float, 
    expires_at_tick: float, 
    max_stacks: int, 
) -> int:



    if damage_per_sec <= 0.0 or max_stacks <= 0:
        return poison_stacks.size()




    while poison_stacks.size() >= max_stacks:
        poison_stacks.pop_front()

    var stack: = PoisonStack.new()
    stack.damage_per_sec = damage_per_sec
    stack.applier_id = applier_id
    stack.applied_at_tick = current_tick
    stack.expires_at_tick = expires_at_tick
    poison_stacks.append(stack)
    return poison_stacks.size()









func tick_poison_expiries(current_tick: float) -> Array[PoisonStack]:
    var expired: Array[PoisonStack] = []
    if poison_stacks.is_empty():
        return expired
    var i: int = poison_stacks.size() - 1
    while i >= 0:
        var stack: PoisonStack = poison_stacks[i]
        if stack != null and stack.expires_at_tick <= current_tick:
            expired.append(stack)
            poison_stacks.remove_at(i)
        i -= 1
    return expired






func get_poison_dps_total() -> float:
    var total: float = 0.0
    for stack in poison_stacks:
        if stack != null:
            total += stack.damage_per_sec
    return total
