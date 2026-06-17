
extends Node2D

func _ready():
    print("=== COMPREHENSIVE STAT TEST ===")


    scan_all_stat_files()


    verify_stat_definitions()

func scan_all_stat_files():
    print("\n--- Scanning for ALL .tres files ---")
    var base_path = "res://systems/exile/stats/definitions/"
    var all_files = []


    _scan_directory(base_path, all_files)

    print("Found ", all_files.size(), " total .tres files:")
    for file in all_files:
        print("  ", file)

func _scan_directory(path: String, file_list: Array):
    var dir = DirAccess.open(path)
    if not dir:
        return

    dir.list_dir_begin()
    var file_name = dir.get_next()

    while file_name != "":
        var full_path = path + "/" + file_name

        if dir.current_is_dir() and file_name != "." and file_name != "..":

            _scan_directory(full_path, file_list)
        elif file_name.ends_with(".tres"):
            file_list.append(full_path)

        file_name = dir.get_next()

func verify_stat_definitions():
    print("\n--- Verifying Stat Definitions ---")
    var base_path = "res://systems/exile/stats/definitions/"
    var all_stat_files = []
    var stats_instance = ExileStats.new()


    _scan_directory(base_path, all_stat_files)


    var valid_count = 0
    var issues = []

    for file_path in all_stat_files:
        var resource = load(file_path)

        if resource is StatDefinition:

            if resource.stat_id in stats_instance:
                print("  ✓ ", file_path.get_file(), " -> stat_id: '", resource.stat_id, "'")
                valid_count += 1
            else:
                var msg = "  ✗ " + file_path.get_file() + " -> stat_id: '" + resource.stat_id + "' NOT IN EXILESTATS"
                print(msg)
                issues.append(msg)
        else:
            print("  ? ", file_path.get_file(), " is not a StatDefinition")

    print("\nSummary: ", valid_count, " valid definitions found")
    if issues.size() > 0:
        print("Issues found:")
        for issue in issues:
            print(issue)


    print("\n--- Checking which ExileStats properties lack definitions ---")
    var found_stat_ids = {}


    for file_path in all_stat_files:
        var resource = load(file_path)
        if resource is StatDefinition:
            found_stat_ids[resource.stat_id] = true


    var properties = stats_instance.get_property_list()
    for prop in properties:
        if prop.type == TYPE_FLOAT and not prop.name in ["resource_local_to_scene", "resource_name", "current_life", "max_life"]:
            if not prop.name in found_stat_ids:
                print("  ⚠ ExileStats.", prop.name, " has no StatDefinition")
