
extends Node

var test_exile: ExileData

func _ready():
    print("\n========== MORALE SYSTEM TEST STARTING ==========\n")


    MoraleManager.morale_changed.connect(_on_morale_changed)
    MoraleManager.morale_state_changed.connect(_on_morale_state_changed)
    MoraleManager.exile_leaving_warning.connect(_on_exile_leaving_warning)


    await test_1_create_exile()
    await get_tree().create_timer(0.1).timeout

    await test_2_basic_morale_changes()
    await get_tree().create_timer(0.1).timeout

    await test_3_morale_modifiers()
    await get_tree().create_timer(0.1).timeout

    await test_4_mission_morale()
    await get_tree().create_timer(0.1).timeout

    await test_5_rest_morale()
    await get_tree().create_timer(0.1).timeout

    await test_6_morale_states()
    await get_tree().create_timer(0.1).timeout

    await test_7_unbreakable_effect()
    await get_tree().create_timer(0.1).timeout

    await test_8_morale_history()

    print("\n========== MORALE SYSTEM TEST COMPLETE ==========\n")

func test_1_create_exile():
    print("\n[TEST 1] Creating Test Exile")
    print("-".repeat(40))


    test_exile = ExileData.new()
    test_exile.name = "Test Warrior"
    test_exile.class_id = "warrior"
    test_exile.level = 5
    test_exile.id = 1


    var stats = ExileStats.new()
    stats.life = 100.0
    stats.morale = 100.0
    stats.max_morale = 100.0
    stats.vitality = 100.0
    test_exile.base_stats = stats
    test_exile.current_stats = stats.duplicate()


    GameState.add_exile(test_exile)

    print("✓ Created exile: %s (Level %d)" % [test_exile.name, test_exile.level])
    print("  Starting morale: %.1f/%.1f" % [test_exile.current_stats.morale, test_exile.current_stats.max_morale])

func test_2_basic_morale_changes():
    print("\n[TEST 2] Basic Morale Changes")
    print("-".repeat(40))

    var initial_morale = test_exile.current_stats.morale


    MoraleManager.apply_custom_event(test_exile, 10, "Found treasure")
    print("✓ Applied +10 morale (custom event)")


    MoraleManager.apply_custom_event(test_exile, -15, "Bad weather")
    print("✓ Applied -15 morale (custom event)")

    var final_morale = test_exile.current_stats.morale
    var expected = initial_morale + 10 - 15
    print("  Final morale: %.1f (expected: %.1f)" % [final_morale, expected])

func test_3_morale_modifiers():
    print("\n[TEST 3] Morale Modifiers (Gain/Resistance)")
    print("-".repeat(40))


    test_exile.current_stats.morale_gain = 50.0
    test_exile.current_stats.morale_loss_resistance = 25.0

    var initial_morale = test_exile.current_stats.morale


    MoraleManager.apply_custom_event(test_exile, 10, "Good news with bonus")
    print("✓ +10 morale with 50%% gain = +15")


    MoraleManager.apply_custom_event(test_exile, -10, "Bad news with resistance")
    print("✓ -10 morale with 25%% resistance = -7.5")

    var final_morale = test_exile.current_stats.morale
    var expected_change = 15 - 7.5
    print("  Net change: %.1f (expected: %.1f)" % [final_morale - initial_morale, expected_change])


    test_exile.current_stats.morale_gain = 0.0
    test_exile.current_stats.morale_loss_resistance = 0.0

func test_4_mission_morale():
    print("\n[TEST 4] Mission Morale System")
    print("-".repeat(40))


    print("• Mission Victory (same level):")
    MoraleManager.apply_mission_victory(test_exile, 5, 30.0)


    print("• Mission Victory (too easy):")
    MoraleManager.apply_mission_victory(test_exile, 2, 10.0)


    print("• Thrilling Victory (90%+ damage):")
    MoraleManager.apply_mission_victory(test_exile, 5, 95.0)


    print("• Safe Retreat:")
    MoraleManager.apply_retreat_penalty(test_exile, false)

    print("• Risky Retreat:")
    MoraleManager.apply_retreat_penalty(test_exile, true)

func test_5_rest_morale():
    print("\n[TEST 5] Rest Morale System")
    print("-".repeat(40))


    print("• Rest with food (normal vitality):")
    MoraleManager.apply_rest_morale(test_exile, true, false)


    print("• Rest with food (full vitality):")
    MoraleManager.apply_rest_morale(test_exile, true, true)


    print("• Rest without food (3 days):")
    for i in range(3):
        MoraleManager.apply_rest_morale(test_exile, false, false)
        print("  Day %d: Hungry penalty increasing" % [i + 1])

func test_6_morale_states():
    print("\n[TEST 6] Morale State Thresholds")
    print("-".repeat(40))


    test_exile.current_stats.morale = 95.0
    var modifiers = MoraleManager.get_morale_combat_modifiers(test_exile)
    print("• High Morale (95%%):")
    print("  Damage dealt: +%.0f%% MORE" % modifiers.damage_dealt_more)
    print("  Damage taken: %.0f%% LESS" % modifiers.damage_taken_less)
    print("  Experience: +%.0f%% MORE" % modifiers.experience_more)


    test_exile.current_stats.morale = 20.0
    modifiers = MoraleManager.get_morale_combat_modifiers(test_exile)
    print("• Low Morale (20%%):")
    print("  Damage dealt: %.0f%% LESS" % abs(modifiers.damage_dealt_more))
    print("  Damage taken: %.0f%% MORE" % abs(modifiers.damage_taken_less))
    print("  Experience: %.0f%% LESS" % abs(modifiers.experience_more))


    test_exile.current_stats.morale = 0.0
    print("• Broken Morale (0%%):")
    print("  Can leave guild: %s" % MoraleManager.can_exile_leave(test_exile))
    print("  Leave chance: %.0f%%" % MoraleManager.get_leave_chance(test_exile.id))

func test_7_unbreakable_effect():
    print("\n[TEST 7] Unbreakable Special Effect")
    print("-".repeat(40))


    print("• Without unbreakable effect:")
    test_exile.current_stats.morale = 0.0
    print("  Can leave at 0 morale: %s" % MoraleManager.can_exile_leave(test_exile))


    print("• With unbreakable passive:")
    test_exile.allocated_passives["unbreakable"] = 1
    print("  Can leave at 0 morale: %s" % MoraleManager.can_exile_leave(test_exile))


    test_exile.allocated_passives.erase("unbreakable")
    test_exile.current_stats.morale = 50.0

func test_8_morale_history():
    print("\n[TEST 8] Morale History Tracking")
    print("-".repeat(40))


    var history = MoraleManager.get_morale_history(test_exile.id, 5)
    print("• Last %d morale changes:" % history.size())

    for i in range(history.size()):
        var record = history[i]
        print("  %d. %+.1f morale: %s" % [i + 1, record.amount, record.get_reason_text()])


func _on_morale_changed(exile_id: int, old_value: float, new_value: float, change_amount: float, reason: String):
    print("  → Morale changed: %.1f → %.1f (%+.1f) - %s" % [old_value, new_value, change_amount, reason])

func _on_morale_state_changed(exile_id: int, state: String):
    print("  ⚠ Morale state changed to: %s" % state.to_upper())

func _on_exile_leaving_warning(exile_id: int, leave_chance: float):
    print("  ⚠⚠⚠ EXILE LEAVING WARNING! Chance: %.0f%%" % leave_chance)
