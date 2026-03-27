extends CharacterBody2D
# 添加UI Label引用
@export var status_label: Label  # 拖拽你的Label节点到这里
@export var hp_bar: TextureProgressBar
@export var mp_bar: TextureProgressBar
# 移动相关
@export var move_speed : float = 150
@export var animator : AnimatedSprite2D
@export var is_game_over: bool = false

# 战斗相关
@export var bullet_scene : PackedScene
@export var max_hp : int = 5
@export var shoot_cooldown_time : float = 1
@export var bullet_delay : float = 0.5

var current_hp: int = max_hp:
	set(value):
		current_hp = clamp(value, 0, max_hp)
		_update_status()  # 数值变化时更新显示


# MP系统
@export var max_mp: int = 15
@export var mp_regen_per_second: float = 0.5
var current_mp: float = max_mp:
	set(value):
		current_mp = clamp(value, 0, max_mp)
		_update_status()  # 数值变化时更新显示

# 其他战斗变量
var is_hit : bool = false
var can_shoot : bool = true
var hit_stun_time : float = 0.5
var is_shooting : bool = false

# 冲刺系统
@export var dash_distance : float = 100
@export var dash_duration : float = 0.2
@export var dash_cooldown : float = 1.0
var can_dash : bool = true
var is_dashing : bool = false
var dash_direction : Vector2 = Vector2.ZERO

# 边界限制
@export var move_boundary_left : float = -280
@export var move_boundary_right : float = 305
@export var invincible_during_dash: bool = true
var is_invincible: bool = false

# 特殊射击技能
@export var shoot2_mp_cost: int = 10
@export var shoot2_cooldown: float = 10.0
@export var shoot2_bullet_count: int = 90
@export var shoot2_spread_angle: float = 60.0
@export var shoot2_speed: float = 300.0
@export var shoot2_gravity: float = 300.0
var can_shoot2: bool = true

@export var shoot3_mp_cost: int = 1
@export var shoot3_cooldown: float = 0
@export var shoot3_speed: float = 500.0
var can_shoot3: bool = true

@export var shoot4_mp_cost: int = 3
@export var shoot4_cooldown: float = 3.0
@export var shoot4_speed: float = 200.0
var can_shoot4: bool = true
var is_victory := false

@export var bomb_count: int = 3  # 初始有3个炸弹


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

func play_victory_animation():
	is_victory = true
	$AnimatedSprite2D.play("win") 
	
	
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
		



func _ready():
	add_to_group("player")
	current_hp = max_hp
	current_mp = max_mp
	_update_status()
	

func _process(delta):
	if is_victory:
		return
	# MP自动回复
	if current_mp < max_mp and not is_game_over:
		current_mp = min(current_mp + mp_regen_per_second * delta, max_mp)
	
	# 跑步音效控制
	if velocity == Vector2.ZERO or is_game_over:
		$run.stop()
	elif not $run.playing:
		$run.play()

func _physics_process(delta: float) -> void:
	if is_game_over or is_hit:
		return
	
	# 处理冲刺
	if not is_dashing and not is_shooting:
		if Input.is_action_just_pressed("dash") and can_dash:
			if Input.is_action_pressed("left"):
				start_dash(Vector2.LEFT)
			elif Input.is_action_pressed("right"):
				start_dash(Vector2.RIGHT)
		
		# 正常移动
		velocity = Input.get_vector("left","right","up","down") * move_speed
		
		# 播放闲置和跑步动画
		if velocity == Vector2.ZERO:
			animator.play("idle")
		else:
			animator.play("run")
		
		move_and_slide()
		position.x = clamp(position.x, move_boundary_left, move_boundary_right)
	
	# 检测射击状态
	if Input.is_action_just_pressed("shoot"):
		shoot_bullet()
	if Input.is_action_just_pressed("shoot2"):
		shoot_bullet2()
	if Input.is_action_just_pressed("shoot3"):
		shoot_bullet3()
	if Input.is_action_just_pressed("shoot4"):
		shoot_bullet4()
	if Input.is_action_just_pressed("shoot5"):
		shoot_bullet5()


# 冲刺函数
func start_dash(direction: Vector2):
	if not can_dash or is_dashing:
		return
		
	is_dashing = true
	can_dash = false
	dash_direction = direction
	if invincible_during_dash:
		is_invincible = true
	animator.play("dash")
	
	# 计算目标位置
	var target_position = position + (dash_direction * dash_distance)
	target_position.x = clamp(target_position.x, move_boundary_left, move_boundary_right)
	
	# 使用Tween实现平滑冲刺
	var tween = create_tween()
	tween.tween_property(self, "position", target_position, dash_duration)
	
	# 冲刺结束后恢复状态
	await get_tree().create_timer(dash_duration).timeout
	is_dashing = false
	if invincible_during_dash:
		is_invincible = false
		
	# 冷却时间
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true

# 基础射击
func shoot_bullet():
	if bullet_scene and animator and not is_game_over and can_shoot:
		is_shooting = true
		can_shoot = false
		animator.play("shoot")
		var shoot_sounds = [$shoot1, $shoot2, $shoot3]
		var random_sound = shoot_sounds[randi() % shoot_sounds.size()]
		random_sound.play()
		
		await get_tree().create_timer(bullet_delay).timeout
		var bullet = bullet_scene.instantiate()
		bullet.position = position + Vector2(10,60)
		get_parent().add_child(bullet)
		
		var remaining_cooldown = shoot_cooldown_time - bullet_delay
		if remaining_cooldown > 0:
			await get_tree().create_timer(remaining_cooldown).timeout
		is_shooting = false
		can_shoot = true

