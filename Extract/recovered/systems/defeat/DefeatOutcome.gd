class_name DefeatOutcome
extends Resource





@export var outcome_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""


@export var weight: float = 10.0


@export_group("Conditions")
@export var requires_allies_survived: bool = false
@export var requires_total_wipe: bool = false
@export var requires_solo: bool = false
@export var min_zone_danger: int = 0
@export var min_scar_count: int = 0


@export_group("Consequences")
@export var vitality_cost_percent: float = 0.0
@export var morale_cost: float = 0.0
@export var recovery_days: int = 0

@export_subgroup("Scars")
@export var assigns_scar: bool = false
@export var forced_scar_trait_id: String = ""

@export_subgroup("Items")
@export var items_damaged: int = 0
@export var item_damage_severity: int = 0
@export var items_destroyed: int = 0

@export_subgroup("Capture")



@export var capture_duration_days: int = 0






@export_range(1, 14, 1) var rescue_timeout_days: int = 3


func is_valid_for_context(context: Dictionary) -> bool:
    if requires_allies_survived and not context.get("allies_survived", false):
        return false
    if requires_total_wipe and not context.get("total_wipe", false):
        return false
    if requires_solo and not context.get("was_solo", false):
        return false
    if min_zone_danger > context.get("zone_danger", 0):
        return false
    if min_scar_count > context.get("scar_count", 0):
        return false
    return true
