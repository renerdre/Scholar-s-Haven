extends Control

signal pull_finished(results: Array)   # untuk animasi opening nanti
@onready var pull_animation: Control = find_child("PullAnimation", true, false)
# Harga dan jumlah pull tiap tombol (urut PullButton1..3). SESUAIKAN dengan desainmu.
const PULL_OPTIONS := [
	{"pulls": 1, "cost": 120},
	{"pulls": 5, "cost": 500},
	{"pulls": 10, "cost": 900},
]
const PULL_BUTTON_NAMES := ["PullButton1", "PullButton2", "PullButton3"]

# Mencampur warna gambar ke putih sebesar "amount" (0 = normal, 1 = putih penuh)
const WHITE_SHADER_CODE := """
shader_type canvas_item;
uniform float amount : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	COLOR.rgb = mix(COLOR.rgb, vec3(1.0), amount);
}
"""

@onready var chest_button: BaseButton = find_child("ChestButton", true, false)
@onready var loot_popup: Control = find_child("ChestLootPopup", true, false)
@onready var message_label: Label = find_child("ShopMessageLabel", true, false)

var chest_material: ShaderMaterial
var hover_tween: Tween
var message_tween: Tween


func _ready() -> void:
	_setup_chest()
	_setup_pull_buttons()
	_fill_rate_labels()
	_show_message("", false)
	print("[DEBUG] pull_animation = ", pull_animation)
	if pull_animation:
		pull_finished.connect(pull_animation.play)
		print("[DEBUG] pull_finished tersambung ke PullAnimation.play")


# ---------- Chest ----------

func _setup_chest() -> void:
	var shader := Shader.new()
	shader.code = WHITE_SHADER_CODE
	chest_material = ShaderMaterial.new()
	chest_material.shader = shader
	chest_material.set_shader_parameter("amount", 0.0)
	chest_button.material = chest_material
	chest_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	chest_button.mouse_entered.connect(func(): _tween_chest(1.0))
	chest_button.mouse_exited.connect(func(): _tween_chest(0.0))
	chest_button.pressed.connect(loot_popup.open)


func _tween_chest(target: float) -> void:
	if hover_tween:
		hover_tween.kill()
	var from: float = chest_material.get_shader_parameter("amount")
	hover_tween = create_tween()
	hover_tween.tween_method(
		func(v: float): chest_material.set_shader_parameter("amount", v), from, target, 0.12)


# ---------- Tombol beli ----------

func _setup_pull_buttons() -> void:
	for i in PULL_OPTIONS.size():
		var button := find_child(PULL_BUTTON_NAMES[i], true, false) as BaseButton
		if button == null:
			push_warning("Tombol beli tidak ditemukan: " + PULL_BUTTON_NAMES[i])
			continue
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_set_child_label(button, "PriceLabel", _format_number(PULL_OPTIONS[i]["cost"]))
		_set_child_label(button, "PullLabel", "%d pull" % PULL_OPTIONS[i]["pulls"])
		button.pressed.connect(_on_pull_pressed.bind(i))


func _on_pull_pressed(index: int) -> void:
	var option: Dictionary = PULL_OPTIONS[index]
	var cost: int = option["cost"]
	if Game.coins < cost:
		_show_message("Not enough coins.", true)
		return

	# Undi semua item dulu, tandai mana yang baru dan mana yang duplikat
	var results: Array = []
	var new_count := 0
	for i in int(option["pulls"]):
		var item := ItemDB.roll_item()
		if item.is_empty():
			continue
		var is_duplicate := Game.owns(item["id"])
		if not is_duplicate:
			Game.owned_items.append(item["id"])
			new_count += 1
		results.append({"item": item, "duplicate": is_duplicate})

	# Bayar dan simpan
	Game.coins -= cost
	AccountDB.save_purchase(Game.email, Game.coins, Game.owned_items)

	# Placeholder hasil: ringkasan singkat. Animasi opening nanti menyambung ke pull_finished.
	var best: Dictionary = results[0]["item"]
	for r in results:
		print("Pull: %s (%s)%s" % [r["item"]["name"], r["item"]["rarity"],
				" - duplicate" if r["duplicate"] else ""])
		if ItemDB.RARITY_ORDER.find(r["item"]["rarity"]) > ItemDB.RARITY_ORDER.find(best["rarity"]):
			best = r["item"]
	_show_message("Got %d item(s), %d new. Best: %s (%s)" % [
		results.size(), new_count, best["name"], best["rarity"]], false)
	print("[DEBUG] emit pull_finished, jumlah hasil: ", results.size())
	pull_finished.emit(results)


# ---------- Label ----------

# Isi label persen di daftar rate dari ItemDB (node "UncommonPercent", "RarePercent", dst.)
func _fill_rate_labels() -> void:
	for rarity in ItemDB.GACHA_RATES:
		var label := find_child(rarity + "Percent", true, false) as Label
		if label:
			label.text = ItemDB.format_percent(ItemDB.GACHA_RATES[rarity])


func _set_child_label(parent: Node, label_name: String, text: String) -> void:
	var label := parent.find_child(label_name, true, false) as Label
	if label:
		label.text = text


func _show_message(text: String, is_error: bool) -> void:
	if message_label == null:
		if not text.is_empty():
			print(text)
		return
	if message_tween:
		message_tween.kill()
	message_label.text = text
	message_label.modulate = Color("#E05A5A") if is_error else Color("#4CD137")
	message_label.modulate.a = 1.0
	if not text.is_empty():
		message_tween = create_tween()
		message_tween.tween_interval(2.5)
		message_tween.tween_property(message_label, "modulate:a", 0.0, 0.5)


func _format_number(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out
