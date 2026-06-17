class_name PassiveTreeView
extends Control




































signal passive_hovered(passive_def: PassiveDefinition, global_pos: Vector2, suppress_effects: bool)
signal passive_unhovered()
signal choice_selected(passive_def: PassiveDefinition)
signal choice_deselected()
signal choice_committed(passive_def: PassiveDefinition)

const SMALL_WIDGET_SCENE: PackedScene = preload("res://gameUI/levelUp/PassiveTreeNodeWidget.tscn")
const DETAIL_CARD_SCENE: PackedScene = preload("res://gameUI/levelUp/PassiveChoiceDetailCard.tscn")




const Y_GAP_SMALL: float = 100.0
const SMALL_WIDGET_HALF: float = 60.0
const CARD_GAP_BEFORE: float = 140.0
const CARD_HEIGHT: float = 320.0
const CARD_X_SPACING: float = 320.0



const ORIGIN_ANCHOR_POS: Vector2 = Vector2(0, 0)
const ORIGIN_GAP_Y: float = 60.0
const BRANCH_LINE_COLOR: Color = Color(0.55, 0.5, 0.32, 1.0)
const BRANCH_LINE_WIDTH: float = 3.0


const GHOST_LINE_COLOR: Color = Color(0.35, 0.32, 0.22, 0.55)
const GHOST_LINE_WIDTH: float = 2.0
const PAN_ANIM_DURATION: float = 0.4

@onready var clip_panel: Panel = $ClipPanel
@onready var canvas: Control = $ClipPanel / Canvas
@onready var branch_layer: Control = $ClipPanel / Canvas / BranchLayer
@onready var widget_layer: Control = $ClipPanel / Canvas / WidgetLayer
@onready var jump_top_button: Button = $Overlay / JumpTopButton
@onready var jump_current_button: Button = $Overlay / JumpCurrentButton
@onready var jump_bottom_button: Button = $Overlay / JumpBottomButton
@onready var respec_button: Button = $Overlay / RespecButton
@onready var origin_anchor: Panel = $ClipPanel / Canvas / OriginAnchor

var exile: ExileData = null


var _chosen_positions: Dictionary = {}
var _pending_positions: Dictionary = {}



var _branch_segments: Array = []

var _level_y_by_level: Dictionary = {}


var _selected_pending_node: PassiveTreeNode = null
var _selected_choice_index: int = -1


var _detail_cards: Array[PassiveChoiceDetailCard] = []



var _focus_after_relayout: PassiveTreeNode = null
var _pan_tween: Tween = null


var _is_dragging: bool = false
var _drag_start_mouse: Vector2 = Vector2.ZERO
var _drag_start_canvas: Vector2 = Vector2.ZERO


func _ready() -> void :
    branch_layer.draw.connect(_draw_branches)
    GameState.exile_updated.connect(_on_exile_updated)
    jump_top_button.pressed.connect(_on_jump_top_pressed)
    jump_current_button.pressed.connect(_on_jump_current_pressed)
    jump_bottom_button.pressed.connect(_on_jump_bottom_pressed)
    respec_button.pressed.connect(_on_respec_pressed)


func bind(target_exile: ExileData) -> void :
    exile = target_exile
    _selected_pending_node = null
    _selected_choice_index = -1
    _relayout()
    call_deferred("_focus_on_current")




