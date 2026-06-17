class_name AffixValueTier
extends Resource



@export var item_level: int = 1
@export_group("Value Configuration")
@export var is_range_value: bool = false


@export var min_value: float = 0.0
@export var max_value: float = 0.0


@export_subgroup("Range Values")
@export var min_value_low: float = 0.0
@export var min_value_high: float = 0.0
@export var max_value_low: float = 0.0
@export var max_value_high: float = 0.0


func to_dictionary() -> Dictionary:
    if is_range_value:
        return {
            "min_low": min_value_low, 
            "min_high": min_value_high, 
            "max_low": max_value_low, 
            "max_high": max_value_high
        }
    else:
        return {
            "min": min_value, 
            "max": max_value
        }


func _validate_property(property: Dictionary) -> void :

    if property.name in ["min_value", "max_value"]:
        property.usage = PROPERTY_USAGE_DEFAULT if not is_range_value else PROPERTY_USAGE_NO_EDITOR


    if property.name in ["min_value_low", "min_value_high", "max_value_low", "max_value_high"]:
        property.usage = PROPERTY_USAGE_DEFAULT if is_range_value else PROPERTY_USAGE_NO_EDITOR
