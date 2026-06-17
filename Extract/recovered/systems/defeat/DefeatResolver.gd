class_name DefeatResolver
extends RefCounted







class DefeatResult:
    var exile_data: ExileData
    var died: bool = false
    var outcome: DefeatOutcome
    var scar_trait: TraitDefinition
    var source_description: String = ""




static func resolve_all(defeat_contexts: Array[DefeatContext]) -> Array[DefeatResult]:
    var results: Array[DefeatResult] = []

    for context in defeat_contexts:
        var result: = resolve_single(context)
        if result:
            results.append(result)

    return results


static func resolve_single(context: DefeatContext) -> DefeatResult:
    if not context or not context.exile_data:
        push_error("DefeatResolver: invalid context")
        return null

    var result: = DefeatResult.new()
    result.exile_data = context.exile_data
    result.source_description = context.source_details


    if _roll_death(context.scar_count):
        result.died = true
        _apply_death(context.exile_data)
        return result


    var outcome: = _select_outcome(context)
    if not outcome:
        push_warning("DefeatResolver: no valid outcomes for %s, using fallback" % context.exile_data.name)
        outcome = _get_fallback_outcome()

    result.outcome = outcome


    _apply_outcome(context.exile_data, outcome, result)

    return result




static func _roll_death(scar_count: int) -> bool:
    var death_chance: float
    if GameSettings.DEATH_CHANCE_PER_SCAR.has(scar_count):
        death_chance = GameSettings.DEATH_CHANCE_PER_SCAR[scar_count]
    else:
        death_chance = GameSettings.DEATH_CHANCE_MAX_SCARS

    if death_chance <= 0.0:
        return false

    return randf() * 100.0 < death_chance


static func _apply_death(exile: ExileData) -> void :
    exile.status = "dead"
    GameState.exile_died.emit(exile.id)




static func _select_outcome(context: DefeatContext) -> DefeatOutcome:
    var all_outcomes: = _load_outcomes()
    var filter: = context.to_outcome_filter()

    var valid: Array[Dictionary] = []
    var total_weight: = 0.0

    for outcome in all_outcomes:
        if not outcome.is_valid_for_context(filter):
            continue
        if outcome.weight <= 0.0:
            continue
        valid.append({"outcome": outcome, "weight": outcome.weight})
        total_weight += outcome.weight

    if valid.is_empty():
        return null

    var roll: = randf() * total_weight
    var current: = 0.0

    for entry in valid:
        current += entry.weight
        if roll <= current:
            return entry.outcome

    return valid[0].outcome




static func _apply_outcome(
    exile: ExileData, 
    outcome: DefeatOutcome, 
    result: DefeatResult
) -> void :

    if outcome.vitality_cost_percent > 0.0:
        var vitality_loss: = exile.current_stats.max_vitality * (outcome.vitality_cost_percent / 100.0)
        exile.current_vitality = maxf(0.0, exile.current_vitality - vitality_loss)


    if outcome.morale_cost > 0.0:
        MoraleManager.apply_morale_damage(exile, outcome.morale_cost, outcome.display_name)


    if outcome.recovery_days > 0:
        exile.status = "recovering"



    if outcome.assigns_scar:
        var scar: = _resolve_scar(exile, outcome)
        if scar:
            exile.add_trait(scar.trait_id, "Defeat: " + outcome.display_name)
            result.scar_trait = scar
            ExileGenerator.recalculate_stats(exile)



            GameState.scar_assigned.emit(exile, scar)


    if outcome.items_damaged > 0 or outcome.items_destroyed > 0:
        pass





    if outcome.capture_duration_days > 0:
        exile.status = "lost"

    GameState.exile_updated.emit(exile)




static func _resolve_scar(exile: ExileData, outcome: DefeatOutcome) -> TraitDefinition:

    if not outcome.forced_scar_trait_id.is_empty():
        var forced: = TraitLibrary.get_trait_by_id(outcome.forced_scar_trait_id)
        if forced and not exile.has_trait(forced.trait_id):
            return forced


    var available: = _get_available_scars(exile)
    if available.is_empty():
        push_warning("DefeatResolver: no valid scars for %s" % exile.name)
        return null

    return _weighted_scar_selection(available)


static func _get_available_scars(exile: ExileData) -> Array[TraitDefinition]:
    var all_scars: = TraitLibrary.get_scar_traits()
    var available: Array[TraitDefinition] = []

    for scar in all_scars:
        if scar.unique and exile.has_trait(scar.trait_id):
            continue
        if not scar.is_class_compatible(exile.get_class_name()):
            continue
        var incompatible: = false
        for blocked_id in scar.incompatible_traits:
            if exile.has_trait(blocked_id):
                incompatible = true
                break
        if incompatible:
            continue
        available.append(scar)

    return available


static func _weighted_scar_selection(scars: Array[TraitDefinition]) -> TraitDefinition:
    if scars.is_empty():
        return null

    var total_weight: = 0.0
    for scar in scars:
        total_weight += scar.get_drop_weight()

    var roll: = randf() * total_weight
    var current: = 0.0

    for scar in scars:
        current += scar.get_drop_weight()
        if roll <= current:
            return scar

    return scars[0]




static var _cached_outcomes: Array[DefeatOutcome] = []

static func _load_outcomes() -> Array[DefeatOutcome]:
    if not _cached_outcomes.is_empty():
        return _cached_outcomes


    var root: = "res://systems/defeat/outcomes/"
    var paths: Array[String] = ResourceDirScan.list_tres_files_recursive(root)
    if paths.is_empty() and DirAccess.open(root) == null:
        push_warning("DefeatResolver: cannot open %s" % root)
        return _cached_outcomes

    for file_path in paths:
        var resource: = load(file_path)
        if resource is DefeatOutcome:
            _cached_outcomes.append(resource)

    return _cached_outcomes


static func _get_fallback_outcome() -> DefeatOutcome:
    var fallback: = DefeatOutcome.new()
    fallback.outcome_id = "fallback_downed"
    fallback.display_name = "Downed"
    fallback.description = "Knocked unconscious but recovered."
    fallback.morale_cost = 5.0





    fallback.recovery_days = 1
    return fallback
