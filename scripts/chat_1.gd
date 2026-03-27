extends Node2D
@onready var room =$room

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 启动对话
	var dialog = Dialogic.start("res://chat/start.dtl")
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
		get_tree().change_scene_to_file("res://scenes/select.tscn")

	elif value == "Change":
		# 触发显示 room
		room.show()
		print("检测到 Change 信号，room 已显示")
func _on_skip_pressed() -> void:
	print("跳过按钮被点击")  # 测试触发
	get_tree().change_scene_to_file("res://scenes/select.tscn")
