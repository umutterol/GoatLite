extends Node

var test_exile: ExileData

func _ready():
    print("\n========== DEFEAT SYSTEM TEST STARTING ==========\n")


    GameState.exile_died.connect(_on_exile_died)
    MoraleManager.morale_changed.connect(_on_morale_changed)

    await get_tree().create_timer(0.1).timeout

    test_1_setup_exile()
    await get_tree().create_timer(0.1).timeout

    test_2_outcome_loading()
    await get_tree().create_timer(0.1).timeout

    test_3_allies_survived_defeat()
    await get_tree().create_timer(0.1).timeout

    test_4_total_wipe_defeat()
    await get_tree().create_timer(0.1).timeout

    test_5_default_defeat()
    await get_tree().create_timer(0.1).timeout

    test_6_scar_assignment()
    await get_tree().create_timer(0.1).timeout

    test_7_death_roll_distribution()
    await get_tree().create_timer(0.1).timeout

    test_8_resolve_all_batch()

    print("\n========== DEFEAT SYSTEM TEST COMPLETE ==========\n")


func test_1_setup_exile():
    print("\n[TEST 1] Creating Test Exile")
    print("-".repeat(40))

    test_exile = ExileGenerator.create_exile({})
    GameState.add_exile(test_exile)

    print("✓ Created: %s (Level %d, %s)" % [test_exile.name, test_exile.level, test_exile.get_class_name()])
    print("  Life: %.0f | Vitality: %.0f | Morale: %.0f" % [
        test_exile.current_stats.current_life, 
        test_exile.current_vitality, 
        test_exile.current_stats.morale
    ])
    print("  Scar count: %d" % test_exile.get_scar_count())


func test_2_outcome_loading():
    print("\n[TEST 2] Outcome Loading")
    print("-".repeat(40))


    DefeatResolver._cached_outcomes.clear()
    var outcomes: = DefeatResolver._load_outcomes()

    print("  Loaded %d outcome(s) from res://systems/defeat/outcomes/" % outcomes.size())

    if outcomes.is_empty():
        print("✗ ERROR: No outcomes found! Create .tres files first.")
        return

    for outcome in outcomes:
        print("  • %s (weight: %.0f)" % [outcome.display_name, outcome.weight])
        _print_outcome_conditions(outcome)

    print("✓ Outcome loading works")


func test_3_allies_survived_defeat():
    print("\n[TEST 3] Defeat — Allies Survived")
    print("-".repeat(40))

    _reset_exile_state()

    var context: = DefeatContext.create(test_exile, "combat", "Test Monster")
    context.allies_survived = true
    context.zone_danger = 1

    var result: = DefeatResolver.resolve_single(context)
    _print_result(result)


func test_4_total_wipe_defeat():
    print("\n[TEST 4] Defeat — Total Wipe")
    print("-".repeat(40))

    _reset_exile_state()

    var context: = DefeatContext.create(test_exile, "combat", "Boss Monster")
    context.total_wipe = true
    context.zone_danger = 3

    var result: = DefeatResolver.resolve_single(context)
    _print_result(result)


func test_5_default_defeat():
    print("\n[TEST 5] Defeat — No Special Context")
    print("-".repeat(40))

    _reset_exile_state()

    var context: = DefeatContext.create(test_exile, "event", "Trap")

    var result: = DefeatResolver.resolve_single(context)
    _print_result(result)


func test_6_scar_assignment():
    print("\n[TEST 6] Scar Assignment (Forced)")
    print("-".repeat(40))

    _reset_exile_state()

    var scars_before: = test_exile.get_scar_count()
    var traits_before: = test_exile.traits.size()


    var available_scars: = DefeatResolver._get_available_scars(test_exile)
    print("  Available scars in pool: %d" % available_scars.size())

    if available_scars.is_empty():
        print("✗ No scar traits found — create at least one SCAR category trait .tres")
        return

    for scar in available_scars:
        print("  • %s (weight: %.0f)" % [scar.name, scar.get_drop_weight()])


    var picked_scar: = DefeatResolver._weighted_scar_selection(available_scars)
    if picked_scar:
        test_exile.add_trait(picked_scar.trait_id, "Test: forced scar")
        ExileGenerator.recalculate_stats(test_exile)
        print("  Assigned scar: %s" % picked_scar.name)
        print("  Scar count: %d → %d" % [scars_before, test_exile.get_scar_count()])
        print("  Traits: %d → %d" % [traits_before, test_exile.traits.size()])
        print("✓ Scar assignment works")
    else:
        print("✗ Weighted selection returned null")


