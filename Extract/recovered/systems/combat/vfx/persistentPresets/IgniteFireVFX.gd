@tool
class_name IgniteFireVFX
extends Node2D























@export var flame_color: Color = Color(1.0, 0.6, 0.2, 1.0):
    set(value):
        flame_color = value
        _apply_to_particles()




@export_range(0.0, 5.0, 0.05) var intensity: float = 1.0:
    set(value):
        intensity = maxf(value, 0.0)
        _apply_to_particles()




@export_range(0.0, 5.0, 0.05) var smoke_density: float = 1.0:
    set(value):
        smoke_density = maxf(value, 0.0)
        _apply_to_particles()




@export_range(0.1, 5.0, 0.05) var smoke_lifetime_scale: float = 1.0:
    set(value):
        smoke_lifetime_scale = maxf(value, 0.05)
        _apply_to_particles()




@export_range(0.0, 80.0, 1.0) var emission_radius_px: float = 14.0:
    set(value):
        emission_radius_px = maxf(value, 0.0)
        _apply_to_particles()



var _baseline_cinder_amount: int = 22
var _baseline_smoke_amount: int = 10
var _baseline_smoke_lifetime: float = 2.0
var _baseline_ember_amount: int = 14


func _ready() -> void :
    var cinders: CPUParticles2D = _get_cinders()
    var smoke: CPUParticles2D = _get_smoke()
    var embers: CPUParticles2D = _get_embers()
    if cinders != null:
        _baseline_cinder_amount = cinders.amount
    if smoke != null:
        _baseline_smoke_amount = smoke.amount
        _baseline_smoke_lifetime = smoke.lifetime
    if embers != null:
        _baseline_ember_amount = embers.amount
    _apply_to_particles()


func _apply_to_particles() -> void :
    var cinders: CPUParticles2D = _get_cinders()
    if cinders != null:
        cinders.color = flame_color
        cinders.amount = maxi(int(round(float(_baseline_cinder_amount) * intensity)), 1)
        cinders.emission_sphere_radius = emission_radius_px

    var smoke: CPUParticles2D = _get_smoke()
    if smoke != null:

        smoke.amount = maxi(int(round(float(_baseline_smoke_amount) * intensity * smoke_density)), 1)
        smoke.lifetime = _baseline_smoke_lifetime * smoke_lifetime_scale
        smoke.emission_sphere_radius = emission_radius_px

    var embers: CPUParticles2D = _get_embers()
    if embers != null:
        embers.color = flame_color
        embers.amount = maxi(int(round(float(_baseline_ember_amount) * intensity)), 1)
        embers.emission_sphere_radius = emission_radius_px * 0.7


func _get_cinders() -> CPUParticles2D:
    return get_node_or_null("Cinders") as CPUParticles2D


func _get_smoke() -> CPUParticles2D:
    return get_node_or_null("SmokeWhisps") as CPUParticles2D


func _get_embers() -> CPUParticles2D:
    return get_node_or_null("Embers") as CPUParticles2D
