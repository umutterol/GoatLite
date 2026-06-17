


class_name ItemLabel
extends Control





signal affix_clicked(slot_kind: String, affix_index: int)

const RARITY_COLORS: Dictionary = {
    Item.Rarity.COMMON: "white", 
    Item.Rarity.UNCOMMON: "#4f8fef", 
    Item.Rarity.RARE: "#ffd700", 
}
const COLOR_IMPLICIT: String = "#cccccc"
const COLOR_EXPLICIT: String = "#88aaff"
const COLOR_CATEGORY: String = "#aaaaaa"
const COLOR_BASE_STAT: String = "#cccccc"


const COLOR_LOCAL_SCALED: String = "#88aaff"


const COLOR_MONSTER_INFREQUENT: String = "#B020D8"


const COLOR_CORRUPTED: String = "#c43838"

@onready var item_name_label: RichTextLabel = $PanelContainer / MarginContainer / VBoxContainer / PanelContainer / VBoxContainer / ItemName
@onready var item_base_label: RichTextLabel = $PanelContainer / MarginContainer / VBoxContainer / PanelContainer / VBoxContainer / ItemBase
@onready var category_level: RichTextLabel = $PanelContainer / MarginContainer / VBoxContainer / CategoryLevel
@onready var mi_label: RichTextLabel = $PanelContainer / MarginContainer / VBoxContainer / MonsterInfrequent
@onready var corrupted_label: RichTextLabel = $PanelContainer / MarginContainer / VBoxContainer / Corrupted
@onready var base_stats_label: RichTextLabel = $PanelContainer / MarginContainer / VBoxContainer / BaseStats
@onready var base_stats_divider: HSeparator = $PanelContainer / MarginContainer / VBoxContainer / BaseStatsDivider
@onready var implicits_label: RichTextLabel = $PanelContainer / MarginContainer / VBoxContainer / Implicits
@onready var implicit_divider: HSeparator = $PanelContainer / MarginContainer / VBoxContainer / ImplicitDivider
@onready var modifiers_label: RichTextLabel = $PanelContainer / MarginContainer / VBoxContainer / Modifiers





var _affix_clicks_enabled: bool = false
var _last_item: Item = null



var _highlighted_affix: AffixInstance = null

const COLOR_HIGHLIGHT_BG: String = "#3a2f0a"
const COLOR_HIGHLIGHT_TEXT: String = "#ffd700"




const BASE_FONT_NAME: int = 16
const BASE_FONT_BASE_ITEM: int = 16
const BASE_FONT_SMALL: int = 12
const BASE_FONT_BODY: int = 14


func _ready() -> void :



    modifiers_label.meta_clicked.connect(_on_modifiers_meta_clicked)






func set_font_scale(factor: float) -> void :
    if not is_node_ready():
        await ready
    _apply_size(item_name_label, BASE_FONT_NAME * factor)
    _apply_size(item_base_label, BASE_FONT_BASE_ITEM * factor)
    _apply_size(category_level, BASE_FONT_SMALL * factor)
    _apply_size(mi_label, BASE_FONT_SMALL * factor)
    _apply_size(corrupted_label, BASE_FONT_SMALL * factor)
    _apply_size(base_stats_label, BASE_FONT_BODY * factor)
    _apply_size(implicits_label, BASE_FONT_BODY * factor)
    _apply_size(modifiers_label, BASE_FONT_BODY * factor)


func _apply_size(label: RichTextLabel, px: float) -> void :
    label.add_theme_font_size_override("normal_font_size", int(round(px)))
    label.add_theme_font_size_override("bold_font_size", int(round(px)))
    label.add_theme_font_size_override("italics_font_size", int(round(px)))
    label.add_theme_font_size_override("bold_italics_font_size", int(round(px)))
    label.add_theme_font_size_override("mono_font_size", int(round(px)))




func set_affix_clicks_enabled(enabled: bool) -> void :
    if _affix_clicks_enabled == enabled:
        return
    _affix_clicks_enabled = enabled
    if _last_item != null:
        populate(_last_item)





func set_highlighted_affix(affix: AffixInstance) -> void :
    _highlighted_affix = affix





