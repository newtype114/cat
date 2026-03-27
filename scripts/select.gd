extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var bgms = [$BGM]
	var selected_bgm = bgms[randi() % bgms.size()]
	selected_bgm.play()	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	var bgms = [$start1]
	var selected_bgm = bgms[randi() % bgms.size()]
	selected_bgm.play()
	await $start1.finished
	# 预加载游戏主场景
	var main_scene = preload("res://scenes/game.tscn")
	
	# 切换到游戏主场景
	get_tree().change_scene_to_packed(main_scene)
func _on_button_2_pressed() -> void:
	var bgms = [$start2]
	var selected_bgm = bgms[randi() % bgms.size()]
	selected_bgm.play()
	await $start2.finished
	# 预加载游戏主场景
	var main_scene = preload("res://scenes/背景2.tscn")
	# 切换到游戏主场景
	get_tree().change_scene_to_packed(main_scene)
