class_name RecruitmentManager
extends RefCounted

static func generate_daily_recruits(count: int = GameSettings.BASE_RECRUIT_COUNT) -> Array[RecruitData]:
    var recruits: Array[RecruitData] = []

    for i in range(count):
        var recruit = _generate_single_recruit()
        recruits.append(recruit)


    if recruits.is_empty():
        recruits.append(_generate_common_recruit())

    return recruits














static func generate_event_recruits(params: Dictionary) -> Array[RecruitData]:
    var count: int = int(params.get("count", 1))
    var level_min: int = max(1, int(params.get("level_min", 1)))
    var level_max: int = max(level_min, int(params.get("level_max", level_min)))
    var quality_bonus: float = float(params.get("quality_bonus", 0.0))
    var min_class_rarity: int = int(params.get("min_class_rarity", 0))
    var min_trait_rarity: int = int(params.get("min_trait_rarity", 0))
    var free: bool = bool(params.get("free", false))
    var guaranteed_desperate: bool = bool(params.get("desperate", false))

    var recruits: Array[RecruitData] = []

    for i in range(count):
        var exile_params: Dictionary = {
            "level": randi_range(level_min, level_max), 
            "min_class_rarity": min_class_rarity, 
            "min_trait_rarity": min_trait_rarity, 
            "quality_bonus": quality_bonus, 
        }

        var recruit: = RecruitData.new()
        recruit.exile_data = ExileGenerator.create_exile(exile_params)
        recruit.is_event_recruit = true



        recruit.food_cost = 0
        recruit.chaos_cost = 0
        recruit.scrap_cost = 0
        recruit.exalt_cost = 0

        if not free:
            _calculate_event_recruit_cost(recruit)

        if guaranteed_desperate:
            recruit.apply_desperate_modifier()

        recruits.append(recruit)

    return recruits





static func _calculate_event_recruit_cost(recruit: RecruitData) -> void :
    var exile: ExileData = recruit.exile_data
    if exile == null:
        push_warning("RecruitmentManager: recruit has null exile_data, skipping cost calc")
        return


    var value: float = float(GameSettings.EVENT_RECRUIT_BASE_SCRAP_COST)
    if exile.class_definition:
        var class_rarity_name: String = ClassDefinition.ClassRarity.keys()[exile.class_definition.rarity]
        value += float(GameSettings.EVENT_RECRUIT_CLASS_RARITY_COSTS.get(class_rarity_name, 0))
    for trait_id in exile.traits:
        var trait_def: TraitDefinition = TraitLibrary.get_trait_by_id(trait_id)
        if trait_def:
            var trait_rarity_name: String = TraitDefinition.TraitRarity.keys()[trait_def.rarity]
            value += float(GameSettings.EVENT_RECRUIT_TRAIT_RARITY_COSTS.get(trait_rarity_name, 0))





    var lvl: int = max(1, exile.level)
    var level_multiplier: float = float(GameSettings.EVENT_RECRUIT_LEVEL_MULTIPLIER.get(lvl, 0.0))
    if level_multiplier <= 0.0:
        push_warning("RecruitmentManager: no EVENT_RECRUIT_LEVEL_MULTIPLIER for level %d, using linear fallback" % lvl)
        level_multiplier = float(lvl)
    value *= level_multiplier



    var variance: float = randf_range(
        - GameSettings.EVENT_RECRUIT_COST_VARIANCE, GameSettings.EVENT_RECRUIT_COST_VARIANCE
    )
    value *= (1.0 + variance)
    value = max(value, 1.0)


    var bundle: String = _roll_cost_bundle()
    match bundle:
        "SCRAP_ONLY":
            recruit.scrap_cost = int(round(value))
        "SCRAP_EXALT":
            var converted: float = value * GameSettings.EVENT_RECRUIT_EXALT_CONVERT_PCT
            recruit.exalt_cost = max(1, int(round(converted / GameSettings.EVENT_RECRUIT_SCRAP_PER_EXALT)))
            recruit.scrap_cost = max(0, int(round(value * (1.0 - GameSettings.EVENT_RECRUIT_EXALT_CONVERT_PCT))))
        "SCRAP_CHAOS":
            var converted: float = value * GameSettings.EVENT_RECRUIT_CHAOS_CONVERT_PCT
            recruit.chaos_cost = max(1, int(round(converted / GameSettings.EVENT_RECRUIT_SCRAP_PER_CHAOS)))
            recruit.scrap_cost = max(0, int(round(value * (1.0 - GameSettings.EVENT_RECRUIT_CHAOS_CONVERT_PCT))))
        _:


            push_warning("RecruitmentManager: unknown cost bundle '%s', defaulting to SCRAP_ONLY" % bundle)
            recruit.scrap_cost = int(round(value))





