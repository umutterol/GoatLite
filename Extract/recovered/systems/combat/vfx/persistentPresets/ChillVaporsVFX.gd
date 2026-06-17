@tool
class_name ChillVaporsVFX
extends Node2D






















@export var tint_color: Color = Color(0.55, 0.78, 1.0, 0.7):
    set(value):
        tint_color = value
        _apply_to_particles()




@export_range(0.0, 5.0, 0.05) var vapor_density: float = 1.0:
    set(value):
        vapor_density = maxf(value, 0.0)
        _apply_to_particles()




@export_range(0.1, 5.0, 0.05) var vapor_lifetime_scale: float = 1.0:
    set(value):
        vapor_lifetime_scale = maxf(value, 0.05)
        _apply_to_particles()




@export_range(0.0, 5.0, 0.05) var swirl_density: float = 1.0:
    set(value):
        swirl_density = maxf(value, 0.0)
        _apply_to_particles()




@export_range(0.0, 5.0, 0.05) var swirl_intensity: float = 1.0:
    set(value):
        swirl_intensity = maxf(value, 0.0)
        _apply_to_particles()




@export_range(0.0, 80.0, 1.0) var emission_radius_px: float = 16.0:
    set(value):
        emission_radius_px = maxf(value, 0.0)
        _apply_to_particles()



var _baseline_vapor_amount: int = 18
var _baseline_vapor_lifetime: float = 1.6
var _baseline_swirl_amount: int = 12
var _baseline_swirl_angular_min: float = 60.0
var _baseline_swirl_angular_max: float = 140.0


func _ready() -> void :
    var vapor: CPUParticles2D = _get_vapor()
    var swirls: CPUParticles2D = _get_swirls()
    if vapor != null:
        _baseline_vapor_amount = vapor.amount
        _baseline_vapor_lifetime = vapor.lifetime
    if swirls != null:
        _baseline_swirl_amount = swirls.amount
        _baseline_swirl_angular_min = swirls.angular_velocity_min
        _baseline_swirl_angular_max = swirls.angular_velocity_max
    _apply_to_particles()




func _apply_to_particles() -> void :
    var vapor: CPUParticles2D = _get_vapor()
    if vapor != null:
        vapor.color = tint_color
        vapor.amount = maxi(int(round(float(_baseline_vapor_amount) * vapor_density)), 1)
        vapor.lifetime = _baseline_vapor_lifetime * vapor_lifetime_scale
        vapor.emission_sphere_radius = emission_radius_px

    var swirls: CPUParticles2D = _get_swirls()
    if swirls != null:
        swirls.color = tint_color
        swirls.amount = maxi(int(round(float(_baseline_swirl_amount) * swirl_density)), 1)
        swirls.angular_velocity_min = _baseline_swirl_angular_min * swirl_intensity
        swirls.angular_velocity_max = _baseline_swirl_angular_max * swirl_intensity
        swirls.emission_sphere_radius = emission_radius_px


func _get_vapor() -> CPUParticles2D:
    return get_node_or_null("Vapor") as CPUParticles2D


func _get_swirls() -> CPUParticles2D:
    return get_node_or_null("Swirls") as CPUParticles2D
