
















class_name CharacterSheet
extends Panel

const TRAIT_CARD_SCENE: PackedScene = preload("res://gameUI/guild/characterSheet/TraitCardPanel.tscn")
const POTENTIAL_CARD_SCENE: PackedScene = preload("res://gameUI/guild/characterSheet/PotentialCardPanel.tscn")
const FLOATING_TOOLTIP_SCENE: PackedScene = preload("res://gameUI/tooltips/NonKeywordTooltipPanel.tscn")
const PORTRAIT_LEVEL_UP_BADGE_SCENE: PackedScene = preload("res://gameUI/levelUp/PortraitLevelUpBadge.tscn")
const MESSAGE_MODAL_SCENE: PackedScene = preload("res://gameUI/smallComponents/MessageModal.tscn")


@onready var portrait_panel: Panel = $MarginContainer / Layout / Header / PortraitPanel
@onready var class_icon: TextureRect = $MarginContainer / Layout / Header / PortraitPanel / ClassIcon
@onready var class_fallback_label: Label = $MarginContainer / Layout / Header / PortraitPanel / FallbackLabel
@onready var name_label: Label = $MarginContainer / Layout / Header / HeaderInfo / NameRow / NameLabel
@onready var name_edit: LineEdit = $MarginContainer / Layout / Header / HeaderInfo / NameRow / NameEdit
@onready var edit_name_button: Button = $MarginContainer / Layout / Header / HeaderInfo / NameRow / EditNameButton
@onready var confirm_name_button: Button = $MarginContainer / Layout / Header / HeaderInfo / NameRow / ConfirmNameButton
@onready var dismiss_button: PanelButton = $MarginContainer / Layout / Header / HeaderInfo / NameRow / DismissButton
@onready var class_level_label: Label = $MarginContainer / Layout / Header / HeaderInfo / ClassLevelLabel
@onready var status_icons_grid: GridContainer = $MarginContainer / Layout / Header / StatusIconsGrid
@onready var recovery_icon: PanelContainer = %RecoveryIcon
@onready var starving_icon: StarvingIcon = %StarvingIcon
@onready var high_morale_icon: MoraleStateIcon = %HighMoraleIcon
@onready var low_morale_icon: MoraleStateIcon = %LowMoraleIcon
@onready var close_button = $MarginContainer / Layout / Header / CloseButton


@onready var xp_bar: ProgressBar = $MarginContainer / Layout / XPBar
@onready var xp_value_label: Label = $MarginContainer / Layout / XPBar / XPValueLabel
@onready var life_bar: ProgressBar = $MarginContainer / Layout / LifeBar
@onready var life_value_label: Label = $MarginContainer / Layout / LifeBar / LifeValueLabel
@onready var vitality_bar: ProgressBar = $MarginContainer / Layout / BarsGrid / VitalityBar
@onready var vitality_value_label: Label = $MarginContainer / Layout / BarsGrid / VitalityBar / VitalityValueLabel
@onready var morale_bar: ProgressBar = $MarginContainer / Layout / BarsGrid / MoraleBar
@onready var morale_value_label: Label = $MarginContainer / Layout / BarsGrid / MoraleBar / MoraleValueLabel


@onready var armour_value: Label = $MarginContainer / Layout / DefenceTiles / ArmourTile / VBox / ValueLabel
@onready var evasion_value: Label = $MarginContainer / Layout / DefenceTiles / EvasionTile / VBox / ValueLabel
@onready var energy_shield_value: Label = $MarginContainer / Layout / DefenceTiles / EnergyShieldTile / VBox / ValueLabel
@onready var block_value: Label = $MarginContainer / Layout / DefenceTiles / BlockTile / VBox / ValueLabel
@onready var endurance_value: Label = $MarginContainer / Layout / DefenceTiles / EnduranceTile / VBox / ValueLabel


@onready var fire_res_value: Label = $MarginContainer / Layout / ResistGrid / FireRes / VBox / FireResValue
@onready var cold_res_value: Label = $MarginContainer / Layout / ResistGrid / ColdRes / VBox / ColdResValue
@onready var light_res_value: Label = $MarginContainer / Layout / ResistGrid / LightRes / VBox / LightResValue
@onready var chaos_res_value: Label = $MarginContainer / Layout / ResistGrid / ChaosRes / VBox / ChaosResValue


