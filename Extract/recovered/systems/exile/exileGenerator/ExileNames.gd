class_name ExileNames
extends RefCounted


static var prefixes = [

    "Grim", "Dark", "Iron", "Stone", "Ash", "Blood", "Bone", "Frost", 
    "Storm", "Thunder", "Shadow", "Night", "Dawn", "Dusk", "Grey", "Black", 
    "Red", "White", "Gold", "Silver", "Bronze", "Steel", 


    "Swift", "Strong", "Sharp", "Bright", "Cold", "Hard", "Soft", "Wild", 
    "Mad", "Lost", "Broken", "Cursed", "Blessed", "Silent", "Loud", "Proud", 


    "War", "Battle", "Death", "Life", "Dream", "Rage", "Fear", "Hope", 
    "Doom", "Bane", "Rune", "Spell", "Blade", "Shield", "Hammer", "Axe", 


    "Wolf", "Bear", "Eagle", "Raven", "Fox", "Lion", "Dragon", "Serpent", 
    "Oak", "Thorn", "Rose", "Ember", "Flame", "Ice", "Wind", "Earth"
]

static var suffixes = [

    "jaw", "fist", "hand", "eye", "tooth", "claw", "heart", "skull", 
    "bone", "blood", "brow", "arm", "foot", 


    "breaker", "crusher", "slayer", "keeper", "seeker", "walker", "runner", 
    "singer", "caller", "bringer", "taker", "maker", "shaker", "rider", 


    "blade", "edge", "point", "shield", "helm", "mail", "forge", "anvil", 
    "hammer", "sword", "spear", "bow", "arrow", "stone", "ward", 


    "bane", "doom", "fell", "sworn", "bound", "born", "blessed", "cursed", 
    "marked", "scarred", "touched", "struck", "forged", "tempered", 


    "moor", "dale", "hill", "vale", "field", "heim", "gard", "hold", 
    "fall", "rise", "end", "start", "way", "path", "road"
]


static var class_prefixes = {
    "warrior": ["Iron", "Steel", "Battle", "War", "Blade"], 
    "ranger": ["Swift", "Eagle", "Wind", "Shadow", "Silent"], 
    "occultist": ["Dark", "Cursed", "Spell", "Rune", "Dream"], 
    "berserker": ["Blood", "Rage", "Mad", "Wild", "Doom"]
}


static func generate_random_name() -> String:
    var prefix = prefixes.pick_random()
    var suffix = suffixes.pick_random()


    while _is_redundant_combination(prefix, suffix):
        suffix = suffixes.pick_random()

    return prefix + suffix


static func generate_class_name(class_id: String) -> String:
    var prefix = ""


    if class_prefixes.has(class_id) and randf() < 0.6:
        prefix = class_prefixes[class_id].pick_random()
    else:
        prefix = prefixes.pick_random()

    var suffix = suffixes.pick_random()

    while _is_redundant_combination(prefix, suffix):
        suffix = suffixes.pick_random()

    return prefix + suffix


static func generate_unique_names(count: int) -> Array[String]:
    var names: Array[String] = []
    var attempts = 0
    var max_attempts = count * 10

    while names.size() < count and attempts < max_attempts:
        var new_name = generate_random_name()
        if not names.has(new_name):
            names.append(new_name)
        attempts += 1

    return names


static func _is_redundant_combination(prefix: String, suffix: String) -> bool:

    var prefix_lower = prefix.to_lower()
    var suffix_lower = suffix.to_lower()


    if prefix_lower in suffix_lower or suffix_lower in prefix_lower:
        return true


    var redundant_pairs = {
        "blade": ["sword", "edge", "point"], 
        "iron": ["steel", "forge", "anvil"], 
        "blood": ["heart", "blood"], 
        "bone": ["skull", "bone"], 
        "shadow": ["dark", "night"], 
        "storm": ["thunder", "wind"]
    }

    for key in redundant_pairs:
        if prefix_lower == key and suffix_lower in redundant_pairs[key]:
            return true
        if suffix_lower == key and prefix_lower in redundant_pairs[key]:
            return true

    return false


static func add_prefix(new_prefix: String):
    if not prefixes.has(new_prefix):
        prefixes.append(new_prefix)

static func add_suffix(new_suffix: String):
    if not suffixes.has(new_suffix):
        suffixes.append(new_suffix)