func test_7_death_roll_distribution():
    print("\n[TEST 7] Death Roll Distribution (1000 rolls per scar count)")
    print("-".repeat(40))

    for scar_count in range(6):
        var deaths: = 0
        for i in range(1000):
            if DefeatResolver._roll_death(scar_count):
                deaths += 1

        var expected: float = GameSettings.DEATH_CHANCE_PER_SCAR.get(scar_count, GameSettings.DEATH_CHANCE_MAX_SCARS)
        print("  %d scars: %d/1000 deaths (expected ~%.0f%%)" % [scar_count, deaths, expected])

    print("✓ Death roll distribution logged")


func test_8_resolve_all_batch():
    print("\n[TEST 8] Batch Resolution (5 defeats)")
    print("-".repeat(40))

    _reset_exile_state()

    var contexts: Array[DefeatContext] = []
    for i in range(5):
        var context: = DefeatContext.create(test_exile, "combat", "Enemy %d" % (i + 1))
        context.allies_survived = i % 2 == 0
        contexts.append(context)

    var results: = DefeatResolver.resolve_all(contexts)
    print("  Resolved %d/%d contexts" % [results.size(), contexts.size()])

    for result in results:
        if result.died:
            print("  • DIED (source: %s)" % result.source_description)
        elif result.outcome:
            print("  • %s (source: %s)" % [result.outcome.display_name, result.source_description])
            if result.scar_trait:
                print("    Scar gained: %s" % result.scar_trait.name)

    print("✓ Batch resolution complete")




func _reset_exile_state():
    test_exile.status = "idle"
    test_exile.current_stats.morale = 80.0
    test_exile.current_vitality = test_exile.current_stats.max_vitality
    test_exile.current_stats.current_life = test_exile.current_stats.life


func _print_result(result: DefeatResolver.DefeatResult):
    if not result:
        print("  ✗ Result is null")
        return

    if result.died:
        print("  RESULT: DEATH")
        print("  Status: %s" % result.exile_data.status)
        return

    if not result.outcome:
        print("  ✗ No outcome assigned")
        return

    print("  RESULT: %s" % result.outcome.display_name)
    print("  Description: %s" % result.outcome.description)
    print("  Status: %s" % result.exile_data.status)
    print("  Morale: %.0f | Vitality: %.0f" % [
        result.exile_data.current_stats.morale, 
        result.exile_data.current_vitality
    ])
    if result.scar_trait:
        print("  Scar gained: %s" % result.scar_trait.name)
    print("  Scars total: %d" % result.exile_data.get_scar_count())


func _print_outcome_conditions(outcome: DefeatOutcome):
    var conditions: Array[String] = []
    if outcome.requires_allies_survived:
        conditions.append("allies_survived")
    if outcome.requires_total_wipe:
        conditions.append("total_wipe")
    if outcome.requires_solo:
        conditions.append("solo")
    if outcome.min_zone_danger > 0:
        conditions.append("danger>=%d" % outcome.min_zone_danger)
    if outcome.min_scar_count > 0:
        conditions.append("scars>=%d" % outcome.min_scar_count)

    if conditions.is_empty():
        print("    Conditions: none (always valid)")
    else:
        print("    Conditions: %s" % ", ".join(conditions))


func _on_exile_died(exile_id: int):
    print("  [SIGNAL] exile_died: id=%d" % exile_id)


func _on_morale_changed(exile_id: int, old_value: float, new_value: float, change_amount: float, reason: String):
    print("  [SIGNAL] morale_changed: %.0f → %.0f (%.0f, %s)" % [old_value, new_value, change_amount, reason])
