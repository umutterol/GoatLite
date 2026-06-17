class_name CraftingService
extends RefCounted











static var _affix_pool: AffixPool = null




static func reset_pool() -> void :
    _affix_pool = null


static func _ensure_pool() -> AffixPool:
    if _affix_pool == null:
        _affix_pool = AffixPool.new()
        _affix_pool.load_all_affixes()
    return _affix_pool








static func can_apply(item: Item, craft_type: int) -> Dictionary:
    if item == null or item.base_item == null:
        return {"ok": false, "reason": "No item selected"}
    if not item.is_craftable():
        return {"ok": false, "reason": "Item is Corrupted — no further crafting"}

    var def: Dictionary = CraftingDefinitions.CRAFTS.get(craft_type, {})
    if def.is_empty():
        return {"ok": false, "reason": "Unknown craft type"}

    match craft_type:
        CraftingDefinitions.CraftType.EXALT:
            var slots: Dictionary = _get_open_slots(item)
            if slots["prefix"] + slots["suffix"] == 0:
                return {"ok": false, "reason": "Item is full — no open affix slots"}
        CraftingDefinitions.CraftType.CHAOS:
            if item.prefix_affixes.is_empty() and item.suffix_affixes.is_empty():
                return {"ok": false, "reason": "Item has no affixes to chaos"}
        CraftingDefinitions.CraftType.VAAL:
            pass

    var cost: int = CraftingDefinitions.get_cost_for_item(craft_type, item)
    if not _can_afford(craft_type, cost):
        return {"ok": false, "reason": "Insufficient %s" % def.get("display_name", "currency")}

    return {"ok": true, "reason": ""}









static func preview_exalt(item: Item) -> Dictionary:
    var slots: Dictionary = _get_open_slots(item)
    var pool: AffixPool = _ensure_pool()
    var existing: Array = _existing_explicit_bases(item)

    var odds_prefix: Dictionary = {}
    var odds_suffix: Dictionary = {}
    var names_prefix: Dictionary = {}
    var names_suffix: Dictionary = {}
    if slots["prefix"] > 0:
        var pcands: Array[AffixBase] = pool.get_valid_prefixes(item.base_item, item.item_level, item.source_tags)
        var pfiltered: Array = _filter_excluded(pcands, existing)
        odds_prefix = pool.compute_odds(pfiltered)
        names_prefix = _build_name_lookup(pfiltered, item.item_level)
    if slots["suffix"] > 0:
        var scands: Array[AffixBase] = pool.get_valid_suffixes(item.base_item, item.item_level, item.source_tags)
        var sfiltered: Array = _filter_excluded(scands, existing)
        odds_suffix = pool.compute_odds(sfiltered)
        names_suffix = _build_name_lookup(sfiltered, item.item_level)

    return {
        "open_slots": slots, 
        "odds_prefix": odds_prefix, 
        "odds_suffix": odds_suffix, 
        "names_prefix": names_prefix, 
        "names_suffix": names_suffix, 
    }






static func preview_chaos(item: Item, target_affix: AffixInstance) -> Dictionary:
    if target_affix == null or target_affix.affix_base == null:
        return {}
    var pool: AffixPool = _ensure_pool()
    var is_prefix: bool = target_affix.affix_base.is_prefix

    var candidates: Array[AffixBase]
    if is_prefix:
        candidates = pool.get_valid_prefixes(item.base_item, item.item_level, item.source_tags)
    else:
        candidates = pool.get_valid_suffixes(item.base_item, item.item_level, item.source_tags)




    var exclude: Array = _existing_explicit_bases(item)
    var filtered: Array = _filter_excluded(candidates, exclude)

    return {
        "removed": target_affix, 
        "slot_kind": "prefix" if is_prefix else "suffix", 
        "odds": pool.compute_odds(filtered), 
        "names": _build_name_lookup(filtered, item.item_level), 
    }





static func preview_vaal(_item: Item) -> Dictionary:
    var outcomes: Array = []
    for outcome in CraftingDefinitions.CORRUPT_OUTCOMES.keys():
        var data: Dictionary = CraftingDefinitions.CORRUPT_OUTCOMES[outcome]
        outcomes.append({
            "outcome": outcome, 
            "name": data["display_name"], 
            "blurb": data["blurb"], 
            "weight_pct": 25.0, 
        })
    return {"outcomes": outcomes}





