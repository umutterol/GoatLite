class_name CraftingModal
extends Control

















signal close_requested

const ItemLabelScene: PackedScene = preload("res://gameUI/inventory/itemDetails/itemLabel/ItemLabel.tscn")
const ExaltTexture: Texture2D = preload("res://assets/sprites/itemSprites/currencySprites/ExaltShardPhysical.png")
const ChaosTexture: Texture2D = preload("res://assets/sprites/itemSprites/currencySprites/ChaosShardPhysical.png")
const VaalTexture: Texture2D = preload("res://assets/sprites/itemSprites/currencySprites/VaalIcon.png")

const COLOR_CONFIRM_DEFAULT: Color = Color(1.0, 1.0, 1.0)
const COLOR_CONFIRM_VAAL: Color = Color(1.0, 0.45, 0.45)


const ORIGIN_STASH: String = "stash"
const ORIGIN_EQUIPMENT: String = "equipment"

@onready var main_panel: PanelContainer = %MainPanel
@onready var exalt_button: CurrencyButton = %ExaltButton
@onready var chaos_button: CurrencyButton = %ChaosButton
@onready var vaal_button: CurrencyButton = %VaalButton
@onready var item_host: CenterContainer = %ItemHost
@onready var bench_slot: CraftingBenchSlot = %CraftingBenchSlot
@onready var preview_label: RichTextLabel = %PreviewLabel
@onready var cost_formula_label: Label = %CostFormulaLabel
@onready var cost_total_label: Label = %CostTotalLabel
@onready var cost_divider: HSeparator = %CostDivider
@onready var confirm_button: Button = %ConfirmButton
@onready var outcome_log: RichTextLabel = %OutcomeLog





@onready var bench_glowify: GlowifyNode = %BenchGlowify
@onready var exalt_glowify: GlowifyNode = %ExaltGlowify
@onready var chaos_glowify: GlowifyNode = %ChaosGlowify
@onready var vaal_glowify: GlowifyNode = %VaalGlowify
@onready var confirm_glowify: GlowifyNode = %ConfirmGlowify

var _item_label: ItemLabel = null



var _affix_throb: TextGlowifyNode = null
var _selected_craft: int = -1
var _selected_chaos_target: AffixInstance = null
var _crafting_in_flight: bool = false
var _current_exile: ExileData = null


var _held_origin: Dictionary = {}



var _panel_offset_origin: Rect2 = Rect2()


func _ready() -> void :
    hide()
    _ensure_item_label()

    bench_slot.validate_drop_cb = Callable(self, "_can_claim_item")
    bench_slot.claim_item_cb = Callable(self, "_claim_item")
    bench_slot.item_placed.connect(_on_slot_item_placed)
    bench_slot.item_right_clicked.connect(_on_slot_right_clicked)




    var group: = ButtonGroup.new()
    group.allow_unpress = true
    exalt_button.button_group = group
    chaos_button.button_group = group
    vaal_button.button_group = group
    exalt_button.toggled.connect(_on_currency_toggled.bind(CraftingDefinitions.CraftType.EXALT))
    chaos_button.toggled.connect(_on_currency_toggled.bind(CraftingDefinitions.CraftType.CHAOS))
    vaal_button.toggled.connect(_on_currency_toggled.bind(CraftingDefinitions.CraftType.VAAL))
    confirm_button.pressed.connect(_on_confirm_pressed)
    _item_label.affix_clicked.connect(_on_affix_clicked)



    preview_label.add_theme_font_size_override("normal_font_size", 18)
    preview_label.add_theme_font_size_override("bold_font_size", 18)
    GameState.resource_changed.connect(_on_resources_changed.unbind(3))
    GameState.stash_changed.connect(_on_resources_changed)






func show_modal() -> void :
    if visible:
        return
    _selected_craft = -1
    _selected_chaos_target = null
    _crafting_in_flight = false
    _reset_button_toggles()
    _clear_outcome_log()
    show()


    _refresh_all()




