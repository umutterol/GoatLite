class_name ScoutingDiscovery extends Resource















enum DISCOVERY_TYPE{

    MONSTER_INFO, 
    DROP_TABLE, 
    SHORTCUT, 
    HIDDEN_CACHE, 
    LORE, 
}


@export var discovery_type: DISCOVERY_TYPE


@export var discovery_id: String


@export_range(0.0, 100.0) var scouting_threshold: float


@export_range(0.0, 1.0) var base_chance: float


@export var description: String
