









class_name GameStartRecruitment
extends Control

const FADE_OUT_SECONDS: float = 2.0


const FADE_IN_SECONDS: float = 1.0
const TRANSITION_HOLD_SECONDS: float = 1.6
const TRANSITION_FADE_SECONDS: float = 0.6

const EXILES_PER_RAFT: int = 2



const MAX_TRAIT_REROLL_ATTEMPTS: int = 40

@onready var left_raft: RaftPanel = $Margins / Layout / RaftsRow / LeftRaft
@onready var right_raft: RaftPanel = $Margins / Layout / RaftsRow / RightRaft
@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var transition_label: Label = $FadeOverlay / TransitionLabel


func _ready() -> void :
    left_raft.setup("Raft One", _roll_exiles())
    right_raft.setup("Raft Two", _roll_exiles())

    left_raft.join_confirmed.connect(_on_join_confirmed)
    right_raft.join_confirmed.connect(_on_join_confirmed)

    _play_entry_fade_in()







func _play_entry_fade_in() -> void :
    if fade_overlay == null:
        return
    fade_overlay.visible = true
    fade_overlay.color = Color(0, 0, 0, 1)
    if transition_label != null:
        transition_label.modulate = Color(1, 1, 1, 0)
    var tween: = create_tween()
    tween.tween_property(fade_overlay, "color:a", 0.0, FADE_IN_SECONDS)
    tween.tween_callback( func(): fade_overlay.visible = false)















func _roll_exiles() -> Array[ExileData]:
    var result: Array[ExileData] = []
    for i in range(EXILES_PER_RAFT):
        result.append(ExileGenerator.create_exile({"level": 1}))


    if not _raft_has_uncommon_class(result):
        var class_idx: = _index_of_lowest_class_rarity(result)
        result[class_idx] = ExileGenerator.create_exile({
            "level": 1, 
            "min_class_rarity": ClassDefinition.ClassRarity.UNCOMMON, 
        })




    for attempt in range(MAX_TRAIT_REROLL_ATTEMPTS):
        if _raft_has_uncommon_trait(result):
            return result
        var idx: = _pick_trait_reroll_index(result)
        result[idx] = ExileGenerator.create_exile({"level": 1})
        if not _raft_has_uncommon_class(result):
            result[idx] = ExileGenerator.create_exile({
                "level": 1, 
                "min_class_rarity": ClassDefinition.ClassRarity.UNCOMMON, 
            })



    push_warning("GameStartRecruitment: failed to force uncommon trait after %d attempts" % MAX_TRAIT_REROLL_ATTEMPTS)
    return result




func _raft_has_uncommon_class(exiles: Array[ExileData]) -> bool:
    for exile in exiles:
        if _class_rarity_of(exile) >= ClassDefinition.ClassRarity.UNCOMMON:
            return true
    return false


func _raft_has_uncommon_trait(exiles: Array[ExileData]) -> bool:
    for exile in exiles:
        if _peak_trait_rarity(exile) >= TraitDefinition.TraitRarity.UNCOMMON:
            return true
    return false



func _peak_trait_rarity(exile: ExileData) -> int:
    var peak: int = -1
    for trait_id in exile.traits:
        var trait_def: TraitDefinition = TraitLibrary.get_trait_by_id(trait_id)
        if trait_def == null:
            continue
        if trait_def.rarity > peak:
            peak = trait_def.rarity
    return peak


func _class_rarity_of(exile: ExileData) -> int:
    if exile == null or exile.class_definition == null:
        return ClassDefinition.ClassRarity.COMMON
    return exile.class_definition.rarity


func _index_of_lowest_class_rarity(exiles: Array[ExileData]) -> int:
    var lowest_index: = 0
    var lowest_value: int = _class_rarity_of(exiles[0])
    for i in range(1, exiles.size()):
        var value: = _class_rarity_of(exiles[i])
        if value < lowest_value:
            lowest_value = value
            lowest_index = i
    return lowest_index


func _index_of_lowest_peak_trait_rarity(exiles: Array[ExileData]) -> int:
    var lowest_index: = 0
    var lowest_value: int = _peak_trait_rarity(exiles[0])
    for i in range(1, exiles.size()):
        var value: = _peak_trait_rarity(exiles[i])
        if value < lowest_value:
            lowest_value = value
            lowest_index = i
    return lowest_index







func _pick_trait_reroll_index(exiles: Array[ExileData]) -> int:
    var idx: = _index_of_lowest_peak_trait_rarity(exiles)
    var other: = 1 - idx
    var idx_is_uncommon: = _class_rarity_of(exiles[idx]) >= ClassDefinition.ClassRarity.UNCOMMON
    var other_is_uncommon: = _class_rarity_of(exiles[other]) >= ClassDefinition.ClassRarity.UNCOMMON
    if idx_is_uncommon and not other_is_uncommon:
        return other
    return idx




func _on_join_confirmed(raft: RaftPanel) -> void :

    left_raft.set_locked(true)
    right_raft.set_locked(true)

    _apply_raft_to_game_state(raft)
    await _play_transition()
    SceneRouter.to_guild()


func _apply_raft_to_game_state(raft: RaftPanel) -> void :
    for exile in raft.exiles:
        GameState.add_exile(exile)



    StarterGearSeeder.seed_for_exiles(raft.exiles)


    GameState.pending_intro_fade = true






func _play_transition() -> void :
    fade_overlay.visible = true
    fade_overlay.color = Color(0, 0, 0, 0)
    transition_label.modulate = Color(1, 1, 1, 0)


    var tween_fade_in: = create_tween()
    tween_fade_in.tween_property(fade_overlay, "color", Color(0, 0, 0, 1), FADE_OUT_SECONDS)
    await tween_fade_in.finished


    var tween_label_in: = create_tween()
    tween_label_in.tween_property(transition_label, "modulate:a", 1.0, TRANSITION_FADE_SECONDS)
    await tween_label_in.finished

    await get_tree().create_timer(TRANSITION_HOLD_SECONDS).timeout

    var tween_label_out: = create_tween()
    tween_label_out.tween_property(transition_label, "modulate:a", 0.0, TRANSITION_FADE_SECONDS)
    await tween_label_out.finished
