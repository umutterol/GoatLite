extends Control













const MONSTER_DIRS: Array[String] = [
    "res://systems/monsters/normal/", 
    "res://systems/monsters/unique/", 
]





const MELEE_WEAPON_PATH: String = "res://systems/items/itemBases/weapon/sword/1h/scrap_short_sword.tres"
const MELEE_OFFHAND_PATH: String = "res://systems/items/itemBases/offhand/shield/cooking_pot_lid.tres"
const RANGED_WEAPON_PATH: String = "res://systems/items/itemBases/weapon/bow/sapling_bow.tres"
const ARMOUR_HELMET_PATH: String = "res://systems/items/itemBases/armour/helmet/decayed_hood.tres"
const ARMOUR_CHEST_PATH: String = "res://systems/items/itemBases/armour/chest/tattered_rags.tres"
const ARMOUR_GLOVES_PATH: String = "res://systems/items/itemBases/armour/gloves/cracked_leather_gloves.tres"
const ARMOUR_BOOTS_PATH: String = "res://systems/items/itemBases/armour/boots/rawhide_boots.tres"

const COMBAT_PLAYBACK_SCENE: PackedScene = preload("res://gameUI/combat/CombatPlaybackScreen.tscn")



const PARTY_CAP: int = 5












const AILMENT_PRESETS: Dictionary = {
    "Vanilla": {}, 
    "Force Shocks": {
        "lightning_damage": Vector2(30.0, 60.0), 
        "shock_chance": 100.0, 
        "shock_effect_more_pct": 50.0, 
        "shock_duration_more_pct": 50.0, 
    }, 
    "Force Chills": {
        "cold_damage": Vector2(30.0, 60.0), 



        "chill_effect_more_pct": 50.0, 
        "chill_duration_more_pct": 50.0, 
    }, 
    "Force Ignites": {
        "fire_damage": Vector2(30.0, 60.0), 
        "ignite_chance": 100.0, 
        "ignite_effect_more_pct": 50.0, 
        "ignite_duration_more_pct": 30.0, 
        "damage_over_time_more_pct": 30.0, 
    }, 
    "Force Impales": {






        "physical_damage": Vector2(40.0, 80.0), 
        "impale_chance": 100.0, 
        "impale_effect_pct": 30.0, 
        "max_impales_bonus": 3, 
    }, 
    "Force Poisons": {






        "physical_damage": Vector2(20.0, 35.0), 
        "chaos_damage": Vector2(20.0, 35.0), 
        "poison_chance": 150.0, 
        "poison_effect_more_pct": 50.0, 
        "poison_duration_more_pct": 50.0, 
        "damage_over_time_more_pct": 30.0, 
    }, 
    "Mixed Elements": {



        "fire_damage": Vector2(10.0, 20.0), 
        "cold_damage": Vector2(10.0, 20.0), 
        "lightning_damage": Vector2(10.0, 20.0), 
        "chaos_damage": Vector2(8.0, 16.0), 
        "shock_chance": 30.0, 
        "chill_effect_more_pct": 25.0, 
        "ignite_chance": 30.0, 
        "poison_chance": 40.0, 
        "impale_chance": 30.0, 
        "impale_effect_pct": 15.0, 
    }, 
    "Crit Build": {




        "critical_chance": 60.0, 
        "critical_multiplier": 200.0, 
        "shock_effect_more_pct": 50.0, 
        "chill_effect_more_pct": 50.0, 
        "ignite_effect_more_pct": 50.0, 
        "impale_chance": 60.0, 
        "impale_effect_pct": 25.0, 
    }, 
}








func _apply_ailment_preset(exile: ExileData, preset_name: String, force_crits: bool) -> void :
    var stats: ExileStats = exile.current_stats
    if stats == null:
        push_warning("CombatSandbox: exile '%s' has null current_stats — preset skipped." % exile.name)
        return
    var recipe: Dictionary = AILMENT_PRESETS.get(preset_name, {})
    for key in recipe:
        stats.set(key, recipe[key])
    if force_crits:
        stats.critical_chance = 100.0


