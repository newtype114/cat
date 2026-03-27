extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	var main_scene = load("res://scenes/start_menu.tscn")
	print("返回主菜单")  
	var err = get_tree().change_scene_to_packed(main_scene)
	print("切换结果: ", err)
