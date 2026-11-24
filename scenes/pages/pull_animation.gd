extends Control

# --- Durasi (detik), ubah untuk mengatur tempo ---
const T_STAGE_FADE := 0.35   # layar hitam muncul
const T_FALL := 0.9          # peti jatuh
const T_AFTER_FALL := 0.4
const T_GLOW_IN := 0.7       # warna rarity memenuhi layar
const T_GLOW_HOLD := 0.4
const T_GLOW_OUT := 0.6      # warna memudar, peti sudah terbuka
const T_AFTER_OPEN := 0.3
const T_FLASH_IN := 0.12     # flash putih
const T_FLASH_OUT := 0.5
const CARD_STAGGER := 0.06   # jeda munculnya tiap kartu
const WHEEL_STEP := 120

enum Phase { HIDDEN, PLAYING, DONE, CLOSING }
const DEBUG := true
const RESULT_MARGIN := 20.0   # jarak daftar item dari tepi Stage

@onready var backdrop: Control = find_child("Backdrop", true, false)
@onready var dim: Control = find_child("Dim", true, false)
@export var card_scene: PackedScene   # kartu yang sama dengan Card Scene di ChestLootPopup

@onready var stage: Control = find_child("Stage", true, false)
@onready var chest_closed: Control = find_child("Chest", true, false)
@onready var chest_open: Control = find_child("ChestOpen", true, false)
@onready var result_scroll: ScrollContainer = find_child("ResultScroll", true, false)
@onready var result_row: HBoxContainer = find_child("ResultRow", true, false)
@onready var glow: ColorRect = find_child("RarityGlow", true, false)
@onready var flash: ColorRect = find_child("Flash", true, false)

var phase: Phase = Phase.HIDDEN
var closed_rest_pos := Vector2.ZERO
var pending_results: Array = []
var main_tween: Tween
var reveal_tween: Tween


func _ready() -> void:
	var required := {
		"Stage": stage, "Backdrop": backdrop, "Chest": chest_closed,
		"ChestOpen": chest_open, "ResultScroll": result_scroll,
		"ResultRow": result_row, "RarityGlow": glow, "Flash": flash,
	}
	for node_name in required:
		if required[node_name] == null:
			push_error("PullAnimation: node '%s' tidak ditemukan. Cek namanya." % node_name)
			return

	visible = false
	_fit_stage_to_backdrop()
	_layout_result_scroll()
	stage.clip_contents = true
	closed_rest_pos = chest_closed.position # harus setelah Stage disesuaikan

	chest_open.visible = false
	glow.visible = false
	flash.visible = false

	result_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	result_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result_row.alignment = BoxContainer.ALIGNMENT_CENTER
	result_scroll.gui_input.connect(_on_scroll_input)
	print("[DEBUG] PullAnimation siap. Stage: ", stage.get_global_rect())


# Dipanggil dari shop.gd lewat signal pull_finished
func play(results: Array) -> void:
	if phase != Phase.HIDDEN:
		push_warning("PullAnimation: animasi sebelumnya belum ditutup.")
		return
	if results.is_empty():
		push_warning("PullAnimation: hasil kosong.")
		return
	if card_scene == null:
		push_error("Card Scene belum diisi di Inspector node PullAnimation.")
		return

	pending_results = results
	phase = Phase.PLAYING

	# Reset ke kondisi awal
	for child in result_row.get_children():
		result_row.remove_child(child)
		child.queue_free()
	result_scroll.visible = false

	chest_open.visible = false
	chest_closed.visible = true
	chest_closed.position = Vector2(closed_rest_pos.x, -chest_closed.size.y - 40.0) # di atas Stage

	stage.visible = true
	stage.modulate.a = 0.0
	if dim:
		dim.modulate.a = 0.0
	glow.color = ItemDB.RARITY_COLORS[_best_rarity(results)]
	glow.modulate.a = 0.0
	glow.visible = true
	flash.modulate.a = 0.0
	flash.visible = true
	modulate.a = 1.0
	visible = true

	# Satu rangkaian tween, jadi bisa dibatalkan sekaligus saat di-skip
	main_tween = create_tween()
	main_tween.tween_property(stage, "modulate:a", 1.0, T_STAGE_FADE)
	if dim:
		main_tween.parallel().tween_property(dim, "modulate:a", 1.0, T_STAGE_FADE)
	main_tween.tween_property(chest_closed, "position:y", closed_rest_pos.y, T_FALL) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	main_tween.tween_interval(T_AFTER_FALL)
	main_tween.tween_property(glow, "modulate:a", 1.0, T_GLOW_IN)
	main_tween.tween_interval(T_GLOW_HOLD)
	main_tween.tween_callback(_open_chest) # terjadi di balik warna penuh
	main_tween.tween_property(glow, "modulate:a", 0.0, T_GLOW_OUT)
	main_tween.tween_interval(T_AFTER_OPEN)
	main_tween.tween_property(flash, "modulate:a", 1.0, T_FLASH_IN)
	main_tween.tween_callback(_build_results.bind(true))
	main_tween.tween_property(flash, "modulate:a", 0.0, T_FLASH_OUT)
	main_tween.tween_callback(_on_animation_done)

	if DEBUG:
		get_tree().create_timer(1.8).timeout.connect(_debug_report)