@onready var dps_tile: PanelContainer = $MarginContainer / Layout / OffenceTiles / DpsTile
@onready var dps_value_label: Label = $MarginContainer / Layout / OffenceTiles / DpsTile / VBox / ValueLabel
@onready var hit_tile: PanelContainer = $MarginContainer / Layout / OffenceTiles / HitTile
@onready var hit_value_label: Label = $MarginContainer / Layout / OffenceTiles / HitTile / VBox / ValueLabel
@onready var attack_speed_value_label: Label = $MarginContainer / Layout / OffenceTiles / AttackSpeedTile / VBox / ValueLabel
@onready var crit_value_label: Label = $MarginContainer / Layout / OffenceTiles / CritTile / VBox / ValueLabel


@onready var life_regen_value_label: Label = $MarginContainer / Layout / RecoveryTiles / LifeRegenTile / VBox / ValueLabel
@onready var life_gain_value_label: Label = $MarginContainer / Layout / RecoveryTiles / LifeGainTile / VBox / ValueLabel
@onready var life_leech_value_label: Label = $MarginContainer / Layout / RecoveryTiles / LifeLeechTile / VBox / ValueLabel
@onready var second_wind_value_label: Label = $MarginContainer / Layout / RecoveryTiles / SecondWindTile / VBox / ValueLabel


@onready var tab_container: TabContainer = $MarginContainer / Layout / TabContainer
@onready var traits_grid: HFlowContainer = $MarginContainer / Layout / TabContainer / Traits / TraitsBody / TraitsGridMargin / TraitsGrid
@onready var traits_empty_label: Label = $MarginContainer / Layout / TabContainer / Traits / TraitsBody / TraitsEmptyLabel
@onready var potential_grid: GridContainer = $MarginContainer / Layout / TabContainer / Traits / TraitsBody / PotentialGrid
@onready var scaling_body: VBoxContainer = $MarginContainer / Layout / TabContainer / Scaling / ScalingMargin / ScalingBody
@onready var ailment_body: VBoxContainer = $MarginContainer / Layout / TabContainer / Ailment / AilmentMargin / AilmentBody
@onready var other_body: VBoxContainer = $MarginContainer / Layout / TabContainer / Other / OtherMargin / OtherBody





@onready var morale_effects_body: VBoxContainer = $MarginContainer / Layout / TabContainer / Morale / TopSection / TopLeft / LeftBody / EffectsBody
@onready var morale_effects_empty: Label = $MarginContainer / Layout / TabContainer / Morale / TopSection / TopLeft / LeftBody / EffectsBody / NoEffectsLabel
@onready var morale_modifiers_body: VBoxContainer = $MarginContainer / Layout / TabContainer / Morale / TopSection / TopRight / RightBody
@onready var morale_history_grid: GridContainer = $MarginContainer / Layout / TabContainer / Morale / BottomSection / BottomBody / HistoryGrid
@onready var morale_history_empty: Label = $MarginContainer / Layout / TabContainer / Morale / BottomSection / BottomBody / HistoryEmptyLabel

var exile_data: ExileData = null
var _floating_tooltip: NonKeywordTooltipPanel = null
var _level_up_badge: PortraitLevelUpBadge = null


var _is_editing_name: bool = false


func _ready() -> void :
    close_button.pressed.connect(_close)
    GameState.exile_updated.connect(_on_exile_updated)



    edit_name_button.pressed.connect(_begin_name_edit)
    confirm_name_button.pressed.connect(_commit_name_edit)
    name_edit.text_submitted.connect(_on_name_edit_submitted)
    dismiss_button.pressed.connect(_on_dismiss_pressed)


    _floating_tooltip = FLOATING_TOOLTIP_SCENE.instantiate()
    add_child(_floating_tooltip)
    _floating_tooltip.z_index = 200


    dps_tile.mouse_entered.connect(_on_offence_tile_hover)
    dps_tile.mouse_exited.connect(_on_offence_tile_unhover)
    hit_tile.mouse_entered.connect(_on_offence_tile_hover)
    hit_tile.mouse_exited.connect(_on_offence_tile_unhover)



    portrait_panel.mouse_entered.connect(_on_class_hover)
    portrait_panel.mouse_exited.connect(_on_class_unhover)
    class_level_label.mouse_entered.connect(_on_class_hover)
    class_level_label.mouse_exited.connect(_on_class_unhover)





    _level_up_badge = PORTRAIT_LEVEL_UP_BADGE_SCENE.instantiate()
    portrait_panel.add_child(_level_up_badge)
    _level_up_badge.clicked.connect(_on_level_up_badge_clicked)


    tab_container.current_tab = 0
    hide()


