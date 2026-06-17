



extends Control
class_name InventoryGrid

signal item_clicked(item: Item)
signal equipped_item_dropped(item: Item)
signal item_right_clicked(item: Item)

const DRAG_SWITCH_DELAY: float = 0.5

@onready var tab_container: TabContainer = $inventoryPanel / inventoryVBox / inventoryTabs

var edit_line_edit: LineEdit = null
var editing_tab_index: int = -1
var original_tab_name: String = ""
var _drag_hover_tab: int = -1
var _drag_hover_timer: float = 0.0

func _ready() -> void :
    setup_tab_right_click()
    load_tab_names()
    await get_tree().process_frame

    for i in range(tab_container.get_tab_count()):
        var tab = tab_container.get_tab_control(i)
        if tab is StashGrid:
            tab.tab_index = i
            tab.item_tab_changed.connect(_on_item_tab_changed)
            if not tab.item_clicked.is_connected(_on_item_clicked):
                tab.item_clicked.connect(_on_item_clicked)
            if not tab.equipped_item_dropped.is_connected(_on_equipped_item_dropped):
                tab.equipped_item_dropped.connect(_on_equipped_item_dropped)
            if not tab.item_right_clicked.is_connected(_on_item_right_clicked):
                tab.item_right_clicked.connect(_on_item_right_clicked)
    _refresh_all_tabs()
    GameState.stash_changed.connect(_refresh_all_tabs)

func _process(delta: float) -> void :

    if not get_viewport().gui_is_dragging():
        _drag_hover_tab = -1
        _drag_hover_timer = 0.0
        return

    var tab_bar = tab_container.get_tab_bar()
    var mouse_pos = tab_bar.get_local_mouse_position()
    var hovered = -1
    for i in range(tab_container.get_tab_count()):
        if tab_bar.get_tab_rect(i).has_point(mouse_pos):
            hovered = i
            break

    if hovered >= 0 and hovered != tab_container.current_tab:
        if hovered == _drag_hover_tab:
            _drag_hover_timer += delta
            if _drag_hover_timer >= DRAG_SWITCH_DELAY:
                tab_container.current_tab = hovered
                _drag_hover_timer = 0.0
                _drag_hover_tab = -1
        else:
            _drag_hover_tab = hovered
            _drag_hover_timer = 0.0
    else:
        _drag_hover_tab = -1
        _drag_hover_timer = 0.0



func get_active_grid() -> StashGrid:
    var tab = tab_container.get_current_tab_control()
    if tab is StashGrid:
        return tab as StashGrid
    return null

func _get_items_for_tab(index: int) -> Array[Item]:
    var result: Array[Item] = []
    for item in GameState.get_stash_items():
        if item.stash_tab == index:
            result.append(item)
    return result

func _refresh_all_tabs() -> void :
    for i in range(tab_container.get_tab_count()):
        var tab = tab_container.get_tab_control(i)
        if tab is StashGrid:
            tab.populate(_get_items_for_tab(i))

func _on_item_tab_changed(_item: Item) -> void :
    _refresh_all_tabs()



func sort_active_tab() -> void :
    var grid: StashGrid = get_active_grid()
    if grid == null:
        return
    grid.sort_tab()

func _on_item_clicked(item: Item) -> void :
    item_clicked.emit(item)

func _on_equipped_item_dropped(item: Item) -> void :
    equipped_item_dropped.emit(item)

func _on_item_right_clicked(item: Item) -> void :
    item_right_clicked.emit(item)



func setup_tab_right_click() -> void :
    var tab_bar = tab_container.get_tab_bar()
    if tab_bar:
        tab_bar.gui_input.connect(_on_tab_bar_input)

func _on_tab_bar_input(event: InputEvent) -> void :
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
            if editing_tab_index >= 0:
                finish_editing(false)
                return
            var clicked_tab = get_tab_at_position(event.position)
            if clicked_tab >= 0:
                start_inline_editing(clicked_tab)

