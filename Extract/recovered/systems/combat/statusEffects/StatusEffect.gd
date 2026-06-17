class_name StatusEffect
extends Resource





















































enum RefreshMode{
    REPLACE, 
    REFRESH_DURATION, 
    IGNORE, 
    REPLACE_IF_STRONGER, 
}




@export var effect_id: StringName = &""


@export var display_name: String = ""



@export_multiline var description: String = ""



@export var max_stacks: int = 1






@export var duration_seconds: float = 0.0




@export var refresh_mode: RefreshMode = RefreshMode.REFRESH_DURATION



@export var is_buff: bool = false













@export var is_damage_over_time: bool = false




















@export var stat_modifiers: Dictionary = {}










@export var per_tick_effects: Dictionary = {}







@export var vfx: PersistentVFX
