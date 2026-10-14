extends Node

var coins: int = 150
var username: String = ""
var email: String = ""


const SCENES := {
	"login": "res://scenes/pages/login.tscn",
	"home": "res://scenes/pages/home.tscn",
	"profile": "res://scenes/pages/profile.tscn",
	"shop": "res://scenes/pages/shop.tscn",
	"news": "res://scenes/pages/news.tscn",
	"settings": "res://scenes/pages/settings.tscn",
	"topup": "res://scenes/pages/topup.tscn",
	"ingame": "res://scenes/pages/ingame.tscn",
}

func go_to(page: String) -> void:
	if not SCENES.has(page):
		push_warning("Halaman tidak ditemukan: " + page)
		return
	if not ResourceLoader.exists(SCENES[page]):
		push_warning("Scene belum dibuat: " + SCENES[page])
		return
	get_tree().change_scene_to_file(SCENES[page])
