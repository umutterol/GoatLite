@tool
extends EditorScript



func _run():
    print("=== GENERATING STAT REFERENCE ===")

    var content = "# Stat and Tag Reference\n"
    content += "*Generated: " + Time.get_datetime_string_from_system() + "*\n\n"


    content += "## Available Stats (for stat_id)\n\n"
    content += _generate_stats_table()


    content += "\n## Damage Categories\n\n"
    content += "`damage` and `elemental_damage` are **composite stats** — they have no property on `ExileStats`. "
    content += "When a passive/trait/affix authors against them with INCREASED/REDUCED/MORE/LESS scaling, "
    content += "`StatCalculator._apply_percentage_to_stat` fans the modifier out to the underlying damage types listed below. "
    content += "FLAT bonuses on composites are not supported — author per-type instead (e.g. `physical_damage` FLAT).\n\n"
    content += "| Category | Affects | Usage |\n"
    content += "|----------|---------|-------|\n"
    content += "| `damage` | Physical, Fire, Cold, Lightning, Chaos | Global damage modifiers (composite fan-out) |\n"
    content += "| `elemental_damage` | Fire, Cold, Lightning | Elemental-only modifiers (composite fan-out) |\n"
    content += "| `physical_damage` | Physical only | Physical-specific modifiers |\n\n"


    content += "## Scaling Types\n\n"
    content += "| Type | Value | Effect | Stacking |\n"
    content += "|------|-------|--------|----------|\n"
    content += "| FLAT | 0 | Direct addition/subtraction | Additive |\n"
    content += "| INCREASED | 1 | Percentage increase | Additive with other increased/reduced |\n"
    content += "| MORE | 2 | Percentage multiplier | Multiplicative with other more/less |\n"
    content += "| REDUCED | 3 | Percentage decrease | Additive with increased |\n"
    content += "| LESS | 4 | Percentage divisor | Multiplicative with more |\n\n"


    var tags = _get_all_existing_tags()

    content += "## Existing Tags\n\n"
    content += _generate_tags_table(tags)


    content += "\n## Passive Statistics\n\n"
    content += _generate_passive_stats()


    var file = FileAccess.open("res://STAT_REFERENCE.md", FileAccess.WRITE)
    file.store_string(content)
    file.close()

    print("Reference saved to: res://STAT_REFERENCE.md")
    OS.shell_open(ProjectSettings.globalize_path("res://STAT_REFERENCE.md"))

func _generate_stats_table() -> String:
    var test_stats = ExileStats.new()
    var properties = test_stats.get_property_list()

    var ignored_props = ["resource_local_to_scene", "resource_name", "current_life", 
                        "max_life", "resource_path", "script", "damage_modifiers"]

    var stats_data = []

    for prop in properties:
        if prop.name in ignored_props:
            continue

        if prop.type == TYPE_FLOAT:
            var default_val = test_stats.get(prop.name)
            var type_str = "float"
            stats_data.append({
                "name": prop.name, 
                "type": type_str, 
                "default": str(default_val), 
                "category": _categorize_stat(prop.name)
            })
        elif prop.type == TYPE_VECTOR2:
            var default_val = test_stats.get(prop.name)
            var type_str = "Vector2"
            stats_data.append({
                "name": prop.name, 
                "type": type_str, 
                "default": "(%d, %d)" % [default_val.x, default_val.y], 
                "category": _categorize_stat(prop.name)
            })


    stats_data.sort_custom( func(a, b):
        if a.category != b.category:
            return a.category < b.category
        return a.name < b.name
    )


    var table = "| Stat ID | Default | Stat ID | Default |\n"
    table += "|---------|---------|---------|--------|\n"

    var i = 0
    while i < stats_data.size():
        var stat1 = stats_data[i]
        var cell1 = "`%s` | %s" % [stat1.name, stat1.default]

        if i + 1 < stats_data.size():
            var stat2 = stats_data[i + 1]
            var cell2 = "`%s` | %s" % [stat2.name, stat2.default]
            table += "| %s | %s |\n" % [cell1, cell2]
        else:
            table += "| %s | | |\n" % [cell1]

        i += 2

    return table

func _categorize_stat(stat_name: String) -> String:
    if stat_name.ends_with("_damage"):
        return "damage"
    elif stat_name.ends_with("_resistance") or stat_name.ends_with("_resistance_cap"):
        return "resistance"
    elif stat_name in ["life", "vitality", "morale", "max_morale"]:
        return "core"
    elif stat_name in ["armour", "block_chance", "block_amount", "evasion", "endurance", "endurance_threshold"]:
        return "defence"
    elif stat_name in ["life_regen", "life_leech", "life_gain_on_hit", "second_wind_chance", "second_wind_amount", "second_wind_threshold"]:
        return "recovery"
    elif stat_name in ["critical_chance", "critical_multiplier", "attack_speed"]:
        return "combat"
    elif stat_name in ["movement", "scouting", "survival", "scavenging"]:
        return "utility"
    elif stat_name.begins_with("morale_") or stat_name.ends_with("_morale_bonus"):
        return "morale"
    else:
        return "other"

