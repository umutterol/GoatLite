class_name TargetRule
extends Resource











































enum Filter{
    ALL, 
    ATTACKING_ME, 
    ATTACKING_ANY_ALLY, 
    HAS_STATUS, 
    LACKS_STATUS, 
    IN_RANGE, 
}








enum Picker{
    NEAREST, 
    FARTHEST, 
    LOWEST_CURRENT_HP, 
    HIGHEST_CURRENT_HP, 
    LOWEST_MAX_HP, 
    HIGHEST_MAX_HP, 
    FASTEST, 
    SLOWEST, 
    RANDOM, 
    ANY, 
}




@export var filter: Filter = Filter.IN_RANGE





@export var status_id: StringName = &""







@export var require_in_range: bool = false


@export var picker: Picker = Picker.NEAREST




func describe() -> String:
    var parts: PackedStringArray = []
    parts.append(_picker_label(picker))
    if filter != Filter.ALL:
        parts.append(_filter_label(filter, status_id))
    if require_in_range:
        parts.append("in range")
    return ", ".join(parts)


static func _filter_label(f: Filter, sid: StringName) -> String:
    match f:
        Filter.IN_RANGE: return "in range"
        Filter.ATTACKING_ME: return "attacking me"
        Filter.ATTACKING_ANY_ALLY: return "attacking an ally"
        Filter.HAS_STATUS: return "with %s" % (str(sid) if sid != &"" else "<status>")
        Filter.LACKS_STATUS: return "without %s" % (str(sid) if sid != &"" else "<status>")
        _: return ""


static func _picker_label(p: Picker) -> String:
    match p:
        Picker.NEAREST: return "Nearest"
        Picker.FARTHEST: return "Farthest"
        Picker.LOWEST_CURRENT_HP: return "Lowest current HP"
        Picker.HIGHEST_CURRENT_HP: return "Highest current HP"
        Picker.LOWEST_MAX_HP: return "Lowest max HP"
        Picker.HIGHEST_MAX_HP: return "Highest max HP"
        Picker.FASTEST: return "Fastest"
        Picker.SLOWEST: return "Slowest"
        Picker.RANDOM: return "Random"
        Picker.ANY: return "Any"
        _: return "?"
