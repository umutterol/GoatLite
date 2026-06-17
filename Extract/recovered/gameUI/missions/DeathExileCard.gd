class_name DeathExileCard
extends PanelContainer






const RECAP_TIME_WINDOW: float = 10.0
const RECAP_MIN_DAMAGE_EVENTS: int = 10

@onready var portrait: ExilePortraitSlot = %Portrait
@onready var name_label: Label = %NameLabel
@onready var class_level_label: Label = %ClassLevelLabel
@onready var log_view: RichTextLabel = %LogView
@onready var weapon_icon: WeaponTypeIcon = %WeaponIcon



var _tooltip: NonKeywordTooltipPanel = null



var _events_by_meta: Dictionary = {}





func populate(
    exile: ExileData, 
    combat_result: CombatResultData, 
    combatant_id: int, 
    tooltip: NonKeywordTooltipPanel, 
) -> void :
    _tooltip = tooltip
    portrait.paint_exile(exile)
    name_label.text = exile.name
    class_level_label.text = "%s  -  Level %d" % [exile.get_class_name(), exile.level]
    weapon_icon.populate(ExileWeaponHelper.get_main_weapon(exile))

    if combat_result == null:
        log_view.clear()
        log_view.append_text(
            "[color=#888][i]No combat log available - this death did not occur in combat.[/i][/color]"
        )
        return

    log_view.meta_hover_started.connect(_on_meta_hover_started)
    log_view.meta_hover_ended.connect(_on_meta_hover_ended)

    var events: Array = _gather_recap_events(combat_result, combatant_id)
    _render_events(events, combat_result.combatants, exile.id)












func _gather_recap_events(combat_result: CombatResultData, combatant_id: int) -> Array:
    var taken: Array = []
    var downed: CombatEvent = null
    for event in combat_result.event_log:
        match event.event_type:
            CombatEnums.CombatEventType.DAMAGE_DEALT:
                if event.data.get("defender_id", -1) == combatant_id:
                    taken.append(event)
            CombatEnums.CombatEventType.DOWNED:
                if event.data.get("combatant_id", -1) == combatant_id:
                    downed = event
            CombatEnums.CombatEventType.EVASION:

                if event.data.get("defender_id", -1) == combatant_id:
                    taken.append(event)

    if downed == null and taken.is_empty():
        return []

    var threshold: float = (downed.tick if downed else 0.0) - RECAP_TIME_WINDOW
    var by_time: Array = taken.filter( func(e): return e.tick >= threshold)
    var slice_start: int = max(0, taken.size() - RECAP_MIN_DAMAGE_EVENTS)
    var by_count: Array = taken.slice(slice_start, taken.size())

    var chosen: Array = by_time if by_time.size() >= by_count.size() else by_count
    if downed != null and not chosen.has(downed):
        chosen.append(downed)
    chosen.sort_custom( func(a, b): return a.tick < b.tick)
    return chosen






func _render_events(events: Array, combatants: Array, exile_id: int) -> void :
    log_view.clear()
    _events_by_meta.clear()
    if events.is_empty():
        log_view.append_text("[color=#888][i]No damage events were recorded for this exile.[/i][/color]")
        return
    var next_idx: int = 0
    for event in events:
        var meta_id: String = ""
        if event.event_type == CombatEnums.CombatEventType.DAMAGE_DEALT:
            meta_id = "dx:%d:%d" % [exile_id, next_idx]
            _events_by_meta[meta_id] = event
            next_idx += 1
        var line: String = CombatLogFormatter.format_event(
            event, combatants, {"meta_id": meta_id}, 
        )
        if not line.is_empty():
            log_view.append_text(line + "\n")






func _on_meta_hover_started(meta: Variant) -> void :
    if not _tooltip:
        return
    var event: CombatEvent = _events_by_meta.get(str(meta), null)
    if not event:
        return
    _tooltip.show_breakdown(
        CombatLogFormatter.format_breakdown_bbcode(event), 
        get_global_mouse_position(), 
    )


func _on_meta_hover_ended(_meta: Variant) -> void :
    if _tooltip:
        _tooltip.hide_tooltip()