func _relayout() -> void :
    for child in widget_layer.get_children():
        child.queue_free()
    _chosen_positions.clear()
    _pending_positions.clear()
    _level_y_by_level.clear()
    _detail_cards.clear()




    var new_segments: Array = []

    if exile == null or exile.passive_tree_root == null:
        _branch_segments = new_segments
        branch_layer.queue_redraw()
        return












    var anchor_h: float = origin_anchor.size.y if origin_anchor.size.y > 0.0 else origin_anchor.custom_minimum_size.y
    var anchor_bottom: Vector2 = ORIGIN_ANCHOR_POS + Vector2(0, anchor_h * 0.5)
    var next_y: float = ORIGIN_GAP_Y
    var parent_chosen_x: float = 0.0
    var prev_resolved_center: Vector2 = anchor_bottom
    var have_prev: bool = true
    var node: PassiveTreeNode = exile.passive_tree_root

    while node != null:






        var is_unallocated: bool = node.is_pending() and node.previous_chosen_index >= 0
        if is_unallocated:


            var node_anchor_x: float = parent_chosen_x + (node.previous_chosen_index - 1) * CARD_X_SPACING
            var small_y_u: float = next_y + SMALL_WIDGET_HALF
            _lay_out_unallocated(node, node_anchor_x, parent_chosen_x, small_y_u)
            if have_prev:


                new_segments.append([prev_resolved_center, _chosen_positions[node], true])
                for slot_i in range(node.generated_choice_ids.size()):
                    if slot_i == node.previous_chosen_index:
                        continue
                    var sibling_slot_x: float = parent_chosen_x + (slot_i - 1) * CARD_X_SPACING
                    new_segments.append([prev_resolved_center, Vector2(sibling_slot_x, small_y_u), true])
            _level_y_by_level[node.level] = small_y_u
            next_y += SMALL_WIDGET_HALF * 2.0 + Y_GAP_SMALL
            prev_resolved_center = _chosen_positions[node]
            have_prev = true
            _lay_out_abandoned_children(node, parent_chosen_x, next_y, new_segments)
            parent_chosen_x = node_anchor_x
        elif node.is_pending():
            next_y += CARD_GAP_BEFORE
            var card_center_y: float = next_y + CARD_HEIGHT * 0.5
            _lay_out_pending(node, parent_chosen_x, card_center_y)
            if have_prev:
                for c in _pending_positions[node]:
                    new_segments.append([prev_resolved_center, c, false])
            _level_y_by_level[node.level] = card_center_y
            next_y += CARD_HEIGHT
            _lay_out_abandoned_children(node, parent_chosen_x, next_y, new_segments)




            break
        else:


            var node_chosen_x: float = parent_chosen_x + (node.chosen_index - 1) * CARD_X_SPACING
            var small_y: float = next_y + SMALL_WIDGET_HALF
            _lay_out_resolved(node, node_chosen_x, parent_chosen_x, small_y)
            if have_prev:
                new_segments.append([prev_resolved_center, _chosen_positions[node], false])


                for slot_i in range(node.generated_choice_ids.size()):
                    if slot_i == node.chosen_index:
                        continue
                    var ghost_slot_x: float = parent_chosen_x + (slot_i - 1) * CARD_X_SPACING
                    new_segments.append([prev_resolved_center, Vector2(ghost_slot_x, small_y), true])
            _level_y_by_level[node.level] = small_y
            next_y += SMALL_WIDGET_HALF * 2.0 + Y_GAP_SMALL
            prev_resolved_center = _chosen_positions[node]
            have_prev = true
            _lay_out_abandoned_children(node, parent_chosen_x, next_y, new_segments)
            parent_chosen_x = node_chosen_x

        var next_live: PassiveTreeNode = node.get_next_in_path()
        if next_live == null:
            break
        node = next_live





    _branch_segments = new_segments
    _update_branch_layer_extents()
    branch_layer.queue_redraw()




    if _focus_after_relayout != null and _chosen_positions.has(_focus_after_relayout):
        var target: Vector2 = _chosen_positions[_focus_after_relayout]
        _focus_after_relayout = null
        call_deferred("_pan_canvas_to_point", target, true)
    else:
        _focus_after_relayout = null





func _lay_out_resolved(node: PassiveTreeNode, node_chosen_x: float, parent_chosen_x: float, level_y: float) -> void :
    var passive_id: String = node.get_chosen_id()
    var passive_def: PassiveDefinition = PassiveLibrary.get_passive_by_id(passive_id)

    var widget: PassiveTreeNodeWidget = SMALL_WIDGET_SCENE.instantiate()
    widget_layer.add_child(widget)
    widget.bind(node, node.chosen_index, passive_def, false, false)
    _center_widget_at(widget, Vector2(node_chosen_x, level_y))
    _chosen_positions[node] = Vector2(node_chosen_x, level_y)
    widget.hovered.connect(_on_widget_hovered.bind(false))
    widget.unhovered.connect(_on_widget_unhovered)



    for i in range(node.generated_choice_ids.size()):
        if i == node.chosen_index:
            continue
        var ghost_x: float = parent_chosen_x + (i - 1) * CARD_X_SPACING
        var ghost_id: String = node.generated_choice_ids[i]
        var ghost_def: PassiveDefinition = PassiveLibrary.get_passive_by_id(ghost_id)
        var ghost: PassiveTreeNodeWidget = SMALL_WIDGET_SCENE.instantiate()
        widget_layer.add_child(ghost)
        ghost.bind(node, i, ghost_def, false, true)
        _center_widget_at(ghost, Vector2(ghost_x, level_y))
        ghost.hovered.connect(_on_widget_hovered.bind(false))
        ghost.unhovered.connect(_on_widget_unhovered)










