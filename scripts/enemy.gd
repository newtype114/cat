extends Area2D
@export var cat_speed : float = -100
# Called when the node enters the scene tree for the first time.
@export var is_dead : bool = false
@export var breath_chance : float = 0.05#每秒哈气概率
var is_breathing : bool = false
var normal_speed := Vector2.ZERO
@export var min_y_position : float = 20#y限制范围
@export var max_y_position : float = 150    # 最大Y边界
@export var bullet_disappear_chance : float = 0.9 # 子弹消失概率
@export var target_x_position : float = -350  # 新增：触发扣分的X坐标位置
@export var health : int = 3  # 新增：怪物生命值
#掉落相关
@export var heart_scene: PackedScene #掉落心
@export var bomb_scene: PackedScene  # 掉落炸弹

func take_damage(amount: int = 1):  # 新增：处理伤害的方法
	if is_dead:
		return
		
	health -= amount
	if health <= 0:
		die()
		
func die():  # 新增：死亡处理
	$AnimatedSprite2D.play("cat_death")
	is_dead = true
	$death.play()

	# 生成 1~10 的随机整数
	var rand_num = randi_range(1, 10)
	print("生成的随机数为：", rand_num)

	if rand_num < 2 and heart_scene:
		var heart = heart_scene.instantiate()
		heart.global_position = global_position
		get_tree().current_scene.add_child(heart)
		print("掉落Heart！")
	elif rand_num <= 3 and bomb_scene:
		var bomb = bomb_scene.instantiate()
		bomb.global_position = global_position
		get_parent().add_child(bomb)
		print("掉落炸弹！")

	await get_tree().create_timer(1.2).timeout
	queue_free()
func _ready():
	normal_speed = Vector2(randf_range(-100,-50), randf_range(-50,50))

	$AnimatedSprite2D.play("run")  # 强制播放移动动画

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# ===【新增】哈气触发逻辑===
	if not is_breathing and randf() < breath_chance * delta:
		is_breathing = true
		$"哈气".play()
		$AnimatedSprite2D.play("哈气")
		await $AnimatedSprite2D.animation_finished
		is_breathing = false
		cat_speed *= 1.5  # 加速
		$AnimatedSprite2D.play("run")

	if not is_dead and not is_breathing:
		position += Vector2(cat_speed,randf_range(-50,50))*delta
	if position.x <= target_x_position :
		get_tree().current_scene.score -= 2
		queue_free()
		
		
#碰撞检测
func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and not is_dead:
		print("hit")
		if body is CharacterBody2D:
			print("击中")
			if body.has_method("take_damage"):
				body.take_damage()
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_attack"):
		#print("被攻击命中")
		die()
		get_tree().current_scene.score +=3
	if area.is_in_group("bullet") and not is_dead:
		# 如果是持久性子弹（shoot4发射的）
		if area.has_method("is_persistent") and area.is_persistent:
			# 调用take_damage方法并传递伤害值
			if has_method("take_damage"):
				take_damage(area.damage)
		else:
			# 普通子弹处理
			if randf() <= bullet_disappear_chance:
				area.queue_free()
				get_tree().current_scene.score +=3
			die()
