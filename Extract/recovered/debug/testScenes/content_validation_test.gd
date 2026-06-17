extends Node2D
































const COMPOSITE_STATS: Array[String] = ["damage", "elemental_damage"]



const SCALING_NAMES: Dictionary = {
    0: "FLAT", 
    1: "INCREASED", 
    2: "MORE", 
    3: "REDUCED", 
    4: "LESS", 
}



const MODIFIER_NAMES: Dictionary = {
    0: "FLAT_ADDED", 
    1: "PERCENT_INCREASED", 
    2: "PERCENT_REDUCED", 
    3: "PERCENT_MORE", 
    4: "PERCENT_LESS", 
    5: "FLAT_OVERRIDE", 
}


var _passive_issues: int = 0
var _trait_issues: int = 0
var _class_issues: int = 0
var _affix_issues: int = 0
var _weapon_issues: int = 0





var _explicit_affix_cache: Array[AffixBase] = []
var _explicit_affix_cache_built: bool = false


func _ready() -> void :
    print("\n========== CONTENT VALIDATION TEST ==========")
    _validate_passives()
    _validate_traits()
    _validate_classes()
    _validate_affixes()
    _validate_weapons()
    _print_summary()



func _validate_passives() -> void :
    print("\n--- Passives ---")
    if PassiveLibrary == null:
        _fail_passive("PassiveLibrary autoload missing — cannot validate passives")
        return

    var all_passives: Array[PassiveDefinition] = PassiveLibrary.get_all_passives()
    print("  Loaded %d passives." % all_passives.size())



    var seen_ids: Dictionary = {}

    for passive in all_passives:
        if passive == null:
            _fail_passive("null entry in PassiveLibrary.all_passives")
            continue
        _check_required_id(passive.passive_id, "passive_id", "Passive", passive)
        _check_filename_id_match(passive.resource_path, passive.passive_id, "Passive")
        _check_duplicate_id(seen_ids, passive.passive_id, passive.resource_path, "Passive")

        for bonus in passive.stat_bonuses:
            if bonus == null:
                _fail_passive("Passive '%s' has a null entry in stat_bonuses" % passive.passive_id)
                continue
            _check_stat_bonus(bonus, "Passive '%s'" % passive.passive_id, "_fail_passive")

        for conditional in passive.conditional_bonuses:
            if conditional == null:
                _fail_passive("Passive '%s' has a null entry in conditional_bonuses" % passive.passive_id)
                continue
            _check_stat_bonus(conditional, "Passive '%s' (conditional)" % passive.passive_id, "_fail_passive")

    if _passive_issues == 0:
        print("  ✓ All passives clean.")


func _fail_passive(message: String) -> void :
    push_warning("[ContentValidation] " + message)
    print("  ✗ %s" % message)
    _passive_issues += 1



func _validate_traits() -> void :
    print("\n--- Traits ---")
    if TraitLibrary == null:
        _fail_trait("TraitLibrary autoload missing — cannot validate traits")
        return

    var all_traits: Array[TraitDefinition] = TraitLibrary.get_all_traits()
    print("  Loaded %d traits." % all_traits.size())

    var seen_ids: Dictionary = {}

    for trait_def in all_traits:
        if trait_def == null:
            _fail_trait("null entry in TraitLibrary.all_traits")
            continue
        _check_required_id(trait_def.trait_id, "trait_id", "Trait", trait_def)
        _check_filename_id_match(trait_def.resource_path, trait_def.trait_id, "Trait")
        _check_duplicate_id(seen_ids, trait_def.trait_id, trait_def.resource_path, "Trait")

        for bonus in trait_def.stat_bonuses:
            if bonus == null:
                _fail_trait("Trait '%s' has a null entry in stat_bonuses" % trait_def.trait_id)
                continue
            _check_stat_bonus(bonus, "Trait '%s'" % trait_def.trait_id, "_fail_trait")



        if "conditional_bonuses" in trait_def:
            for conditional in trait_def.conditional_bonuses:
                if conditional == null:
                    _fail_trait("Trait '%s' has a null entry in conditional_bonuses" % trait_def.trait_id)
                    continue
                _check_stat_bonus(conditional, "Trait '%s' (conditional)" % trait_def.trait_id, "_fail_trait")

    if _trait_issues == 0:
        print("  ✓ All traits clean.")


func _fail_trait(message: String) -> void :
    push_warning("[ContentValidation] " + message)
    print("  ✗ %s" % message)
    _trait_issues += 1



