class_name CombatLogFormatter
extends RefCounted





















static func format_event(event: CombatEvent, combatants: Array, opts: Dictionary = {}) -> String:
    if not event:
        return ""
    var t: String = "%.1fs" % event.tick
    match event.event_type:
        CombatEnums.CombatEventType.COMBAT_START:
            var ec: int = event.data.get("exile_count", 0)
            var mc: int = event.data.get("monster_count", 0)
            return "[color=#8ad][%s] Combat begins - %d exile(s) vs %d enemy(ies)[/color]" % [t, ec, mc]

        CombatEnums.CombatEventType.COMBAT_END:
            return _format_combat_end(event, t)

        CombatEnums.CombatEventType.DECISION_POINT:
            var reason: String = event.data.get("reason", "")
            return "[color=#ec5][%s] Decision point - %s[/color]" % [t, reason]

        CombatEnums.CombatEventType.SECOND_WIND:
            var who: String = _name(combatants, event.data.get("combatant_id", -1))
            var healed: float = event.data.get("healed_amount", 0.0)
            return "[color=#7f7][%s] %s catches a second wind! (+%.0f life)[/color]" % [t, who, healed]

        CombatEnums.CombatEventType.LEVEL_UP:
            var who2: String = _name(combatants, event.data.get("combatant_id", -1))
            var new_level: int = event.data.get("new_level", 0)
            return "[color=#fc5][%s] %s - LEVEL UP! Now level %d[/color]" % [t, who2, new_level]

        CombatEnums.CombatEventType.DAMAGE_DEALT:
            return _format_damage_dealt(event, combatants, t, opts)

        CombatEnums.CombatEventType.DEATH:
            var victim: String = _name(combatants, event.data.get("combatant_id", -1))
            var death_source: String = event.data.get("source", "")



            if death_source == "desperation_drain":
                return "[color=gray][%s][/color] [color=#e88]%s collapsed from Desperation[/color]" % [t, victim]




            if death_source == "ignite_dot":
                var burner: String = _name(combatants, event.data.get("killer_id", -1))
                return "[color=gray][%s][/color] [color=#ec6]%s was burned to death by %s[/color]" % [t, victim, burner]
            if death_source == "poison_dot":
                var poisoner: String = _name(combatants, event.data.get("killer_id", -1))
                return "[color=gray][%s][/color] [color=#9d4]%s succumbed to poison from %s[/color]" % [t, victim, poisoner]
            var killer: String = _name(combatants, event.data.get("killer_id", -1))
            return "[color=gray][%s][/color] [color=red]%s killed by %s[/color]" % [t, victim, killer]

        CombatEnums.CombatEventType.DOWNED:
            var fallen: String = _name(combatants, event.data.get("combatant_id", -1))
            var downed_source: String = event.data.get("source", "")


            if downed_source == "desperation_drain":
                return "[color=gray][%s][/color] [color=#e88]%s collapsed from Desperation[/color]" % [t, fallen]

            if downed_source == "ignite_dot":
                var burner_d: String = _name(combatants, event.data.get("killer_id", -1))
                return "[color=gray][%s][/color] [color=#ec6]%s burned down - applied by %s[/color]" % [t, fallen, burner_d]
            if downed_source == "poison_dot":
                var poisoner_d: String = _name(combatants, event.data.get("killer_id", -1))
                return "[color=gray][%s][/color] [color=#9d4]%s poisoned to ground - applied by %s[/color]" % [t, fallen, poisoner_d]
            return "[color=gray][%s][/color] [color=orange]%s went down[/color]" % [t, fallen]

        CombatEnums.CombatEventType.EVASION:


            var att: String = _name(combatants, event.data.get("attacker_id", -1))
            var def: String = _name(combatants, event.data.get("defender_id", -1))
            return "[color=#888][%s] %s evaded %s's attack[/color]" % [t, def, att]

        CombatEnums.CombatEventType.BLOCK:


            var atk: String = _name(combatants, event.data.get("attacker_id", -1))
            var dfn: String = _name(combatants, event.data.get("defender_id", -1))
            var amt: float = event.data.get("blocked_amount", 0.0)
            return "[color=#888][%s] %s blocked %.0f from %s[/color]" % [t, dfn, amt, atk]

        CombatEnums.CombatEventType.MORALE_PENALTY:
            return _format_morale_penalty(event, combatants, t)

        CombatEnums.CombatEventType.OVERTIME_BEGAN:





            return "[color=#ec5][%s] [b]Overtime - Desperation sets in.[/b][/color]" % t

        CombatEnums.CombatEventType.DESPERATION_INCREASED:
            return _format_desperation_increased(event, t)

        CombatEnums.CombatEventType.STATUS_EFFECT_APPLIED:





            if event.data.get("inline_with_hit", false):
                return ""
            var who: String = _name(combatants, event.data.get("combatant_id", -1))
            var nice_name: String = _effect_display_name(event.data)
            var stacks: int = int(event.data.get("stacks", 1))
            var stack_chunk: String = " (%d stacks)" % stacks if stacks > 1 else ""
            var detail_chunk: String = _format_effect_details(event.data)
            return "[color=#c9a][%s] %s gained [b]%s[/b]%s%s[/color]" % [t, who, nice_name, stack_chunk, detail_chunk]

        CombatEnums.CombatEventType.STATUS_EFFECT_EXPIRED:
            var fader: String = _name(combatants, event.data.get("combatant_id", -1))



            var expired_nice: String = _effect_display_name(event.data)
            return "[color=#888][%s] %s's [b]%s[/b] wore off[/color]" % [t, fader, expired_nice]

        CombatEnums.CombatEventType.IMPALE_APPLIED:




            if event.data.get("inline_with_hit", false):
                return ""
            var atk_i: String = _name(combatants, event.data.get("attacker_id", -1))
            var def_i: String = _name(combatants, event.data.get("defender_id", -1))
            var flat: float = float(event.data.get("flat_damage", 0.0))
            var stacks_now: int = int(event.data.get("stacks_now", 0))


            var stacks_added: int = int(event.data.get("stacks_added", 1))
            var max_s: int = int(event.data.get("max_stacks", 0))
            var phys: float = float(event.data.get("phys_dealt", 0.0))
            var capt: float = float(event.data.get("capture_pct", 0.0))
            var verb: String = "impales" if stacks_added == 1 else "impales x%d" % stacks_added
            return "[color=#c97][%s] %s %s %s (%d/%d) - %.1f from %.0f phys x %.0f%%[/color]" % [
                t, atk_i, verb, def_i, stacks_now, max_s, flat, phys, capt, 
            ]

        CombatEnums.CombatEventType.IMPALE_CONSUMED:


            if event.data.get("inline_with_hit", false):
                return ""
            var def_c: String = _name(combatants, event.data.get("defender_id", -1))
            var count: int = int(event.data.get("stacks_consumed", 0))
            var total_flat: float = float(event.data.get("total_flat", 0.0))
            var plural: String = "impale" if count == 1 else "impales"
            return "[color=#c97][%s] %s's %d %s burst (+%.0f elemental)[/color]" % [
                t, def_c, count, plural, total_flat, 
            ]

        CombatEnums.CombatEventType.POISON_APPLIED:



            if event.data.get("inline_with_hit", false):
                return ""
            var atk_p: String = _name(combatants, event.data.get("attacker_id", -1))
            var def_p: String = _name(combatants, event.data.get("defender_id", -1))
            var dps: float = float(event.data.get("damage_per_sec", 0.0))
            var stacks_now_p: int = int(event.data.get("stacks_now", 0))
            var stacks_added_p: int = int(event.data.get("stacks_added", 1))
            var dur_p: float = float(event.data.get("duration_seconds", 0.0))
            var verb_p: String = "poisons" if stacks_added_p == 1 else "poisons x%d" % stacks_added_p
            return "[color=#7c5][%s] %s %s %s for %.1f chaos dmg/s (%.1fs, %d stacks)[/color]" % [
                t, atk_p, verb_p, def_p, dps, dur_p, stacks_now_p, 
            ]

        CombatEnums.CombatEventType.POISON_EXPIRED:




            return ""

        CombatEnums.CombatEventType.AILMENT_ROLL:
            return _format_ailment_roll(event, combatants, t)

        CombatEnums.CombatEventType.ABILITY_EXECUTED:



            var ability_ref: MonsterAbility = event.data.get("ability")
            if ability_ref == null or ability_ref.ability_id == "basic_attack":
                return ""
            var actor: String = _name(combatants, event.data.get("actor_id", -1))
            return "[color=#fa5][%s] %s uses [b]%s[/b][/color]" % [t, actor, ability_ref.display_name]

        _:
            return ""















