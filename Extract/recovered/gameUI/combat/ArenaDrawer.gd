extends Control





func _draw() -> void :
    if owner and owner.has_method("draw_arena"):
        owner.draw_arena(self)
