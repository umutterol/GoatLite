class_name StatDefinition
extends Resource





enum StatCategory{
    CORE, 
    DEFENSIVE, 
    HEALING, 
    OFFENSIVE, 
    UTILITY
}





enum StatType{
    FLAT, 
    PERCENTAGE
}









enum StatScalingType{
    FLAT, 
    INCREASED, 
    MORE, 
    REDUCED, 
    LESS, 
}












@export var stat_id: String = ""




@export var display_name: String = ""




@export_multiline var description: String = ""









@export var category: StatCategory = StatCategory.CORE





@export var stat_type: StatType = StatType.FLAT





@export var default_value: float = 0.0





@export var min_value: float = -999999.0





@export var max_value: float = 999999.0







@export var show_as_percentage: bool = false





@export var decimal_places: int = 0




@export var icon: Texture2D
