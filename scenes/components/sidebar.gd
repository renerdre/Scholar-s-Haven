extends Control

# Halaman mana yang sedang aktif (diatur di Inspector tiap halaman)
@export_enum("home", "profile", "shop", "news", "settings") var active_page: String = "home"

var nav_buttons: Dictionary = {}


func _ready() -> void:
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
		# Tombol halaman aktif terang penuh, yang lain sedikit redup
		button.modulate = Color(1, 1, 1, 1) if page == active_page else Color(1, 1, 1, 0.65)

	var exit_button: TextureButton = find_child("ExitButton", true, false)
	if exit_button:
		exit_button.pressed.connect(_on_exit_pressed)


func _on_nav_pressed(page: String) -> void:
	if page == active_page:
		return # sudah di halaman ini
	Game.go_to(page)


func _on_exit_pressed() -> void:
	# Di web, quit() tidak menutup tab browser, jadi Exit = kembali ke login
	Game.email = ""
	Game.username = ""
	Game.go_to("login")
