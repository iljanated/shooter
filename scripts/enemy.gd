extends CharacterBody2D

func _physics_process(delta: float) -> void:
	move_and_slide()

	if velocity:
		$AnimatedSprite2D.play("walk")
		if velocity.x > 0:
			$AnimatedSprite2D.flip_h = false
		else:
			$AnimatedSprite2D.flip_h = true
	else:
		$AnimatedSprite2D.play("idle")