static func format_breakdown_bbcode(event: CombatEvent) -> String:
    if not event:
        return ""
    match event.event_type:
        CombatEnums.CombatEventType.DAMAGE_DEALT:
            return _format_damage_breakdown(event)
        CombatEnums.CombatEventType.IMPALE_APPLIED:
            return _format_impale_applied_breakdown(event)
        CombatEnums.CombatEventType.IMPALE_CONSUMED:
            return _format_impale_consumed_breakdown(event)
        CombatEnums.CombatEventType.STATUS_EFFECT_APPLIED:
            return _format_status_applied_breakdown(event)
        CombatEnums.CombatEventType.POISON_APPLIED:






            return _format_poison_applied_breakdown(event)
        _:
            return ""




static func _format_damage_breakdown(event: CombatEvent) -> String:
    var data: Dictionary = event.data
    var total: int = int(round(float(data.get("total", 0.0))))

    var lines: Array[String] = []
    lines.append("[b]Hit breakdown[/b]")



    var dom: int = DamageColors.dominant_type(data)
    var total_color: String = DamageColors.hex_for(dom) if dom >= 0 else "ffffff"
    lines.append("Total: [b][color=#%s]%d damage[/color][/b]" % [total_color, total])




    var per_type_lines: Array[String] = []
    for type in StatEnums.DamageType.values():
        var key: String = DamageColors.name_for(type).to_lower()
        var base: float = float(data.get("base_" + key, 0.0))
        var raw: float = float(data.get("raw_" + key, 0.0))
        var final: float = float(data.get(key, 0.0))
        if base <= 0.01 and raw <= 0.01 and final <= 0.01:
            continue
        per_type_lines.append(_format_type_line(type, base, raw, final, data))
    if not per_type_lines.is_empty():
        lines.append("---------")
        lines.append_array(per_type_lines)


    var modifier_lines: Array[String] = _format_modifier_lines(data)
    if not modifier_lines.is_empty():
        lines.append("---------")
        lines.append_array(modifier_lines)




    var impale_consumed: int = int(data.get("impale_stacks_consumed", 0))
    if impale_consumed > 0:
        var bonus_by_type: Dictionary = data.get("impale_bonus_by_type", {})
        var total_bonus: float = float(bonus_by_type.get("fire", 0.0))\
