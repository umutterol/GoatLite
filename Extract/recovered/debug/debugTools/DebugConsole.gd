














extends CanvasLayer

const CHEATS_FEATURE: String = "cheats"



var panel: PanelContainer
var output_label: RichTextLabel
var input_field: LineEdit


var commands: Dictionary = {}


var command_history: Array[String] = []
var history_index: int = -1
const MAX_OUTPUT_LINES = 200





var _item_generator: ItemGenerator = null


func _ready():


    if not _cheats_enabled():
        queue_free()
        return

    layer = 100
    _build_ui()
    _register_commands()
    panel.hide()









func _cheats_enabled() -> bool:
    if not OS.is_debug_build():
        return false
    return OS.has_feature("editor") or OS.has_feature(CHEATS_FEATURE)






func _input(event: InputEvent):
    if not _cheats_enabled():
        return

    if event is InputEventKey and event.pressed and event.physical_keycode == KEY_QUOTELEFT:
        _toggle()
        get_viewport().set_input_as_handled()
        return







    if panel.visible and event is InputEventKey and event.pressed:
        if not input_field.has_focus():
            input_field.grab_focus()




        match event.keycode:
            KEY_UP:
                _history_prev()
                get_viewport().set_input_as_handled()
            KEY_DOWN:
                _history_next()
                get_viewport().set_input_as_handled()
            KEY_ESCAPE:
                _toggle()
                get_viewport().set_input_as_handled()






func _register_commands():
    commands["help"] = _cmd_help
    commands["clear"] = _cmd_clear
    commands["exiles"] = _cmd_exiles
    commands["morale"] = _cmd_morale
    commands["damage"] = _cmd_damage
    commands["kill"] = _cmd_kill
    commands["heal"] = _cmd_heal
    commands["level"] = _cmd_level
    commands["xp"] = _cmd_xp
    commands["gold"] = _cmd_gold
    commands["food"] = _cmd_food
    commands["exalt"] = _cmd_exalt
    commands["additem"] = _cmd_additem
    commands["stats"] = _cmd_stats
    commands["recalc"] = _cmd_recalc
    commands["status"] = _cmd_status
    commands["unstuck"] = _cmd_unstuck
    commands["aoe"] = _cmd_aoe
    commands["lost"] = _cmd_lost
    commands["captives"] = _cmd_captives
    commands["force_long_lost"] = _cmd_force_long_lost
    commands["roll_long_lost"] = _cmd_roll_long_lost
    commands["force_capture"] = _cmd_force_capture






func _cmd_help(_args: Array):
    log_info("[b]── Debug Console Commands ──[/b]")
    log_info("  [b]help[/b]              — show this list")
    log_info("  [b]clear[/b]             — clear output")
    log_info("  [b]exiles[/b]            — list all exiles (index, name, class, level)")
    log_info("  [b]stats[/b] <index>     — show detailed stats for an exile")
    log_info("  [b]morale[/b] <index> <amount> — change morale (negative to reduce)")
    log_info("  [b]damage[/b] <index> <amount> — damage exile life")
    log_info("  [b]kill[/b] <index>      — instantly kill an exile (triggers DeathReport)")
    log_info("  [b]heal[/b] <index>      — fully heal life and vitality")
    log_info("  [b]level[/b] <index>     — grant one level-up")
    log_info("  [b]xp[/b] <index> <amount> — grant experience")
    log_info("  [b]gold[/b] <amount>     — add/remove chaos shards")
    log_info("  [b]food[/b] <amount>     — add/remove food")
    log_info("  [b]exalt[/b] <amount>    — add/remove exalted orbs")
    log_info("  [b]additem[/b] <item_id> [common|uncommon|rare] — spawn item into guild stash")
    log_info("  [b]recalc[/b] <index>    — force stat recalculation")
    log_info("  [b]status[/b] <index>    — show lifecycle status + vitals for an exile")
    log_info("  [b]unstuck[/b] <index>   — force status to 'recovering' (use to fix stuck captured/on_mission)")
    log_info("  [b]aoe[/b] [on|off]      — toggle AoE hit-radius debug overlay in combat playback")
    log_info("  [b]lost[/b]              — list every lost / long_lost exile across all areas")
    log_info("  [b]captives[/b] <area_index> — dump captured + long_lost rosters for one area (0=Coast, 1=Mud Flats...)")
    log_info("  [b]force_long_lost[/b] <index> [area_index=0] [days_ago=7] — drop exile into the long_lost pool")
    log_info("  [b]roll_long_lost[/b]    — bypass chance + immediately roll the global long-lost rescue spawn")
    log_info("  [b]force_capture[/b] <index> [area_index=0] — flip exile to lost + spawn fresh rescue mission")
    log_info("")
    log_info("  [color=gray]<index> = exile position from 'exiles' list (0, 1, 2...)[/color]")


