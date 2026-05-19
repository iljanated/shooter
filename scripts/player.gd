extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


var max_speed = 100


func _ready():
	pass

func _physics_process(delta):
	var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_vector * max_speed
	move_and_slide()

	if velocity:
		$AnimatedSprite2D.play("walk")
		if velocity.x > 0:
			$AnimatedSprite2D.flip_h = false
		else:
			$AnimatedSprite2D.flip_h = true
	else:
		$AnimatedSprite2D.play("idle")