func _lay_out_unallocated(node: PassiveTreeNode, node_anchor_x: float, parent_chosen_x: float, level_y: float) -> void :
    var prev_idx: int = node.previous_chosen_index


    _chosen_positions[node] = Vector2(node_anchor_x, level_y)

    for i in range(node.generated_choice_ids.size()):
        var slot_x: float = parent_chosen_x + (i - 1) * CARD_X_SPACING
        var passive_id: String = node.generated_choice_ids[i]
        var passive_def: PassiveDefinition = PassiveLibrary.get_passive_by_id(passive_id)
        var widget: PassiveTreeNodeWidget = SMALL_WIDGET_SCENE.instantiate()
        widget_layer.add_child(widget)



        var as_ghost: bool = i != prev_idx
        widget.bind(node, i, passive_def, true, as_ghost)



        if not as_ghost:
            widget.modulate = Color(1.0, 1.0, 1.0, 0.55)
        _center_widget_at(widget, Vector2(slot_x, level_y))
        widget.clicked.connect(_on_unallocated_widget_clicked)
        widget.hovered.connect(_on_widget_hovered.bind(false))
        widget.unhovered.connect(_on_widget_unhovered)


func _lay_out_pending(node: PassiveTreeNode, parent_anchor_x: float, level_y: float) -> void :


    var suppress_effects: bool = false

    var centers: Array[Vector2] = []
    for i in range(node.generated_choice_ids.size()):
        var passive_id: String = node.generated_choice_ids[i]
        var passive_def: PassiveDefinition = PassiveLibrary.get_passive_by_id(passive_id)
        var center: Vector2 = Vector2(parent_anchor_x + (i - 1) * CARD_X_SPACING, level_y)
        centers.append(center)

        var card: PassiveChoiceDetailCard = DETAIL_CARD_SCENE.instantiate()
        widget_layer.add_child(card)
        card.bind(node, i, passive_def, suppress_effects)
        _center_widget_at(card, center)
        card.clicked.connect(_on_detail_card_clicked)
        _detail_cards.append(card)
    _pending_positions[node] = centers






func _lay_out_abandoned_children(parent_node: PassiveTreeNode, parent_anchor_x: float, start_y: float, segments: Array) -> void :
    var abandoned: Array[PassiveTreeNode] = parent_node.get_abandoned_children()
    if abandoned.is_empty():
        return
    for ab_root in abandoned:
        var ab_anchor_x: float = parent_anchor_x + (ab_root.from_parent_choice - 1) * CARD_X_SPACING



        var parent_attach: Vector2
        if _chosen_positions.has(parent_node):
            parent_attach = _chosen_positions[parent_node]
        else:
            var pending_centers: Array = _pending_positions.get(parent_node, [])
            if ab_root.from_parent_choice >= 0 and ab_root.from_parent_choice < pending_centers.size():
                parent_attach = pending_centers[ab_root.from_parent_choice]
            else:
                parent_attach = Vector2(ab_anchor_x, start_y)
        _lay_out_abandoned_chain(ab_root, parent_attach, ab_anchor_x, start_y, segments)






