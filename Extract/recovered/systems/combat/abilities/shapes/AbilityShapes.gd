class_name AbilityShapes
extends RefCounted



























static func circle(centre: Vector2, radius: float, candidates: Array[CombatantData]) -> Array[CombatantData]:
    var hit: Array[CombatantData] = []
    var radius_sq: float = radius * radius
    for c in candidates:
        if c.position.distance_squared_to(centre) <= radius_sq:
            hit.append(c)
    return hit








static func line(origin: Vector2, forward: Vector2, length: float, width: float, candidates: Array[CombatantData]) -> Array[CombatantData]:



    var centre: Vector2 = origin + forward * (length * 0.5)
    return rectangle(centre, forward, length, width, candidates)








static func rectangle(centre: Vector2, forward: Vector2, length: float, width: float, candidates: Array[CombatantData]) -> Array[CombatantData]:
    var hit: Array[CombatantData] = []
    var half_length: float = length * 0.5
    var half_width: float = width * 0.5

    var side: Vector2 = Vector2( - forward.y, forward.x)
    for c in candidates:
        var local: Vector2 = c.position - centre
        var along: float = local.dot(forward)
        var across: float = local.dot(side)
        if absf(along) <= half_length and absf(across) <= half_width:
            hit.append(c)
    return hit











static func cone(origin: Vector2, forward: Vector2, length: float, half_angle_rad: float, candidates: Array[CombatantData]) -> Array[CombatantData]:
    var hit: Array[CombatantData] = []
    var length_sq: float = length * length


    var cos_half: float = cos(half_angle_rad)
    for c in candidates:
        var offset: Vector2 = c.position - origin
        var dist_sq: float = offset.length_squared()
        if dist_sq <= 0.0001:



            hit.append(c)
            continue
        if dist_sq > length_sq:
            continue

        var cos_angle: float = offset.dot(forward) / sqrt(dist_sq)
        if cos_angle >= cos_half:
            hit.append(c)
    return hit






static func ring(centre: Vector2, inner_radius: float, outer_radius: float, candidates: Array[CombatantData]) -> Array[CombatantData]:
    var hit: Array[CombatantData] = []
    var inner_sq: float = inner_radius * inner_radius
    var outer_sq: float = outer_radius * outer_radius
    for c in candidates:
        var dist_sq: float = c.position.distance_squared_to(centre)
        if dist_sq >= inner_sq and dist_sq <= outer_sq:
            hit.append(c)
    return hit
