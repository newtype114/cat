extends CharacterBody2D
# 添加UI Label引用
@export var status_label: Label  # 拖拽你的Label节点到这里
@export var hp_bar: TextureProgressBar
@export var mp_bar: TextureProgressBar
# 移动相关
@export var move_speed : float = 300
@export var animator : AnimatedSprite2D
@export var is_game_over: bool = false
var is_attacking := false  # 是否处于攻击中
var can_move := true  # 控制是否允许移动，独立于 is_attacking
# 战斗相关
@export var bullet_scene : PackedScene
@export var light_sword_scene: PackedScene
@export var max_hp : int = 15
@export var shoot_cooldown_time : float = 1
@export var bullet_delay : float = 0.5
var current_hp: int = max_hp:
	set(value):
		current_hp = clamp(value, 0, max_hp)
		_update_status()  # 数值变化时更新显示
# 冲刺系统
@export var dash_distance : float = 100
@export var dash_duration : float = 0.2
@export var dash_cooldown : float = 1.0
var can_dash : bool = true
var is_dashing : bool = false
var dash_direction : Vector2 = Vector2.ZERO
# --- 受伤状态（你添加的） ---
var is_hit := false
@export var hit_stun_time: float = 0.5
@onready var attack_area2: Area2D = $AttackArea2
# 边界限制
@export var move_boundary_left : float = -280
@export var move_boundary_right : float = 305
@export var invincible_during_dash: bool = true
var is_invincible: bool = false


# MP系统
@export var max_mp: int = 15
@export var mp_regen_per_second: float = 0.5
@export var bomb_count: int = 3  # 初始有3个炸弹
var current_mp: float = max_mp:
	set(value):
		current_mp = clamp(value, 0, max_mp)
		_update_status()  # 数值变化时更新显示

func add_hp(amount: int):
	#音效添加
	current_hp += amount
func has_variable(var_name: String) -> bool:
	return var_name in self
# 增加最大 MP 并回满 MP
func add_mp(amount: int = 1):
	max_mp += amount
	current_mp = max_mp
	print("mp up")
	_update_status()

func _ready() -> void:
	$AttackArea.monitoring = false
	$AttackArea/CollisionShape2D.disabled = true  # 初始化时禁用碰撞体
	$AttackArea.add_to_group("player_attack")
	$AttackArea2.monitoring = false  # 初始化时禁用AttackArea2
	$AttackArea2/CollisionShape2D.disabled = true  # 禁用碰撞体
	$AttackArea2.add_to_group("player_attack")
	animator.animation_finished.connect(_on_attack_animation_finished) # ✅只连一次
	_update_status()
func _update_status():
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = current_hp
		if current_hp <= max_hp / 3:
			hp_bar.tint_progress = Color(1, 0.3, 0.3)  # 红色警告
		else:
			hp_bar.tint_progress = Color(1, 0, 0)

	if mp_bar:
		mp_bar.max_value = max_mp
		mp_bar.value = current_mp
		if current_mp <= max_mp / 4:
			mp_bar.tint_progress = Color(0.6, 0.6, 1)  # 蓝色偏灰
		else:
			mp_bar.tint_progress = Color(0.3, 0.3, 1)
			mp_bar.max_value = max_mp
	
	if status_label:
		# 使用图标+数值的简洁显示方式
		var hp_text = "♥%d/%d" % [current_hp, max_hp]
		var mp_text = "✦%d/%d" % [int(current_mp), max_mp]
		var bomb_text = "☢%d" % bomb_count  # 或 💣

		# 组合显示
		status_label.text = "%s   %s   %s" % [hp_text, mp_text, bomb_text]
		# 低数值警告色
		if current_hp <= max_hp / 3:
			status_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		elif current_mp <= max_mp / 4:
			status_label.add_theme_color_override("font_color", Color(0.5, 0.5, 1))
		else:
			status_label.add_theme_color_override("font_color", Color(1, 1, 1))
		
