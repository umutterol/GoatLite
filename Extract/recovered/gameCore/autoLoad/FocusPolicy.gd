extends Node



















const OPT_IN_GROUP: = "keyboard_activate"


func _ready() -> void :
    get_tree().node_added.connect(_on_node_added)


    _scrub_subtree(get_tree().root)


func _on_node_added(node: Node) -> void :
    if node is BaseButton:
        _apply(node)


func _scrub_subtree(root: Node) -> void :
    if root is BaseButton:
        _apply(root)
    for child in root.get_children():
        _scrub_subtree(child)


func _apply(button: BaseButton) -> void :
    if button.is_in_group(OPT_IN_GROUP):
        return
    button.focus_mode = Control.FOCUS_NONE
