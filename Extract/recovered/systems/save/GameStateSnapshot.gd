class_name GameStateSnapshot
extends Resource























@export var current_day: int = 1
@export var current_turn: int = 0


@export var chaos: int = 0
@export var food: int = 0
@export var scrap: int = 0
@export var exalt: int = 0





@export var exiles: Array[ExileData] = []
@export var next_exile_id: int = 1




@export var guild_stash: Array[Item] = []


@export var stash_tab_names: Array[String] = []


@export var current_recruits: Array[RecruitData] = []






@export var next_event_recruit_day: int = -1




@export var current_party_ids: Array[int] = []
@export var party_auto_dropped_recovering: Array[int] = []



@export var selected_mission_board_area: WorldEnum.AREAS = WorldEnum.AREAS.COAST






@export var core_exile_ids: Array[int] = []
@export var backbench_exile_ids: Array[int] = []
