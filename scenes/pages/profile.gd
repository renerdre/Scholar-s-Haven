extends Control

@onready var name_input: LineEdit = find_child("NameInput", true, false)
@onready var username_input: LineEdit = find_child("UsernameInput", true, false)
@onready var country_input: LineEdit = find_child("CountryInput", true, false)
@onready var school_input: LineEdit = find_child("SchoolInput", true, false)
@onready var about_input: LineEdit = find_child("AboutInput", true, false)
@onready var save_button: BaseButton = find_child("SaveProfileButton", true, false)
@onready var customize_button: BaseButton = find_child("CustomizeAvatarButton", true, false)
@onready var wardrobe: Control = find_child("WardrobePopup", true, false)
@onready var message_label: Label = find_child("ProfileMessageLabel", true, false)
@onready var avatar_preview: AvatarPreview = find_child("ProfileAvatarPreview", true, false)

var message_tween: Tween


func _ready() -> void:
	name_input.text = Game.profile.get("name", "")
	username_input.text = Game.username
	country_input.text = Game.profile.get("country", "Indonesia")
	school_input.text = Game.profile.get("school", "")
	about_input.text = Game.profile.get("about", "")
	_show_message("", false)

	save_button.pressed.connect(_on_save_pressed)
	
	customize_button.pressed.connect(wardrobe.open)
	wardrobe.saved.connect(func(): avatar_preview.show_avatar(Game.avatar))


func _on_save_pressed() -> void:
	# 1. Username wajib dan tidak boleh kosong
	var new_username := username_input.text.strip_edges()
	if new_username.is_empty():
		username_input.text = Game.username
		_show_message("Username can't be empty.", true)
		return

	if new_username != Game.username:
		var name_result := AccountDB.set_username(Game.email, new_username)
		if not name_result["ok"]:
			_show_message(name_result["error"], true)
			return
		Game.username = name_result["username"]
		username_input.text = Game.username

	# 2. Field lain (opsional)
	var result := AccountDB.update_profile(Game.email, {
		"name": name_input.text,
		"country": country_input.text,
		"school": school_input.text,
		"about": about_input.text,
	})
	if not result["ok"]:
		_show_message(result["error"], true)
		return

	Game.profile = result["profile"]
	_show_message("Profile saved.", false)


func _show_message(text: String, is_error: bool) -> void:
	if message_label == null:
		return
	if message_tween:
		message_tween.kill()
	message_label.text = text
	message_label.modulate = Color("#E05A5A") if is_error else Color("#4CD137")
	message_label.modulate.a = 1.0
	if not text.is_empty():
		message_tween = create_tween()
		message_tween.tween_interval(2.0)
		message_tween.tween_property(message_label, "modulate:a", 0.0, 0.5)
