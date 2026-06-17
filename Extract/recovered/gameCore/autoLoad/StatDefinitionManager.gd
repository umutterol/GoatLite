extends Node

var stat_definitions: Dictionary = {}

func _ready():
    load_all_stat_definitions()

func load_all_stat_definitions():

    for file_path in ResourceDirScan.list_tres_files_recursive("res://systems/exile/stats/definitions/"):
        var resource = load(file_path)
        if resource is StatDefinition:
            stat_definitions[resource.stat_id] = resource

func get_stat_definition(stat_id: String) -> StatDefinition:
    return stat_definitions.get(stat_id, null)
