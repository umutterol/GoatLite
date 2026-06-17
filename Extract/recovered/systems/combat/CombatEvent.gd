class_name CombatEvent
extends RefCounted






var tick: float = 0.0


var event_type: CombatEnums.CombatEventType









var data: Dictionary = {}


static func create(
    tick_time: float, 
    type: CombatEnums.CombatEventType, 
    event_data: Dictionary = {}
) -> CombatEvent:
    var event: = CombatEvent.new()
    event.tick = tick_time
    event.event_type = type
    event.data = event_data
    return event



func _to_string() -> String:
    var type_name: String = CombatEnums.CombatEventType.keys()[event_type]
    return "[%.1fs] %s %s" % [tick, type_name, data]
