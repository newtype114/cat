extends CharacterBody2D
# 导出HP Label变量，方便在Godot编辑器里拖拽绑定
@export var hp_label: Label
#signal mp_updated(new_value, max_value)
@export var move_speed : float=150
@export var animator : AnimatedSprite2D
# Called when the node enters the scene tree for the first time.
@export var is_game_over:bool=false
#箭矢变量
@export var bullet_scene : PackedScene
#hp最大值
@export var max_hp : int=3
@export var shoot_cooldown_time : float =1 # 新增：射击冷却时间
@export var bullet_delay : float = 0.5  # 子弹生成延迟时间

#当前hp
var current_hp: int = max_hp
#受伤
var is_hit : bool = false
var can_shoot : bool = true  # 新增：是否允许射击的标志
#僵直
var hit_stun_time : float = 0.5
@export var dash_distance : float = 100  # 冲刺距离
@export var dash_duration : float = 0.2  # 冲刺持续时间
@export var dash_cooldown : float = 1.0  # 冲刺冷却时间
var can_dash : bool = true
var is_dashing : bool = false
var dash_direction : Vector2 = Vector2.ZERO
# 移动边界限制
@export var move_boundary_left : float = -280   # 左边界
@export var move_boundary_right : float = 305  # 右边界（根据你的场景调整）
@export var invincible_during_dash: bool = true  # 是否在冲刺时无敌
var is_invincible: bool = false  # 当前是否无敌
#mp
@export var max_mp: int = 10
@export var mp_regen_per_second: float = 1.0  # MP每秒回复量
@export var shoot2_mp_cost: int = 3  # 每次射击消耗MP
@export var shoot2_cooldown: float = 1.0  # 冷却时间
@export var shoot2_bullet_count: int = 90  # 子弹数量
@export var shoot2_spread_angle: float = 60.0  # 子弹散射角度
@export var shoot2_speed: float = 300.0  # 子弹初速度
@export var shoot2_gravity: float = 300.0  # 子弹重力
var can_shoot2: bool = true
# 第三种射击相关参数
@export var shoot3_mp_cost: int = 2  # 每次射击消耗MP
@export var shoot3_cooldown: float = 1.5  # 冷却时间
@export var shoot3_speed: float = 400.0  # 子弹速度
var can_shoot3: bool = true
# 在导出变量部分添加shoot4相关参数
@export var shoot4_mp_cost: int = 5  # 每次射击消耗MP
@export var shoot4_cooldown: float = 3.0  # 冷却时间
@export var shoot4_speed: float = 200.0  # 子弹速度
var can_shoot4: bool = true
@export var mp_label: Label 
var current_mp: float = max_mp:
	set(value):
		current_mp = clamp(value, 0, max_mp)
func consume_mp(amount: int):
	current_mp -= amount  # 会自动触发信号
func regenerate_mp(delta: float):
	if current_mp < max_mp:
		current_mp += mp_regen_per_second * delta  # 会自动触发信号



func _process(delta):
	if mp_label:
		mp_label.text = "MP: %d/%d" % [current_mp, max_mp]  # 格式化为"当前值/最大值"	
#入场
#func _process(delta: float) -> void:
	if velocity == Vector2.ZERO or is_game_over:
		$run.stop()
	elif not $run.playing:
		$run.play()
# MP自动回复
	if current_mp < max_mp and not is_game_over:
		current_mp = min(current_mp + mp_regen_per_second * delta, max_mp)
		# 可以在这里更新MP UI显示
func _ready():
	add_to_group("player")
	current_hp = max_hp
	