func _cmd_clear(_args: Array):
    output_label.text = ""


func _cmd_exiles(_args: Array):
    var all = GameState.get_all_exiles()
    if all.is_empty():
        log_warn("No exiles in roster.")
        return
    for i in range(all.size()):
        var e = all[i]
        log_info("[b]%d[/b] — %s | %s | Lv %d | [%s] | Life %.0f/%.0f | Morale %.0f/%.0f" % [
            i, e.name, e.get_class_name(), e.level, e.status, 
            e.current_life, e.current_stats.life, 
            e.current_morale, e.current_stats.max_morale, 
        ])


func _cmd_status(args: Array):
    var exile = _parse_exile(args, 0)
    if not exile:
        return
    log_info("[b]%s[/b] status: [%s]  (Life %.0f/%.0f  Vit %.0f/%.0f)" % [
        exile.name, exile.status, 
        exile.current_life, exile.current_stats.life, 
        exile.current_vitality, exile.current_stats.vitality, 
    ])






func _cmd_unstuck(args: Array):
    var exile = _parse_exile(args, 0)
    if not exile:
        return
    if exile.status == "dead":
        log_err("%s is dead. unstuck refuses to revive." % exile.name)
        return
    var prev: String = exile.status
    exile.status = "recovering"
    exile.current_vitality = exile.current_stats.vitality
    GameState.exile_updated.emit(exile)
    log_info("%s status: %s → recovering. Vitality restored; EOD will heal." % [exile.name, prev])


func _cmd_morale(args: Array):
    var exile = _parse_exile(args, 0)
    if not exile:
        return
    var amount = _parse_float(args, 1)
    if amount == null:
        log_err("Usage: morale <index> <amount>")
        return
    var before = exile.current_morale
    MoraleManager.apply_custom_event(exile, amount, "debug console")
    log_info("%s morale: %.1f → %.1f" % [exile.name, before, exile.current_morale])


func _cmd_damage(args: Array):
    var exile = _parse_exile(args, 0)
    if not exile:
        return
    var amount = _parse_float(args, 1)
    if amount == null:
        log_err("Usage: damage <index> <amount>")
        return
    var before = exile.current_life
    exile.current_life = max(0.0, exile.current_life - amount)
    exile.current_stats.current_life = exile.current_life
    log_info("%s life: %.0f → %.0f" % [exile.name, before, exile.current_life])


func _cmd_kill(args: Array):
    var exile = _parse_exile(args, 0)
    if not exile:
        return
    if exile.status == "dead":
        log_warn("%s is already dead." % exile.name)
        return
    log_info("Killing %s." % exile.name)

    GameState.mark_exile_dead(exile.id)


func _cmd_heal(args: Array):
    var exile = _parse_exile(args, 0)
    if not exile:
        return
    exile.current_life = exile.current_stats.life
    exile.current_stats.current_life = exile.current_life
    exile.current_vitality = exile.current_stats.vitality
    exile.current_stats.current_vitality = exile.current_vitality
    log_info("%s fully healed. Life: %.0f  Vitality: %.0f" % [
        exile.name, exile.current_life, exile.current_vitality
    ])


func _cmd_level(args: Array):
    var exile = _parse_exile(args, 0)
    if not exile:
        return
    exile.level += 1
    exile.pending_passive_points += GameSettings.PASSIVE_POINTS_PER_LEVEL



    LevelUpSystem.queue_level_up(exile)
    LevelUpSystem.resolve_pending_growth(exile)
    ExileGenerator.recalculate_stats(exile)
    log_info("%s levelled up to %d." % [exile.name, exile.level])


