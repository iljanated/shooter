extends Marker2D

class_name EntityPool

@export var entity_name: String
@export var spawn_offset: int = 32

var scene : PackedScene

var entities: Array[Enemy] = []
var spawn_timer: float = 0.0
var spawn_points: Array[SpawnPoint] = []

func _ready() -> void:
	y_sort_enabled = true
	var path = "res://scenes/%s.tscn" % entity_name
	scene = load(path)
	if not scene:
		push_error("EntityPool: Unknown entity type ", entity_name)

	var spawn_nodes = get_tree().get_nodes_in_group("spawn_points")
	for spawn_node in spawn_nodes:
		if spawn_node is SpawnPoint:
			spawn_points.append(spawn_node)

func _process(delta: float) -> void:
	spawn_timer += delta
	if spawn_timer >= 0.3:
		_spawn()
		spawn_timer = 0.0

func _spawn() -> Node2D:
	var entity = _find_disabled()
	
	if not entity:
		entity = scene.instantiate()
		entities.append(entity)
		add_child(entity)
		entity.despawned.connect(_on_despawn)

	entity.process_mode = Node.PROCESS_MODE_INHERIT
	entity.visible = true
	
	if spawn_points.size() > 0:
		var spawn_point = spawn_points[randi() % spawn_points.size()]
		entity.position = spawn_point.position - position + Vector2(randi_range(-spawn_offset, spawn_offset), randi_range(-spawn_offset, spawn_offset))
	
	return entity

func _on_despawn(entity: Enemy) -> void:
	entity.process_mode = Node.PROCESS_MODE_DISABLED
	entity.visible = false

func _find_disabled() -> Enemy:
	for entity in entities:
		if entity.process_mode == Node.PROCESS_MODE_DISABLED:
			return entity
	return null
