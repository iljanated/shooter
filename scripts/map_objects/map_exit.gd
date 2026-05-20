@tool
extends Node2D

class_name MapExit


func _draw():
    draw_circle(Vector2.ZERO, 16, Color(1, 0, 1,0.3))