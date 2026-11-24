class_name CharacterVisual
extends Node2D

@export var visual_scale := 1.85
@export var frame_time := 0.13               # detik per frame saat jalan
@export var feet_offset := Vector2(0, -20)   # kaki tepat di titik (0,0): setengah tinggi 40 px

# Urutan jalan: kaki kiri depan, netral, kaki kanan depan, netral
const WALK_SEQUENCE := ["Walking Cycle_1", "Idle", "Walking Cycle_2", "Idle"]
const LAYER_NAMES := ["Body", "Pants", "Top", "Accessory", "Hat"]   # bawah -> atas
const SLOT_TO_LAYER := {
	"pants": "Pants", "shirt": "Top", "accessory": "Accessory", "hat": "Hat",
}
# Arah di mana aksesori (pedang/staf) digambar DI BELAKANG badan. Kosong dulu, tes nanti.
const ACCESSORY_BEHIND_DIRECTIONS := []

var layers: Dictionary = {}     # nama layer -> Sprite2D
var textures: Dictionary = {}   # nama layer -> {"Front|Idle": Texture2D, ...}
var direction := "Front"
var face_left := false
var walking := false
var current_anim := "Idle"
var step := 0
var step_timer := 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for layer_name in LAYER_NAMES:
		var sprite := Sprite2D.new()
		sprite.name = layer_name
		sprite.offset = feet_offset
		add_child(sprite)
		layers[layer_name] = sprite
	_apply_scale()
	apply_avatar(Game.avatar)


func apply_avatar(avatar: Dictionary) -> void:
	textures.clear()
	_load_layer("Body", ItemDB.get_item(str(avatar.get("gender", "male"))))
	for slot in SLOT_TO_LAYER:
		_load_layer(SLOT_TO_LAYER[slot], ItemDB.get_item(str(avatar.get(slot, ""))))
	_refresh()


# arah: "Front" / "Back" / "Side". face_left hanya berarti untuk "Side".
func set_motion(new_direction: String, is_walking: bool, new_face_left: bool = false) -> void:
	var changed := false
	if new_direction != direction:
		direction = new_direction
		changed = true
	if new_face_left != face_left:
		face_left = new_face_left
		_apply_scale()
	if is_walking != walking:
		walking = is_walking
		step = 0
		step_timer = 0.0
		current_anim = WALK_SEQUENCE[0] if walking else "Idle"
		changed = true
	if changed:
		_refresh()


func _process(delta: float) -> void:
	if not walking:
		return
	step_timer += delta
	if step_timer >= frame_time:
		step_timer -= frame_time
		step = (step + 1) % WALK_SEQUENCE.size()
		current_anim = WALK_SEQUENCE[step]
		_refresh()


func _load_layer(layer_name: String, item: Dictionary) -> void:
	var loaded := {}
	if not item.is_empty():
		for dir in ItemDB.DIRECTIONS:
			if not ItemDB.has_frames(item, dir):
				continue
			for anim in ItemDB.ANIMS:
				var path := ItemDB.get_ingame_path(item, dir, anim)
				if ResourceLoader.exists(path):
					loaded["%s|%s" % [dir, anim]] = load(path)
				else:
					push_warning("Frame avatar tidak ditemukan: " + path)
	textures[layer_name] = loaded


func _refresh() -> void:
	var key := "%s|%s" % [direction, current_anim]
	for layer_name in LAYER_NAMES:
		layers[layer_name].texture = textures.get(layer_name, {}).get(key, null)
	layers["Accessory"].z_index = -1 if direction in ACCESSORY_BEHIND_DIRECTIONS else 0


func _apply_scale() -> void:
	scale = Vector2(-visual_scale if face_left else visual_scale, visual_scale)
