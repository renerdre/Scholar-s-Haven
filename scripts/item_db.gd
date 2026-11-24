extends Node

# Slot yang tidak boleh kosong: baju, celana, gender
const REQUIRED_SLOTS := ["gender", "shirt", "pants"]

const DIRECTIONS := ["Front", "Back", "Side"]
const ANIMS := ["Idle", "Walking Cycle_1", "Walking Cycle_2"]

const INGAME_ROOT := "res://assets/ui/button/avatar/ingameavatar"
const BASE_ROOT := "res://assets/ui/button/avatar/base"

# Peluang per rarity (%) untuk Outfit Chest. Sisa (100 - total) = Common, sudah dimiliki pemain.
const GACHA_RATES := {
	"Uncommon": 67.0, "Rare": 15.6, "Epic": 10.0, "Legendary": 6.8, "Mythical": 0.6,
}

# Nama folder tiap set di ingameavatar (tidak seragam, jadi dipetakan manual)
const INGAME_FOLDERS := {
	"Common1": "a. Common1", "Common2": "a. Common2", "Uncommon1": "b. Uncommon1",
	"Rare1": "c. Rare", "Epic1": "d. Epic", "Legendary1": "e. Legendary",
	"Mythical1": "f. Mythical",
}

# {label} diisi mis. "Front Idle". Kalau file Male sudah di-rename seperti Female,
# ganti template "male" jadi BASE_ROOT + "/Male/({label}) Male Base.png"
const BASE_TEMPLATES := {
	"male": BASE_ROOT + "/Male/({label}) Male Base.png",
	"female": BASE_ROOT + "/Female/({label}) Female Base.png",
}

const RARITY_COLORS := {
	"Common": Color("#9A8F7A"),
	"Uncommon": Color("#5CB85C"),
	"Rare": Color("#2F6FD6"),
	"Epic": Color("#A855F7"),
	"Legendary": Color("#E8A21A"),
	"Mythical": Color("#D63A4A"),
}

# Urutan tampil: Common paling atas, Mythical paling bawah
const RARITY_ORDER := ["Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical"]

const TABS := ["All", "Gender", "Hat", "Clothes", "Pants", "Accessories"]
const TAB_TO_SLOT := {
	"Gender": "gender", "Hat": "hat", "Clothes": "shirt",
	"Pants": "pants", "Accessories": "accessory",
}

# --- Lokasi aset ikon item (SESUAIKAN dengan folder project-mu) ---
const ICON_ROOT := "res://assets/ui/button/avatar/preview"
const RARITY_FOLDERS := {
	"Common": "a. Common", "Uncommon": "b. Uncommon", "Rare": "c. Rare",
	"Epic": "d. Epic", "Legendary": "e. Legendary", "Mythical": "f. Mythical",
}

