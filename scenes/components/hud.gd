extends CanvasLayer

@export var study_icon: Texture2D
@export var rest_icon: Texture2D
@export var mic_on_icon: Texture2D
@export var mic_off_icon: Texture2D

const STUDY_SECONDS := 25 * 60
const REST_SECONDS := 5 * 60

enum State { IDLE, STUDYING, RESTING }
var state: State = State.IDLE
var phase_end_ms: int = 0
var mic_on: bool = true

var other_players := [
	{"name": "Kiruue", "status": "Studying"},
	{"name": "Lemonilo", "status": "Resting"},
]

@onready var player_rows: VBoxContainer = find_child("PlayerRows", true, false)
@onready var room_name_label: Label = find_child("RoomNameLabel", true, false)
@onready var timer_label: Label = find_child("TimerLabel", true, false)
@onready var status_label: Label = find_child("StatusLabel", true, false)
@onready var mic_button: TextureButton = find_child("MicButton", true, false)
@onready var study_button: TextureButton = find_child("StudyButton", true, false)
@onready var leave_button: TextureButton = find_child("LeaveButton", true, false)
@onready var chat_log: RichTextLabel = find_child("ChatLog", true, false)
@onready var chat_input: LineEdit = find_child("ChatInput", true, false)


func _ready() -> void:
	room_name_label.text = Game.current_room_name
	status_label.text = Game.player_status
	_update_timer_label()
	_refresh_player_list()

	mic_button.pressed.connect(_on_mic_pressed)
	study_button.pressed.connect(_on_study_pressed)
	leave_button.pressed.connect(_on_leave_pressed)
	Game.status_changed.connect(func(_s): _refresh_player_list())

	chat_log.bbcode_enabled = true
	chat_log.scroll_following = true
	chat_input.text_submitted.connect(_on_chat_submitted)
	_add_chat_line("Kiruue", "wkwkwkkw")
	_add_chat_line("Lemonilo", "kok gitu")


func _process(_delta: float) -> void:
	if state == State.IDLE:
		return

	if Time.get_ticks_msec() >= phase_end_ms:
		_start_phase(State.RESTING if state == State.STUDYING else State.STUDYING)
	_update_timer_label()


# ---------- Study / Rest ----------

func _on_study_pressed() -> void:
	if state == State.STUDYING:
		_start_phase(State.RESTING)
	else:
		_start_phase(State.STUDYING) 


func _start_phase(new_state: State) -> void:
	state = new_state
	var seconds := STUDY_SECONDS if new_state == State.STUDYING else REST_SECONDS
	phase_end_ms = Time.get_ticks_msec() + seconds * 1000

	var status := "Studying" if new_state == State.STUDYING else "Resting"
	status_label.text = status
	Game.set_player_status(status)

	if study_icon and rest_icon:
		study_button.texture_normal = rest_icon if new_state == State.RESTING else study_icon
	_update_timer_label()


func _update_timer_label() -> void:
	var seconds_left := STUDY_SECONDS
	if state != State.IDLE:
		seconds_left = maxi(0, ceili((phase_end_ms - Time.get_ticks_msec()) / 1000.0))
	timer_label.text = Game.format_time(seconds_left)


# ---------- Mic / Leave ----------

func _on_mic_pressed() -> void:
	mic_on = not mic_on
	if mic_on_icon and mic_off_icon:
		mic_button.texture_normal = mic_on_icon if mic_on else mic_off_icon
	mic_button.modulate = Color.WHITE if mic_on else Color(1, 1, 1, 0.5)
	# TODO: real voice chat later


func _on_leave_pressed() -> void:
	Game.set_player_status("Idle")
	Game.go_to("home")


# ---------- Player list ----------

func _refresh_player_list() -> void:
	for child in player_rows.get_children():
		player_rows.remove_child(child)
		child.queue_free()

	_add_player_row("You", Game.player_status)
	for p in other_players:
		_add_player_row("%s (%s)" % [p["name"], p["status"]], p["status"])


func _add_player_row(text: String, status: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	var dot := ColorRect.new()
	dot.custom_minimum_size = Vector2(8, 8)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dot.color = _status_color(status)
	row.add_child(dot)

	var label := Label.new()
	label.text = text
	row.add_child(label)

	player_rows.add_child(row)


func _status_color(status: String) -> Color:
	match status:
		"Studying": return Color("#4CD137")
		"Resting": return Color("#E8891A")
		_: return Color("#9A9A9A")


# ---------- Chat ----------

func _on_chat_submitted(text: String) -> void:
	var message := text.strip_edges()
	chat_input.clear()
	chat_input.release_focus()
	if message.is_empty():
		return
	var sender := Game.username if Game.username != "" else "You"
	_add_chat_line(sender, message)
	# TODO: send over WebSocket later


func _add_chat_line(sender: String, message: String) -> void:

	var safe_sender := sender.replace("[", "[lb]")
	var safe_message := message.replace("[", "[lb]")
	chat_log.append_text("[color=#F0B840]%s:[/color] %s\n" % [safe_sender, safe_message])


func _unhandled_input(event: InputEvent) -> void:

	if event is InputEventMouseButton and event.pressed and chat_input.has_focus():
		chat_input.release_focus()

	elif event is InputEventKey and event.pressed and not event.echo \
			and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER) \
			and not chat_input.has_focus():
		chat_input.grab_focus()
		get_viewport().set_input_as_handled()