static func apply_exalt(item: Item) -> Dictionary:
    var gate: Dictionary = can_apply(item, CraftingDefinitions.CraftType.EXALT)
    if not gate["ok"]:
        return {"success": false, "reason": gate["reason"]}

    var pool: AffixPool = _ensure_pool()
    var slots: Dictionary = _get_open_slots(item)
    var existing: Array = _existing_explicit_bases(item)


    var pick_prefix: bool
    if slots["prefix"] > 0 and slots["suffix"] > 0:
        pick_prefix = randf() < 0.5
    else:
        pick_prefix = slots["prefix"] > 0

    var candidates: Array[AffixBase]
    if pick_prefix:
        candidates = pool.get_valid_prefixes(item.base_item, item.item_level, item.source_tags)
    else:
        candidates = pool.get_valid_suffixes(item.base_item, item.item_level, item.source_tags)
    var filtered: Array = _filter_excluded(candidates, existing)

    if filtered.is_empty():
        return {"success": false, "reason": "Pool exhausted for that slot kind"}

    var picked: AffixBase = pool.pick_weighted_affix(filtered)
    if picked == null:
        return {"success": false, "reason": "Picker returned null"}

    var instance: AffixInstance = _roll_affix_instance(picked, item.item_level, pool)
    if pick_prefix:
        item.prefix_affixes.append(instance)
    else:
        item.suffix_affixes.append(instance)

    item.update_rarity()
    _spend_currency(CraftingDefinitions.CraftType.EXALT, item)

    return {
        "success": true, 
        "slot_kind": "prefix" if pick_prefix else "suffix", 
        "new_affix": instance, 
    }







static func apply_chaos(item: Item, target_affix: AffixInstance) -> Dictionary:
    var gate: Dictionary = can_apply(item, CraftingDefinitions.CraftType.CHAOS)
    if not gate["ok"]:
        return {"success": false, "reason": gate["reason"]}
    if target_affix == null or target_affix.affix_base == null:
        return {"success": false, "reason": "No target affix"}

    var is_prefix: bool = target_affix.affix_base.is_prefix
    var target_array: Array = item.prefix_affixes if is_prefix else item.suffix_affixes
    if not target_array.has(target_affix):
        return {"success": false, "reason": "Affix not found on item"}


    var removed_base: AffixBase = target_affix.affix_base
    target_array.erase(target_affix)

    var pool: AffixPool = _ensure_pool()
    var candidates: Array[AffixBase]
    if is_prefix:
        candidates = pool.get_valid_prefixes(item.base_item, item.item_level, item.source_tags)
    else:
        candidates = pool.get_valid_suffixes(item.base_item, item.item_level, item.source_tags)

    var exclude: Array = [removed_base]
    exclude.append_array(_existing_explicit_bases(item))
    var filtered: Array = _filter_excluded(candidates, exclude)

    if filtered.is_empty():

        target_array.append(target_affix)
        return {"success": false, "reason": "No valid replacement available"}

    var picked: AffixBase = pool.pick_weighted_affix(filtered)
    if picked == null:
        target_array.append(target_affix)
        return {"success": false, "reason": "Picker returned null"}

    var instance: AffixInstance = _roll_affix_instance(picked, item.item_level, pool)
    target_array.append(instance)

    item.update_rarity()
    _spend_currency(CraftingDefinitions.CraftType.CHAOS, item)

    return {
        "success": true, 
        "removed": target_affix, 
        "new_affix": instance, 
        "slot_kind": "prefix" if is_prefix else "suffix", 
    }





static func apply_corrupt(item: Item) -> Dictionary:
    var gate: Dictionary = can_apply(item, CraftingDefinitions.CraftType.VAAL)
    if not gate["ok"]:
        return {"success": false, "reason": gate["reason"]}

    var outcome: int = _pick_corrupt_outcome()
    var details: Dictionary = {}
    var fallback_from: int = -1

    match outcome:
        CraftingDefinitions.CorruptOutcome.REROLL_AFFIXES:
            details = _corrupt_reroll_affixes(item)
        CraftingDefinitions.CorruptOutcome.REROLL_RANGES:
            details = _corrupt_reroll_ranges(item)
        CraftingDefinitions.CorruptOutcome.SHIFT_TIERS:
            details = _corrupt_shift_tiers(item)
        CraftingDefinitions.CorruptOutcome.ADD_CORRUPTED_MOD:
            details = _corrupt_add_mod(item)







            if details.get("added") == null:
                fallback_from = outcome
                outcome = CraftingDefinitions.CorruptOutcome.REROLL_AFFIXES
                details = _corrupt_reroll_affixes(item)
                details["fell_back_from_add_mod"] = true

    item.is_corrupted = true
    item.update_rarity()
    _spend_currency(CraftingDefinitions.CraftType.VAAL, item)

    var result: Dictionary = {
        "success": true, 
        "outcome": outcome, 
        "outcome_name": CraftingDefinitions.CORRUPT_OUTCOMES[outcome]["display_name"], 
        "details": details, 
    }
    if fallback_from >= 0:
        result["fallback_from"] = fallback_from
    return result






