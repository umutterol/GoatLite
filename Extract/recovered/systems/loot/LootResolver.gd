class_name LootResolver
extends RefCounted







class EncounterLoot:
    var items: Array[Item] = []
    var experience_total: int = 0




    var food: int = 0
    var scrap: int = 0
    var chaos: int = 0


    var exalt: int = 0












    var per_kill_drops: Dictionary = {}





    var bonus_drops: Dictionary = {}




    var bonus_source_combatant_id: int = -1




    func ensure_per_kill_entry(combatant_id: int) -> Dictionary:
        if not per_kill_drops.has(combatant_id):
            per_kill_drops[combatant_id] = {
                "food": 0, "scrap": 0, "chaos": 0, 

                "exalt": 0, 



                "items": [] as Array[Item], 
            }
        return per_kill_drops[combatant_id]







static func resolve_encounter(
    defeated_monsters: Array[CombatantData], 
    mission: MissionData, 
    item_generator: ItemGenerator, 
    rng: RandomNumberGenerator, 
) -> EncounterLoot:
    var loot: = EncounterLoot.new()

    for combatant in defeated_monsters:
        var monster_data: MonsterData = combatant.source_monster
        if not monster_data:
            continue





        loot.experience_total += combatant.scaled_experience_value




        var per_kill: Dictionary = loot.ensure_per_kill_entry(combatant.combatant_id)





        var food_count: int = _roll_drop_count(monster_data.food_drops, rng)
        var scrap_count: int = _roll_drop_count(monster_data.scrap_drops, rng)
        var chaos_count: int = _roll_drop_count(monster_data.chaos_drops, rng)
        var exalt_count: int = _roll_drop_count(monster_data.exalt_drops, rng)
        var vaal_count: int = _roll_drop_count(monster_data.vaal_drops, rng)
        loot.food += food_count
        loot.scrap += scrap_count
        loot.chaos += chaos_count
        loot.exalt += exalt_count
        per_kill["food"] += food_count
        per_kill["scrap"] += scrap_count
        per_kill["chaos"] += chaos_count
        per_kill["exalt"] += exalt_count


        for _i in vaal_count:
            _materialise_vaal_orb(loot, per_kill)




        _resolve_drop_table(monster_data, mission, item_generator, rng, loot, per_kill)







        var total_quantity: float = monster_data.base_drop_chance\
+ mission.quantity_bonus\
+ monster_data.item_quantity_bonus
        var drop_count: int = _roll_drop_count(total_quantity, rng)
        if drop_count <= 0:
            continue



        var combined_rarity_boost: float = mission.rarity_bonus + monster_data.item_rarity_bonus

        for _i in drop_count:
            var item: = _generate_drop(monster_data, mission, item_generator, rng, combined_rarity_boost)
            if item:
                loot.items.append(item)
                per_kill["items"].append(item)







                _roll_natural_currency_drops(loot, per_kill, rng)

    return loot







static func _roll_natural_currency_drops(
    loot: EncounterLoot, 
    per_kill: Dictionary, 
    rng: RandomNumberGenerator, 
) -> void :
    if rng.randf() < GameSettings.NATURAL_EXALT_DROP_CHANCE:
        loot.exalt += 1
        per_kill["exalt"] += 1
    if rng.randf() < GameSettings.NATURAL_CHAOS_DROP_CHANCE:
        loot.chaos += 1
        per_kill["chaos"] += 1
    if rng.randf() < GameSettings.NATURAL_VAAL_DROP_CHANCE:
        _materialise_vaal_orb(loot, per_kill)







static func _materialise_vaal_orb(loot: EncounterLoot, per_kill: Dictionary) -> void :
    var vaal: Item = VaalOrbFactory.make()
    loot.items.append(vaal)
    per_kill["items"].append(vaal)





static func _resolve_drop_table(
    monster: MonsterData, 
    mission: MissionData, 
    item_generator: ItemGenerator, 
    rng: RandomNumberGenerator, 
    loot: EncounterLoot, 
    per_kill: Dictionary, 
) -> void :
    if not monster.drop_table:
        return
    for entry in monster.drop_table.entries:
        if not entry or not entry.item_base:
            continue
        if rng.randf() > entry.chance:
            continue


        var forced: = item_generator.generate_item(mission.level, entry.item_base, _drop_tags_for(monster, mission))
        if forced:
            loot.items.append(forced)
            per_kill["items"].append(forced)




static func resolve_completion(
    mission: MissionData, 
    completion_percent: float, 
    item_generator: ItemGenerator, 
    rng: RandomNumberGenerator, 
) -> Array[Item]:
    var items: Array[Item] = []
    if not mission.mission_rewards:
        return items

    var rewards: MissionReward = mission.mission_rewards





    var mission_rarity_boost: float = mission.rarity_bonus


    if completion_percent >= 1.0:
        for base in rewards.guaranteed_item_bases:
            var item: = item_generator.generate_item(mission.level, base, _mission_tags(mission), mission_rarity_boost)
            if item:
                items.append(item)


    var bonus_rolls: int = int(rewards.bonus_item_rolls * completion_percent)
    for _i in bonus_rolls:
        var item: = item_generator.generate_item(mission.level, null, _mission_tags(mission), mission_rarity_boost)
        if item:
            items.append(item)





    var vaal_count: int = int(rewards.vaal_orb_drops * completion_percent)
    for _i in vaal_count:
        items.append(VaalOrbFactory.make())


    var _unused: = rng

    return items







static func _generate_drop(
    monster: MonsterData, 
    mission: MissionData, 
    item_generator: ItemGenerator, 
    _rng: RandomNumberGenerator, 
    rarity_boost: float = 0.0, 
) -> Item:
    return item_generator.generate_item(
        mission.level, null, _drop_tags_for(monster, mission), rarity_boost
    )


static func _mission_tags(mission: MissionData) -> Array:

    return [WorldEnum.AREAS.keys()[mission.area_requirement].to_lower()]





static func _drop_tags_for(monster: MonsterData, mission: MissionData) -> Array:
    var tags: Array = _mission_tags(mission)
    if monster and not monster.drop_tags.is_empty():
        tags.append_array(monster.drop_tags)
    return tags










static func _roll_drop_count(amount: float, rng: RandomNumberGenerator) -> int:
    if amount <= 0.0:
        return 0
    var guaranteed: int = int(floor(amount))
    var bonus_chance: float = amount - float(guaranteed)
    if rng.randf() < bonus_chance:
        return guaranteed + 1
    return guaranteed