@onready var monster_option: OptionButton = %MonsterOption
@onready var monster_count_slider: HSlider = %MonsterCountSlider
@onready var monster_count_label: Label = %MonsterCountLabel
@onready var melee_count_slider: HSlider = %MeleeCountSlider
@onready var melee_count_label: Label = %MeleeCountLabel
@onready var ranged_count_slider: HSlider = %RangedCountSlider
@onready var ranged_count_label: Label = %RangedCountLabel
@onready var exile_level_slider: HSlider = %ExileLevelSlider
@onready var exile_level_label: Label = %ExileLevelLabel
@onready var arena_w_slider: HSlider = %ArenaWidthSlider
@onready var arena_w_label: Label = %ArenaWidthLabel
@onready var arena_h_slider: HSlider = %ArenaHeightSlider
@onready var arena_h_label: Label = %ArenaHeightLabel
@onready var seed_edit: LineEdit = %SeedEdit
@onready var random_seed_check: CheckBox = %RandomSeedCheck
@onready var fight_button: Button = %FightButton
@onready var reload_monsters_button: Button = %ReloadMonstersButton
@onready var status_label: Label = %StatusLabel
@onready var playback_host: Control = %PlaybackHost
@onready var placeholder_label: Label = %PlaceholderLabel



@onready var ailment_preset_option: OptionButton = %AilmentPresetOption
@onready var force_crits_check: CheckBox = %ForceCritsCheck
@onready var monster_fragility_slider: HSlider = %MonsterFragilitySlider
@onready var monster_fragility_label: Label = %MonsterFragilityLabel


var _monsters: Array[MonsterData] = []
var _monster_paths: Array[String] = []


var _playback: CombatPlaybackScreen = null




var _next_exile_id: int = 1000000






func _ready() -> void :
    _load_monsters()
    _populate_monster_options()
    _populate_ailment_presets()
    _wire_signals()
    _refresh_all_labels()
    status_label.text = "%d monster types loaded. Configure, then Fight." % _monsters.size()





func _populate_ailment_presets() -> void :
    ailment_preset_option.clear()


    ailment_preset_option.add_item("Vanilla", 0)
    var i: int = 1
    for key in AILMENT_PRESETS.keys():
        if key == "Vanilla":
            continue
        ailment_preset_option.add_item(key, i)
        i += 1
    ailment_preset_option.select(0)


func _wire_signals() -> void :
    monster_count_slider.value_changed.connect(_on_monster_count_changed)
    melee_count_slider.value_changed.connect(_on_melee_changed)
    ranged_count_slider.value_changed.connect(_on_ranged_changed)
    exile_level_slider.value_changed.connect(_on_level_changed)
    arena_w_slider.value_changed.connect(_on_arena_w_changed)
    arena_h_slider.value_changed.connect(_on_arena_h_changed)
    monster_fragility_slider.value_changed.connect(_on_fragility_changed)
    fight_button.pressed.connect(_on_fight_pressed)
    reload_monsters_button.pressed.connect(_on_reload_pressed)






func _load_monsters() -> void :
    _monsters.clear()
    _monster_paths.clear()
    for dir_path in MONSTER_DIRS:
        var dir: = DirAccess.open(dir_path)
        if dir == null:
            push_warning("CombatSandbox: cannot open %s" % dir_path)
            continue
        dir.list_dir_begin()
        var fname: String = dir.get_next()
        while fname != "":
            if not dir.current_is_dir() and fname.ends_with(".tres"):
                var path: String = dir_path + fname
                var res: Resource = load(path)
                if res is MonsterData:
                    _monsters.append(res)
                    _monster_paths.append(path)
            fname = dir.get_next()
        dir.list_dir_end()


func _populate_monster_options() -> void :
    monster_option.clear()
    for i in _monsters.size():
        var monster: MonsterData = _monsters[i]
        var label: String = monster.display_name
        if label.is_empty():
            label = _monster_paths[i].get_file().get_basename()
        monster_option.add_item(label, i)
    if _monsters.size() > 0:
        monster_option.select(0)






func _refresh_all_labels() -> void :
    _on_monster_count_changed(monster_count_slider.value)
    _on_melee_changed(melee_count_slider.value)
    _on_ranged_changed(ranged_count_slider.value)
    _on_level_changed(exile_level_slider.value)
    _on_arena_w_changed(arena_w_slider.value)
    _on_arena_h_changed(arena_h_slider.value)
    _on_fragility_changed(monster_fragility_slider.value)


func _on_monster_count_changed(value: float) -> void :
    monster_count_label.text = "Monster count: %d" % int(value)


func _on_melee_changed(value: float) -> void :
    melee_count_label.text = "Melee exiles: %d" % int(value)


func _on_ranged_changed(value: float) -> void :
    ranged_count_label.text = "Ranged exiles: %d" % int(value)