func populate(data: ExileData) -> void :
    exile_data = data
    var stats: ExileStats = data.current_stats

    _populate_header(data)
    _populate_status_icons(data)
    _populate_bars(data, stats)
    _populate_defence(stats)
    _populate_resistances(stats)
    _populate_offence(stats)
    _populate_recovery(stats)
    _populate_traits_tab(data)
    _populate_scaling_tab(data)
    _populate_ailment_tab(stats)
    _populate_other_tab(stats)
    _populate_morale_tab(data, stats)
    if _level_up_badge != null:
        _level_up_badge.set_exile(data)

    show()




func _populate_header(data: ExileData) -> void :
    name_label.text = data.name




    _set_name_edit_visible(false)
    var class_text: String = data.class_definition.name if data.class_definition else data.class_id
    class_level_label.text = "%s  -  Level %d" % [class_text, data.level]




    var icon_texture: Texture2D = data.class_definition.icon if data.class_definition else null
    if icon_texture != null:
        class_icon.texture = icon_texture
        class_icon.visible = true
        class_fallback_label.visible = false
    else:
        class_icon.texture = null
        class_icon.visible = false
        class_fallback_label.visible = true


func _populate_status_icons(data: ExileData) -> void :



    recovery_icon.visible = data.status == "recovering"
    starving_icon.bind(data)
    high_morale_icon.bind(data)
    low_morale_icon.bind(data)


func _populate_bars(data: ExileData, stats: ExileStats) -> void :
    var exp_to_next: int = data.get_exp_for_next_level()
    xp_bar.max_value = exp_to_next
    xp_bar.value = data.experience
    xp_value_label.text = "%d / %d xp" % [data.experience, exp_to_next]




    var life_display: float = min(data.current_life, stats.life)
    var vit_display: float = min(data.current_vitality, stats.max_vitality)
    var morale_display: float = min(stats.morale, stats.max_morale)
    life_bar.max_value = stats.life
    life_bar.value = life_display
    life_value_label.text = "%d / %d Life" % [int(round(life_display)), int(round(stats.life))]

    vitality_bar.max_value = stats.max_vitality
    vitality_bar.value = vit_display
    vitality_value_label.text = "%d / %d Vitality" % [int(round(vit_display)), int(round(stats.max_vitality))]

    morale_bar.max_value = stats.max_morale
    morale_bar.value = morale_display
    morale_value_label.text = "%d / %d Morale" % [int(round(morale_display)), int(round(stats.max_morale))]


func _populate_defence(stats: ExileStats) -> void :
    armour_value.text = "%d" % int(round(stats.armour))
    evasion_value.text = "%s%%" % _fmt_num(stats.evasion)
    energy_shield_value.text = "%d" % int(round(stats.energy_shield))
    block_value.text = "%.0f%% / %d" % [stats.block_chance, int(round(stats.block_amount))]
    endurance_value.text = "%.0f%% / %.0f%%" % [stats.endurance_threshold, stats.endurance]


func _populate_resistances(stats: ExileStats) -> void :




    fire_res_value.text = "%d%% / %d%%" % [stats.fire_resistance, stats.fire_resistance_cap]
    cold_res_value.text = "%d%% / %d%%" % [stats.cold_resistance, stats.cold_resistance_cap]
    light_res_value.text = "%d%% / %d%%" % [stats.lightning_resistance, stats.lightning_resistance_cap]
    chaos_res_value.text = "%d%% / %d%%" % [stats.chaos_resistance, stats.chaos_resistance_cap]


func _populate_offence(stats: ExileStats) -> void :
    var avg_per_hit: = _calc_average_hit(stats)
    var crit_factor: = 1.0 + (stats.critical_chance / 100.0) * ((stats.critical_multiplier / 100.0) - 1.0)
    var crit_weighted_avg: = avg_per_hit * crit_factor
    var effective_aspd: = stats.attack_speed * stats.action_speed
    var dps: = crit_weighted_avg * effective_aspd

    dps_value_label.text = _fmt_num(dps)
    hit_value_label.text = "%d" % int(round(avg_per_hit))
    attack_speed_value_label.text = "%s /s" % _fmt_num(effective_aspd, 2)
    crit_value_label.text = "%d%% / %d%%" % [int(round(stats.critical_chance)), int(round(stats.critical_multiplier))]


