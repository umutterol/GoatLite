extends Node2D









const DRAW_WIDTH: float = 800.0
const DRAW_HEIGHT: float = 600.0
const DRAW_OFFSET: = Vector2(100, 100)
const MARKER_RADIUS: float = 10.0



var sim: CombatSimulation
var rng: = RandomNumberGenerator.new()


var encounters: Array[EncounterData] = []
var encounter_index: int = 0
var is_random_mode: bool = false


var spawn_group_labels: Dictionary = {}



const ENCOUNTER_PATHS: Array[String] = [
    "res://systems/combat/encounters/coast/small_zombie_pack.tres", 
    "res://systems/combat/encounters/coast/small_zombie_ambush.tres", 
    "res://systems/combat/encounters/coast/zombies_rhoas.tres", 
    "res://systems/combat/encounters/coast/grandaddy_crab_bossfight.tres", 
]


func _ready() -> void :
    rng.randomize()

    for path in ENCOUNTER_PATHS:
        var enc: EncounterData = load(path)
        if enc != null:
            encounters.append(enc)
        else:
            push_warning("PlacementTest: failed to load encounter at %s" % path)

    if encounters.is_empty():
        push_error("PlacementTest: no encounters loaded — check ENCOUNTER_PATHS")
        return

    _run_encounter(encounters[0])


func _input(event: InputEvent) -> void :
    if not event is InputEventKey or not event.pressed:
        return

    match event.keycode:
        KEY_SPACE:
            _run_random_encounter()
        KEY_R:

            if is_random_mode:
                _run_random_encounter()
            elif not encounters.is_empty():
                _run_encounter(encounters[encounter_index])
        KEY_RIGHT:
            if not encounters.is_empty():
                encounter_index = (encounter_index + 1) % encounters.size()
                is_random_mode = false
                _run_encounter(encounters[encounter_index])
        KEY_LEFT:
            if not encounters.is_empty():
                encounter_index = (encounter_index - 1 + encounters.size()) % encounters.size()
                is_random_mode = false
                _run_encounter(encounters[encounter_index])






func _run_encounter(encounter: EncounterData) -> void :
    sim = CombatSimulation.new()
    spawn_group_labels.clear()


    for i in encounter.monster_spawns.size():
        var spawn: MonsterSpawn = encounter.monster_spawns[i]
        var hint_name: String = MonsterSpawn.PositionHint.keys()[spawn.position_hint]
        var monster_name: String = spawn.monster.display_name if spawn.monster else "???"
        spawn_group_labels[i] = "%s (%s)" % [monster_name, hint_name]

    var party: = _make_test_party()
    sim.initialize(party, encounter, rng.randi())
    queue_redraw()


func _run_random_encounter() -> void :
    is_random_mode = true
    sim = CombatSimulation.new()
    spawn_group_labels.clear()

    var encounter: = EncounterData.new()

    encounter.monster_spawns = [] as Array[MonsterSpawn]

    var possible_hints: = [
        MonsterSpawn.PositionHint.FRONTLINE, 
        MonsterSpawn.PositionHint.BACKLINE, 
        MonsterSpawn.PositionHint.FLANK, 
        MonsterSpawn.PositionHint.SPREAD, 
        MonsterSpawn.PositionHint.VANGUARD, 
        MonsterSpawn.PositionHint.REAR, 
    ]
    possible_hints.shuffle()
    var num_groups: = rng.randi_range(2, possible_hints.size())

    var dummy_monster: MonsterData = load("res://systems/monsters/normal/zombie.tres")

    for i in range(num_groups):
        var spawn: = MonsterSpawn.new()
        spawn.position_hint = possible_hints[i]
        spawn.count = rng.randi_range(2, 6)
        spawn.monster = dummy_monster
        encounter.monster_spawns.append(spawn)

        var hint_name: String = MonsterSpawn.PositionHint.keys()[possible_hints[i]]
        spawn_group_labels[i] = "Zombie (%s)" % hint_name

    var party: = _make_test_party()
    sim.initialize(party, encounter, rng.randi())
    queue_redraw()


func _make_test_party() -> Array[ExileData]:
    var party: Array[ExileData] = []
    for i in range(4):
        var exile: = ExileData.new()
        exile.name = "Exile " + str(i + 1)
        exile.current_stats = ExileStats.new()
        exile.current_stats.life = 100.0
        exile.current_life = 100.0
        party.append(exile)
    return party






func _world_to_screen(world_pos: Vector2, arena_w: float, arena_h: float) -> Vector2:
    return Vector2(
        world_pos.x / arena_w * DRAW_WIDTH, 
        world_pos.y / arena_h * DRAW_HEIGHT
    ) + DRAW_OFFSET


func _draw() -> void :
    if not sim or sim.combatants.is_empty():
        return

    var arena_w: float = sim._encounter.arena_width
    var arena_h: float = sim._encounter.arena_height


    draw_rect(Rect2(DRAW_OFFSET, Vector2(DRAW_WIDTH, DRAW_HEIGHT)), Color.DARK_SLATE_GRAY, false, 3.0)

    var exile_color: = Color.DODGER_BLUE
    var monster_color: = Color.CRIMSON
    var font: = ThemeDB.fallback_font
    var font_size: = 14

    for c in sim.combatants:
        var draw_pos: = _world_to_screen(c.position, arena_w, arena_h)

        if c.team == CombatEnums.CombatantTeam.EXILES:
            draw_circle(draw_pos, MARKER_RADIUS, exile_color)
            draw_string(font, draw_pos + Vector2(-15, -15), c.display_name, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, exile_color)

        elif c.team == CombatEnums.CombatantTeam.MONSTERS:
            var rect: = Rect2(draw_pos - Vector2(MARKER_RADIUS, MARKER_RADIUS), Vector2(MARKER_RADIUS * 2, MARKER_RADIUS * 2))
            draw_rect(rect, monster_color)

            var label: String = spawn_group_labels.get(c.spawn_group_index, "???")
            draw_string(font, draw_pos + Vector2(-20, -15), label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, monster_color)


    var mode_text: = "RANDOM" if is_random_mode else encounters[encounter_index].display_name
    var header: = "%s  |  Arena: %.0fx%.0f  |  Combatants: %d" % [mode_text, arena_w, arena_h, sim.combatants.size()]
    draw_string(font, Vector2(100, 50), header, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
    draw_string(font, Vector2(100, 75), "LEFT/RIGHT: cycle encounters  |  SPACE: random  |  R: re-roll seed", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.GRAY)
