extends Node






























const COMBAT_PLAYBACK_SCENE_PATH: String = "res://gameUI/combat/CombatPlaybackScreen.tscn"


func _unhandled_input(event: InputEvent) -> void :
    if not (event is InputEventKey):
        return
    var key_event: InputEventKey = event
    if key_event.echo:
        return





    var is_enter: bool = (
        key_event.physical_keycode == KEY_ENTER
        or key_event.physical_keycode == KEY_KP_ENTER
    )
    if key_event.pressed and key_event.alt_pressed and is_enter:
        if OS.has_feature("windows"):
            _toggle_fullscreen()
            get_viewport().set_input_as_handled()
        return

    if key_event.physical_keycode != KEY_SPACE:
        return
    if _is_combat_playback_active():
        return



    var esc: = InputEventKey.new()
    esc.keycode = KEY_ESCAPE
    esc.physical_keycode = KEY_ESCAPE
    esc.pressed = key_event.pressed
    esc.echo = false
    get_viewport().push_input(esc)


    get_viewport().set_input_as_handled()


func _is_combat_playback_active() -> bool:
    var tree: SceneTree = get_tree()
    if tree == null or tree.current_scene == null:
        return false
    return tree.current_scene.scene_file_path == COMBAT_PLAYBACK_SCENE_PATH







func _toggle_fullscreen() -> void :
    var mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
    var is_fullscreen: bool = (
        mode == DisplayServer.WINDOW_MODE_FULLSCREEN
        or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
    )
    if is_fullscreen:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
    else:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