func get_tab_at_position(click_pos: Vector2) -> int:
    var tab_bar = tab_container.get_tab_bar()
    if not tab_bar:
        return -1
    for i in range(tab_container.get_tab_count()):
        if tab_bar.get_tab_rect(i).has_point(click_pos):
            return i
    return -1

func start_inline_editing(tab_index: int) -> void :
    if editing_tab_index >= 0:
        return
    editing_tab_index = tab_index
    original_tab_name = tab_container.get_tab_title(tab_index)
    var tab_bar = tab_container.get_tab_bar()
    var tab_rect = tab_bar.get_tab_rect(tab_index)
    edit_line_edit = LineEdit.new()
    edit_line_edit.text = original_tab_name
    edit_line_edit.max_length = 25
    edit_line_edit.select_all_on_focus = true
    edit_line_edit.position = tab_bar.position + tab_rect.position
    edit_line_edit.size = Vector2(max(tab_rect.size.x, 100), tab_rect.size.y)
    edit_line_edit.add_theme_color_override("font_color", Color.WHITE)
    edit_line_edit.text_submitted.connect(_on_edit_text_submitted)
    edit_line_edit.focus_exited.connect(_on_edit_focus_lost)
    edit_line_edit.gui_input.connect(_on_edit_input)
    add_child(edit_line_edit)
    edit_line_edit.grab_focus()
    edit_line_edit.select_all()

func _on_edit_text_submitted(_new_text: String) -> void :
    finish_editing(true)

func _on_edit_focus_lost() -> void :
    await get_tree().process_frame
    if edit_line_edit and is_instance_valid(edit_line_edit):
        finish_editing(true)

func _on_edit_input(event: InputEvent) -> void :
    if event is InputEventKey and event.pressed:
        match event.keycode:
            KEY_ESCAPE: finish_editing(false)
            KEY_ENTER, KEY_KP_ENTER: finish_editing(true)

func finish_editing(confirm: bool) -> void :
    if editing_tab_index < 0 or not edit_line_edit:
        return
    if confirm:
        var new_name = sanitize_tab_name(edit_line_edit.text)
        if new_name == "":
            new_name = original_tab_name
        tab_container.set_tab_title(editing_tab_index, new_name)
        save_tab_names()
    if edit_line_edit and is_instance_valid(edit_line_edit):
        edit_line_edit.queue_free()
    edit_line_edit = null
    editing_tab_index = -1
    original_tab_name = ""

func sanitize_tab_name(input: String) -> String:
    var clean = input.strip_edges()
    if clean == "":
        return ""
    var sanitized = ""
    for i in range(clean.length()):
        var ch = clean[i]
        var codepoint = ch.unicode_at(0)
        if codepoint < 32 and codepoint != 32:
            continue
        if ch in ["<", ">", ":", "\"", "|", "?", "*", "/", "\\"]:
            continue
        if codepoint == 0 or codepoint == 65534 or codepoint == 65535:
            continue
        sanitized += ch
    if sanitized.length() > 25:
        sanitized = sanitized.substr(0, 25)
    return sanitized.strip_edges()




func save_tab_names() -> void :
    var names: Array[String] = []
    for i in range(tab_container.get_tab_count()):
        names.append(tab_container.get_tab_title(i))
    GameState.stash_tab_names = names






func load_tab_names() -> void :
    var defaults: Array[String] = ["Dump", "Okay", "Good", "Great"]
    var saved: Array[String] = GameState.stash_tab_names
    for i in range(tab_container.get_tab_count()):
        if i < saved.size() and not saved[i].is_empty():
            tab_container.set_tab_title(i, saved[i])
        elif i < defaults.size():
            tab_container.set_tab_title(i, defaults[i])

func _input(event: InputEvent) -> void :
    if editing_tab_index >= 0:
        if event is InputEventMouseButton and event.pressed:
            if edit_line_edit and not edit_line_edit.get_global_rect().has_point(event.global_position):
                finish_editing(true)
                get_viewport().set_input_as_handled()
