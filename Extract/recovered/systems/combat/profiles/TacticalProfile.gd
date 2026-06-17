class_name TacticalProfile
extends Resource









@export_group("Targeting")











@export_range(0.0, 10.0, 0.1, "suffix:s") var sticky_target_duration: float = 2.5













@export_range(0.1, 1.0, 0.05) var engaged_target_distance_discount: float = 0.7


@export_group("Reactive Behaviour")












@export_range(0.0, 5.0, 0.1, "suffix:s") var melee_threat_memory_duration: float = 1.5


@export_group("Stutter Step")











@export_range(0.0, 1.0, 0.05, "suffix:s") var kite_settle_duration: float = 0.1


@export_group("Kite Variance")











@export_range(0.0, 30.0, 0.5, "suffix:°") var kite_angle_jitter_degrees: float = 8.0









@export_range(0.0, 1.0, 0.05) var kite_open_space_weight: float = 0.35





@export_range(0.0, 90.0, 1.0, "suffix:°") var kite_max_deviation_degrees: float = 35.0




@export_range(1, 9, 2) var kite_candidate_count: int = 5


@export_group("Threat Awareness")
















@export_range(0.0, 10.0, 0.5, "suffix:u") var threat_break_radius: float = 0.0


@export_group("Float Drift Tolerance")











@export_range(0.0, 0.5, 0.01, "suffix:u") var attack_range_hysteresis: float = 0.05






const DEFAULT_PATH: = "res://systems/combat/profiles/default_tactical.tres"



static var _default_cache: TacticalProfile = null






static func default() -> TacticalProfile:
    if _default_cache != null:
        return _default_cache
    var loaded: = load(DEFAULT_PATH) as TacticalProfile
    if loaded == null:
        push_warning("TacticalProfile.default(): failed to load %s — using inline defaults" % DEFAULT_PATH)
        loaded = TacticalProfile.new()
    _default_cache = loaded
    return _default_cache