func _cmd_xp(args: Array):
    var exile = _parse_exile(args, 0)
    if not exile:
        return
    var amount = _parse_float(args, 1)
    if amount == null:
        log_err("Usage: xp <index> <amount>")
        return
    exile.experience += int(amount)
    log_info("%s gained %d XP. Total: %d / %d" % [
        exile.name, int(amount), exile.experience, exile.get_exp_for_next_level()
    ])


func _cmd_gold(args: Array):
    var amount = _parse_float(args, 0)
    if amount == null:
        log_err("Usage: gold <amount>")
        return
    GameState.add_chaos(int(amount))
    log_info("Chaos shards: %d" % GameState.chaos)


func _cmd_food(args: Array):
    var amount = _parse_float(args, 0)
    if amount == null:
        log_err("Usage: food <amount>")
        return
    GameState.add_food(int(amount))
    log_info("Food: %d" % GameState.food)


func _cmd_exalt(args: Array):
    var amount = _parse_float(args, 0)
    if amount == null:
        log_err("Usage: exalt <amount>")
        return
    GameState.add_exalt(int(amount))
    log_info("Exalted orbs: %d" % GameState.exalt)








func _cmd_additem(args: Array):
    if args.is_empty():
        log_err("Usage: additem <item_id> [common|uncommon|rare]")
        return
    var item_id: String = args[0].to_lower()
    var rarity: int = _parse_rarity_arg(args, 1)

    if rarity < 0:
        return

    _ensure_item_generator()
    var base: ItemBase = _find_item_base_by_id(item_id)
    if base == null:
        log_err("No item base with id '%s'." % item_id)
        _suggest_item_ids(item_id)
        return

    var item: Item = _item_generator.generate_item_with_rarity(1, rarity, base)
    if item == null:
        log_err("Item generation failed for '%s'." % item_id)
        return
    GameState.add_item_to_stash(item)
    log_info("Spawned [b]%s[/b] (%s, %d affixes) into guild stash." % [
        item.get_display_name(), Item.Rarity.keys()[rarity], item.get_affix_count(), 
    ])




func _ensure_item_generator() -> void :
    if _item_generator != null:
        return
    _item_generator = ItemGenerator.new()
    _item_generator.load_item_bases()


func _find_item_base_by_id(item_id: String) -> ItemBase:
    for base in _item_generator.item_bases:
        if base != null and base.item_id == item_id:
            return base
    return null




func _suggest_item_ids(partial: String) -> void :
    var matches: Array[String] = []
    for base in _item_generator.item_bases:
        if base == null:
            continue
        if base.item_id.contains(partial):
            matches.append(base.item_id)
        if matches.size() >= 5:
            break
    if matches.is_empty():
        log_warn("No close matches found. There are %d item bases loaded." % _item_generator.item_bases.size())
        return
    log_warn("Did you mean: %s" % ", ".join(matches))


func _cmd_stats(args: Array):
    var exile = _parse_exile(args, 0)
    if not exile:
        return
    var s = exile.current_stats
    log_info("[b]── %s (%s Lv%d) ──[/b]" % [exile.name, exile.get_class_name(), exile.level])
    log_info("  Life: %.0f / %.0f  |  Vitality: %.0f / %.0f  |  Morale: %.0f / %.0f" % [
        exile.current_life, s.life, exile.current_vitality, s.vitality, exile.current_morale, s.max_morale
    ])
    log_info("  Armour: %.0f  |  Evasion: %.1f%%  |  Block: %.1f%% (%.0f)" % [
        s.armour, s.evasion, s.block_chance, s.block_amount
    ])
    log_info("  Phys Dmg: %.0f–%.0f  |  ASpd: %.2f  |  Crit: %.1f%% (x%.1f)" % [
        s.physical_damage.x, s.physical_damage.y, s.attack_speed, s.critical_chance, s.critical_multiplier
    ])
    log_info("  Res — Fire: %.0f  Cold: %.0f  Light: %.0f  Chaos: %.0f" % [
        s.fire_resistance, s.cold_resistance, s.lightning_resistance, s.chaos_resistance
    ])