# Slot "gender" tidak ikut tampil di tab All.
# "set" + "part" = nama file aset: <set>_<part>.png  (mis. Mythical1_Helm.png)
const ITEMS := [
	{"id": "male", "name": "Male", "slot": "gender", "rarity": "Common",
		"icon": "res://assets/ui/button/avatar/placeholder/bx_male.png"},
	{"id": "female", "name": "Female", "slot": "gender", "rarity": "Common",
		"icon": "res://assets/ui/button/avatar/placeholder/bx_female.png"},

	# ---- Common ----
	{"id": "peasant_tunic", "name": "Peasant Tunic", "slot": "shirt", "rarity": "Common", "set": "Common1", "part": "Top"},
	{"id": "peasant_trousers", "name": "Peasant Trousers", "slot": "pants", "rarity": "Common", "set": "Common1", "part": "Pants"},
	{"id": "traveler_tunic", "name": "Traveler's Tunic", "slot": "shirt", "rarity": "Common", "set": "Common2", "part": "Top"},
	{"id": "traveler_trousers", "name": "Traveler's Trousers", "slot": "pants", "rarity": "Common", "set": "Common2", "part": "Pants"},

	# ---- Uncommon ----
	{"id": "merchant_doublet", "name": "Merchant's Doublet", "slot": "shirt", "rarity": "Uncommon", "set": "Uncommon1", "part": "Top"},
	{"id": "merchant_trousers", "name": "Merchant's Trousers", "slot": "pants", "rarity": "Uncommon", "set": "Uncommon1", "part": "Pants"},

	# ---- Rare (ksatria, biru) ----
	{"id": "knight_tabard", "name": "Knight Tabard", "slot": "shirt", "rarity": "Rare", "set": "Rare1", "part": "Top"},
	{"id": "knight_greaves", "name": "Knight Greaves", "slot": "pants", "rarity": "Rare", "set": "Rare1", "part": "Pants"},
	{"id": "knight_sword", "name": "Knight's Sword", "slot": "accessory", "rarity": "Rare", "set": "Rare1", "part": "Sword"},

	# ---- Epic (mage, ungu) ----
	{"id": "arcane_robe", "name": "Arcane Robe", "slot": "shirt", "rarity": "Epic", "set": "Epic1", "part": "Top"},
	{"id": "arcane_leggings", "name": "Arcane Leggings", "slot": "pants", "rarity": "Epic", "set": "Epic1", "part": "Pants"},
	{"id": "arcane_staff", "name": "Arcane Staff", "slot": "accessory", "rarity": "Epic", "set": "Epic1", "part": "Staf"},

	# ---- Legendary (raja, kuning) ----
		{"id": "sunforged_crown", "name": "Sunforged Crown", "slot": "hat", "rarity": "Legendary", "set": "Legendary1", "part": "Crown", "skip_dirs": ["Back"]},
	{"id": "sunforged_mail", "name": "Sunforged Mail", "slot": "shirt", "rarity": "Legendary", "set": "Legendary1", "part": "Top"},
	{"id": "sunforged_greaves", "name": "Sunforged Greaves", "slot": "pants", "rarity": "Legendary", "set": "Legendary1", "part": "Pants"},
	{"id": "sunforged_blade", "name": "Sunforged Blade", "slot": "accessory", "rarity": "Legendary", "set": "Legendary1", "part": "Sword"},

	# ---- Mythical (dark knight, ungu) ----
	{"id": "void_helm", "name": "Void Horned Helm", "slot": "hat", "rarity": "Mythical", "set": "Mythical1", "part": "Helmet"},
	{"id": "void_plate", "name": "Void Plate", "slot": "shirt", "rarity": "Mythical", "set": "Mythical1", "part": "Top"},
	{"id": "void_greaves", "name": "Void Greaves", "slot": "pants", "rarity": "Mythical", "set": "Mythical1", "part": "Pants"},
	{"id": "void_greatsword", "name": "Void Greatsword", "slot": "accessory", "rarity": "Mythical", "set": "Mythical1", "part": "Sword"},
]

func _icon_path(item: Dictionary) -> String:
	if item.has("icon"):
		return item["icon"]
	if item.has("set"):
		return "%s/%s/%s_%s.png" % [
			ICON_ROOT, RARITY_FOLDERS[item["rarity"]], item["set"], item["part"]]
	return ""


func get_icon(item: Dictionary) -> Texture2D:
	var path := _icon_path(item)
	if path.is_empty():
		return null
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	push_warning("Ikon item tidak ditemukan: " + path)
	return null


# Path frame animasi jalan (ingame) untuk satu item / base body
func get_ingame_path(item: Dictionary, direction: String, anim: String) -> String:
	var label := "%s %s" % [direction, anim]
	if item["slot"] == "gender":
		return BASE_TEMPLATES[item["id"]].format({"label": label})
	return "{root}/{folder}/{dir}/({label}) {set}_{part}.png".format({
		"root": INGAME_ROOT, "folder": INGAME_FOLDERS[item["set"]],
		"dir": direction, "label": label, "set": item["set"], "part": item["part"],
	})


