class_name ScarredIcon
extends PanelContainer








@onready var count_label: Label = %CountLabel


func set_count(n: int) -> void :


    if not is_node_ready():
        await ready
    if n <= 1:
        count_label.visible = false
    else:
        count_label.visible = true
        count_label.text = "×%d" % n