func _populate_recovery(stats: ExileStats) -> void :
    life_regen_value_label.text = "%s /s" % _fmt_num(stats.life_regen)
    life_gain_value_label.text = "%d" % int(round(stats.life_gain_on_hit))
    life_leech_value_label.text = "%s%%" % _fmt_num(stats.life_leech)
    second_wind_value_label.text = "%d%% to %d%%" % [int(round(stats.second_wind_chance)), int(round(stats.second_wind_amount))]


func _populate_traits_tab(data: ExileData) -> void :
    _populate_traits_grid(data)
    _populate_potential_grid(data)



func _populate_traits_grid(data: ExileData) -> void :

    for child in traits_grid.get_children():
        child.queue_free()

    if data.traits.is_empty():
        traits_empty_label.visible = true
        return

    traits_empty_label.visible = false
    for trait_id in data.traits:
        var trait_def: TraitDefinition = TraitLibrary.get_trait_by_id(trait_id)
        if trait_def == null:
            continue
        var card: TraitCardPanel = TRAIT_CARD_SCENE.instantiate()
        traits_grid.add_child(card)
        card.bind(trait_def)
        card.trait_hovered.connect(_on_trait_hovered)
        card.trait_unhovered.connect(_on_trait_unhovered)




func _populate_potential_grid(data: ExileData) -> void :
    for child in potential_grid.get_children():
        child.queue_free()

    if data.potential == null:
        var placeholder: = Label.new()
        placeholder.text = "No potentials."
        placeholder.modulate = Color(0.7, 0.7, 0.7)
        potential_grid.add_child(placeholder)
        return


    for entry in data.potential.get_display_entries():
        var card: PotentialCardPanel = POTENTIAL_CARD_SCENE.instantiate()
        potential_grid.add_child(card)
        card.bind(entry)












func _populate_scaling_tab(data: ExileData) -> void :


    var rows: = {
        "PhysicalRow": ["physical_damage", "damage"], 
        "ElementalRow": ["elemental_damage"], 
        "FireRow": ["fire_damage", "elemental_damage", "damage"], 
        "ColdRow": ["cold_damage", "elemental_damage", "damage"], 
        "LightningRow": ["lightning_damage", "elemental_damage", "damage"], 
        "ChaosRow": ["chaos_damage", "damage"], 
    }
    for row_name in rows:
        var stat_ids: Array[String] = []
        for sid in rows[row_name]:
            stat_ids.append(sid)
        var total: float = StatCalculator.get_total_increased_percent(data, stat_ids)


        _row(scaling_body, row_name).populate("%+.0f%%" % total)