func _on_level_changed(value: float) -> void :
    exile_level_label.text = "Exile level: %d" % int(value)


func _on_arena_w_changed(value: float) -> void :
    arena_w_label.text = "Arena width: %d units" % int(value)


func _on_arena_h_changed(value: float) -> void :
    arena_h_label.text = "Arena height: %d units" % int(value)





func _on_fragility_changed(value: float) -> void :
    var hint: String = ""
    if value < 0.95:
        hint = " (squishy — easy ailment thresholds)"
    elif value > 1.05:
        hint = " (tanky — harder to ailment)"
    monster_fragility_label.text = "Monster life: ×%.2f%s" % [value, hint]


func _on_reload_pressed() -> void :
    _load_monsters()
    _populate_monster_options()
    status_label.text = "Reloaded — %d monster types found." % _monsters.size()






func _on_fight_pressed() -> void :
    var melee_count: int = int(melee_count_slider.value)
    var ranged_count: int = int(ranged_count_slider.value)
    if melee_count + ranged_count == 0:
        status_label.text = "Need at least one melee or ranged exile."
        return
    if melee_count + ranged_count > PARTY_CAP:
        status_label.text = "Cap is %d total exiles." % PARTY_CAP
        return

    var monster_idx: int = monster_option.get_selected_id()
    if monster_idx < 0 or monster_idx >= _monsters.size():
        status_label.text = "Pick a monster first."
        return

    var monster_count: int = int(monster_count_slider.value)
    var seed_value: int = _resolve_seed()
    var exile_level: int = int(exile_level_slider.value)
    var preset_name: String = ailment_preset_option.get_item_text(ailment_preset_option.selected)
    var force_crits: bool = force_crits_check.button_pressed
    var fragility_mult: float = monster_fragility_slider.value

    var party: Array[ExileData] = _build_party(melee_count, ranged_count, exile_level, preset_name, force_crits)
    var encounter: EncounterData = _build_encounter(_monsters[monster_idx], monster_count, fragility_mult)

    var sim: = CombatSimulation.new()
    sim.initialize(party, encounter, seed_value)
    var result: CombatResultData = sim.run_to_completion()

    _spawn_playback(result, _monsters[monster_idx].display_name, monster_count, melee_count, ranged_count)


    var preset_chunk: String = preset_name
    if force_crits:
        preset_chunk += " + force-crits"
    if not is_equal_approx(fragility_mult, 1.0):
        preset_chunk += " ×%.2f life" % fragility_mult
    status_label.text = "Combat: %.2fs / %d ticks / seed %d. Outcome: %s. Setup: %s" % [
        result.duration, 
        result.snapshots.size(), 
        seed_value, 
        CombatEnums.CombatResult.keys()[result.outcome], 
        preset_chunk, 
    ]





func _resolve_seed() -> int:
    if random_seed_check.button_pressed:
        var rolled: int = randi()
        seed_edit.text = str(rolled)
        return rolled
    var txt: String = seed_edit.text.strip_edges()
    if txt.is_empty():
        return 0
    return int(txt)






func _build_party(melee_count: int, ranged_count: int, level: int, 
        preset_name: String, force_crits: bool) -> Array[ExileData]:
    var party: Array[ExileData] = []

    var item_generator: = ItemGenerator.new()
    item_generator.load_item_bases()

    for _i in melee_count:
        party.append(_make_archetype_exile(item_generator, level, true, preset_name, force_crits))
    for _i in ranged_count:
        party.append(_make_archetype_exile(item_generator, level, false, preset_name, force_crits))
    return party







func _make_archetype_exile(item_generator: ItemGenerator, level: int, is_melee: bool, 
        preset_name: String = "Vanilla", force_crits: bool = false) -> ExileData:
    var archetype: String = "Melee" if is_melee else "Ranged"
    var exile: ExileData = ExileGenerator.create_exile({
        "class_rarity_override": 0, 
        "level": level, 
        "name": "Sandbox %s %d" % [archetype, _next_exile_id], 
    })

    exile.id = _next_exile_id
    _next_exile_id += 1

    if is_melee:
        _equip(exile, item_generator, ItemEnums.EquipSlot.MAIN_HAND, MELEE_WEAPON_PATH)
        _equip(exile, item_generator, ItemEnums.EquipSlot.OFF_HAND, MELEE_OFFHAND_PATH)
    else:

        _equip(exile, item_generator, ItemEnums.EquipSlot.BOTH_HANDS, RANGED_WEAPON_PATH)
    _equip_basic_armour(exile, item_generator)



    ExileGenerator.recalculate_stats(exile)


    _apply_ailment_preset(exile, preset_name, force_crits)



    exile.current_life = exile.current_stats.life
    exile.current_stats.current_life = exile.current_life
    return exile