func get_modifiers_label() -> RichTextLabel:
    return modifiers_label


func populate(item: Item) -> void :
    _last_item = item




    if not is_node_ready():
        await ready
    var rarity_color = RARITY_COLORS.get(item.rarity, "white")




    if item.rarity == Item.Rarity.COMMON:
        item_name_label.visible = false
    else:
        var rarity_name = Item.Rarity.keys()[item.rarity].capitalize()
        item_name_label.text = "[center][color=%s]%s[/color][/center]" % [
            rarity_color, rarity_name
        ]
        item_name_label.visible = true


    item_base_label.text = "[center][color=%s]%s[/color][/center]" % [
        rarity_color, item.base_item.display_name
    ]




    category_level.text = "[center][color=%s]%s  —  Item Level %d[/color][/center]" % [
        COLOR_CATEGORY, _format_category_label(item), item.item_level
    ]







    corrupted_label.visible = item.is_corrupted
    if item.is_corrupted:
        corrupted_label.text = "[center][color=%s]Corrupted[/color][/center]" % COLOR_CORRUPTED




    if item.base_item.is_monster_infrequent:
        var mi_text: String = "Monster Infrequent"
        if item.base_item.monster_infrequent_set != "":
            mi_text = "Monster Infrequent — " + item.base_item.monster_infrequent_set
        mi_label.text = "[center][color=%s]%s[/color][/center]" % [COLOR_MONSTER_INFREQUENT, mi_text]
        mi_label.visible = true
    else:
        mi_label.visible = false


    var combined_lines = _build_base_stats_text(item)
    var implicit_lines = _build_implicits_text(item)

    if implicit_lines != "":
        if combined_lines != "":
            combined_lines += "\n" + implicit_lines
        else:
            combined_lines = implicit_lines

    var has_combined = combined_lines != ""
    if has_combined:
        base_stats_label.text = combined_lines.strip_edges()
        base_stats_label.visible = true
    else:
        base_stats_label.visible = false


    implicits_label.visible = false
    base_stats_divider.visible = false


    var has_explicits = item.prefix_affixes.size() + item.suffix_affixes.size() > 0


    implicit_divider.visible = has_combined and has_explicits

    if has_explicits:
        var lines = ""



        var idx_p: int = 0
        for affix in item.prefix_affixes:
            lines += "[center]%s[/center]\n" % _format_explicit_line(affix, "prefix", idx_p)
            idx_p += 1
        var idx_s: int = 0
        for affix in item.suffix_affixes:
            lines += "[center]%s[/center]\n" % _format_explicit_line(affix, "suffix", idx_s)
            idx_s += 1
        modifiers_label.text = lines.strip_edges()
        modifiers_label.visible = true
    else:
        modifiers_label.visible = false









func _format_explicit_line(affix: AffixInstance, slot_kind: String, idx: int) -> String:
    var text: String = affix.get_display_text()
    var styled: String
    if affix == _highlighted_affix:
        styled = "[bgcolor=%s][color=%s]» %s «[/color][/bgcolor]" % [
            COLOR_HIGHLIGHT_BG, COLOR_HIGHLIGHT_TEXT, text
        ]
    else:
        var line_color: String = COLOR_CORRUPTED if _is_corrupted_mod(affix) else COLOR_EXPLICIT
        styled = "[color=%s]%s[/color]" % [line_color, text]
    if _affix_clicks_enabled:
        styled = "[url=%s:%d]%s[/url]" % [slot_kind, idx, styled]
    return styled





func _is_corrupted_mod(affix: AffixInstance) -> bool:
    if affix == null or affix.affix_base == null:
        return false
    return "corruption_only" in affix.affix_base.custom_tags





