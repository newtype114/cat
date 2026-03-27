extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 启动对话
	var dialog = Dialogic.start("res://chat/end.dtl")
	add_child(dialog)
	# 监听 Dialogic 全局事件
	Dialogic.signal_event.connect(_on_dialogic_event)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func _on_dialogic_event(value: String) -> void:
	if value == "end":
		# 先清理对话
		Dialogic.end_timeline()
		# 再延迟切场景
		await get_tree().process_frame
		await get_tree().create_timer(1.5).timeout
		get_tree().change_scene_to_file("res://scenes/end_2.tscn")
