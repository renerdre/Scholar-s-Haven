extends Label

var joined_ms: int = 0
var elapsed: int = 0


func _ready() -> void:
	joined_ms = Time.get_ticks_msec()
	Game.status_changed.connect(func(_s): _update_text())
	_update_text()


func _process(_delta: float) -> void:
	var now_elapsed := floori((Time.get_ticks_msec() - joined_ms) / 1000.0)
	if now_elapsed != elapsed:
		elapsed = now_elapsed
		_update_text()


func _update_text() -> void:
	var lines: Array[String] = [Game.username if Game.username != "" else "Player"]
	lines.append(Game.format_time(elapsed, true))
	if Game.player_status != "Idle":
		lines.append(Game.player_status)
	text = "\n".join(lines)
