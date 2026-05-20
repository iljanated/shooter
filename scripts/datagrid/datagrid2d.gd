extends Node2D

class_name DataGrid2D

var tilemap_layers: Array[TileMapLayer] = []
var map_exits: Array[MapExit] = []
@export var cell_size: int = 32

var grid: Array[DataGrid2DCell] = []
var exit_distance_field: PackedFloat32Array = PackedFloat32Array()
var player_distance_field: PackedFloat32Array = PackedFloat32Array()
var flow_field_buffer: PackedFloat32Array = PackedFloat32Array()
var grid_rect: Rect2i = Rect2i()
var top_left: Vector2 = Vector2()


func _ready():
	initialize_map_exits_from_static_objects()

	initialize_tilemap_layers_from_static_layers()
	if tilemap_layers.is_empty():
		push_error("DataGrid2D: No TileMapLayer children found under StaticLayers")
		return

	for layer in tilemap_layers:
		var layer_rect = layer.get_used_rect()
		if grid_rect == null or grid_rect == Rect2i():
			grid_rect = layer_rect
		else:
			grid_rect = grid_rect.merge(layer_rect)

	top_left = grid_rect.position * cell_size
	
	var grid_width = grid_rect.size.x
	var grid_height = grid_rect.size.y
	grid.resize(grid_width * grid_height)

	for y in range(grid_height):
		for x in range(grid_width):
			var cell_index = y * grid_width + x
			grid[cell_index] = DataGrid2DCell.new()
	
	for layer in tilemap_layers:
		var layer_cells = layer.get_used_cells()
		for cell in layer_cells:
			var tile_data = layer.get_cell_tile_data(cell)
			var custom_data = tile_data.get_custom_data("type")
			var cell_position = cell - grid_rect.position
			var cell_index = cell_position.y * grid_width + cell_position.x
			match custom_data:
				"floor":
					grid[cell_index].walkable = grid[cell_index].walkable and true
				"wall":
					grid[cell_index].walkable = false

	initialize_flow_fields()
	rebuild_exit_distance_field()
	rebuild_player_distance_field([])
	queue_redraw()
			
func _draw():
	var grid_width = grid_rect.size.x
	var grid_height = grid_rect.size.y

	for y in range(grid_height):
		for x in range(grid_width):
			var cell_index = y * grid_width + x
			var cell = grid[cell_index]
			var color =  Color(0, 1, 0, 0.2) if cell.walkable else Color(1, 0, 0, 0.2)
			draw_rect(Rect2(top_left + Vector2(x, y) * cell_size, Vector2(cell_size, cell_size)), color)


func initialize_tilemap_layers_from_static_layers() -> void:
	tilemap_layers.clear()

	var static_layers_node = get_tree().root.find_child("StaticLayers", true, false)
	if static_layers_node == null:
		push_error("DataGrid2D: Could not find StaticLayers in node tree")
		return

	for child_node in static_layers_node.get_children():
		if child_node is TileMapLayer:
			tilemap_layers.append(child_node)


func initialize_map_exits_from_static_objects() -> void:
	map_exits.clear()

	var static_objects_node = get_tree().root.find_child("StaticObjects", true, false)
	if static_objects_node == null:
		push_error("DataGrid2D: Could not find StaticObjects in node tree")
		return

	for child_node in static_objects_node.get_children():
		if child_node is MapExit:
			map_exits.append(child_node)


func initialize_flow_fields() -> void:
	var cell_count = grid.size()
	exit_distance_field = FlowField.create_default_field(cell_count)
	player_distance_field = FlowField.create_default_field(cell_count)
	flow_field_buffer = FlowField.create_default_field(cell_count)


func rebuild_exit_distance_field() -> void:
	var exit_source_indices: Array[int] = []
	for map_exit in map_exits:
		exit_source_indices.append(get_cell_index_from_world_position(map_exit.global_position))

	flow_field_buffer = FlowField.calculate_field_on_buffer(flow_field_buffer, grid, exit_source_indices)
	var previous_field = exit_distance_field
	exit_distance_field = flow_field_buffer
	flow_field_buffer = previous_field


func rebuild_player_distance_field(player_positions: Array[Vector2]) -> void:
	var player_source_indices: Array[int] = []
	for player_position in player_positions:
		player_source_indices.append(get_cell_index_from_world_position(player_position))

	flow_field_buffer = FlowField.calculate_field_on_buffer(flow_field_buffer, grid, player_source_indices)
	var previous_field = player_distance_field
	player_distance_field = flow_field_buffer
	flow_field_buffer = previous_field


func get_cell_index_from_world_position(world_position: Vector2) -> int:
	if grid_rect == Rect2i():
		return -1

	var local_position = world_position / cell_size
	var cell_position = Vector2i(floor(local_position.x), floor(local_position.y)) - grid_rect.position
	var grid_width = grid_rect.size.x
	var grid_height = grid_rect.size.y

	if cell_position.x < 0 or cell_position.x >= grid_width:
		return -1
	if cell_position.y < 0 or cell_position.y >= grid_height:
		return -1

	return cell_position.y * grid_width + cell_position.x
