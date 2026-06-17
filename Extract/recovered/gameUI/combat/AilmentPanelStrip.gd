class_name AilmentPanelStrip
extends HBoxContainer





















signal panel_hovered(bbcode: String, anchor_rect: Rect2)
signal panel_unhovered

const AILMENT_MINI_PANEL: PackedScene = preload("res://gameUI/combat/AilmentMiniPanel.tscn")









var _panels_by_key: Dictionary = {}






const AILMENT_COLORS: Dictionary = {
    &"shock": Color(0.949, 0.898, 0.549, 1.0), 
    &"chill": Color(0.549, 0.8, 1.0, 1.0), 
    &"ignite": Color(0.949, 0.451, 0.2, 1.0), 
    &"impale": Color(0.8, 0.6, 0.4, 1.0), 
    &"poison": Color(0.4, 0.85, 0.2, 1.0), 
    &"desperation": Color(0.7, 0.3, 0.3, 1.0), 
}

const AILMENT_FALLBACK_COLOR: Color = Color(0.6, 0.6, 0.6, 1.0)



const PANEL_SEPARATION: int = 3


func _ready() -> void :
    add_theme_constant_override("separation", PANEL_SEPARATION)






















func refresh_from_state(state: Dictionary, current_tick: float) -> void :
    if not is_node_ready():
        await ready





    var desired: Dictionary = _build_desired_set(state, current_tick)



    for key in _panels_by_key.keys().duplicate():
        if not desired.has(key):
            var panel: AilmentMiniPanel = _panels_by_key[key]
            if is_instance_valid(panel):
                panel.queue_free()
            _panels_by_key.erase(key)







    var ordered_keys: Array = desired.keys()
    ordered_keys.sort()
    for i in ordered_keys.size():
        var key: StringName = ordered_keys[i]
        var info: Dictionary = desired[key]
        var panel: AilmentMiniPanel = _panels_by_key.get(key)
        if panel == null or not is_instance_valid(panel):
            panel = AILMENT_MINI_PANEL.instantiate()
            add_child(panel)
            panel.panel_hovered.connect(_on_panel_hovered)
            panel.panel_unhovered.connect(_on_panel_unhovered)
            _panels_by_key[key] = panel


        move_child(panel, i)
        panel.populate(info["color"], info["primary_text"], info["bbcode"])







func _build_desired_set(state: Dictionary, current_tick: float) -> Dictionary:
    var desired: Dictionary = {}
    if state == null or state.is_empty():
        return desired

    var status_effects: Dictionary = state.get("status_effects", {})
    for effect_id in status_effects.keys():
        var slot: Dictionary = status_effects[effect_id]
        desired[effect_id] = {
            "color": AILMENT_COLORS.get(effect_id, AILMENT_FALLBACK_COLOR), 
            "primary_text": _primary_label_for_status_effect(effect_id, slot), 
            "bbcode": _build_status_effect_bbcode(effect_id, slot, current_tick), 
        }



    var impale_stacks: Array = state.get("impale_stacks", [])
    if not impale_stacks.is_empty():
        var total_flat: float = 0.0
        for stack in impale_stacks:
            total_flat += float(stack.get("flat_damage", 0.0))
        desired[&"_impale"] = {
            "color": AILMENT_COLORS[&"impale"], 
            "primary_text": "%d" % int(round(total_flat)), 
            "bbcode": _build_impale_bbcode(impale_stacks, total_flat), 
        }



    var poison_stacks: Array = state.get("poison_stacks", [])
    if not poison_stacks.is_empty():
        desired[&"_poison"] = {
            "color": AILMENT_COLORS[&"poison"], 
            "primary_text": "%d" % poison_stacks.size(), 
            "bbcode": _build_poison_bbcode(poison_stacks, current_tick), 
        }

    return desired