func _validate_classes() -> void :
    print("\n--- Classes ---")
    if ClassLibrary == null:
        _fail_class("ClassLibrary autoload missing — cannot validate classes")
        return

    var all_classes: Array[ClassDefinition] = ClassLibrary.get_all_classes()

    print("  Loaded %d classes." % all_classes.size())

    for class_def in all_classes:
        if class_def == null:
            _fail_class("null entry in class library")
            continue
        _check_required_id(class_def.class_id, "class_id", "Class", class_def)
        _check_filename_id_match(class_def.resource_path, class_def.class_id, "Class")




        if "conditional_bonuses" in class_def:
            for conditional in class_def.conditional_bonuses:
                if conditional == null:
                    _fail_class("Class '%s' has a null entry in conditional_bonuses" % class_def.class_id)
                    continue
                _check_stat_bonus(conditional, "Class '%s' (conditional)" % class_def.class_id, "_fail_class")


        for stat_id in class_def.growth_stat_ids:
            if not _stat_id_exists(stat_id) and not COMPOSITE_STATS.has(stat_id):
                _fail_class("Class '%s' growth_stat_ids contains unknown stat '%s'" % [class_def.class_id, stat_id])
        for stat_id in class_def.percent_stat_ids:
            if not _stat_id_exists(stat_id) and not COMPOSITE_STATS.has(stat_id):
                _fail_class("Class '%s' percent_stat_ids contains unknown stat '%s'" % [class_def.class_id, stat_id])

    if _class_issues == 0:
        print("  ✓ All classes clean.")


func _fail_class(message: String) -> void :
    push_warning("[ContentValidation] " + message)
    print("  ✗ %s" % message)
    _class_issues += 1



func _validate_affixes() -> void :
    print("\n--- Affixes ---")
    var base_path: = "res://systems/items/affixes/"
    var files: Array = []
    _scan_directory_recursive(base_path, files)

    var loaded: = 0
    var seen_ids: Dictionary = {}

    for path in files:
        if not path.ends_with(".tres"):
            continue
        var res: Resource = load(path)
        if res == null:
            _fail_affix("Could not load affix at %s — file may be malformed" % path)
            continue
        if not (res is AffixBase):



            _fail_affix("Non-AffixBase .tres in affix tree: %s" % path)
            continue

        loaded += 1
        _check_required_id(res.affix_id, "affix_id", "Affix", res)
        _check_filename_id_match(path, res.affix_id, "Affix")
        _check_duplicate_id(seen_ids, res.affix_id, path, "Affix")


        if res.stat_type == "":
            _fail_affix("Affix '%s' has empty stat_type" % res.affix_id)
        elif not _stat_id_exists(res.stat_type) and not COMPOSITE_STATS.has(res.stat_type):
            _fail_affix("Affix '%s' references unknown stat_type '%s'" % [res.affix_id, res.stat_type])



        if COMPOSITE_STATS.has(res.stat_type) and res.modifier_type == 0:
            _fail_affix("Affix '%s' uses FLAT_ADDED on composite stat '%s' — won't apply (StatCalculator only fans composites for % modifiers)" % [res.affix_id, res.stat_type])



        if res.is_implicit:
            if res.is_prefix or res.is_suffix:
                _fail_affix("Affix '%s' is_implicit but also has is_prefix/is_suffix set" % res.affix_id)
        else:
            if res.is_prefix == res.is_suffix:
                _fail_affix("Affix '%s' must be exactly one of prefix/suffix (or implicit). Currently is_prefix=%s, is_suffix=%s" % [res.affix_id, res.is_prefix, res.is_suffix])





        if res.use_tier_helper:
            if res.value_tiers.is_empty():
                _fail_affix("Affix '%s' has use_tier_helper=true but value_tiers is empty" % res.affix_id)
            else:
                var has_covering_tier: = false
                for tier in res.value_tiers:
                    if tier == null:
                        _fail_affix("Affix '%s' has a null entry in value_tiers" % res.affix_id)
                        continue
                    if tier.item_level <= res.min_item_level:
                        has_covering_tier = true
                if not has_covering_tier:
                    _fail_affix("Affix '%s' min_item_level=%d but no AffixValueTier covers that level (lowest tier=%d)" % [res.affix_id, res.min_item_level, _lowest_tier_level(res.value_tiers)])



        if not _affix_has_any_slot(res):
            _fail_affix("Affix '%s' has no valid_on_* slot flags set — it will never roll" % res.affix_id)

    print("  Loaded %d affixes." % loaded)
    if _affix_issues == 0:
        print("  ✓ All affixes clean.")


func _fail_affix(message: String) -> void :
    push_warning("[ContentValidation] " + message)
    print("  ✗ %s" % message)
    _affix_issues += 1













