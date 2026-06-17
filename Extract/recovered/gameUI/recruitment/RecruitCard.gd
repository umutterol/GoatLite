













class_name RecruitCard
extends PanelContainer

const TRAIT_CARD_SCENE: PackedScene = preload("res://gameUI/guild/characterSheet/TraitCardPanel.tscn")
const POTENTIAL_CARD_SCENE: PackedScene = preload("res://gameUI/guild/characterSheet/PotentialCardPanel.tscn")
const FLOATING_TOOLTIP_SCENE: PackedScene = preload("res://gameUI/tooltips/NonKeywordTooltipPanel.tscn")

@onready var portrait_slot: ExilePortraitSlot = $Layout / HeaderRow / PortraitPanel
@onready var name_label: Label = $Layout / HeaderRow / NameClassVBox / NameLabel
@onready var class_name_label: Label = $Layout / HeaderRow / NameClassVBox / ClassLevelRow / ClassNameLabel
@onready var level_label: Label = $Layout / HeaderRow / NameClassVBox / ClassLevelRow / LevelLabel
@onready var traits_list: GridContainer = $Layout / TraitsSection / TraitsList
@onready var potentials_grid: GridContainer = $Layout / PotentialsSection / PotentialsGrid

var _exile_data: ExileData
var _floating_tooltip: NonKeywordTooltipPanel


func _ready() -> void :




    var tooltip_layer: = CanvasLayer.new()
    tooltip_layer.layer = 100
    add_child(tooltip_layer)
    _floating_tooltip = FLOATING_TOOLTIP_SCENE.instantiate()
    tooltip_layer.add_child(_floating_tooltip)

    class_name_label.mouse_entered.connect(_on_class_name_hover)
    class_name_label.mouse_exited.connect(_on_class_name_unhover)



    portrait_slot.mouse_filter = Control.MOUSE_FILTER_PASS
    portrait_slot.mouse_entered.connect(_on_class_name_hover)
    portrait_slot.mouse_exited.connect(_on_class_name_unhover)



func bind(exile_data: ExileData) -> void :
    _exile_data = exile_data
    if exile_data == null:
        return

    _populate_header(exile_data)
    _populate_traits(exile_data)
    _populate_potentials(exile_data)




func _populate_header(exile_data: ExileData) -> void :
    name_label.text = exile_data.name
    portrait_slot.paint_exile(exile_data)

    var class_def: = exile_data.class_definition
    if class_def != null:
        class_name_label.text = class_def.name
        class_name_label.modulate = RarityColors.get_color(class_def.rarity)
    else:
        class_name_label.text = exile_data.class_id
        class_name_label.modulate = Color.WHITE

    level_label.text = "Level %d" % exile_data.level


func _populate_traits(exile_data: ExileData) -> void :
    for child in traits_list.get_children():
        child.queue_free()

    if exile_data.traits.is_empty():
        var empty: = Label.new()
        empty.text = "(no traits)"
        empty.modulate = Color(0.6, 0.6, 0.6)
        traits_list.add_child(empty)
        return

    for trait_id in exile_data.traits:
        var trait_def: TraitDefinition = TraitLibrary.get_trait_by_id(trait_id)
        if trait_def == null:
            continue
        var card: TraitCardPanel = TRAIT_CARD_SCENE.instantiate()
        traits_list.add_child(card)
        card.bind(trait_def)
        card.trait_hovered.connect(_on_trait_hovered)
        card.trait_unhovered.connect(_on_trait_unhovered)


func _populate_potentials(exile_data: ExileData) -> void :
    for child in potentials_grid.get_children():
        child.queue_free()

    if exile_data.potential == null:
        return






    var hidden_count: = 0
    for entry in exile_data.potential.get_display_entries():
        if entry.is_hidden:
            hidden_count += 1
            continue
        var card: PotentialCardPanel = POTENTIAL_CARD_SCENE.instantiate()
        potentials_grid.add_child(card)
        card.bind(entry)
        _shrink_potential_card(card)

    if hidden_count > 0:
        var unknown_card: PotentialCardPanel = POTENTIAL_CARD_SCENE.instantiate()
        potentials_grid.add_child(unknown_card)


        _apply_collapsed_unknown_label(unknown_card, hidden_count)
        _shrink_potential_card(unknown_card)





