extends Node

func _ready() -> void :
    print("\n=== COMBATANT DATA TEST ===\n")
    _test_from_exile()
    _test_from_monster()
    _test_stats_isolation()
    _test_attack_interval()
    _test_movement_speed()
    _test_team_hostility()
    _test_combat_event()
    _test_tactics_override()
    print("\n=== ALL TESTS COMPLETE ===")


func _test_from_exile() -> void :
    print("--- from_exile ---")
    var exile: = _make_test_exile()
    var c: = CombatantData.from_exile(exile, 1)

    print("  id: %d (expected 1)" % c.combatant_id)
    print("  name: %s (expected Test Exile)" % c.display_name)
    print("  team: %d (expected %d/EXILES)" % [c.team, CombatEnums.CombatantTeam.EXILES])
    print("  source_exile non-null: %s" % (c.source_exile != null))
    print("  source_monster null: %s" % (c.source_monster == null))
    print("  stats non-null: %s" % (c.stats != null))


    print("  max_life: %.0f (expected 200)" % c.max_life)
    print("  current_life: %.0f (expected 150 — exile was injured)" % c.current_life)


    print("  stats.armour: %.0f (expected 50)" % c.stats.armour)
    print("  stats.attack_speed: %.1f (expected 1.2)" % c.stats.attack_speed)
    print("  stats.physical_damage: %s (expected (5, 15))" % c.stats.physical_damage)
    print("  combat_behavior non-null: %s" % (c.combat_behavior != null))


func _test_from_monster() -> void :
    print("--- from_monster ---")
    var monster: = _make_test_monster()
    var c: = CombatantData.from_monster(monster, 10)

    print("  id: %d (expected 10)" % c.combatant_id)
    print("  name: %s (expected Test Zombie)" % c.display_name)
    print("  team: %d (expected %d/MONSTERS)" % [c.team, CombatEnums.CombatantTeam.MONSTERS])
    print("  source_monster non-null: %s" % (c.source_monster != null))
    print("  source_exile null: %s" % (c.source_exile == null))


    print("  max_life: %.0f (expected 80)" % c.max_life)
    print("  current_life: %.0f (expected 80)" % c.current_life)

    print("  stats.armour: %.0f (expected 20)" % c.stats.armour)


    print("  action_slots count: %d (expected 1)" % c.action_slots.size())
    var primary_slot: ActionSlot = c.action_slots[0]
    print("  slot[0].slot_name: %s (expected body)" % primary_slot.slot_name)
    print("  slot[0].abilities count: %d (expected 1)" % primary_slot.abilities.size())
    print("  slot[0].abilities[0].ability_id: %s (expected basic_attack)" % primary_slot.abilities[0].ability_id)
    print("  slot[0].cooldowns[basic_attack]: %.1f (expected 0.0)" % primary_slot.cooldowns.get("basic_attack", -1.0))


func _test_stats_isolation() -> void :
    print("--- Stats Isolation (duplicate doesn't bleed back) ---")
    var exile: = _make_test_exile()
    var original_armour: float = exile.current_stats.armour

    var c: = CombatantData.from_exile(exile, 1)

    c.stats.armour = 999.0

    var source_unchanged: bool = is_equal_approx(exile.current_stats.armour, original_armour)
    print("  Mutated combatant armour to 999")
    print("  Source exile armour still %.0f: %s" % [exile.current_stats.armour, source_unchanged])


    var monster: = _make_test_monster()
    var monster_original_armour: float = monster.base_stats.armour

    var mc: = CombatantData.from_monster(monster, 2)
    mc.stats.armour = 888.0

    var monster_unchanged: bool = is_equal_approx(monster.base_stats.armour, monster_original_armour)
    print("  Mutated monster combatant armour to 888")
    print("  Source monster armour still %.0f: %s" % [monster.base_stats.armour, monster_unchanged])


func _test_attack_interval() -> void :
    print("--- Attack Interval ---")
    var exile: = _make_test_exile()
    var c: = CombatantData.from_exile(exile, 1)


    var interval: = c.get_attack_interval()
    print("  speed 1.2, action 1.0: interval %.3f (expected ~0.833)" % interval)


    c.stats.action_speed = 0.7
    interval = c.get_attack_interval()
    print("  speed 1.2, action 0.7: interval %.3f (expected ~1.190)" % interval)


    c.stats.action_speed = 0.0
    interval = c.get_attack_interval()
    print("  speed 1.2, action 0.0: interval = INF: %s" % (interval == INF))


    c.stats.attack_speed = 0.0
    c.stats.action_speed = 1.0
    interval = c.get_attack_interval()
    print("  speed 0.0, action 1.0: interval = INF: %s" % (interval == INF))


func _test_movement_speed() -> void :
    print("--- Movement Speed ---")

    var exile: = _make_test_exile()
    exile.current_stats.movement = 0.0
    exile.current_stats.action_speed = 1.0
    var c: = CombatantData.from_exile(exile, 1)
    print("  0%% move, 1.0 action: %.1f (expected %.1f)" % [c.get_effective_movement_speed(), CombatantData.BASE_MOVEMENT_RATE])


    exile.current_stats.movement = 30.0
    c = CombatantData.from_exile(exile, 2)
    print("  +30%% move, 1.0 action: %.1f (expected 6.5)" % c.get_effective_movement_speed())


    exile.current_stats.movement = -10.0
    c = CombatantData.from_exile(exile, 3)
    print("  -10%% move, 1.0 action: %.1f (expected 4.5)" % c.get_effective_movement_speed())


    exile.current_stats.movement = 20.0
    exile.current_stats.action_speed = 1.1
    c = CombatantData.from_exile(exile, 4)
    print("  +20%% move, 1.1 action: %.1f (expected 6.6)" % c.get_effective_movement_speed())


