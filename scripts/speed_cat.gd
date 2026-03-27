extends Area2D

@export var acceleration : float = -70.0     # 每秒加速量（正数）
var current_speed : float = -90             # 当前X速度，初始较慢（负数代表向左）
@export var speed_cat_speed : float = -200
@export var max_speed : float = -300     # 最大速度限制（负值，越大速度越快）
# Y轴可能的固定值数组
var y_fixed_values = [-30, -15, 0, 15, 30]
# 当前Y轴速度
var current_y_speed = 0
@export var is_dead : bool = false
@export var bullet_disappear_chance : float = 0.9 # 子弹消失概率
@export var min_y_position : float = 20#y限制范围
@export var max_y_position : float = 150    # 最大Y边界
@export var target_x_position : float = -350  # 新增：触发扣分的X坐标位置	
var can_move: bool = true
@export var start_scene: PackedScene


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if can_move:
		# 每秒根据加速度增加当前速度
		current_speed += acceleration * delta
		# 限制最大速度（不能超过 max_speed）
		if current_speed < max_speed:
			current_speed = max_speed


		if randf() < 0.1:
			current_y_speed = y_fixed_values[randi() % y_fixed_values.size()]
		position += Vector2(current_speed, current_y_speed) * delta
		$AudioStreamPlayer.play()
		if position.x <= target_x_position :
			get_tree().current_scene.score -= 2
			queue_free()

func _on_body_entered(body: Node2D) -> void:
	
	if body is CharacterBody2D and not is_dead:
		print("hit")
		if body is CharacterBody2D:
			print("击中")
			if body.has_method("take_damage"):
				body.take_damage()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("bullet") and not is_dead:
		can_move = false
		# 90%概率消失，10%概率保留子弹
		if randf() <= bullet_disappear_chance:
			area.queue_free()
		$AnimatedSprite2D.play("death")
		$boom.play()
		is_dead = true
		area.queue_free()
		get_tree().current_scene.score +=4
		# 🟡 添加掉落物逻辑（10% 概率）
		if randi() % 10 < 1 and start_scene:
			$"闪光".play()
			var drop = start_scene.instantiate()
			drop.position = self.position
			get_parent().add_child(drop)
	#等待死亡动画
		await get_tree().create_timer(1.2).timeout
		queue_free()


func _on_area_exited(area: Area2D) -> void:
	if area.is_in_group("player_attack"):
		print("被攻击命中")
		can_move = false
		$AnimatedSprite2D.play("death")
		$boom.play()
		is_dead = true
		get_tree().current_scene.score +=4
		# 🟡 添加掉落物逻辑（10% 概率）
		if randi() % 10 < 1 and start_scene:
			$"闪光".play()
			var drop = start_scene.instantiate()
			drop.position = self.position
			get_parent().add_child(drop)
	#等待死亡动画
		await get_tree().create_timer(1.2).timeout
		queue_free()
