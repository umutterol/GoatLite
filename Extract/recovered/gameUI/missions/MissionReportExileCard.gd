class_name MissionReportExileCard
extends PanelContainer













signal death_report_pressed(exile: ExileData)

const RecoveryIconScene: = preload("res://gameUI/smallComponents/RecoveryIcon.tscn")
const DownedIconScene: = preload("res://gameUI/smallComponents/DownedIcon.tscn")
const BatteredIconScene: = preload("res://gameUI/smallComponents/BatteredIcon.tscn")
const StarvingIconScene: = preload("res://gameUI/smallComponents/StarvingIcon.tscn")

@onready var portrait: ExilePortraitSlot = %Portrait
@onready var weapon_icon: WeaponTypeIcon = %WeaponIcon
@onready var header_rich: RichTextLabel = %HeaderRich
@onready var icon_strip: HBoxContainer = %IconStrip
@onready var column: VBoxContainer = %Column

@onready var life_bar: DiffBar = %LifeBar
@onready var vit_bar: DiffBar = %VitBar
@onready var mor_bar: DiffBar = %MorBar
@onready var xp_bar: DiffBar = %XPBar




@onready var damage_taken_bar: ProgressBar = %DamageTakenBar
@onready var damage_taken_value: Label = %DamageTakenValue
@onready var damage_dealt_bar: ProgressBar = %DamageDealtBar
@onready var damage_dealt_value: Label = %DamageDealtValue
@onready var kills_bar: ProgressBar = %KillsBar
@onready var kills_value: Label = %KillsValue

@onready var dead_overlay: Label = %DeadOverlay
@onready var death_report_button: Button = %DeathReportButton
@onready var mia_glowify: TextGlowifyNode = %MiaGlowify

var _exile: ExileData = null
var _is_dead: bool = false


func _ready() -> void :
    death_report_button.pressed.connect(_on_death_report_pressed)







func populate(
    exile: ExileData, 
    combat_stats: Dictionary, 
    party_totals: Dictionary, 
    starting_state: Dictionary, 
    end_state: Dictionary, 
    defeat_result, 
) -> void :
    if not is_node_ready():
        await ready
    _exile = exile
    _is_dead = defeat_result != null and defeat_result.died






    var leveled: bool = combat_stats.get("leveled_up", false)
    var is_missing: bool = (
        not _is_dead
        and defeat_result != null
        and defeat_result.outcome != null
        and defeat_result.outcome.capture_duration_days > 0
    )
    var level_tag: String = ""
    var died_tag: String = ""
    var mia_tag: String = ""
    if _is_dead:
        died_tag = "  [color=#f55][DIED][/color]"
    elif is_missing:
        mia_tag = "  [color=#f55][MIA][/color]"
    elif leveled:
        level_tag = "  [color=#fc5][+LVL][/color]"
    header_rich.text = "[b]%s[/b]  —  %s %d%s%s%s" % [
        exile.name, exile.get_class_name(), exile.level, level_tag, died_tag, mia_tag, 
    ]






    if mia_glowify:
        if is_missing:
            mia_glowify.start()
        else:
            mia_glowify.stop()

    portrait.paint_exile(exile)
    weapon_icon.populate(ExileWeaponHelper.get_main_weapon(exile))

    _rebuild_icon_strip(exile, defeat_result)
    _configure_bars(exile, starting_state, end_state, combat_stats)
    _set_combat_share_bars(combat_stats, party_totals)



    if _is_dead:
        column.modulate = Color(0.65, 0.55, 0.55)




func play_animation(duration: float) -> void :
    if not is_node_ready():
        await ready
    for bar in [life_bar, vit_bar, mor_bar, xp_bar]:
        if bar:
            bar.play_animation(duration)




func reveal_dead_state() -> void :
    if not _is_dead or not is_node_ready():
        return
    dead_overlay.visible = true
    death_report_button.visible = true






func _rebuild_icon_strip(exile: ExileData, defeat_result) -> void :
    for child in icon_strip.get_children():
        child.queue_free()

    if defeat_result and defeat_result.outcome:
        var outcome_id: String = defeat_result.outcome.outcome_id
        if outcome_id == "injured_battered":
            icon_strip.add_child(BatteredIconScene.instantiate())
        else:
            icon_strip.add_child(DownedIconScene.instantiate())






    if exile.status == "recovering":
        icon_strip.add_child(RecoveryIconScene.instantiate())

    if MoraleManager.get_hungry_stacks(exile) > 0:
        var starving: StarvingIcon = StarvingIconScene.instantiate()
        icon_strip.add_child(starving)
        starving.bind(exile)


func _configure_bars(exile: ExileData, starting: Dictionary, end_state: Dictionary, combat_stats: Dictionary) -> void :
    life_bar.configure(
        starting.get("life", 0.0), end_state.get("life", 0.0), 
        maxf(end_state.get("max_life", 1.0), 1.0), 
        life_bar.bar_color, 
    )
    vit_bar.configure(
        starting.get("vitality", 0.0), end_state.get("vitality", 0.0), 
        maxf(end_state.get("max_vitality", 1.0), 1.0), 
        vit_bar.bar_color, 
    )


    mor_bar.configure(
        starting.get("morale", 0.0), exile.current_stats.morale, 
        maxf(exile.current_stats.max_morale, 1.0), 
        mor_bar.bar_color, 
    )




    var xp_earned: int = int(combat_stats.get("xp_earned", 0))
    var xp_end: float = float(exile.experience)
    var xp_start: float = maxf(xp_end - float(xp_earned), 0.0)
    xp_bar.configure(
        xp_start, xp_end, 
        maxf(float(exile.get_exp_for_next_level()), 1.0), 
        xp_bar.bar_color, 
    )





func _set_combat_share_bars(combat_stats: Dictionary, party_totals: Dictionary) -> void :
    _configure_share_bar(
        damage_taken_bar, damage_taken_value, 
        float(combat_stats.get("damage_taken", 0.0)), 
        float(party_totals.get("damage_taken", 0.0)), 
    )
    _configure_share_bar(
        damage_dealt_bar, damage_dealt_value, 
        float(combat_stats.get("damage_dealt", 0.0)), 
        float(party_totals.get("damage_dealt", 0.0)), 
    )
    _configure_share_bar(
        kills_bar, kills_value, 
        float(combat_stats.get("kills", 0)), 
        float(party_totals.get("kills", 0)), 
    )


func _configure_share_bar(bar: ProgressBar, value_label: Label, value: float, party_total: float) -> void :

    bar.max_value = maxf(party_total, 1.0)
    bar.value = value
    value_label.text = "%d" % int(round(value))


func _on_death_report_pressed() -> void :
    death_report_pressed.emit(_exile)
