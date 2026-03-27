extends Area2D

# 设置移动速度（像素/秒）
var speed = Vector2(400, 400)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 创建并启动5秒计时器
	var timer = Timer.new()
	timer.wait_time = 5.0
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "queue_free"))
	add_child(timer)
	timer.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# 每帧向右下方向移动
	position += speed * delta
