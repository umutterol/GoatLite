

class_name TestItemSeeder
extends RefCounted

static func seed_starting_stash() -> void :
    if GameState.guild_stash.size() > 0:
        return


    var generator = ItemGenerator.new()
    generator.load_item_bases()


    var amount_of_commons = 0
    var amount_of_uncommons = 0
    var amount_of_rares = 0


    for i in range(amount_of_commons):
        var common_item = generator.generate_item_with_rarity(1, Item.Rarity.COMMON)
        if common_item:
            GameState.add_item_to_stash(common_item)
            print("TestItemSeeder: Generated common — %s (affixes: %d)" % [
                common_item.get_display_name(), common_item.get_affix_count()
            ])


    for i in range(amount_of_uncommons):
        var magic_item = generator.generate_item_with_rarity(1, Item.Rarity.UNCOMMON)
        if magic_item:
            GameState.add_item_to_stash(magic_item)
            print("TestItemSeeder: Generated random uncommon — %s (affixes: %d)" % [
                magic_item.get_display_name(), magic_item.get_affix_count()
            ])


    for i in range(amount_of_rares):
        var rare_item = generator.generate_item_with_rarity(1, Item.Rarity.RARE)
        if rare_item:
            GameState.add_item_to_stash(rare_item)
            print("TestItemSeeder: Generated random rare — %s (affixes: %d)" % [
                rare_item.get_display_name(), rare_item.get_affix_count()
            ])


    print("TestItemSeeder: Seeded %d items into guild stash." % GameState.guild_stash.size())
    for item in GameState.guild_stash:
        var implicit_texts = []
        for affix in item.implicit_affixes:
            implicit_texts.append(affix.get_display_text())
        print("  - %s | rolled_stats: %s | implicits: %s" % [
            item.get_display_name(), 
            str(item.rolled_stats), 
            str(implicit_texts)
        ])

static func _add_item(base_path: String, rolled: Dictionary) -> void :
    var base = load(base_path) as ItemBase
    if base == null:
        push_error("TestItemSeeder: Failed to load ItemBase at: " + base_path)
        return
    var item = Item.new(base, 1)
    item.rolled_stats = rolled
    item.rarity = Item.Rarity.COMMON



    var generator = ItemGenerator.new()
    generator._generate_implicits(item)

    GameState.add_item_to_stash(item)
