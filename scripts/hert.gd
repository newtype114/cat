extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#pass
	$AnimationPlayer.play("blink")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_timer_timeout() -> void:
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("add_hp"):
			$pickup.play()
			body.add_hp(1)  # 调用玩家的方法来加血
		queue_free()
