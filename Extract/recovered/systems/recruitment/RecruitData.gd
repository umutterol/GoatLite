class_name RecruitData
extends Resource

@export var exile_data: ExileData




@export var food_cost: int = 3
@export var chaos_cost: int = 30
@export var scrap_cost: int = 0
@export var exalt_cost: int = 0
@export var is_desperate: bool = false
@export var is_event_recruit: bool = false
@export var recruit_id: String = ""

func _init():
    recruit_id = "recruit_" + str(Time.get_unix_time_from_system())

func apply_desperate_modifier():
    is_desperate = true
    food_cost = int(food_cost * 0.5)
    chaos_cost = int(chaos_cost * 0.5)
    scrap_cost = int(scrap_cost * 0.5)
    exalt_cost = int(exalt_cost * 0.5)


    var reduction = randf_range(0.4, 0.6)
    exile_data.current_stats.vitality *= (1.0 - reduction)
    exile_data.current_stats.morale *= (1.0 - reduction)




func has_any_cost() -> bool:
    return food_cost > 0 or chaos_cost > 0 or scrap_cost > 0 or exalt_cost > 0
