@tool
extends Area2D

class_name MapExit

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var radius: float = 16.0

func _ready() -> void:
    radius = collision_shape.shape.radius

func _draw():
    draw_circle(Vector2.ZERO, radius, Color(1, 0, 1,0.3))