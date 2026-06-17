extends Node




var affix_pool: AffixPool
var item_generator: ItemGenerator

func _ready():
    print("\n========== ITEM GENERATOR TEST SUITE ==========\n")


    print("Initializing item generation systems...")
    affix_pool = AffixPool.new()
    affix_pool.load_all_affixes()

    item_generator = ItemGenerator.new(affix_pool)
    item_generator.load_item_bases()


    await get_tree().create_timer(0.1).timeout
    test_affix_loading()

    await get_tree().create_timer(0.1).timeout
    test_basic_generation()

    await get_tree().create_timer(0.1).timeout
    test_rarity_distribution()

    await get_tree().create_timer(0.1).timeout
    test_item_level_scaling()

    await get_tree().create_timer(0.1).timeout
    test_specific_item_types()

    await get_tree().create_timer(0.1).timeout
    test_affix_validity()

    await get_tree().create_timer(0.1).timeout
    test_tag_filtering()

    print("\n========== ALL TESTS COMPLETE ==========\n")


func test_affix_loading():
    print("\n--- TEST 1: Affix Loading ---")
    affix_pool.print_affix_summary()


    var life_affix = affix_pool.get_affix_by_id("added_life")
    if life_affix:
        print("\nFound 'added_life' affix:")
        print("  Display Name: ", life_affix.display_name)
        print("  Stat Type: ", life_affix.stat_type)
        print("  Value Tiers: ", life_affix.value_by_level.size())
    else:
        print("ERROR: Could not find 'added_life' affix!")


func test_basic_generation():
    print("\n--- TEST 2: Basic Item Generation ---")

    for i in range(5):
        var item = item_generator.generate_item(1)
        if item:
            print("\nGenerated Item #", i + 1, ":")
            print(item.get_debug_string())
        else:
            print("ERROR: Failed to generate item!")


func test_rarity_distribution():
    print("\n--- TEST 3: Rarity Distribution (1000 items) ---")

    var rarity_counts = {
        Item.Rarity.COMMON: 0, 
        Item.Rarity.UNCOMMON: 0, 
        Item.Rarity.RARE: 0
    }

    var affix_count_distribution = {
        0: 0, 1: 0, 2: 0, 3: 0, 4: 0
    }

    for i in range(1000):
        var item = item_generator.generate_item(5)
        if item:
            rarity_counts[item.rarity] += 1
            affix_count_distribution[item.get_affix_count()] += 1

    print("\nRarity Distribution:")
    for rarity in rarity_counts:
        var percent = (rarity_counts[rarity] / 1000.0) * 100
        print("  ", Item.Rarity.keys()[rarity], ": ", rarity_counts[rarity], " (", "%.1f" % percent, "%)")

    print("\nAffix Count Distribution:")
    for count in range(5):
        var percent = (affix_count_distribution[count] / 1000.0) * 100
        print("  ", count, " affixes: ", affix_count_distribution[count], " (", "%.1f" % percent, "%)")
        var expected = 0
        match count:
            0: expected = GameSettings.ZERO_MOD_BASE_CHANCE
            1: expected = GameSettings.ONE_MOD_BASE_CHANCE
            2: expected = GameSettings.TWO_MOD_BASE_CHANCE
            3: expected = GameSettings.THREE_MOD_BASE_CHANCE
            4: expected = GameSettings.FOUR_MOD_BASE_CHANCE
        print("    Expected: ", expected, "%")


func test_item_level_scaling():
    print("\n--- TEST 4: Item Level Scaling ---")


    var test_base: ItemBase = null
    for base in item_generator.item_bases:
        if base.item_id == "stone_hatchet":
            test_base = base
            break

    if not test_base:
        print("WARNING: Could not find stone_hatchet for testing, using random base")

    for level in [1, 4, 8, 12, 20]:
        print("\n=== Item Level ", level, " ===")
        var item = item_generator.generate_item_with_rarity(level, Item.Rarity.RARE, test_base)
        if item:
            print(item.get_debug_string())


            for affix_inst in item.get_all_affixes():
                if not affix_inst.affix_base.is_implicit:
                    print("  -> ", affix_inst.affix_base.affix_id, " rolled tier ", affix_inst.tier_level)


func test_specific_item_types():
    print("\n--- TEST 5: Specific Item Type Generation ---")

    var test_types = [
        "weapon", "armour", "jewellery", "offhand"
    ]

    for type_name in test_types:
        print("\n=== Generating ", type_name.to_upper(), " ===")


        var base_of_type: ItemBase = null
        for base in item_generator.item_bases:
            if type_name == "weapon" and base.category == ItemEnums.ItemCategory.WEAPON:
                base_of_type = base
                break
            elif type_name == "armour" and base.category == ItemEnums.ItemCategory.ARMOUR:
                base_of_type = base
                break
            elif type_name == "jewellery" and base.category == ItemEnums.ItemCategory.JEWELLERY:
                base_of_type = base
                break
            elif type_name == "offhand" and base.category == ItemEnums.ItemCategory.OFFHAND:
                base_of_type = base
                break

        if base_of_type:
            var item = item_generator.generate_item_with_rarity(8, Item.Rarity.RARE, base_of_type)
            print(item.get_debug_string())
        else:
            print("WARNING: No base found for type: ", type_name)


func test_affix_validity():
    print("\n--- TEST 6: Affix Validity Testing ---")


    var weapon_base: ItemBase = null
    var armour_base: ItemBase = null

    for base in item_generator.item_bases:
        if not weapon_base and base.category == ItemEnums.ItemCategory.WEAPON:
            weapon_base = base
        if not armour_base and base.category == ItemEnums.ItemCategory.ARMOUR:
            armour_base = base
        if weapon_base and armour_base:
            break

    print("\nChecking affix validity for weapon:")
    var valid_weapon_prefixes = affix_pool.get_valid_prefixes(weapon_base, 10)
    for affix in valid_weapon_prefixes:
        if affix.affix_id == "added_physical_1h":
            print("  ✓ Found added_physical_1h (correct)")
        if affix.affix_id == "added_life":
            print("  ✗ Found added_life on weapon (incorrect!)")

    print("\nChecking affix validity for armour:")
    var valid_armour_prefixes = affix_pool.get_valid_prefixes(armour_base, 10)
    for affix in valid_armour_prefixes:
        if affix.affix_id == "added_life":
            print("  ✓ Found added_life (correct)")
        if affix.affix_id == "added_physical_1h":
            print("  ✗ Found added_physical_1h on armour (incorrect!)")


func test_tag_filtering():
    print("\n--- TEST 7: Tag Filtering ---")


    print("\nGenerating items with no tags:")
    for i in range(3):
        var item = item_generator.generate_item(5)
        print("  Item ", i + 1, ": ", item.get_display_name(), " [", item.unique_id.split("_")[-1], "]")


    var test_tags = ["drop_only", "boss_only", "crafting_only"]
    print("\nGenerating items with tags: ", test_tags)
    for i in range(3):
        var item = item_generator.generate_item(5, null, test_tags)
        print("  Item ", i + 1, ": ", item.get_display_name())
        if item.source_tags.size() > 0:
            print("    Source tags: ", item.source_tags)


func generate_test_item(base_id: String, level: int, rarity: Item.Rarity) -> Item:
    var base: ItemBase = null
    for item_base in item_generator.item_bases:
        if item_base.item_id == base_id:
            base = item_base
            break

    if not base:
        push_warning("Could not find item base: " + base_id)
        return null

    return item_generator.generate_item_with_rarity(level, rarity, base)
