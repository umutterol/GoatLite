extends Node

















const CONFIG_PATH: String = "user://preferences.cfg"
const SECTION_PLAYBACK: String = "playback"





const ALLOWED_PLAYBACK_SPEEDS: Array[float] = [0.5, 1.0, 2.0, 4.0]
const DEFAULT_PLAYBACK_SPEED: float = 0.5
const DEFAULT_AUTO_START_PLAYBACK: bool = false


var default_playback_speed: float = DEFAULT_PLAYBACK_SPEED
var auto_start_playback: bool = DEFAULT_AUTO_START_PLAYBACK


func _ready() -> void :
    _load_from_disk()







func set_default_playback_speed(speed: float) -> void :
    var snapped: float = snap_playback_speed(speed)
    if is_equal_approx(snapped, default_playback_speed):
        return
    default_playback_speed = snapped
    save_to_disk()


func set_auto_start_playback(value: bool) -> void :
    if value == auto_start_playback:
        return
    auto_start_playback = value
    save_to_disk()







static func snap_playback_speed(speed: float) -> float:
    var best: float = ALLOWED_PLAYBACK_SPEEDS[0]
    var best_distance: float = abs(speed - best)
    for candidate in ALLOWED_PLAYBACK_SPEEDS:
        var distance: float = abs(speed - candidate)
        if distance < best_distance:
            best = candidate
            best_distance = distance
    return best





func get_default_playback_speed_index() -> int:
    var idx: int = ALLOWED_PLAYBACK_SPEEDS.find(default_playback_speed)
    if idx < 0:
        return 0
    return idx




func _load_from_disk() -> void :
    var config: ConfigFile = ConfigFile.new()
    var err: int = config.load(CONFIG_PATH)
    if err != OK:



        if err != ERR_FILE_NOT_FOUND:
            push_warning("UserPreferences: failed to load %s (err %d), using defaults" % [CONFIG_PATH, err])
        return

    var loaded_speed: float = float(config.get_value(SECTION_PLAYBACK, "default_speed", DEFAULT_PLAYBACK_SPEED))
    default_playback_speed = snap_playback_speed(loaded_speed)
    auto_start_playback = bool(config.get_value(SECTION_PLAYBACK, "auto_start", DEFAULT_AUTO_START_PLAYBACK))


func save_to_disk() -> void :
    var config: ConfigFile = ConfigFile.new()
    config.set_value(SECTION_PLAYBACK, "default_speed", default_playback_speed)
    config.set_value(SECTION_PLAYBACK, "auto_start", auto_start_playback)
    var err: int = config.save(CONFIG_PATH)
    if err != OK:
        push_warning("UserPreferences: failed to save %s (err %d)" % [CONFIG_PATH, err])
