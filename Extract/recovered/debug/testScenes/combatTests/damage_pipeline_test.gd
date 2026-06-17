extends Node

var rng: RandomNumberGenerator


func _ready() -> void :
    rng = RandomNumberGenerator.new()
    rng.seed = 99999

    print("\n=== DAMAGE PIPELINE TEST ===\n")
    _test_basic_hit()
    _test_full_evasion()
    _test_glancing_blow()
    _test_block_reduces_damage()
    _test_armour_reduces_physical()
    _test_resistance_reduces_elemental()
    _test_chaos_bypasses_shield()
    _test_energy_shield_absorbs_non_chaos()
    _test_endurance_reduces_damage()
    _test_second_wind()
    _test_death_vs_downed()
    _test_determinism()
    print("\n=== ALL TESTS COMPLETE ===")


func _test_basic_hit() -> void :
    print("--- Basic Hit ---")
    rng.seed = 12345
    var attacker: = _make_attacker(Vector2(10, 10))
    var defender: = _make_defender(100.0)

    defender.stats.evasion = 0.0
    defender.stats.block_chance = 0.0
    defender.stats.armour = 0.0

    var result: = DamagePipeline.resolve_attack(attacker, defender, 1.0, rng)
    var events: Array = result["events"]


    var damage_event: CombatEvent = _find_event(events, CombatEnums.CombatEventType.DAMAGE_DEALT)
    print("  Damage event exists: %s" % (damage_event != null))
    if damage_event:
        print("  Total damage: %.1f" % damage_event.data["total"])
        print("  Defender life: %.1f (started at 100)" % defender.current_life)
        print("  Attacker damage tracked: %.1f" % attacker.total_damage_dealt)


func _test_full_evasion() -> void :
    print("--- Full Evasion ---")
    var attacker: = _make_attacker(Vector2(10, 10))
    var defender: = _make_defender(100.0)
    defender.stats.evasion = 100.0

    rng.seed = 55555
    var result: = DamagePipeline.resolve_attack(attacker, defender, 1.0, rng)
    var events: Array = result["events"]

    var evade_event: = _find_event(events, CombatEnums.CombatEventType.EVASION)
    var damage_event: = _find_event(events, CombatEnums.CombatEventType.DAMAGE_DEALT)
    print("  Evasion event: %s (expected true)" % (evade_event != null))
    print("  No damage event: %s (expected true)" % (damage_event == null))
    print("  Defender life unchanged: %s (expected true)" % is_equal_approx(defender.current_life, 100.0))


func _test_glancing_blow() -> void :
    print("--- Glancing Blow ---")


    var attacker: = _make_attacker(Vector2(20, 20))
    var defender: = _make_defender(100.0)
    defender.stats.evasion = 50.0
    defender.stats.block_chance = 0.0
    defender.stats.armour = 0.0


    var found_glancing: = false
    for seed_val in range(1, 200):
        rng.seed = seed_val
        defender.current_life = 100.0
        var result: = DamagePipeline.resolve_attack(attacker, defender, 1.0, rng)
        var glancing: = _find_event(result["events"], CombatEnums.CombatEventType.GLANCING_BLOW)
        if glancing != null:
            var damage_evt: = _find_event(result["events"], CombatEnums.CombatEventType.DAMAGE_DEALT)
            print("  Glancing blow found at seed %d" % seed_val)
            print("  Damage dealt: %.1f (expected ~10, half of 20)" % damage_evt.data["total"])
            found_glancing = true
            break
    print("  Glancing blow occurred: %s" % found_glancing)


func _test_block_reduces_damage() -> void :
    print("--- Block ---")
    var attacker: = _make_attacker(Vector2(20, 20))
    var defender: = _make_defender(100.0)
    defender.stats.evasion = 0.0
    defender.stats.armour = 0.0
    defender.stats.block_chance = 100.0
    defender.stats.block_amount = 8.0

    rng.seed = 77777
    var result: = DamagePipeline.resolve_attack(attacker, defender, 1.0, rng)
    var block_evt: = _find_event(result["events"], CombatEnums.CombatEventType.BLOCK)
    var damage_evt: = _find_event(result["events"], CombatEnums.CombatEventType.DAMAGE_DEALT)

    print("  Block event: %s" % (block_evt != null))
    if block_evt:
        print("  Blocked amount: %.1f (expected 8.0)" % block_evt.data["blocked_amount"])
    if damage_evt:
        print("  Final damage: %.1f (expected ~12)" % damage_evt.data["total"])


