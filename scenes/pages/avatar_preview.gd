class_name AvatarPreview
extends Node2D

@export var preview_scale := 3.0
@export var feet_offset := Vector2(0, -20)   # telapak kaki tepat di titik (0,0)

const LAYER_NAMES := ["Body", "Pants", "Top", "Accessory", "Hat"]   # bawah -> atas
const SLOT_TO_LAYER := {
	"pants": "Pants", "shirt": "Top", "accessory": "Accessory", "hat": "Hat",
}

var layers: Dictionary = {}


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scale = Vector2(preview_scale, preview_scale)
	for layer_name in LAYER_NAMES:
		var sprite := Sprite2D.new()
		sprite.name = layer_name
		sprite.offset = feet_offset
		add_child(sprite)
		layers[layer_name] = sprite
	show_avatar(Game.avatar)


func show_avatar(avatar: Dictionary) -> void:
	_show_layer("Body", ItemDB.get_item(str(avatar.get("gender", "male"))))
	for slot in SLOT_TO_LAYER:
		_show_layer(SLOT_TO_LAYER[slot], ItemDB.get_item(str(avatar.get(slot, ""))))


func _show_layer(layer_name: String, item: Dictionary) -> void:
	var sprite: Sprite2D = layers[layer_name]
	sprite.texture = null
	if item.is_empty():
		return
	var path := ItemDB.get_ingame_path(item, "Front", "Idle")
	if ResourceLoader.exists(path):
		sprite.texture = load(path) as Texture2D
	else:
		push_warning("Frame preview tidak ditemukan: " + path)
