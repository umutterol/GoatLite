class_name MoraleStateIcon
extends PanelContainer






















@export var state: String = "high"


func bind(exile: ExileData) -> void :
    if exile == null:
        visible = false
        return
    match state:
        "high":
            visible = MoraleManager.is_morale_high(exile)
        "low":
            visible = MoraleManager.is_morale_low(exile)
        _:
            push_warning("MoraleStateIcon: unknown state '%s' — hiding." % state)
            visible = false
