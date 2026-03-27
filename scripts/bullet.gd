extends Area2D

@export var bullet_speed : float = 250
var velocity: Vector2 = Vector2.ZERO
var bullet_gravity: float = 0.0  # 0表示直线运动
var lifetime: float = 5.0  # 子弹存在时间
var rotation_speed: float = 15.0 # 旋转平滑速度
var is_persistent: bool = false  # 默认会消失的子弹

var damage: int = 1  # 添加这行声明伤害值


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy"):
		# 对敌人造成伤害
		if area.has_method("take_damage"):
			area.take_damage(damage)
# 只有非持久性子弹才会消失
		if not is_persistent:
			queue_free()

# 设置抛物线参数
func set_parabola_params(initial_velocity: Vector2, gravity_strength: float):
	velocity = initial_velocity
	bullet_gravity = gravity_strength
	# 初始旋转角度（根据初始速度方向）
	# 初始旋转直接设置为速度方向（立即转向，不插值）
	if velocity.length() > 0:
		rotation = velocity.angle()
# 根据当前速度方向更新箭矢旋转
func update_rotation():
	if velocity.length() > 0:
		# 计算速度方向的角度（弧度）
		#var angle = velocity.angle()
		#rotation = angle_rad  # 直接设置旋转角度
		var target_angle: float = velocity.angle()
		rotation = lerp_angle(rotation, target_angle, rotation_speed * get_physics_process_delta_time())

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 如果没有设置抛物线参数，使用默认直线运动
	if velocity == Vector2.ZERO:
		velocity = Vector2(bullet_speed, 0)
	await get_tree().create_timer(lifetime).timeout
	queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# 应用重力（如果有）
	if bullet_gravity > 0:
		var prev_velocity = velocity  # 保存之前的速度用于检测变化
		velocity.y += bullet_gravity * delta
		# 只在速度方向变化显著时更新旋转（优化性能）
		if abs(velocity.angle_to(prev_velocity)) > 0.01:
			update_rotation()
	# 更新位置
	position += velocity * delta
