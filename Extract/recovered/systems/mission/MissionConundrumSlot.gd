class_name MissionConundrumsSlot
extends Resource





enum SlotType{
    MANDATORY_COMBAT, 
    RANDOM_COMBAT, 
    MANDATORY_EVENT, 
    RANDOM_EVENT, 
}


@export var slot_type: SlotType = SlotType.RANDOM_COMBAT


@export var encounter: EncounterData



@export var area_filter: Array[WorldEnum.AREAS] = []


@export var required_tags: Array[MissionEnums.ENCOUNTER_TAGS] = []


@export var excluded_tags: Array[MissionEnums.ENCOUNTER_TAGS] = []
