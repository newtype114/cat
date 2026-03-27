extends Area2D
@export var status_label: Label  # 拖拽你的Label节点到这里

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
# 新增：随机数生成相关变量
var random_number: int = 0
var random_timer: float = 0.0
var random_interval: float = 1.5 # 每秒生成一次随机数
# 敌人属性
@export var max_hp: int = 5
var current_hp: int = max_hp:
	set(value):
		current_hp = clamp(value, 0, max_hp)
		update_hp_display()  # HP变化时更新显示


func _ready():
	generate_random_number()
	current_hp = max_hp  # 初始化HP显示

# 更新HP显示
func update_hp_display():
	if status_label:
		status_label.text = "%d/%d" % [current_hp, max_hp]
		if current_hp <= max_hp / 3:
			status_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		else:
			status_label.add_theme_color_override("font_color", Color(1, 1, 1))
			
func _process(delta):
	if not is_dead and can_move:
		# 更新随机数计时器
		random_timer += delta
		if random_timer >= random_interval:
			generate_random_number()
			random_timer = 0.0


# 新增：生成随机数的函数
func generate_random_number():
	random_number = randi() % 100 # 生成0-99的随机数
	#print("生成的随机数: ", random_number) # 调试用，可以删除
	if random_number <= 33:
		get_tree().current_scene.score -= 1
	elif random_number <= 66:
		get_tree().current_scene.score -= 2
	else:
		get_tree().current_scene.score -= 3


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
			
			# 敌人受伤
		current_hp -= 1
		if current_hp <= 0:
			$death.play()
			$AnimatedSprite2D.play("death")
			is_dead = true
			get_tree().current_scene.score +=20
			await get_tree().create_timer(1.2).timeout
			queue_free()
		else:
			$AnimatedSprite2D.play("hit") # 添加受伤动画
			$hit.play()
			await $AnimatedSprite2D.animation_finished
			$AnimatedSprite2D.play("R")
			can_move = true
