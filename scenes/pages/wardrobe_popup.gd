extends Control

signal saved

@export var item_card_scene: PackedScene
@export var debug_clicks := false         # centang sementara: mencetak node yang menangkap klik
@export var manual_tab_clicks := false    # cadangan: tab dideteksi dari posisi klik

@onready var panel: Control = find_child("WardrobePanel", true, false)
@onready var tab_row: Control = find_child("TabRow", true, false)
@onready var grid: GridContainer = find_child("ItemGrid", true, false)
@onready var save_button: BaseButton = find_child("WardrobeSaveButton", true, false)
@onready var preview: AvatarPreview = find_child("CharacterPreview", true, false)

var current_tab := "All"
var draft: Dictionary = {}          # pilihan sementara, baru masuk Game.avatar saat Save
var tab_buttons: Dictionary = {}    # nama tab -> BaseButton


func _ready() -> void:
	visible = false

	for child in tab_row.get_children():
		if not child is BaseButton:
			continue
		var button := child as BaseButton
		var tab := _tab_name_of(button)
		if tab.is_empty():
			push_warning("Tab tidak dikenali dari nama node: " + str(button.name))
			continue
		button.toggle_mode = true
		button.pressed.connect(_select_tab.bind(tab))
		tab_buttons[tab] = button
	if tab_buttons.is_empty():
		push_warning("Tidak ada tombol tab yang dikenali di TabRow.")

	save_button.pressed.connect(_on_save_pressed)


# Nama tab dicari dari nama node (dan teks tombol kalau ada)
func _tab_name_of(button: BaseButton) -> String:
	var label := str(button.name).to_lower()
	if button is Button:
		label += " " + (button as Button).text.to_lower()
	for tab in ItemDB.TABS:
		if label.contains(tab.to_lower()):
			return tab
	return ""


func open() -> void:
	draft = Game.avatar.duplicate()
	current_tab = "All"
	_refresh_tab_visuals()
	_rebuild_grid()
	_update_preview()
	if debug_clicks:
		_report_blockers()
	visible = true


func close() -> void:
	visible = false
	
# Diagnostik: cetak semua Control yang menutupi atau memblokir tombol tab
func _report_blockers() -> void:
	for tab in tab_buttons:
		var button := tab_buttons[tab] as BaseButton
		if button.disabled:
			print("Tab '%s': tombol dalam keadaan Disabled" % tab)
		if button.mouse_filter == Control.MOUSE_FILTER_IGNORE:
			print("Tab '%s': Mouse Filter tombol = Ignore" % tab)
		var center := button.get_global_rect().get_center()
		for c in get_tree().root.find_children("*", "Control", true, false):
			var control := c as Control
			if control == button or button.is_ancestor_of(control):
				continue
			if not control.is_visible_in_tree() \
					or control.mouse_filter != Control.MOUSE_FILTER_STOP:
				continue
			if button.is_greater_than(control) and control.get_global_rect().has_point(center):
				print("Tab '%s' tertutup oleh: %s" % [tab, control.get_path()])


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if debug_clicks and event is InputEventMouseButton and event.pressed:
		print("Klik mengenai: ", get_viewport().gui_get_hovered_control())

	# Esc atau klik di luar panel menutup popup dan membuang perubahan yang belum di-save
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		if manual_tab_clicks:
			for tab in tab_buttons:
				if (tab_buttons[tab] as Control).get_global_rect().has_point(event.position):
					_select_tab(tab)
					get_viewport().set_input_as_handled()
					return
		if not panel.get_global_rect().has_point(event.position):
			close()
			get_viewport().set_input_as_handled()


func _select_tab(tab: String) -> void:
	current_tab = tab
	_refresh_tab_visuals()
	_rebuild_grid()


func _refresh_tab_visuals() -> void:
	for tab in tab_buttons:
		var button: BaseButton = tab_buttons[tab]
		var active: bool = (tab == current_tab)
		button.set_pressed_no_signal(active)
		var has_pressed_look := button is TextureButton \
				and (button as TextureButton).texture_pressed != null
		button.modulate = Color.WHITE if (active or has_pressed_look) else Color(1, 1, 1, 0.7)


func _rebuild_grid() -> void:
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()

	for item in ItemDB.get_items(current_tab):
		if not Game.owns(item["id"]):
			continue
		var card := item_card_scene.instantiate()
		grid.add_child(card)
		card.setup(item, draft.get(item["slot"], "") == item["id"])
		card.chosen.connect(_on_item_chosen)


func _on_item_chosen(item_id: String) -> void:
	var item := ItemDB.get_item(item_id)
	var slot: String = item["slot"]

	if draft.get(slot, "") == item_id:
		# Gender, baju, dan celana wajib ada: klik item yang sedang dipakai tidak melepasnya
		if slot in ItemDB.REQUIRED_SLOTS:
			return
		draft[slot] = ""      # topi dan aksesori: klik lagi = lepas
	else:
		draft[slot] = item_id

	for card in grid.get_children():
		card.set_in_use(draft.get(card.item["slot"], "") == card.item["id"])
	_update_preview()


func _update_preview() -> void:
	if preview:
		preview.show_avatar(draft)


func _on_save_pressed() -> void:
	Game.avatar = draft.duplicate()
	AccountDB.set_avatar(Game.email, Game.avatar)
	saved.emit()
	close()
