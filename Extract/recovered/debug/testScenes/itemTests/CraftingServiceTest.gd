extends Node











var item_generator: ItemGenerator


func _ready() -> void :
    print("\n========== CRAFTING SERVICE TEST SUITE ==========\n")



    item_generator = ItemGenerator.new()
    item_generator.load_item_bases()


    GameState.chaos = 0
    GameState.exalt = 0

    await get_tree().create_timer(0.1).timeout
    test_can_apply_gates()

    await get_tree().create_timer(0.1).timeout
    test_exalt_apply()

    await get_tree().create_timer(0.1).timeout
    test_exalt_cap_refuses()

    await get_tree().create_timer(0.1).timeout
    test_chaos_apply()

    await get_tree().create_timer(0.1).timeout
    test_chaos_different_affix_rule()

    await get_tree().create_timer(0.1).timeout
    test_corrupt_locks_item()

    await get_tree().create_timer(0.1).timeout
    test_corrupt_outcome_distribution()

    await get_tree().create_timer(0.1).timeout
    test_corrupt_add_mod_bypasses_cap()

    await get_tree().create_timer(0.1).timeout
    test_corrupt_shift_tiers_ignores_ilvl()

    await get_tree().create_timer(0.1).timeout
    test_preview_shapes()

    await get_tree().create_timer(0.1).timeout
    test_vaal_consumes_orb_from_stash()

    await get_tree().create_timer(0.1).timeout
    test_vaal_preserves_fractional_implicit()

    await get_tree().create_timer(0.1).timeout
    test_vaal_preserves_fractional_suffix()

    await get_tree().create_timer(0.1).timeout
    test_exalt_rounds_integer_stats()

    print("\n========== ALL CRAFTING TESTS COMPLETE ==========\n")




func test_can_apply_gates() -> void :
    print("\n--- TEST: can_apply gates ---")

    var item: Item = item_generator.generate_item_with_rarity(5, Item.Rarity.COMMON)
    GameState.chaos = 100
    GameState.exalt = 100


    var exalt_gate: Dictionary = CraftingService.can_apply(item, CraftingDefinitions.CraftType.EXALT)
    var chaos_gate: Dictionary = CraftingService.can_apply(item, CraftingDefinitions.CraftType.CHAOS)
    _assert(exalt_gate["ok"], "exalt allowed on common with open slots", exalt_gate.get("reason", ""))
    _assert( not chaos_gate["ok"], "chaos refused on common with no affixes", chaos_gate.get("reason", ""))


    GameState.exalt = 0
    var poor_gate: Dictionary = CraftingService.can_apply(item, CraftingDefinitions.CraftType.EXALT)
    _assert( not poor_gate["ok"], "exalt refused when insufficient currency", poor_gate.get("reason", ""))


    GameState.exalt = 100
    item.is_corrupted = true
    var corrupt_gate: Dictionary = CraftingService.can_apply(item, CraftingDefinitions.CraftType.EXALT)
    _assert( not corrupt_gate["ok"], "exalt refused on corrupted item", corrupt_gate.get("reason", ""))




func test_exalt_apply() -> void :
    print("\n--- TEST: apply_exalt ---")

    var item: Item = item_generator.generate_item_with_rarity(5, Item.Rarity.COMMON)
    GameState.exalt = 100
    var starting_exalt: int = GameState.exalt
    var starting_affixes: int = item.get_affix_count()

    var result: Dictionary = CraftingService.apply_exalt(item)
    _assert(result.get("success", false), "exalt apply succeeded", str(result))
    _assert(item.get_affix_count() == starting_affixes + 1, "affix count increased by 1", 
        "got %d, expected %d" % [item.get_affix_count(), starting_affixes + 1])


    var expected_cost: int = CraftingDefinitions.get_cost_for_item(CraftingDefinitions.CraftType.EXALT, item)
    _assert(GameState.exalt == starting_exalt - expected_cost, 
        "currency deducted correctly", 
        "got %d, expected %d" % [GameState.exalt, starting_exalt - expected_cost])


    _assert(item.rarity == Item.Rarity.UNCOMMON, "common upgraded to uncommon (magic)", 
        "got %s" % Item.Rarity.keys()[item.rarity])