static func _roll_cost_bundle() -> String:
    var weights: Dictionary = GameSettings.EVENT_RECRUIT_BUNDLE_WEIGHTS
    var total: float = 0.0
    for k in weights:
        total += float(weights[k])
    if total <= 0.0:
        return "SCRAP_ONLY"
    var roll: float = randf() * total
    var cum: float = 0.0
    for k in weights:
        cum += float(weights[k])
        if roll <= cum:
            return String(k)
    return "SCRAP_ONLY"

static func _generate_single_recruit(params: Dictionary = {}) -> RecruitData:
    var recruit = RecruitData.new()


    var exile_params = {
        "min_trait_rarity": params.get("min_trait_rarity", 0), 
        "min_class_rarity": params.get("min_class_rarity", 0), 
        "class_rarity_override": params.get("class_rarity_override", -1), 
        "level": params.get("level", 1), 
        "name": params.get("name", "")
    }

    recruit.exile_data = ExileGenerator.create_exile(exile_params)


    _calculate_recruit_costs(recruit)


    if params.get("force_desperate", false):
        recruit.apply_desperate_modifier()
    elif randf() * 100.0 < GameSettings.DESPERATE_RECRUIT_CHANCE:
        recruit.apply_desperate_modifier()

    return recruit

static func _generate_common_recruit() -> RecruitData:
    var params = {
        "class_rarity_override": 0, 
    }
    return _generate_single_recruit(params)

static func _calculate_recruit_costs(recruit: RecruitData):
    var exile = recruit.exile_data
    var food_cost = GameSettings.RECRUIT_BASE_FOOD_COST
    var chaos_cost = GameSettings.RECRUIT_BASE_CHAOS_COST


    if exile.class_definition:
        var class_rarity_name = ClassDefinition.ClassRarity.keys()[exile.class_definition.rarity]
        food_cost += GameSettings.CLASS_RARITY_FOOD_COSTS.get(class_rarity_name, 0)


    for trait_id in exile.traits:
        var trait_def = TraitLibrary.get_trait_by_id(trait_id)
        if trait_def:
            var trait_rarity_name = TraitDefinition.TraitRarity.keys()[trait_def.rarity]
            food_cost += GameSettings.TRAIT_RARITY_FOOD_COSTS.get(trait_rarity_name, 0)


    food_cost = max(1, food_cost)


    chaos_cost = food_cost * GameSettings.CHAOS_COST_MULTIPLIER
    var variance = randf_range( - GameSettings.CHAOS_COST_VARIANCE, GameSettings.CHAOS_COST_VARIANCE)
    chaos_cost = int(chaos_cost * (1.0 + variance))
    chaos_cost = max(10, chaos_cost)


    var level_multiplier = exile.level
    food_cost = int(food_cost * level_multiplier)
    chaos_cost = int(chaos_cost * level_multiplier)

    recruit.food_cost = food_cost
    recruit.chaos_cost = chaos_cost





static func recruit_exile(recruit_data: RecruitData) -> bool:

    if GameState.food < recruit_data.food_cost:
        return false
    if GameState.chaos < recruit_data.chaos_cost:
        return false
    if GameState.scrap < recruit_data.scrap_cost:
        return false
    if GameState.exalt < recruit_data.exalt_cost:
        return false



    if GameState.get_living_exile_count() >= GameState.max_exiles:
        return false


    GameState.spend_food(recruit_data.food_cost)
    GameState.spend_chaos(recruit_data.chaos_cost)
    GameState.spend_scrap(recruit_data.scrap_cost)
    GameState.spend_exalt(recruit_data.exalt_cost)


    GameState.add_exile(recruit_data.exile_data)



    var index = GameState.current_recruits.find(recruit_data)
    if index >= 0:
        GameState.current_recruits.remove_at(index)

    return true