var is_shooting : bool = false
#移动
func _physics_process(delta: float) -> void:
	if is_game_over or is_hit :
		return
	# 处理冲刺
	if not is_dashing and not is_shooting:
	# 检测冲刺输入 (A+左键 或 D+右键)	
		if Input.is_action_just_pressed("dash") and can_dash:
			if Input.is_action_pressed("left"):
				start_dash(Vector2.LEFT)
			elif Input.is_action_pressed("right"):
				start_dash(Vector2.RIGHT)
		# 正常移动
		velocity=Input.get_vector("left","right","up","down")*move_speed
			#播放闲置和跑步动画
		if velocity == Vector2.ZERO:
			animator.play("idle")
		else :
			animator.play("run")
		move_and_slide()
		position.x = clamp(position.x, move_boundary_left, move_boundary_right)
	#检测射击状态
	if Input.is_action_just_pressed("shoot"):
				shoot_bullet()
	# 检测第二种射击
	if Input.is_action_just_pressed("shoot2"):
		shoot_bullet2()
	#检测第三种射击
	if Input.is_action_just_pressed("shoot3"):
		shoot_bullet3()
	#检测第四种射击
	if Input.is_action_just_pressed("shoot4"):
		shoot_bullet4()
#冲刺函数
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
	# 结束无敌状态
	if invincible_during_dash:
		is_invincible = false
		
	
	# 冷却时间
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true			
				
				
func shoot_bullet():
	if bullet_scene and animator and not is_game_over and can_shoot:
		is_shooting = true
		can_shoot = false  # 进入冷却
		animator.play("shoot")
		var shoot_sounds = [$shoot1, $shoot2, $shoot3]
		var random_sound = shoot_sounds[randi() % shoot_sounds.size()]
		random_sound.play()
		await get_tree().create_timer(bullet_delay).timeout# 延迟生成子弹
		# 0.5秒内禁止操作
		var bullet = bullet_scene.instantiate()
		bullet.position = position + Vector2(10,60)
		get_parent().add_child(bullet)
		## 剩余冷却时间
		var remaining_cooldown = shoot_cooldown_time - bullet_delay
		if remaining_cooldown > 0:
			await get_tree().create_timer(remaining_cooldown).timeout
		is_shooting = false
		can_shoot = true
#第二射击
func shoot_bullet2():	
	if bullet_scene == null or animator == null or is_game_over:
		return
	# 检查MP是否足够
	if current_mp < shoot2_mp_cost or not can_shoot2:
		# 可以在这里播放"MP不足"音效
		return
	# 消耗MP
	current_mp -= shoot2_mp_cost
	can_shoot2 = false
	is_shooting = true
	# 播放动画和音效
	animator.play("shoot2")
	var shoot_sounds = [$shoot2_1,$shoot2_2]
	var random_sound = shoot_sounds[randi() % shoot_sounds.size()]
	random_sound.play()
	await get_tree().create_timer(1).timeout
	# 基础向上角度（例如30度向上）
	var base_direction = Vector2(1, -1).normalized()
	await get_tree().create_timer(bullet_delay).timeout
	# 生成多颗抛物线子弹
	for i in range(shoot2_bullet_count):
		var bullet = bullet_scene.instantiate()
		bullet.position = position + Vector2(40, 40)
		# 随机化偏转角度 (-15°到+15°之间随机)
		var angle_offset = randf_range(-shoot2_spread_angle/2, shoot2_spread_angle/2)
		# 随机化初始速度 (80%-120%的基础速度)
		var speed_variation = randf_range(0.8, 1.2)
		var current_speed = shoot2_speed * speed_variation
		# 应用角度偏移和随机速度
		var direction = base_direction.rotated(deg_to_rad(angle_offset))
		var initial_velocity = direction * current_speed
		
		direction = direction.rotated(deg_to_rad(angle_offset))
		#var initial_velocity = direction * shoot2_speed	
		bullet.set_parabola_params(initial_velocity, shoot2_gravity)	

		
		get_parent().add_child(bullet)
		
		# 稍微错开子弹生成时间(可选)
		if i < shoot2_bullet_count - 1:
			await get_tree().create_timer(0.05).timeout
		# 等待动画播放完毕就可以移动
	await animator.animation_finished
	is_shooting = false	
	# 射击冷却在后台继续（不影响移动）
	await get_tree().create_timer(shoot2_cooldown).timeout
	can_shoot2 = true		
	
	
