class_name ConditionalStatBonus
extends Resource


























enum ConditionType{
    ALWAYS, 
    WITHIN_ENDURANCE_THRESHOLD, 
    ABOVE_ENDURANCE_THRESHOLD, 
    LOW_LIFE, 
    FULL_LIFE, 
    HIGH_MORALE, 
    LOW_MORALE, 
    ABOVE_LIFE_PERCENT, 
    BELOW_LIFE_PERCENT
}




@export var condition_type: ConditionType = ConditionType.ALWAYS







@export var condition_threshold: float = 0.0







@export var stat_id: String = ""


@export var scaling_type: StatDefinition.StatScalingType = StatDefinition.StatScalingType.FLAT


@export var base_value: float = 0.0




@export var value_per_stack: float = 0.0


@export var value_range_min: float = 0.0


@export var value_range_max: float = 0.0






@export var use_random_range: bool = false


func is_condition_met(exile_data: ExileData, stats: ExileStats) -> bool:
    match condition_type:
        ConditionType.ALWAYS:
            return true
        ConditionType.WITHIN_ENDURANCE_THRESHOLD:
            var threshold_life = stats.max_life * (stats.endurance_threshold / 100.0)
            return exile_data.current_life <= threshold_life
        ConditionType.ABOVE_ENDURANCE_THRESHOLD:
            var threshold_life = stats.max_life * (stats.endurance_threshold / 100.0)
            return exile_data.current_life > threshold_life
        ConditionType.LOW_LIFE:
            var life_percentage = (exile_data.current_life / stats.max_life) * 100.0
            return life_percentage < condition_threshold
        ConditionType.FULL_LIFE:
            return exile_data.current_life >= stats.life
        ConditionType.HIGH_MORALE:

            if stats.max_morale <= 0.0:
                return false
            var morale_pct = (stats.morale / stats.max_morale) * 100.0
            return morale_pct >= condition_threshold
        ConditionType.LOW_MORALE:
            if stats.max_morale <= 0.0:
                return false
            var morale_pct = (stats.morale / stats.max_morale) * 100.0
            return morale_pct <= condition_threshold
        ConditionType.ABOVE_LIFE_PERCENT:
            var life_percentage = (exile_data.current_life / stats.life) * 100.0
            return life_percentage > condition_threshold
        ConditionType.BELOW_LIFE_PERCENT:
            var life_percentage = (exile_data.current_life / stats.life) * 100.0
            return life_percentage < condition_threshold
        _:
            return false


func calculate_bonus_value(stack_count: int = 1) -> float:
    var base = base_value
    if use_random_range:
        base = randf_range(value_range_min, value_range_max)

    return base + (value_per_stack * (stack_count - 1))



func get_display_text(stack_count: int = 1) -> String:
    var value = calculate_bonus_value(stack_count)
    var stat_def = StatDefinitionManager.get_stat_definition(stat_id)

    if not stat_def:
        push_warning("ConditionalStatBonus: unknown stat_id '%s'" % stat_id)
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
                push_warning("ConditionalStatBonus '%s': negative INCREASED value (%s); use REDUCED scaling instead." % [stat_id, value])
            suffix = "% increased "
        StatDefinition.StatScalingType.MORE:
            if value < 0:
                push_warning("ConditionalStatBonus '%s': negative MORE value (%s); use LESS scaling instead." % [stat_id, value])
            suffix = "% more "
        StatDefinition.StatScalingType.REDUCED:
            suffix = "% reduced "
        StatDefinition.StatScalingType.LESS:
            suffix = "% less "

    var format_str = "%." + str(stat_def.decimal_places) + "f"
    var display_value = value if scaling_type == StatDefinition.StatScalingType.FLAT else absf(value)
    var value_text = format_str % display_value


    var condition_text = get_condition_description()

    return prefix + value_text + suffix + stat_def.display_name + condition_text


func get_condition_description() -> String:
    match condition_type:
        ConditionType.ALWAYS:
            return ""
        ConditionType.WITHIN_ENDURANCE_THRESHOLD:
            return " while within endurance threshold"
        ConditionType.ABOVE_ENDURANCE_THRESHOLD:
            return " while above endurance threshold"
        ConditionType.LOW_LIFE:
            return " while on low life (below " + str(condition_threshold) + "%)"
        ConditionType.FULL_LIFE:
            return " while on full life"
        ConditionType.HIGH_MORALE:
            return " while morale is at or above " + str(condition_threshold) + "% of max"
        ConditionType.LOW_MORALE:
            return " while morale is at or below " + str(condition_threshold) + "% of max"
        ConditionType.ABOVE_LIFE_PERCENT:
            return " while above " + str(condition_threshold) + "% life"
        ConditionType.BELOW_LIFE_PERCENT:
            return " while below " + str(condition_threshold) + "% life"
        _:
            return " (unknown condition)"
