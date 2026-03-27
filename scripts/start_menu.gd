extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var bgms = [$bgm1, $bgm2]
	var selected_bgm = bgms[randi() % bgms.size()]
	selected_bgm.play()



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_startbutton_pressed() -> void:
	var main_scene = preload("res://scenes/chat_1.tscn")
	get_tree().change_scene_to_packed(main_scene)


func _on_quitbutton_pressed() -> void:
	get_tree().quit()


func _on_illustrated_handbook_pressed() -> void:
	var main_scene = load("res://scenes/illustrated_handbook.tscn")
	if main_scene == null:
		push_error("illustrated_handbook.tscn 加载失败，请检查路径")
		return
	get_tree().change_scene_to_packed(main_scene)