func _test_armour_reduces_physical() -> void :
    print("--- Armour (physical only) ---")
    var attacker: = _make_attacker(Vector2(100, 100))
    var defender: = _make_defender(500.0)
    defender.stats.evasion = 0.0
    defender.stats.block_chance = 0.0
    defender.stats.armour = 200.0

    rng.seed = 11111
    var result: = DamagePipeline.resolve_attack(attacker, defender, 1.0, rng)
    var damage_evt: = _find_event(result["events"], CombatEnums.CombatEventType.DAMAGE_DEALT)

    if damage_evt:

        var expected_reduction: = CombatMath.calculate_armour_reduction(200.0, 100.0)
        var expected_damage: = 100.0 * (1.0 - expected_reduction)
        print("  Physical after armour: %.1f (expected ~%.1f)" % [damage_evt.data["physical"], expected_damage])
        print("  Reduction was: %.1f%%" % (expected_reduction * 100.0))


func _test_resistance_reduces_elemental() -> void :
    print("--- Resistance ---")

    var attacker: = _make_attacker(Vector2.ZERO)
    attacker.stats.fire_damage = Vector2(50, 50)
    var defender: = _make_defender(500.0)
    defender.stats.evasion = 0.0
    defender.stats.block_chance = 0.0
    defender.stats.fire_resistance = 40.0

    rng.seed = 22222
    var result: = DamagePipeline.resolve_attack(attacker, defender, 1.0, rng)
    var damage_evt: = _find_event(result["events"], CombatEnums.CombatEventType.DAMAGE_DEALT)

    if damage_evt:

        print("  Fire after 40%% res: %.1f (expected 30.0)" % damage_evt.data["fire"])


func _test_chaos_bypasses_shield() -> void :
    print("--- Chaos Bypasses Energy Shield ---")

    var attacker: = _make_attacker(Vector2.ZERO)
    attacker.stats.chaos_damage = Vector2(30, 30)

    var defender: = _make_defender(100.0)
    defender.stats.evasion = 0.0
    defender.stats.block_chance = 0.0
    defender.current_energy_shield = 50.0
    defender.max_energy_shield = 50.0

    rng.seed = 33333
    var result: = DamagePipeline.resolve_attack(attacker, defender, 1.0, rng)
    var damage_evt: = _find_event(result["events"], CombatEnums.CombatEventType.DAMAGE_DEALT)

    if damage_evt:
        print("  Shield absorbed: %.1f (expected 0.0)" % damage_evt.data["shield_absorbed"])
        print("  Shield remaining: %.1f (expected 50.0)" % defender.current_energy_shield)
        print("  Life remaining: %.1f (expected 70.0)" % defender.current_life)


func _test_energy_shield_absorbs_non_chaos() -> void :
    print("--- Energy Shield Absorbs Non-Chaos ---")
    var attacker: = _make_attacker(Vector2(40, 40))
    var defender: = _make_defender(100.0)
    defender.stats.evasion = 0.0
    defender.stats.block_chance = 0.0
    defender.stats.armour = 0.0
    defender.current_energy_shield = 25.0
    defender.max_energy_shield = 25.0

    rng.seed = 44444
    var result: = DamagePipeline.resolve_attack(attacker, defender, 1.0, rng)
    var damage_evt: = _find_event(result["events"], CombatEnums.CombatEventType.DAMAGE_DEALT)

    if damage_evt:
        print("  Shield absorbed: %.1f (expected 25.0)" % damage_evt.data["shield_absorbed"])
        print("  Shield remaining: %.1f (expected 0.0)" % defender.current_energy_shield)
        print("  Life remaining: %.1f (expected 85.0)" % defender.current_life)


func _test_endurance_reduces_damage() -> void :
    print("--- Endurance ---")
    var attacker: = _make_attacker(Vector2(10, 10))
    var defender: = _make_defender(100.0)
    defender.stats.evasion = 0.0
    defender.stats.block_chance = 0.0
    defender.stats.armour = 0.0
    defender.stats.endurance = 20.0
    defender.stats.endurance_threshold = 30.0
    defender.current_life = 25.0

    rng.seed = 55555
    var result: = DamagePipeline.resolve_attack(attacker, defender, 1.0, rng)
    var endurance_evt: = _find_event(result["events"], CombatEnums.CombatEventType.ENDURANCE)
    var damage_evt: = _find_event(result["events"], CombatEnums.CombatEventType.DAMAGE_DEALT)

    print("  Endurance event: %s (expected true)" % (endurance_evt != null))
    if damage_evt:

        print("  Damage after endurance: %.1f (expected 8.0)" % damage_evt.data["total"])
        print("  Endurance active flag: %s" % damage_evt.data["endurance_active"])


