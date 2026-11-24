extends Control

const MIN_SHOW_SECONDS := 0.6
const BAR_SPEED := 150.0 # persen per detik

var progress_bar: Range
var target_path: String = ""
var shown_value := 0.0
var elapsed := 0.0
var finished := false


func _ready() -> void:
	progress_bar = find_child("LoadingBar", true, false) as Range

	target_path = Game.target_scene_path
	if target_path.is_empty():
		target_path = Game.SCENES["title"]

	progress_bar.min_value = 0.0
	progress_bar.max_value = 100.0
	progress_bar.value = 0.0

	ResourceLoader.load_threaded_request(target_path)


func _process(delta: float) -> void:
	if finished:
		return
	elapsed += delta

	var progress: Array = []
	var status := ResourceLoader.load_threaded_get_status(target_path, progress)
	var target_value := shown_value

	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			if progress.size() > 0:
				target_value = progress[0] * 100.0
		ResourceLoader.THREAD_LOAD_LOADED:
			target_value = 100.0
		_:
			finished = true
			push_error("Gagal memuat scene: " + target_path)
			return


	shown_value = move_toward(shown_value, target_value, delta * BAR_SPEED)
	progress_bar.value = shown_value

	if status == ResourceLoader.THREAD_LOAD_LOADED \
			and shown_value >= 100.0 and elapsed >= MIN_SHOW_SECONDS:
		_finish()


func _finish() -> void:
	finished = true
	var next_scene := ResourceLoader.load_threaded_get(target_path) as PackedScene
	get_tree().change_scene_to_packed(next_scene)
