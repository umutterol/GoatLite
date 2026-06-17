extends Node2D

func _ready() -> void :
    var coast_missions: Array[MissionData] = MissionManager.get_available_missions(WorldEnum.AREAS.COAST)
    print("Available coast missions: ", coast_missions.size())
    for m: MissionData in coast_missions:
        print("  - ", m.mission_id, " (", m.display_name, ")")
