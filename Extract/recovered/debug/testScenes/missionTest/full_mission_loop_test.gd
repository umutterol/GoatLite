extends Node





const PARTY_SIZE: int = 3
const MISSION_ID: String = "explore_coast"
const RNG_SEED: int = 0


func _ready() -> void :
    print("\n========== FULL MISSION LOOP TEST ==========\n")

    var party_ids: Array[int] = _seed_party(PARTY_SIZE)
    if party_ids.is_empty():
        push_error("Test: could not seed party")
        return

    var mission: MissionData = MissionManager.get_mission_by_id(MISSION_ID)
    if not mission:
        push_error("Test: mission '%s' not in registry" % MISSION_ID)
        return

    print("Stash before: %d items, chaos=%d, food=%d" % [
        GameState.guild_stash.size(), GameState.chaos, GameState.food
    ])
    print("Party state before:")
    print("  %s" % _party_state_snapshot(party_ids))

    var active: ActiveMission = MissionManager.accept_mission(mission, party_ids)
    if not active:
        push_error("Test: accept_mission failed")
        return

    var runner: MissionRunner = MissionManager.start_runner(active, RNG_SEED)
    var report: Dictionary = runner.run_all_encounters()

    print("\n--- REPORT ---")
    for k in report.keys():
        if k == "encounter_outcomes":
            print("  encounter_outcomes:")
            for outcome: Dictionary in report[k]:
                var result_name: String = CombatEnums.CombatResult.keys()[outcome["result"]]
                var loot: LootResolver.EncounterLoot = outcome["loot"]
                print("    [%d] %s → %s | %d items, %d xp" % [
                    outcome["index"], outcome["encounter_id"], result_name, 
                    loot.items.size(), loot.experience_total, 
                ])
        elif k == "defeat_results":
            print("  defeat_results:")
            for r in report[k]:
                print("    %s — died=%s outcome=%s scar=%s" % [
                    r.exile_data.name, r.died, 
                    r.outcome.display_name if r.outcome else "n/a", 
                    r.scar_trait.name if r.scar_trait else "none", 
                ])
        elif k == "status":
            print("  status: %s" % ActiveMission.STATUS.keys()[report[k]])
        else:
            print("  %s: %s" % [k, report[k]])

    print("\nStash after: %d items, chaos=%d, food=%d" % [
        GameState.guild_stash.size(), GameState.chaos, GameState.food
    ])
    print("Party state after:")
    print("  %s" % _party_state_snapshot(party_ids))




    print("\nHP writeback check:")
    for id in party_ids:
        var e: ExileData = GameState.get_exile_by_id(id)
        if not e:
            continue
        var max_life: float = e.current_stats.life
        var at_full: bool = e.current_life >= max_life
        var marker: String = "⚠ at full HP" if at_full else "✓ HP changed"
        print("  %s: %.1f/%.1f  %s" % [e.name, e.current_life, max_life, marker])

    print("\n=============================================\n")




func _seed_party(count: int) -> Array[int]:
    var ids: Array[int] = []
    var recruits: Array[RecruitData] = RecruitmentManager.generate_event_recruits({
        "count": count, "free": true, 
    })
    for r in recruits:
        var exile: ExileData = r.exile_data
        if GameState.add_exile(exile):
            ids.append(exile.id)
    return ids


func _party_state_snapshot(ids: Array[int]) -> String:
    var parts: Array[String] = []
    for id in ids:
        var e: ExileData = GameState.get_exile_by_id(id)
        if not e:
            continue
        parts.append("%s[L%d xp=%d hp=%.0f/%.0f morale=%.0f status=%s]" % [
            e.name, e.level, e.experience, 
            e.current_life, e.current_stats.life, 
            e.current_stats.morale, e.status, 
        ])
    return "\n  ".join(parts)
