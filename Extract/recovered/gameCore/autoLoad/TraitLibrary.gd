extends Node

var all_traits: Array[TraitDefinition] = []
var traits_by_id: Dictionary = {}
var background_traits: Array[TraitDefinition] = []
var learned_traits: Array[TraitDefinition] = []
var scar_traits: Array[TraitDefinition] = []

func _ready():
    load_all_traits()
    index_traits()

func load_all_traits():

    for file_path in ResourceDirScan.list_tres_files_recursive("res://systems/exile/traits/"):
        var resource = load(file_path)
        if resource is TraitDefinition:
            all_traits.append(resource)
            traits_by_id[resource.trait_id] = resource

func index_traits():
    background_traits.clear()
    learned_traits.clear()
    scar_traits.clear()

    var i = 0
    while i < all_traits.size():
        var current_trait = all_traits[i]
        if current_trait.category == TraitDefinition.TraitCategory.BACKGROUND:
            background_traits.append(current_trait)
        elif current_trait.category == TraitDefinition.TraitCategory.SCAR:
            scar_traits.append(current_trait)
        else:
            learned_traits.append(current_trait)
        i += 1

func get_all_traits() -> Array[TraitDefinition]:
    return all_traits.duplicate()

func get_trait_by_id(trait_id: String) -> TraitDefinition:
    return traits_by_id.get(trait_id, null)

func get_background_traits() -> Array[TraitDefinition]:
    return background_traits.duplicate()

func get_learned_traits() -> Array[TraitDefinition]:
    return learned_traits.duplicate()

func get_scar_traits() -> Array[TraitDefinition]:
    return scar_traits.duplicate()
