class_name OpportunityInstance
extends Resource

















@export var instance_id: String = ""



@export var template_mission_id: String = ""



@export var day_appeared: int = 0




@export var timeout_days_override: int = -1





@export var display_name_override: String = ""






@export var context: Dictionary = {}








@export var runtime_mission_data: MissionData = null







func get_effective_timeout_days(template: MissionData) -> int:
    if timeout_days_override >= 0:
        return timeout_days_override
    if template == null:
        return -1
    return template.timeout_days



func get_effective_display_name(template: MissionData) -> String:
    if not display_name_override.is_empty():
        return display_name_override
    if template == null:
        return ""
    return template.display_name
