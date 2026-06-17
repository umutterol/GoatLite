extends Node

func _ready():
    print("\n========== TESTING TRAIT SYSTEM ==========")
    _test_library_status()
    _test_default_exile_traits()
    _test_trait_details()
    _test_uncommon_recruit()
    _test_rare_recruit()
    _test_rarity_filter_validation()
    print("\n========== ALL TRAIT TESTS COMPLETE ==========")


func _test_library_status():
    print("\n[TEST 1] Library Status:")
    print("  TraitLibrary loaded: ", TraitLibrary != null)
    var all_traits = TraitLibrary.get_all_traits()
    print("  Total traits loaded: ", all_traits.size())


    var rarity_counts = [0, 0, 0, 0]
    for trait_def in all_traits:
        if trait_def.rarity >= 0 and trait_def.rarity <= 3:
            rarity_counts[trait_def.rarity] += 1
    var rarity_names = ["Common", "Uncommon", "Rare", "Legendary"]
    for i in range(4):
        print("    %s: %d" % [rarity_names[i], rarity_counts[i]])

    if all_traits.size() == 0:
        push_error("  FAIL — no traits loaded, remaining tests will fail")


func _test_default_exile_traits():
    print("\n[TEST 2] Default Exile (no rarity filter):")
    var exile = ExileGenerator.create_exile({"name": "Test Default"})

    print("  Class: ", exile.get_class_name())
    print("  Traits: ", exile.traits)
    print("  Trait count: ", exile.traits.size())

    if exile.traits.is_empty():
        print("  NOTE — rolled zero traits (possible but uncommon)")


func _test_trait_details():
    print("\n[TEST 3] Trait Detail Check:")
    var exile = ExileGenerator.create_exile({"name": "Detail Check"})
    var rarity_names = ["Common", "Uncommon", "Rare", "Legendary"]

    for trait_id in exile.traits:
        var trait_def = TraitLibrary.get_trait_by_id(trait_id)
        if trait_def:
            print("  - %s (%s)" % [trait_def.name, rarity_names[trait_def.rarity]])
            print("    %s" % trait_def.description)
        else:
            push_error("  FAIL — trait_id '%s' not found in TraitLibrary" % trait_id)


func _test_uncommon_recruit():
    print("\n[TEST 4] Uncommon Recruit (min_trait_rarity = UNCOMMON):")
    var exile = ExileGenerator.create_exile({
        "name": "Uncommon Recruit", 
        "min_trait_rarity": TraitManager.TraitRarity.UNCOMMON, 
    })

    _print_trait_rarities(exile)
    _validate_min_rarity(exile, TraitManager.TraitRarity.UNCOMMON, "Uncommon")


func _test_rare_recruit():
    print("\n[TEST 5] Rare Recruit (min_trait_rarity = RARE):")
    var exile = ExileGenerator.create_exile({
        "name": "Rare Recruit", 
        "min_trait_rarity": TraitManager.TraitRarity.RARE, 
    })

    _print_trait_rarities(exile)
    _validate_min_rarity(exile, TraitManager.TraitRarity.RARE, "Rare")


func _test_rarity_filter_validation():

    print("\n[TEST 6] Rarity Filter Bulk Validation (20 uncommon recruits):")
    var violation_count = 0
    var total_traits = 0

    for run in range(20):
        var exile = ExileGenerator.create_exile({
            "min_trait_rarity": TraitManager.TraitRarity.UNCOMMON, 
        })
        for trait_id in exile.traits:
            total_traits += 1
            var trait_def = TraitLibrary.get_trait_by_id(trait_id)
            if trait_def and trait_def.rarity < TraitManager.TraitRarity.UNCOMMON:
                violation_count += 1
                push_error("  FAIL — common trait '%s' on run %d" % [trait_def.name, run])

    print("  Total traits generated: ", total_traits)
    if violation_count == 0:
        print("  PASS — no common traits found in any uncommon+ recruit")
    else:
        push_error("  FAIL — %d violations found" % violation_count)




func _print_trait_rarities(exile: ExileData):
    var rarity_names = ["Common", "Uncommon", "Rare", "Legendary"]
    print("  Class: ", exile.get_class_name())
    print("  Traits (%d):" % exile.traits.size())
    for trait_id in exile.traits:
        var trait_def = TraitLibrary.get_trait_by_id(trait_id)
        if trait_def:
            print("    - %s (%s)" % [trait_def.name, rarity_names[trait_def.rarity]])
        else:
            push_error("    - UNKNOWN trait_id: %s" % trait_id)


func _validate_min_rarity(exile: ExileData, min_rarity: int, rarity_label: String):
    var all_valid = true
    for trait_id in exile.traits:
        var trait_def = TraitLibrary.get_trait_by_id(trait_id)
        if trait_def and trait_def.rarity < min_rarity:
            push_error("  FAIL — trait '%s' is below %s rarity" % [trait_def.name, rarity_label])
            all_valid = false
    if exile.traits.is_empty():
        print("  NOTE — no traits generated (possible but check if pool is empty)")
    elif all_valid:
        print("  PASS — all traits are %s+" % rarity_label)
