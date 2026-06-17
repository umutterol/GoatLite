class_name MissionData
extends Resource








@export var mission_id: String = ""


@export var display_name: String = ""


@export_multiline var description: String = ""


@export var icon: Texture2D

@export_group("Where & When")

@export var area_requirement: WorldEnum.AREAS = WorldEnum.AREAS.COAST




@export var level: int = 1



@export var mission_tags: Array[MissionEnums.MISSION_TAGS] = []









@export var availability_type: MissionEnums.AVAILABILITY_TYPE






@export var prerequisites: Array[ProgressionRequirement] = []

@export_subgroup("Recruit Bonus (RECRUIT tag only)")













@export_range(-1.0, 1.0, 0.05) var recruit_quality_bonus: float = -1.0




@export_range(-1.0, 1.0, 0.05) var recruit_level_margin: float = -1.0





@export_range(-1, 3, 1) var recruit_min_class_rarity: int = -1






@export_range(-1, 3, 1) var recruit_min_trait_rarity: int = -1





@export_range(1, 6, 1) var recruit_count: int = 1

@export_subgroup("Discoverable Only")



@export_range(0.0, 100.0) var scouting_threshold_percent: float = 0.0




@export_range(0.0, 1.0) var discovery_base_chance: float = 0.0



@export var discovery_description: String = ""

@export_subgroup("Opportunity Only")



@export_range(0.0, 1.0) var opportunity_chance: float = 0.0



@export var timeout_days: int = -1




@export var one_time_only: bool = false




@export var opportunity_cooldown_days: int = 0

@export_subgroup("Boss Only")





@export var boss_mission: bool = false





@export var boss_cooldown_days: int = 0

@export_group("Mission Details")




@export var mission_length: int = 1

@export_subgroup("Encounters & Events")



@export var encounter_slots: Array[MissionConundrumsSlot] = []

@export_subgroup("Rewards")





@export var scouting_reward: float = 0.0


@export var rarity_bonus: float = 0.0


@export var quantity_bonus: float = 0.0


@export var mission_rewards: MissionReward
