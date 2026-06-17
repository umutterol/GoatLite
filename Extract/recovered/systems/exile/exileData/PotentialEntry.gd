class_name PotentialEntry
extends Resource

@export var tag: String = ""
@export var total_value: float = 1.0
@export var is_hidden: bool = false
@export var sources: Array[PotentialSource] = []

func _init(p_tag: String = ""):
    tag = p_tag

func add_source(source_name: String, value: float):
    var source = PotentialSource.new()
    source.source_name = source_name
    source.value = value
    sources.append(source)


    recalculate_total()

func recalculate_total():
    total_value = 1.0
    for source in sources:
        total_value += source.value
    total_value = clamp(total_value, 0.0, 5.0)

func reveal():
    is_hidden = false

func get_display_value() -> float:
    return total_value if not is_hidden else 0.0

func get_breakdown_string() -> String:
    if is_hidden:
        return "%s: ??? (Hidden)" % tag

    var parts = []
    for source in sources:
        var value_sign = "+" if source.value >= 0 else ""
        parts.append("%s%.1f from %s" % [value_sign, source.value, source.source_name])

    return "%s: %.1f (%s)" % [tag, total_value, ", ".join(parts)]
