class_name CurrencyFlyPip
extends Control

















const TOTAL_DURATION: float = 0.55
const BURST_DURATION_RATIO: float = 0.22

const BURST_OFFSET_X_MAX: float = 28.0
const BURST_OFFSET_Y_MIN: float = -45.0
const BURST_OFFSET_Y_MAX: float = -15.0

const SPRITE_SIZE: Vector2 = Vector2(20, 20)


@onready var icon: TextureRect = $Icon







func spawn(
    start_global_pos: Vector2, 
    end_global_pos: Vector2, 
    texture: Texture2D, 
    on_arrive: Callable, 
) -> void :


    if not is_node_ready():
        await ready

    icon.texture = texture
    icon.custom_minimum_size = SPRITE_SIZE
    icon.size = SPRITE_SIZE


    icon.position = - SPRITE_SIZE * 0.5

    global_position = start_global_pos



    var burst_offset: Vector2 = Vector2(
        randf_range( - BURST_OFFSET_X_MAX, BURST_OFFSET_X_MAX), 
        randf_range(BURST_OFFSET_Y_MIN, BURST_OFFSET_Y_MAX), 
    )
    var burst_target: Vector2 = start_global_pos + burst_offset

    var burst_time: float = TOTAL_DURATION * BURST_DURATION_RATIO
    var travel_time: float = TOTAL_DURATION - burst_time

    var tween: Tween = create_tween()
    tween.set_parallel(false)

    tween.tween_property(self, "global_position", burst_target, burst_time)\
.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.tween_property(self, "global_position", end_global_pos, travel_time)\
.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
    tween.tween_callback( func() -> void :
        if on_arrive.is_valid():
            on_arrive.call()
        queue_free()
    )
