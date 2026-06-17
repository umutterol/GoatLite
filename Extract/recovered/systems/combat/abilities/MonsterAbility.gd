class_name MonsterAbility
extends Resource


































@export var ability_id: String = ""



@export var display_name: String = ""


@export var icon: Texture2D


@export_multiline var description: String = ""



@export_group("Targeting")










@export var shape: CombatEnums.AbilityType = CombatEnums.AbilityType.SINGLE_TARGET










@export var ability_target: CombatEnums.AbilityTarget = CombatEnums.AbilityTarget.NEAREST














@export_range(0.0, 50.0, 0.1) var ability_range: float = 1.5
















@export var aoe_centred_on_target: bool = false


















@export_range(0.0, 50.0, 0.1) var aoe_size: float = 1.5



@export_group("Timing")






@export_range(0.0, 60.0, 0.1) var cooldown_seconds: float = 1.0












@export_range(0.0, 5.0, 0.05) var wind_up_seconds: float = 0.0








@export_range(0.0, 5.0, 0.05) var recovery_seconds: float = 0.0





@export_range(0.0, 5.0, 0.05) var attack_speed_override: float = 1.0



@export_group("Damage")




@export_range(0.0, 10.0, 0.05) var damage_scaling: float = 1.0

















@export_range(0.0, 1.0, 0.01) var convert_to_physical: float = 0.0
@export_range(0.0, 1.0, 0.01) var convert_to_fire: float = 0.0
@export_range(0.0, 1.0, 0.01) var convert_to_cold: float = 0.0
@export_range(0.0, 1.0, 0.01) var convert_to_lightning: float = 0.0
@export_range(0.0, 1.0, 0.01) var convert_to_chaos: float = 0.0



@export_group("VFX")






@export var execute_vfx: AttackVFX



@export var impact_vfx: HitImpactFX




@export var telegraph_vfx: Resource









func can_use(_owner: CombatantData, _sim) -> bool:
    return true





func get_effective_range(_owner: CombatantData) -> float:
    return ability_range





func get_effective_cooldown(_owner: CombatantData) -> float:
    return cooldown_seconds








func create_action(p_owner: CombatantData, p_sim, p_target: CombatantData) -> AbilityAction:
    var action: = DefaultAoeAction.new()
    action.setup(self, p_owner, p_sim, p_target)
    return action





func has_conversion() -> bool:
    return convert_to_physical > 0.0\
or convert_to_fire > 0.0\
or convert_to_cold > 0.0\
or convert_to_lightning > 0.0\
or convert_to_chaos > 0.0
