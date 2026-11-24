extends Node

signal status_changed(new_status: String)
signal coins_changed(new_amount: int)

var owned_items: Array = []

var coins: int = 150:
	set(value):
		coins = value
		coins_changed.emit(coins)
var username: String = ""
var email: String = ""

var player_status: String = "Idle"
var current_room_name: String = "Late Night Studies"
var current_room: Dictionary = {}
var previous_page: String = ""

var profile: Dictionary = {}

const DEFAULT_AVATAR := {
	"gender": "male", "hat": "", "shirt": "peasant_tunic",
	"pants": "peasant_trousers", "accessory": "",
}
var avatar: Dictionary = DEFAULT_AVATAR.duplicate()


const SCENES := {
	"title": "res://scenes/pages/title.tscn",
	"login": "res://scenes/pages/login.tscn",
	"signup": "res://scenes/pages/signup.tscn",
	"home": "res://scenes/pages/home.tscn",
	"profile": "res://scenes/pages/profile.tscn",
	"shop": "res://scenes/pages/shop.tscn",
	"news": "res://scenes/pages/news.tscn",
	"settings": "res://scenes/pages/settings.tscn",
	"topup": "res://scenes/pages/topup.tscn",
	"ingame": "res://scenes/pages/ingame.tscn",
}
const LOADING_SCREEN := "res://scenes/pages/LoadingScreen.tscn"
var current_page: String = "title"
var target_scene_path: String = ""


func _needs_loading(from_page: String, to_page: String) -> bool:
	return to_page == "ingame" \
		or from_page == "ingame" \
		or (from_page == "title" and to_page == "login") \
		or (from_page == "login" and to_page == "home") \
		or (from_page == "signup" and to_page == "home")
		

func login_as(account: Dictionary) -> void:
	email = account["email"]
	username = account["username"]
	coins = int(account["coins"])   # JSON menyimpan angka sebagai float
	profile = account.get("profile", {}).duplicate()
	owned_items = account.get("owned_items", []).duplicate()
	avatar = DEFAULT_AVATAR.duplicate()
	avatar.merge(account.get("avatar", {}), true)
	avatar.merge(account.get("avatar", {}), true)
	avatar = ItemDB.sanitize_avatar(avatar, DEFAULT_AVATAR)   # <-- baru
	go_to("home")
	

func go_to(page: String) -> void:
	if not SCENES.has(page):
		push_warning("Halaman tidak ditemukan: " + page)
		return
	if not ResourceLoader.exists(SCENES[page]):
		push_warning("Scene belum dibuat: " + SCENES[page])
		return

	var from_page := current_page
	previous_page = from_page
	current_page = page

	if page == "ingame":
		Music.stop()
	else:
		Music.resume()

	if _needs_loading(from_page, page):
		target_scene_path = SCENES[page]
		get_tree().change_scene_to_file(LOADING_SCREEN)
	else:
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
	
func reset_session() -> void:
	email = ""
	username = ""
	profile = {}
	avatar = DEFAULT_AVATAR.duplicate()
	coins = 0
	owned_items = []

func owns(item_id: String) -> bool:
	if item_id in owned_items:
		return true
	return ItemDB.get_item(item_id).get("rarity", "") == "Common"
