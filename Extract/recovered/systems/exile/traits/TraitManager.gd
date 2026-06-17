class_name TraitManager
extends RefCounted

enum TraitRarity{
    COMMON = 0, 
    UNCOMMON = 1, 
    RARE = 2, 
    LEGENDARY = 3
}










static func generate_starting_traits(
    class_def: ClassDefinition, 
    min_rarity: TraitRarity = TraitRarity.COMMON, 
    quality_bonus: float = 0.0, 
) -> Array[String]:
    if class_def == null:
        push_error("TraitManager.generate_starting_traits: null class_def")
        return []


    var num_traits = _roll_trait_count()

    var selected_traits: Array[String] = []
    var available_pool = _get_available_background_traits(class_def, min_rarity)

    var i = 0
    while i < num_traits:
        var selected_trait = _weighted_trait_selection(
            available_pool, selected_traits, min_rarity, quality_bonus
        )
        if selected_trait:
            selected_traits.append(selected_trait.trait_id)
            _remove_incompatible_traits(available_pool, selected_trait)
        i += 1

    return selected_traits


static func generate_learned_trait(exile_data: ExileData) -> String:
    var available_pool = _get_available_learned_traits(exile_data)

    if available_pool.is_empty():
        return ""

    var selected_trait = _weighted_trait_selection(available_pool, exile_data.traits)
    if selected_trait:
        return selected_trait.trait_id
    else:
        return ""








static func _is_class_trait_compatible(trait_def: TraitDefinition, class_def: ClassDefinition) -> bool:
    if trait_def == null:
        return false
    if class_def == null:
        return true
    if not trait_def.is_class_compatible(class_def.name):
        return false
    if class_def.incompatible_trait_ids.has(trait_def.trait_id):
        return false
    return true


static func _roll_trait_count() -> int:
    var roll = randf() * 100.0

    if roll <= 80.0:
        return 1
    elif roll <= 95.0:
        return 2
    else:
        return 3




static func _get_available_background_traits(class_def: ClassDefinition, min_rarity: int) -> Array[TraitDefinition]:
    var all_traits = TraitLibrary.get_background_traits()
    var available: Array[TraitDefinition] = []

    var i = 0
    while i < all_traits.size():
        var current_trait = all_traits[i]

        if not _is_class_trait_compatible(current_trait, class_def):
            i += 1
            continue


        if current_trait.rarity < min_rarity:
            i += 1
            continue

        available.append(current_trait)
        i += 1

    return available





static func _get_available_learned_traits(exile_data: ExileData) -> Array[TraitDefinition]:
    var all_traits = TraitLibrary.get_learned_traits()
    var available: Array[TraitDefinition] = []
    var class_def: ClassDefinition = exile_data.class_definition

    var i = 0
    while i < all_traits.size():
        var current_trait = all_traits[i]

        if not _is_class_trait_compatible(current_trait, class_def):
            i += 1
            continue


        if exile_data.level < current_trait.required_level:
            i += 1
            continue


        if current_trait.unique and exile_data.has_trait(current_trait.trait_id):
            i += 1
            continue


        var has_incompatible = false
        var j = 0
        while j < current_trait.incompatible_traits.size():
            if exile_data.has_trait(current_trait.incompatible_traits[j]):
                has_incompatible = true
                break
            j += 1

        if has_incompatible:
            i += 1
            continue

        available.append(current_trait)
        i += 1

    return available








static func _weighted_trait_selection(
    available_traits: Array[TraitDefinition], 
    existing_traits: Array[String], 
    min_rarity: int = 0, 
    quality_bonus: float = 0.0, 
) -> TraitDefinition:
    if available_traits.is_empty():
        return null

    var pool: Array = []
    for current_trait in available_traits:
        if current_trait.rarity < min_rarity:
            continue
        if current_trait.unique:
            var already_has: = false
            for t_id in existing_traits:
                if t_id == current_trait.trait_id:
                    already_has = true
                    break
            if already_has:
                continue
        pool.append(current_trait)

    if pool.is_empty():
        return null

    var picked: Variant = RarityWeighting.pick_weighted(pool, quality_bonus)
    if picked == null:
        return pool[0]
    return picked as TraitDefinition


static func _remove_incompatible_traits(pool: Array[TraitDefinition], selected_trait: TraitDefinition):
    var to_remove = []

    var i = 0
    while i < pool.size():
        var current_trait = pool[i]
        var should_remove = false


        var j = 0
        while j < selected_trait.incompatible_traits.size():
            if selected_trait.incompatible_traits[j] == current_trait.trait_id:
                should_remove = true
                break
            j += 1


        if not should_remove:
            j = 0
            while j < current_trait.incompatible_traits.size():
                if current_trait.incompatible_traits[j] == selected_trait.trait_id:
                    should_remove = true
                    break
                j += 1

        if should_remove:
            to_remove.append(current_trait)
        i += 1


    i = 0
    while i < to_remove.size():
        pool.erase(to_remove[i])
        i += 1
