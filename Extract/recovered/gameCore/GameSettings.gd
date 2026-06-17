class_name GameSettings
extends RefCounted



const TURNS_PER_DAY = 10


const STARTING_CHAOS = 0
const STARTING_FOOD = 0
const STARTING_SCRAP = 0
const STARTING_EXALT = 0


const CLASS_RARITY_WEIGHTS = {
    "COMMON": 70.0, 
    "UNCOMMON": 20.0, 
    "RARE": 8.0, 
    "LEGENDARY": 2.0
}


const EXILE_REVEALED_POTENTIALS_PERCENT = 50.0
const EXILE_LEVEL_UP_DISCOVERY_CHANCE = 50.0


const PASSIVE_CHOICES_PER_LEVEL = 3
const PASSIVE_RARITY_WEIGHTS = {
    "COMMON": 86.5, 
    "UNCOMMON": 10.0, 
    "RARE": 3.0, 
    "LEGENDARY": 0.5
}



const TRAIT_STARTING_CHANCES = {
    1: 80.0, 
    2: 15.0, 
    3: 5.0
}


const TRAIT_RARITY_WEIGHTS = {
    "COMMON": 60.0, 
    "UNCOMMON": 25.0, 
    "RARE": 12.0, 
    "LEGENDARY": 3.0
}


const LEARNED_TRAIT_LEVELS = [10, 20]





const BASE_RECRUIT_COUNT = 3
const DESPERATE_RECRUIT_CHANCE = 5.0


const RECRUIT_BASE_FOOD_COST = 5
const RECRUIT_BASE_CHAOS_COST = 50


const CLASS_RARITY_FOOD_COSTS = {
    "COMMON": 0, 
    "UNCOMMON": 1, 
    "RARE": 2, 
    "LEGENDARY": 3
}
const TRAIT_RARITY_FOOD_COSTS = {
    "COMMON": -1, 
    "UNCOMMON": 0, 
    "RARE": 1, 
    "LEGENDARY": 2
}

const CHAOS_COST_MULTIPLIER = 10
const CHAOS_COST_VARIANCE = 0.2














const RECRUIT_OFFER_DAYS_MIN: int = 6
const RECRUIT_OFFER_DAYS_MAX: int = 12




const EVENT_RECRUIT_COUNT_MIN: int = 2
const EVENT_RECRUIT_COUNT_MAX: int = 3





const EVENT_RECRUIT_LEVEL_MARGIN: float = 0.4




const MISSION_RECRUIT_LEVEL_MARGIN: float = 0.25







const EVENT_RECRUIT_QUALITY_BONUS: float = 0.0
const MISSION_RECRUIT_QUALITY_BONUS: float = 0.3





const EVENT_RECRUIT_MIN_CLASS_RARITY: int = 0
const EVENT_RECRUIT_MIN_TRAIT_RARITY: int = 0
const MISSION_RECRUIT_MIN_CLASS_RARITY: int = 0
const MISSION_RECRUIT_MIN_TRAIT_RARITY: int = 0










const EVENT_RECRUIT_BASE_SCRAP_COST: int = 10


const EVENT_RECRUIT_CLASS_RARITY_COSTS: Dictionary = {
    "COMMON": 0, 
    "UNCOMMON": 5, 
    "RARE": 15, 
    "LEGENDARY": 30, 
}


const EVENT_RECRUIT_TRAIT_RARITY_COSTS: Dictionary = {
    "COMMON": 0, 
    "UNCOMMON": 2, 
    "RARE": 5, 
    "LEGENDARY": 10, 
}







const EVENT_RECRUIT_LEVEL_MULTIPLIER: Dictionary = {
    1: 0.48, 
    2: 1.12, 
    3: 2.0, 
    4: 2.96, 
    5: 4.0, 
    6: 5.28, 
    7: 6.72, 
    8: 8.32, 
    9: 10.08, 
    10: 12.0, 
}



const EVENT_RECRUIT_COST_VARIANCE: float = 0.2




const EVENT_RECRUIT_BUNDLE_WEIGHTS: Dictionary = {
    "SCRAP_ONLY": 60.0, 
    "SCRAP_EXALT": 20.0, 
    "SCRAP_CHAOS": 20.0, 
}





const EVENT_RECRUIT_EXALT_CONVERT_PCT: float = 0.4
const EVENT_RECRUIT_CHAOS_CONVERT_PCT: float = 0.3





const EVENT_RECRUIT_SCRAP_PER_EXALT: float = 25.0
const EVENT_RECRUIT_SCRAP_PER_CHAOS: float = 5.0









const EVASION_CAP: float = 75.0




















const MONSTER_LIFE_PCT_PER_LEVEL: float = 10.0




const MONSTER_VITALITY_PCT_PER_LEVEL: float = 10.0





const MONSTER_DAMAGE_PCT_PER_LEVEL: float = 5.0







const MONSTER_XP_PCT_PER_LEVEL: float = 10.0











