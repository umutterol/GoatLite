class_name DefeatContext
extends RefCounted





var exile_data: ExileData
var scar_count: int = 0


var source: String = ""
var source_details: String = ""
var zone_danger: int = 0


var was_solo: bool = false
var allies_survived: bool = false
var total_wipe: bool = false


static func create(exile: ExileData, defeat_source: String, details: String = "") -> DefeatContext:
    var context: = DefeatContext.new()
    context.exile_data = exile
    context.scar_count = exile.get_scar_count()
    context.source = defeat_source
    context.source_details = details
    return context


func to_outcome_filter() -> Dictionary:
    return {
        "allies_survived": allies_survived, 
        "total_wipe": total_wipe, 
        "was_solo": was_solo, 
        "zone_danger": zone_danger, 
        "scar_count": scar_count, 
    }