func _validate_weapons() -> void :
    print("\n--- Weapons ---")
    var base_path: = "res://systems/items/itemBases/weapon/"
    var files: Array = []
    _scan_directory_recursive(base_path, files)

    var loaded: = 0
    var seen_ids: Dictionary = {}

    for path in files:
        if not path.ends_with(".tres"):
            continue
        var res: Resource = load(path)
        if res == null:
            _fail_weapon("Could not load weapon at %s — file may be malformed" % path)
            continue
        if not (res is ItemBase):
            _fail_weapon("Non-ItemBase .tres in weapon tree: %s" % path)
            continue
        if res.category != ItemEnums.ItemCategory.WEAPON:
            _fail_weapon("Weapon base '%s' at %s has category=%d (expected WEAPON)" % [res.item_id, path, res.category])
            continue

        loaded += 1
        _check_required_id(res.item_id, "item_id", "Weapon", res)
        _check_filename_id_match(path, res.item_id, "Weapon")
        _check_duplicate_id(seen_ids, res.item_id, path, "Weapon")


        if not _weapon_has_any_base_damage(res):
            _fail_weapon("Weapon '%s' has no base damage on any type — will deal 0 damage" % res.item_id)
        _check_weapon_damage_ranges(res)



        if res.base_attack_speed <= 0.0:
            _fail_weapon("Weapon '%s' has base_attack_speed=%s (must be > 0)" % [res.item_id, str(res.base_attack_speed)])


        if res.base_critical_chance < 0.0:
            _fail_weapon("Weapon '%s' has negative base_critical_chance=%s" % [res.item_id, str(res.base_critical_chance)])


        if res.icon == null:
            _fail_weapon("Weapon '%s' has no icon assigned" % res.item_id)





        for implicit in res.implicit_affixes:
            if implicit == null:
                _fail_weapon("Weapon '%s' has a null entry in implicit_affixes" % res.item_id)
                continue
            if not implicit.is_implicit:
                _fail_weapon("Weapon '%s' references affix '%s' as implicit, but that affix has is_implicit=false" % [res.item_id, implicit.affix_id])




        var rollable_prefixes: = 0
        var rollable_suffixes: = 0
        for affix in _get_explicit_affixes():
            if not affix.can_appear_on_item(res):
                continue
            if affix.is_prefix:
                rollable_prefixes += 1
            elif affix.is_suffix:
                rollable_suffixes += 1
        if rollable_prefixes == 0:
            _fail_weapon("Weapon '%s' has zero rollable prefixes — no explicit prefix passes can_appear_on_item (likely missing valid_on_<weapon_type> on the affixes)" % res.item_id)
        if rollable_suffixes == 0:
            _fail_weapon("Weapon '%s' has zero rollable suffixes — no explicit suffix passes can_appear_on_item" % res.item_id)

    print("  Loaded %d weapons." % loaded)
    if _weapon_issues == 0:
        print("  ✓ All weapons clean.")


func _fail_weapon(message: String) -> void :
    push_warning("[ContentValidation] " + message)
    print("  ✗ %s" % message)
    _weapon_issues += 1




func _weapon_has_any_base_damage(item: ItemBase) -> bool:
    return item.base_physical_damage_max > 0\
or item.base_fire_damage_max > 0\
or item.base_cold_damage_max > 0\
or item.base_lightning_damage_max > 0\
or item.base_chaos_damage_max > 0





func _check_weapon_damage_ranges(item: ItemBase) -> void :
    var types: Array = [
        ["physical", item.base_physical_damage_min, item.base_physical_damage_max], 
        ["fire", item.base_fire_damage_min, item.base_fire_damage_max], 
        ["cold", item.base_cold_damage_min, item.base_cold_damage_max], 
        ["lightning", item.base_lightning_damage_min, item.base_lightning_damage_max], 
        ["chaos", item.base_chaos_damage_min, item.base_chaos_damage_max], 
    ]
    for entry in types:
        var dmg_name: String = entry[0]
        var dmg_min: int = entry[1]
        var dmg_max: int = entry[2]
        if dmg_min > dmg_max:
            _fail_weapon("Weapon '%s' base_%s_damage_min (%d) > max (%d)" % [item.item_id, dmg_name, dmg_min, dmg_max])






func _get_explicit_affixes() -> Array[AffixBase]:
    if _explicit_affix_cache_built:
        return _explicit_affix_cache
    _explicit_affix_cache_built = true
    var files: Array = []
    _scan_directory_recursive("res://systems/items/affixes/explicit/", files)
    for affix_path in files:
        if not affix_path.ends_with(".tres"):
            continue
        var res: Resource = load(affix_path)
        if res is AffixBase and not res.is_implicit and (res.is_prefix or res.is_suffix):
            _explicit_affix_cache.append(res)
    return _explicit_affix_cache







