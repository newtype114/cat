extends Node2D

@export var cat_scene : PackedScene
@export var speed_cat_scene : PackedScene
@export var r_cat_scene : PackedScene
@export var score : int = 0
@export var score_label : Label
@export var game_over_label : Label
@export var level_clear_panel : Control
@export var finish_label : Node
# 跟踪当前r_cat数量
var current_r_cats := 0
const MAX_R_CATS := 3

#  新增：关卡系统变量
var current_level := 1
var level_running := true
var target_score := 10

#  可选统计
var cats_killed := 0
var speed_cats_killed := 0
var r_cats_escaped := 0
# 加速控制
var spawn_speedup_timer := 0.0
var speedup_interval := 5.0  # 每5秒尝试加速一次
var timer_min_wait := 0.8  # 每种怪物生成的最短间隔

# 初始时间间隔
var timer1_start_wait := 2.5
var timer2_start_wait := 4.5
var timer3_start_wait := 8.5


#  新增结束
func _unhandled_input(event: InputEvent) -> void:
	if level_clear_panel.visible and event.is_action_pressed("ui_accept"):
		_on_next_level_button_pressed()



func _ready() -> void:
	var bgms = [$bgm2]
	#var bgms = [$"BGM(hy)"]
	var selected_bgm = bgms[randi() % bgms.size()]
	selected_bgm.play()
	
	update_target_score()
	_start_level_timers()

	# ✅ 正确连接 LevelClearUI 的信号
	level_clear_panel.next_level_pressed.connect(_on_next_level_button_pressed)

	level_clear_panel.visible = false
	
	
	#var next_button = level_clear_panel.get_node("NextLevelButton")
	#next_button.pressed.connect(_on_next_level_button_pressed)
	#level_clear_panel.visible = false
	
	
func  _process(delta: float) -> void:
	
	score_label.text = "得分：" + str(score)
	if score > 300 :
		finish_label.visible = true  # 显示 finish 节点
		await get_tree().create_timer(1.5).timeout
		get_tree().change_scene_to_file("res://scenes/end.tscn")
	
	# ⬇️ 新增：检查是否达成本关目标分数
	if level_running and score >= target_score:
		_end_level()
	# ⬇️ 怪物生成速度逐渐加快
	if level_running:
		spawn_speedup_timer += delta
		if spawn_speedup_timer >= speedup_interval:
			spawn_speedup_timer = 0
			_speed_up_timers()
			
func _speed_up_timers():
	if $Timer.is_stopped() == false:
		$Timer.wait_time = max(timer_min_wait, $Timer.wait_time - 0.2)
	if $Timer2.is_stopped() == false:
		$Timer2.wait_time = max(timer_min_wait, $Timer2.wait_time - 0.3)
	if $Timer3.is_stopped() == false:
		$Timer3.wait_time = max(timer_min_wait, $Timer3.wait_time - 0.4)

	print("加速出怪：Timer间隔 =>", $Timer.wait_time, $Timer2.wait_time, $Timer3.wait_time)
# ⬇️ 新增：设置每关目标分数
func update_target_score():
	match current_level:
		1:
			target_score = 20
		2:
			target_score = 40
		3:
			target_score = 500
		_:
			show_game_over()

# ⬇️ 新增：结算并暂停游戏
func _end_level():
	level_running = false
	$Timer.stop()
	$Timer2.stop()
	$Timer3.stop()
# 🆕 播放玩家胜利动画（路径根据实际结构调整）
	var player = get_node("Player")  # 如果不是主场景直接子节点，请用相对路径，比如 $Main/Player
	player.get_node("AnimatedSprite2D").play("win")  # 或者 "AnimationPlayer".play("win")

	level_clear_panel.visible = true
	level_clear_panel.get_node("Label").text = "关卡 " + str(current_level) + " 完成！\n得分：" + str(score)




func _spawn_cat() -> void:
	var cat_node = cat_scene.instantiate()
	cat_node.position = Vector2(340, randf_range(30, 150))
	get_tree().current_scene.add_child(cat_node)


func _speed_cat() -> void:
	var speed_cat_node = speed_cat_scene.instantiate()
	speed_cat_node.position = Vector2(340, randf_range(30, 150))
	get_tree().current_scene.add_child(speed_cat_node)

func show_game_over():
	game_over_label.visible = true
	

func _r_cat() -> void:
	if current_r_cats >= MAX_R_CATS:
		print("已达到最大r_cat数量限制")
		return
	var r_cat_node = r_cat_scene.instantiate()
	$"吼叫".play()
	r_cat_node.position = Vector2(randi_range(30,270),randf_range(-123,10))
	get_tree().current_scene.add_child(r_cat_node)
	# ✅ 增加数量
	current_r_cats += 1
	print("r_cat 生成，当前数量：", current_r_cats)

	# ✅ 连接销毁信号，监听其被销毁时的 tree_exited 事件
	r_cat_node.connect("tree_exited", Callable(self, "_on_r_cat_exited"))
# ✅ 当 r_cat 被销毁时自动减少计数
func _on_r_cat_exited() -> void:
	current_r_cats = max(current_r_cats - 1, 0)
	print("r_cat 被销毁，当前数量：", current_r_cats)


func _start_level_timers():
	$Timer.stop()
	$Timer2.stop()
	$Timer3.stop()
	$Timer.wait_time = timer1_start_wait
	$Timer2.wait_time = timer2_start_wait
	$Timer3.wait_time = timer3_start_wait
	match current_level:
		1:
			$Timer.start()  # 只出普通cat
		2:
			$Timer.start()
			$Timer2.start()  # 加入speed_cat
		3:
			$Timer.start()
			$Timer2.start()
			$Timer3.start()  # 加入r_cat
		_:
			show_game_over()



func _on_next_level_button_pressed() -> void:
	level_clear_panel.visible = false
	current_level += 1
	score = 0
	current_r_cats = 0
	update_target_score()
	level_running = true
	spawn_speedup_timer = 0  # 重置加速计时器

	_start_level_timers()
	print("下一关按钮被点击")
