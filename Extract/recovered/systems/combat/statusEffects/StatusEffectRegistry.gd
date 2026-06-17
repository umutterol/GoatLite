class_name StatusEffectRegistry
extends RefCounted




















const DIR_PATH: = "res://systems/combat/statusEffects/"









const _EXCLUDED_FROM_TARGET_FILTERS: Array[StringName] = [&"desperation"]

static var _cache: Array[StatusEffect] = []
static var _loaded: bool = false




static func all() -> Array[StatusEffect]:
    if not _loaded:
        _load()
    return _cache.duplicate()






static func for_target_filters() -> Array[StatusEffect]:
    if not _loaded:
        _load()
    var out: Array[StatusEffect] = []
    for effect in _cache:
        if effect == null:
            continue
        if effect.effect_id in _EXCLUDED_FROM_TARGET_FILTERS:
            continue
        out.append(effect)
    return out




static func by_id(id: StringName) -> StatusEffect:
    if not _loaded:
        _load()
    for effect in _cache:
        if effect != null and effect.effect_id == id:
            return effect
    return null






static func _load() -> void :


    _loaded = true


    for path in ResourceDirScan.list_tres_files(DIR_PATH):
        var loaded: = load(path) as StatusEffect
        if loaded != null:
            _cache.append(loaded)
        else:
            push_warning("StatusEffectRegistry: %s did not load as StatusEffect" % path)
