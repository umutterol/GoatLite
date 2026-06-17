extends Node












signal scene_about_to_change

const GUILD: PackedScene = preload("res://gameUI/guild/GuildScene.tscn")
const MISSION_BOARD: PackedScene = preload("res://gameUI/missions/MissionBoardScreen.tscn")
const COMBAT_PLAYBACK: PackedScene = preload("res://gameUI/combat/CombatPlaybackScreen.tscn")
const MISSION_REPORT: PackedScene = preload("res://gameUI/missions/MissionReportScreen.tscn")
const RESCUED_EXILE: PackedScene = preload("res://gameUI/missions/RescuedExileScreen.tscn")
const LONG_LOST_SURFACED: PackedScene = preload("res://gameUI/missions/LongLostSurfacedModal.tscn")
const GAME_START_RECRUITMENT: PackedScene = preload("res://gameUI/recruitment/GameStartRecruitment.tscn")
const MAIN_MENU: PackedScene = preload("res://gameUI/main/MainMenu.tscn")


func to_game_start_recruitment() -> void :
    _change_to(GAME_START_RECRUITMENT)


func to_main_menu() -> void :
    _change_to(MAIN_MENU)


func to_guild() -> void :
    _change_to(GUILD)


func to_mission_board() -> void :
    _change_to(MISSION_BOARD)


func to_combat_playback() -> void :
    _change_to(COMBAT_PLAYBACK)


func to_mission_report() -> void :
    _change_to(MISSION_REPORT)


func to_rescued_exile_screen() -> void :
    _change_to(RESCUED_EXILE)


func to_long_lost_surfaced_modal() -> void :
    _change_to(LONG_LOST_SURFACED)


func _change_to(scene: PackedScene) -> void :
    if scene == null:
        push_error("SceneRouter: scene is null, cannot change")
        return


    scene_about_to_change.emit()


    get_tree().change_scene_to_packed.call_deferred(scene)
