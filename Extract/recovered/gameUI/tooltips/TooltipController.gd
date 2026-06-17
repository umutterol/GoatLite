extends Node








const KEYWORD_PANEL: = preload("res://gameUI/tooltips/KeywordTooltipPanel.tscn")
const CANVAS_LAYER: = 200
const SHOW_DELAY: = 0.35
const NESTED_DELAY: = 0.1
const HIDE_DELAY: = 0.08
const GAP: = 8


const META_HIDE_TIMER: = "tt_hide_timer"
const META_SOURCE_KEY: = "tt_source_key"
const META_SOURCE_PARENT: = "tt_source_parent"
const META_SOURCE_ANCHOR: = "tt_source_anchor"





static func _meta_or(obj: Object, key: String, fallback: Variant) -> Variant:
    if not is_instance_valid(obj):
        return fallback
    return obj.get_meta(key) if obj.has_meta(key) else fallback

var _canvas: CanvasLayer
var _show_timer: Timer

var _floating: Array[KeywordTooltipPanel] = []
var _pinned: Array[KeywordTooltipPanel] = []


var _pending_key: String = ""
var _pending_anchor_rect: Rect2
var _pending_parent: KeywordTooltipPanel = null
var _pending_anchor_node: Control = null


func _ready() -> void :
    _canvas = CanvasLayer.new()
    _canvas.name = "TooltipLayer"
    _canvas.layer = CANVAS_LAYER
    add_child(_canvas)

    _show_timer = Timer.new()
    _show_timer.one_shot = true
    _show_timer.timeout.connect(_on_show_timeout)
    add_child(_show_timer)




    SceneRouter.scene_about_to_change.connect(close_all_floating)






func _input(event: InputEvent) -> void :
    if not (event is InputEventKey and event.pressed and not event.echo):
        return



    if event.physical_keycode == KEY_T and not _floating.is_empty():
        _pin_all_floating()
        get_viewport().set_input_as_handled()
        return

    if event.physical_keycode == KEY_ESCAPE and ( not _floating.is_empty() or not _pinned.is_empty()):
        close_all_floating()
        close_all_pinned()
        get_viewport().set_input_as_handled()




func request_show(key: String, anchor_rect: Rect2, anchor: Control = null) -> void :
    if key.is_empty():
        return

    if anchor != null:
        var existing: = _find_panel_by_anchor(anchor)
        if existing:
            _cancel_hide_chain(existing)
            return
    _pending_key = key
    _pending_anchor_rect = anchor_rect
    _pending_parent = null
    _pending_anchor_node = anchor
    _show_timer.start(SHOW_DELAY)


func notify_anchor_entered(anchor: Control) -> void :
    var panel: = _find_panel_by_anchor(anchor)
    if panel:
        _cancel_hide_chain(panel)


func notify_anchor_exited(anchor: Control) -> void :
    _show_timer.stop()
    _pending_key = ""
    var panel: = _find_panel_by_anchor(anchor)
    if panel:
        _start_panel_hide(panel)


func close_all_floating() -> void :
    while not _floating.is_empty():
        _close_floating_at(_floating.size() - 1)


func close_all_pinned() -> void :

    for panel in _pinned.duplicate():
        _on_pinned_close(panel)



func _pin_all_floating() -> void :

    for panel in _floating.duplicate():
        _on_pin_requested(panel)




func _on_show_timeout() -> void :
    if _pending_key.is_empty():
        return
    _spawn(_pending_key, _pending_anchor_rect, _pending_parent, _pending_anchor_node)
    _pending_key = ""


func _spawn(key: String, anchor_rect: Rect2, parent: KeywordTooltipPanel, anchor: Control) -> void :
    if parent == null:

        close_all_floating()
    else:

        var parent_index: = _floating.find(parent)
        if parent_index >= 0:
            for i in range(_floating.size() - 1, parent_index, -1):
                _close_floating_at(i)

    var panel: KeywordTooltipPanel = KEYWORD_PANEL.instantiate()
    panel.visible = false
    _canvas.add_child(panel)
    panel.populate(key)


    var hide_timer: = Timer.new()
    hide_timer.one_shot = true
    hide_timer.wait_time = HIDE_DELAY
    hide_timer.timeout.connect(_on_panel_hide_timeout.bind(panel))
    panel.add_child(hide_timer)

    panel.set_meta(META_HIDE_TIMER, hide_timer)
    panel.set_meta(META_SOURCE_KEY, key)
    panel.set_meta(META_SOURCE_PARENT, parent)
    panel.set_meta(META_SOURCE_ANCHOR, anchor)




    panel.keyword_hovered.connect(_on_nested_keyword_hovered.bind(panel))
    panel.keyword_unhovered.connect(_on_nested_keyword_unhovered.bind(panel))
    panel.keyword_clicked.connect(_on_nested_keyword_clicked.bind(panel))

    _floating.append(panel)



    await get_tree().process_frame
    await get_tree().process_frame
    if not is_instance_valid(panel):
        return
    _position(panel, anchor_rect)
    panel.visible = true