func _physics_process(delta: float) -> void:
	if is_game_over or is_attacking or is_dashing or is_hit: 
		return

	# 冲刺输入处理（替代 _process 中的部分）
	if Input.is_action_just_pressed("dash") and can_dash:
		if Input.is_action_pressed("left"):
			start_dash(Vector2.LEFT)
		elif Input.is_action_pressed("right"):
			start_dash(Vector2.RIGHT)

	# 正常移动
	if can_move:
		var input_vector = Input.get_vector("left", "right", "up", "down")
		velocity = input_vector * move_speed
		move_and_slide()

		# 动画控制
		if not is_attacking:
			if input_vector != Vector2.ZERO:
				if !animator.is_playing() or animator.animation != "run":
					animator.play("run")
				animator.flip_h = input_vector.x < 0
			else:
				if animator.animation != "待机":
					animator.play("待机")
	if Input.is_action_just_pressed("shoot5"):
		shoot_bullet5()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("shoot4") and not is_attacking and not is_game_over and not is_hit:
		if current_mp >= 8:
			start_attack4()
		else:
			print("MP不足，无法释放攻击4")
	# ==== 新增：释放 atk2 攻击（特殊攻击）====
	if Input.is_action_just_pressed("shoot3") and not is_attacking and not is_game_over:
		if current_mp >= 3:
			start_attack2()
		else:
			print("MP不足，无法释放特殊攻击")
		return
	if is_hit:  
		return
	# ==== 新增：攻击输入处理 ====
	if Input.is_action_just_pressed("shoot") and not is_attacking:
		start_attack()
		return  # 攻击期间不允许移动
		# MP自动回复（✅ 从原主角脚本整合）
	if current_mp < max_mp and not is_game_over:
		current_mp = min(current_mp + mp_regen_per_second * delta, max_mp)
	if Input.is_action_just_pressed("shoot2") and not is_attacking and not is_game_over and not is_hit:
		if current_mp >= 10:  # 设置MP消耗
			start_attack3()			
# 冲刺函数（新增）
func start_dash(direction: Vector2):
	if not can_dash or is_dashing:
		return
	is_dashing = true
	can_dash = false
	dash_direction = direction
	if invincible_during_dash:
		is_invincible = true
	#animator.play("dash")

	var target_position = position + (dash_direction * dash_distance)
	target_position.x = clamp(target_position.x, move_boundary_left, move_boundary_right)

	var tween = create_tween()
	tween.tween_property(self, "position", target_position, dash_duration)

	await get_tree().create_timer(dash_duration).timeout
	is_dashing = false
	if invincible_during_dash:
		is_invincible = false

	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true


func start_attack():
	is_attacking = true
	animator.play("atk")       # 播放攻击动画
	var bgms = [$"atk1-1",$"atk1-2",$"atk1-3"]
	var selected_bgm = bgms[randi() % bgms.size()]
	selected_bgm.play()
	await get_tree().create_timer(0.1).timeout
	$AttackArea.monitoring = true  # 开启攻击检测
	$AttackArea/CollisionShape2D.disabled = false  #  启用碰撞形状
	can_move = false

func start_attack2():
	if is_attacking or current_mp < 3:
		return  # MP不足或已在攻击中

	is_attacking = true
	can_move = false
	is_invincible = true  # 进入无敌状态
	current_mp -= 3
	animator.play("atk2")
	$atk2.play()

	await get_tree().create_timer(2).timeout  # 动画长度（根据需要调整）
	
	# 恢复HP，但不超过上限
	current_hp = min(current_hp + 5, max_hp)
	is_attacking = false
	can_move = true
	is_invincible = false