+ float(bonus_by_type.get("cold", 0.0))\
+ float(bonus_by_type.get("lightning", 0.0))
        var plural: String = "Impale" if impale_consumed == 1 else "Impales"
        lines.append("---------")
        lines.append("Consumed %d %s for +%.1f elemental:" % [impale_consumed, plural, total_bonus])


        for elem in ["fire", "cold", "lightning"]:
            var amt: float = float(bonus_by_type.get(elem, 0.0))
            if amt <= 0.01:
                continue
            lines.append("  +%.1f %s" % [amt, elem.capitalize()])

    return "\n".join(lines)





static func _format_impale_applied_breakdown(event: CombatEvent) -> String:
    var data: Dictionary = event.data
    var phys: float = float(data.get("phys_dealt", 0.0))
    var capt: float = float(data.get("capture_pct", 0.0))
    var flat: float = float(data.get("flat_damage", 0.0))
    var stacks_now: int = int(data.get("stacks_now", 0))


    var stacks_added: int = int(data.get("stacks_added", 1))
    var max_s: int = int(data.get("max_stacks", 0))
    var lines: Array[String] = []
    lines.append("[b]Impale applied[/b]")
    lines.append("---------")
    lines.append("Capture: %.0f phys x %.0f%% = [b]%.1f flat[/b] per stack" % [phys, capt, flat])
    if stacks_added > 1:


        lines.append("Stacks deposited: [b]%d[/b] [color=#888](impale chance > 100%%)[/color]" % stacks_added)
    lines.append("Stacks: %d / %d" % [stacks_now, max_s])
    if stacks_now >= max_s:
        lines.append("[color=#888]At cap - next phys hit FIFO-evicts the oldest stack.[/color]")
    lines.append("---------")
    lines.append("[color=#aaa]The next elemental hit on this target consumes ALL stacks and adds their flat damage to that hit, split proportionally across the elements present.[/color]")
    return "\n".join(lines)




