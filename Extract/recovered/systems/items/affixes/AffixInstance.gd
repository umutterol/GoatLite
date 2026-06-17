class_name AffixInstance
extends Resource












@export var affix_base: AffixBase
@export var rolled_value: Variant = 0.0
@export var tier_level: int = 1


func _init(p_affix_base: AffixBase = null, p_value: Variant = null, p_tier: int = 1) -> void :
    affix_base = p_affix_base
    if p_value != null:
        rolled_value = p_value
    tier_level = p_tier





func get_value() -> float:
    if rolled_value is Dictionary:
        return (rolled_value.min + rolled_value.max) / 2.0
    return float(rolled_value)





func get_display_text() -> String:
    if not affix_base:
        return "Invalid Affix"




    var is_percent_mod: bool = affix_base.modifier_type in [
        AffixBase.ModifierType.PERCENT_INCREASED, 
        AffixBase.ModifierType.PERCENT_REDUCED, 
        AffixBase.ModifierType.PERCENT_MORE, 
        AffixBase.ModifierType.PERCENT_LESS, 
    ]
    var effective_prefix: String = "" if is_percent_mod else affix_base.value_prefix

    var value_text: String = ""
    if rolled_value is Dictionary:
        var min_val: float = float(rolled_value.min)
        var max_val: float = float(rolled_value.max)
        var min_formatted: String = str(int(min_val)) if min_val == int(min_val) else "%.1f" % min_val
        var max_formatted: String = str(int(max_val)) if max_val == int(max_val) else "%.1f" % max_val
        value_text = effective_prefix + min_formatted + "-" + max_formatted + affix_base.value_suffix
    else:
        var formatted_value: String = str(int(rolled_value)) if float(rolled_value) == int(rolled_value) else "%.1f" % rolled_value
        value_text = effective_prefix + formatted_value + affix_base.value_suffix

    match affix_base.modifier_type:
        AffixBase.ModifierType.PERCENT_INCREASED:
            return value_text + " increased " + affix_base.display_name
        AffixBase.ModifierType.PERCENT_REDUCED:
            return value_text + " reduced " + affix_base.display_name
        AffixBase.ModifierType.PERCENT_MORE:
            return value_text + " more " + affix_base.display_name
        AffixBase.ModifierType.PERCENT_LESS:
            return value_text + " less " + affix_base.display_name
        AffixBase.ModifierType.FLAT_OVERRIDE:
            return affix_base.display_name + " is always " + value_text
        _:



            return value_text + " to " + affix_base.display_name
