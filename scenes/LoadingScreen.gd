extends Control

@onready var progress_bar = $LoadingBar 

func _ready():

	ResourceLoader.load_threaded_request(Global.target_scene_path)

func _process(_delta):
	var progress = []

	var status = ResourceLoader.load_threaded_get_status(Global.target_scene_path, progress)
	
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:

		progress_bar.value = progress[0] * 100
		
	elif status == ResourceLoader.THREAD_LOAD_LOADED:

		set_process(false)
		progress_bar.value = 100
		
		await get_tree().create_timer(0.5).timeout

		var next_scene = ResourceLoader.load_threaded_get(Global.target_scene_path)
		get_tree().change_scene_to_packed(next_scene)
		
	elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		print("🚨 ERROR: Gagal memuat scene di path: ", Global.target_scene_path)
		set_process(false)