static func _primary_label_for_status_effect(effect_id: StringName, slot: Dictionary) -> String:
    match effect_id:
        &"shock":


            var mag: float = float(slot.get("magnitude_pct", 0.0))
            if absf(mag) < 0.5:
                return ""
            return "%d" % int(round(mag))
        &"chill":


            var mag2: float = float(slot.get("magnitude_pct", 0.0))
            if absf(mag2) < 0.5:
                return ""
            return "%d" % int(round(absf(mag2)))
        &"ignite":


            var dps: float = float(slot.get("magnitude_pct", 0.0))
            if dps < 0.5:
                return ""
            return "%d" % int(round(dps))
        _:


            var stacks: int = int(slot.get("stacks", 1))
            if stacks > 1:
                return "%d" % stacks
            return ""


func _on_panel_hovered(bbcode: String, anchor_rect: Rect2) -> void :
    panel_hovered.emit(bbcode, anchor_rect)


func _on_panel_unhovered() -> void :
    panel_unhovered.emit()







static func _build_status_effect_bbcode(effect_id: StringName, slot: Dictionary, current_tick: float) -> String:
    var display_name: String = String(slot.get("display_name", ""))
    if display_name.is_empty():
        display_name = String(effect_id).capitalize()

    var lines: Array[String] = []
    var stacks: int = int(slot.get("stacks", 1))
    var header: String = display_name
    if stacks > 1:
        header = "%s (%d stacks)" % [display_name, stacks]
    lines.append("[b]%s[/b]" % header)


    var per_tick_keys: Dictionary = slot.get("per_tick_keys", {})
    var dot_dps: float = float(per_tick_keys.get("fire_damage_per_sec", 0.0))
    if dot_dps > 0.0:
        lines.append("DPS: %.1f fire" % dot_dps)
    var vit_drain: float = float(per_tick_keys.get("vitality_drain_per_sec", 0.0))
    if vit_drain > 0.0:
        lines.append("Vitality drain: %.1f/s" % vit_drain)



    var modifier_keys: Dictionary = slot.get("modifier_keys", {})
    var dmg_taken: float = float(modifier_keys.get("damage_taken_more_pct", 0.0))
    if dmg_taken != 0.0:
        lines.append("Damage taken: %+.0f%%" % dmg_taken)
    var action_speed: float = float(modifier_keys.get("action_speed_more_pct", 0.0))
    if action_speed != 0.0:
        lines.append("Action speed: %+.0f%%" % action_speed)
    var dmg_dealt: float = float(modifier_keys.get("damage_dealt_more_pct", 0.0))
    if dmg_dealt != 0.0:
        lines.append("Damage dealt: %+.0f%%" % dmg_dealt)


    var expires_at_tick: float = float(slot.get("expires_at_tick", INF))
    if expires_at_tick < INF:
        var remaining: float = maxf(expires_at_tick - current_tick, 0.0)
        lines.append("Time left: %.1fs" % remaining)

    return "\n".join(lines)


static func _build_impale_bbcode(impale_stacks: Array, total_flat: float) -> String:
    var lines: Array[String] = []
    lines.append("[b]Impale[/b]")
    lines.append("Stored flat: %.1f" % total_flat)
    lines.append("Stacks: %d" % impale_stacks.size())
    lines.append("[color=#888]Next elemental hit consumes all stacks.[/color]")
    return "\n".join(lines)


static func _build_poison_bbcode(poison_stacks: Array, current_tick: float) -> String:
    var total_dps: float = 0.0
    var longest_remaining: float = 0.0
    for stack in poison_stacks:
        total_dps += float(stack.get("damage_per_sec", 0.0))
        var rem: float = float(stack.get("expires_at_tick", 0.0)) - current_tick
        if rem > longest_remaining:
            longest_remaining = rem

    var lines: Array[String] = []
    lines.append("[b]Poison (%d stacks)[/b]" % poison_stacks.size())
    lines.append("Total DPS: %.1f chaos/s" % total_dps)
    lines.append("Longest stack: %.1fs left" % longest_remaining)
    return "\n".join(lines)