func close_modal() -> void :
    _return_held_to_origin()
    _selected_craft = -1
    _selected_chaos_target = null
    _crafting_in_flight = false
    _stop_all_pulses()
    hide()




func set_current_exile(exile: ExileData) -> void :
    _current_exile = exile




func send_from_stash(item: Item) -> bool:
    if bench_slot.get_item() != null:
        return false
    if not _can_claim_item(item):
        return false
    if not _claim_item(item):
        return false
    bench_slot.set_item(item)
    _on_slot_item_placed(item)
    if not visible:
        show_modal()
    return true




func send_from_equipment(item: Item, exile: ExileData, slot: ItemEnums.EquipSlot) -> bool:
    if bench_slot.get_item() != null or item == null or exile == null:
        return false
    if item.is_corrupted:
        return false


    if not EquipmentManager.unequip_item(exile, slot):
        return false
    if not GameState.guild_stash.has(item):
        return false
    GameState.remove_item_from_stash(item)
    item.stash_position = Vector2i(-1, -1)
    _held_origin = {"type": ORIGIN_EQUIPMENT, "exile": exile, "slot": slot}
    bench_slot.set_item(item)
    _on_slot_item_placed(item)
    if not visible:
        show_modal()
    return true




func has_item(item: Item) -> bool:
    return bench_slot.get_item() == item




func release_held_item() -> void :
    bench_slot.release()
    _held_origin = {}
    _refresh_all()




func _unhandled_input(event: InputEvent) -> void :
    if not visible or _crafting_in_flight:
        return
    if event.is_action_pressed("ui_cancel"):
        close_requested.emit()
        get_viewport().set_input_as_handled()







func _can_claim_item(item: Item) -> bool:
    if item == null or item.base_item == null:
        return false
    if item.base_item.category == ItemEnums.ItemCategory.CURRENCY:
        return false
    if item.is_corrupted:
        return false
    if GameState.guild_stash.has(item):
        return true

    return _find_equipment_origin(item).is_empty() == false




func _claim_item(item: Item) -> bool:
    if GameState.guild_stash.has(item):
        GameState.remove_item_from_stash(item)
        item.stash_position = Vector2i(-1, -1)
        _held_origin = {"type": ORIGIN_STASH}
        return true
    var origin: Dictionary = _find_equipment_origin(item)
    if not origin.is_empty():
        if not EquipmentManager.unequip_item(origin["exile"], origin["slot"]):
            return false

        if not GameState.guild_stash.has(item):
            return false
        GameState.remove_item_from_stash(item)
        item.stash_position = Vector2i(-1, -1)
        _held_origin = {"type": ORIGIN_EQUIPMENT, "exile": origin["exile"], "slot": origin["slot"]}
        return true
    return false





func _find_equipment_origin(item: Item) -> Dictionary:
    if _current_exile == null:
        return {}
    for slot_key in _current_exile.equipped_items:
        if _current_exile.equipped_items[slot_key] == item:
            return {"exile": _current_exile, "slot": ItemEnums.EquipSlot[slot_key]}
    return {}






func _return_held_to_origin() -> void :
    var item: Item = bench_slot.clear()
    if item == null:
        _held_origin = {}
        return
    var origin_type: String = _held_origin.get("type", ORIGIN_STASH)
    if origin_type == ORIGIN_EQUIPMENT:
        var exile: ExileData = _held_origin.get("exile")
        var slot: int = _held_origin.get("slot", -1)
        if exile != null and slot >= 0 and EquipmentManager.equip_item_to_slot(exile, item, slot):
            _held_origin = {}
            return


    _return_item_to_stash(item)
    _held_origin = {}