func _cmd_recalc(args: Array):
    var exile = _parse_exile(args, 0)
    if not exile:
        return
    ExileGenerator.recalculate_stats(exile)
    log_info("%s stats recalculated." % exile.name)










func _cmd_lost(_args: Array):
    var any: bool = false
    for area_enum_value: int in WorldEnum.AREAS.values():
        var area_id: WorldEnum.AREAS = area_enum_value as WorldEnum.AREAS
        var progress: AreaProgress = AreaManager.get_area_progress(area_id)
        if progress == null:
            continue
        var area_name: String = WorldEnum.AREAS.keys()[area_id]
        for exile_id in progress.captured_exile_ids:
            var exile: ExileData = GameState.get_exile_by_id(exile_id)
            if exile == null:
                continue
            any = true
            log_info("  [color=#f9a]LOST[/color]      | %s (Lv %d %s) — %s — rescue active" % [
                exile.name, exile.level, exile.get_class_name(), area_name, 
            ])
        for exile_id in progress.long_lost_exile_ids:
            var exile: ExileData = GameState.get_exile_by_id(exile_id)
            if exile == null:
                continue
            any = true
            var lost_day: int = -1
            if exile.lifecycle != null:
                lost_day = exile.lifecycle.lost_day
            var days_since: int = (
                GameState.current_day - lost_day if lost_day >= 0 else -1
            )
            log_info("  [color=#caa]LONG-LOST[/color] | %s (Lv %d %s) — %s — lost since day %d (%d days ago)" % [
                exile.name, exile.level, exile.get_class_name(), area_name, lost_day, days_since, 
            ])
    if not any:
        log_warn("No lost or long-lost exiles.")





func _cmd_captives(args: Array):
    if args.is_empty():
        log_err("Usage: captives <area_index>  (0=Coast, 1=Mud Flats, ...)")
        return
    var area_index: int = int(args[0])
    var keys: Array = WorldEnum.AREAS.keys()
    if area_index < 0 or area_index >= keys.size():
        log_err("Area index %d out of range (0..%d)." % [area_index, keys.size() - 1])
        return
    var area_id: WorldEnum.AREAS = area_index as WorldEnum.AREAS
    var progress: AreaProgress = AreaManager.get_area_progress(area_id)
    if progress == null:
        log_err("No AreaProgress for %s." % keys[area_index])
        return
    log_info("[b]── %s ──[/b]" % keys[area_index])
    log_info("  captured_exile_ids:  %s" % str(progress.captured_exile_ids))
    log_info("  long_lost_exile_ids: %s" % str(progress.long_lost_exile_ids))
    log_info("  active_opportunities (instances):")
    if progress.active_opportunities.is_empty():
        log_info("    (none)")
    else:
        for instance_id in progress.active_opportunities.keys():
            var raw: Variant = progress.active_opportunities[instance_id]
            if raw is OpportunityInstance:
                var inst: OpportunityInstance = raw
                log_info("    %s  template=%s  appeared=day %d  override_timeout=%d  context=%s" % [
                    inst.instance_id, inst.template_mission_id, 
                    inst.day_appeared, inst.timeout_days_override, str(inst.context), 
                ])
            else:
                log_info("    %s  (legacy v2 entry: %s)" % [str(instance_id), str(raw)])







