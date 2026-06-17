class_name LevelUpSystem
extends RefCounted
























static func queue_level_up(exile: ExileData) -> PassiveTreeNode:
    if not _validate(exile):
        return null





    var choices: Array[PassiveDefinition] = PassiveSelectionManager.generate_passive_choices(exile)
    var choice_ids: Array[String] = []
    for choice in choices:
        choice_ids.append(choice.passive_id)

    var node: PassiveTreeNode = exile.append_pending_level_node(exile.level, choice_ids)


    _apply_level_up_healing(exile)

    GameState.level_up_queued.emit(exile, node)
    GameState.exile_updated.emit(exile)
    return node










static func resolve_pending_growth(exile: ExileData) -> Array[int]:
    var resolved: Array[int] = []
    if not _validate(exile):
        return resolved

    var cursor: PassiveTreeNode = exile.passive_tree_root
    while cursor != null:
        if not cursor.growth_applied:
            _apply_flat_growth(exile)
            _check_potential_discovery(exile)
            _check_learned_traits(exile, cursor.level)
            cursor.growth_applied = true
            resolved.append(cursor.level)


        var next: PassiveTreeNode = cursor.get_next_in_path()
        if next == null:
            break
        cursor = next

    if not resolved.is_empty():

        exile.current_stats = StatCalculator.calculate_final_stats(exile)
        GameState.level_up_growth_resolved.emit(exile, resolved)
        GameState.exile_updated.emit(exile)
    return resolved





static func snapshot_stats(exile: ExileData) -> ExileStats:
    if not _validate(exile):
        return null
    var stats: ExileStats = StatCalculator.calculate_final_stats(exile)
    return stats.duplicate(true) as ExileStats




static func _validate(exile: ExileData) -> bool:
    if not exile or not exile.class_definition:
        push_error("LevelUpSystem: invalid exile or missing class")
        return false
    return true




static func _apply_flat_growth(exile: ExileData) -> void :
    var class_def: ClassDefinition = exile.class_definition
    var flat_growth: Dictionary = class_def.get_all_growth_stats()

    for stat_id in flat_growth:
        var growth_value = flat_growth[stat_id]
        if growth_value == 0:
            continue

        var current_value = exile.base_stats.get(stat_id)

        if current_value is Vector2:
            exile.base_stats.set(stat_id, Vector2(
                current_value.x + growth_value, 
                current_value.y + growth_value
            ))
        elif current_value is float or current_value is int:
            exile.base_stats.set(stat_id, current_value + growth_value)
        else:
            push_warning("LevelUpSystem: unknown stat type for growth: " + str(stat_id))



static func _check_potential_discovery(exile: ExileData) -> void :
    if not exile.potential:
        push_error("LevelUpSystem: no potential system on " + exile.name)
        return



    var hidden_before: Array[String] = []
    for tag in exile.potential.entries:
        if exile.potential.entries[tag].is_hidden:
            hidden_before.append(tag)

    if not exile.potential.try_reveal_random_potential():
        return


    for tag in hidden_before:
        if not exile.potential.entries[tag].is_hidden:
            print("[LevelUp] %s discovered potential: %s" % [exile.name, tag])
            GameState.potential_discovered.emit(exile, tag)
            return




static func _check_learned_traits(exile: ExileData, at_level: int) -> void :
    if not (at_level in GameSettings.LEARNED_TRAIT_LEVELS):
        return

    var new_trait_id: String = TraitManager.generate_learned_trait(exile)
    if new_trait_id == "":
        return

    exile.add_trait(new_trait_id, "Level " + str(at_level))

    var trait_def: TraitDefinition = TraitLibrary.get_trait_by_id(new_trait_id)
    if trait_def:
        var modifiers: Dictionary = trait_def.get_potential_modifiers()
        if not modifiers.is_empty():
            exile.potential.add_trait_potentials(trait_def.name, modifiers)
        print("[LevelUp] %s learned trait: %s" % [exile.name, trait_def.name])
        GameState.trait_learned.emit(exile, new_trait_id)




static func _apply_level_up_healing(exile: ExileData) -> void :

    exile.current_stats = StatCalculator.calculate_final_stats(exile)
    var max_life: float = exile.current_stats.life
    exile.current_life = min(exile.current_life + max_life, max_life)
    exile.current_stats.current_life = exile.current_life
    exile.current_stats.max_life = max_life