func _shrink_potential_card(card: PotentialCardPanel) -> void :
    await card.ready
    if not is_instance_valid(card):
        return
    card.custom_minimum_size = Vector2(82, 30)
    card.value_label.add_theme_font_size_override("font_size", 14)
    card.tag_label.add_theme_font_size_override("font_size", 11)








func _apply_collapsed_unknown_label(card: PotentialCardPanel, count: int) -> void :
    if not is_instance_valid(card):
        return
    card.value_label.text = "+%d" % count
    card.tag_label.text = "Unknown"
    card.tooltip_hover.keyword = "potential_unknown"
    card.modulate = Color(0.7, 0.7, 0.75)




func _on_class_name_hover() -> void :
    if _exile_data == null or _exile_data.class_definition == null:
        return
    var bbcode: = _build_class_bbcode(_exile_data.class_definition)
    _floating_tooltip.show_breakdown(bbcode, get_global_mouse_position())


func _on_class_name_unhover() -> void :
    _floating_tooltip.hide_tooltip()




func _on_trait_hovered(trait_def: TraitDefinition) -> void :
    if trait_def == null:
        return
    var bbcode: = _build_trait_bbcode(trait_def)
    _floating_tooltip.show_breakdown(bbcode, get_global_mouse_position())


func _on_trait_unhovered() -> void :
    _floating_tooltip.hide_tooltip()











func _build_class_bbcode(class_def: ClassDefinition) -> String:
    var rarity_hex: = RarityColors.get_hex(class_def.rarity)
    var rarity_name: = RarityColors.get_rarity_name(class_def.rarity)

    var lines: Array[String] = []
    lines.append("[code]%s[/code]" % class_def.name)
    lines.append("[color=%s]%s Class[/color]" % [rarity_hex, rarity_name])

    if class_def.description != "":
        lines.append("")
        lines.append(class_def.description)




    lines.append("")
    lines.append(_format_class_base_stats(class_def))

    var starting_lines: = _build_class_override_lines(class_def)
    if not starting_lines.is_empty():
        lines.append("")
        lines.append("[b]Starting Bonuses[/b]")
        lines.append_array(starting_lines)

    var growth_section: = _format_class_growth(class_def)
    if growth_section != "":
        lines.append("")
        lines.append("[b]Per Level[/b]")
        lines.append(growth_section)

    if not class_def.conditional_bonuses.is_empty():
        lines.append("")
        lines.append("[b]Conditional Bonuses[/b]")
        for conditional in class_def.conditional_bonuses:
            if conditional == null:
                continue
            lines.append("  %s" % conditional.get_display_text(1))

    if not class_def.special_effects.is_empty():
        lines.append("")
        lines.append("[b]Special Effects[/b]")
        for effect in class_def.special_effects:
            lines.append("  %s" % effect.capitalize().replace("_", " "))

    return "\n".join(lines)


func _format_class_base_stats(class_def: ClassDefinition) -> String:

    var life: float = class_def.override_life if class_def.override_life >= 0 else 100.0
    var vitality: float = class_def.override_vitality if class_def.override_vitality >= 0 else 100.0
    var morale: float = class_def.override_morale if class_def.override_morale >= 0 else 100.0
    return "[b]Base Life:[/b] %d   [b]Vitality:[/b] %d   [b]Morale:[/b] %d" % [
        int(round(life)), int(round(vitality)), int(round(morale))
    ]