func _lay_out_abandoned_chain(start_node: PassiveTreeNode, parent_attach: Vector2, anchor_x: float, start_y: float, segments: Array) -> void :
    var next_y: float = start_y
    var prev_center: Vector2 = parent_attach
    var node: PassiveTreeNode = start_node
    while node != null:
        var y: float = next_y + SMALL_WIDGET_HALF



        var slot_index: int = -1
        if node.chosen_index >= 0:
            slot_index = node.chosen_index
        elif node.previous_chosen_index >= 0:
            slot_index = node.previous_chosen_index
        var passive_id: String = ""
        if slot_index >= 0 and slot_index < node.generated_choice_ids.size():
            passive_id = node.generated_choice_ids[slot_index]
        elif node.generated_choice_ids.size() > 0:
            passive_id = node.generated_choice_ids[0]
            slot_index = 1
        var passive_def: PassiveDefinition = PassiveLibrary.get_passive_by_id(passive_id)
        var ghost: PassiveTreeNodeWidget = SMALL_WIDGET_SCENE.instantiate()
        widget_layer.add_child(ghost)
        ghost.bind(node, slot_index, passive_def, false, true)
        _center_widget_at(ghost, Vector2(anchor_x, y))
        ghost.hovered.connect(_on_widget_hovered.bind(false))
        ghost.unhovered.connect(_on_widget_unhovered)

        segments.append([prev_center, Vector2(anchor_x, y), true])
        prev_center = Vector2(anchor_x, y)
        next_y += SMALL_WIDGET_HALF * 2.0 + Y_GAP_SMALL




        node = node.get_next_in_path()





static func _center_widget_at(widget: Control, center: Vector2) -> void :
    var widget_size: Vector2 = widget.size if widget.size != Vector2.ZERO else widget.custom_minimum_size
    widget.position = center - widget_size * 0.5




func _draw_branches() -> void :




    var offset: Vector2 = branch_layer.position
    for seg in _branch_segments:
        var from_pos: Vector2 = seg[0] - offset
        var to_pos: Vector2 = seg[1] - offset
        var is_ghost: bool = seg[2]
        if is_ghost:
            branch_layer.draw_line(from_pos, to_pos, GHOST_LINE_COLOR, GHOST_LINE_WIDTH, true)
        else:
            branch_layer.draw_line(from_pos, to_pos, BRANCH_LINE_COLOR, BRANCH_LINE_WIDTH, true)






func _update_branch_layer_extents() -> void :
    if _branch_segments.is_empty():
        branch_layer.position = Vector2.ZERO
        branch_layer.size = clip_panel.size
        return
    var min_p: Vector2 = _branch_segments[0][0]
    var max_p: Vector2 = _branch_segments[0][0]
    for seg in _branch_segments:
        min_p = min_p.min(seg[0])
        min_p = min_p.min(seg[1])
        max_p = max_p.max(seg[0])
        max_p = max_p.max(seg[1])
    var padding: Vector2 = clip_panel.size
    branch_layer.position = min_p - padding
    branch_layer.size = (max_p - min_p) + padding * 2.0




func _gui_input(event: InputEvent) -> void :
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                _is_dragging = true
                _drag_start_mouse = event.position
                _drag_start_canvas = canvas.position
            else:
                _is_dragging = false
    elif event is InputEventMouseMotion and _is_dragging:
        var delta: Vector2 = event.position - _drag_start_mouse
        canvas.position = _drag_start_canvas + delta




func _on_detail_card_clicked(node: PassiveTreeNode, choice_index: int, immediate: bool) -> void :
    if node == null:
        return

    passive_unhovered.emit()

    _selected_pending_node = node
    _selected_choice_index = choice_index




    if immediate:
        confirm_selection()
        return


    for card in _detail_cards:
        if not is_instance_valid(card):
            continue
        card.set_selected(card.choice_index == choice_index and card.tree_node == node)

    var passive_def: PassiveDefinition = PassiveLibrary.get_passive_by_id(node.generated_choice_ids[choice_index])
    choice_selected.emit(passive_def)




func confirm_selection() -> PassiveDefinition:
    if _selected_pending_node == null or _selected_choice_index < 0:
        return null
    var node: PassiveTreeNode = _selected_pending_node
    var idx: int = _selected_choice_index
    var passive_def: PassiveDefinition = PassiveLibrary.get_passive_by_id(node.generated_choice_ids[idx])

    var success: bool = exile.choose_passive_at_node(node, idx)
    if not success:
        return null




    _focus_after_relayout = node

    _selected_pending_node = null
    _selected_choice_index = -1
    GameState.exile_updated.emit(exile)
    choice_committed.emit(passive_def)
    return passive_def




func cancel_selection() -> void :
    _selected_pending_node = null
    _selected_choice_index = -1
    for card in _detail_cards:
        if is_instance_valid(card):
            card.set_selected(false)
    choice_deselected.emit()


func has_selection() -> bool:
    return _selected_choice_index >= 0




