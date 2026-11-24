extends Control

const MIN_CAPACITY := 2
const MAX_CAPACITY := 6
const DEFAULT_CAPACITY := 4

const COLOR_PRIVATE := Color("#F0B840")
const COLOR_PUBLIC := Color("#4CD137")

var capacity: int = DEFAULT_CAPACITY
var is_public := false

# Popup username wajib
@onready var username_popup: Control = find_child("usernamemandatoryPopup", true, false)
@onready var username_input: LineEdit = find_child("usernameInput", true, false)
@onready var username_save_button: BaseButton = find_child("saveusernameButton", true, false)
@onready var username_error_label: Label = find_child("UsernameErrorLabel", true, false)

# Tombol pembuka di Home
@onready var create_open_button: BaseButton = find_child("CreateRoomButton", true, false)
@onready var join_open_button: BaseButton = find_child("JoinRoomButton", true, false)

# Pop up
@onready var create_popup: Control = find_child("CreatePopup", true, false)
@onready var join_popup: Control = find_child("JoinPopup", true, false)
@onready var create_dim: Control = find_child("CreateDim", true, false)
@onready var join_dim: Control = find_child("JoinDim", true, false)

# Isi pop up Create
@onready var room_name_input: LineEdit = find_child("RoomNameInput", true, false)
@onready var description_input: LineEdit = find_child("DescriptionInput", true, false)
@onready var minus_button: BaseButton = find_child("MinusButton", true, false)
@onready var plus_button: BaseButton = find_child("PlusButton", true, false)
@onready var capacity_label: Label = find_child("CapacityLabel", true, false)
@onready var privacy_button: BaseButton = find_child("PrivacyButton", true, false)
@onready var privacy_label: Label = find_child("PrivacyLabel", true, false)
@onready var create_submit_button: BaseButton = find_child("CreateSubmitButton", true, false)

# Isi pop up Join
@onready var room_code_input: LineEdit = find_child("RoomCodeInput", true, false)
@onready var join_submit_button: BaseButton = find_child("JoinSubmitButton", true, false)

@onready var create_panel: Control = find_child("CreatePanel", true, false)
@onready var join_panel: Control = find_child("JoinPanel", true, false)


func _ready() -> void:
	create_popup.visible = false
	join_popup.visible = false

	# Buka pop up
	create_open_button.pressed.connect(_open_create_popup)
	join_open_button.pressed.connect(_open_join_popup)


	# Pop up Create
	minus_button.pressed.connect(func(): _change_capacity(-1))
	plus_button.pressed.connect(func(): _change_capacity(1))
	privacy_button.pressed.connect(_toggle_privacy)
	create_submit_button.pressed.connect(_on_create_pressed)
	room_name_input.text_submitted.connect(func(_t): description_input.grab_focus())
	description_input.text_submitted.connect(func(_t): _on_create_pressed())

	# Pop up Join
	join_submit_button.pressed.connect(_on_join_pressed)
	room_code_input.text_submitted.connect(func(_t): _on_join_pressed())
	
		# Popup username wajib
	username_popup.visible = false
	username_save_button.pressed.connect(_on_username_save_pressed)
	username_input.text_submitted.connect(func(_t): _on_username_save_pressed())
	if Game.username.is_empty():
		_open_username_popup()


func _input(event: InputEvent) -> void:
	if username_popup.visible:
		return
	var popup := _active_popup()
	if popup == null:
		return

	# Esc menutup pop up
	if event.is_action_pressed("ui_cancel"):
		popup.visible = false
		get_viewport().set_input_as_handled()
		return

	# Klik atau sentuh di luar panel menutup pop up
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		var panel: Control = create_panel if popup == create_popup else join_panel
		if not panel.get_global_rect().has_point(event.position):
			popup.visible = false
			get_viewport().set_input_as_handled()


func _active_popup() -> Control:
	if create_popup.visible:
		return create_popup
	if join_popup.visible:
		return join_popup
	return null


# ---------- Buka / tutup ----------

func _open_create_popup() -> void:
	_close_popups()
	_reset_create_form()
	create_popup.visible = true
	room_name_input.grab_focus()


func _open_join_popup() -> void:
	_close_popups()
	room_code_input.clear()
	join_popup.visible = true
	room_code_input.grab_focus()


func _close_popups() -> void:
	create_popup.visible = false
	join_popup.visible = false




# ---------- Form Create ----------

func _reset_create_form() -> void:
	room_name_input.clear()
	description_input.clear()
	capacity = DEFAULT_CAPACITY
	is_public = false
	_update_capacity()
	_update_privacy()


func _change_capacity(delta: int) -> void:
	capacity = clampi(capacity + delta, MIN_CAPACITY, MAX_CAPACITY)
	_update_capacity()


func _update_capacity() -> void:
	capacity_label.text = str(capacity)
	# Tombol redup saat sudah mentok
	minus_button.modulate.a = 0.4 if capacity <= MIN_CAPACITY else 1.0
	plus_button.modulate.a = 0.4 if capacity >= MAX_CAPACITY else 1.0


func _toggle_privacy() -> void:
	is_public = not is_public
	_update_privacy()


func _update_privacy() -> void:
	privacy_label.text = "Public" if is_public else "Private"
	privacy_label.add_theme_color_override("font_color", COLOR_PUBLIC if is_public else COLOR_PRIVATE)


# ---------- Submit (placeholder: langsung masuk in game) ----------

func _on_create_pressed() -> void:
	var room_name := room_name_input.text.strip_edges()
	if room_name.is_empty():
		room_name = "Untitled Room"

	Game.current_room_name = room_name
	Game.current_room = {
		"name": room_name,
		"description": description_input.text.strip_edges(),
		"capacity": capacity,
		"is_public": is_public,
		"host": Game.username,
	}
	Game.go_to("ingame")


func _on_join_pressed() -> void:
	# TODO backend: cek kode room ke server. Sekarang kode apa pun diterima.
	Game.current_room = {"code": room_code_input.text.strip_edges().to_upper()}
	Game.current_room_name = "Late Night Studies" # placeholder
	Game.go_to("ingame")
	

# ---------- Username wajib ----------

func _open_username_popup() -> void:
	_close_popups()
	username_input.clear()
	_show_username_error("")
	username_popup.visible = true
	username_input.grab_focus()


func _on_username_save_pressed() -> void:
	var result := AccountDB.set_username(Game.email, username_input.text)
	if not result["ok"]:
		_show_username_error(result["error"])
		return
	Game.username = result["username"]
	username_popup.visible = false


func _show_username_error(message: String) -> void:
	if username_error_label:
		username_error_label.text = message