# Pastikan avatar valid: id tidak dikenal atau slot wajib yang kosong dikembalikan ke default
func sanitize_avatar(avatar: Dictionary, defaults: Dictionary) -> Dictionary:
	var result := avatar.duplicate()
	for slot in ["gender", "hat", "shirt", "pants", "accessory"]:
		var item := get_item(str(result.get(slot, "")))
		if item.is_empty() or item["slot"] != slot:
			result[slot] = defaults[slot] if slot in REQUIRED_SLOTS else ""
	return result


func _ready() -> void:
	if OS.is_debug_build():
		_verify_assets()

# Arah yang memang tidak punya gambar (mis. mahkota tidak terlihat dari belakang)
func has_frames(item: Dictionary, direction: String) -> bool:
	return not (item.get("skip_dirs", []) as Array).has(direction)

# Cek semua ikon dan semua frame jalan; yang hilang dicetak di Output
func _verify_assets() -> void:
	var missing := 0
	for item in ITEMS:
		var paths: Array[String] = []
		var icon_path := _icon_path(item)
		if not icon_path.is_empty():
			paths.append(icon_path)
		for dir in DIRECTIONS:
			if not has_frames(item, dir):
				continue
			for anim in ANIMS:
				paths.append(get_ingame_path(item, dir, anim))
		for path in paths:
			if not ResourceLoader.exists(path):
				push_warning("Aset tidak ditemukan: " + path)
				missing += 1
	print("ItemDB: cek aset selesai, %d file tidak ditemukan." % missing)


# Filter per tab, urut rarity (Common -> Mythical).
# Item dengan rarity sama tetap dalam urutan di ITEMS di atas.
func get_items(tab: String) -> Array:
	var result: Array = []
	for rarity in RARITY_ORDER:
		for item in ITEMS:
			if item["rarity"] != rarity:
				continue
			if tab == "All":
				if item["slot"] == "gender":
					continue
			elif item["slot"] != TAB_TO_SLOT[tab]:
				continue
			result.append(item)
	return result


func get_item(id: String) -> Dictionary:
	for item in ITEMS:
		if item["id"] == id:
			return item
	return {}

func _items_of_rarity(rarity: String) -> Array:
	var result: Array = []
	for item in ITEMS:
		if item["rarity"] == rarity and item["slot"] != "gender":
			result.append(item)
	return result


# Daftar hadiah chest (Uncommon -> Mythical). Peluang rarity dibagi rata ke item di rarity itu.
func get_gacha_pool() -> Array:
	var pool: Array = []
	for rarity in RARITY_ORDER:
		if not GACHA_RATES.has(rarity):
			continue
		var items := _items_of_rarity(rarity)
		for item in items:
			pool.append({"item": item, "chance": GACHA_RATES[rarity] / float(items.size())})
	return pool


# Undi satu item. Sisa peluang di luar GACHA_RATES jatuh ke Common.
func roll_item() -> Dictionary:
	var roll := randf() * 100.0
	var acc := 0.0
	for entry in get_gacha_pool():
		acc += entry["chance"]
		if roll < acc:
			return entry["item"]
	var commons := _items_of_rarity("Common")
	return commons.pick_random() if not commons.is_empty() else {}


# 9 -> "9%", 9.333 -> "9.33%", 0.15 -> "0.15%"
func format_percent(value: float) -> String:
	return ("%.2f" % value).rstrip("0").rstrip(".") + "%"

func _verify_rates() -> void:
	var total := 0.0
	for rarity in GACHA_RATES:
		total += GACHA_RATES[rarity]
	if total > 100.001:
		push_error("GACHA_RATES berjumlah %.1f%% (lebih dari 100%%). Peluang tidak valid." % total)
	elif total < 99.999:
		push_warning("GACHA_RATES berjumlah %.1f%%; sisanya dianggap Common." % total)
