class_name ProgressionRequirement extends Resource






enum TYPE{
    MISSION_COMPLETED, 
    MISSION_TAG_COUNT, 
    TOTAL_MISSIONS_IN_AREA, 
    SCOUTING_PERCENT, 
    BOSS_DEFEATED, 
}


@export var type: TYPE



@export var area: WorldEnum.AREAS


@export var mission_id: String = ""


@export var tag: MissionEnums.MISSION_TAGS






@export var required_value: float = 0.0
