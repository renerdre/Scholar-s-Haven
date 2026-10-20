extends Control

const DUMMY_ACCOUNTS := {
	"scholar@campus.co.id": {"password": "scholar123", "username": "Scholar", "coins": 150},
	"test@test.com": {"password": "test123", "username": "Tester", "coins": 500},
}

@onready var email_input: LineEdit = %EmailInput
@onready var password_input: LineEdit = %PasswordInput
@onready var login_button: TextureButton = %LoginButton
@onready var error_label: Label = get_node_or_null("%ErrorLabel")



func _ready() -> void:
	password_input.secret = true
	_show_error("")

	login_button.pressed.connect(_on_login_pressed)
	email_input.text_submitted.connect(func(_t): password_input.grab_focus())
	password_input.text_submitted.connect(func(_t): _on_login_pressed())


	email_input.grab_focus()


func _on_login_pressed() -> void:
	var email := email_input.text.strip_edges().to_lower()
	var password := password_input.text

	if email.is_empty() or password.is_empty():
		_show_error("Email and password are required fields.")
		return

	if not DUMMY_ACCOUNTS.has(email) or DUMMY_ACCOUNTS[email]["password"] != password:
		_show_error("Email or password is wrong.")
		return

	var account: Dictionary = DUMMY_ACCOUNTS[email]
	Game.email = email
	Game.username = account["username"]
	Game.coins = account["coins"]
	Game.go_to("home")


func _show_error(message: String) -> void:
	if error_label:
		error_label.text = message
	elif not message.is_empty():
		print(message)
