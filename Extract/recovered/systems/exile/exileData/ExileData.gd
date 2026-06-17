class_name ExileData
extends Resource


@export var id: int = -1
@export var name: String = ""


@export var class_id: String = "warrior"

@export var class_definition: ClassDefinition


@export var level: int = 1
@export var experience: int = 0



@export var base_stats: ExileStats
@export var current_stats: ExileStats


@export var current_life: float = 100.0
@export var current_vitality: float = 100.0
@export var current_morale: float = 100.0














@export var status: String = "idle"






@export var lifecycle: ExileLifecycleState





@export var food_ration: int = 1






@export var food_ration_locked: bool = false


@export var equipped_items: Dictionary = {}


@export var allocated_passives: Dictionary = {}





@export var pending_passive_points: int = 0



@export var passive_tree_root: PassiveTreeNode


@export var traits: Array[String] = []
@export var trait_sources: Dictionary = {}


@export var potential: ExilePotential





@export var tactics_override: ExileTacticsOverride

func _init():

    pass




func get_exp_for_next_level() -> int:
    return ExileData.exp_for_level(level)






static func exp_for_level(level_value: int) -> int:
    var base: float = GameSettings.EXP_PER_LEVEL_BASE
    var multiplier: float = GameSettings.EXP_PER_LEVEL_MULTIPLIER
    return int(base * pow(multiplier, level_value - 1))

func can_level_up() -> bool:
    return experience >= get_exp_for_next_level()



func on_level_up():

    pass







func gain_experience(amount: int) -> bool:
    experience += amount

    var leveled_up: = false


    while can_level_up():
        experience -= get_exp_for_next_level()
        level += 1


        pending_passive_points += GameSettings.PASSIVE_POINTS_PER_LEVEL



        LevelUpSystem.queue_level_up(self)
        leveled_up = true

    return leveled_up




func get_equipped_item(slot: ItemEnums.EquipSlot) -> Item:
    var slot_key = ItemEnums.EquipSlot.keys()[slot]
    return equipped_items.get(slot_key, null)


func has_item_in_slot(slot: ItemEnums.EquipSlot) -> bool:
    var slot_key = ItemEnums.EquipSlot.keys()[slot]
    return equipped_items.has(slot_key) and equipped_items[slot_key] != null





func get_passive_weight_modifier(passive: PassiveDefinition) -> float:
    if not potential:
        return 1.0

    return potential.calculate_passive_weight(passive)

func allocate_passive(passive_id: String):
    if not allocated_passives.has(passive_id):
        allocated_passives[passive_id] = {"count": 0, "rolled_values": []}

    var passive_def = PassiveLibrary.get_passive_by_id(passive_id)

    if passive_def and allocated_passives[passive_id] is Dictionary and allocated_passives[passive_id]["count"] < passive_def.max_stacks:
        allocated_passives[passive_id]["count"] += 1


        var rolled_stats = []
        for bonus in passive_def.stat_bonuses:
            if bonus.use_random_range:
                var rolled = randf_range(bonus.value_range_min, bonus.value_range_max)
                rolled = snappedf(rolled, 0.1)
                rolled_stats.append(rolled)
            else:
                rolled_stats.append(bonus.base_value)

        allocated_passives[passive_id]["rolled_values"].append(rolled_stats)
        pending_passive_points -= 1














        var old_max_life: float = current_stats.max_life if current_stats else 0.0
        current_stats = StatCalculator.calculate_final_stats(self)
        var max_life_delta: float = current_stats.life - old_max_life
        if max_life_delta > 0.0:
            current_life += max_life_delta





        current_life = min(current_life, current_stats.life)
        current_stats.current_life = current_life

func has_passive(passive_id: String) -> bool:
    return get_passive_stacks(passive_id) > 0

func get_passive_stacks(passive_id: String) -> int:
    if not allocated_passives.has(passive_id):
        return 0

    var passive_data = allocated_passives[passive_id]
    if passive_data is Dictionary:
        return passive_data.get("count", 0)
    elif passive_data is int:
        return passive_data

    return 0











func has_pending_passive_pick() -> bool:
    var node: PassiveTreeNode = passive_tree_root
    while node != null:
        if node.is_pending():
            return true
        var next: PassiveTreeNode = node.get_next_in_path()
        if next == null:
            return false
        node = next
    return false



func get_pending_passive_nodes() -> Array[PassiveTreeNode]:
    var result: Array[PassiveTreeNode] = []
    var node: PassiveTreeNode = passive_tree_root
    while node != null:
        if node.is_pending():
            result.append(node)
        var next: PassiveTreeNode = node.get_next_in_path()
        if next == null:
            break
        node = next
    return result






func get_passive_tree_leaf() -> PassiveTreeNode:
    var node: PassiveTreeNode = passive_tree_root
    if node == null:
        return null
    while true:
        var next: PassiveTreeNode = node.get_next_in_path()
        if next == null:
            return node
        node = next
    return node




