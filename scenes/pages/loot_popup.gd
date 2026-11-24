extends Control

const WHEEL_STEP := 120

@export var card_scene: PackedScene   # shop_item_card.tscn
@export var scroll_gap := 20.0        # jarak (px) antara bagian bawah kartu dan scrollbar

@export var click_area: Control
@export var fallback_padding := Vector4(40, 90, 40, 40)  # node bingkai popup yang terlihat; kosong = pakai LootPanel
const DEBUG_CLICKS := true      # ubah ke true untuk melihat posisi klik dan area panel di Output

@onready var panel: Control = find_child("LootPanel", true, false)
@onready var scroll: ScrollContainer = find_child("LootScroll", true, false)
@onready var row: HBoxContainer = find_child("LootRow", true, false)


func _ready() -> void:
	var required := {"LootPanel": panel, "LootScroll": scroll, "LootRow": row}
	for node_name in required:
		if required[node_name] == null:
			push_error("Node tidak ditemukan di popup: " + node_name)
	visible = false
	scroll.gui_input.connect(_on_scroll_input)


func open() -> void:
	_build_cards()
	scroll.scroll_horizontal = 0
	visible = true


func close() -> void:
	visible = false


func _build_cards() -> void:
	if card_scene == null:
		push_error("Card Scene belum diisi di Inspector node ChestLootPopup.")
		return

	for child in row.get_children():
		row.remove_child(child)
		child.queue_free()

	for entry in ItemDB.get_gacha_pool():
		var card := card_scene.instantiate() as Button
		row.add_child(card)
		card.setup(entry["item"], false)
		card.set_chance_text(ItemDB.format_percent(entry["chance"]))
		# Kartu hanya untuk dilihat: tidak bisa diklik, dan tidak menghalangi geser/scroll
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.focus_mode = Control.FOCUS_NONE
		# Tinggi kartu tetap (tidak melar), sisanya menjadi jarak ke scrollbar
		card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	_apply_scroll_gap()


func _apply_scroll_gap() -> void:
	var card_height := 0.0
	for card in row.get_children():
		card_height = maxf(card_height, (card as Control).get_combined_minimum_size().y)
	var bar_height := scroll.get_h_scroll_bar().get_combined_minimum_size().y
	scroll.custom_minimum_size.y = card_height + scroll_gap + bar_height


# Mouse wheel menggeser daftar secara horizontal
func _on_scroll_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN \
				or event.button_index == MOUSE_BUTTON_WHEEL_RIGHT:
			scroll.scroll_horizontal += WHEEL_STEP
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP \
				or event.button_index == MOUSE_BUTTON_WHEEL_LEFT:
			scroll.scroll_horizontal -= WHEEL_STEP
			get_viewport().set_input_as_handled()


# Esc atau klik di luar panel menutup popup
# Esc atau klik di luar bingkai menutup popup
func _inside_rect() -> Rect2:
	if click_area:
		return click_area.get_global_rect()
	return scroll.get_global_rect().grow_individual(
		fallback_padding.x, fallback_padding.y, fallback_padding.z, fallback_padding.w)


# Esc atau klik di luar bingkai menutup popup
func _input(event: InputEvent) -> void:
	if not visible:
		return
	var is_left_click: bool = event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT

	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
	elif is_left_click:
		var rect := _inside_rect()
		if DEBUG_CLICKS:
			print("[LOOT CLICK] pos=%s inside_rect=%s" % [event.position, rect])
		if not rect.has_point(event.position):
			close()
			get_viewport().set_input_as_handled()