func _position(panel: Control, anchor_rect: Rect2) -> void :
    var vp_size: = get_viewport().get_visible_rect().size
    var sz: = panel.size


    var pos: = Vector2(anchor_rect.position.x + anchor_rect.size.x + GAP, anchor_rect.position.y)
    if pos.x + sz.x > vp_size.x:
        pos.x = anchor_rect.position.x - sz.x - GAP
    if pos.x < 0:
        pos.x = anchor_rect.position.x
        pos.y = anchor_rect.position.y + anchor_rect.size.y + GAP

    pos.x = clampf(pos.x, 0.0, max(0.0, vp_size.x - sz.x))




    pos.y = minf(pos.y, vp_size.y - sz.y)
    if sz.y <= vp_size.y:
        pos.y = maxf(pos.y, 0.0)
    panel.global_position = pos




func _on_nested_keyword_hovered(key: String, anchor_rect: Rect2, parent: KeywordTooltipPanel) -> void :
    if key.is_empty():
        return

    var existing: = _find_child_panel(parent, key)
    if existing:
        _cancel_hide_chain(existing)
        return
    _pending_key = key
    _pending_anchor_rect = anchor_rect
    _pending_parent = parent
    _pending_anchor_node = null
    _show_timer.start(NESTED_DELAY)


func _on_nested_keyword_unhovered(parent: KeywordTooltipPanel) -> void :
    _show_timer.stop()
    _pending_key = ""


    for panel in _floating:
        if _meta_or(panel, META_SOURCE_PARENT, null) == parent:
            _start_panel_hide(panel)


func _on_nested_keyword_clicked(key: String, anchor_rect: Rect2, parent: KeywordTooltipPanel) -> void :

    var target: = _find_child_panel(parent, key)
    if target == null:
        _show_timer.stop()
        _pending_key = ""
        _spawn(key, anchor_rect, parent, null)
        target = _find_child_panel(parent, key)
    if target:
        _on_pin_requested(target)




func _start_panel_hide(panel: KeywordTooltipPanel) -> void :
    if not is_instance_valid(panel):
        return
    var timer: = _meta_or(panel, META_HIDE_TIMER, null) as Timer
    if timer:
        timer.start(HIDE_DELAY)


func _stop_hide_timer(panel: KeywordTooltipPanel) -> void :
    if not is_instance_valid(panel):
        return
    var timer: = _meta_or(panel, META_HIDE_TIMER, null) as Timer
    if timer:
        timer.stop()




func _cancel_hide_chain(panel: KeywordTooltipPanel) -> void :
    var idx: = _floating.find(panel)
    if idx < 0:
        return
    for i in range(idx + 1):
        _stop_hide_timer(_floating[i])


func _on_panel_hide_timeout(panel: KeywordTooltipPanel) -> void :
    var idx: = _floating.find(panel)
    if idx < 0:
        return

    for i in range(_floating.size() - 1, idx - 1, -1):
        _close_floating_at(i)




func _find_child_panel(parent: KeywordTooltipPanel, key: String) -> KeywordTooltipPanel:
    for panel in _floating:
        if _meta_or(panel, META_SOURCE_PARENT, null) == parent and _meta_or(panel, META_SOURCE_KEY, "") == key:
            return panel
    return null


func _find_panel_by_anchor(anchor: Control) -> KeywordTooltipPanel:
    for panel in _floating:
        if _meta_or(panel, META_SOURCE_ANCHOR, null) == anchor:
            return panel
    return null


func _close_floating_at(index: int) -> void :
    if index < 0 or index >= _floating.size():
        return
    var panel: = _floating[index]
    _floating.remove_at(index)
    if is_instance_valid(panel):
        panel.queue_free()




func _on_pin_requested(panel: KeywordTooltipPanel) -> void :
    var idx: = _floating.find(panel)
    if idx < 0:
        return

    for i in range(_floating.size() - 1, idx, -1):
        _close_floating_at(i)
    _floating.erase(panel)
    _promote_to_pinned(panel)


func _promote_to_pinned(panel: KeywordTooltipPanel) -> void :
    panel.set_pinned(true)
    panel.close_requested.connect(_on_pinned_close)

    var timer: = _meta_or(panel, META_HIDE_TIMER, null) as Timer
    if timer:
        timer.stop()
        timer.queue_free()
    if panel.has_meta(META_HIDE_TIMER):
        panel.remove_meta(META_HIDE_TIMER)
    _attach_drag(panel)
    _pinned.append(panel)


func _on_pinned_close(panel: KeywordTooltipPanel) -> void :
    _pinned.erase(panel)
    if is_instance_valid(panel):
        panel.queue_free()


func _attach_drag(panel: KeywordTooltipPanel) -> void :
    var handle: = panel.get_drag_handle()
    if handle == null:
        return


    const DRAG_EDGE_KEEP_IN_VIEW: = 32.0
    var state: = {"dragging": false, "offset": Vector2.ZERO}
    handle.gui_input.connect( func(event: InputEvent) -> void :
        if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:

                if panel.has_meta("_suppress_drag_click"):
                    panel.remove_meta("_suppress_drag_click")
                    return
                state["dragging"] = true
                state["offset"] = panel.global_position - panel.get_global_mouse_position()
            else:
                state["dragging"] = false
        elif event is InputEventMouseMotion and state["dragging"]:
            var raw: Vector2 = panel.get_global_mouse_position() + state["offset"]
            var vp: Vector2 = get_viewport().get_visible_rect().size
            raw.x = clampf(raw.x, DRAG_EDGE_KEEP_IN_VIEW - panel.size.x, vp.x - DRAG_EDGE_KEEP_IN_VIEW)
            raw.y = clampf(raw.y, 0.0, vp.y - DRAG_EDGE_KEEP_IN_VIEW)
            panel.global_position = raw
    )
