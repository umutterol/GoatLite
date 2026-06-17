class_name MonsterData
extends Resource












@export var monster_id: String = ""



@export var display_name: String = ""




@export var icon: Texture2D



@export var description: String = ""







@export var is_unique: bool = false



@export_group("Stats")









@export var base_level: int = 1






@export var base_stats: ExileStats

@export_group("Presentation")






@export var faces_target: bool = true

@export_group("Behavior")






@export var combat_behavior: CombatBehavior



@export_group("Abilities")




















@export var action_slot_configs: Array[ActionSlotConfig] = []



@export_group("Rewards")














@export var drop_tags: Array[String] = []





@export var drop_table: MonsterDropTable







@export var experience_value: int = 10











@export var item_rarity_bonus: float = 0.0













@export var item_quantity_bonus: float = 0.0








@export var base_drop_chance: float = 0.25














@export var food_drops: float = 0.0





@export var scrap_drops: float = 0.0







@export var chaos_drops: float = 0.0










@export var exalt_drops: float = 0.0









@export var vaal_drops: float = 0.0



@export_group("Special")





@export var on_death_effect: String = ""
