class_name ActiveMission
extends Resource




enum STATUS{
    IN_PROGRESS, 
    COMPLETED, 
    FAILED, 
    RETREATED, 
}

@export var mission_data: MissionData
@export var area_id: WorldEnum.AREAS
@export var assigned_exile_ids: Array[int] = []
@export var status: STATUS = STATUS.IN_PROGRESS


@export var current_encounter_index: int = 0
@export var total_encounters: int = 0


@export var day_started: int = -1






@export var opportunity_instance: OpportunityInstance

var completion_percent: float:
    get:
        if total_encounters <= 0:
            return 0.0
        return float(current_encounter_index) / float(total_encounters)



static func create(p_mission: MissionData, p_area: WorldEnum.AREAS) -> ActiveMission:
    var active: = ActiveMission.new()
    active.mission_data = p_mission
    active.area_id = p_area
    active.total_encounters = p_mission.mission_length
    return active
