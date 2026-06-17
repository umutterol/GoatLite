class_name ExileGenerator
extends RefCounted







static func create_exile(params: Dictionary = {}) -> ExileData:
    var exile = ExileData.new()



    exile.lifecycle = ExileLifecycleState.new()


    var class_def = params.get("class", null) as ClassDefinition
    var min_class_rarity = params.get("min_class_rarity", 0)
    var class_rarity_override = params.get("class_rarity_override", -1)
    var custom_name = params.get("name", "")
    var starting_level = params.get("level", 1)




    var quality_bonus: float = float(params.get("quality_bonus", 0.0))


    if not class_def:
        if class_rarity_override >= 0:
            class_def = ClassLibrary.get_random_class_by_rarity(class_rarity_override)
        elif quality_bonus > 0.0:

            class_def = ClassLibrary.get_random_class_with_quality_bonus(min_class_rarity, quality_bonus)
        elif min_class_rarity > 0:
            class_def = ClassLibrary.get_random_class_min_rarity(min_class_rarity)
        else:
            class_def = ClassLibrary.get_random_class()


    _apply_class_to_exile(exile, class_def)


    _generate_and_apply_traits(exile, params)


    _initialize_potential(exile)


    _calculate_initial_stats(exile)


    exile.id = _generate_exile_id()
    exile.name = custom_name if custom_name else _generate_exile_name(class_def)
    exile.level = starting_level






    _bake_initiator_node(exile)


    if starting_level > 1:






        exile.level = 1
        for i in range(starting_level - 1):
            exile.level += 1
            exile.pending_passive_points += GameSettings.PASSIVE_POINTS_PER_LEVEL
            LevelUpSystem.queue_level_up(exile)



        LevelUpSystem.resolve_pending_growth(exile)

    return exile






static func _bake_initiator_node(exile: ExileData) -> void :
    var choices: Array[PassiveDefinition] = PassiveSelectionManager.generate_initiator_choices(exile)
    if choices.is_empty():

        push_warning("ExileGenerator: no initiator choices available for %s" % exile.name)
        return
    var choice_ids: Array[String] = []
    for c in choices:
        choice_ids.append(c.passive_id)
    var node: PassiveTreeNode = PassiveTreeNode.new()
    node.level = 1
    node.generated_choice_ids = choice_ids
    node.chosen_index = -1
    node.is_initiator = true


    node.growth_applied = true
    exile.passive_tree_root = node

    exile.pending_passive_points += GameSettings.PASSIVE_POINTS_PER_LEVEL




static func _apply_class_to_exile(exile: ExileData, class_def: ClassDefinition):

    exile.class_id = class_def.class_id
    exile.class_definition = class_def


    var base_stats = ExileStats.new()


    var overrides = class_def.get_stat_overrides()
    for stat_id in overrides:
        var value = overrides[stat_id]
        base_stats.set(stat_id, value)


    exile.base_stats = base_stats




static func _generate_and_apply_traits(exile: ExileData, params: Dictionary):

    var min_rarity = params.get("min_trait_rarity", 0)


    var quality_bonus: float = float(params.get("quality_bonus", 0.0))



    var trait_ids = TraitManager.generate_starting_traits(
        exile.class_definition, 
        min_rarity, 
        quality_bonus, 
    )


    for trait_id in trait_ids:
        exile.add_trait(trait_id, "Background")



static func _initialize_potential(exile: ExileData):


    if not exile.potential:
        exile.potential = ExilePotential.new()


    exile.potential.add_exile_random_potentials()


    if exile.class_definition:
        var class_potentials = exile.class_definition.get_potential_modifiers()
        exile.potential.add_class_potentials(class_potentials)


    for trait_id in exile.traits:
        var trait_def = TraitLibrary.get_trait_by_id(trait_id)
        if trait_def:
            var modifiers = trait_def.get_potential_modifiers()
            if not modifiers.is_empty():
                exile.potential.add_trait_potentials(trait_def.name, modifiers)


    exile.potential.finalize_potentials()



static func _calculate_initial_stats(exile: ExileData):
    exile.current_stats = StatCalculator.calculate_final_stats(exile)

    exile.current_life = exile.current_stats.life

    exile.current_vitality = exile.current_stats.vitality * 1.0

    exile.current_stats.current_life = exile.current_life
    exile.current_stats.max_life = exile.current_stats.life
















static func recalculate_stats(exile: ExileData):
    var had_prior_stats: bool = exile.current_stats != null
    var old_max_life: float = exile.current_stats.life if had_prior_stats else 0.0

    exile.current_stats = StatCalculator.calculate_final_stats(exile)
    var new_max_life: float = exile.current_stats.life

    if had_prior_stats:
        var delta: float = new_max_life - old_max_life
        if exile.current_life > 0.0:
            exile.current_life = clampf(exile.current_life + delta, 1.0, new_max_life)
        else:

            exile.current_life = 0.0


    exile.current_stats.current_life = exile.current_life
    exile.current_stats.max_life = new_max_life



static func _generate_exile_id() -> int:

    var id = GameState.next_exile_id
    GameState.next_exile_id += 1
    return id

static func _generate_exile_name(class_def: ClassDefinition) -> String:

    if class_def and randf() < 0.7:
        return ExileNames.generate_class_name(class_def.class_id)
    else:
        return ExileNames.generate_random_name()



static func generate_recruit_options(count: int = 3, params: Dictionary = {}) -> Array[ExileData]:
    var recruits: Array[ExileData] = []








    for i in range(count):
        var recruit_params = params.duplicate()

        recruits.append(create_exile(recruit_params))

    return recruits



static func prepare_exile_for_save(exile: ExileData) -> ExileData:



    return exile

static func restore_exile_from_save(exile: ExileData) -> ExileData:





    if exile.class_id and not exile.class_definition:
        exile.class_definition = ClassLibrary.get_class_by_id(exile.class_id)

    return exile