static func _can_afford(craft_type: int, cost: int) -> bool:
    match craft_type:
        CraftingDefinitions.CraftType.EXALT:
            return GameState.exalt >= cost
        CraftingDefinitions.CraftType.CHAOS:
            return GameState.chaos >= cost
        CraftingDefinitions.CraftType.VAAL:
            return GameState.count_vaal_orbs() >= cost
    return false


static func _spend_currency(craft_type: int, item: Item) -> void :
    var cost: int = CraftingDefinitions.get_cost_for_item(craft_type, item)
    match craft_type:
        CraftingDefinitions.CraftType.EXALT:
            GameState.spend_exalt(cost)
        CraftingDefinitions.CraftType.CHAOS:
            GameState.spend_chaos(cost)
        CraftingDefinitions.CraftType.VAAL:
            _consume_vaal_orbs(cost)





static func _consume_vaal_orbs(count: int) -> void :
    for _i in count:
        var found: Item = null
        for item in GameState.guild_stash:
            if item and item.base_item and item.base_item.item_id == "vaal_orb":
                found = item
                break
        if found == null:
            push_warning("CraftingService._consume_vaal_orbs: ran out before consuming all %d" % count)
            return
        GameState.remove_item_from_stash(found)











static func _get_open_slots(item: Item) -> Dictionary:
    var total: int = item.get_affix_count()
    var prefix_cap: int
    var suffix_cap: int
    if total < 2:
        prefix_cap = 1
        suffix_cap = 1
    else:
        prefix_cap = 2
        suffix_cap = 2
    return {
        "prefix": maxi(0, prefix_cap - item.prefix_affixes.size()), 
        "suffix": maxi(0, suffix_cap - item.suffix_affixes.size()), 
    }





static func _existing_explicit_bases(item: Item) -> Array:
    var bases: Array = []
    for inst in item.prefix_affixes + item.suffix_affixes:
        if inst and inst.affix_base:
            bases.append(inst.affix_base)
    return bases



static func _filter_excluded(candidates: Array, exclude: Array) -> Array:
    var result: Array = []
    for affix in candidates:
        if affix and not exclude.has(affix):
            result.append(affix)
    return result









static func _build_name_lookup(candidates: Array, item_level: int) -> Dictionary:
    var names: Dictionary = {}
    for affix in candidates:
        if affix == null:
            continue
        names[affix.affix_id] = _build_preview_text(affix, item_level)
    return names







static func _build_preview_text(affix: AffixBase, item_level: int) -> String:
    var lo: float = INF
    var hi: float = - INF
    for tier_level in affix.value_by_level.keys():
        if int(tier_level) > item_level:
            continue
        var values: Dictionary = affix.value_by_level[tier_level]
        var tier_lo: float
        var tier_hi: float
        if values.has("min_low") and values.has("max_high"):

            tier_lo = float(values["min_low"])
            tier_hi = float(values["max_high"])
        elif values.has("min") and values.has("max"):
            tier_lo = float(values["min"])
            tier_hi = float(values["max"])
        elif values.has("value"):
            tier_lo = float(values["value"])
            tier_hi = float(values["value"])
        else:
            continue
        lo = minf(lo, tier_lo)
        hi = maxf(hi, tier_hi)
    if lo == INF:

        lo = affix.min_value
        hi = affix.max_value

    var value_or_range: Variant
    if is_equal_approx(lo, hi):
        value_or_range = lo
    else:
        value_or_range = {"min": lo, "max": hi}


    var preview_instance: = AffixInstance.new(affix, value_or_range, 1)
    var text: String = preview_instance.get_display_text()
    if text == "" or text == "Invalid Affix":
        text = affix.display_name if affix.display_name != "" else affix.affix_id
    return text









static func _roll_affix_instance(affix_base: AffixBase, item_level: int, pool: AffixPool) -> AffixInstance:
    var valid_tiers: Array[int] = pool.get_valid_tiers(affix_base, item_level)
    var tier: int = pool.roll_weighted_tier(valid_tiers)
    var rolled: Variant = affix_base.roll_value_at_level(item_level)
    rolled = _round_rolled_value(rolled, affix_base)
    return AffixInstance.new(affix_base, rolled, tier)









static func _round_rolled_value(rolled: Variant, affix_base: AffixBase) -> Variant:
    if not _should_round_stat(affix_base.stat_type):
        return rolled
    if rolled is Dictionary:
        rolled.min = round(rolled.min)
        rolled.max = round(rolled.max)
    else:
        rolled = round(rolled)
    return rolled





static func _should_round_stat(stat_type: String) -> bool:
    if stat_type.is_empty():
        return true
    var definition: StatDefinition = StatDefinitionManager.get_stat_definition(stat_type)
    if definition == null:
        push_warning("CraftingService: no StatDefinition for stat_type '%s' — defaulting to round()." % stat_type)
        return true
    return definition.decimal_places <= 0