# 第三种射击 - 三方向直线射击
func shoot_bullet3():
	if bullet_scene == null or animator == null or is_game_over:
		return
	# 检查MP是否足够
	if current_mp < shoot3_mp_cost or not can_shoot3:
		return
	# 消耗MP
	current_mp -= shoot3_mp_cost
	can_shoot3 = false
	is_shooting = true
	# 播放特殊射击动画和音效
	animator.play("shoot")
	var shoot_sounds = [$shoot3_1]
	var random_sound = shoot_sounds[randi() % shoot_sounds.size()]
	random_sound.play()
	
	await get_tree().create_timer(bullet_delay).timeout
	
	# 创建三颗不同方向的子弹
	var directions = [
		Vector2(1, -0.5).normalized(),  # 右上
		Vector2(1, 0),   
		Vector2(1, 0.5).normalized()    # 右下
	]
	for direction in directions:
		var bullet = bullet_scene.instantiate()
		bullet.position = position + Vector2(30, 60)
		# 根据bullet.gd的正确方式初始化子弹
		bullet.velocity = direction * shoot3_speed  # 直接设置velocity变量
		bullet.bullet_gravity = 0.0  # 设置为0表示直线运动
		bullet.rotation = direction.angle()  # 设置初始旋转
		
		get_parent().add_child(bullet)
		
	# 等待动画播放完毕
	await animator.animation_finished
	is_shooting = false
	# 射击冷却
	await get_tree().create_timer(shoot3_cooldown).timeout
	can_shoot3 = true
	
# 添加shoot4函数
func shoot_bullet4():
	if bullet_scene == null or animator == null or is_game_over:
		return
	# 检查MP是否足够
	if current_mp < shoot4_mp_cost or not can_shoot4:
		# 可以在这里播放"MP不足"音效
		return
	# 消耗MP
	current_mp -= shoot4_mp_cost
	can_shoot4 = false
	is_shooting = true
	# 播放特殊射击动画和音效
	animator.play("shoot4")
	var shoot_sounds = [$shoot4_1]
	var random_sound = shoot_sounds[randi() % shoot_sounds.size()]
	random_sound.play()
	# 等待动画播放到合适时间生成子弹
	await get_tree().create_timer(0.5).timeout
	# 创建特殊子弹
	var bullet = bullet_scene.instantiate()
	# 设置子弹位置（向右上方偏移）
	bullet.position = position + Vector2(40, 30)
	# 设置子弹属性
	bullet.velocity = Vector2.RIGHT * shoot4_speed  # 向右发射
	bullet.bullet_gravity = 0.0  # 直线运动
	bullet.rotation = 0  # 朝向右侧
	# 放大3倍
	bullet.scale = Vector2(3, 3)
	# 标记为特殊子弹（不消失）
	bullet.is_persistent = true  # 需要在bullet.gd中添加这个变量
	# 添加到场景
	get_parent().add_child(bullet)
	# 等待动画播放完毕
	await animator.animation_finished
	is_shooting = false
	# 射击冷却
	await get_tree().create_timer(shoot4_cooldown).timeout
	can_shoot4 = true
	
	

	
#受伤函数
func take_damage():
	if is_game_over or is_hit or is_invincible:  # 添加无敌状态检查
		return
	current_hp -= 1
	is_hit = true
	if current_hp <= 0:
		current_hp = 0
		game_over()
	else :
		animator.play("hited")
		var shoot_sounds = [$hited1,$hited2,$hited3]
		var random_sound = shoot_sounds[randi() % shoot_sounds.size()]
		random_sound.play()
		await get_tree().create_timer(hit_stun_time).timeout
		is_hit = false


func game_over():
	is_game_over=true
	get_tree().current_scene.show_game_over()
	animator.play("death")
	var shoot_sounds = [$death1,$death2,$death3]
	var random_sound = shoot_sounds[randi() % shoot_sounds.size()]
	random_sound.play()
	await get_tree().create_timer(3).timeout
	get_tree().reload_current_scene()