func test_exalt_cap_refuses() -> void :
    print("\n--- TEST: exalt refused at full cap ---")


    var item: Item = item_generator.generate_item_with_rarity(10, Item.Rarity.RARE)

    while item.get_affix_count() < 4:
        GameState.exalt = 100
        var r: Dictionary = CraftingService.apply_exalt(item)
        if not r.get("success", false):
            break

    if item.get_affix_count() != 4:
        print("  (skipping cap test — couldn't reach 4 affixes, item has %d)" % item.get_affix_count())
        return

    GameState.exalt = 100
    var result: Dictionary = CraftingService.apply_exalt(item)
    _assert( not result.get("success", true), "exalt refused at 4-affix cap", 
        "got success=true unexpectedly: %s" % str(result))




func test_chaos_apply() -> void :
    print("\n--- TEST: apply_chaos ---")

    var item: Item = item_generator.generate_item_with_rarity(5, Item.Rarity.RARE)
    if item.get_affix_count() == 0:
        print("  (skipping chaos test — generator produced no affixes)")
        return

    GameState.chaos = 100
    var target: AffixInstance = item.prefix_affixes[0] if not item.prefix_affixes.is_empty() else item.suffix_affixes[0]
    var removed_base: AffixBase = target.affix_base
    var starting_count: int = item.get_affix_count()

    var result: Dictionary = CraftingService.apply_chaos(item, target)
    _assert(result.get("success", false), "chaos apply succeeded", str(result))
    _assert(item.get_affix_count() == starting_count, "affix count unchanged", 
        "got %d, expected %d" % [item.get_affix_count(), starting_count])
    _assert( not item.has_affix(removed_base.affix_id), "removed affix is gone", 
        "removed=%s, item still has it" % removed_base.affix_id)




func test_chaos_different_affix_rule() -> void :
    print("\n--- TEST: chaos replacement differs from removed (100 trials) ---")

    var same_count: int = 0
    for i in 100:
        var item: Item = item_generator.generate_item_with_rarity(5, Item.Rarity.RARE)
        if item.get_affix_count() == 0:
            continue
        GameState.chaos = 1000
        var target_array: Array = item.prefix_affixes if not item.prefix_affixes.is_empty() else item.suffix_affixes
        var target: AffixInstance = target_array[0]
        var removed_id: String = target.affix_base.affix_id
        var result: Dictionary = CraftingService.apply_chaos(item, target)
        if not result.get("success", false):
            continue
        var new_affix: AffixInstance = result["new_affix"]
        if new_affix.affix_base.affix_id == removed_id:
            same_count += 1

    _assert(same_count == 0, "no chaos craft returned the same affix", 
        "%d/100 returned the same affix" % same_count)




func test_corrupt_locks_item() -> void :
    print("\n--- TEST: corrupt locks item ---")

    var item: Item = item_generator.generate_item_with_rarity(5, Item.Rarity.UNCOMMON)
    _seed_vaal_orbs(1)

    var result: Dictionary = CraftingService.apply_corrupt(item)
    _assert(result.get("success", false), "corrupt apply succeeded", str(result))
    _assert(item.is_corrupted, "is_corrupted set", "")
    _assert( not item.is_craftable(), "is_craftable() returns false", "")


    GameState.exalt = 100
    var gate: Dictionary = CraftingService.can_apply(item, CraftingDefinitions.CraftType.EXALT)
    _assert( not gate["ok"], "exalt refused on corrupted item", gate.get("reason", ""))




func test_corrupt_outcome_distribution() -> void :
    print("\n--- TEST: corrupt outcome distribution (1000 trials, ~25% each) ---")

    var counts: Dictionary = {}
    for outcome in CraftingDefinitions.CORRUPT_OUTCOMES.keys():
        counts[outcome] = 0

    for i in 1000:
        var item: Item = item_generator.generate_item_with_rarity(5, Item.Rarity.UNCOMMON)
        _seed_vaal_orbs(1)
        var result: Dictionary = CraftingService.apply_corrupt(item)
        if result.get("success", false):
            counts[result["outcome"]] += 1

    for outcome in counts:
        var name: String = CraftingDefinitions.CORRUPT_OUTCOMES[outcome]["display_name"]
        var pct: float = float(counts[outcome]) / 10.0
        print("  %s: %d (%.1f%%)" % [name, counts[outcome], pct])

        _assert(pct > 20.0 and pct < 30.0, "%s within 20-30%%" % name, "got %.1f%%" % pct)




