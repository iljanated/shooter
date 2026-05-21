extends State
class_name  EnemyGoToExitState

@export var enemy: Enemy
@export var max_speed: float = 50.0

var flock_box: Area2D
var arrow_component: ArrowComponent
var datagrid: DataGrid2D
var gradient = Vector2.RIGHT

func _ready() -> void:
	flock_box = enemy.find_child("FlockBox", true, false)
	arrow_component = enemy.find_child("ArrowComponent", true, false)
	datagrid = get_tree().root.find_child("DataGrid2D", true, false)
	if datagrid == null:
		push_error("EnemyGoToExitState: Could not find DataGrid2D in node tree")
	
	if not enemy:
		push_error("EnemyGoToExitState: character_body is not assigned")

func enter():
	pass

func update(delta):
	pass

func physics_update(delta):
	var new_gradient = datagrid.get_gradient("exits", enemy.global_position)
	if new_gradient != Vector2.ZERO:
		gradient = new_gradient
	
	enemy.velocity = gradient * max_speed

	var flock_vector = Vector2.ZERO
	var other_characters = flock_box.get_overlapping_bodies()
	for other in other_characters:
		if other is Enemy and other != enemy:
			var to_other = other.global_position - enemy.global_position
			var distance = to_other.length()
			if distance > 0:
				flock_vector -= to_other.normalized() / distance

	enemy.velocity = (gradient + flock_vector * 10.0).normalized() * max_speed

	arrow_component.rotation = gradient.angle()
	
