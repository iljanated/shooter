extends CharacterBody2D

class_name Enemy

signal despawned

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

func despawn() -> void:
	emit_signal("despawned", self)


func _on_hit_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("exits"):
		despawn()