# 第二种射击
func shoot_bullet2():    
	if bullet_scene == null or animator == null or is_game_over:
		return
	if current_mp < shoot2_mp_cost or not can_shoot2:
		return
	
	current_mp -= shoot2_mp_cost
	can_shoot2 = false
	is_shooting = true
	animator.play("shoot2")
	is_invincible = true  # 进入无敌状态，在动画期间不受伤害
	var shoot_sounds = [$shoot2_1,$shoot2_2]
	var random_sound = shoot_sounds[randi() % shoot_sounds.size()]
	random_sound.play()
	
	await get_tree().create_timer(1).timeout
	var base_direction = Vector2(1, -1).normalized()
	await get_tree().create_timer(bullet_delay).timeout
	
	for i in range(shoot2_bullet_count):
		var bullet = bullet_scene.instantiate()
		bullet.position = position + Vector2(40, 40)
		var angle_offset = randf_range(-shoot2_spread_angle/2, shoot2_spread_angle/2)
		var speed_variation = randf_range(0.8, 1.2)
		var current_speed = shoot2_speed * speed_variation
		var direction = base_direction.rotated(deg_to_rad(angle_offset))
		var initial_velocity = direction * current_speed
		bullet.set_parabola_params(initial_velocity, shoot2_gravity)    
		get_parent().add_child(bullet)
		
		if i < shoot2_bullet_count - 1:
			await get_tree().create_timer(0.05).timeout
	
	await animator.animation_finished
	is_shooting = false    
	is_invincible = false  # 动画结束后，取消无敌状态
	await get_tree().create_timer(shoot2_cooldown).timeout
	can_shoot2 = true

# 第三种射击
func shoot_bullet3():
	if bullet_scene == null or animator == null or is_game_over:
		return
	if current_mp < shoot3_mp_cost or not can_shoot3:
		return
	
	current_mp -= shoot3_mp_cost
	can_shoot3 = false
	is_shooting = true
	animator.play("shoot")
	var shoot_sounds = [$shoot3_1]
	var random_sound = shoot_sounds[randi() % shoot_sounds.size()]
	random_sound.play()
	
	await get_tree().create_timer(bullet_delay).timeout
	
	var directions = [
		Vector2(1, -0.5).normalized(),
		Vector2(1, 0),   
		Vector2(1, 0.5).normalized()
	]
	for direction in directions:
		var bullet = bullet_scene.instantiate()
		bullet.position = position + Vector2(30, 60)
		bullet.velocity = direction * shoot3_speed
		bullet.bullet_gravity = 0.0
		bullet.rotation = direction.angle()
		get_parent().add_child(bullet)
	
	await animator.animation_finished
	is_shooting = false
	await get_tree().create_timer(shoot3_cooldown).timeout
	can_shoot3 = true

# 第四种射击
func shoot_bullet4():
	if bullet_scene == null or animator == null or is_game_over:
		return
	if current_mp < shoot4_mp_cost or not can_shoot4:
		return
	
	current_mp -= shoot4_mp_cost
	can_shoot4 = false
	is_shooting = true
	animator.play("shoot4")
	var shoot_sounds = [$shoot4_1]
	var random_sound = shoot_sounds[randi() % shoot_sounds.size()]
	random_sound.play()
	
	await get_tree().create_timer(0.5).timeout
	# 发射5颗叠在一起的子弹
	for i in range(5):
		var bullet = bullet_scene.instantiate()
		bullet.is_persistent = true
		# 使用相同位置使子弹重叠
		bullet.position = position + Vector2(40, 30)
		bullet.velocity = Vector2.RIGHT * shoot4_speed
		bullet.bullet_gravity = 0.0
		bullet.rotation = 0
		bullet.scale = Vector2(3, 3)
		get_parent().add_child(bullet)
	# 添加微小延迟避免完全重叠（可选）
		await get_tree().create_timer(0.01).timeout
	await animator.animation_finished
	is_shooting = false
	await get_tree().create_timer(shoot4_cooldown).timeout
	can_shoot4 = true

#第五种射击
func shoot_bullet5():
	if bomb_count <= 0 or is_game_over:
		return
	if not animator:
		return

	bomb_count -= 1
	_update_status()
	is_shooting = true
	animator.play("shoot4")
	
	get_tree().current_scene.score -=15
	await get_tree().create_timer(0.5).timeout
	$shoot5.play()  # 可选音效节点（需在场景中添加 AudioStreamPlayer 命名为 shoot5）
	# 等待动画播放完成
	await animator.animation_finished
	
	# 清除所有敌人（假设敌人都有 enemy 群组）
	var enemies = get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if e and e.has_method("queue_free"):
			e.queue_free()

	is_shooting = false


# 受伤函数
func take_damage(amount: int = 1):
	if is_game_over or is_hit or is_invincible:
		return
	
	current_hp -= amount
	is_hit = true
	
	if current_hp <= 0:
		current_hp = 0
		game_over()
	else:
		animator.play("hited")
		var shoot_sounds = [$hited1, $hited2, $hited3]
		var random_sound = shoot_sounds[randi() % shoot_sounds.size()]
		random_sound.play()
		await get_tree().create_timer(hit_stun_time).timeout
		is_hit = false

func game_over():
	is_game_over = true
	get_tree().current_scene.show_game_over()
	animator.play("death")
	var shoot_sounds = [$death1,$death2,$death3]
	var random_sound = shoot_sounds[randi() % shoot_sounds.size()]
	random_sound.play()
	await get_tree().create_timer(3).timeout
	get_tree().reload_current_scene()

# MP消耗函数
func consume_mp(amount: int):
	current_mp -= amount

# 受伤函数
