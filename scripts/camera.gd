extends Camera2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("zoom_out"):
		self.zoom *= 0.9
	elif event.is_action_pressed("zoom_in"):
		self.zoom *= 1.1
