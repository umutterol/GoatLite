class_name Main
extends Control






func _ready() -> void :



    if OS.has_feature("windows") and not OS.has_feature("editor"):
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

    SceneRouter.to_main_menu()
