@tool
class_name PoisonCloudVFX
extends Node2D
























@export var poison_color: Color = Color(0.4, 0.85, 0.2, 1.0):
    set(value):
        poison_color = value
        _apply_to_particles()



@export_range(0.0, 5.0, 0.05) var intensity: float = 1.0:
    set(value):
        intensity = maxf(value, 0.0)
        _apply_to_particles()



@export_range(0.0, 80.0, 1.0) var emission_radius_px: float = 16.0:
    set(value):
        emission_radius_px = maxf(value, 0.0)
        _apply_to_particles()



var _baseline_miasma_amount: int = 16
var _baseline_bubble_amount: int = 8
var _baseline_speck_amount: int = 18





var _stack_intensity_mult: float = 1.0


func _ready() -> void :
    var miasma: CPUParticles2D = _get_miasma()
    var bubbles: CPUParticles2D = _get_bubbles()
    var specks: CPUParticles2D = _get_specks()
    if miasma != null:
        _baseline_miasma_amount = miasma.amount
    if bubbles != null:
        _baseline_bubble_amount = bubbles.amount
    if specks != null:
        _baseline_speck_amount = specks.amount
    _apply_to_particles()










func set_visible_count(stack_count: int) -> void :
    if stack_count <= 1:
        _stack_intensity_mult = 1.0
    else:


        _stack_intensity_mult = 1.0 + 0.36 * log(float(stack_count))
        _stack_intensity_mult = clampf(_stack_intensity_mult, 1.0, 3.5)
    _apply_to_particles()


func _apply_to_particles() -> void :
    var combined_mult: float = intensity * _stack_intensity_mult

    var miasma: CPUParticles2D = _get_miasma()
    if miasma != null:
        miasma.color = poison_color
        miasma.amount = maxi(int(round(float(_baseline_miasma_amount) * combined_mult)), 1)
        miasma.emission_sphere_radius = emission_radius_px

    var bubbles: CPUParticles2D = _get_bubbles()
    if bubbles != null:

        bubbles.color = Color(
            poison_color.r * 0.6, poison_color.g * 0.8, poison_color.b * 0.5, 1.0
        )
        bubbles.amount = maxi(int(round(float(_baseline_bubble_amount) * combined_mult)), 1)
        bubbles.emission_sphere_radius = emission_radius_px * 0.55

    var specks: CPUParticles2D = _get_specks()
    if specks != null:


        specks.amount = maxi(int(round(float(_baseline_speck_amount) * combined_mult)), 1)
        specks.emission_sphere_radius = emission_radius_px * 0.75


func _get_miasma() -> CPUParticles2D:
    return get_node_or_null("MiasmaCloud") as CPUParticles2D


func _get_bubbles() -> CPUParticles2D:
    return get_node_or_null("DripBubbles") as CPUParticles2D


func _get_specks() -> CPUParticles2D:
    return get_node_or_null("ToxinSpecks") as CPUParticles2D
