@tool
extends Node2D

class_name SpawnPoint


func _draw():
    draw_circle(Vector2.ZERO, 16, Color(0, 1, 1,0.3))