func _return_item_to_stash(item: Item) -> void :
    var slot_info: Dictionary = GameState.find_free_stash_slot(item)
    if slot_info.is_empty():
        push_warning("CraftingModal: stash full, can't return '%s'" % item.get_display_name())
        return
    item.stash_tab = int(slot_info.get("tab", 0))
    item.stash_position = slot_info.get("position", Vector2i(-1, -1))
    GameState.add_item_to_stash(item)




func _on_slot_item_placed(_item: Item) -> void :

    _selected_craft = -1
    _selected_chaos_target = null
    _reset_button_toggles()
    _refresh_all()


func _on_slot_right_clicked(_item: Item) -> void :


    _return_held_to_origin()
    _selected_craft = -1
    _selected_chaos_target = null
    _reset_button_toggles()
    _refresh_all()




func _on_currency_toggled(on: bool, craft_type: int) -> void :
    if _crafting_in_flight:
        return
    if on:
        _set_selected(craft_type)
    elif _selected_craft == craft_type:
        _set_selected(-1)


func _set_selected(craft_type: int) -> void :
    _selected_craft = craft_type


    _selected_chaos_target = null
    _item_label.set_affix_clicks_enabled(craft_type == CraftingDefinitions.CraftType.CHAOS)
    _render_item()
    _render_preview()
    _render_cost_panel()
    _render_confirm_button()
    _update_pulse_state()


func _reset_button_toggles() -> void :



    exalt_button.set_pressed_no_signal(false)
    chaos_button.set_pressed_no_signal(false)
    vaal_button.set_pressed_no_signal(false)




func _ensure_item_label() -> void :
    if _item_label != null:
        return
    _item_label = ItemLabelScene.instantiate()
    item_host.add_child(_item_label)



    _item_label.set_font_scale(1.75)


    _affix_throb = TextGlowifyNode.new()
    _affix_throb.auto_start = false
    _item_label.add_child(_affix_throb)
    if not _item_label.is_node_ready():
        await _item_label.ready
    _affix_throb.target = _item_label.get_modifiers_label()


func _render_item() -> void :
    var item: Item = bench_slot.get_item()
    if item == null:
        _item_label.visible = false
        return
    _item_label.visible = true


    _item_label.set_highlighted_affix(_selected_chaos_target)
    _item_label.populate(item)


func _on_affix_clicked(slot_kind: String, idx: int) -> void :
    var item: Item = bench_slot.get_item()
    if _selected_craft != CraftingDefinitions.CraftType.CHAOS or item == null:
        return
    var arr: Array = item.prefix_affixes if slot_kind == "prefix" else item.suffix_affixes
    if idx < 0 or idx >= arr.size():
        return
    _selected_chaos_target = arr[idx]

    _render_item()
    _render_preview()
    _render_confirm_button()
    _update_pulse_state()




func _refresh_all() -> void :
    _render_item()
    _refresh_currency_buttons()
    _render_preview()
    _render_cost_panel()
    _render_confirm_button()
    _update_pulse_state()


func _on_resources_changed() -> void :
    if visible:
        _refresh_currency_buttons()
        _render_cost_panel()
        _render_confirm_button()
        _update_pulse_state()







func _render_cost_panel() -> void :
    var item: Item = bench_slot.get_item()
    if item == null or _selected_craft < 0:
        cost_formula_label.text = ""
        cost_total_label.text = ""
        cost_formula_label.visible = false
        cost_total_label.visible = false
        cost_divider.visible = false
        return
    var def: Dictionary = CraftingDefinitions.CRAFTS.get(_selected_craft, {})
    var per_ilvl: int = int(def.get("cost_per_item_level", 0))
    var flat: int = int(def.get("flat_cost", 0))
    var total: int = CraftingDefinitions.get_cost_for_item(_selected_craft, item)
    var noun: String = def.get("display_name", "Orb")
    var plural: String = noun + "s"
    var noun_for_total: String = noun if total == 1 else plural
    cost_formula_label.text = _format_cost_formula(item.item_level, per_ilvl, flat, noun)
    cost_total_label.text = "%d %s" % [total, noun_for_total]
    cost_formula_label.visible = true
    cost_total_label.visible = true
    cost_divider.visible = true








