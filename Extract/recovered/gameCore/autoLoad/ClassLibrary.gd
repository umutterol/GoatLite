
extends Node


var _all_classes: Array[ClassDefinition] = []
var _classes_by_id: Dictionary = {}
var _classes_by_rarity: Dictionary = {
    ClassDefinition.ClassRarity.COMMON: [], 
    ClassDefinition.ClassRarity.UNCOMMON: [], 
    ClassDefinition.ClassRarity.RARE: [], 
    ClassDefinition.ClassRarity.LEGENDARY: []
}

func _ready():
    _load_all_classes()

static func get_class_by_id(class_id: String) -> ClassDefinition:
    if ClassLibrary and ClassLibrary._classes_by_id.has(class_id):
        return ClassLibrary._classes_by_id[class_id]
    push_error("ClassLibrary: Unknown class ID: " + class_id)
    return null

static func get_all_classes() -> Array[ClassDefinition]:
    if ClassLibrary:
        return ClassLibrary._all_classes
    return []

static func get_classes_by_rarity(rarity: ClassDefinition.ClassRarity) -> Array[ClassDefinition]:
    if ClassLibrary and ClassLibrary._classes_by_rarity.has(rarity):
        return ClassLibrary._classes_by_rarity[rarity]
    return []

static func get_random_class(min_rarity: ClassDefinition.ClassRarity = ClassDefinition.ClassRarity.COMMON) -> ClassDefinition:
    if not ClassLibrary:
        return null

    var available_classes: Array[ClassDefinition] = []


    for rarity in range(min_rarity, ClassDefinition.ClassRarity.LEGENDARY + 1):
        if ClassLibrary._classes_by_rarity.has(rarity):
            available_classes.append_array(ClassLibrary._classes_by_rarity[rarity])

    if available_classes.is_empty():
        push_warning("No classes available at rarity " + str(min_rarity) + " or higher")
        return null


    return ClassLibrary._weighted_random_selection(available_classes)

func _load_all_classes():

    _all_classes.clear()
    _classes_by_id.clear()
    for rarity in _classes_by_rarity:
        _classes_by_rarity[rarity].clear()


    var base_path = "res://systems/exile/exileClasses/"
    var rarity_folders = [
        "1_common", 
        "2_uncommon", 
        "3_rare", 
        "4_legendary"
    ]


    for i in range(rarity_folders.size()):
        var folder_path = base_path + rarity_folders[i] + "/"
        _load_classes_from_folder(folder_path, i)

func _load_classes_from_folder(folder_path: String, expected_rarity: int):



    var paths: Array[String] = ResourceDirScan.list_tres_files(folder_path)
    if paths.is_empty() and DirAccess.open(folder_path) == null:
        print("ClassLibrary: Folder not found: ", folder_path)
        return

    for resource_path in paths:
        var class_def = load(resource_path) as ClassDefinition
        if not class_def:
            push_error("Failed to load class from: " + resource_path)
            continue

        if class_def.rarity != expected_rarity:
            push_warning("Class " + class_def.name + " has rarity " + 
                str(class_def.rarity) + " but is in folder for rarity " + 
                str(expected_rarity))

        if class_def.class_id == "":
            push_error("Class in " + resource_path + " missing class_id")
            continue

        _all_classes.append(class_def)
        _classes_by_id[class_def.class_id] = class_def
        _classes_by_rarity[class_def.rarity].append(class_def)

func _weighted_random_selection(classes: Array[ClassDefinition]) -> ClassDefinition:
    if classes.is_empty():
        return null


    var total_weight = 0.0
    for class_def in classes:
        total_weight += class_def.get_drop_weight()


    var random_value = randf() * total_weight
    var current_weight = 0.0

    for class_def in classes:
        current_weight += class_def.get_drop_weight()
        if random_value <= current_weight:
            return class_def


    return classes[-1]


static func get_random_class_by_rarity(rarity: int) -> ClassDefinition:
    var matching_classes = []


    if ClassLibrary and ClassLibrary._classes_by_id:
        for class_id in ClassLibrary._classes_by_id:
            var class_def = ClassLibrary._classes_by_id[class_id]
            if class_def.rarity == rarity:
                matching_classes.append(class_def)

    if matching_classes.is_empty():
        push_error("No classes found with rarity: " + str(rarity))
        return get_random_class()

    return matching_classes[randi() % matching_classes.size()]

static func get_random_class_min_rarity(min_rarity: int) -> ClassDefinition:
    var matching_classes = []


    if ClassLibrary and ClassLibrary._classes_by_id:
        for class_id in ClassLibrary._classes_by_id:
            var class_def = ClassLibrary._classes_by_id[class_id]
            if class_def.rarity >= min_rarity:
                matching_classes.append(class_def)

    if matching_classes.is_empty():
        push_error("No classes found with min rarity: " + str(min_rarity))
        return get_random_class()


    var total_weight = 0.0
    var weighted_classes = []

    for class_def in matching_classes:
        var rarity_name = ClassDefinition.ClassRarity.keys()[class_def.rarity]
        var weight = GameSettings.CLASS_RARITY_WEIGHTS.get(rarity_name, 1.0)
        weighted_classes.append({"class": class_def, "weight": weight})
        total_weight += weight


    var random_value = randf() * total_weight
    var current_weight = 0.0

    for wc in weighted_classes:
        current_weight += wc.weight
        if random_value <= current_weight:
            return wc. class 

    return matching_classes[0]






static func get_random_class_with_quality_bonus(
    min_rarity: int = 0, quality_bonus: float = 0.0
) -> ClassDefinition:
    if not ClassLibrary or not ClassLibrary._classes_by_id:
        return null
    var candidates: Array = []
    for class_id in ClassLibrary._classes_by_id:
        var class_def: ClassDefinition = ClassLibrary._classes_by_id[class_id]
        if class_def.rarity >= min_rarity:
            candidates.append(class_def)
    if candidates.is_empty():
        push_warning("ClassLibrary: no classes match min_rarity %d — falling back" % min_rarity)
        return get_random_class()
    var picked: Variant = RarityWeighting.pick_weighted(candidates, quality_bonus)
    if picked == null:
        return get_random_class()
    return picked as ClassDefinition
