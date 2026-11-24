extends Control

const PROMPT_DELAY := 2.5 # detik sampai "Click to enter" muncul

@export var title_music: AudioStream

@onready var logo: Control = _find_logo()
@onready var prompt: Label = find_child("PromptLabel", true, false)
@onready var fade: ColorRect = find_child("FadeRect", true, false)

var ready_to_enter := false
var entering := false
var blink_tween: Tween


func _find_logo() -> Control:
	var node := find_child("Logo", true, false) as Control
	if node == null:
		node = find_child("LogoCenter", true, false) as Control
	if node == null:
		push_warning("Node 'Logo' tidak ditemukan di scene Title.")
	return node


func _ready() -> void:
	prompt.text = "Click to enter"
	prompt.modulate.a = 0.0
	fade.color = Color.BLACK
	fade.modulate.a = 1.0
	if logo:
		logo.modulate.a = 0.0

	# Musik langsung dimulai dari title
	if title_music:
		Music.play(title_music)

	# Intro: layar hitam memudar, logo muncul perlahan
	var intro := create_tween().set_parallel(true)
	intro.tween_property(fade, "modulate:a", 0.0, 1.5)
	if logo:
		intro.tween_property(logo, "modulate:a", 1.0, 3.0).set_delay(0.6)

	get_tree().create_timer(PROMPT_DELAY).timeout.connect(_show_prompt)


func _show_prompt() -> void:
	ready_to_enter = true
	# Muncul perlahan, lalu berkedip lembut selamanya
	blink_tween = create_tween().set_loops()
	blink_tween.tween_property(prompt, "modulate:a", 1.0, 1.1) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	blink_tween.tween_property(prompt, "modulate:a", 0.25, 1.1) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# _input (bukan _unhandled_input) supaya klik di mana saja diterima
func _input(event: InputEvent) -> void:
	if not ready_to_enter or entering:
		return
	var clicked: bool = event is InputEventMouseButton and event.pressed
	var key_pressed: bool = event is InputEventKey and event.pressed and not event.echo
	if clicked or key_pressed:
		get_viewport().set_input_as_handled()
		_enter()


func _enter() -> void:
	entering = true
	if blink_tween:
		blink_tween.kill()
	prompt.modulate.a = 1.0

	var out := create_tween()
	out.tween_property(fade, "modulate:a", 1.0, 1.0)
	await out.finished
	Game.go_to("login")
