class_name MonsterSpawn
extends Resource



@export var monster: MonsterData


@export_range(1, 20) var count: int = 1


enum PositionHint{
    FRONTLINE, 
    BACKLINE, 
    FLANK, 
    SPREAD, 
    VANGUARD, 
    REAR, 

}
@export var position_hint: PositionHint = PositionHint.FRONTLINE