func _on_exile_updated(updated_exile: ExileData) -> void :
    if updated_exile != exile:
        return
    _relayout()


func _on_widget_hovered(passive_def: PassiveDefinition, global_pos: Vector2, is_initiator: bool) -> void :
    passive_hovered.emit(passive_def, global_pos, is_initiator)


func _on_widget_unhovered() -> void :
    passive_unhovered.emit()




func _on_jump_top_pressed() -> void :

    _pan_canvas_to_point(ORIGIN_ANCHOR_POS, true)


func _on_jump_current_pressed() -> void :

    _focus_on_current(true)


func _on_jump_bottom_pressed() -> void :


    if _level_y_by_level.is_empty():
        return
    var deepest_level: int = -1
    var deepest_y: float = 0.0
    for lvl in _level_y_by_level.keys():
        var lvl_int: int = int(lvl)
        if lvl_int > deepest_level:
            deepest_level = lvl_int
            deepest_y = float(_level_y_by_level[lvl])
    _pan_canvas_to_y(deepest_y, true)









func _pan_canvas_to_point(target: Vector2, animated: bool) -> void :
    var target_pos: Vector2 = clip_panel.size * 0.5 - target
    if _pan_tween != null and _pan_tween.is_valid():
        _pan_tween.kill()
    if not animated:
        canvas.position = target_pos
        return
    _pan_tween = create_tween()
    _pan_tween.set_trans(Tween.TRANS_QUART)
    _pan_tween.set_ease(Tween.EASE_OUT)
    _pan_tween.tween_property(canvas, "position", target_pos, PAN_ANIM_DURATION)





func _pan_canvas_to_y(target_y: float, animated: bool) -> void :


    _pan_canvas_to_point(Vector2(_get_active_x_at_y(target_y), target_y), animated)





func _get_active_x_at_y(target_y: float) -> float:
    for node in _chosen_positions:
        var pos: Vector2 = _chosen_positions[node]
        if absf(pos.y - target_y) < 1.0:
            return pos.x
    for node in _pending_positions:
        var centers: Array = _pending_positions[node]
        if centers.size() > 0 and absf(centers[0].y - target_y) < 1.0:

            return centers[centers.size() / 2].x
    return 0.0






func _focus_on_current(animated: bool = false) -> void :
    if exile == null:
        return
    var focus_node: PassiveTreeNode = _find_pending_or_leaf()
    if focus_node == null:
        _pan_canvas_to_point(ORIGIN_ANCHOR_POS, animated)
        return



    var target: Vector2
    if _chosen_positions.has(focus_node):
        target = _chosen_positions[focus_node]
    elif _pending_positions.has(focus_node):
        var centers: Array = _pending_positions[focus_node]

        target = centers[centers.size() / 2] if centers.size() > 0 else Vector2.ZERO
    else:
        var y_variant = _level_y_by_level.get(focus_node.level, 0.0)
        target = Vector2(0, float(y_variant))
    _pan_canvas_to_point(target, animated)


func _find_pending_or_leaf() -> PassiveTreeNode:
    var node: PassiveTreeNode = exile.passive_tree_root
    if node == null:
        return null
    while node != null:
        if node.is_pending():
            return node
        var next: PassiveTreeNode = node.get_next_in_path()
        if next == null:
            return node
        node = next
    return null








func _on_unallocated_widget_clicked(node: PassiveTreeNode, choice_index: int) -> void :
    if node == null:
        return
    passive_unhovered.emit()
    var picked_def: PassiveDefinition = PassiveLibrary.get_passive_by_id(node.generated_choice_ids[choice_index])
    if exile.choose_passive_at_node(node, choice_index):
        _focus_after_relayout = node
        GameState.exile_updated.emit(exile)
        choice_committed.emit(picked_def)














func _on_respec_pressed() -> void :
    if exile == null:
        return




    var node: PassiveTreeNode = exile.passive_tree_root
    var deepest_resolved: PassiveTreeNode = null
    while node != null:
        if not node.is_pending():
            deepest_resolved = node
        var next: PassiveTreeNode = node.get_next_in_path()
        if next == null:
            break
        node = next
    if deepest_resolved == null:
        return
    if exile.respec_passive_at_node(deepest_resolved):


        cancel_selection()
        GameState.exile_updated.emit(exile)
