extends Control

@onready var name_label: Label = find_child("RoomNameLabel", true, false)
@onready var host_label: Label = find_child("HostLabel", true, false)
@onready var desc_label: Label = find_child("DescriptionLabel", true, false)
@onready var members_label: Label = find_child("MembersLabel", true, false)
@onready var join_button: BaseButton = find_child("JoinButton", true, false)

var room_name := "Late Night Studies"
var host_name := "Kiruue"
var description := "Belajar bareng sampai subuh"
var members := 3
var capacity := 5


func _ready() -> void:
	name_label.text = room_name
	host_label.text = host_name
	desc_label.text = description
	members_label.text = "Members: %d/%d" % [members, capacity]

	join_button.pressed.connect(_on_join_pressed)


func _on_join_pressed() -> void:
	if members >= capacity:
		print("Room penuh")
		return
	Game.go_to("ingame")
