class_name HitImpactFX
extends Resource



















enum ParticleStyle{

    DOT, 


    STREAK, 


    CURL, 





    STATIC_ARC, 
}


enum DecayMode{


    FADE_WITH_PARTICLE, 


    BRIEF_GROUND_STAIN, 


    PERSISTENT_STAIN, 
}




const BRIEF_STAIN_LIFETIME: float = 1.2




@export var particle_style: ParticleStyle = ParticleStyle.DOT




@export var decay_mode: DecayMode = DecayMode.FADE_WITH_PARTICLE





@export var color_inner: Color = Color(1, 0.2, 0.2, 1)


@export var color_outer: Color = Color(0.4, 0.05, 0.05, 1)





@export_range(1, 30, 1) var particle_count: int = 10


@export_range(0.1, 2.0, 0.05) var lifetime_seconds: float = 0.4
















@export var lock_to_target: bool = true






@export_range(0.0, 40.0, 0.5) var speed_min: float = 6.0
@export_range(0.0, 40.0, 0.5) var speed_max: float = 14.0



@export_range(0.0, TAU, 0.05) var angle_spread_radians: float = 2.1





@export_range( - PI, PI, 0.05) var direction_bias_radians: float = 0.0



@export_range(-20.0, 30.0, 0.5) var gravity: float = 18.0




@export_range(0.5, 4.0, 0.1) var particle_radius_min: float = 1.0
@export_range(0.5, 4.0, 0.1) var particle_radius_max: float = 2.2



@export var glow: bool = false







@export_range(1.0, 3.0, 0.05) var crit_multiplier: float = 1.8






@export_range(0.0, 30.0, 0.5) var curl_frequency: float = 14.0



@export_range(0.0, 3.0, 0.05) var curl_amplitude: float = 0.6








@export_range(0.1, 8.0, 0.1) var arc_endpoint_distance_min: float = 1.5



@export_range(0.1, 8.0, 0.1) var arc_endpoint_distance_max: float = 4.0



@export_range(0.0, 0.5, 0.01) var arc_jitter: float = 0.12



@export_range(3, 20, 1) var arc_segments: int = 8







@export var arcs_sequenced: bool = true




@export_range(0.05, 2.0, 0.05) var arc_flash_duration: float = 0.15




@export_range(0, 4, 1) var arc_branch_count: int = 0



@export_range(0.5, 4.0, 0.1) var arc_stroke_width: float = 1.4






func get_effective_particle_count(is_crit: bool) -> int:
    if not is_crit:
        return particle_count
    return int(round(float(particle_count) * crit_multiplier))




func get_effective_speed_max(is_crit: bool) -> float:
    if not is_crit:
        return speed_max
    return speed_max * crit_multiplier




func get_effective_color_inner(is_crit: bool) -> Color:
    if not is_crit:
        return color_inner
    return color_inner.lerp(Color.WHITE, 0.3)
