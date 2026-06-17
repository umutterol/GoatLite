class_name PassiveSelectionManager
extends RefCounted

static func generate_passive_choices(exile_data: ExileData) -> Array[PassiveDefinition]:
    var available_passives = get_available_passives(exile_data)
    var choices: Array[PassiveDefinition] = []


    var num_choices = GameSettings.PASSIVE_CHOICES_PER_LEVEL

    for i in range(num_choices):

        var selected
        if exile_data.potential:
            selected = growth_weighted_selection(available_passives, exile_data)
        else:

            selected = weighted_random_selection(available_passives)

        if selected:
            choices.append(selected)
            available_passives.erase(selected)

    return choices






static func generate_initiator_choices(exile_data: ExileData) -> Array[PassiveDefinition]:
    var pool: Array[PassiveDefinition] = []
    for passive in get_available_passives(exile_data):
        if passive.passive_type == PassiveDefinition.PassiveType.PASSIVE:
            pool.append(passive)

    var choices: Array[PassiveDefinition] = []
    var num_choices: int = GameSettings.PASSIVE_CHOICES_PER_LEVEL
    for i in range(num_choices):
        var selected
        if exile_data.potential:
            selected = growth_weighted_selection(pool, exile_data)
        else:
            selected = weighted_random_selection(pool)
        if selected:
            choices.append(selected)
            pool.erase(selected)
    return choices


static func growth_weighted_selection(passives: Array[PassiveDefinition], exile_data: ExileData) -> PassiveDefinition:
    if passives.is_empty():
        return null

    var total_weight = 0.0
    var weighted_passives = []


    for passive in passives:
        var base_weight = passive.get_drop_weight()
        var potential_modifier = exile_data.get_passive_weight_modifier(passive)
        var final_weight = base_weight * potential_modifier

        weighted_passives.append({
            "passive": passive, 
            "weight": final_weight
        })
        total_weight += final_weight


    var random_value = randf() * total_weight
    var current_weight = 0.0

    for wp in weighted_passives:
        current_weight += wp.weight
        if random_value <= current_weight:
            return wp.passive

    return weighted_passives[0].passive

static func get_available_passives(exile_data: ExileData) -> Array[PassiveDefinition]:
    var all_passives = PassiveLibrary.get_all_passives()
    var available: Array[PassiveDefinition] = []

    for passive in all_passives:
        if can_exile_take_passive(exile_data, passive):
            available.append(passive)

    return available

static func can_exile_take_passive(exile_data: ExileData, passive: PassiveDefinition) -> bool:

    if exile_data.level < passive.min_level:
        return false


    if passive.class_restricted.size() > 0:
        if not passive.class_restricted.has(exile_data.get_class_name()):
            return false


    var current_stacks = exile_data.get_passive_stacks(passive.passive_id)
    if current_stacks >= passive.max_stacks:
        return false


    for prereq_id in passive.requires_previous:
        if not exile_data.has_passive(prereq_id):
            return false


    for i in range(passive.required_passive_ids.size()):
        if i >= passive.required_stack_counts.size():
            break

        var passive_id = passive.required_passive_ids[i]
        var required_count = passive.required_stack_counts[i]
        var actual_stacks = exile_data.get_passive_stacks(passive_id)

        if actual_stacks < required_count:
            return false


    for exclusive_id in passive.mutually_exclusive:
        if exile_data.has_passive(exclusive_id):
            return false

    return true

static func weighted_random_selection(passives: Array[PassiveDefinition]) -> PassiveDefinition:
    if passives.is_empty():
        return null

    var total_weight = 0.0
    for passive in passives:
        total_weight += passive.get_drop_weight()

    var random_value = randf() * total_weight
    var current_weight = 0.0

    for passive in passives:
        current_weight += passive.get_drop_weight()
        if random_value <= current_weight:
            return passive

    return passives[0]
