class_name RarityWeighting
extends RefCounted






















const TIER_COUNT: int = 4





static func pick_weighted(items: Array, quality_bonus: float) -> Variant:
    if items.is_empty():
        return null


    var by_tier: Array = []
    for _i in range(TIER_COUNT):
        by_tier.append([])
    for item in items:
        var tier: int = item.rarity
        if tier < 0 or tier >= TIER_COUNT:
            continue
        by_tier[tier].append(item)


    var tier_weight: Array[float] = []
    for tier in range(TIER_COUNT):
        var sum: float = 0.0
        for item in by_tier[tier]:
            sum += item.get_drop_weight()
        tier_weight.append(sum)




    var bonus: float = clampf(quality_bonus, 0.0, 1.0)
    if bonus > 0.0 and tier_weight[0] > 0.0:
        var present_upper: Array[int] = []
        for tier in range(1, TIER_COUNT):
            if not by_tier[tier].is_empty():
                present_upper.append(tier)
        if not present_upper.is_empty():
            var shifted: float = tier_weight[0] * bonus
            tier_weight[0] -= shifted
            var per_upper: float = shifted / float(present_upper.size())
            for tier in present_upper:
                tier_weight[tier] += per_upper


    var total: float = 0.0
    for w in tier_weight:
        total += w
    if total <= 0.0:
        return null
    var roll: float = randf() * total
    var cum: float = 0.0
    var chosen_tier: int = -1
    for tier in range(TIER_COUNT):
        cum += tier_weight[tier]
        if roll <= cum and tier_weight[tier] > 0.0:
            chosen_tier = tier
            break
    if chosen_tier == -1:

        for tier in range(TIER_COUNT - 1, -1, -1):
            if tier_weight[tier] > 0.0:
                chosen_tier = tier
                break
    if chosen_tier == -1:
        return null


    var tier_items: Array = by_tier[chosen_tier]
    if tier_items.is_empty():

        for tier in range(TIER_COUNT):
            if not by_tier[tier].is_empty():
                tier_items = by_tier[tier]
                break
    if tier_items.is_empty():
        return null

    var item_total: float = 0.0
    for item in tier_items:
        item_total += item.get_drop_weight()
    if item_total <= 0.0:
        return tier_items[0]
    var item_roll: float = randf() * item_total
    var item_cum: float = 0.0
    for item in tier_items:
        item_cum += item.get_drop_weight()
        if item_roll <= item_cum:
            return item
    return tier_items[-1]
