class_name Item
extends Resource


@export var unique_id: String = ""


@export var base_item: ItemBase


@export var item_level: int = 1


@export var stash_tab: int = 0
@export var stash_position: Vector2i = Vector2i(-1, -1)




enum Rarity{
    COMMON, 
    UNCOMMON, 
    RARE, 
    UNIQUE, 


}
@export var rarity: Rarity = Rarity.COMMON


@export var rolled_stats: Dictionary = {}


@export var prefix_affixes: Array = []
@export var suffix_affixes: Array = []
@export var implicit_affixes: Array = []






@export var is_corrupted: bool = false


@export var generated_timestamp: int = 0
@export var source_tags: Array = []


func _init(p_base_item: ItemBase = null, p_item_level: int = 1):
    if p_base_item:
        base_item = p_base_item
        item_level = p_item_level
        unique_id = _generate_unique_id()
        generated_timestamp = int(Time.get_unix_time_from_system())


func _generate_unique_id() -> String:
    var time_str = str(Time.get_unix_time_from_system())
    var random_str = str(randi() % 100000)
    return base_item.item_id + "_" + time_str + "_" + random_str


func get_affix_count() -> int:
    return prefix_affixes.size() + suffix_affixes.size()


func update_rarity():
    var total_affixes = get_affix_count()
    if total_affixes == 0:
        rarity = Rarity.COMMON
    elif total_affixes <= 2:
        rarity = Rarity.UNCOMMON
    else:
        rarity = Rarity.RARE


func get_display_name() -> String:
    match rarity:
        Rarity.UNIQUE:



            return "Unique " + base_item.display_name
        Rarity.RARE:
            return "Rare " + base_item.display_name
        Rarity.UNCOMMON:
            return "Uncommon " + base_item.display_name
        _:
            return base_item.display_name


func get_stat(stat_name: String) -> Variant:
    return rolled_stats.get(stat_name, 0)


func get_total_stat(stat_type: String) -> float:
    var total = 0.0


    if rolled_stats.has(stat_type):
        total += rolled_stats[stat_type]


    for affix in implicit_affixes + prefix_affixes + suffix_affixes:
        if affix.affix_base.stat_type == stat_type:
            total += affix.get_value()

    return total




func is_craftable() -> bool:
    return not is_corrupted



func has_affix(affix_id: String) -> bool:
    for affix in implicit_affixes + prefix_affixes + suffix_affixes:
        if affix.affix_base.affix_id == affix_id:
            return true
    return false


func get_all_affixes() -> Array:
    return implicit_affixes + prefix_affixes + suffix_affixes










func get_local_stat_total(stat_id: String) -> float:
    var base_value: float = float(rolled_stats.get(stat_id, 0))
    var local_flat: float = 0.0
    var local_increased: float = 0.0
    var local_reduced: float = 0.0

    for affix_instance in get_all_affixes():
        var affix: AffixBase = affix_instance.affix_base
        if affix == null or not affix.is_local:
            continue
        if affix.stat_type != stat_id:
            continue
        match affix.modifier_type:
            AffixBase.ModifierType.FLAT_ADDED:
                local_flat += affix_instance.get_value()
            AffixBase.ModifierType.PERCENT_INCREASED:
                local_increased += affix_instance.get_value()
            AffixBase.ModifierType.PERCENT_REDUCED:
                local_reduced += affix_instance.get_value()

    var raw_total: float = base_value + local_flat
    var net_percent: float = local_increased - local_reduced
    return raw_total * (1.0 + net_percent / 100.0)







func get_local_damage_range(damage_type: String) -> Vector2:
    var stat_id: String = damage_type + "_damage"
    var min_key: String = damage_type + "_damage_min"
    var max_key: String = damage_type + "_damage_max"

    var base_min: float = float(rolled_stats.get(min_key, 0))
    var base_max: float = float(rolled_stats.get(max_key, 0))

    var local_flat_min: float = 0.0
    var local_flat_max: float = 0.0
    var local_increased: float = 0.0
    var local_reduced: float = 0.0

    for affix_instance in get_all_affixes():
        var affix: AffixBase = affix_instance.affix_base
        if affix == null or not affix.is_local:
            continue
        if affix.stat_type != stat_id:
            continue
        match affix.modifier_type:
            AffixBase.ModifierType.FLAT_ADDED:

                if affix_instance.rolled_value is Dictionary and affix_instance.rolled_value.has("min"):
                    local_flat_min += float(affix_instance.rolled_value.min)
                    local_flat_max += float(affix_instance.rolled_value.max)
                else:
                    var flat_val: float = affix_instance.get_value()
                    local_flat_min += flat_val
                    local_flat_max += flat_val
            AffixBase.ModifierType.PERCENT_INCREASED:
                local_increased += affix_instance.get_value()
            AffixBase.ModifierType.PERCENT_REDUCED:
                local_reduced += affix_instance.get_value()

    var multiplier: float = 1.0 + (local_increased - local_reduced) / 100.0
    var final_min: float = (base_min + local_flat_min) * multiplier
    var final_max: float = (base_max + local_flat_max) * multiplier
    return Vector2(final_min, final_max)



func has_local_affix_for(stat_id: String) -> bool:
    for affix_instance in get_all_affixes():
        var affix: AffixBase = affix_instance.affix_base
        if affix == null or not affix.is_local:
            continue
        if affix.stat_type == stat_id:
            return true
    return false


func get_debug_string() -> String:
    var lines = []
    lines.append("=== " + get_display_name() + " ===")
    lines.append("Item Level: " + str(item_level))
    lines.append("Rarity: " + Rarity.keys()[rarity])
    lines.append("Base Type: " + base_item.get_type_name())


    lines.append("\nBase Stats:")
    for stat_name in rolled_stats:
        var value = rolled_stats[stat_name]
        var display_value = str(value)


        if stat_name in ["evasion", "movement", "critical_chance", "block_chance"]:
            display_value += "%"

        lines.append("  " + stat_name + ": " + display_value)


    if implicit_affixes.size() > 0:
        lines.append("\nImplicit Affixes:")
        for affix in implicit_affixes:
            lines.append("  " + affix.get_display_text())


    if prefix_affixes.size() > 0:
        lines.append("\nPrefix Affixes:")
        for affix in prefix_affixes:
            lines.append("  " + affix.get_display_text())

    if suffix_affixes.size() > 0:
        lines.append("\nSuffix Affixes:")
        for affix in suffix_affixes:
            lines.append("  " + affix.get_display_text())

    return "\n".join(lines)
