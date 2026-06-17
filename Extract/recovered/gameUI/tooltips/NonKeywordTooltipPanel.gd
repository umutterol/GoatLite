class_name NonKeywordTooltipPanel
extends PanelContainer


















const SCREEN_PADDING: float = 8.0
const ANCHOR_OFFSET: Vector2 = Vector2(16, 12)



@export var max_content_width: float = 380.0

@onready var body: RichTextLabel = %Body




func show_breakdown(bbcode: String, screen_pos: Vector2) -> void :
    body.text = bbcode



    body.autowrap_mode = TextServer.AUTOWRAP_OFF
    body.custom_minimum_size = Vector2.ZERO
    visible = true


    await get_tree().process_frame
    if not is_inside_tree():
        return

    var natural_w: float = body.get_content_width()
    if natural_w > max_content_width:

        body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        body.custom_minimum_size = Vector2(max_content_width, 0)
        await get_tree().process_frame
        if not is_inside_tree():
            return



    reset_size()
    await get_tree().process_frame
    if not is_inside_tree():
        return

    _place_at(screen_pos)


func hide_tooltip() -> void :
    visible = false


func _place_at(screen_pos: Vector2) -> void :
    var vp_size: Vector2 = get_viewport().get_visible_rect().size
    var sz: Vector2 = size
    var pos: Vector2 = screen_pos + ANCHOR_OFFSET
    if pos.x + sz.x > vp_size.x - SCREEN_PADDING:
        pos.x = screen_pos.x - sz.x - ANCHOR_OFFSET.x
    if pos.y + sz.y > vp_size.y - SCREEN_PADDING:
        pos.y = screen_pos.y - sz.y - ANCHOR_OFFSET.y
    pos.x = clampf(pos.x, SCREEN_PADDING, max(SCREEN_PADDING, vp_size.x - sz.x - SCREEN_PADDING))



    pos.y = minf(pos.y, vp_size.y - sz.y - SCREEN_PADDING)
    if sz.y + SCREEN_PADDING * 2.0 <= vp_size.y:
        pos.y = maxf(pos.y, SCREEN_PADDING)
    global_position = pos