func _populate_ailment_tab(stats: ExileStats) -> void :



    _row(ailment_body, "ShockChanceRow").set_value_or_hide(stats.shock_chance, 0.0, "%+.0f%%")
    _row(ailment_body, "ShockEffectRow").set_value_or_hide(stats.shock_effect_more_pct, 0.0, "%+.0f%%")
    _row(ailment_body, "ShockDurationRow").set_value_or_hide(stats.shock_duration_more_pct, 0.0, "%+.0f%%")
    _row(ailment_body, "ChillEffectRow").set_value_or_hide(stats.chill_effect_more_pct, 0.0, "%+.0f%%")
    _row(ailment_body, "ChillDurationRow").set_value_or_hide(stats.chill_duration_more_pct, 0.0, "%+.0f%%")
    _row(ailment_body, "IgniteChanceRow").set_value_or_hide(stats.ignite_chance, 0.0, "%+.0f%%")
    _row(ailment_body, "IgniteEffectRow").set_value_or_hide(stats.ignite_effect_more_pct, 0.0, "%+.0f%%")
    _row(ailment_body, "IgniteDurationRow").set_value_or_hide(stats.ignite_duration_more_pct, 0.0, "%+.0f%%")
    _row(ailment_body, "DamageOverTimeRow").set_value_or_hide(stats.damage_over_time_more_pct, 0.0, "%+.0f%%")
    _row(ailment_body, "PoisonChanceRow").set_value_or_hide(stats.poison_chance, 0.0, "%+.0f%%")
    _row(ailment_body, "PoisonEffectRow").set_value_or_hide(stats.poison_effect_more_pct, 0.0, "%+.0f%%")
    _row(ailment_body, "PoisonDurationRow").set_value_or_hide(stats.poison_duration_more_pct, 0.0, "%+.0f%%")
    _row(ailment_body, "ImpaleChanceRow").set_value_or_hide(stats.impale_chance, 0.0, "%+.0f%%")
    _row(ailment_body, "ImpaleEffectRow").set_value_or_hide(stats.impale_effect_pct, 0.0, "%+.0f%%")




    var max_impales_row: = _row(ailment_body, "MaxImpalesRow")
    if stats.max_impales_bonus > 0:
        var effective: int = GameSettings.IMPALE_BASE_MAX_STACKS + stats.max_impales_bonus
        max_impales_row.populate("%d (+%d)" % [effective, stats.max_impales_bonus])
    else:
        max_impales_row.hide_row()



    _row(ailment_body, "ShockEffectReductionRow").set_value_or_hide(stats.shock_effect_reduction_pct, 0.0, "%.0f%%")
    _row(ailment_body, "ShockDurationReductionRow").set_value_or_hide(stats.shock_duration_reduction_pct, 0.0, "%.0f%%")
    _row(ailment_body, "ChillEffectReductionRow").set_value_or_hide(stats.chill_effect_reduction_pct, 0.0, "%.0f%%")
    _row(ailment_body, "ChillDurationReductionRow").set_value_or_hide(stats.chill_duration_reduction_pct, 0.0, "%.0f%%")
    _row(ailment_body, "IgniteDurationReductionRow").set_value_or_hide(stats.ignite_duration_reduction_pct, 0.0, "%.0f%%")
    _row(ailment_body, "PoisonDurationReductionRow").set_value_or_hide(stats.poison_duration_reduction_pct, 0.0, "%.0f%%")


    var immunities_row: = _row(ailment_body, "ImmunitiesRow")
    if stats.ailment_immunities.is_empty():
        immunities_row.hide_row()
    else:
        var pretty: Array[String] = []
        for sn in stats.ailment_immunities:
            pretty.append(str(sn).capitalize())
        immunities_row.populate(", ".join(pretty))




    var offence_rows: = ["ShockChanceRow", "ShockEffectRow", "ShockDurationRow", 
        "ChillEffectRow", "ChillDurationRow", "IgniteChanceRow", "IgniteEffectRow", 
        "IgniteDurationRow", "DamageOverTimeRow", "PoisonChanceRow", 
        "PoisonEffectRow", "PoisonDurationRow", "ImpaleChanceRow", 
        "ImpaleEffectRow", "MaxImpalesRow"]
    var defence_rows: = ["ShockEffectReductionRow", "ShockDurationReductionRow", 
        "ChillEffectReductionRow", "ChillDurationReductionRow", 
        "IgniteDurationReductionRow", "PoisonDurationReductionRow", "ImmunitiesRow"]
    var offence_any: bool = _any_row_visible(ailment_body, offence_rows)
    var defence_any: bool = _any_row_visible(ailment_body, defence_rows)
    ailment_body.get_node("OffenceEmptyLabel").visible = not offence_any
    ailment_body.get_node("DefenceEmptyLabel").visible = not defence_any


    ailment_body.get_node("OffenceDefenceSeparator").visible = offence_any or defence_any


func _populate_other_tab(stats: ExileStats) -> void :




    _row(other_body, "MovementSpeedRow").populate("%+.0f%%" % stats.movement)
    _row(other_body, "ActionSpeedRow").populate("%.0f%%" % (stats.action_speed * 100.0))
    _row(other_body, "ScoutingRow").populate("%+.0f%%" % stats.scouting)
    _row(other_body, "SurvivalRow").populate("%+.0f%%" % stats.survival)
    _row(other_body, "ScavengingRow").populate("%+.0f%%" % stats.scavenging)






func _populate_morale_tab(data: ExileData, stats: ExileStats) -> void :
    _populate_morale_effects(data, stats)
    _populate_morale_modifiers(stats)
    _populate_morale_history(data)




func _populate_morale_effects(data: ExileData, stats: ExileStats) -> void :

    for child in morale_effects_body.get_children():
        if child == morale_effects_empty:
            continue
        child.queue_free()

    var added_any: bool = false



    if MoraleManager.is_morale_high(data):
        _add_effect_label("+%.0f%% Damage Dealt" % GameSettings.MORALE_HIGH_DAMAGE_DEALT_MORE, true)
        _add_effect_label("+%.0f%% Damage Reduction" % GameSettings.MORALE_HIGH_DAMAGE_TAKEN_LESS, true)
        _add_effect_label("+%.0f%% Experience Gained" % GameSettings.MORALE_HIGH_XP_MORE, true)
        added_any = true
    elif MoraleManager.is_morale_low(data):
        _add_effect_label("-%.0f%% Damage Dealt" % GameSettings.MORALE_HIGH_DAMAGE_DEALT_MORE, false)
        _add_effect_label("-%.0f%% Damage Reduction" % GameSettings.MORALE_HIGH_DAMAGE_TAKEN_LESS, false)
        _add_effect_label("-%.0f%% Experience Gained" % GameSettings.MORALE_HIGH_XP_MORE, false)
        added_any = true



    if MoraleManager.is_morale_broken(data):
        var leave_chance: float = MoraleManager.get_leave_chance(data.id)
        if leave_chance > 0.0:
            _add_effect_label("%.0f%% Chance to Leave Guild" % leave_chance, false)
            added_any = true



    morale_effects_empty.visible = not added_any




