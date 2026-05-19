extends State
class_name  EnemyIdleState

@export var character_body: CharacterBody2D
@export var max_speed: float = 50.0

var move_direction : Vector2 = Vector2.ZERO
var move_timer : float = 0.0

func enter():
    randomize_idle()

func update(delta):
    move_timer -= delta
    if move_timer <= 0:
        randomize_idle()

func physics_update(delta):
    if character_body:
        character_body.velocity = move_direction * max_speed

func randomize_idle():
    move_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
    move_timer = randf_range(1.0, 3.0)