static func _format_impale_consumed_breakdown(event: CombatEvent) -> String:
    var data: Dictionary = event.data
    var count: int = int(data.get("stacks_consumed", 0))
    var total_flat: float = float(data.get("total_flat", 0.0))
    var per_element: Dictionary = data.get("per_element", {})
    var plural: String = "Impale" if count == 1 else "Impales"
    var lines: Array[String] = []
    lines.append("[b]Impale consumed[/b]")
    lines.append("---------")
    lines.append("Consumed: [b]%d %s[/b] (%.1f flat total)" % [count, plural, total_flat])
    lines.append("---------")

    for elem in ["fire", "cold", "lightning"]:
        var amt: float = float(per_element.get(elem, 0.0))
        if amt <= 0.01:
            continue
        lines.append("+%.1f as %s" % [amt, elem.capitalize()])
    lines.append("---------")
    lines.append("[color=#aaa]Added pre-mitigation so the hit's elemental resistance still applies. No crit multiplier.[/color]")
    return "\n".join(lines)





static func _format_status_applied_breakdown(event: CombatEvent) -> String:
    var data: Dictionary = event.data
    var nice_name: String = _effect_display_name(data)
    var magnitude: float = float(data.get("magnitude_pct", 0.0))
    var label: String = String(data.get("magnitude_label", ""))
    var dur: float = float(data.get("duration_seconds", 0.0))

    var lines: Array[String] = []
    lines.append("[b]%s applied[/b]" % nice_name)
    lines.append("---------")

    if "dmg/sec" in label or "dmg/s" in label:
        lines.append("Magnitude: [b]%.1f %s[/b]" % [magnitude, label])
    else:
        lines.append("Magnitude: [b]%.1f%% %s[/b]" % [absf(magnitude), label])
    if dur > 0.0:
        lines.append("Duration: %.2fs" % dur)


    var chance: float = float(data.get("chance_pct", 0.0))
    if chance > 0.0:
        var was_crit: bool = bool(data.get("was_crit", false))
        var roll_val: float = float(data.get("roll_value", -1.0))
        if was_crit:
            lines.append("Roll: [color=yellow]CRIT - chance forced to 100%[/color]")
        elif roll_val >= 0.0:
            lines.append("Roll: %.1f vs %.0f%% chance" % [roll_val, chance])




    var damage: float = float(data.get("magnitude_damage", 0.0))
    var max_life: float = float(data.get("magnitude_max_life", 0.0))
    if damage > 0.0 and max_life > 0.0:
        lines.append("---------")
        var base_pct: float = float(data.get("magnitude_base_pct", 0.0))
        var effect_more: float = float(data.get("magnitude_effect_more_pct", 0.0))
        lines.append("Curve: %.0f damage vs %.0f max life" % [damage, max_life])
        if "dmg/sec" in label or "dmg/s" in label:

            lines.append("Base DPS: %.1f x (1 + %.0f%% effect) = %.1f" % [base_pct, effect_more, magnitude])
        else:
            lines.append("Base: %.1f%% x (1 + %.0f%% effect) = %.1f%%" % [absf(base_pct), effect_more, absf(magnitude)])

    return "\n".join(lines)








static func _format_poison_applied_breakdown(event: CombatEvent) -> String:
    var data: Dictionary = event.data
    var dps: float = float(data.get("damage_per_sec", 0.0))
    var dur: float = float(data.get("duration_seconds", 0.0))
    var stacks_now: int = int(data.get("stacks_now", 0))
    var stacks_added: int = int(data.get("stacks_added", 1))

    var lines: Array[String] = []
    lines.append("[b]Poison applied[/b]")
    lines.append("---------")
    lines.append("Per-stack DPS: [b]%.1f chaos dmg/s[/b]" % dps)
    if dur > 0.0:
        lines.append("Duration: %.2fs (each stack independent)" % dur)
    if stacks_added > 1:
        lines.append("Stacks deposited: [b]%d[/b] [color=#888](chance > 100%%)[/color]" % stacks_added)
    lines.append("Stacks on target: %d" % stacks_now)
    if stacks_now > 1:
        lines.append("Total active DPS: [b]%.1f[/b] [color=#888](%d stacks x %.1f)[/color]" % [
            float(stacks_now) * dps, stacks_now, dps, 
        ])


    var chance: float = float(data.get("chance_pct", 0.0))
    if chance > 0.0:
        var roll_val: float = float(data.get("roll_value", -1.0))
        if roll_val >= 0.0:
            lines.append("Roll: %.1f vs %.0f%% chance" % [roll_val, chance])
        else:
            lines.append("Chance: %.0f%% [color=#888](no roll - guaranteed)[/color]" % chance)


    var damage: float = float(data.get("magnitude_damage", 0.0))
    if damage > 0.0:
        lines.append("---------")
        var base_pct: float = float(data.get("magnitude_base_pct", 0.0))
        var effect_more: float = float(data.get("magnitude_effect_more_pct", 0.0))
        lines.append("Source: %.0f (phys + chaos post-mit)" % damage)
        lines.append("Base DPS: %.1f x (1 + %.0f%% effect) = %.1f" % [base_pct, effect_more, dps])

    return "\n".join(lines)






