extends Node

signal status_changed(new_status: String)

var coins: int = 150
var username: String = ""
var email: String = ""

var player_status: String = "Idle"
var current_room_name: String = "Late Night Studies"


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

var current_page: String = "login"

func go_to(page: String) -> void:
	if not SCENES.has(page):
		push_warning("Halaman tidak ditemukan: " + page)
		return
	if not ResourceLoader.exists(SCENES[page]):
		push_warning("Scene belum dibuat: " + SCENES[page])
		return
	current_page = page
	get_tree().change_scene_to_file(SCENES[page])
	
func set_player_status(new_status: String) -> void:
	player_status = new_status
	status_changed.emit(new_status)


func format_time(total_seconds: int, with_hours: bool = false) -> String:
	var s := total_seconds % 60
	if with_hours:
		var h := floori(total_seconds / 3600.0)
		var m := floori((total_seconds % 3600) / 60.0)
		return "%02d:%02d:%02d" % [h, m, s]
	var m_total := floori(total_seconds / 60.0)
	return "%02d:%02d" % [m_total, s]
