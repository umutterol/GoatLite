extends Node

var all_passives: Array[PassiveDefinition] = []
var passives_by_id: Dictionary = {}
var passives_by_tag: Dictionary = {}

func _ready():
    load_all_passives()
    index_passives()

func load_all_passives():

    for file_path in ResourceDirScan.list_tres_files_recursive("res://systems/exile/passives/definitions/"):
        var resource = load(file_path)
        if resource is PassiveDefinition:
            all_passives.append(resource)
            passives_by_id[resource.passive_id] = resource

func index_passives():
    for passive in all_passives:
        for tag in passive.get_all_tags():
            if not passives_by_tag.has(tag):
                passives_by_tag[tag] = []
            passives_by_tag[tag].append(passive)

func get_all_passives() -> Array[PassiveDefinition]:
    return all_passives.duplicate()

func get_passive_by_id(passive_id: String) -> PassiveDefinition:
    return passives_by_id.get(passive_id, null)

func get_passives_by_tag(tag: String) -> Array[PassiveDefinition]:
    return passives_by_tag.get(tag, []).duplicate()
