class_name MissionCard
extends PanelContainer










signal embark_requested(mission: MissionData, instance: OpportunityInstance)

const UNKNOWN_MONSTER_DESCRIPTION: String = "You haven't yet encountered this creature. Defeat or engage it on a mission in this area to add it to your bestiary."

@export_group("Rarity Flair")



@export var default_style: StyleBox

@export var unique_style: StyleBox

@export var rare_style: StyleBox

@onready var icon_rect: TextureRect = %IconRect
@onready var title_label: RichTextLabel = %TitleLabel
@onready var recommended_level_label: Label = %RecommendedLevelLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var timeout_label: Label = %TimeoutLabel
@onready var description_label: RichTextLabel = %DescriptionLabel
@onready var monsters_list: VBoxContainer = %MonstersList
@onready var embark_button: Button = %EmbarkButton


const TIMEOUT_NORMAL_COLOR: Color = Color(0.85, 0.74, 0.32, 1.0)


const TIMEOUT_LAST_DAY_COLOR: Color = Color(0.95, 0.3, 0.3, 1.0)

var _mission: MissionData = null




var _instance: OpportunityInstance = null



var _monster_tooltip: NonKeywordTooltipPanel = null


func _ready() -> void :
    embark_button.pressed.connect(_on_embark_pressed)










func populate(
    mission: MissionData, 
    area_id: WorldEnum.AREAS, 
    monster_tooltip: NonKeywordTooltipPanel = null, 
    instance: OpportunityInstance = null, 
) -> void :
    _mission = mission
    _instance = instance
    _monster_tooltip = monster_tooltip
    if not is_node_ready():
        await ready

    _apply_rarity_flair(mission)



    recommended_level_label.text = "Recommended Level: %d" % mission.level
    var encounters: int = mission.encounter_slots.size()
    var enc_word: String = "ENCOUNTER" if encounters == 1 else "ENCOUNTERS"
    var rarity_tag: String = _rarity_subtitle_tag(mission)
    subtitle_label.text = "%d %s%s" % [encounters, enc_word, rarity_tag]

    description_label.text = mission.description

    _render_timeout(mission, area_id)



    if mission.icon:
        icon_rect.texture = mission.icon
        icon_rect.visible = true
    else:
        icon_rect.texture = null
        icon_rect.visible = false

    _render_known_monsters(area_id)






func _apply_rarity_flair(mission: MissionData) -> void :
    var style: StyleBox = default_style






    var display_name: String = mission.display_name
    if _instance != null and not _instance.display_name_override.is_empty():
        display_name = _instance.display_name_override
    elif _instance != null and _instance.template_mission_id.begins_with("rescue_captured_"):
        display_name = "Rescue Mission"
    var inner_title: String = display_name

    if mission.boss_mission and unique_style:
        style = unique_style
        inner_title = "[color=%s]%s[/color]" % [RarityColors.LEGENDARY_HEX, display_name]
    elif mission.availability_type == MissionEnums.AVAILABILITY_TYPE.OPPORTUNITY and rare_style:
        style = rare_style
        inner_title = "[color=%s]%s[/color]" % [RarityColors.RARE_HEX, display_name]

    if style:
        add_theme_stylebox_override("panel", style)


    title_label.text = "[code]%s[/code]" % inner_title










func _render_timeout(mission: MissionData, area_id: WorldEnum.AREAS) -> void :
    if mission.availability_type != MissionEnums.AVAILABILITY_TYPE.OPPORTUNITY:
        timeout_label.visible = false
        return





    var instance: OpportunityInstance = _instance
    if instance == null:
        var progress: AreaProgress = AreaManager.get_area_progress(area_id)
        if progress == null or not progress.active_opportunities.has(mission.mission_id):
            timeout_label.visible = false
            return


        var raw_value: Variant = progress.active_opportunities[mission.mission_id]
        if not (raw_value is OpportunityInstance):
            timeout_label.visible = false
            return
        instance = raw_value
    if instance == null:
        timeout_label.visible = false
        return
    var timeout: int = instance.get_effective_timeout_days(mission)
    if timeout <= 0:
        timeout_label.visible = false
        return
    var days_remaining: int = timeout - (GameState.current_day - instance.day_appeared)
    if days_remaining <= 0:

        timeout_label.visible = false
        return

    timeout_label.visible = true
    if days_remaining == 1:
        timeout_label.text = "Last Chance"
        timeout_label.add_theme_color_override("font_color", TIMEOUT_LAST_DAY_COLOR)
    else:
        timeout_label.text = "%d days remaining" % days_remaining
        timeout_label.add_theme_color_override("font_color", TIMEOUT_NORMAL_COLOR)





func _rarity_subtitle_tag(mission: MissionData) -> String:
    if mission.boss_mission:
        return "  •  [Boss]"
    if mission.availability_type == MissionEnums.AVAILABILITY_TYPE.OPPORTUNITY:
        return "  •  [Opportunity]"
    return ""











func _render_known_monsters(area_id: WorldEnum.AREAS) -> void :
    for child in monsters_list.get_children():
        child.queue_free()

    var pool: Array[MonsterData] = MissionManager.get_mission_monster_pool(_mission, area_id)
    if pool.is_empty():
        var empty: = Label.new()
        empty.text = "—"
        empty.modulate = Color(0.5, 0.5, 0.5)
        monsters_list.add_child(empty)
        return

    for monster: MonsterData in pool:
        var entry: = _build_monster_entry(area_id, monster)
        monsters_list.add_child(entry)


