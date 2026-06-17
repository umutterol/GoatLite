class_name AreaConnection extends Resource






@export var target_area: WorldEnum.AREAS



@export var requirements: Array[ProgressionRequirement] = []



@export_range(0.0, 1.0) var discovery_chance: float = 0.0



@export var scouting_modifies_chance: bool = true



@export var trigger_mission_id: String = ""



@export var trigger_mission_tags: Array[MissionEnums.MISSION_TAGS] = []
