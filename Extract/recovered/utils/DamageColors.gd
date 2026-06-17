class_name DamageColors
extends RefCounted














const COLORS: = {
    StatEnums.DamageType.PHYSICAL: Color(0.95, 0.95, 0.95), 
    StatEnums.DamageType.FIRE: Color(0.95, 0.45, 0.2), 
    StatEnums.DamageType.COLD: Color(0.55, 0.8, 1.0), 
    StatEnums.DamageType.LIGHTNING: Color(0.95, 0.9, 0.55), 
    StatEnums.DamageType.CHAOS: Color(0.8, 0.45, 0.95), 
}


const NAMES: = {
    StatEnums.DamageType.PHYSICAL: "Physical", 
    StatEnums.DamageType.FIRE: "Fire", 
    StatEnums.DamageType.COLD: "Cold", 
    StatEnums.DamageType.LIGHTNING: "Lightning", 
    StatEnums.DamageType.CHAOS: "Chaos", 
}



const KEY_TO_TYPE: = {
    "physical": StatEnums.DamageType.PHYSICAL, 
    "fire": StatEnums.DamageType.FIRE, 
    "cold": StatEnums.DamageType.COLD, 
    "lightning": StatEnums.DamageType.LIGHTNING, 
    "chaos": StatEnums.DamageType.CHAOS, 
}


static func color_for(type: StatEnums.DamageType) -> Color:
    return COLORS.get(type, Color.WHITE)


static func name_for(type: StatEnums.DamageType) -> String:
    return NAMES.get(type, "?")




static func hex_for(type: StatEnums.DamageType) -> String:
    return color_for(type).to_html(false)






static func dominant_type(payload: Dictionary) -> int:
    var best_type: int = -1
    var best_amount: float = 0.0
    for type in StatEnums.DamageType.values():
        var key: String = NAMES[type].to_lower()
        var amount: float = float(payload.get(key, 0.0))
        if amount > best_amount:
            best_amount = amount
            best_type = type
    return best_type




static func is_single_type(payload: Dictionary) -> bool:
    var non_zero_count: int = 0
    for type in StatEnums.DamageType.values():
        var key: String = NAMES[type].to_lower()
        if float(payload.get(key, 0.0)) > 0.01:
            non_zero_count += 1
            if non_zero_count > 1:
                return false
    return non_zero_count == 1
