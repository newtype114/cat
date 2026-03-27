extends Control  # 挂载到CanvasLayer下的控制节点

@onready var mp_bar: TextureProgressBar = $MP_Bar

func _ready():
	# 等待玩家节点就绪
	await get_tree().process_frame
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		player.mp_updated.connect(_on_mp_updated)
		# 初始化显示
		mp_bar.max_value = player.max_mp
		mp_bar.value = player.current_mp
		print("UI控制器已连接玩家信号")
	else:
		push_error("未找到玩家节点！检查：1.玩家是否添加到'player'组 2.是否在场景中")

func _on_mp_updated(current: float, max_val: float):
	if is_instance_valid(mp_bar):
		mp_bar.value = current
		mp_bar.max_value = max_val
		print("MP更新:", current, "/", max_val)