func _test_second_wind() -> void :
    print("--- Second Wind ---")
    var attacker: = _make_attacker(Vector2(15, 15))
    var defender: = _make_defender(100.0)
    defender.stats.evasion = 0.0
    defender.stats.block_chance = 0.0
    defender.stats.armour = 0.0
    defender.stats.second_wind_chance = 100.0
    defender.stats.second_wind_threshold = 20.0
    defender.stats.second_wind_amount = 50.0
    defender.current_life = 25.0


    rng.seed = 66666
    var result: = DamagePipeline.resolve_attack(attacker, defender, 1.0, rng)
    var sw_event: = _find_event(result["events"], CombatEnums.CombatEventType.SECOND_WIND)

    print("  Second wind triggered: %s (expected true)" % (sw_event != null))
    if sw_event:
        print("  Healed amount: %.1f (expected 50.0)" % sw_event.data["healed_amount"])
        print("  Life after heal: %.1f" % sw_event.data["new_life"])
    print("  Defender second_wind_triggered flag: %s" % defender.second_wind_triggered)


func _test_death_vs_downed() -> void :
    print("--- Death vs Downed ---")

    var attacker: = _make_attacker(Vector2(999, 999))
    var monster: = _make_defender(50.0)
    monster.source_exile = null
    monster.source_monster = MonsterData.new()
    monster.stats.evasion = 0.0
    monster.stats.block_chance = 0.0
    monster.stats.armour = 0.0

    rng.seed = 88888
    var result: = DamagePipeline.resolve_attack(attacker, monster, 1.0, rng)
    print("  Monster killed: %s" % result["killed"])
    print("  Monster state DEAD: %s" % (monster.state == CombatEnums.CombatantState.DEAD))
    var death_event: = _find_event(result["events"], CombatEnums.CombatEventType.DEATH)
    print("  Death event: %s" % (death_event != null))


    var exile_defender: = _make_defender(50.0)
    exile_defender.source_exile = ExileData.new()
    exile_defender.source_monster = null
    exile_defender.stats.evasion = 0.0
    exile_defender.stats.block_chance = 0.0
    exile_defender.stats.armour = 0.0

    rng.seed = 88888
    result = DamagePipeline.resolve_attack(attacker, exile_defender, 1.0, rng)
    print("  Exile killed: %s" % result["killed"])
    print("  Exile state DOWNED: %s" % (exile_defender.state == CombatEnums.CombatantState.DOWNED))
    var downed_event: = _find_event(result["events"], CombatEnums.CombatEventType.DOWNED)
    print("  Downed event: %s" % (downed_event != null))
    print("  Attacker kills: %d (expected 2)" % attacker.kills)


func _test_determinism() -> void :
    print("--- Determinism ---")
    var results_a: = _run_seeded_attack(42)
    var results_b: = _run_seeded_attack(42)

    var life_match: = is_equal_approx(results_a["life"], results_b["life"])
    var events_match: float = results_a["event_count"] == results_b["event_count"]
    print("  Same seed, same life remaining: %s (%.1f vs %.1f)" % [life_match, results_a["life"], results_b["life"]])
    print("  Same seed, same event count: %s (%d vs %d)" % [events_match, results_a["event_count"], results_b["event_count"]])






func _make_attacker(phys_damage: Vector2) -> CombatantData:
    var c: = CombatantData.new()
    c.combatant_id = 1
    c.display_name = "Test Attacker"
    c.team = CombatEnums.CombatantTeam.EXILES
    c.stats = ExileStats.new()
    c.stats.physical_damage = phys_damage
    c.stats.critical_chance = 0.0
    c.stats.attack_speed = 1.0
    c.stats.action_speed = 1.0
    return c


func _make_defender(life: float) -> CombatantData:
    var c: = CombatantData.new()
    c.combatant_id = 2
    c.display_name = "Test Defender"
    c.team = CombatEnums.CombatantTeam.MONSTERS
    c.source_monster = MonsterData.new()
    c.stats = ExileStats.new()
    c.stats.life = life
    c.current_life = life
    c.max_life = life
    c.stats.evasion = 0.0
    c.stats.block_chance = 0.0
    c.stats.armour = 0.0
    c.stats.second_wind_chance = 0.0
    return c


func _find_event(events: Array, type: CombatEnums.CombatEventType) -> CombatEvent:
    for event in events:
        if event.event_type == type:
            return event
    return null


func _run_seeded_attack(seed_val: int) -> Dictionary:
    rng.seed = seed_val
    var attacker: = _make_attacker(Vector2(5, 20))
    attacker.stats.critical_chance = 15.0
    var defender: = _make_defender(100.0)
    defender.stats.evasion = 20.0
    defender.stats.block_chance = 30.0
    defender.stats.block_amount = 5.0
    defender.stats.armour = 50.0

    var result: = DamagePipeline.resolve_attack(attacker, defender, 1.0, rng)
    return {"life": defender.current_life, "event_count": result["events"].size()}
