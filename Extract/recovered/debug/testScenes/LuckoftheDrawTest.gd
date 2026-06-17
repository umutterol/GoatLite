extends Node



@export var passive_to_test: String = "D:/Game Dev/exiled-guild-manager-godot/systems/exile/passives/definitions/notable/luck_of_the_draw.tres"

func _ready():
    print("\n=== TESTING LUCK OF THE DRAW PASSIVE - 10 GENERATIONS ===\n")


    var passive_resource = load("D:/Game Dev/exiled-guild-manager-godot/systems/exile/passives/definitions/notable/luck_of_the_draw.tres")

    if not passive_resource:
        print("ERROR: Could not load luck_of_the_draw.tres")
        print("Make sure the file path is correct!")
        return

    print("Loaded passive: ", passive_resource.name)
    print("Description: ", passive_resource.description)
    print("\n--- Generating 10 instances with random stats ---\n")


    for i in range(10):
        print("=== Generation #", i + 1, " ===")


        var instance = passive_resource.duplicate(true)


        for stat_bonus in instance.stat_bonuses:
            if stat_bonus.use_random_range:

                var random_value = randf_range(stat_bonus.value_range_min, stat_bonus.value_range_max)


                random_value = snapped(random_value, 0.1)


                stat_bonus.base_value = random_value



                print("  ", stat_bonus.get_display_text())

        print("")

    print("=== TEST COMPLETE ===\n")


    show_statistics(passive_resource)


func format_stat_name(stat_id: String) -> String:
    return stat_id.replace("_", " ").capitalize()


func show_statistics(passive_resource):
    print("\n--- STAT RANGES REFERENCE ---")
    for stat_bonus in passive_resource.stat_bonuses:
        print(format_stat_name(stat_bonus.stat_id), ": ", 
            stat_bonus.value_range_min, "-", stat_bonus.value_range_max)
        print("  Display format: ", stat_bonus.get_display_text())