static func _format_damage_dealt(event: CombatEvent, combatants: Array, t: String, opts: Dictionary) -> String:
    var atk_name: String = _name(combatants, event.data.get("attacker_id", -1))
    var def_name: String = _name(combatants, event.data.get("defender_id", -1))

    var damage_chunk: String = _format_damage_value(event.data, opts.get("meta_id", ""))

    var crit_mark: String = ""
    if event.data.get("is_crit", false):
        crit_mark = " [color=yellow](CRIT!)[/color]"
    var glance_mark: String = ""
    if event.data.get("is_glancing", false):
        glance_mark = " [color=#aaa](glanced)[/color]"






    var inline_suffix: String = _format_inline_chunks(opts.get("inline_chunks", []))

    return "[color=gray][%s][/color] %s hits %s for %s%s%s%s" % [
        t, atk_name, def_name, damage_chunk, crit_mark, glance_mark, inline_suffix, 
    ]











static func _format_inline_chunks(inline_chunks: Array) -> String:
    if inline_chunks.is_empty():
        return ""





    var consumed_chunks: Array = []
    var ailment_chunks: Array = []
    var applied_chunks: Array = []
    for chunk in inline_chunks:
        var evt: CombatEvent = chunk.get("event")
        if evt == null:
            continue
        match evt.event_type:
            CombatEnums.CombatEventType.IMPALE_CONSUMED:
                consumed_chunks.append(chunk)
            CombatEnums.CombatEventType.STATUS_EFFECT_APPLIED, \
CombatEnums.CombatEventType.POISON_APPLIED:
                ailment_chunks.append(chunk)
            CombatEnums.CombatEventType.IMPALE_APPLIED:
                applied_chunks.append(chunk)

    var ordered: Array = []
    ordered.append_array(consumed_chunks)
    ordered.append_array(ailment_chunks)
    ordered.append_array(applied_chunks)

    var pieces: PackedStringArray = []
    for chunk in ordered:
        var meta_id: String = chunk.get("meta_id", "")
        var evt: CombatEvent = chunk.get("event")
        var text: String = _inline_chunk_text(evt)
        if text.is_empty():
            continue
        if meta_id.is_empty():
            pieces.append(text)
        else:


            pieces.append("[u][url=%s]%s[/url][/u]" % [meta_id, text])

    if pieces.is_empty():
        return ""
    return " [color=#c9a](%s)[/color]" % ", ".join(pieces)






static func _inline_chunk_text(event: CombatEvent) -> String:
    if event == null:
        return ""
    match event.event_type:
        CombatEnums.CombatEventType.IMPALE_APPLIED:
            var stacks_now: int = int(event.data.get("stacks_now", 0))
            var max_s: int = int(event.data.get("max_stacks", 0))


            var stacks_added: int = int(event.data.get("stacks_added", 1))



            if stacks_added > 1:
                return "applied %d Impales (%d/%d)" % [stacks_added, stacks_now, max_s]
            return "applied Impale (%d/%d)" % [stacks_now, max_s]
        CombatEnums.CombatEventType.IMPALE_CONSUMED:
            var count: int = int(event.data.get("stacks_consumed", 0))
            var plural: String = "Impale" if count == 1 else "Impales"
            return "consumed %d %s" % [count, plural]
        CombatEnums.CombatEventType.STATUS_EFFECT_APPLIED:



            var nice_name: String = _effect_display_name(event.data)
            var magnitude: float = float(event.data.get("magnitude_pct", 0.0))
            var label: String = String(event.data.get("magnitude_label", ""))



            if "dmg/sec" in label or "dmg/s" in label or "damage/sec" in label:
                return "applied %.0f/s %s" % [magnitude, nice_name]


            return "applied %.0f%% %s" % [absf(magnitude), nice_name]
        CombatEnums.CombatEventType.POISON_APPLIED:





            var dps_p: float = float(event.data.get("damage_per_sec", 0.0))
            var stacks_now_p: int = int(event.data.get("stacks_now", 0))
            var stacks_added_p: int = int(event.data.get("stacks_added", 1))
            if stacks_added_p > 1:
                return "applied %.0f/s Poison x%d (%d stacks)" % [dps_p, stacks_added_p, stacks_now_p]
            return "applied %.0f/s Poison (%d stacks)" % [dps_p, stacks_now_p]
        _:
            return ""