func _format_cost_formula(ilvl: int, per_ilvl: int, flat: int, _noun: String) -> String:
    if per_ilvl == 0:
        return "flat cost"
    var per_str: String = "%d per item level (ilvl %d)" % [per_ilvl, ilvl]
    if flat == 0:
        return per_str
    return "%d + %s" % [flat, per_str]




func _refresh_currency_buttons() -> void :
    _refresh_one(exalt_button, CraftingDefinitions.CraftType.EXALT, GameState.exalt)
    _refresh_one(chaos_button, CraftingDefinitions.CraftType.CHAOS, GameState.chaos)
    _refresh_one(vaal_button, CraftingDefinitions.CraftType.VAAL, GameState.count_vaal_orbs())


func _refresh_one(button: CurrencyButton, craft_type: int, held: int) -> void :
    var item: Item = bench_slot.get_item()
    if item == null:

        button.set_state(held, 0, false)
        button.disabled = true
        button.tooltip_text = "Place an item to craft"
        return
    var cost: int = CraftingDefinitions.get_cost_for_item(craft_type, item)
    var gate: Dictionary = CraftingService.can_apply(item, craft_type)
    var ok: bool = bool(gate.get("ok", false))
    button.set_state(held, cost, true)
    button.disabled = not ok
    button.tooltip_text = gate.get("reason", "")
    if not ok and button.button_pressed:
        button.set_pressed_no_signal(false)
        if _selected_craft == craft_type:
            _selected_craft = -1
            _render_preview()
            _render_confirm_button()




func _render_preview() -> void :
    var item: Item = bench_slot.get_item()
    if item == null:
        preview_label.text = "[color=#888]Drag or Ctrl + Right-click an item into the bench to begin crafting.[/color]"
        return
    match _selected_craft:
        CraftingDefinitions.CraftType.EXALT:
            preview_label.text = _build_exalt_preview()
        CraftingDefinitions.CraftType.CHAOS:
            preview_label.text = _build_chaos_preview()
        CraftingDefinitions.CraftType.VAAL:
            preview_label.text = _build_vaal_preview()
        _:
            preview_label.text = "[color=#888]Select a crafting option above to preview possible outcomes.[/color]"


func _build_exalt_preview() -> String:
    var item: Item = bench_slot.get_item()
    var data: Dictionary = CraftingService.preview_exalt(item)
    var open: Dictionary = data.get("open_slots", {"prefix": 0, "suffix": 0})
    var has_prefix: bool = open.get("prefix", 0) > 0
    var has_suffix: bool = open.get("suffix", 0) > 0





    var scale: float = 0.5 if (has_prefix and has_suffix) else 1.0
    var lines: PackedStringArray = []
    lines.append("[b]Exalt - Add Affix[/b]")
    lines.append("[color=#aaa]Open slots: %d prefix / %d suffix[/color]" % [open.get("prefix", 0), open.get("suffix", 0)])
    if has_prefix:
        lines.append("\n[color=#a0c0ff]Prefix candidates[/color]")
        lines.append(_format_odds(data.get("odds_prefix", {}), data.get("names_prefix", {}), scale))
    if has_suffix:
        lines.append("\n[color=#a0c0ff]Suffix candidates[/color]")
        lines.append(_format_odds(data.get("odds_suffix", {}), data.get("names_suffix", {}), scale))
    return "\n".join(lines)


