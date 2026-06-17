class_name GameSaveData
extends Resource















const CURRENT_VERSION: int = 4

@export var save_version: int = CURRENT_VERSION



@export var saved_at_iso: String = ""



@export var save_label: String = ""


@export var snapshot: GameStateSnapshot




@export var area_progress: Dictionary = {}