static func _format_damage_value(data: Dictionary, meta_id: String) -> String:
    var total: int = int(round(float(data.get("total", 0.0))))
    var dom: int = DamageColors.dominant_type(data)
    var color_hex: String = DamageColors.hex_for(dom) if dom >= 0 else "ffffff"

    var inner_text: String
    if DamageColors.is_single_type(data) and dom >= 0:
        inner_text = "%d %s damage" % [total, DamageColors.name_for(dom)]
    else:
        inner_text = "%d damage" % total
    var colored: String = "[color=#%s]%s[/color]" % [color_hex, inner_text]

    if meta_id.is_empty():
        return "[b]%s[/b]" % colored
    return "[b][u][url=%s]%s[/url][/u][/b]" % [meta_id, colored]









static func _format_type_line(type: int, base: float, raw: float, final: float, data: Dictionary) -> String:
    var color_hex: String = DamageColors.hex_for(type)
    var name_text: String = DamageColors.name_for(type)
    var type_key: String = DamageColors.name_for(type).to_lower()

    var is_crit: bool = data.get("is_crit", false)
    var is_glance: bool = data.get("is_glancing", false)
    var crit_mult_pct: float = float(data.get("crit_multiplier", 100.0))


    var crit_changes_value: bool = is_crit and absf(crit_mult_pct - 100.0) > 0.5

    var has_breakdown: bool = data.has("mitigation_breakdown")

    var steps: Array[String] = []



    if crit_changes_value or is_glance:
        steps.append("base %d" % int(round(base)))
        if crit_changes_value:
            steps.append("crit x%.2f" % (crit_mult_pct / 100.0))
        if is_glance:
            steps.append("glance x0.5")

    if has_breakdown:





        var mitigation: Dictionary = data.get("mitigation_breakdown", {})
        var source_order: Array[String] = ["block", "armour", "resist", "endurance", "morale_less"]
        var source_labels: Dictionary = {
            "block": "block", "armour": "armour", "resist": "resist", 
            "endurance": "endurance", "morale_less": "morale", 
        }
        var current_value: float = raw




        var pre_status_key: String = "pre_status_" + type_key
        var pre_status_val: float = float(data.get(pre_status_key, raw))
        var has_any_defence: bool = false
        for source_name in source_order:
            var source_dict: Dictionary = mitigation.get(source_name, {})
            if absf(float(source_dict.get(type_key, 0.0))) > 0.01:
                has_any_defence = true
                break
        var status_diff: float = pre_status_val - final
        var has_status_step: bool = absf(status_diff) > 0.01

        if has_any_defence or has_status_step:


            if not (crit_changes_value or is_glance):
                steps.append("from %d" % int(round(raw)))
            for source_name in source_order:
                var source_dict_b: Dictionary = mitigation.get(source_name, {})
                var delta: float = float(source_dict_b.get(type_key, 0.0))
                if absf(delta) <= 0.01:
                    continue
                var label: String = String(source_labels.get(source_name, source_name))
                current_value -= delta
                if delta > 0.0:
                    steps.append("-%d %s" % [int(round(delta)), label])
                else:
                    steps.append("+%d %s" % [int(round( - delta)), label])
        if has_status_step:
            var status_label: String = _amplifier_label(data)
            if status_diff < 0.0:
                steps.append("+%d %s" % [int(round( - status_diff)), status_label])
            else:
                steps.append("-%d %s" % [int(round(status_diff)), status_label])
    else:


        var legacy_diff: float = raw - final
        if absf(legacy_diff) > 0.01:
            if crit_changes_value or is_glance:
                steps.append("%d" % int(round(raw)))
            else:
                steps.append("from %d" % int(round(raw)))
            if legacy_diff > 0.0:
                steps.append("-%d reduced" % int(round(legacy_diff)))
            else:
                steps.append("+%d amplified" % int(round( - legacy_diff)))

    var line: String = "[color=#%s]%s: %d[/color]" % [color_hex, name_text, int(round(final))]
    if not steps.is_empty():
        line += "  ([color=#888]%s[/color])" % ", ".join(steps)
    return line





