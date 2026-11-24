extends CharacterBody2D

const SPEED := 120.0
const STOP_DISTANCE := 4.0 # distance (px) counted as "arrived"

var target_position: Vector2
var is_moving := false
var facing_dir := "Front"
var face_left := false

@onready var visual: CharacterVisual = $Visual
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
		visual.set_motion(facing_dir, false, face_left)
		return

	var to_target := target_position - global_position
	if to_target.length() <= STOP_DISTANCE:
		is_moving = false
		velocity = Vector2.ZERO
		visual.set_motion(facing_dir, false, face_left)
		return

	velocity = to_target.normalized() * SPEED
	move_and_slide()
	_update_facing(velocity)
	visual.set_motion(facing_dir, true, face_left)


# Sumbu yang lebih dominan menentukan arah hadap
func _update_facing(v: Vector2) -> void:
	if absf(v.x) > absf(v.y):
		facing_dir = "Side"
		face_left = v.x < 0.0
	else:
		facing_dir = "Front" if v.y > 0.0 else "Back"
		face_left = false