func _build_monster_entry(area_id: WorldEnum.AREAS, monster: MonsterData) -> Label:
    var label: = Label.new()
    var seen: bool = AreaManager.is_monster_seen(area_id, monster.monster_id)
    if seen:
        label.text = monster.display_name
        label.add_theme_color_override("font_color", Color(0.86, 0.82, 0.74, 1))
    else:
        label.text = "Unknown"
        label.add_theme_color_override("font_color", Color(0.55, 0.5, 0.45, 1))
    label.add_theme_font_size_override("font_size", 16)
    label.mouse_filter = Control.MOUSE_FILTER_PASS




    var bbcode: String
    if seen:
        bbcode = _build_monster_tooltip_bbcode(monster)
    else:
        bbcode = "[b]Unknown[/b]\n%s" % UNKNOWN_MONSTER_DESCRIPTION
    label.mouse_entered.connect( func() -> void : _show_monster_tooltip(label, bbcode))
    label.mouse_exited.connect(_hide_monster_tooltip)
    return label





func _build_monster_tooltip_bbcode(monster: MonsterData) -> String:
    var lines: Array[String] = []
    lines.append("[b]%s[/b]" % monster.display_name)
    if not monster.description.is_empty():
        lines.append(monster.description)

    var sections: Array[String] = [
        _build_damage_types_section(monster), 
        _build_abilities_section(monster), 
        _build_resistances_section(monster), 
        _build_movement_section(monster), 
        _build_drops_section(monster), 
    ]
    for section in sections:
        if section.is_empty():
            continue
        lines.append("")
        lines.append(section)

    return "\n".join(lines)





func _build_damage_types_section(monster: MonsterData) -> String:
    if monster.base_stats == null:
        return ""
    var stats: ExileStats = monster.base_stats
    var damage_entries: Array = [
        [StatEnums.DamageType.PHYSICAL, stats.physical_damage], 
        [StatEnums.DamageType.FIRE, stats.fire_damage], 
        [StatEnums.DamageType.COLD, stats.cold_damage], 
        [StatEnums.DamageType.LIGHTNING, stats.lightning_damage], 
        [StatEnums.DamageType.CHAOS, stats.chaos_damage], 
    ]
    var lines: Array[String] = []
    for entry: Array in damage_entries:
        var type_id: int = entry[0]
        var range_vec: Vector2 = entry[1]
        if range_vec == Vector2.ZERO:
            continue
        var hex: String = DamageColors.hex_for(type_id)
        var type_name: String = DamageColors.name_for(type_id)
        lines.append("[color=#%s]%s Damage[/color]" % [hex, type_name])
    if lines.is_empty():
        return ""
    return "Known to deal:\n" + "\n".join(lines)





func _build_abilities_section(monster: MonsterData) -> String:
    var names: Array[String] = []
    for config: ActionSlotConfig in monster.action_slot_configs:
        if config == null:
            continue
        for ability: MonsterAbility in config.abilities:
            if ability == null:
                continue
            if ability.ability_id == "basic_attack":
                continue
            if ability.display_name.is_empty():
                continue
            names.append(ability.display_name)
    if names.is_empty():
        return ""
    return "\n".join(names)









func _build_resistances_section(monster: MonsterData) -> String:
    if monster.base_stats == null:
        return ""
    var stats: ExileStats = monster.base_stats
    var resist_entries: Array = [
        [StatEnums.DamageType.FIRE, stats.fire_resistance, "Fire"], 
        [StatEnums.DamageType.COLD, stats.cold_resistance, "Cold"], 
        [StatEnums.DamageType.LIGHTNING, stats.lightning_resistance, "Lightning"], 
        [StatEnums.DamageType.CHAOS, stats.chaos_resistance, "Chaos"], 
    ]
    var lines: Array[String] = []
    for entry: Array in resist_entries:
        var type_id: int = entry[0]
        var value: float = entry[1]
        var type_name: String = entry[2]
        if is_zero_approx(value):
            continue
        var label_text: String = _resistance_tier_label(value)
        var hex: String = DamageColors.hex_for(type_id)
        lines.append("[color=#%s]%s to %s Damage.[/color]" % [hex, label_text, type_name])
    if lines.is_empty():
        return ""
    return "\n".join(lines)


static func _resistance_tier_label(value: float) -> String:
    if value <= -40.0:
        return "Highly Vulnerable"
    if value < 0.0:
        return "Vulnerable"
    if value >= 40.0:
        return "Highly Resistant"
    return "Resistant"




func _build_movement_section(monster: MonsterData) -> String:
    if monster.base_stats == null:
        return ""
    var movement_value: float = monster.base_stats.movement
    if is_zero_approx(movement_value):
        return ""
    var prefix: String = "Very " if absf(movement_value) > 20.0 else ""
    if movement_value < 0.0:
        return "%sSlow-Moving" % prefix
    return "%sFast-Moving" % prefix




func _build_drops_section(monster: MonsterData) -> String:
    var lines: Array[String] = []
    if monster.food_drops > 0.0:
        lines.append("Food Source")
    if monster.scrap_drops > 0.0:
        lines.append("Scrap Source")
    if lines.is_empty():
        return ""
    return "\n".join(lines)


func _show_monster_tooltip(anchor: Label, bbcode: String) -> void :
    if _monster_tooltip == null:
        return



    var screen_pos: Vector2 = anchor.get_global_position() + Vector2(anchor.size.x + 8.0, 0.0)
    _monster_tooltip.show_breakdown(bbcode, screen_pos)


func _hide_monster_tooltip() -> void :
    if _monster_tooltip:
        _monster_tooltip.hide_tooltip()




func set_can_embark(enabled: bool, reason: String = "") -> void :
    if not is_node_ready():
        await ready
    embark_button.disabled = not enabled
    embark_button.tooltip_text = reason if not enabled else ""


func _on_embark_pressed() -> void :
    if _mission:
        embark_requested.emit(_mission, _instance)