func _populate_morale_modifiers(stats: ExileStats) -> void :
    _row(morale_modifiers_body, "MoraleGainRow").populate("%+.0f%%" % stats.morale_gain)
    _row(morale_modifiers_body, "MoraleLossResistRow").populate("%+.0f%%" % stats.morale_loss_resistance)
    _row(morale_modifiers_body, "VictoryMoraleRow").populate("%+.0f" % stats.victory_morale_bonus)
    _row(morale_modifiers_body, "WellFedRow").populate("%+.0f" % stats.well_fed_rest_morale_bonus)





func _populate_morale_history(data: ExileData) -> void :
    for child in morale_history_grid.get_children():
        child.queue_free()

    var history: Array = MoraleManager.get_morale_history(data.id, 10)
    if history.is_empty():
        morale_history_empty.visible = true
        morale_history_grid.visible = false
        return

    morale_history_empty.visible = false
    morale_history_grid.visible = true


    history.reverse()
    for record in history:
        morale_history_grid.add_child(_build_history_label(record))




func _build_history_label(record) -> Label:
    var label: = Label.new()
    label.add_theme_font_size_override("font_size", 12)
    var positive: bool = record.amount >= 0.0
    var sign_str: String = "+" if positive else ""


    label.text = "%s%.0f  %s" % [sign_str, record.amount, record.get_reason_text()]
    var color: Color = Color(0.55, 0.85, 0.55) if positive else Color(0.95, 0.45, 0.45)
    label.add_theme_color_override("font_color", color)
    return label





func _add_effect_label(text: String, positive: bool) -> void :
    var label: = Label.new()
    label.text = text
    var color: Color = Color(0.55, 0.85, 0.55) if positive else Color(0.95, 0.45, 0.45)
    label.add_theme_color_override("font_color", color)
    morale_effects_body.add_child(label)




static func _row(parent: Node, row_name: String) -> CharacterStatRow:
    return parent.get_node(row_name) as CharacterStatRow




static func _any_row_visible(parent: Node, row_names: Array) -> bool:
    for n in row_names:
        var node: = parent.get_node_or_null(n)
        if node and node.visible:
            return true
    return false




func _on_offence_tile_hover() -> void :
    if exile_data == null:
        return
    var bbcode: = _build_damage_breakdown_bbcode(exile_data.current_stats)
    _floating_tooltip.show_breakdown(bbcode, get_global_mouse_position())


func _on_offence_tile_unhover() -> void :
    _floating_tooltip.hide_tooltip()


func _on_trait_hovered(trait_def: TraitDefinition) -> void :
    if trait_def == null:
        return
    var bbcode: = _build_trait_bbcode(trait_def)
    _floating_tooltip.show_breakdown(bbcode, get_global_mouse_position())


func _on_trait_unhovered() -> void :
    _floating_tooltip.hide_tooltip()




func _on_class_hover() -> void :
    if exile_data == null or exile_data.class_definition == null:
        return
    var bbcode: = _build_class_bbcode(exile_data.class_definition)
    _floating_tooltip.show_breakdown(bbcode, get_global_mouse_position())


func _on_class_unhover() -> void :
    _floating_tooltip.hide_tooltip()