func _build_class_override_lines(class_def: ClassDefinition) -> Array[String]:
    var lines: Array[String] = []
    if class_def.override_life >= 0.0 and class_def.override_life != 100.0:
        lines.append("  Life: %.0f" % class_def.override_life)
    if class_def.override_vitality >= 0.0 and class_def.override_vitality != 100.0:
        lines.append("  Vitality: %.0f" % class_def.override_vitality)
    if class_def.override_morale >= 0.0 and class_def.override_morale != 100.0:
        lines.append("  Morale: %.0f" % class_def.override_morale)
    if class_def.override_evasion >= 0.0 and class_def.override_evasion != 10.0:
        lines.append("  Evasion: %s" % _fmt_num(class_def.override_evasion))
    if class_def.override_block_chance >= 0.0 and class_def.override_block_chance != 0.0:
        lines.append("  Block Chance: %.0f%%" % class_def.override_block_chance)
    if class_def.override_critical_multiplier >= 0.0 and class_def.override_critical_multiplier != 150.0:
        lines.append("  Crit Multi: %.0f%%" % class_def.override_critical_multiplier)
    if class_def.override_life_regen >= 0.0 and class_def.override_life_regen != 0.0:
        lines.append("  Life Regen: %s / sec" % _fmt_num(class_def.override_life_regen))
    if class_def.override_fire_resistance >= 0.0 and class_def.override_fire_resistance != 0.0:
        lines.append("  Fire Resistance: %+.0f%%" % class_def.override_fire_resistance)
    if class_def.override_cold_resistance >= 0.0 and class_def.override_cold_resistance != 0.0:
        lines.append("  Cold Resistance: %+.0f%%" % class_def.override_cold_resistance)
    if class_def.override_lightning_resistance >= 0.0 and class_def.override_lightning_resistance != 0.0:
        lines.append("  Lightning Resistance: %+.0f%%" % class_def.override_lightning_resistance)
    if class_def.override_chaos_resistance >= 0.0 and class_def.override_chaos_resistance != 0.0:
        lines.append("  Chaos Resistance: %+.0f%%" % class_def.override_chaos_resistance)
    if class_def.override_survival >= 0.0 and class_def.override_survival != 0.0:
        lines.append("  Survival: %s%%" % _fmt_signed(class_def.override_survival))
    if class_def.override_scouting >= 0.0 and class_def.override_scouting != 0.0:
        lines.append("  Scouting: %s%%" % _fmt_signed(class_def.override_scouting))
    if class_def.override_scavenging >= 0.0 and class_def.override_scavenging != 0.0:
        lines.append("  Scavenging: %s%%" % _fmt_signed(class_def.override_scavenging))
    if class_def.override_movement >= 0.0 and class_def.override_movement != 0.0:
        lines.append("  Movement Speed: %+.0f%%" % class_def.override_movement)
    return lines


func _format_class_growth(class_def: ClassDefinition) -> String:
    var lines: Array[String] = []
    lines.append("  [b]Life:[/b] +%.0f   [b]Vitality:[/b] +%.0f" % [
        class_def.life_per_level, class_def.vitality_per_level
    ])

    for i in range(class_def.growth_stat_ids.size()):
        var stat_id: String = class_def.growth_stat_ids[i]
        var value: float = class_def.growth_stat_values[i] if i < class_def.growth_stat_values.size() else 0.0
        var prefix: = "+" if value > 0 else ""
        lines.append("  [b]%s:[/b] %s%s" % [_format_stat_name(stat_id), prefix, str(value)])

    for i in range(class_def.percent_stat_ids.size()):
        var stat_id: String = class_def.percent_stat_ids[i]
        var value: float = class_def.percent_stat_values[i] if i < class_def.percent_stat_values.size() else 0.0
        var prefix: = "+" if value > 0 else ""
        lines.append("  [b]%s:[/b] %s%s%%" % [_format_stat_name(stat_id), prefix, str(value)])

    return "\n".join(lines)


func _build_trait_bbcode(trait_def: TraitDefinition) -> String:

    var rarity_hex: = RarityColors.get_hex(trait_def.rarity)
    var rarity_name: = RarityColors.get_rarity_name(trait_def.rarity)
    var category_name: = _trait_category_name(trait_def.category)

    var lines: Array[String] = []
    lines.append("[code]%s[/code]" % trait_def.name)
    lines.append("[color=%s]%s[/color]  [color=gray]· %s[/color]" % [rarity_hex, rarity_name, category_name])
    lines.append("")
    lines.append(trait_def.get_full_description())
    return "\n".join(lines)




static func _format_stat_name(stat_id: String) -> String:
    return stat_id.capitalize().replace("_", " ")





static func _fmt_num(value: float, max_decimals: int = 1) -> String:
    var factor: float = pow(10.0, max_decimals)
    var rounded: float = round(value * factor) / factor
    if absf(rounded - round(rounded)) < (0.5 / factor):
        return "%d" % int(round(rounded))
    var format_str: String = "%." + str(max_decimals) + "f"
    var result: String = format_str % rounded
    if "." in result:
        result = result.rstrip("0").rstrip(".")
    return result



static func _fmt_signed(value: float, max_decimals: int = 1) -> String:
    var body: String = _fmt_num(value, max_decimals)
    if body.begins_with("-"):
        return body
    return "+" + body


static func _trait_category_name(category: int) -> String:
    match category:
        TraitDefinition.TraitCategory.BACKGROUND: return "Background"
        TraitDefinition.TraitCategory.LEARNED: return "Learned"
        TraitDefinition.TraitCategory.SCAR: return "Scar"
        _: return "?"