func _build_chaos_preview() -> String:
    var item: Item = bench_slot.get_item()
    if _selected_chaos_target == null:
        return "[color=#ffd700][b]Chaos - Replace[/b][/color]\n\n[color=#888]Click an affix on the item to target it for replacement.[/color]"
    var data: Dictionary = CraftingService.preview_chaos(item, _selected_chaos_target)
    var lines: PackedStringArray = []
    lines.append("[b]Chaos - Replace[/b]")
    lines.append("[color=#c0a0a0]Removing:[/color] %s" % _selected_chaos_target.get_display_text())
    lines.append("\n[color=#a0c0ff]Possible replacements (%s)[/color]" % data.get("slot_kind", "?"))
    lines.append(_format_odds(data.get("odds", {}), data.get("names", {}), 1.0))
    return "\n".join(lines)


func _build_vaal_preview() -> String:
    var item: Item = bench_slot.get_item()
    var data: Dictionary = CraftingService.preview_vaal(item)
    var lines: PackedStringArray = []
    lines.append("[color=#c43838][b]Vaal - Corrupt[/b][/color]")

    lines.append("[color=#888]One of four outcomes, 25% each. The orb decides.[/color]\n")
    for outcome_data in data.get("outcomes", []):
        lines.append("[color=#cccccc]- %s[/color]: %s" % [outcome_data["name"], outcome_data["blurb"]])
    lines.append("\n[color=#c43838]Item becomes Corrupted. No further crafting after.[/color]")
    return "\n".join(lines)











func _format_odds(odds: Dictionary, names: Dictionary, scale: float) -> String:
    if odds.is_empty():
        return "[color=#888]No candidates available[/color]"
    var ids: Array = odds.keys()
    ids.sort_custom( func(a, b): return float(odds[a]) > float(odds[b]))
    var rows: PackedStringArray = []
    rows.append("[table=2]")
    for i in ids.size():
        var aid: String = str(ids[i])
        var pct: float = float(odds[aid]) * scale
        var display: String = str(names.get(aid, aid))


        rows.append("[cell expand=1]%s[/cell][cell][right][color=#ddd]%5.1f%%[/color][/right][/cell]" % [display, pct])
    rows.append("[/table]")
    return "\n".join(rows)




func _render_confirm_button() -> void :
    if _crafting_in_flight:
        confirm_button.disabled = true
        return
    var item: Item = bench_slot.get_item()
    if item == null:
        confirm_button.text = "Select an Item to Craft"
        confirm_button.modulate = COLOR_CONFIRM_DEFAULT
        confirm_button.disabled = true
        return
    match _selected_craft:
        CraftingDefinitions.CraftType.EXALT:
            confirm_button.text = "EXALT  SLAM"
            confirm_button.modulate = COLOR_CONFIRM_DEFAULT
            confirm_button.disabled = not _can_confirm_exalt()
        CraftingDefinitions.CraftType.CHAOS:
            confirm_button.text = "CHAOS  SLAM"
            confirm_button.modulate = COLOR_CONFIRM_DEFAULT
            confirm_button.disabled = not _can_confirm_chaos()
        CraftingDefinitions.CraftType.VAAL:
            confirm_button.text = "CORRUPT  SLAM"
            confirm_button.modulate = COLOR_CONFIRM_VAAL
            confirm_button.disabled = not _can_confirm_vaal()
        _:
            confirm_button.text = "Select a Crafting Option"
            confirm_button.modulate = COLOR_CONFIRM_DEFAULT
            confirm_button.disabled = true


func _can_confirm_exalt() -> bool:
    return CraftingService.can_apply(bench_slot.get_item(), CraftingDefinitions.CraftType.EXALT).get("ok", false)


func _can_confirm_chaos() -> bool:
    if _selected_chaos_target == null:
        return false
    return CraftingService.can_apply(bench_slot.get_item(), CraftingDefinitions.CraftType.CHAOS).get("ok", false)


func _can_confirm_vaal() -> bool:
    return CraftingService.can_apply(bench_slot.get_item(), CraftingDefinitions.CraftType.VAAL).get("ok", false)