func _build_damage_breakdown_bbcode(stats: ExileStats) -> String:
    var lines: Array[String] = []
    lines.append("[code]Damage Breakdown[/code]")

    var damage_types: = [
        ["physical", stats.physical_damage, "ffffff"], 
        ["fire", stats.fire_damage, "f27333"], 
        ["cold", stats.cold_damage, "8cccff"], 
        ["lightning", stats.lightning_damage, "f2e58c"], 
        ["chaos", stats.chaos_damage, "cc73f2"], 
    ]

    var total_avg: = 0.0
    var any_listed: = false
    for entry in damage_types:
        var type_name: String = entry[0]
        var range_vec: Vector2 = entry[1]
        var hex: String = entry[2]
        if range_vec == Vector2.ZERO:
            continue
        var avg: = (range_vec.x + range_vec.y) * 0.5
        total_avg += avg
        any_listed = true
        lines.append("  [color=#%s]%s[/color]: %d-%d  (avg %.0f)" % [
            hex, type_name.capitalize(), int(round(range_vec.x)), int(round(range_vec.y)), avg
        ])

    if not any_listed:
        lines.append("  [color=gray]No damage on weapon / stats.[/color]")

    lines.append("")
    lines.append("Avg per hit (non-crit): [b]%.0f[/b]" % total_avg)
    var crit_factor: = 1.0 + (stats.critical_chance / 100.0) * ((stats.critical_multiplier / 100.0) - 1.0)


    lines.append("Crit-weighted avg: [b]%s[/b]  ([color=yellow]%d%% * %sx[/color])" % [
        _fmt_num(total_avg * crit_factor), 
        int(round(stats.critical_chance)), 
        _fmt_num(stats.critical_multiplier / 100.0, 2), 
    ])
    var effective_aspd: = stats.attack_speed * stats.action_speed
    lines.append("Effective Attack Speed: [b]%s /s[/b]" % _fmt_num(effective_aspd, 2))
    lines.append("[b]Total DPS: %s[/b]" % _fmt_num(total_avg * crit_factor * effective_aspd))

    return "\n".join(lines)


func _build_trait_bbcode(trait_def: TraitDefinition) -> String:
    var rarity_hex: = RarityColors.get_hex(trait_def.rarity)
    var rarity_name: = RarityColors.get_rarity_name(trait_def.rarity)
    var category_name: = _trait_category_name(trait_def.category)

    var lines: Array[String] = []
    lines.append("[code]%s[/code]" % trait_def.name)
    lines.append("[color=%s]%s[/color]  [color=gray]- %s[/color]" % [rarity_hex, rarity_name, category_name])
    lines.append("")

    lines.append(trait_def.get_full_description())
    return "\n".join(lines)


static func _trait_category_name(category: int) -> String:
    match category:
        TraitDefinition.TraitCategory.BACKGROUND: return "Background"
        TraitDefinition.TraitCategory.LEARNED: return "Learned"
        TraitDefinition.TraitCategory.SCAR: return "Scar"
        _: return "?"






func _build_class_bbcode(class_def: ClassDefinition) -> String:
    var rarity_hex: = RarityColors.get_hex(class_def.rarity)
    var rarity_name: = RarityColors.get_rarity_name(class_def.rarity)

    var lines: Array[String] = []
    lines.append("[code]%s[/code]" % class_def.name)
    lines.append("[color=%s]%s Class[/color]" % [rarity_hex, rarity_name])
    if class_def.description.strip_edges().length() > 0:
        lines.append("")
        lines.append(class_def.description)


    var starting_lines: = _build_class_override_lines(class_def)
    if not starting_lines.is_empty():
        lines.append("")
        lines.append("[code]Starting Bonuses[/code]")
        lines.append_array(starting_lines)


    var growth_lines: Array[String] = []
    if class_def.life_per_level != 0.0:
        growth_lines.append("  Life: %+.0f" % class_def.life_per_level)
    if class_def.vitality_per_level != 0.0:
        growth_lines.append("  Vitality: %+.0f" % class_def.vitality_per_level)
    for i in range(class_def.growth_stat_ids.size()):
        if i >= class_def.growth_stat_values.size():
            break
        var value: float = class_def.growth_stat_values[i]
        if value == 0.0:
            continue
        growth_lines.append("  %s: %s" % [_humanize_stat(class_def.growth_stat_ids[i]), _fmt_signed(value)])
    if not growth_lines.is_empty():
        lines.append("")
        lines.append("[code]Growth per Level[/code]")
        lines.append_array(growth_lines)


    if not class_def.percent_stat_ids.is_empty():
        var percent_lines: Array[String] = []
        for i in range(class_def.percent_stat_ids.size()):
            if i >= class_def.percent_stat_values.size():
                break
            var pct: float = class_def.percent_stat_values[i]
            if pct == 0.0:
                continue
            percent_lines.append("  %s: %s%% / level" % [_humanize_stat(class_def.percent_stat_ids[i]), _fmt_signed(pct)])
        if not percent_lines.is_empty():
            lines.append("")
            lines.append("[code]Percentage Growth[/code]")
            lines.append_array(percent_lines)


    if not class_def.conditional_bonuses.is_empty():
        lines.append("")
        lines.append("[code]Conditional Bonuses[/code]")
        for conditional in class_def.conditional_bonuses:
            if conditional == null:
                continue
            lines.append("  %s" % conditional.get_display_text(1))


    if not class_def.special_effects.is_empty():
        lines.append("")
        lines.append("[code]Special Effects[/code]")
        for effect in class_def.special_effects:
            lines.append("  %s" % effect.capitalize().replace("_", " "))


    if not class_def.potential_tags.is_empty():
        var potential_lines: Array[String] = []
        for i in range(class_def.potential_tags.size()):
            if i >= class_def.potential_values.size():
                break
            var value: float = class_def.potential_values[i]
            if value == 0.0:
                continue
            potential_lines.append("  %s: %s" % [_humanize_stat(class_def.potential_tags[i]), _fmt_signed(value)])
        if not potential_lines.is_empty():
            lines.append("")
            lines.append("[code]Growth Potentials[/code]")
            lines.append_array(potential_lines)

    return "\n".join(lines)




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