func test_corrupt_add_mod_bypasses_cap() -> void :
    print("\n--- TEST: ADD_CORRUPTED_MOD bypasses 4-affix cap ---")





    var ring_base: ItemBase = load("res://systems/items/itemBases/jewellery/ring/iron_ring.tres")
    if ring_base == null:
        print("  (iron_ring.tres not found — skipping)")
        return

    var item: Item = item_generator.generate_item_with_rarity(10, Item.Rarity.RARE, ring_base)
    GameState.exalt = 1000
    while item.get_affix_count() < 4:
        var r: Dictionary = CraftingService.apply_exalt(item)
        if not r.get("success", false):
            break

    var starting_count: int = item.get_affix_count()
    if starting_count != 4:
        print("  (couldn't reach 4 affixes — item has %d, skipping cap-bypass test)" % starting_count)
        return




    var details: Dictionary = CraftingService._corrupt_add_mod(item)
    if details.get("added") == null:
        print("  (no corruption mods for ring base — author coverage and re-run)")
        return

    _assert(item.get_affix_count() == starting_count + 1, 
        "affix count exceeded 4-cap after corruption mod", 
        "got %d, expected %d" % [item.get_affix_count(), starting_count + 1])




func test_corrupt_shift_tiers_ignores_ilvl() -> void :
    print("\n--- TEST: SHIFT_TIERS can land on tiers above item_level ---")



    var saw_higher_tier: bool = false
    for i in 50:
        var item: Item = item_generator.generate_item_with_rarity(1, Item.Rarity.UNCOMMON)
        if item.get_affix_count() == 0:
            continue

        var starting_max_tier: int = _max_tier_on_item(item)
        CraftingService._corrupt_shift_tiers(item)
        var ending_max_tier: int = _max_tier_on_item(item)
        if ending_max_tier > starting_max_tier:
            saw_higher_tier = true
            break

    _assert(saw_higher_tier, "tier shifted above starting tier in <=50 trials", 
        "50 trials and tier never exceeded starting — affixes may all be single-tier")




func test_preview_shapes() -> void :
    print("\n--- TEST: preview return shapes ---")

    var item: Item = item_generator.generate_item_with_rarity(5, Item.Rarity.UNCOMMON)

    var exalt_preview: Dictionary = CraftingService.preview_exalt(item)
    _assert(exalt_preview.has("open_slots") and exalt_preview.has("odds_prefix") and exalt_preview.has("odds_suffix"), 
        "preview_exalt has expected keys", str(exalt_preview.keys()))

    if not item.prefix_affixes.is_empty():
        var chaos_preview: Dictionary = CraftingService.preview_chaos(item, item.prefix_affixes[0])
        _assert(chaos_preview.has("removed") and chaos_preview.has("slot_kind") and chaos_preview.has("odds"), 
            "preview_chaos has expected keys", str(chaos_preview.keys()))

    var vaal_preview: Dictionary = CraftingService.preview_vaal(item)
    _assert(vaal_preview.has("outcomes") and vaal_preview["outcomes"].size() == 4, 
        "preview_vaal returns 4 outcomes", "got %d" % vaal_preview.get("outcomes", []).size())




func test_vaal_consumes_orb_from_stash() -> void :
    print("\n--- TEST: vaal craft consumes one orb from stash ---")

    var item: Item = item_generator.generate_item_with_rarity(5, Item.Rarity.UNCOMMON)
    _seed_vaal_orbs(2)
    var starting: int = GameState.count_vaal_orbs()

    var result: Dictionary = CraftingService.apply_corrupt(item)
    _assert(result.get("success", false), "vaal apply succeeded", str(result))
    _assert(GameState.count_vaal_orbs() == starting - 1, 
        "vaal count decreased by exactly 1", 
        "got %d, expected %d" % [GameState.count_vaal_orbs(), starting - 1])








