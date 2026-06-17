class_name SaveMigrator
extends RefCounted



















static func migrate(save_data: GameSaveData) -> GameSaveData:
    if save_data == null:
        push_error("SaveMigrator.migrate: null save_data")
        return null









    while save_data.save_version < GameSaveData.CURRENT_VERSION:
        var before: int = save_data.save_version
        var matched: bool = false

        match save_data.save_version:
            1:
                _migrate_v1_to_v2(save_data)
                matched = true
            2:
                _migrate_v2_to_v3(save_data)
                matched = true
            3:
                _migrate_v3_to_v4(save_data)
                matched = true
            _:
                pass

        if not matched:
            push_error("SaveMigrator: no migrator for version %d" % save_data.save_version)
            return save_data



        if save_data.save_version <= before:
            push_error("SaveMigrator: migrator for v%d failed to advance version" % before)
            return save_data

    if save_data.save_version > GameSaveData.CURRENT_VERSION:
        push_warning(
            "SaveMigrator: save is from a newer version (%d) than this build supports (%d). "
            %[save_data.save_version, GameSaveData.CURRENT_VERSION]
            + "Loading may produce missing data or warnings."
        )
    return save_data














static func _migrate_v1_to_v2(save_data: GameSaveData) -> void :
    save_data.save_version = 2

















static func _migrate_v2_to_v3(save_data: GameSaveData) -> void :

    if save_data.area_progress != null:
        for area_key in save_data.area_progress.keys():
            var progress: AreaProgress = save_data.area_progress[area_key]
            if progress == null:
                continue
            var rebuilt: Dictionary = {}
            for legacy_key in progress.active_opportunities.keys():
                var legacy_value: Variant = progress.active_opportunities[legacy_key]
                var instance: = OpportunityInstance.new()
                instance.instance_id = String(legacy_key)
                instance.template_mission_id = String(legacy_key)
                instance.day_appeared = int(legacy_value)
                rebuilt[instance.instance_id] = instance
            progress.active_opportunities = rebuilt



            if progress.long_lost_exile_ids == null:
                progress.long_lost_exile_ids = []


    if save_data.snapshot != null and save_data.snapshot.exiles != null:
        for exile: ExileData in save_data.snapshot.exiles:
            if exile != null and exile.lifecycle == null:
                exile.lifecycle = ExileLifecycleState.new()

    save_data.save_version = 3















static func _migrate_v3_to_v4(save_data: GameSaveData) -> void :
    if save_data.snapshot != null and save_data.snapshot.exiles != null:
        for exile: ExileData in save_data.snapshot.exiles:
            if exile == null or exile.tactics_override == null:
                continue
            var override: ExileTacticsOverride = exile.tactics_override
            _translate_legacy_target_priority(override)



            if not override.has_any_override():
                exile.tactics_override = null

    save_data.save_version = 4





static func _translate_legacy_target_priority(override: ExileTacticsOverride) -> void :
    var legacy: int = override.target_priority
    if legacy < 0:
        return

    var picker: int = _aggro_type_to_picker(legacy)
    if picker < 0:



        override.target_priority = -1
        return




    override.fallback_picker = picker
    override.target_priority = -1





static func _aggro_type_to_picker(aggro: int) -> int:
    match aggro:
        CombatEnums.AggroType.NEAREST:
            return TargetRule.Picker.NEAREST
        CombatEnums.AggroType.LOWEST_HP:
            return TargetRule.Picker.LOWEST_CURRENT_HP
        CombatEnums.AggroType.HIGHEST_HP:
            return TargetRule.Picker.HIGHEST_CURRENT_HP
        CombatEnums.AggroType.RANDOM:
            return TargetRule.Picker.RANDOM
    return -1