func append_pending_level_node(new_level: int, choice_ids: Array[String]) -> PassiveTreeNode:
    var node: = PassiveTreeNode.new()
    node.level = new_level
    node.generated_choice_ids = choice_ids.duplicate()
    node.chosen_index = -1

    var leaf: = get_passive_tree_leaf()
    if leaf == null:
        passive_tree_root = node

    else:



        node.from_parent_choice = leaf.chosen_index
        leaf.children.append(node)
    return node




func choose_passive_at_node(node: PassiveTreeNode, choice_index: int) -> bool:
    if node == null or not node.is_pending():
        return false
    if choice_index < 0 or choice_index >= node.generated_choice_ids.size():
        push_warning("choose_passive_at_node: choice_index out of range")
        return false




    node.previous_chosen_index = -1
    node.chosen_index = choice_index
    allocate_passive(node.generated_choice_ids[choice_index])




    _ensure_child_for_pick(node, choice_index)
    return true













func _ensure_child_for_pick(parent: PassiveTreeNode, chosen_idx: int) -> void :
    for child in parent.children:
        if child == null or child.is_abandoned:
            continue
        if child.from_parent_choice == chosen_idx:
            return
    for child in parent.children:
        if child == null or child.is_abandoned:
            continue
        if child.from_parent_choice == -1:
            child.from_parent_choice = chosen_idx
            _reroll_node_choices(child)
            return
    if level > parent.level:
        var choices: Array[PassiveDefinition] = PassiveSelectionManager.generate_passive_choices(self)
        var choice_ids: Array[String] = []
        for choice in choices:
            choice_ids.append(choice.passive_id)
        var new_child: = PassiveTreeNode.new()
        new_child.level = parent.level + 1
        new_child.generated_choice_ids = choice_ids
        new_child.chosen_index = -1
        new_child.from_parent_choice = chosen_idx
        parent.children.append(new_child)





func _reroll_node_choices(node: PassiveTreeNode) -> void :
    var choices: Array[PassiveDefinition] = PassiveSelectionManager.generate_passive_choices(self)
    var choice_ids: Array[String] = []
    for choice in choices:
        choice_ids.append(choice.passive_id)
    node.generated_choice_ids = choice_ids











func respec_passive_at_node(node: PassiveTreeNode) -> bool:
    if node == null or node.is_pending():
        return false


    var live_child: PassiveTreeNode = node.get_live_child()
    if live_child != null and not live_child.is_pending():
        push_warning("respec_passive_at_node: not the deepest resolved node")
        return false

    var passive_id: String = node.get_chosen_id()
    _refund_passive_stack(passive_id)
    pending_passive_points += 1





    node.previous_chosen_index = node.chosen_index
    node.chosen_index = -1




    var old_max_life: float = current_stats.max_life if current_stats else 0.0
    current_stats = StatCalculator.calculate_final_stats(self)
    var max_life_delta: float = current_stats.life - old_max_life
    if max_life_delta < 0.0:
        current_life = min(current_life, current_stats.life)
        current_stats.current_life = current_life
    return true








func respec_passive_to_level(target_level: int) -> int:
    var steps: int = 0
    while true:
        var leaf: PassiveTreeNode = get_passive_tree_leaf()
        if leaf == null or leaf.level <= target_level:
            break



        if leaf.is_pending():
            leaf.is_abandoned = true
            continue
        if not respec_passive_at_node(leaf):
            break
        steps += 1
    return steps





func _refund_passive_stack(passive_id: String) -> void :
    if not allocated_passives.has(passive_id):
        return
    var data = allocated_passives[passive_id]
    if not (data is Dictionary):
        return
    var count: int = int(data.get("count", 0))
    if count <= 0:
        return
    data["count"] = count - 1
    var rolled: Array = data.get("rolled_values", [])
    if rolled.size() > 0:
        rolled.pop_back()
    if data["count"] <= 0:
        allocated_passives.erase(passive_id)




func has_trait(trait_id: String) -> bool:
    return traits.has(trait_id)

func add_trait(trait_id: String, source: String = "Unknown"):
    if not has_trait(trait_id):
        traits.append(trait_id)
        trait_sources[trait_id] = source



func get_trait_ids() -> Array[String]:
    return traits

func get_scar_count() -> int:
    var count: = 0
    for trait_id in traits:
        var trait_def: = TraitLibrary.get_trait_by_id(trait_id)
        if trait_def and trait_def.category == TraitDefinition.TraitCategory.SCAR:
            count += 1
    return count









func is_embark_ready() -> bool:
    return status == "idle" and current_life > 0.0



func get_class_name() -> String:
    if class_definition:
        return class_definition.name
    return "Unknown"


func get_all_special_effects() -> Array[String]:
    return SpecialEffectManager.get_all_special_effects(self)
