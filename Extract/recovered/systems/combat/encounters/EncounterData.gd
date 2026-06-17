class_name EncounterData
extends Resource


enum EncounterType{
    NORMAL, 
    ELITE, 
    BOSS, 
}



@export var encounter_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var encounter_type: EncounterType = EncounterType.NORMAL




@export var area_tags: Array[WorldEnum.AREAS] = []
@export var tags: Array[MissionEnums.ENCOUNTER_TAGS] = []


@export var selection_weight: float = 10.0




@export var monster_spawns: Array[MonsterSpawn] = []




@export var arena_width: float = 30.0
@export var arena_height: float = 20.0





@export var recommended_level: int = 1
