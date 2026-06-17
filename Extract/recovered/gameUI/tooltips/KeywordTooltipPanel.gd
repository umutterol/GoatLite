class_name KeywordTooltipPanel
extends PanelContainer






const KEYWORD_COLOR: = "#9ecbff"

signal keyword_hovered(key: String, anchor_rect: Rect2)
signal keyword_unhovered
signal keyword_clicked(key: String, anchor_rect: Rect2)
signal close_requested(panel: KeywordTooltipPanel)




@export_node_path("RichTextLabel") var content_label_path: NodePath = ^"Margins/VBox/Content"
@export_node_path("RichTextLabel") var pin_hint_path: NodePath = ^"PinHint"
@export_node_path("Button") var close_button_path: NodePath = ^"CloseButton"
@export_node_path("Control") var drag_handle_path: NodePath = ^"."

@onready var content_label: RichTextLabel = get_node_or_null(content_label_path)
@onready var pin_hint: RichTextLabel = get_node_or_null(pin_hint_path)
@onready var close_button: Button = get_node_or_null(close_button_path)
@onready var drag_handle: Control = get_node_or_null(drag_handle_path)

var _current_key: String = ""
var _pinned: bool = false


func _ready() -> void :
    mouse_filter = Control.MOUSE_FILTER_STOP

    if content_label:
        content_label.bbcode_enabled = true
        content_label.fit_content = true
        content_label.meta_hover_started.connect(_on_meta_hover_started)
        content_label.meta_hover_ended.connect(_on_meta_hover_ended)
        content_label.meta_clicked.connect(_on_meta_clicked)
    else:
        push_warning("KeywordTooltipPanel: content_label not assigned.")

    if close_button:
        close_button.pressed.connect(_on_close_pressed)
        close_button.visible = false


func populate(key: String) -> void :
    _current_key = key
    if content_label == null:
        return
    var lines: = TooltipDefinitions.get_tooltip(key)
    var processed: Array[String] = []
    for line in lines:
        processed.append(_linkify(line))
    content_label.text = "\n\n".join(processed)




func set_pinned(value: bool) -> void :
    _pinned = value
    if pin_hint:
        pin_hint.visible = not value
    if close_button:
        close_button.visible = value


func is_pinned() -> bool:
    return _pinned


func get_drag_handle() -> Control:
    return drag_handle




func _linkify(text: String) -> String:
    var regex: = RegEx.new()
    regex.compile("\\{([a-z_][a-z0-9_]*)\\}")
    var matches: = regex.search_all(text)
    if matches.is_empty():
        return text


    var result: = text
    for i in range(matches.size() - 1, -1, -1):
        var m: = matches[i]
        var key: = m.get_string(1)
        var display: = _humanize(key)
        var replacement: = "[url=%s][color=%s]%s[/color][/url]" % [key, KEYWORD_COLOR, display]
        result = result.substr(0, m.get_start()) + replacement + result.substr(m.get_end())
    return result


func _humanize(key: String) -> String:



    return key.replace("_", " ").capitalize()


func _on_meta_hover_started(meta: Variant) -> void :
    var key: = str(meta)
    if key.is_empty():
        return


    var mouse: = get_viewport().get_mouse_position()
    keyword_hovered.emit(key, Rect2(mouse, Vector2(1, 1)))


func _on_meta_hover_ended(_meta: Variant) -> void :
    keyword_unhovered.emit()


func _on_meta_clicked(meta: Variant) -> void :
    var key: = str(meta)
    if key.is_empty():
        return


    set_meta("_suppress_drag_click", true)
    var mouse: = get_viewport().get_mouse_position()
    keyword_clicked.emit(key, Rect2(mouse, Vector2(1, 1)))


func _on_close_pressed() -> void :
    close_requested.emit(self)
