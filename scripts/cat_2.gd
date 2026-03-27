extends Area2D
@export var cat_speed : float = -100
# Called when the node enters the scene tree for the first time.
@export var is_dead : bool = false
@export var breath_chance : float = 0.005#每秒哈气概率
var is_breathing : bool = false
var normal_speed := Vector2.ZERO
@export var min_y_position : float = 20#y限制范围
@export var max_y_position : float = 150    # 最大Y边界
@export var bullet_disappear_chance : float = 0.9 # 子弹消失概率
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	normal_speed = Vector2(randf_range(-100,-50), randf_range(-50,50))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		if body is CharacterBody2D:
			if body.has_method("take_damage"):
				body.take_damage()
				
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("bullet") and not is_dead:
		# 90%概率消失，10%概率保留子
		if randf() <= bullet_disappear_chance:
			area.queue_free()
		$AnimatedSprite2D.play("cat_death")
		is_dead = true
		area.queue_free()
		await get_tree().create_timer(1.2).timeout
		queue_free()