static func _amplifier_label(data: Dictionary) -> String:
    var amps: Array = data.get("damage_taken_amplifiers", [])
    if amps.is_empty():
        return "amplified"
    if amps.size() == 1:
        return "from %s" % String(amps[0].get("name", "status"))
    if amps.size() == 2:
        return "from %s + %s" % [
            String(amps[0].get("name", "?")), 
            String(amps[1].get("name", "?")), 
        ]
    return "from status (%d)" % amps.size()


static func _format_modifier_lines(data: Dictionary) -> Array[String]:
    var lines: Array[String] = []
    if data.get("is_crit", false):
        var crit_mult_pct: float = float(data.get("crit_multiplier", 100.0))
        lines.append("[color=yellow]Critical strike (x%.2f)[/color]" % (crit_mult_pct / 100.0))
    if data.get("is_glancing", false):
        lines.append("[color=#aaa]Glancing blow (incoming damage halved)[/color]")
    var blocked: float = float(data.get("blocked_amount", 0.0))
    if blocked > 0.01:
        lines.append("[color=#cce]Block: %d absorbed[/color]" % int(round(blocked)))
    if data.get("endurance_active", false):
        var pct: float = float(data.get("endurance_percent", 0.0))
        lines.append("[color=#ddc]Endurance: %d%% reduction[/color]" % int(round(pct)))
    var shield: float = float(data.get("shield_absorbed", 0.0))
    if shield > 0.01:
        lines.append("[color=#ace]Energy shield absorbed: %d[/color]" % int(round(shield)))





    var amps: Array = data.get("damage_taken_amplifiers", [])
    for amp in amps:
        var amp_name: String = String(amp.get("name", "Status"))
        var amp_pct: float = float(amp.get("magnitude_pct", 0.0))
        lines.append("[color=#e9c]Amplified by %s: +%.0f%% damage taken[/color]" % [amp_name, amp_pct])
    if amps.size() >= 2:
        var total_pct: float = float(data.get("status_taken_more_pct", 0.0))
        var total_mult: float = 1.0 + total_pct / 100.0
        lines.append("[color=#e9c]Combined status amplification: x%.2f[/color]" % total_mult)

    return lines






static func _format_morale_penalty(event: CombatEvent, combatants: Array, t: String) -> String:
    var who: String = _name(combatants, event.data.get("defender_id", -1))
    var amount: int = int(event.data.get("amount", 0))
    var source: String = event.data.get("source", "")
    var life_pct: float = float(event.data.get("life_pct", 0.0))
    var reason: String = ""
    match source:
        "crit": reason = "brutal crit"
        "chaos": reason = "chaos damage"
        _: reason = source


    return "[color=gray][%s][/color] [color=#4cb8ec]%s - -%d Morale (%s, %d%% life)[/color]" % [
        t, who, amount, reason, int(round(life_pct * 100.0)), 
    ]


static func _format_combat_end(event: CombatEvent, t: String) -> String:
    var result: int = event.data.get("result", -1)
    var dur: float = event.data.get("duration", 0.0)
    var name_text: String = "Combat ends"
    var color: String = "#aaa"
    match result:
        CombatEnums.CombatResult.VICTORY:
            name_text = "VICTORY"
            color = "#5cc"
        CombatEnums.CombatResult.DEFEAT:
            name_text = "DEFEAT"
            color = "#f55"
        CombatEnums.CombatResult.RETREAT:
            name_text = "RETREATED"
            color = "#ec5"
    return "[color=%s][%s] %s (combat lasted %.1fs)[/color]" % [color, t, name_text, dur]