func _on_confirm_pressed() -> void :
    var item: Item = bench_slot.get_item()
    if item == null or _selected_craft < 0 or _crafting_in_flight:
        return
    _crafting_in_flight = true
    _render_confirm_button()


    _stop_all_pulses()
    var cost: int = CraftingDefinitions.get_cost_for_item(_selected_craft, item)
    var start: Vector2 = _currency_origin_global(_selected_craft)
    var end: Vector2 = _bench_global_center()
    var texture: Texture2D = _currency_texture(_selected_craft)



    var per_pip: Callable = _on_pip_arrived.bind(_selected_craft)
    CraftingJuice.fly_currency(self, start, end, texture, cost, 
        func() -> void : _apply_selected_craft(), 
        per_pip)





func _on_pip_arrived(craft_type: int) -> void :
    var button: CurrencyButton = _button_for(craft_type)
    if button == null:
        return
    button.tick_held_visual()


func _apply_selected_craft() -> void :
    var item: Item = bench_slot.get_item()
    if item == null:
        _crafting_in_flight = false
        _render_confirm_button()
        return
    var result: Dictionary = {}
    match _selected_craft:
        CraftingDefinitions.CraftType.EXALT:
            result = CraftingService.apply_exalt(item)
        CraftingDefinitions.CraftType.CHAOS:
            result = CraftingService.apply_chaos(item, _selected_chaos_target)
        CraftingDefinitions.CraftType.VAAL:
            result = CraftingService.apply_corrupt(item)
        _:
            _crafting_in_flight = false
            _render_confirm_button()
            return

    _log_result(result)
    var was_vaal: bool = _selected_craft == CraftingDefinitions.CraftType.VAAL






    var preserved_craft: int = -1 if was_vaal else _selected_craft
    _selected_chaos_target = null
    _selected_craft = preserved_craft
    _reset_button_toggles()
    if preserved_craft != -1:
        var preserved_button: CurrencyButton = _button_for(preserved_craft)
        if preserved_button != null:
            preserved_button.set_pressed_no_signal(true)
    _item_label.set_affix_clicks_enabled(preserved_craft == CraftingDefinitions.CraftType.CHAOS)

    _render_item()
    if result.get("success", false):
        CraftingJuice.slam_punch(bench_slot)
        CraftingJuice.slam_punch(_item_label)
        CraftingJuice.rarity_glow(_item_label, item.rarity, item.is_corrupted)
        CraftingJuice.particle_burst(self, _bench_global_center(), item.rarity, item.is_corrupted)
        if was_vaal:
            CraftingJuice.panel_shake(main_panel)
    _render_preview()
    _refresh_currency_buttons()
    _render_cost_panel()
    _crafting_in_flight = false
    _render_confirm_button()
    _update_pulse_state()




func _log_result(result: Dictionary) -> void :
    if not result.get("success", false):
        outcome_log.append_text("[color=#c43838]Failed: %s[/color]\n" % result.get("reason", "Failed"))
        return
    if result.has("outcome_name"):
        _log_vaal_result(result)
    elif result.has("removed"):
        var removed_inst: AffixInstance = result["removed"]
        var added_chaos: AffixInstance = result["new_affix"]
        outcome_log.append_text("[color=#a0c0ff]Chaos:[/color] removed [color=#aaa]%s[/color], rolled [color=#ffd700]%s[/color]\n" % [removed_inst.get_display_text(), added_chaos.get_display_text()])
    elif result.has("new_affix"):
        var added_exalt: AffixInstance = result["new_affix"]
        outcome_log.append_text("[color=#a0c0ff]+ Exalt:[/color] [color=#ffd700]%s[/color]  [color=#888](%s)[/color]\n" % [added_exalt.get_display_text(), result.get("slot_kind", "?")])







