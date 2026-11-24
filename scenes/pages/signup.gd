extends Control

@onready var email_input: LineEdit = %EmailInput
@onready var password_input: LineEdit = %PasswordInput
@onready var signup_button: BaseButton = %SignupButton
@onready var google_button: BaseButton = %SignupGoogle
@onready var goto_login_button: BaseButton = %gotoLoginpage
@onready var error_label: Label = get_node_or_null("%ErrorLabel")


func _ready() -> void:
	password_input.secret = true
	_show_error("")

	signup_button.pressed.connect(_on_signup_pressed)
	google_button.pressed.connect(_on_google_pressed)
	goto_login_button.pressed.connect(func(): Game.go_to("login"))

	email_input.text_submitted.connect(func(_t): password_input.grab_focus())
	password_input.text_submitted.connect(func(_t): _on_signup_pressed())
	email_input.grab_focus()


func _on_signup_pressed() -> void:
	var email := email_input.text.strip_edges()
	var password := password_input.text

	if email.is_empty() or password.is_empty():
		_show_error("Email and password are required fields.")
		return

	var result := AccountDB.register(email, password)
	if not result["ok"]:
		_show_error(result["error"])
		return

	# Akun baru username-nya kosong, jadi Home otomatis memunculkan popup username.
	Game.login_as(result["account"])


func _on_google_pressed() -> void:
	var result := AccountDB.google_sign_in()
	if not result["ok"]:
		_show_error(result["error"])
		return
	Game.login_as(result["account"])


func _show_error(message: String) -> void:
	if error_label:
		error_label.text = message
	elif not message.is_empty():
		print(message)
