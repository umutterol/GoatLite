class_name PassiveTreeNode
extends Resource


















@export var level: int = 0



@export var generated_choice_ids: Array[String] = []



@export var chosen_index: int = -1





@export var children: Array[PassiveTreeNode] = []





@export var from_parent_choice: int = -1





@export var is_abandoned: bool = false









@export var previous_chosen_index: int = -1






@export var growth_applied: bool = false








@export var is_initiator: bool = false




func is_pending() -> bool:
    return chosen_index == -1

func get_chosen_id() -> String:
    if chosen_index < 0 or chosen_index >= generated_choice_ids.size():
        return ""
    return generated_choice_ids[chosen_index]











func get_live_child() -> PassiveTreeNode:
    if chosen_index < 0:
        return null
    for child in children:
        if child == null or child.is_abandoned:
            continue
        if child.from_parent_choice == chosen_index:
            return child
    for child in children:
        if child == null or child.is_abandoned:
            continue
        if child.from_parent_choice == -1:
            return child
    return null











func get_next_in_path() -> PassiveTreeNode:
    if chosen_index >= 0:
        return get_live_child()
    if previous_chosen_index >= 0:
        for child in children:
            if child == null or child.is_abandoned:
                continue
            if child.from_parent_choice == previous_chosen_index:
                return child
        return null
    for child in children:
        if child != null and not child.is_abandoned and child.from_parent_choice == -1:
            return child
    return null









func get_abandoned_children() -> Array[PassiveTreeNode]:
    var result: Array[PassiveTreeNode] = []
    var live: PassiveTreeNode = get_next_in_path()
    for child in children:
        if child == null or child == live:
            continue
        result.append(child)
    return result