func _log_vaal_result(result: Dictionary) -> void :
    var fallback: String = ""
    if result.has("fallback_from"):
        fallback = "  [color=#888](fell back from Add Mod - no corruption mods for this base)[/color]"
    outcome_log.append_text("[color=#c43838]Vaal corrupts: %s[/color]%s\n" % [result["outcome_name"], fallback])
    var details: Dictionary = result.get("details", {})
    match int(result.get("outcome", -1)):
        CraftingDefinitions.CorruptOutcome.REROLL_AFFIXES:
            _log_vaal_reroll_affixes(details)
        CraftingDefinitions.CorruptOutcome.REROLL_RANGES:
            _log_vaal_reroll_ranges(details)
        CraftingDefinitions.CorruptOutcome.SHIFT_TIERS:
            _log_vaal_shift_tiers(details)
        CraftingDefinitions.CorruptOutcome.ADD_CORRUPTED_MOD:
            _log_vaal_add_mod(details)


func _log_vaal_reroll_affixes(details: Dictionary) -> void :
    var olds: Array = []
    olds.append_array(details.get("old_prefixes", []))
    olds.append_array(details.get("old_suffixes", []))
    var news: Array = []
    news.append_array(details.get("new_prefixes", []))
    news.append_array(details.get("new_suffixes", []))
    if olds.is_empty() and news.is_empty():
        outcome_log.append_text("  [color=#888]no affixes to reroll[/color]\n")
        return
    if not olds.is_empty():
        outcome_log.append_text("  [color=#888]Before:[/color]\n")
        for inst in olds:
            outcome_log.append_text("    [color=#aaa]%s[/color]\n" % inst.get_display_text())
    if not news.is_empty():
        outcome_log.append_text("  [color=#888]After:[/color]\n")
        for inst in news:
            outcome_log.append_text("    [color=#ffd700]%s[/color]\n" % inst.get_display_text())


func _log_vaal_reroll_ranges(details: Dictionary) -> void :
    var changes: Array = details.get("changes", [])
    if changes.is_empty():
        outcome_log.append_text("  [color=#888]no values to reroll[/color]\n")
        return
    for change in changes:
        var inst: AffixInstance = change["affix"]



        var before_text: String = _format_affix_with_value(inst, change["old_value"], inst.tier_level)
        var after_text: String = inst.get_display_text()
        outcome_log.append_text("  [color=#aaa]%s[/color] → [color=#ffd700]%s[/color]\n" % [before_text, after_text])


func _log_vaal_shift_tiers(details: Dictionary) -> void :
    var changes: Array = details.get("changes", [])
    if changes.is_empty():
        outcome_log.append_text("  [color=#888]no affixes to shift[/color]\n")
        return
    for change in changes:
        var inst: AffixInstance = change["affix"]
        var before_text: String = _format_affix_with_value(inst, change["old_value"], change["old_tier"])
        var after_text: String = inst.get_display_text()
        var clamp_note: String = ""
        if int(change["old_tier"]) == int(change["new_tier"]):
            clamp_note = "  [color=#888](tier clamped — only value rerolled)[/color]"
        outcome_log.append_text("  [color=#aaa]%s[/color] → [color=#ffd700]%s[/color]%s\n" % [before_text, after_text, clamp_note])


func _log_vaal_add_mod(details: Dictionary) -> void :
    var added: AffixInstance = details.get("added")
    if added == null:


        outcome_log.append_text("  [color=#888]%s[/color]\n" % details.get("reason", "nothing added"))
        return


    outcome_log.append_text("  [color=#c43838]+ %s[/color]  [color=#888](corrupted)[/color]\n" % added.get_display_text())





func _format_affix_with_value(affix: AffixInstance, value: Variant, tier: int) -> String:
    if affix == null or affix.affix_base == null:
        return "?"
    var temp: = AffixInstance.new(affix.affix_base, value, tier)
    return temp.get_display_text()


func _clear_outcome_log() -> void :
    outcome_log.clear()




