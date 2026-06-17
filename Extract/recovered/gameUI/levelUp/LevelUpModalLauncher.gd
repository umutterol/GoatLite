class_name LevelUpModalLauncher
extends RefCounted









const MODAL_SCENE: PackedScene = preload("res://gameUI/levelUp/LevelUpModal.tscn")







static func launch_for(exile: ExileData) -> LevelUpModal:
    if exile == null:
        push_warning("LevelUpModalLauncher.launch_for(null)")
        return null

    var tree: SceneTree = Engine.get_main_loop() as SceneTree



    for child in tree.current_scene.get_children():
        if child is LevelUpModal:
            (child as LevelUpModal).rebind(exile)
            return child

    var modal: LevelUpModal = MODAL_SCENE.instantiate()
    modal.exile = exile
    tree.current_scene.add_child(modal)
    return modal
