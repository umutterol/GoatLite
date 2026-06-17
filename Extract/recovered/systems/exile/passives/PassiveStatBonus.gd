class_name PassiveStatBonus
extends Resource





enum DamageTarget{
    BOTH, 
    MIN_ONLY, 
    MAX_ONLY
}














@export var stat_id: String = ""













@export var scaling_type: StatDefinition.StatScalingType = StatDefinition.StatScalingType.FLAT












@export var base_value: float = 0.0





@export var value_per_stack: float = 0.0



@export var value_range_min: float = 0.0



@export var value_range_max: float = 0.0




@export var use_random_range: bool = false







@export var damage_target: DamageTarget = DamageTarget.BOTH

func calculate_bonus_value(stack_count: int = 1) -> float:
    var base = base_value
    if use_random_range:
        base = randf_range(value_range_min, value_range_max)

    return base + (value_per_stack * (stack_count - 1))

func get_display_text(stack_count: int = 1) -> String:
    var value = calculate_bonus_value(stack_count)
    var stat_def = StatDefinitionManager.get_stat_definition(stat_id)



    if not stat_def:
        push_warning("PassiveStatBonus: unknown stat_id '%s'" % stat_id)
        var sign_str: = "+" if value >= 0 else ""
        return "[!unknown stat] %s: %s%.1f" % [stat_id, sign_str, value]






    var prefix = ""
    var suffix = ""

    match scaling_type:
        StatDefinition.StatScalingType.FLAT:
            prefix = "+" if value >= 0 else ""
            suffix = " to " if not stat_def.show_as_percentage else "% to "
        StatDefinition.StatScalingType.INCREASED:
            if value < 0:
                push_warning("PassiveStatBonus '%s': negative INCREASED value (%s); use REDUCED scaling instead." % [stat_id, value])
            suffix = "% increased "
        StatDefinition.StatScalingType.MORE:
            if value < 0:
                push_warning("PassiveStatBonus '%s': negative MORE value (%s); use LESS scaling instead." % [stat_id, value])
            suffix = "% more "
        StatDefinition.StatScalingType.REDUCED:
            suffix = "% reduced "
        StatDefinition.StatScalingType.LESS:
            suffix = "% less "

    var format_str = "%." + str(stat_def.decimal_places) + "f"


    var display_value = value if scaling_type == StatDefinition.StatScalingType.FLAT else absf(value)
    var value_text = format_str % display_value


    var target_text = ""
    if is_damage_stat() and damage_target != DamageTarget.BOTH:
        match damage_target:
            DamageTarget.MIN_ONLY:
                target_text = "Minimum "
            DamageTarget.MAX_ONLY:
                target_text = "Maximum "

    return prefix + value_text + suffix + target_text + stat_def.display_name


func is_damage_stat() -> bool:
    return stat_id.ends_with("_damage") or stat_id.contains("damage")


func apply_to_stat(current_value, stack_count: int = 1):
    var bonus_value = calculate_bonus_value(stack_count)


    if current_value is Vector2 and is_damage_stat():
        match scaling_type:
            StatDefinition.StatScalingType.FLAT:

                match damage_target:
                    DamageTarget.BOTH:
                        return Vector2(
                            current_value.x + bonus_value, 
                            current_value.y + bonus_value
                        )
                    DamageTarget.MIN_ONLY:
                        return Vector2(
                            current_value.x + bonus_value, 
                            current_value.y
                        )
                    DamageTarget.MAX_ONLY:
                        return Vector2(
                            current_value.x, 
                            current_value.y + bonus_value
                        )

            StatDefinition.StatScalingType.INCREASED, StatDefinition.StatScalingType.MORE:
                var multiplier = 1.0 + (bonus_value / 100.0)
                match damage_target:
                    DamageTarget.BOTH:
                        return Vector2(
                            current_value.x * multiplier, 
                            current_value.y * multiplier
                        )
                    DamageTarget.MIN_ONLY:
                        return Vector2(
                            current_value.x * multiplier, 
                            current_value.y
                        )
                    DamageTarget.MAX_ONLY:
                        return Vector2(
                            current_value.x, 
                            current_value.y * multiplier
                        )

            StatDefinition.StatScalingType.REDUCED, StatDefinition.StatScalingType.LESS:
                var multiplier = 1.0 - (bonus_value / 100.0)
                match damage_target:
                    DamageTarget.BOTH:
                        return Vector2(
                            current_value.x * multiplier, 
                            current_value.y * multiplier
                        )
                    DamageTarget.MIN_ONLY:
                        return Vector2(
                            current_value.x * multiplier, 
                            current_value.y
                        )
                    DamageTarget.MAX_ONLY:
                        return Vector2(
                            current_value.x, 
                            current_value.y * multiplier
                        )


    else:
        match scaling_type:
            StatDefinition.StatScalingType.FLAT:
                return current_value + bonus_value
            StatDefinition.StatScalingType.INCREASED, StatDefinition.StatScalingType.MORE:
                return current_value * (1.0 + bonus_value / 100.0)
            StatDefinition.StatScalingType.REDUCED, StatDefinition.StatScalingType.LESS:
                return current_value * (1.0 - bonus_value / 100.0)

    return current_value
