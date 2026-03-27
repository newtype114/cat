extends Node2D
@export var score : int = 0
@export var score_label : Label
@export var game_over_label : Label
@export var cat_scene : PackedScene
@export var speed_cat_scene : PackedScene
@export var finish_label : Node
# 添加两个计时器变量
var cat_timer := 0.0       # 普通猫生成计时器
var speed_cat_timer := 0.0 # Speed Cat生成计时器

# 设置生成间隔（初始值）
var CAT_INTERVAL := 1.0    # 普通猫生成间隔（秒）
var SPEED_CAT_INTERVAL := 3.0  # Speed Cat生成间隔（秒）

var spawn_speedup_timer := 0.0
var speedup_interval := 5.0  # 每5秒尝试加速一次
var timer_min_wait := 0.8  # 每种怪物生成的最短间隔
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#var bgms = [$bgm]
	var bgms = [$bgm2]
	var selected_bgm = bgms[randi() % bgms.size()]
	selected_bgm.play()
	# 初始化计时器
	cat_timer = CAT_INTERVAL
	speed_cat_timer = SPEED_CAT_INTERVAL	
	#update_target_score()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	score_label.text = "当前得分：" + str(score)
	# ★ 检查分数是否超过 100
	if score > 800 :
		finish_label.visible = true  # 显示 finish 节点
		await get_tree().create_timer(1.5).timeout
		get_tree().change_scene_to_file("res://scenes/end.tscn")
	# 更新普通猫计时器
	cat_timer -= delta
	if cat_timer <= 0:
		_spawn_cat()  # 生成普通猫
		cat_timer = CAT_INTERVAL  # 重置计时器
	
	# 更新Speed Cat计时器
	speed_cat_timer -= delta
	if speed_cat_timer <= 0:
		_speed_cat()  # 生成Speed Cat
		speed_cat_timer = SPEED_CAT_INTERVAL  # 重置计时器	
	# 加速逻辑
	spawn_speedup_timer += delta
	if spawn_speedup_timer >= speedup_interval:
		spawn_speedup_timer = 0
		# 加速两种猫的生成
		CAT_INTERVAL = max(timer_min_wait, CAT_INTERVAL - 0.1)  # 普通猫每次减少0.1秒间隔
		SPEED_CAT_INTERVAL = max(timer_min_wait, SPEED_CAT_INTERVAL - 0.2)  # Speed Cat每次减少0.2秒间隔



func _spawn_cat() -> void:
	var cat_node = cat_scene.instantiate()
	cat_node.position = Vector2(1170, randf_range(160, 630))
	get_tree().current_scene.add_child(cat_node)


func _speed_cat() -> void:
	var speed_cat_node = speed_cat_scene.instantiate()
	speed_cat_node.position = Vector2(1170, randf_range(160, 630))
	get_tree().current_scene.add_child(speed_cat_node)