func _check_stat_bonus(bonus: Resource, context: String, fail_handler_name: String) -> void :
    var stat_id: String = bonus.stat_id
    if stat_id == "":
        call(fail_handler_name, "%s has a bonus with empty stat_id" % context)
        return
    var is_composite: = COMPOSITE_STATS.has(stat_id)
    if not is_composite and not _stat_id_exists(stat_id):
        call(fail_handler_name, "%s references unknown stat_id '%s'" % [context, stat_id])

    var scaling: int = bonus.scaling_type
    var scaling_name: String = SCALING_NAMES.get(scaling, "UNKNOWN(%d)" % scaling)





    if scaling in [1, 2, 3, 4] and bonus.base_value < 0.0:
        call(fail_handler_name, "%s has negative %s value (%s) — use the opposite scaling type instead" % [context, scaling_name, str(bonus.base_value)])



    if is_composite and scaling == 0:
        call(fail_handler_name, "%s uses FLAT scaling on composite stat '%s' — won't apply (only %% scaling fans composites)" % [context, stat_id])


    if bonus.use_random_range and bonus.value_range_max < bonus.value_range_min:
        call(fail_handler_name, "%s use_random_range max (%s) < min (%s)" % [context, str(bonus.value_range_max), str(bonus.value_range_min)])


func _check_required_id(id_value: String, field_name: String, kind: String, res: Resource) -> void :
    if id_value == "":
        var path: String = res.resource_path if res != null else "<unknown>"
        var fail_handler: = _fail_handler_for_kind(kind)
        call(fail_handler, "%s at %s has empty %s" % [kind, path, field_name])


func _check_filename_id_match(resource_path: String, id_value: String, kind: String) -> void :
    if resource_path == "" or id_value == "":
        return
    var filename: = resource_path.get_file().get_basename()
    if filename != id_value:
        var fail_handler: = _fail_handler_for_kind(kind)
        call(fail_handler, "%s at %s has id '%s' but filename '%s' — convention requires they match" % [kind, resource_path, id_value, filename])


func _check_duplicate_id(seen: Dictionary, id_value: String, path: String, kind: String) -> void :
    if id_value == "":
        return
    if seen.has(id_value):
        var fail_handler: = _fail_handler_for_kind(kind)
        call(fail_handler, "%s duplicate id '%s' at %s (also at %s)" % [kind, id_value, path, seen[id_value]])
    else:
        seen[id_value] = path





func _fail_handler_for_kind(kind: String) -> String:
    match kind:
        "Passive":
            return "_fail_passive"
        "Trait":
            return "_fail_trait"
        "Class":
            return "_fail_class"
        "Affix":
            return "_fail_affix"
        "Weapon":
            return "_fail_weapon"
        _:
            return "_fail_passive"


func _stat_id_exists(stat_id: String) -> bool:
    if StatDefinitionManager == null:
        return false
    return StatDefinitionManager.get_stat_definition(stat_id) != null


func _affix_has_any_slot(affix: AffixBase) -> bool:



    return affix.valid_on_helmet\
or affix.valid_on_gloves\
or affix.valid_on_boots\
or affix.valid_on_chest\
or affix.valid_on_1h_weapon\
or affix.valid_on_2h_weapon\
or affix.valid_on_ring\
or affix.valid_on_amulet\
or affix.valid_on_belt\
or affix.valid_on_rucksack\
or affix.valid_on_sword\
or affix.valid_on_mace\
or affix.valid_on_axe\
or affix.valid_on_bow\
or affix.valid_on_staff\
or affix.valid_on_wand\
or affix.valid_on_focus\
or affix.valid_on_sceptre\
or affix.valid_on_shield\
or affix.valid_on_spear\
or affix.valid_on_dagger


func _lowest_tier_level(value_tiers: Array) -> int:
    var lowest: int = 999999
    for tier in value_tiers:
        if tier == null:
            continue
        if tier.item_level < lowest:
            lowest = tier.item_level
    return lowest


func _scan_directory_recursive(path: String, file_list: Array) -> void :
    var dir: = DirAccess.open(path)
    if dir == null:
        return
    dir.list_dir_begin()
    var file_name: = dir.get_next()
    while file_name != "":
        var full_path: = path + "/" + file_name
        if dir.current_is_dir() and file_name != "." and file_name != "..":
            _scan_directory_recursive(full_path, file_list)
        else:
            file_list.append(full_path)
        file_name = dir.get_next()


func _print_summary() -> void :
    print("\n========== SUMMARY ==========")
    print("  Passive issues: %d" % _passive_issues)
    print("  Trait issues:   %d" % _trait_issues)
    print("  Class issues:   %d" % _class_issues)
    print("  Affix issues:   %d" % _affix_issues)
    print("  Weapon issues:  %d" % _weapon_issues)
    var total: = _passive_issues + _trait_issues + _class_issues + _affix_issues + _weapon_issues
    if total == 0:
        print("  ✓ ALL CONTENT VALID")
    else:
        print("  ✗ %d issue(s) found — see ✗ lines above and any [ContentValidation] push_warning entries" % total)
    print("=============================\n")
