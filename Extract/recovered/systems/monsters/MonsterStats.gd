@tool
class_name MonsterStats
extends ExileStats



















const HIDDEN_FIELDS: = [



    "second_wind_chance", 
    "second_wind_amount", 
    "second_wind_threshold", 




    "morale", 
    "max_morale", 
    "morale_gain", 
    "morale_loss_resistance", 
    "victory_morale_bonus", 
    "well_fed_rest_morale_bonus", 




    "scouting", 
    "survival", 
    "scavenging", 
]





func _validate_property(property: Dictionary) -> void :
    if property.name in HIDDEN_FIELDS:
        property.usage &= ~ PROPERTY_USAGE_EDITOR
