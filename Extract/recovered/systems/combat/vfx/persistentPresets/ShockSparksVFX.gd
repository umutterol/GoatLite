@tool
class_name ShockSparksVFX
extends Node2D






















@export var spark_color: Color = Color(1.0, 0.95, 0.5, 1.0):
    set(value):
        spark_color = value
        _apply_to_particles()





@export_range(0.0, 5.0, 0.05) var intensity: float = 1.0:
    set(value):
        intensity = maxf(value, 0.0)
        _apply_to_particles()





@export_range(0.0, 80.0, 1.0) var emission_radius_px: float = 18.0:
    set(value):
        emission_radius_px = maxf(value, 0.0)
        _apply_to_particles()





@export_range(0.1, 5.0, 0.05) var lifetime_scale: float = 1.0:
    set(value):
        lifetime_scale = maxf(value, 0.05)
        _apply_to_particles()




@export_range(0.0, 5.0, 0.05) var velocity_scale: float = 1.0:
    set(value):
        velocity_scale = maxf(value, 0.0)
        _apply_to_particles()





var _baseline_lifetime: float = 0.4
var _baseline_velocity_min: float = 20.0
var _baseline_velocity_max: float = 50.0
var _baseline_amount: int = 24


func _ready() -> void :
    var sparks: CPUParticles2D = _get_sparks()
    if sparks == null:
        return



    _baseline_lifetime = sparks.lifetime
    _baseline_velocity_min = sparks.initial_velocity_min
    _baseline_velocity_max = sparks.initial_velocity_max
    _baseline_amount = sparks.amount
    _apply_to_particles()





func _apply_to_particles() -> void :
    var sparks: CPUParticles2D = _get_sparks()
    if sparks == null:
        return
    sparks.color = spark_color
    sparks.amount = maxi(int(round(float(_baseline_amount) * intensity)), 1)
    sparks.emission_sphere_radius = emission_radius_px
    sparks.lifetime = _baseline_lifetime * lifetime_scale
    sparks.initial_velocity_min = _baseline_velocity_min * velocity_scale
    sparks.initial_velocity_max = _baseline_velocity_max * velocity_scale


func _get_sparks() -> CPUParticles2D:


    return get_node_or_null("Sparks") as CPUParticles2D
