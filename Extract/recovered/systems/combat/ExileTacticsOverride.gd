class_name ExileTacticsOverride
extends Resource






























@export var target_priority: int = -1














@export var target_rules: Array[TargetRule] = []









@export var fallback_picker: int = TargetRule.Picker.NEAREST

















@export_range(-1.0, 10.0, 0.1, "suffix:s") var target_lock_seconds: float = -1.0














@export var kite_profile: int = KiteProfile.Profile.INHERIT














func has_any_override() -> bool:
    if not target_rules.is_empty():
        return true
    if fallback_picker != TargetRule.Picker.NEAREST:
        return true
    if target_lock_seconds >= 0.0:
        return true
    if kite_profile != KiteProfile.Profile.INHERIT:
        return true
    return false