static func _humanize_stat(stat_id: String) -> String:
    return stat_id.replace("_", " ").capitalize()





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




static func _calc_average_hit(stats: ExileStats) -> float:
    var total: = 0.0
    for range_vec in [stats.physical_damage, stats.fire_damage, stats.cold_damage, 
            stats.lightning_damage, stats.chaos_damage]:
        total += (range_vec.x + range_vec.y) * 0.5
    return total




func _on_level_up_badge_clicked(clicked_exile: ExileData) -> void :
    LevelUpModalLauncher.launch_for(clicked_exile)




func _begin_name_edit() -> void :
    if exile_data == null:
        return
    _is_editing_name = true
    name_edit.text = exile_data.name
    _set_name_edit_visible(true)
    name_edit.grab_focus()
    name_edit.select_all()


func _commit_name_edit() -> void :
    if exile_data == null:
        _is_editing_name = false
        _set_name_edit_visible(false)
        return
    var new_name: String = name_edit.text.strip_edges()

    if new_name.length() > 0 and new_name != exile_data.name:
        exile_data.name = new_name
        _is_editing_name = false


        GameState.exile_updated.emit(exile_data)
        return

    _is_editing_name = false
    _set_name_edit_visible(false)


func _cancel_name_edit() -> void :
    _is_editing_name = false
    _set_name_edit_visible(false)


func _on_name_edit_submitted(_text: String) -> void :
    _commit_name_edit()



func _set_name_edit_visible(editing: bool) -> void :
    name_label.visible = not editing
    name_edit.visible = editing
    edit_name_button.visible = not editing
    confirm_name_button.visible = editing




func _close() -> void :
    hide()
    if _floating_tooltip != null:
        _floating_tooltip.hide_tooltip()
    _is_editing_name = false
    _set_name_edit_visible(false)
    exile_data = null






func _on_dismiss_pressed() -> void :
    if exile_data == null:
        return
    var modal: MessageModal = MESSAGE_MODAL_SCENE.instantiate()
    modal.setup(
        "Dismiss Exile?", 
        "Are you sure you want to dismiss [b]%s[/b]?\n\nAny equipped items will be returned to your stash. This cannot be undone." % exile_data.name, 
        "Dismiss", 
        "Cancel", 
    )
    add_child(modal)


    var target_id: int = exile_data.id
    modal.confirmed.connect( func(): _confirm_dismiss(target_id))


func _confirm_dismiss(target_id: int) -> void :
    if GameState.dismiss_exile(target_id):

        _close()


func _unhandled_input(event: InputEvent) -> void :
    if not visible:
        return



    if _is_editing_name:
        if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
            _cancel_name_edit()
            get_viewport().set_input_as_handled()
            return
        if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:


            var name_row_rect: Rect2 = name_edit.get_global_rect().merge(confirm_name_button.get_global_rect())
            if not name_row_rect.has_point(event.global_position):
                _cancel_name_edit()
                get_viewport().set_input_as_handled()
                return
        return


    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        if not get_global_rect().has_point(event.global_position):
            _close()
            get_viewport().set_input_as_handled()






func _on_exile_updated(updated_exile: ExileData) -> void :
    if _is_editing_name:
        return
    if exile_data and exile_data.id == updated_exile.id:
        populate(exile_data)
