extends Control

# Warna tombol (atur di Inspector kalau mau)
@export var active_color := Color(1, 1, 1, 1)
@export var inactive_color := Color(1, 1, 1, 0.65)
@export var glow_offset_y := 0.0

var active_page: String = ""
var nav_buttons: Dictionary = {}

@onready var glow: Control = find_child("ActiveGlow", true, false)


func _ready() -> void:
	active_page = Game.current_page

	nav_buttons = {
		"home": find_child("HomeButton", true, false),
		"profile": find_child("ProfileButton", true, false),
		"shop": find_child("ShopButton", true, false),
		"news": find_child("NewsButton", true, false),
		"settings": find_child("SettingsButton", true, false),
	}

	for page in nav_buttons:
		var button: TextureButton = nav_buttons[page]
		if button == null:
			push_warning("Tombol untuk '%s' tidak ditemukan di Sidebar." % page)
			continue
		button.pressed.connect(_on_nav_pressed.bind(page))
		button.modulate = active_color if page == active_page else inactive_color

	var exit_button: TextureButton = find_child("ExitButton", true, false)
	if exit_button:
		exit_button.pressed.connect(_on_exit_pressed)

	# Tunggu 1 frame supaya posisi tombol sudah final, lalu taruh cahayanya
	await get_tree().process_frame
	await get_tree().process_frame
	_place_glow()

func _glow_y_for(button: Control) -> float:
	var glow_height := glow.size.y * glow.scale.y
	return _center_y(button) - glow_height * 0.5 + glow_offset_y

func _place_glow() -> void:
	if glow == null:
		return

	var button := nav_buttons.get(active_page) as Control
	if button == null:
		glow.visible = false
		return

	var target_y := _glow_y_for(button)
	glow.visible = true

	var previous := nav_buttons.get(Game.previous_page) as Control
	if previous != null and previous != button:
		glow.global_position.y = _glow_y_for(previous)
		create_tween().tween_property(glow, "global_position:y", target_y, 0.25) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		glow.global_position.y = target_y
		glow.modulate.a = 0.0
		create_tween().tween_property(glow, "modulate:a", 1.0, 0.3)


func _center_y(control: Control) -> float:
	return control.global_position.y + control.size.y * 0.5


func _on_nav_pressed(page: String) -> void:
	if page == active_page:
		return
	if Game.username.is_empty():
		return
	Game.go_to(page)


func _on_exit_pressed() -> void:
	Game.reset_session()
	Game.go_to("login")
