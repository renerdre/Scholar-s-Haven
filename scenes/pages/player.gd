extends CharacterBody2D

const SPEED := 120.0
const STOP_DISTANCE := 4.0 # distance (px) counted as "arrived"

var target_position: Vector2
var is_moving := false

@onready var sprite: Sprite2D = $Sprite
@onready var marker: Node2D = get_node_or_null("../ClickMarker")


func _ready() -> void:
	target_position = global_position


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
			and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		target_position = get_global_mouse_position()
		is_moving = true
		if marker:
			marker.show_at(target_position)


func _physics_process(_delta: float) -> void:
	if not is_moving:
		return

	var to_target := target_position - global_position
	if to_target.length() <= STOP_DISTANCE:
		is_moving = false
		velocity = Vector2.ZERO
		return

	velocity = to_target.normalized() * SPEED
	move_and_slide()

	if absf(velocity.x) > 1.0:
		sprite.flip_h = velocity.x < 0.0