func start_attack3():
	if is_attacking or current_mp < 10:
		return  # 已在攻击中或MP不足
	is_attacking = true
	can_move = false
	is_invincible = true  # 开启无敌状态
	current_mp -= 10  # 消耗MP
	# 播放攻击动画
	animator.play("atk3")
	var shoot_sounds = [$"atk3-1",$"atk3-2",$"atk3-3"]
	var random_sound = shoot_sounds[randi() % shoot_sounds.size()]
	random_sound.play()
	await get_tree().create_timer(1.0).timeout

	# 开启AttackArea2的判定
	$AttackArea2.monitoring = true
	$AttackArea2/CollisionShape2D.disabled = false
	
	# 等待2秒后结束攻击
	await get_tree().create_timer(2.0).timeout
	
	# 关闭AttackArea2的判定
	$AttackArea2.monitoring = false
	$AttackArea2/CollisionShape2D.disabled = true
	
	# 恢复状态
	is_attacking = false
	can_move = true
	is_invincible = false

func start_attack4():
	if is_attacking or current_mp < 8:
		return

	current_mp -= 8
	is_attacking = true
	can_move = false
	is_invincible = true

	animator.play("atk4")
	#$atk4.play()  # 若你有音效，可取消注释

	# 等待动画播放完成（使用 `animation_finished` 信号，建议动画名唯一）
	await animator.animation_finished

	# 攻击前摇结束，恢复操作权
	is_attacking = false
	can_move = true
	is_invincible = false

	# 启动异步生成过程（不阻塞其他操作）
	spawn_light_swords()

func shoot_bullet5():
	if bomb_count <= 0:
		return
	if not animator:
		return

	bomb_count -= 1
	_update_status()
	#is_shooting = true
	#animator.play("shoot5")
	
	get_tree().current_scene.score -=15
	await get_tree().create_timer(0).timeout
	$Boom.play()# 可选音效节点（需在场景中添加 AudioStreamPlayer 命名为 shoot5）
	# 等待动画播放完成
	#await animator.animation_finished
	
	# 清除所有敌人（假设敌人都有 enemy 群组）
	var enemies = get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if e and e.has_method("queue_free"):
			e.queue_free()

	#is_shooting = false


# 受伤函数
func take_damage(amount: int = 1):
	if is_game_over or is_hit or is_invincible:
		return
	
	current_hp -= amount
	is_hit = true
	can_move = false    # 禁止移动
	is_attacking = false# 强制中断攻击
	
	if current_hp <= 0:
		current_hp = 0
		game_over()
	else:
		animator.play("hited")
		var shoot_sounds = [$hited1, $hited2, $hited3]
		var random_sound = shoot_sounds[randi() % shoot_sounds.size()]
		random_sound.play()
		await get_tree().create_timer(0.5).timeout
		is_hit = false
		can_move = true

func game_over():
	is_game_over = true
	get_tree().current_scene.show_game_over()
	animator.play("death")
	var shoot_sounds = [$death1,$death2,$death3]
	var random_sound = shoot_sounds[randi() % shoot_sounds.size()]
	random_sound.play()
	await get_tree().create_timer(3).timeout
	get_tree().reload_current_scene()
# ==== 新增：攻击结束回调 ====
func _on_attack_animation_finished():
	# 确保是攻击动画结束才处理
	if animator.animation == "atk":
		$AttackArea.monitoring = false  # 关闭攻击判定
		$AttackArea/CollisionShape2D.disabled = true  # ✅ 禁用碰撞形状
		is_attacking = false        # 恢复非攻击状态
		can_move = true  # 恢复移动

func spawn_light_swords():
	var center_position = global_position + Vector2(0, -80)  # 角色头顶上方

	for i in range(15):
		var offset_x = randf_range(-275, 275)  # 控制生成范围在你角色中心 ±275 像素
		var offset_y = randf_range(-20, 130)
		var spawn_position = center_position + Vector2(offset_x, offset_y)

		var sword = light_sword_scene.instantiate()
		get_parent().add_child(sword)
		sword.global_position = spawn_position

		await get_tree().create_timer(0.8).timeout  # 每把剑间隔 0.1s 生成（你可以调大调小）
