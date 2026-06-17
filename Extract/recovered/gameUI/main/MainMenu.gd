












class_name MainMenu
extends Control

const FADE_OUT_SECONDS: float = 1.0

const MessageModalScene: = preload("res://gameUI/smallComponents/MessageModal.tscn")


const URL_TWITCH: String = "https://twitch.tv/ziggydlive"
const URL_YOUTUBE: String = "https://www.youtube.com/@ziggydgaming"
const URL_ITCH: String = "https://ziggyd.itch.io/"



@export_multiline var patch_notes_body: String = "[b]0.1.0 beta[/b]\n\n- Initial release.\n- Edit this text on the MainMenu node in the inspector."
@export_multiline var roadmap_body: String = "[b]Planned[/b]\n\n- Replace this placeholder with your roadmap items.\n- BBCode like [color=#c8a04b]colored text[/color] and [b]bold[/b] work here."
@export_multiline var new_game_warning_body: String = "You have an existing save game.\n\nStarting a new game won't delete it [i]immediately[/i], but the next save (including autosave) will [b]overwrite[/b] your current progress.\n\nUse [b]Load Game[/b] if you'd rather continue your existing run."

@onready var new_game_button: Button = %NewGameButton
@onready var load_game_button: Button = %LoadGameButton
@onready var quit_button: Button = %QuitButton
@onready var patch_notes_button: Button = %PatchNotes
@onready var roadmap_button: Button = %RoadMap
@onready var fade_overlay: ColorRect = $FadeOverlay

@onready var version_label: Label = %version
@onready var twitch_text: LinkButton = $MarginContainer / VBoxContainer / TwitchLink / Label
@onready var twitch_icon: TextureButton = $MarginContainer / VBoxContainer / TwitchLink / Twitch
@onready var youtube_text: LinkButton = $MarginContainer / VBoxContainer / YouTubeLink / Label2
@onready var youtube_icon: TextureButton = $MarginContainer / VBoxContainer / YouTubeLink / YT
@onready var itch_text: LinkButton = $MarginContainer / VBoxContainer / ItchioLink / Label3
@onready var itch_icon: TextureButton = $MarginContainer / VBoxContainer / ItchioLink / ITCHIO


func _ready() -> void :
    new_game_button.pressed.connect(_on_new_game_pressed)
    load_game_button.pressed.connect(_on_load_game_pressed)
    patch_notes_button.pressed.connect(_on_patch_notes_pressed)
    roadmap_button.pressed.connect(_on_roadmap_pressed)



    quit_button.visible = OS.has_feature("windows")
    quit_button.pressed.connect(_on_quit_pressed)




    var version_string: String = ProjectSettings.get_setting("application/config/version", "0.0.0")
    version_label.text = version_string



    twitch_text.pressed.connect(_open_url.bind(URL_TWITCH))
    twitch_icon.pressed.connect(_open_url.bind(URL_TWITCH))
    youtube_text.pressed.connect(_open_url.bind(URL_YOUTUBE))
    youtube_icon.pressed.connect(_open_url.bind(URL_YOUTUBE))
    itch_text.pressed.connect(_open_url.bind(URL_ITCH))
    itch_icon.pressed.connect(_open_url.bind(URL_ITCH))





    var has_save: bool = _has_existing_save()
    load_game_button.disabled = not has_save
    if not has_save:
        load_game_button.tooltip_text = "No saved games found"




    fade_overlay.visible = true
    fade_overlay.color = Color(0, 0, 0, 1)
    var tween: = create_tween()
    tween.tween_property(fade_overlay, "color:a", 0.0, FADE_OUT_SECONDS)
    tween.tween_callback( func(): fade_overlay.visible = false)




func _on_new_game_pressed() -> void :


    if _has_existing_save():
        _show_new_game_confirm()
        return
    _start_new_game()


func _show_new_game_confirm() -> void :
    var modal: MessageModal = MessageModalScene.instantiate()
    modal.setup(
        "Start a New Game?", 
        new_game_warning_body, 
        "Start New Game", 
        "Cancel", 
    )
    add_child(modal)
    modal.confirmed.connect(_start_new_game)



func _start_new_game() -> void :

    new_game_button.disabled = true
    load_game_button.disabled = true


    GameState.reset_for_new_game()
    AreaManager.reset_for_new_game()
    await _fade_to_black()
    SceneRouter.to_game_start_recruitment()


func _has_existing_save() -> bool:
    return (
        SaveManager.slot_exists(SaveManager.MANUAL_SLOT_DEFAULT)
        or SaveManager.slot_exists(SaveManager.AUTOSAVE_SLOT)
    )




func _on_load_game_pressed() -> void :
    new_game_button.disabled = true
    load_game_button.disabled = true



    var target_slot: int = SaveManager.most_recent_slot()
    if target_slot < 0:

        push_warning("MainMenu: Load pressed with no saves available")
        new_game_button.disabled = false
        return





    await _fade_to_black()
    var ok: bool = SaveManager.load_from_slot(target_slot)
    if not ok:
        push_error("MainMenu: load failed; staying on menu")

        _fade_from_black()
        new_game_button.disabled = false
        load_game_button.disabled = false
        return
    SceneRouter.to_guild()




func _fade_to_black() -> void :
    fade_overlay.visible = true
    fade_overlay.color = Color(0, 0, 0, 0)
    var tween: = create_tween()
    tween.tween_property(fade_overlay, "color:a", 1.0, FADE_OUT_SECONDS)
    await tween.finished


func _fade_from_black() -> void :
    var tween: = create_tween()
    tween.tween_property(fade_overlay, "color:a", 0.0, FADE_OUT_SECONDS)
    tween.tween_callback( func(): fade_overlay.visible = false)




func _open_url(url: String) -> void :


    OS.shell_open(url)




func _on_patch_notes_pressed() -> void :
    _show_info_modal("Patch Notes", patch_notes_body)


func _on_roadmap_pressed() -> void :
    _show_info_modal("Roadmap", roadmap_body)


func _show_info_modal(title: String, body_bbcode: String) -> void :
    var modal: MessageModal = MessageModalScene.instantiate()
    modal.setup(title, body_bbcode)
    add_child(modal)




func _on_quit_pressed() -> void :



    get_tree().quit()