func _test_team_hostility() -> void :
    print("--- Team Hostility ---")
    var exile_c: = CombatantData.new()
    exile_c.team = CombatEnums.CombatantTeam.EXILES

    var monster_c: = CombatantData.new()
    monster_c.team = CombatEnums.CombatantTeam.MONSTERS

    var ally_c: = CombatantData.new()
    ally_c.team = CombatEnums.CombatantTeam.EXILES_ALLIES

    var rogue_c: = CombatantData.new()
    rogue_c.team = CombatEnums.CombatantTeam.ROGUE_EXILES

    print("  Exile vs Monster: %s (expected true)" % exile_c.is_enemy_of(monster_c))
    print("  Monster vs Exile: %s (expected true)" % monster_c.is_enemy_of(exile_c))
    print("  Exile vs Ally: %s (expected false)" % exile_c.is_enemy_of(ally_c))
    print("  Ally vs Monster: %s (expected true)" % ally_c.is_enemy_of(monster_c))
    print("  Exile vs Rogue: %s (expected true)" % exile_c.is_enemy_of(rogue_c))
    print("  Rogue vs Monster: %s (expected true)" % rogue_c.is_enemy_of(monster_c))


func _test_combat_event() -> void :
    print("--- CombatEvent ---")
    var event: = CombatEvent.create(
        2.3, 
        CombatEnums.CombatEventType.DAMAGE_DEALT, 
        {"attacker_id": 1, "defender_id": 10, "total": 23.5}
    )
    print("  tick: %.1f (expected 2.3)" % event.tick)
    print("  type: %d (expected %d/DAMAGE_DEALT)" % [event.event_type, CombatEnums.CombatEventType.DAMAGE_DEALT])
    print("  to_string: %s" % event)


func _test_tactics_override() -> void :
    print("--- Tactics Override (Phase 2A + 2B) ---")
    var exile: = _make_test_exile()


    var inferred: = CombatBehavior.resolve_for_exile(exile)
    print("  no override: rules=%d, aggro_type=%d/NEAREST, kite_mode=%d" % [
        inferred.target_rules.size(), inferred.aggro_type, inferred.kite_mode
    ])



    var override: = ExileTacticsOverride.new()
    var rule: = TargetRule.new()
    rule.filter = TargetRule.Filter.ALL
    rule.picker = TargetRule.Picker.LOWEST_CURRENT_HP
    override.target_rules = [rule]
    override.fallback_picker = TargetRule.Picker.FARTHEST
    exile.tactics_override = override

    var with_rules: = CombatBehavior.resolve_for_exile(exile)
    print("  rule chain: rules=%d (expected 1), fallback=%d (expected %d/FARTHEST)" % [
        with_rules.target_rules.size(), 
        with_rules.fallback_picker, 
        TargetRule.Picker.FARTHEST, 
    ])



    override.target_lock_seconds = 7.5
    var locked: = CombatBehavior.resolve_for_exile(exile)
    var lock_actual: float = locked.get_tactical().sticky_target_duration
    print("  lock 7.5s override: sticky_target_duration=%.2f (expected 7.5)" % lock_actual)





    var second_exile: = _make_test_exile()
    var fresh: = CombatBehavior.resolve_for_exile(second_exile)
    print("  shared preset after other exile's lock override: sticky=%.2f (expected 1.0 = tactical_melee_tank.tres unmutated)" % fresh.get_tactical().sticky_target_duration)



    override.kite_profile = KiteProfile.Profile.RECKLESS
    var reckless: = CombatBehavior.resolve_for_exile(exile)
    print("  reckless kite: mode=%d (expected %d/KITE_ONLY_VS_SLOWER_MELEE), stance=%d (expected %d/AGGRESSIVE), pref_dist=%.2f" % [
        reckless.kite_mode, 
        CombatEnums.KiteMode.KITE_ONLY_VS_SLOWER_MELEE, 
        reckless.stance, 
        CombatEnums.Stance.AGGRESSIVE, 
        reckless.preferred_distance, 
    ])


    exile.tactics_override = null
    var cleared: = CombatBehavior.resolve_for_exile(exile)
    print("  cleared override: rules=%d (expected 0), aggro_type=%d (expected %d/NEAREST)" % [
        cleared.target_rules.size(), cleared.aggro_type, CombatEnums.AggroType.NEAREST
    ])


    var empty_override: = ExileTacticsOverride.new()
    print("  empty override has_any_override=%s (expected false)" % str(empty_override.has_any_override()))






func _make_test_exile() -> ExileData:
    var exile: = ExileData.new()
    exile.name = "Test Exile"
    exile.current_life = 150.0

    var stats: = ExileStats.new()
    stats.life = 200.0
    stats.armour = 50.0
    stats.evasion = 15.0
    stats.attack_speed = 1.2
    stats.action_speed = 1.0
    stats.physical_damage = Vector2(5, 15)
    stats.fire_resistance = 30.0
    stats.movement = 0.0
    stats.energy_shield = 0.0
    exile.current_stats = stats
    exile.base_stats = stats.duplicate()
    return exile


func _make_test_monster() -> MonsterData:
    var monster: = MonsterData.new()
    monster.display_name = "Test Zombie"
    monster.monster_id = "test_zombie"

    var stats: = ExileStats.new()
    stats.life = 80.0
    stats.armour = 20.0
    stats.attack_speed = 0.8
    stats.physical_damage = Vector2(4, 10)
    monster.base_stats = stats

    var behavior: = CombatBehavior.new()
    behavior.aggro_type = CombatEnums.AggroType.NEAREST
    monster.combat_behavior = behavior




    var slot_config: = ActionSlotConfig.new()
    monster.action_slot_configs = [slot_config]

    return monster
