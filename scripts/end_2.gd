extends Node2D
var step: int = 0
var is_fading = false
var has_changed_scene = false  # 防止重复切换场景
# Called when the node enters the scene tree for the first time.

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Narration.text = ""
	#$Next.visible = false  # 初始隐藏
	$EndTimer.start(1.0)  # 在_ready中启动初始计时器

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_fading and not has_changed_scene:
		$FadeLayer.modulate.a += 0.5 * delta
		if $FadeLayer.modulate.a >= 1.0:
			$FadeLayer.modulate.a = 1.0  # 限制上限
			has_changed_scene = true
			get_tree().change_scene_to_file("res://scenes/start_menu.tscn")
			
func _on_end_timer_timeout() -> void:
	match step:
		0:
			$Narration.text = "耄耋的源头已经被找到\n"
		1:
			$Narration.text += "大家正团结起来向着耄耋的源头进发\n"  # 使用+=追加文本
		2:
			$Narration.text += "接下来就是彻底解决耄耋入侵了\n"
		3:
			$Narration.text += "感谢您的游玩\n"
		4:
			$Narration.text += "如果有机会\n"
		5:
			$Narration.text += "让我们在《基米入侵2深入》再见\n"
		6:
			$Narration.text += "\n"
		7:
			$Narration.text += "\n"
		8:
			$Narration.text += "\n"
		9:
			$Narration.text += "\n"
		10:
			$Narration.text += "\n"
		11:
			#$Next.visible = true  # 显示按钮
			return
		_:
			pass
	step += 1   # 每次超时后推进到下一步
	
func _on_next_pressed() -> void:
	is_fading = true  # 开始淡出
	$Next.disabled = true  # 禁用按钮，防止连点