func _cmd_force_long_lost(args: Array):
    var exile: ExileData = _parse_exile(args, 0)
    if not exile:
        return
    var area_index: int = int(args[1]) if args.size() > 1 else 0
    var days_ago: int = int(args[2]) if args.size() > 2 else GameSettings.LONG_LOST_ELIGIBILITY_DAYS
    var keys: Array = WorldEnum.AREAS.keys()
    if area_index < 0 or area_index >= keys.size():
        log_err("Area index %d out of range (0..%d)." % [area_index, keys.size() - 1])
        return
    var area_id: WorldEnum.AREAS = area_index as WorldEnum.AREAS
    var progress: AreaProgress = AreaManager.get_area_progress(area_id)
    if progress == null:
        log_err("No AreaProgress for %s." % keys[area_index])
        return

    exile.status = "long_lost"
    if exile.lifecycle == null:
        exile.lifecycle = ExileLifecycleState.new()
    exile.lifecycle.lost_day = GameState.current_day - days_ago
    exile.equipped_items.clear()
    progress.captured_exile_ids.erase(exile.id)
    if not progress.long_lost_exile_ids.has(exile.id):
        progress.long_lost_exile_ids.append(exile.id)
    GameState.exile_updated.emit(exile)
    log_info("%s → long_lost in %s. lost_day = %d (%d days ago). Gear stripped." % [
        exile.name, keys[area_index], exile.lifecycle.lost_day, days_ago, 
    ])






func _cmd_force_capture(args: Array):
    var exile: ExileData = _parse_exile(args, 0)
    if not exile:
        return
    var area_index: int = int(args[1]) if args.size() > 1 else 0
    var keys: Array = WorldEnum.AREAS.keys()
    if area_index < 0 or area_index >= keys.size():
        log_err("Area index %d out of range (0..%d)." % [area_index, keys.size() - 1])
        return
    var area_id: WorldEnum.AREAS = area_index as WorldEnum.AREAS
    var progress: AreaProgress = AreaManager.get_area_progress(area_id)
    if progress == null:
        log_err("No AreaProgress for %s." % keys[area_index])
        return
    if exile.status == "dead":
        log_err("%s is dead. Can't capture a corpse." % exile.name)
        return

    exile.status = "lost"
    if not progress.captured_exile_ids.has(exile.id):
        progress.captured_exile_ids.append(exile.id)


    var instance: OpportunityInstance = MissionManager._spawn_rescue_instance(
        area_id, progress, exile, "fresh", GameSettings.RESCUE_TIMEOUT_DAYS_DEFAULT
    )
    GameState.exile_updated.emit(exile)
    GameState.exile_lost.emit(exile, area_id)
    if instance != null:
        log_info("%s captured in %s. Rescue instance %s spawned (level %d, %d-day timeout)." % [
            exile.name, keys[area_index], instance.instance_id, 
            instance.runtime_mission_data.level if instance.runtime_mission_data else MissionManager.get_mission_by_id(instance.template_mission_id).level, 
            instance.get_effective_timeout_days(MissionManager.get_mission_by_id(instance.template_mission_id)), 
        ])
    else:
        log_warn("%s status flipped to 'lost' but rescue spawn failed (no rescue template for area?)." % exile.name)





func _cmd_roll_long_lost(_args: Array):


    MissionManager.try_roll_long_lost_rescue(10000.0)
    log_info("Forced long-lost roll. Check active rescues with: captives <area_index>")


func _cmd_aoe(args: Array):
    if args.is_empty():
        CombatPlaybackScreen.debug_draw_aoe_outline = not CombatPlaybackScreen.debug_draw_aoe_outline
    else:
        var arg: String = args[0].to_lower()
        match arg:
            "on", "true", "1":
                CombatPlaybackScreen.debug_draw_aoe_outline = true
            "off", "false", "0":
                CombatPlaybackScreen.debug_draw_aoe_outline = false
            _:
                log_err("Usage: aoe [on|off]  (bare 'aoe' toggles)")
                return
    log_info("AoE debug overlay: %s" % ("ON" if CombatPlaybackScreen.debug_draw_aoe_outline else "OFF"))







func _parse_exile(args: Array, arg_index: int) -> ExileData:
    if arg_index >= args.size():
        log_err("Missing exile index. Use 'exiles' to list them.")
        return null
    if not args[arg_index].is_valid_int():
        log_err("'%s' is not a valid index." % args[arg_index])
        return null
    var idx = args[arg_index].to_int()
    var all = GameState.get_all_exiles()
    if idx < 0 or idx >= all.size():
        log_err("Index %d out of range (0–%d)." % [idx, all.size() - 1])
        return null
    return all[idx]


func _parse_float(args: Array, arg_index: int):
    if arg_index >= args.size():
        return null
    if not args[arg_index].is_valid_float():
        log_err("'%s' is not a valid number." % args[arg_index])
        return null
    return args[arg_index].to_float()