func _currency_origin_global(craft_type: int) -> Vector2:
    match craft_type:
        CraftingDefinitions.CraftType.EXALT:
            return exalt_button.global_position + exalt_button.size * 0.5
        CraftingDefinitions.CraftType.CHAOS:
            return chaos_button.global_position + chaos_button.size * 0.5
        CraftingDefinitions.CraftType.VAAL:
            return _vaal_inventory_global()
    return global_position




func _vaal_inventory_global() -> Vector2:
    var grid: Node = get_tree().current_scene.find_child("InventoryGrid", true, false)
    for stash_item in GameState.guild_stash:
        if stash_item and stash_item.base_item and stash_item.base_item.item_id == "vaal_orb":
            if grid != null and grid is Control and "cell_size" in grid:
                var cell: int = int(grid.cell_size)
                var origin: Vector2 = (grid as Control).global_position
                var pos: Vector2i = stash_item.stash_position
                if pos != Vector2i(-1, -1):
                    return origin + Vector2(
                        (pos.x + stash_item.base_item.grid_width * 0.5) * cell, 
                        (pos.y + stash_item.base_item.grid_height * 0.5) * cell, 
                    )
            break
    return vaal_button.global_position + vaal_button.size * 0.5


func _currency_texture(craft_type: int) -> Texture2D:
    match craft_type:
        CraftingDefinitions.CraftType.EXALT:
            return ExaltTexture
        CraftingDefinitions.CraftType.CHAOS:
            return ChaosTexture
        CraftingDefinitions.CraftType.VAAL:
            return VaalTexture
    return null


func _bench_global_center() -> Vector2:
    return bench_slot.global_position + bench_slot.size * 0.5


func _button_for(craft_type: int) -> CurrencyButton:
    match craft_type:
        CraftingDefinitions.CraftType.EXALT:
            return exalt_button
        CraftingDefinitions.CraftType.CHAOS:
            return chaos_button
        CraftingDefinitions.CraftType.VAAL:
            return vaal_button
    return null















func _update_pulse_state() -> void :
    if _crafting_in_flight or not visible:
        _stop_all_pulses()
        return
    var has_item: bool = bench_slot.get_item() != null
    if not has_item:

        bench_glowify.start()
        exalt_glowify.stop()
        chaos_glowify.stop()
        vaal_glowify.stop()
        confirm_glowify.stop()
        _stop_affix_throb()
        return

    bench_glowify.stop()
    if _selected_craft < 0:

        _pulse_if_enabled(exalt_button, exalt_glowify)
        _pulse_if_enabled(chaos_button, chaos_glowify)
        _pulse_if_enabled(vaal_button, vaal_glowify)
        confirm_glowify.stop()
        _stop_affix_throb()
        return

    exalt_glowify.stop()
    chaos_glowify.stop()
    vaal_glowify.stop()
    var chaos_needs_target: bool = _selected_craft == CraftingDefinitions.CraftType.CHAOS\
and _selected_chaos_target == null
    if chaos_needs_target:



        if _affix_throb != null and _affix_throb.target != null and _affix_throb.target.visible:
            _affix_throb.start()
        confirm_glowify.stop()
        return



    _stop_affix_throb()
    if not confirm_button.disabled:
        var base: Color = COLOR_CONFIRM_VAAL if _selected_craft == CraftingDefinitions.CraftType.VAAL else COLOR_CONFIRM_DEFAULT
        confirm_glowify.set_base_color(base)
        confirm_glowify.start()
    else:
        confirm_glowify.stop()

        _render_confirm_button()


func _pulse_if_enabled(button: CurrencyButton, glowify: GlowifyNode) -> void :
    if button.disabled:
        glowify.stop()
    else:
        glowify.start()


func _stop_affix_throb() -> void :
    if _affix_throb != null:
        _affix_throb.stop()


func _stop_all_pulses() -> void :
    bench_glowify.stop()
    exalt_glowify.stop()
    chaos_glowify.stop()
    vaal_glowify.stop()
    confirm_glowify.stop()
    _stop_affix_throb()