func _equip_basic_armour(exile: ExileData, item_generator: ItemGenerator) -> void :
    _equip(exile, item_generator, ItemEnums.EquipSlot.HELMET, ARMOUR_HELMET_PATH)
    _equip(exile, item_generator, ItemEnums.EquipSlot.CHEST, ARMOUR_CHEST_PATH)
    _equip(exile, item_generator, ItemEnums.EquipSlot.GLOVES, ARMOUR_GLOVES_PATH)
    _equip(exile, item_generator, ItemEnums.EquipSlot.BOOTS, ARMOUR_BOOTS_PATH)





func _equip(exile: ExileData, item_generator: ItemGenerator, slot: ItemEnums.EquipSlot, base_path: String) -> void :
    var base: Resource = load(base_path)
    if base == null:
        push_warning("CombatSandbox: missing item base at %s" % base_path)
        return
    if not (base is ItemBase):
        push_warning("CombatSandbox: %s is not an ItemBase" % base_path)
        return
    var item: Item = item_generator.generate_item(1, base)
    if item == null:
        push_warning("CombatSandbox: generate_item returned null for %s" % base_path)
        return
    var slot_key: String = ItemEnums.EquipSlot.keys()[slot]
    exile.equipped_items[slot_key] = item






func _build_encounter(monster: MonsterData, count: int, fragility_mult: float = 1.0) -> EncounterData:
    var encounter: = EncounterData.new()
    var monster_key: String = monster.monster_id if not monster.monster_id.is_empty() else "monster"
    encounter.encounter_id = "sandbox_%s_x%d" % [monster_key, count]
    encounter.display_name = "Sandbox vs %s x%d" % [monster.display_name, count]
    encounter.arena_width = arena_w_slider.value
    encounter.arena_height = arena_h_slider.value
    encounter.recommended_level = 1




    var working_monster: MonsterData = monster
    if not is_equal_approx(fragility_mult, 1.0):
        working_monster = monster.duplicate() as MonsterData
        var scaled_stats: ExileStats = monster.base_stats.duplicate() as ExileStats
        scaled_stats.life = maxf(scaled_stats.life * fragility_mult, 1.0)
        working_monster.base_stats = scaled_stats

    var spawn: = MonsterSpawn.new()
    spawn.monster = working_monster
    spawn.count = count
    spawn.position_hint = MonsterSpawn.PositionHint.FRONTLINE
    encounter.monster_spawns = [spawn]

    return encounter









func _spawn_playback(result: CombatResultData, monster_name: String, monster_count: int, 
        melee_count: int, ranged_count: int) -> void :
    _teardown_playback()

    var ranged_summary: String = ""
    if ranged_count > 0:
        ranged_summary = " + %d ranged" % ranged_count
    var melee_summary: String = ""
    if melee_count > 0:
        melee_summary = "%d melee" % melee_count
    elif ranged_count > 0:

        melee_summary = "%d ranged" % ranged_count
        ranged_summary = ""
    var label: String = "Sandbox: %s%s vs %s x%d" % [
        melee_summary, ranged_summary, monster_name, monster_count, 
    ]

    CombatPlaybackScreen.sandbox_payload = {
        "combat_result": result, 
        "encounter_label": label, 
        "continue_text": "Reset →", 
    }


    var instance: Control = COMBAT_PLAYBACK_SCENE.instantiate()
    _playback = instance as CombatPlaybackScreen
    playback_host.add_child(instance)


    instance.anchor_left = 0.0
    instance.anchor_top = 0.0
    instance.anchor_right = 1.0
    instance.anchor_bottom = 1.0
    instance.offset_left = 0.0
    instance.offset_top = 0.0
    instance.offset_right = 0.0
    instance.offset_bottom = 0.0

    placeholder_label.visible = false
    _playback.sandbox_continue_pressed.connect(_on_playback_continue)


func _teardown_playback() -> void :
    if _playback != null and is_instance_valid(_playback):
        _playback.queue_free()
    _playback = null
    placeholder_label.visible = true



    CombatPlaybackScreen.sandbox_payload = {}


func _on_playback_continue() -> void :
    _teardown_playback()
    status_label.text = "Playback reset. Reconfigure and Fight again."
