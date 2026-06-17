class_name CombatEnums
extends RefCounted






enum AggroType{
    NEAREST, 
    LOWEST_HP, 
    HIGHEST_HP, 
    RANDOM, 
    NONE, 
}

enum AbilityTarget{
    NEAREST, 
    LOWEST_HP, 
    HIGHEST_HP, 
    RANDOM, 
    SELF, 
    NONE, 
}

enum AbilityType{
    SINGLE_TARGET, 
    LINE, 
    CONE, 
    CIRCLE, 
    RECTANGLE, 
}


enum KiteMode{
    NONE, 
    MOVEMENT_SKILL_ONLY, 
    KITE_BETWEEN_ATTACKS, 
    KITE_ONLY_VS_SLOWER_MELEE, 





}


enum Stance{
    AGGRESSIVE, 
    BALANCED, 
    DEFENSIVE, 
}




enum CombatantTeam{
    EXILES, 
    MONSTERS, 
    THIRD_PARTY, 
    EXILES_ALLIES, 
    ROGUE_EXILES, 
}

enum CombatantState{
    IDLE, 
    MOVING, 
    ATTACKING, 
    STUNNED, 
    FROZEN, 
    PINNED, 
    DOWNED, 
    DEAD, 
    RETREATED, 
}

enum CombatResult{
    VICTORY, 
    DEFEAT, 
    RETREAT, 
}




enum CombatEventType{
    COMBAT_START, 
    COMBAT_END, 
    ROUND_START, 
    MOVEMENT, 
    ATTACK_START, 
    DAMAGE_DEALT, 
    EVASION, 
    GLANCING_BLOW, 
    BLOCK, 
    CRITICAL_STRIKE, 
    DEATH, 
    DOWNED, 
    SECOND_WIND, 
    ENDURANCE, 
    DECISION_POINT, 
    LEVEL_UP, 
    EXPERIENCE_GAINED, 



    LIFE_LEECH, 
    LIFE_GAIN_ON_HIT, 
    MORALE_PENALTY, 







    OVERTIME_BEGAN, 



    DESPERATION_INCREASED, 







    STATUS_EFFECT_APPLIED, 






    STATUS_EFFECT_EXPIRED, 



    IMPALE_APPLIED, 






    IMPALE_CONSUMED, 









    POISON_APPLIED, 

















    POISON_EXPIRED, 



    AILMENT_ROLL, 















    ABILITY_TELEGRAPHED, 

    ABILITY_EXECUTED, 

    AOE_HIT, 




    ACTION_RECOVERY, 



}
