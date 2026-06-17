class_name KiteProfile
extends RefCounted

















enum Profile{
    INHERIT, 

    EVASIVE_MELEE, 








    CAREFUL_SNIPER, 


    BALANCED_AGGRESSIVE, 


    RECKLESS, 



    NO_KITING, 

}













const PROFILE_DEFS: Dictionary = {























    Profile.EVASIVE_MELEE: {
        "kite_mode": CombatEnums.KiteMode.KITE_BETWEEN_ATTACKS, 
        "preferred_distance_pct": 1.05, 
        "stance": CombatEnums.Stance.BALANCED, 
        "tactical_overrides": {
            "kite_angle_jitter_degrees": 20.0, 
            "kite_max_deviation_degrees": 80.0, 
            "kite_open_space_weight": 0.5, 
            "melee_threat_memory_duration": 0.0, 




            "kite_settle_duration": 0.2, 
        }, 
    }, 




    Profile.CAREFUL_SNIPER: {
        "kite_mode": CombatEnums.KiteMode.KITE_BETWEEN_ATTACKS, 
        "preferred_distance_pct": 0.95, 
        "stance": CombatEnums.Stance.DEFENSIVE, 
        "tactical_overrides": {
            "kite_angle_jitter_degrees": 12.0, 
            "kite_max_deviation_degrees": 55.0, 
            "kite_open_space_weight": 0.45, 
            "threat_break_radius": 4.0, 
        }, 
    }, 


    Profile.BALANCED_AGGRESSIVE: {
        "kite_mode": CombatEnums.KiteMode.KITE_BETWEEN_ATTACKS, 
        "preferred_distance_pct": 0.66, 
        "stance": CombatEnums.Stance.BALANCED, 
        "tactical_overrides": {
            "kite_angle_jitter_degrees": 12.0, 
            "kite_max_deviation_degrees": 55.0, 
            "kite_open_space_weight": 0.45, 
            "threat_break_radius": 3.0, 
        }, 
    }, 
    Profile.RECKLESS: {
        "kite_mode": CombatEnums.KiteMode.KITE_ONLY_VS_SLOWER_MELEE, 
        "preferred_distance_pct": 0.5, 
        "stance": CombatEnums.Stance.AGGRESSIVE, 
    }, 
    Profile.NO_KITING: {
        "kite_mode": CombatEnums.KiteMode.NONE, 
        "preferred_distance_pct": 0.0, 
        "stance": CombatEnums.Stance.BALANCED, 
    }, 
}




const LABELS: Dictionary = {
    Profile.EVASIVE_MELEE: "Evasive Melee", 
    Profile.CAREFUL_SNIPER: "Careful Sniper", 
    Profile.BALANCED_AGGRESSIVE: "Balanced Aggressive", 
    Profile.RECKLESS: "Reckless", 
    Profile.NO_KITING: "No Kiting", 
}