func _generate_tags_table(tags: Dictionary) -> String:
    var table = "| Type | Tags |\n"
    table += "|------|------|\n"


    var all_tags = []
    for tag in tags["stat_tags"]:
        all_tags.append({"tag": tag, "type": "Stat"})
    for tag in tags["theme_tags"]:
        all_tags.append({"tag": tag, "type": "Theme"})
    for tag in tags["category_tags"]:
        all_tags.append({"tag": tag, "type": "Category"})


    var grouped = {}
    for tag_data in all_tags:
        if not grouped.has(tag_data.type):
            grouped[tag_data.type] = []
        grouped[tag_data.type].append("`" + tag_data.tag + "`")


    for type in ["Stat", "Theme", "Category"]:
        if grouped.has(type):
            var tags_str = ", ".join(grouped[type])
            table += "| **%s** | %s |\n" % [type, tags_str]

    return table

func _generate_passive_stats() -> String:
    var passive_files = []
    _scan_directory("res://systems/exile/passives/definitions/", passive_files, ".tres")

    var stats = {
        "total": 0, 
        "by_type": {}, 
        "by_rarity": {}, 
        "damage_passives": []
    }

    for file_path in passive_files:
        var resource = load(file_path)
        if resource and resource is PassiveDefinition:
            stats.total += 1


            var type_name = ["Passive", "Notable", "Keystone"][resource.passive_type]
            stats.by_type[type_name] = stats.by_type.get(type_name, 0) + 1


            var rarity_name = ["Common", "Uncommon", "Rare", "Legendary"][resource.rarity]
            stats.by_rarity[rarity_name] = stats.by_rarity.get(rarity_name, 0) + 1


            for bonus in resource.stat_bonuses:
                if bonus.stat_id.ends_with("_damage") or bonus.stat_id == "damage" or bonus.stat_id == "elemental_damage":
                    stats.damage_passives.append(resource.passive_id)
                    break

    var content = "| Metric | Count | Details |\n"
    content += "|--------|-------|--------|\n"
    content += "| **Total Passives** | %d | |\n" % stats.total


    var type_details = []
    for type in ["Passive", "Notable", "Keystone"]:
        if stats.by_type.has(type):
            type_details.append("%s: %d" % [type, stats.by_type[type]])
    content += "| **By Type** | | %s |\n" % ", ".join(type_details)


    var rarity_details = []
    for rarity in ["Common", "Uncommon", "Rare", "Legendary"]:
        if stats.by_rarity.has(rarity):
            rarity_details.append("%s: %d" % [rarity, stats.by_rarity[rarity]])
    content += "| **By Rarity** | | %s |\n" % ", ".join(rarity_details)


    content += "| **Damage Modifiers** | %d | %s |\n" % [stats.damage_passives.size(), ", ".join(stats.damage_passives)]

    return content

func _get_all_existing_tags() -> Dictionary:
    var result = {
        "stat_tags": [], 
        "theme_tags": [], 
        "category_tags": []
    }

    var tag_sets = {
        "stat_tags": {}, 
        "theme_tags": {}, 
        "category_tags": {}
    }


    var passive_files = []
    _scan_directory("res://systems/exile/passives/definitions/", passive_files, ".tres")

    for file_path in passive_files:
        var resource = load(file_path)
        if resource and resource is PassiveDefinition:
            for tag in resource.stat_tags:
                tag_sets["stat_tags"][tag] = true
            for tag in resource.theme_tags:
                tag_sets["theme_tags"][tag] = true
            for tag in resource.category_tags:
                tag_sets["category_tags"][tag] = true


    for key in tag_sets:
        result[key] = tag_sets[key].keys()
        result[key].sort()

    return result

func _scan_directory(path: String, file_list: Array, extension: String):
    var dir = DirAccess.open(path)
    if not dir:
        return

    dir.list_dir_begin()
    var file_name = dir.get_next()

    while file_name != "":
        var full_path = path + "/" + file_name

        if dir.current_is_dir() and file_name != "." and file_name != "..":
            _scan_directory(full_path, file_list, extension)
        elif file_name.ends_with(extension):
            file_list.append(full_path)

        file_name = dir.get_next()