static func _format_desperation_increased(event: CombatEvent, t: String) -> String:
    var stacks: int = int(event.data.get("stacks", 0))
    var damage_more: float = float(event.data.get("damage_more_pct", 0.0))
    var vit_drain: float = float(event.data.get("vitality_drain_per_sec", 0.0))
    return "[color=#e88][%s] [b]Desperation Increases![/b] Now +%d%% damage, -%.1f vitality/s for all combatants ([color=#fcc]%d stacks[/color])[/color]" % [
        t, int(round(damage_more)), vit_drain, stacks, 
    ]









static func _format_effect_details(payload: Dictionary) -> String:
    var mag: float = float(payload.get("magnitude_pct", 0.0))
    var dur: float = float(payload.get("duration_seconds", 0.0))




    var mag_label: String = String(payload.get("magnitude_label", "inc dmg taken"))
    var stat_parts: Array[String] = []
    if mag > 0.0:
        stat_parts.append("%.0f%% %s" % [mag, mag_label])
    if dur > 0.0:
        stat_parts.append("%.1fs" % dur)

    var roll_text: String = _format_roll_context(payload)
    var calc_text: String = _format_magnitude_calc(payload)

    var out: String = ""
    if not stat_parts.is_empty():
        out += " [color=#888](%s)[/color]" % ", ".join(stat_parts)
    if not roll_text.is_empty():
        out += " [color=#666][%s][/color]" % roll_text
    if not calc_text.is_empty():
        out += " [color=#666][%s][/color]" % calc_text
    return out






static func _format_magnitude_calc(payload: Dictionary) -> String:
    if not payload.has("magnitude_damage"):
        return ""
    var dmg: float = float(payload.get("magnitude_damage", 0.0))
    var max_life: float = float(payload.get("magnitude_max_life", 0.0))
    var base_pct: float = float(payload.get("magnitude_base_pct", 0.0))
    var effect_more: float = float(payload.get("magnitude_effect_more_pct", 0.0))
    var final_pct: float = float(payload.get("magnitude_pct", 0.0))
    var effect_mult: float = 1.0 + effect_more / 100.0
    return "mag: %.1f/%.0f, %.1f%% base x %.2f effect = %.1f%%" % [
        dmg, max_life, base_pct, effect_mult, final_pct, 
    ]





static func _format_roll_context(payload: Dictionary) -> String:
    if not payload.has("chance_pct"):
        return ""
    var was_crit: bool = bool(payload.get("was_crit", false))
    if was_crit:
        return "crit forced"
    var chance: float = float(payload.get("chance_pct", 0.0))
    var roll: float = float(payload.get("roll_value", -1.0))
    return "rolled %.1f vs %.0f%% chance" % [roll, chance]









static func _format_ailment_roll(event: CombatEvent, combatants: Array, t: String) -> String:
    var attacker: String = _name(combatants, event.data.get("attacker_id", -1))
    var ailment_name: String = String(event.data.get("ailment_name", "Ailment"))
    var result: String = String(event.data.get("result", ""))
    var roll_text: String = _format_roll_context(event.data)

    match result:
        "rolled_failed":
            return "[color=#666][%s] %s's [b]%s[/b] roll failed [color=#555](%s)[/color][/color]" % [
                t, attacker, ailment_name, roll_text, 
            ]
        "discarded_below_min":
            var mag: float = float(event.data.get("magnitude_pct", 0.0))


            var calc: String = _format_magnitude_calc(event.data)
            var calc_chunk: String = " [color=#444][%s][/color]" % calc if not calc.is_empty() else ""



            var roll_prefix: String = "%s - " % roll_text if not roll_text.is_empty() else ""
            return "[color=#666][%s] %s's [b]%s[/b] discarded [color=#555](%s%.1f%% magnitude below minimum)[/color]%s[/color]" % [
                t, attacker, ailment_name, roll_prefix, mag, calc_chunk, 
            ]
        _:
            return ""







static func _effect_display_name(payload: Dictionary) -> String:
    var display: String = String(payload.get("display_name", ""))
    if not display.is_empty():
        return display
    var raw_id: String = String(payload.get("effect_id", &""))
    if raw_id.is_empty():
        return ""
    return raw_id.replace("_", " ").capitalize()


static func _name(combatants: Array, combatant_id: int) -> String:
    if combatant_id < 0 or combatant_id >= combatants.size():
        return "?"
    var c: CombatantData = combatants[combatant_id]
    if c.display_name != "":
        return c.display_name
    return "Combatant %d" % combatant_id
