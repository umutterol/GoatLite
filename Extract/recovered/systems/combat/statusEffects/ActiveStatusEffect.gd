class_name ActiveStatusEffect
extends RefCounted











var effect: StatusEffect = null




var stacks: int = 0




var applied_at_tick: float = 0.0






var expires_at_tick: float = INF













var magnitude_multiplier: float = 1.0













var applier_id: int = -1







func get_modifier_total(key: String) -> float:
    if effect == null:
        return 0.0
    var per_stack: float = float(effect.stat_modifiers.get(key, 0.0))
    return per_stack * float(stacks) * magnitude_multiplier





func get_per_tick_total(key: String) -> float:
    if effect == null:
        return 0.0
    var per_stack: float = float(effect.per_tick_effects.get(key, 0.0))
    return per_stack * float(stacks) * magnitude_multiplier
