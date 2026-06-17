













class_name GuildMenuModal
extends CanvasLayer

const MessageModalScene: = preload("res://gameUI/smallComponents/MessageModal.tscn")

@onready var backdrop: ColorRect = $Backdrop
@onready var save_button: Button = %SaveButton
@onready var load_button: Button = %LoadButton
@onready var settings_button: Button = %SettingsButton
@onready var return_button: Button = %ReturnButton
@onready var close_button: Button = %CloseButton
@onready var quit_button: Button = %QuitButton

var _saved_this_session: bool = false


func _ready() -> void :
    save_button.pressed.connect(_on_save_pressed)
    load_button.pressed.connect(_on_load_pressed)
    return_button.pressed.connect(_on_return_pressed)
    close_button.pressed.connect(_close)


    quit_button.visible = OS.has_feature("windows")
    quit_button.pressed.connect(_on_quit_pressed)

    backdrop.gui_input.connect(_on_backdrop_input)




    SaveManager.save_completed.connect(_on_save_completed)


    if SaveManager.most_recent_slot() < 0:
        load_button.disabled = true
        load_button.tooltip_text = "No saved games found"


    settings_button.disabled = true
    settings_button.tooltip_text = "Settings not yet available in this build"




func _on_save_pressed() -> void :
    SaveManager.save_to_slot(SaveManager.MANUAL_SLOT_DEFAULT, "Manual save")



func _on_load_pressed() -> void :
    var target_slot: int = SaveManager.most_recent_slot()
    if target_slot < 0:
        return



    var modal: MessageModal = MessageModalScene.instantiate()
    modal.setup(
        "Load Game", 
        "Replace current game with the most recent saved game?", 
        "Load", 
        "Cancel", 
    )
    add_child(modal)
    modal.confirmed.connect( func():
        SaveManager.load_from_slot(target_slot)
        _close()
    )


func _on_return_pressed() -> void :
    if _saved_this_session:
        _do_return_to_main_menu()
        return
    _show_unsaved_warning()


func _show_unsaved_warning() -> void :
    var modal: MessageModal = MessageModalScene.instantiate()
    modal.setup(
        "Return to Main Menu?", 
        "You haven't saved this session.\n\nReturning to the Main Menu will discard any changes made since the last save (gear, party layout, tactics, etc.).\n\n[i]Note: end-of-day autosaves still exist on disk, but any tweaks made today since then will be lost.[/i]", 
        "Return Anyway", 
        "Cancel", 
    )
    add_child(modal)
    modal.confirmed.connect(_do_return_to_main_menu)


func _do_return_to_main_menu() -> void :
    SceneRouter.to_main_menu()




func _on_save_completed(slot: int) -> void :
    if slot == SaveManager.MANUAL_SLOT_DEFAULT:
        _saved_this_session = true




func _close() -> void :
    queue_free()


func _on_backdrop_input(event: InputEvent) -> void :
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        _close()




func handle_escape() -> bool:
    _close()
    return true




func _on_quit_pressed() -> void :





    get_tree().quit()
