extends Control

# Matikan di halaman Top Up (Inspector instance-nya)
@export var show_topup_button := true

@onready var coins_label: Label = find_child("Coins", true, false)
@onready var topup_button: BaseButton = find_child("TopupButton", true, false)


func _ready() -> void:
	_update(Game.coins)
	Game.coins_changed.connect(_update)

	topup_button.visible = show_topup_button
	topup_button.pressed.connect(_on_topup_pressed)


func _update(amount: int) -> void:
	coins_label.text = _format(amount)


func _on_topup_pressed() -> void:
	if Game.current_page != "topup":
		Game.go_to("topup")


# 1500 -> "1,500"
func _format(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out
