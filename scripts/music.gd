extends Node

var player: AudioStreamPlayer
var tween: Tween
var last_stream: AudioStream
var stopped := true


func _ready() -> void:
	player = AudioStreamPlayer.new()
	add_child(player)


func play(stream: AudioStream, fade_in: float = 3.0) -> void:
	if stream == null:
		return
	last_stream = stream
	if not stopped and player.stream == stream:
		return # sudah memutar lagu ini

	stopped = false
	if tween:
		tween.kill()
	player.stream = stream
	player.volume_db = -40.0
	player.play()
	tween = create_tween()
	tween.tween_property(player, "volume_db", 0.0, fade_in)


# Lanjutkan lagu terakhir kalau sebelumnya dihentikan
func resume(fade_in: float = 2.0) -> void:
	if stopped and last_stream:
		play(last_stream, fade_in)


func stop(fade_out: float = 1.5) -> void:
	if stopped:
		return
	stopped = true
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(player, "volume_db", -40.0, fade_out)
	tween.tween_callback(player.stop)