func _best_rarity(results: Array) -> String:
	var best := "Common"
	for r in results:
		var rarity: String = r["item"]["rarity"]
		if ItemDB.RARITY_ORDER.find(rarity) > ItemDB.RARITY_ORDER.find(best):
			best = rarity
	return best


# Ganti peti tertutup dengan peti terbuka
func _open_chest() -> void:
	chest_closed.visible = false
	chest_open.visible = true


func _on_animation_done() -> void:
	glow.visible = false
	flash.visible = false
	phase = Phase.DONE


func _build_results(animate: bool) -> void:
	for child in result_row.get_children():
		result_row.remove_child(child)
		child.queue_free()

	var cards: Array[Control] = []
	for r in pending_results:
		var card := card_scene.instantiate() as Button
		result_row.add_child(card)           # setup() butuh node sudah di scene tree
		card.setup(r["item"], false)
		card.set_chance_text("Duplicate" if r["duplicate"] else "NEW!")
		# Kartu hanya untuk dilihat: tidak menghalangi klik dan scroll
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.focus_mode = Control.FOCUS_NONE
		card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		cards.append(card)

	result_scroll.scroll_horizontal = 0
	result_scroll.visible = true

	if animate:
		reveal_tween = create_tween().set_parallel(true)
		for i in cards.size():
			cards[i].modulate.a = 0.0
			reveal_tween.tween_property(cards[i], "modulate:a", 1.0, 0.18) \
				.set_delay(0.1 + CARD_STAGGER * i)


# Lewati animasi: langsung ke hasil
func _skip() -> void:
	if main_tween:
		main_tween.kill()
	if reveal_tween:
		reveal_tween.kill()
	stage.modulate.a = 1.0
	stage.visible = true
	if dim:
		dim.modulate.a = 1.0
	chest_closed.position = closed_rest_pos
	_open_chest()
	glow.modulate.a = 0.0
	flash.modulate.a = 0.0
	_build_results(false)
	_on_animation_done()


func _close() -> void:
	phase = Phase.CLOSING
	var out := create_tween()
	out.tween_property(self, "modulate:a", 0.0, 0.25)
	out.tween_callback(func():
		visible = false
		modulate.a = 1.0
		phase = Phase.HIDDEN)


func _input(event: InputEvent) -> void:
	if phase == Phase.HIDDEN or phase == Phase.CLOSING:
		return

	var is_click: bool = event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT
	var inside_stage: bool = is_click and stage.get_global_rect().has_point(event.position)

	if phase == Phase.PLAYING:
		# Saat animasi: klik di dalam Stage = lewati. Di luar Stage dan Esc tidak berpengaruh.
		if inside_stage:
			get_viewport().set_input_as_handled()
			_skip()
		return

	# Phase.DONE: klik di luar Stage atau Esc menutup
	var outside_click: bool = is_click and not inside_stage
	if outside_click or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()


# Mouse wheel menggeser daftar item secara horizontal (sama seperti ChestLootPopup)
func _on_scroll_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN \
				or event.button_index == MOUSE_BUTTON_WHEEL_RIGHT:
			result_scroll.scroll_horizontal += WHEEL_STEP
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP \
				or event.button_index == MOUSE_BUTTON_WHEEL_LEFT:
			result_scroll.scroll_horizontal -= WHEEL_STEP
			get_viewport().set_input_as_handled()


func _debug_report() -> void:
	if phase != Phase.PLAYING and phase != Phase.DONE:
		return
	print("[DEBUG] --- laporan PullAnimation ---")
	print("[DEBUG] Stage: rect=%s modulate.a=%.2f clip=%s visible=%s" % [
		stage.get_global_rect(), stage.modulate.a, stage.clip_contents, stage.visible])
	for child in stage.get_children():
		if child is Control:
			print("[DEBUG]   %s: visible=%s rect=%s" % [
				child.name, child.visible, child.get_global_rect()])
	print("[DEBUG] Urutan anak PullAnimation (atas = digambar paling belakang):")
	for child in get_children():
		print("[DEBUG]   ", child.name)


# Stage harus seluas kotak gelap (Backdrop), supaya Clip Contents dan
# "klik di luar Stage" bekerja. Posisi dan ukuran semua anak dipertahankan.
func _fit_stage_to_backdrop() -> void:
	var target := backdrop.get_global_rect()

	var saved: Dictionary = {}
	for child in stage.get_children():
		if child is Control:
			saved[child] = (child as Control).get_global_rect()

	stage.global_position = target.position
	stage.size = target.size

	for child in saved:
		var rect: Rect2 = saved[child]
		child.size = rect.size
		child.global_position = rect.position


# Daftar item selebar Stage dan berada di atas peti terbuka
func _layout_result_scroll() -> void:
	var height := maxf(chest_open.position.y - RESULT_MARGIN * 2.0, 120.0)
	result_scroll.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	result_scroll.size = Vector2(stage.size.x - RESULT_MARGIN * 2.0, height)
	result_scroll.position = Vector2(RESULT_MARGIN, RESULT_MARGIN)
