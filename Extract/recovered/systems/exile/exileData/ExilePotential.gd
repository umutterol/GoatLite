class_name ExilePotential
extends Resource


@export var entries: Dictionary = {}


func add_exile_random_potentials():

    var all_tags = _get_all_possible_tags()

    if all_tags.size() < 3:
        push_warning("Not enough tags defined for random potentials")
        return


    all_tags.shuffle()
    var selected_tags = []


    for i in range(min(3, all_tags.size())):
        selected_tags.append(all_tags[i])


    _add_potential(all_tags[0], "Exile", snappedf(randf_range(0.5, 0.9), 0.1))
    if all_tags.size() > 1:
        _add_potential(all_tags[1], "Exile", snappedf(randf_range(0.8, 1.4), 0.1))
    if all_tags.size() > 2:
        _add_potential(all_tags[2], "Exile", snappedf(randf_range(1.1, 1.9), 0.1))

func add_class_potentials(potentials: Dictionary):
    for tag in potentials:
        var value = potentials[tag]
        _add_potential(tag, "Class", value)

func add_trait_potentials(trait_name: String, potentials: Dictionary):
    for tag in potentials:
        var value = potentials[tag]
        _add_potential(tag, trait_name, value)


func finalize_potentials():

    _apply_hidden_status()


func get_tag_weight(tag: String) -> float:
    if not entries.has(tag):
        return 1.0

    var entry: PotentialEntry = entries[tag]
    return entry.get_display_value() if not entry.is_hidden else 1.0


func get_true_tag_weight(tag: String) -> float:
    if not entries.has(tag):
        return 1.0

    var entry: PotentialEntry = entries[tag]
    return entry.total_value


















func calculate_passive_weight(passive: PassiveDefinition) -> float:
    var bonus: float = 0.0

    var all_passive_tags = passive.get_all_tags()
    if passive.primary_tag != "":
        all_passive_tags.append(passive.primary_tag)



    for tag in all_passive_tags:
        bonus += get_true_tag_weight(tag) - 1.0

    return max(1.0 + bonus, 0.0)


func try_reveal_random_potential() -> bool:
    var hidden_entries = []

    for tag in entries:
        var entry: PotentialEntry = entries[tag]
        if entry.is_hidden:
            hidden_entries.append(entry)

    if hidden_entries.is_empty():
        return false


    var chance = GameSettings.EXILE_LEVEL_UP_DISCOVERY_CHANCE / 100.0
    if randf() <= chance:
        var entry = hidden_entries.pick_random()
        entry.reveal()
        return true

    return false


func get_display_entries() -> Array[PotentialEntry]:
    var result: Array[PotentialEntry] = []

    for tag in entries:
        result.append(entries[tag])


    result.sort_custom( func(a, b): return a.get_display_value() > b.get_display_value())
    return result


func _add_potential(tag: String, source_name: String, value: float):
    if not entries.has(tag):
        entries[tag] = PotentialEntry.new(tag)

        entries[tag].total_value = 1.0

    var entry: PotentialEntry = entries[tag]
    entry.add_source(source_name, value)

func _apply_hidden_status():
    var revealed_percent = GameSettings.EXILE_REVEALED_POTENTIALS_PERCENT / 100.0
    var all_entries: Array[PotentialEntry] = []

    for tag in entries:
        all_entries.append(entries[tag])


    all_entries.shuffle()


    var reveal_count = int(all_entries.size() * revealed_percent)
    reveal_count = max(1, reveal_count)


    for i in range(all_entries.size()):
        all_entries[i].is_hidden = i >= reveal_count

func _get_all_possible_tags() -> Array[String]:
    var tags: Array[String] = []
    var tag_set = {}

    var all_passives = PassiveLibrary.get_all_passives()
    for passive in all_passives:
        for tag in passive.stat_tags:
            tag_set[tag] = true
        for tag in passive.theme_tags:
            tag_set[tag] = true
        for tag in passive.category_tags:
            tag_set[tag] = true
        if passive.primary_tag != "":
            tag_set[passive.primary_tag] = true

    tags.assign(tag_set.keys())
    return tags
