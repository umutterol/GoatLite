class_name AreaProgress extends Resource

@export var area_id: WorldEnum.AREAS
@export var unlocked: bool = false
@export var scouting_progress: float = 0.0
@export var current_area_level: int = 1


@export var completed_mission_ids: Array[String] = []
@export var total_missions_completed: int = 0
@export var tag_completion_counts: Dictionary = {}


@export var boss_defeated: bool = false
@export var boss_last_completed_day: int = -1


@export var discovered_mission_ids: Array[String] = []







@export var active_opportunities: Dictionary = {}






@export var last_opportunity_completion_day: Dictionary = {}






@export var captured_exile_ids: Array[int] = []






@export var long_lost_exile_ids: Array[int] = []






@export var seen_monster_ids: Array[String] = []