func _build_base_stats_text(item: Item) -> String:
    var lines: PackedStringArray = []
    var stats = item.rolled_stats
    var base = item.base_item

    match base.category:
        ItemEnums.ItemCategory.WEAPON:


            if stats.has("physical_damage_min") and stats.has("physical_damage_max"):
                var phys: Vector2 = item.get_local_damage_range("physical")
                var phys_color: = COLOR_LOCAL_SCALED if item.has_local_affix_for("physical_damage") else COLOR_BASE_STAT
                lines.append(_stat_line("Physical Damage: %d–%d" % [round(phys.x), round(phys.y)], phys_color))


            for element in ["fire", "cold", "lightning", "chaos"]:
                var min_key = element + "_damage_min"
                var max_key = element + "_damage_max"
                if stats.has(min_key) and stats.has(max_key):
                    var elem_range: Vector2 = item.get_local_damage_range(element)
                    var elem_color: = COLOR_LOCAL_SCALED if item.has_local_affix_for(element + "_damage") else COLOR_BASE_STAT
                    lines.append(_stat_line("%s Damage: %d–%d" % [
                        element.capitalize(), round(elem_range.x), round(elem_range.y)
                    ], elem_color))


            var aspd = stats.get("attack_speed", base.base_attack_speed)
            lines.append(_stat_line("Attack Speed: %.2f" % aspd))


            var crit = stats.get("critical_chance", base.base_critical_chance)
            lines.append(_stat_line("Critical Chance: %.1f%%" % crit))


            var weapon_range = stats.get("attack_range", base.base_attack_range)
            lines.append(_stat_line("Weapon Range: %.1f" % weapon_range))

        ItemEnums.ItemCategory.ARMOUR:



            if stats.has("armour") and stats["armour"] != 0:
                var armour_color: = COLOR_LOCAL_SCALED if item.has_local_affix_for("armour") else COLOR_BASE_STAT
                lines.append(_stat_line("Armour: %d" % round(item.get_local_stat_total("armour")), armour_color))
            if stats.has("evasion") and stats["evasion"] != 0:
                var evasion_color: = COLOR_LOCAL_SCALED if item.has_local_affix_for("evasion") else COLOR_BASE_STAT
                lines.append(_stat_line("Evasion: %.0f%%" % item.get_local_stat_total("evasion"), evasion_color))

        ItemEnums.ItemCategory.OFFHAND:
            if stats.has("block_chance") and stats["block_chance"] > 0:
                var bc_color: = COLOR_LOCAL_SCALED if item.has_local_affix_for("block_chance") else COLOR_BASE_STAT
                lines.append(_stat_line("Block Chance: %d%%" % round(item.get_local_stat_total("block_chance")), bc_color))
            if stats.has("block_amount") and stats["block_amount"] > 0:
                var ba_color: = COLOR_LOCAL_SCALED if item.has_local_affix_for("block_amount") else COLOR_BASE_STAT
                lines.append(_stat_line("Block Amount: %d" % round(item.get_local_stat_total("block_amount")), ba_color))




    if stats.has("movement") and stats["movement"] != 0:
        var mov = stats["movement"]
        var sign_str = "+" if mov > 0 else ""
        lines.append(_stat_line("Movement: %s%d%%" % [sign_str, mov]))

    return "\n".join(lines)

func _build_implicits_text(item: Item) -> String:
    if item.implicit_affixes.size() == 0:
        return ""
    var lines: PackedStringArray = []
    for affix in item.implicit_affixes:


        var color: String = COLOR_CORRUPTED if _is_corrupted_mod(affix) else COLOR_IMPLICIT
        lines.append("[center][color=%s]%s[/color][/center]" % [
            color, affix.get_display_text()
        ])
    return "\n".join(lines)

func _stat_line(text: String, color: String = COLOR_BASE_STAT) -> String:
    return "[center][color=%s]%s[/color][/center]" % [color, text]






func _on_modifiers_meta_clicked(meta: Variant) -> void :
    if not _affix_clicks_enabled:
        return
    var parts: PackedStringArray = str(meta).split(":")
    if parts.size() != 2:
        return
    affix_clicked.emit(parts[0], int(parts[1]))






func _format_category_label(item: Item) -> String:
    var base: = item.base_item
    if base.category == ItemEnums.ItemCategory.WEAPON:
        var hand_prefix: String = "2H" if base.hand_type == ItemEnums.HandType.TWO_HANDED else "1H"
        return "%s %s" % [hand_prefix, ItemEnums.get_weapon_type_name(base.weapon_type)]
    return base.get_type_name()
