class_name CombatBehavior
extends Resource




const MELEE_ATTACK_RANGE_DEFAULT: = 1.5
const RANGED_PREFERRED_DISTANCE_BUFFER: = 2.0



const TACTICAL_RANGED_DEFAULT: = preload("res://systems/combat/profiles/tactical_ranged_kiter.tres")
const TACTICAL_MELEE_DEFAULT: = preload("res://systems/combat/profiles/tactical_melee_tank.tres")

@export_group("Targeting")

















@export var aggro_type: CombatEnums.AggroType = CombatEnums.AggroType.NEAREST









@export var target_rules: Array[TargetRule] = []
@export var fallback_picker: int = TargetRule.Picker.NEAREST


@export_group("Range & Positioning")




@export var attack_range: float = 1.5









@export var preferred_distance: float = 0.0









@export var kite_mode: CombatEnums.KiteMode = CombatEnums.KiteMode.NONE




@export var engage_range: float = 0.0


@export_group("Disposition")









@export var stance: CombatEnums.Stance = CombatEnums.Stance.BALANCED


@export_group("Tuning")









@export var tactical_profile: TacticalProfile


@export_group("Combat VFX")










@export var basic_attack_vfx_override: AttackVFX = null




func get_tactical() -> TacticalProfile:
    if tactical_profile != null:
        return tactical_profile
    return TacticalProfile.default()






static func infer_from_exile(exile: ExileData) -> CombatBehavior:
    var behavior: = CombatBehavior.new()
    var weapon: Item = _get_equipped_weapon(exile)

    if weapon == null or weapon.base_item == null:

        behavior.tactical_profile = TACTICAL_MELEE_DEFAULT
        return behavior

    var base: ItemBase = weapon.base_item
    behavior.attack_range = base.base_attack_range

    if base.ranged:

        behavior.preferred_distance = maxf(base.base_attack_range - RANGED_PREFERRED_DISTANCE_BUFFER, 4.0)
        behavior.kite_mode = CombatEnums.KiteMode.KITE_BETWEEN_ATTACKS
        behavior.tactical_profile = TACTICAL_RANGED_DEFAULT
    else:

        behavior.preferred_distance = 0.0
        behavior.kite_mode = CombatEnums.KiteMode.NONE
        behavior.tactical_profile = TACTICAL_MELEE_DEFAULT

    behavior.aggro_type = CombatEnums.AggroType.NEAREST
    return behavior











static func resolve_for_exile(exile: ExileData) -> CombatBehavior:
    var behavior: = infer_from_exile(exile)
    _apply_tactics_override(behavior, exile.tactics_override)
    return behavior















static func _apply_tactics_override(behavior: CombatBehavior, override: ExileTacticsOverride) -> void :
    if override == null:
        return




    if not override.target_rules.is_empty():
        behavior.target_rules = override.target_rules.duplicate()
    behavior.fallback_picker = override.fallback_picker





    var needs_tactical_dup: bool = (
        override.target_lock_seconds >= 0.0
        or _kite_profile_touches_tactical(override.kite_profile)
    )
    if needs_tactical_dup:
        behavior.tactical_profile = behavior.get_tactical().duplicate()


    if override.target_lock_seconds >= 0.0:
        behavior.tactical_profile.sticky_target_duration = override.target_lock_seconds


    if override.kite_profile != KiteProfile.Profile.INHERIT:
        _apply_kite_profile(behavior, override.kite_profile)






static func _kite_profile_touches_tactical(profile: int) -> bool:
    if profile == KiteProfile.Profile.INHERIT:
        return false
    if not KiteProfile.PROFILE_DEFS.has(profile):
        return false
    var def: Dictionary = KiteProfile.PROFILE_DEFS[profile]
    return def.has("tactical_overrides")









static func _apply_kite_profile(behavior: CombatBehavior, profile: int) -> void :
    if not KiteProfile.PROFILE_DEFS.has(profile):
        push_warning(
            "CombatBehavior._apply_kite_profile: unknown KiteProfile %d — leaving gear defaults"
            %profile
        )
        return
    var def: Dictionary = KiteProfile.PROFILE_DEFS[profile]
    behavior.kite_mode = def["kite_mode"]
    behavior.preferred_distance = behavior.attack_range * float(def["preferred_distance_pct"])
    behavior.stance = def["stance"]




    if def.has("tactical_overrides"):
        var overrides: Dictionary = def["tactical_overrides"]
        for key in overrides:
            behavior.tactical_profile.set(key, overrides[key])


static func _get_equipped_weapon(exile: ExileData) -> Item:
    var weapon: Item = exile.get_equipped_item(ItemEnums.EquipSlot.MAIN_HAND)
    if weapon != null:
        return weapon
    return exile.get_equipped_item(ItemEnums.EquipSlot.BOTH_HANDS)