static func _pick_corrupt_outcome() -> int:
    var outcomes: Array = CraftingDefinitions.CORRUPT_OUTCOMES.keys()
    return outcomes[randi() % outcomes.size()]








static func _corrupt_reroll_affixes(item: Item) -> Dictionary:
    var old_prefixes: Array = item.prefix_affixes.duplicate()
    var old_suffixes: Array = item.suffix_affixes.duplicate()
    item.prefix_affixes.clear()
    item.suffix_affixes.clear()

    var pool: AffixPool = _ensure_pool()
    if old_prefixes.size() > 0:
        var pcands: Array[AffixBase] = pool.get_valid_prefixes(item.base_item, item.item_level, item.source_tags)
        _add_random_affixes(item, pcands, old_prefixes.size(), true, pool)
    if old_suffixes.size() > 0:
        var scands: Array[AffixBase] = pool.get_valid_suffixes(item.base_item, item.item_level, item.source_tags)
        _add_random_affixes(item, scands, old_suffixes.size(), false, pool)

    return {
        "prefix_count": old_prefixes.size(), 
        "suffix_count": old_suffixes.size(), 
        "old_prefixes": old_prefixes, 
        "old_suffixes": old_suffixes, 
        "new_prefixes": item.prefix_affixes.duplicate(), 
        "new_suffixes": item.suffix_affixes.duplicate(), 
    }







static func _corrupt_reroll_ranges(item: Item) -> Dictionary:
    var changes: Array = []
    for inst in item.implicit_affixes + item.prefix_affixes + item.suffix_affixes:
        if inst == null or inst.affix_base == null:
            continue
        var old_value: Variant = inst.rolled_value
        if old_value is Dictionary:
            old_value = (old_value as Dictionary).duplicate()


        var rolled: Variant = inst.affix_base.roll_value_at_level(inst.tier_level)
        inst.rolled_value = _round_rolled_value(rolled, inst.affix_base)
        changes.append({
            "affix": inst, 
            "old_value": old_value, 
            "new_value": inst.rolled_value, 
        })
    return {"rerolled_count": changes.size(), "changes": changes}








static func _corrupt_shift_tiers(item: Item) -> Dictionary:
    var changes: Array = []
    for inst in item.prefix_affixes + item.suffix_affixes:
        if inst == null or inst.affix_base == null:
            continue
        var tiers_sorted: Array = inst.affix_base.value_by_level.keys()
        tiers_sorted.sort()
        if tiers_sorted.is_empty():
            continue
        var current_idx: int = tiers_sorted.find(inst.tier_level)
        if current_idx < 0:
            current_idx = 0
        var step: int = 1 if randf() < 0.5 else -1
        var new_idx: int = clampi(current_idx + step, 0, tiers_sorted.size() - 1)
        var new_tier: int = tiers_sorted[new_idx]
        var old_tier: int = inst.tier_level
        var old_value: Variant = inst.rolled_value
        if old_value is Dictionary:
            old_value = (old_value as Dictionary).duplicate()
        inst.tier_level = new_tier
        var rolled: Variant = inst.affix_base.roll_value_at_level(new_tier)
        inst.rolled_value = _round_rolled_value(rolled, inst.affix_base)
        changes.append({
            "affix": inst, 
            "old_tier": old_tier, 
            "new_tier": new_tier, 
            "old_value": old_value, 
            "new_value": inst.rolled_value, 
        })
    return {"shifted_count": changes.size(), "changes": changes}






static func _corrupt_add_mod(item: Item) -> Dictionary:
    var pool: AffixPool = _ensure_pool()
    var corruption_pool: Array[AffixBase] = pool.get_corruption_only_pool(item.base_item)
    if corruption_pool.is_empty():
        return {"added": null, "reason": "No corruption mods available for this base"}



    var picked: AffixBase = pool.pick_weighted_affix(corruption_pool)
    if picked == null:
        return {"added": null, "reason": "Picker returned null"}

    var instance: AffixInstance = _roll_affix_instance(picked, item.item_level, pool)


    if picked.is_prefix:
        item.prefix_affixes.append(instance)
    else:
        item.suffix_affixes.append(instance)
    return {"added": instance}





static func _add_random_affixes(item: Item, candidates: Array[AffixBase], count: int, is_prefix: bool, pool: AffixPool) -> void :
    var available: Array = candidates.duplicate()
    var target: Array = item.prefix_affixes if is_prefix else item.suffix_affixes
    for _i in count:
        if available.is_empty():
            break
        var picked: AffixBase = pool.pick_weighted_affix(available)
        if picked == null:
            break
        available.erase(picked)
        var instance: AffixInstance = _roll_affix_instance(picked, item.item_level, pool)
        target.append(instance)