const SHOCK_BASE_CHANCE: float = 10.0






const SHOCK_MIN_APPLIED_MAGNITUDE: float = 5.0





const SHOCK_MAX_BASE_MAGNITUDE: float = 20.0





const SHOCK_REFERENCE_DAMAGE_PCT: float = 0.1





const SHOCK_CURVE_EXPONENT: float = 0.4



const SHOCK_BASE_DURATION: float = 4.0


















const CHILL_MIN_APPLIED_MAGNITUDE: float = 5.0






const CHILL_MAX_BASE_MAGNITUDE: float = 20.0




const CHILL_REFERENCE_DAMAGE_PCT: float = 0.1





const CHILL_CURVE_EXPONENT: float = 0.4



const CHILL_BASE_DURATION: float = 4.0












const IGNITE_BASE_CHANCE: float = 0.0



const IGNITE_BASE_DURATION: float = 4.0






const IGNITE_BASE_DAMAGE_FRACTION: float = 0.9





const IGNITE_MIN_APPLIED_DPS: float = 1.0














const IMPALE_BASE_CAPTURE_PCT: float = 10.0





const IMPALE_BASE_CHANCE: float = 0.0





const IMPALE_BASE_MAX_STACKS: int = 3
















const POISON_BASE_CHANCE: float = 0.0




const POISON_BASE_DURATION: float = 2.0







const POISON_BASE_DAMAGE_FRACTION: float = 0.3





const POISON_MAX_STACKS: int = 999




const POISON_MIN_APPLIED_DPS: float = 0.5



const EXP_PER_LEVEL_BASE = 100
const EXP_PER_LEVEL_MULTIPLIER = 1.5
const PASSIVE_POINTS_PER_LEVEL = 1






const ZERO_MOD_BASE_CHANCE = 50
const ONE_MOD_BASE_CHANCE = 20
const TWO_MOD_BASE_CHANCE = 15
const THREE_MOD_BASE_CHANCE = 10
const FOUR_MOD_BASE_CHANCE = 5













const NATURAL_EXALT_DROP_CHANCE: float = 1.0 / 20.0
const NATURAL_CHAOS_DROP_CHANCE: float = 1.0 / 35.0
const NATURAL_VAAL_DROP_CHANCE: float = 1.0 / 50.0


























const MORALE_BRUTAL_HIT_THRESHOLD: float = 0.05
const MORALE_BRUTAL_HIT_BUCKET: float = 0.05
const MORALE_BRUTAL_HIT_PENALTY_PER_TIER: int = 2
const MORALE_BRUTAL_HIT_PENALTY_MAX: int = 10


const MORALE_MISSION_SUCCESS_BASE: float = 1.0


const MORALE_THRILLING_VICTORY_DAMAGE_PCT: float = 80.0
const MORALE_THRILLING_VICTORY_BONUS: float = 3.0



const MORALE_BOREDOM_PENALTY_CAP: float = -5.0
const MORALE_SAFE_RETREAT_PENALTY: float = -5.0
const MORALE_RISKY_RETREAT_PENALTY: float = -15.0




const MORALE_REST_WITHOUT_FOOD_BASE: float = -3.0
const MORALE_REST_FULL_VITALITY_BONUS: float = 1.0




const MORALE_RARE_KILL_BONUS: float = 1.0
const MORALE_BOSS_KILL_BONUS: float = 5.0




const MORALE_HIGH_THRESHOLD_PERCENT: float = 90.0
const MORALE_LOW_THRESHOLD_PERCENT: float = 25.0




const MORALE_HIGH_DAMAGE_DEALT_MORE: float = 10.0
const MORALE_HIGH_DAMAGE_TAKEN_LESS: float = 10.0
const MORALE_HIGH_XP_MORE: float = 10.0








const MORALE_BROKEN_LEAVE_ENABLED: bool = false



const MORALE_LEAVE_CHANCE_PER_TURN: float = 5.0
const MORALE_LEAVE_CHANCE_CAP: float = 95.0













const LIFE_PER_VITALITY: float = 5.0





const VITALITY_PER_LIFE_HEALED: float = 0.5





const REST_VITALITY_REGEN_PCT: float = 0.05




const RECOVERY_VITALITY_REGEN_BONUS_PCT: float = 0.05






const RATION_VITALITY_BONUS: Array = [0.0, 0.05, 0.075]




const DEATH_CHANCE_PER_SCAR = {
    0: 0.0, 
    1: 3.0, 
    2: 8.0, 
    3: 15.0, 
    4: 35.0, 
    5: 60.0, 
}
const DEATH_CHANCE_MAX_SCARS = 60.0








const RESCUE_TIMEOUT_DAYS_DEFAULT: int = 3




const LONG_LOST_RESCUE_TIMEOUT: int = 2



const LONG_LOST_ELIGIBILITY_DAYS: int = 7







const LONG_LOST_ROLL_PER_SCOUTING: float = 0.01
