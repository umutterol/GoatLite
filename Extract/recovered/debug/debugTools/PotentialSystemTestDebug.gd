
extends Node

func _ready():
    print("\n========== TESTING POTENTIAL SYSTEM ==========")


    print("\n[TEST 1] GameSettings Constants:")
    print("  Passive choices per level: ", GameSettings.PASSIVE_CHOICES_PER_LEVEL)
    print("  Revealed potentials: ", GameSettings.EXILE_REVEALED_POTENTIALS_PERCENT, "%")
    print("  Common weight: ", GameSettings.PASSIVE_RARITY_WEIGHTS["COMMON"])


    print("\n[TEST 2] Creating Test Exile:")
    var test_exile = ExileData.new()
    test_exile.name = "Test Exile"
    test_exile.level = 5
    var dummy_stats = ExileStats.new()
    test_exile.setup_from_class(dummy_stats)

    print("  Exile created: ", test_exile.name)
    print("  Has potential system: ", test_exile.potential != null)
    print("  Number of potential entries: ", test_exile.potential.entries.size())


    print("\n[TEST 3] Potential Details:")
    var hidden_count = 0
    for tag in test_exile.potential.entries:
        var entry = test_exile.potential.entries[tag]
        if entry.is_hidden:
            hidden_count += 1
            print("  - ", tag, ": HIDDEN")
        else:
            print("  - ", tag, ": ", "%.2f" % entry.total_value)
    print("  Total hidden: ", hidden_count, " / ", test_exile.potential.entries.size())


    print("\n[TEST 4] Passive Selection:")
    var choices = PassiveSelectionManager.generate_passive_choices(test_exile)
    print("  Generated ", choices.size(), " passive choices:")
    for i in range(choices.size()):
        var passive = choices[i]
        var weight_mod = test_exile.get_passive_weight_modifier(passive)
        print("    ", i + 1, ". ", passive.name, " (weight mod: ", "%.2f" % weight_mod, ")")


    print("\n[TEST 5] Potential Impact on Selection:")
    print("  Passives get weighted by their tags. For example:")
    if choices.size() > 0:
        var example_passive = choices[0]
        print("  '", example_passive.name, "' has tags: ", example_passive.get_all_tags())
        print("  Base drop weight: ", example_passive.get_drop_weight())
        print("  After potential modifier: ", example_passive.get_drop_weight() * test_exile.get_passive_weight_modifier(example_passive))


    print("\n[TEST 6] Testing Level Up Discovery:")
    var original_hidden = hidden_count
    for i in range(5):
        test_exile.on_level_up()


    var new_hidden_count = 0
    for tag in test_exile.potential.entries:
        if test_exile.potential.entries[tag].is_hidden:
            new_hidden_count += 1

    print("  Leveled up 5 times")
    print("  Hidden potentials: ", original_hidden, " -> ", new_hidden_count)
    print("  Discovered: ", original_hidden - new_hidden_count, " potentials")

    print("\n========== TEST COMPLETE ==========")