func _parse_rarity_arg(args: Array, arg_index: int) -> int:
    if arg_index >= args.size():
        return Item.Rarity.COMMON
    var raw: String = args[arg_index].to_lower()
    match raw:
        "c", "common":
            return Item.Rarity.COMMON
        "u", "uncommon", "magic":
            return Item.Rarity.UNCOMMON
        "r", "rare":
            return Item.Rarity.RARE
        _:
            log_err("Unknown rarity '%s'. Use: common, uncommon, rare." % raw)
            return -1






func log_info(text: String):
    _append(text)

func log_warn(text: String):
    _append("[color=yellow]%s[/color]" % text)

func log_err(text: String):
    _append("[color=red]%s[/color]" % text)

func _append(bbcode: String):
    output_label.append_text(bbcode + "\n")

    while output_label.get_line_count() > MAX_OUTPUT_LINES:
        output_label.remove_paragraph(0)






func _execute(raw_text: String):
    var trimmed = raw_text.strip_edges()
    if trimmed.is_empty():
        return


    command_history.push_front(trimmed)
    if command_history.size() > 50:
        command_history.resize(50)
    history_index = -1


    _append("[color=gray]> %s[/color]" % trimmed)


    var parts = trimmed.split(" ", false)
    var cmd_name = parts[0].to_lower()
    var args = parts.slice(1)

    if commands.has(cmd_name):
        commands[cmd_name].call(args)
    else:
        log_err("Unknown command: '%s'. Type 'help' for a list." % cmd_name)






func _history_prev():
    if command_history.is_empty():
        return
    history_index = min(history_index + 1, command_history.size() - 1)
    input_field.text = command_history[history_index]
    input_field.caret_column = input_field.text.length()

func _history_next():
    if history_index <= 0:
        history_index = -1
        input_field.text = ""
        return
    history_index -= 1
    input_field.text = command_history[history_index]
    input_field.caret_column = input_field.text.length()






func _build_ui():

    panel = PanelContainer.new()
    panel.anchor_left = 0.5
    panel.anchor_top = 0.4
    panel.anchor_right = 1.0
    panel.anchor_bottom = 1.0
    panel.offset_left = -10.0
    panel.offset_top = -10.0
    panel.offset_right = -10.0
    panel.offset_bottom = -10.0

    var style = StyleBoxFlat.new()
    style.bg_color = Color(0.05, 0.05, 0.08, 0.92)
    style.border_color = Color(0.3, 0.3, 0.35)
    style.set_border_width_all(1)
    style.set_corner_radius_all(4)
    style.set_content_margin_all(8)
    panel.add_theme_stylebox_override("panel", style)

    var vbox = VBoxContainer.new()
    vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL


    var header = HBoxContainer.new()
    var title = Label.new()
    title.text = "Debug Console (`)"
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
    header.add_child(title)
    vbox.add_child(header)


    var sep = HSeparator.new()
    vbox.add_child(sep)


    output_label = RichTextLabel.new()
    output_label.bbcode_enabled = true
    output_label.scroll_following = true
    output_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
    output_label.add_theme_color_override("default_color", Color(0.85, 0.85, 0.85))
    vbox.add_child(output_label)


    input_field = LineEdit.new()
    input_field.placeholder_text = "Type a command... (try 'help')"
    input_field.text_submitted.connect(_on_text_submitted)

    var input_style = StyleBoxFlat.new()
    input_style.bg_color = Color(0.08, 0.08, 0.1, 1.0)
    input_style.border_color = Color(0.3, 0.3, 0.35)
    input_style.set_border_width_all(1)
    input_style.set_corner_radius_all(2)
    input_style.set_content_margin_all(4)
    input_field.add_theme_stylebox_override("normal", input_style)
    vbox.add_child(input_field)

    panel.add_child(vbox)
    add_child(panel)


func _on_text_submitted(text: String):
    _execute(text)
    input_field.clear()


func _toggle():
    panel.visible = not panel.visible
    if panel.visible:
        input_field.grab_focus()