func test_vaal_preserves_fractional_implicit() -> void :
    print("\n--- TEST: Vaal reroll-ranges preserves fractional implicit ---")

    var coral_base: ItemBase = load("res://systems/items/itemBases/jewellery/amulet/coral_amulet.tres")
    if coral_base == null:
        print("  (coral_amulet.tres not found — skipping)")
        return

    var item: Item = item_generator.generate_item_with_rarity(8, Item.Rarity.RARE, coral_base)
    if item.implicit_affixes.is_empty():
        print("  (no implicit on coral amulet — skipping)")
        return

    var implicit: AffixInstance = item.implicit_affixes[0]
    if implicit.affix_base.stat_type != "life_regen":
        print("  (expected life_regen implicit, got '%s' — skipping)" % implicit.affix_base.stat_type)
        return



    var zero_hits: int = 0
    var min_seen: float = INF
    for i in 200:
        CraftingService._corrupt_reroll_ranges(item)
        var v: float = float(implicit.rolled_value)
        if v < min_seen:
            min_seen = v
        if v <= 0.0:
            zero_hits += 1

    _assert(zero_hits == 0, 
        "life_regen implicit never rounded to 0 across 200 rerolls", 
        "%d rerolls produced 0; min value seen = %.3f" % [zero_hits, min_seen])








func test_vaal_preserves_fractional_suffix() -> void :
    print("\n--- TEST: Vaal reroll-ranges preserves fractional life_leech ---")

    var ring_base: ItemBase = load("res://systems/items/itemBases/jewellery/ring/iron_ring.tres")
    var leech_affix: AffixBase = load("res://systems/items/affixes/explicit/suffix/life_leech_ring.tres")
    if ring_base == null or leech_affix == null:
        print("  (iron_ring.tres or life_leech_ring.tres not found — skipping)")
        return

    var item: Item = item_generator.generate_item_with_rarity(1, Item.Rarity.UNCOMMON, ring_base)





    var synthetic: AffixInstance = AffixInstance.new(leech_affix, 0.15, 1)
    item.suffix_affixes.append(synthetic)

    var zero_hits: int = 0
    var min_seen: float = INF
    for i in 200:
        CraftingService._corrupt_reroll_ranges(item)
        var v: float = float(synthetic.rolled_value)
        if v < min_seen:
            min_seen = v
        if v <= 0.0:
            zero_hits += 1

    _assert(zero_hits == 0, 
        "life_leech suffix never rounded to 0 across 200 rerolls (tier 1 range 0.1–0.2)", 
        "%d rerolls produced 0; min value seen = %.3f" % [zero_hits, min_seen])










func test_exalt_rounds_integer_stats() -> void :
    print("\n--- TEST: Exalt rounds integer stats (no fractional life/etc.) ---")




    var fractional_stats: Array[String] = [
        "life_regen", "life_leech", "critical_chance", "evasion_rating"
    ]

    var ring_base: ItemBase = load("res://systems/items/itemBases/jewellery/ring/iron_ring.tres")
    if ring_base == null:
        print("  (iron_ring.tres not found — skipping)")
        return

    var fractional_violations: Array[String] = []

    for trial in 50:
        var item: Item = item_generator.generate_item_with_rarity(10, Item.Rarity.COMMON, ring_base)
        GameState.exalt = 1000
        while item.get_affix_count() < 4:
            var r: Dictionary = CraftingService.apply_exalt(item)
            if not r.get("success", false):
                break
        for inst in item.prefix_affixes + item.suffix_affixes:
            if inst == null or inst.affix_base == null:
                continue
            var stat: String = inst.affix_base.stat_type
            if stat in fractional_stats:
                continue


            if inst.rolled_value is Dictionary:
                continue
            var v: float = float(inst.rolled_value)
            if v != float(int(v)):
                fractional_violations.append(
                    "trial %d: %s rolled %.3f (stat=%s)" % [trial, inst.affix_base.affix_id, v, stat]
                )

    _assert(fractional_violations.is_empty(), 
        "every integer-stat affix rolled as an exact int across exalt trials", 
        "%d violations; first: %s" % [
            fractional_violations.size(), 
            fractional_violations[0] if not fractional_violations.is_empty() else ""
        ])




func _assert(condition: bool, label: String, detail: String) -> void :
    if condition:
        print("  ok    — %s" % label)
    else:
        print("  FAIL  — %s  (%s)" % [label, detail])


func _seed_vaal_orbs(count: int) -> void :

    var to_remove: Array = []
    for it in GameState.guild_stash:
        if it and it.base_item and it.base_item.item_id == "vaal_orb":
            to_remove.append(it)
    for it in to_remove:
        GameState.remove_item_from_stash(it)
    for _i in count:
        GameState.add_item_to_stash(VaalOrbFactory.make())


func _max_tier_on_item(item: Item) -> int:
    var m: int = 0
    for inst in item.prefix_affixes + item.suffix_affixes:
        if inst and inst.tier_level > m:
            m = inst.tier_level
    return m
