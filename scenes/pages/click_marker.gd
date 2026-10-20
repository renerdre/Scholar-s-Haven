extends Node2D

const HOLD_TIME := 0.4  
const FADE_TIME := 0.6  

var tween: Tween


func _ready() -> void:
	modulate.a = 0.0


func show_at(world_position: Vector2) -> void:
	global_position = world_position

	if tween:
		tween.kill()

	modulate.a = 1.0
	scale = Vector2.ONE

	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, FADE_TIME).set_delay(HOLD_TIME)
	tween.tween_property(self, "scale", Vector2(0.6, 0.6), FADE_TIME).set_delay(HOLD_TIME)


func _draw() -> void:
	var gold := Color("#E8C15A")

	# ellipse
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
	draw_arc(Vector2.ZERO, 12.0, 0.0, TAU, 32, gold, 1.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Arrow
	draw_line(Vector2(0, -26), Vector2(0, 0), gold, 1.5)
	draw_line(Vector2(0, 0), Vector2(-3, -5), gold, 1.5)
	draw_line(Vector2(0, 0), Vector2(3, -5), gold, 1.5)
