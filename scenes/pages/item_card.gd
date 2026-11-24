extends Button

signal chosen(item_id: String)

var item: Dictionary = {}

@onready var name_label: Label = find_child("NameLabel", true, false)
@onready var rarity_label: Label = find_child("RarityLabel", true, false)
@onready var icon_rect: TextureRect = find_child("Icon", true, false)
@onready var border: Panel = find_child("Border", true, false)
@onready var used_overlay: Control = find_child("UsedOverlay", true, false)
@onready var chance_label: Label = find_child("ChanceLabel", true, false)


# Panggil SETELAH kartu ditambahkan ke scene tree
func setup(new_item: Dictionary, in_use: bool) -> void:
	item = new_item
	name_label.text = item["name"]

	# Ikon: kalau belum ada filenya, lingkaran placeholder tetap tampil
	var icon_texture := ItemDB.get_icon(item)
	if icon_rect == null:
		push_warning("Node 'Icon' (TextureRect) tidak ditemukan di item_card.")
	elif icon_texture:
		icon_rect.texture = icon_texture

	var is_gender: bool = item["slot"] == "gender"
	var color: Color = ItemDB.RARITY_COLORS[item["rarity"]]

	# Gender tidak punya rarity: sembunyikan label, stroke netral
	rarity_label.visible = not is_gender
	rarity_label.text = item["rarity"]
	rarity_label.add_theme_color_override("font_color", color)

	var stroke := StyleBoxFlat.new()
	stroke.draw_center = false
	stroke.set_border_width_all(2)
	stroke.border_color = color
	border.add_theme_stylebox_override("panel", stroke)

	set_in_use(in_use)
	pressed.connect(func(): chosen.emit(item["id"]))


func set_in_use(value: bool) -> void:
	used_overlay.visible = value


# Hanya dipakai di kartu Shop (scene yang punya node "ChanceLabel")
func set_chance_text(text: String) -> void:
	if chance_label:
		chance_label.text = text
