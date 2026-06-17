class_name ExileStats
extends Resource











@export_group("Core Stats")








@export var life: float = 100.0























@export var vitality: float = 100.0






@export var morale: float = 100.0: set = set_morale




@export var max_morale: float = 100.0


@export_group("Defence Stats")











@export var armour: float = 0.0








@export var block_chance: float = 0.0







@export var block_amount: float = 0.0






@export var evasion: float = 10.0






@export var endurance: float = 10.0




@export var endurance_threshold: float = 25.0





@export var energy_shield: float = 0.0


@export_group("Resistances")





@export var cold_resistance: float = 0.0




@export var cold_resistance_cap: float = 75.0


@export var lightning_resistance: float = 0.0


@export var lightning_resistance_cap: float = 75.0


@export var fire_resistance: float = 0.0


@export var fire_resistance_cap: float = 75.0


@export var chaos_resistance: float = 0.0


@export var chaos_resistance_cap: float = 75.0


@export_group("Recovery Stats")







@export var life_regen: float = 0.0






@export var life_leech: float = 0.0




@export var life_gain_on_hit: float = 0.0






@export var second_wind_chance: float = 5.0





@export var second_wind_amount: float = 50.0






@export var second_wind_threshold: float = 10.0


@export_group("Base Damage")







@export var physical_damage: Vector2 = Vector2(0, 0)



@export var fire_damage: Vector2 = Vector2(0, 0)


@export var cold_damage: Vector2 = Vector2(0, 0)


@export var lightning_damage: Vector2 = Vector2(0, 0)



@export var chaos_damage: Vector2 = Vector2(0, 0)

@export_group("Combat Stats")




@export var critical_chance: float = 5.0





@export var critical_multiplier: float = 150.0





@export var attack_speed: float = 1.0








@export var action_speed: float = 1.0


@export_group("Ailment Stats")





@export var shock_chance: float = 0.0







@export var shock_effect_more_pct: float = 0.0




@export var shock_duration_more_pct: float = 0.0
















@export var ailment_immunities: Array[StringName] = []














@export var shock_effect_reduction_pct: float = 0.0



@export var shock_duration_reduction_pct: float = 0.0



@export var chill_effect_reduction_pct: float = 0.0


@export var chill_duration_reduction_pct: float = 0.0





@export var ignite_duration_reduction_pct: float = 0.0







@export var poison_duration_reduction_pct: float = 0.0







@export var chill_effect_more_pct: float = 0.0




@export var chill_duration_more_pct: float = 0.0
















@export var damage_over_time_more_pct: float = 0.0







@export var ignite_chance: float = 0.0






@export var ignite_effect_more_pct: float = 0.0





@export var ignite_duration_more_pct: float = 0.0


























@export var poison_chance: float = 0.0






@export var poison_effect_more_pct: float = 0.0






@export var poison_duration_more_pct: float = 0.0


















@export var impale_effect_pct: float = 0.0







@export var impale_chance: float = 0.0









@export var max_impales_bonus: int = 0


@export_group("Morale Stats")




@export var morale_gain: float = 0





@export var morale_loss_resistance: float = 0





@export var victory_morale_bonus: float = 0





@export var well_fed_rest_morale_bonus: float = 0



@export_group("Utility Stats")











@export var movement: float = 0.0







@export var scouting: float = 0.0






@export var survival: float = 0.0





@export var scavenging: float = 0.0


var current_life: float = 100.0
var max_life: float = 100.0
var current_vitality: float = 100.0
var max_vitality: float = 100.0

func _init():
    current_life = life
    max_life = life
    reset_modifiers()

func set_morale(value: float):
    morale = clamp(value, 0.0, max_morale)

func get_armour_reduction(incoming_damage: float) -> float:
    return CombatMath.calculate_armour_reduction(armour, incoming_damage)


func get_resistance(damage_type: String) -> float:
    match damage_type:
        "cold": return cold_resistance
        "lightning": return lightning_resistance
        "fire": return fire_resistance
        "chaos": return chaos_resistance
        _: return 0.0

func is_endurance_active() -> bool:
    return CombatMath.is_endurance_active(current_life, max_life, endurance_threshold)

func roll_evasion() -> String:
    return CombatMath.roll_evasion(evasion)

func calculate_block() -> Dictionary:
    return CombatMath.calculate_block(block_chance, block_amount)

func get_effective_resistance(damage_type: String) -> float:
    var raw: = get_resistance(damage_type)
    var cap: = get_resistance_cap(damage_type)
    return CombatMath.get_effective_resistance(raw, cap)

func get_resistance_cap(damage_type: String) -> float:
    match damage_type:
        "fire": return fire_resistance_cap
        "cold": return cold_resistance_cap
        "lightning": return lightning_resistance_cap
        "chaos": return chaos_resistance_cap
        _: return 75.0


var damage_modifiers: Dictionary = {
    "increased": {}, 
    "more": {}, 
    "less": {}, 
    "reduced": {}
}


func reset_modifiers():
    damage_modifiers = {
        "increased": {}, 
        "more": {}, 
        "less": {}, 
        "reduced": {}
    }


func get_final_damage(damage_type: String) -> Vector2:
    var base = get(damage_type + "_damage") as Vector2
    if not base or base == null:
        return Vector2.ZERO
    return base


func add_damage_modifier(_stat_id: String, _scaling_type: String, _value: float):

    pass
