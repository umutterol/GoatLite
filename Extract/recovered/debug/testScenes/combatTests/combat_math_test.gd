extends Node

func _ready() -> void :
    print("\n=== COMBAT MATH DELEGATION TEST ===\n")
    _test_armour()
    _test_evasion()
    _test_block()
    _test_resistance()
    _test_endurance()
    _test_second_wind()
    _test_crit()
    print("\n=== ALL TESTS COMPLETE ===")


func _test_armour() -> void :
    print("--- Armour ---")
    var stats: = ExileStats.new()
    stats.armour = 250.0


    var direct: = CombatMath.calculate_armour_reduction(250.0, 100.0)

    var delegated: = stats.get_armour_reduction(100.0)

    print("  CombatMath:  250 armour vs 100 dmg = %.1f%% reduction" % (direct * 100))
    print("  ExileStats:  250 armour vs 100 dmg = %.1f%% reduction" % (delegated * 100))
    print("  Match: %s" % str(is_equal_approx(direct, delegated)))


func _test_evasion() -> void :
    print("--- Evasion ---")

    var stats: = ExileStats.new()
    stats.evasion = 30.0

    var results: = {"hit": 0, "glancing": 0, "evaded": 0}
    for i in 100:
        var result: = stats.roll_evasion()
        results[result] += 1

    print("  100 rolls at 30%% evasion: %s" % str(results))
    print("  All values valid: %s" % str(results["hit"] + results["glancing"] + results["evaded"] == 100))


func _test_block() -> void :
    print("--- Block ---")
    var stats: = ExileStats.new()
    stats.block_chance = 50.0
    stats.block_amount = 30.0

    var blocked_count: = 0
    for i in 100:
        var result: = stats.calculate_block()
        if result["blocked"]:
            blocked_count += 1

            assert (result["amount"] == 30.0, "Block amount mismatch")

    print("  100 rolls at 50%% block: %d blocked" % blocked_count)


func _test_resistance() -> void :
    print("--- Resistance ---")
    var stats: = ExileStats.new()
    stats.fire_resistance = 90.0
    stats.fire_resistance_cap = 75.0

    var effective: = stats.get_effective_resistance("fire")
    print("  90%% fire res, 75%% cap = %.0f%% effective" % effective)
    print("  Capped correctly: %s" % str(is_equal_approx(effective, 75.0)))


func _test_endurance() -> void :
    print("--- Endurance ---")
    var stats: = ExileStats.new()
    stats.max_life = 100.0
    stats.endurance_threshold = 25.0

    stats.current_life = 30.0
    print("  At 30/100 life (threshold 25%%): active = %s (expected false)" % stats.is_endurance_active())

    stats.current_life = 20.0
    print("  At 20/100 life (threshold 25%%): active = %s (expected true)" % stats.is_endurance_active())


func _test_second_wind() -> void :
    print("--- Second Wind ---")

    var eligible: = CombatMath.is_second_wind_eligible(15.0, 8.0, 100.0, 10.0)
    print("  15 -> 8 life (threshold 10%%): eligible = %s (expected true)" % eligible)


    var not_eligible: = CombatMath.is_second_wind_eligible(8.0, 5.0, 100.0, 10.0)
    print("  8 -> 5 life (threshold 10%%): eligible = %s (expected false)" % not_eligible)


    var dead: = CombatMath.is_second_wind_eligible(15.0, 0.0, 100.0, 10.0)
    print("  15 -> 0 life: eligible = %s (expected false)" % dead)


func _test_crit() -> void :
    print("--- Crit ---")
    var seeded_rng: = RandomNumberGenerator.new()
    seeded_rng.seed = 12345


    var results_a: = []
    seeded_rng.seed = 12345
    for i in 10:
        results_a.append(CombatMath.roll_crit(50.0, seeded_rng))

    var results_b: = []
    seeded_rng.seed = 12345
    for i in 10:
        results_b.append(CombatMath.roll_crit(50.0, seeded_rng))

    print("  Determinism (same seed): %s" % str(results_a == results_b))
