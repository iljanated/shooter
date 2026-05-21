extends Node2D

class_name DataGrid2D

@export var debug_collision_draw = false
@export var debug_exits_distance_field_draw = false
@export var cell_size: int = 32

var tilemap_layers: Array[TileMapLayer] = []
var map_exits: Array[MapExit] = []

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
	var grid_size = grid_width * grid_height
	grid.resize(grid_size)

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

	exit_distance_field.resize(grid_size)
	player_distance_field.resize(grid_size)
	flow_field_buffer.resize(grid_size)
	
	rebuild_exit_distance_field()
	rebuild_player_distance_field()
	
	queue_redraw()
			
func _draw():
	var grid_width = grid_rect.size.x
	var grid_height = grid_rect.size.y

	if debug_collision_draw:
		for y in range(grid_height):
			for x in range(grid_width):
				var cell_index = y * grid_width + x
				var cell = grid[cell_index]
				var color =  Color(0, 1, 0, 0.2) if cell.walkable else Color(1, 0, 0, 0.2)
				draw_rect(Rect2(top_left + Vector2(x, y) * cell_size, Vector2(cell_size, cell_size)), color)

	if debug_exits_distance_field_draw:
		var font : Font = ThemeDB.fallback_font
		var font_size = 10

		for y in range(grid_height):
			for x in range(grid_width):
				var cell_index = y * grid_width + x
				var gradient = get_gradient("exits", top_left + Vector2(x, y) * cell_size + Vector2(cell_size, cell_size) * 0.5)
				draw_line(top_left + Vector2(x, y) * cell_size + Vector2(cell_size, cell_size) * 0.5, top_left + Vector2(x, y) * cell_size + Vector2(cell_size, cell_size) * 0.5 + gradient * cell_size * 0.5, Color(1, 0, 1))	
				draw_string(font, top_left + Vector2(x, y) * cell_size + Vector2(0, (cell_size + font_size) * 0.5), str(exit_distance_field[cell_index]).pad_decimals(1),HORIZONTAL_ALIGNMENT_CENTER, cell_size, font_size)


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

func rebuild_exit_distance_field() -> void:
	
	var exit_source_indices: Array[int] = []
	for map_exit in map_exits:
		var index = world_position_to_index(map_exit.global_position)
		if index != -1:
			exit_source_indices.append(index)

	FlowField.calculate_field(flow_field_buffer, grid_rect.size, grid, exit_source_indices)

	var previous_field = exit_distance_field
	exit_distance_field = flow_field_buffer
	flow_field_buffer = previous_field


func rebuild_player_distance_field() -> void:
	pass

func get_index_distance(flow_field: String, index: int) -> float:
	var selected_field: PackedFloat32Array
	match flow_field:
		"exits":
			selected_field = exit_distance_field
		"players":
			selected_field = player_distance_field
		_:
			push_error("DataGrid2D: Unknown flow field name ", flow_field)
			return INF

	if index < 0 or index >= selected_field.size():
		return INF

	return selected_field[index]

func get_distance(flow_field: String, world_position: Vector2) -> float:
	var index = world_position_to_index(Vector2(world_position.x, world_position.y))
	return get_index_distance(flow_field, index)

func get_gradient(flow_field: String, world_position: Vector2) -> Vector2:
	var center_index = world_position_to_index(Vector2(world_position.x, world_position.y))
	var center_value = get_index_distance(flow_field, center_index)
	if center_value == INF:
		return Vector2.ZERO

	var grid_width = grid_rect.size.x
	var grid_height = grid_rect.size.y
	var cell_x = center_index % grid_width
	var cell_y = int(center_index / grid_width)

	var result = Vector2.ZERO
	var result_value = center_value

	# right
	if cell_x < grid_width - 1:
		var index = center_index + 1
		var value = get_index_distance(flow_field, index)
		if value < result_value:
			result_value = value
			result = Vector2(1, 0)

	# right_down
	if cell_x < grid_width - 1 and cell_y < grid_height - 1:
		var index = center_index + 1 + grid_width
		var value = get_index_distance(flow_field, index)
		if value < result_value:
			result_value = value
			result = Vector2(0.7071, 0.7071)

	# down
	if cell_y < grid_height - 1:
		var index = center_index + grid_width
		var value = get_index_distance(flow_field, index)
		if value < result_value:
			result_value = value
			result = Vector2(0, 1)

	# left_down
	if cell_x > 0 and cell_y < grid_height - 1:
		var index = center_index - 1 + grid_width
		var value = get_index_distance(flow_field, index)
		if value < result_value:
			result_value = value
			result = Vector2(-0.7071, 0.7071)

	# left
	if cell_x > 0:
		var index = center_index - 1
		var value = get_index_distance(flow_field, index)
		if value < result_value:
			result_value = value
			result = Vector2(-1, 0)

	# left_up
	if cell_x > 0 and cell_y > 0:
		var index = center_index - 1 - grid_width
		var value = get_index_distance(flow_field, index)
		if value < center_value:
			result = Vector2(-0.7071, -0.7071)

	# up
	if cell_y > 0:
		var index = center_index - grid_width
		var value = get_index_distance(flow_field, index)
		if value < center_value:
			result = Vector2(0, -1)

	# right_up
	if cell_x < grid_width - 1 and cell_y > 0:
		var index = center_index + 1 - grid_width
		var value = get_index_distance(flow_field, index)
		if value < center_value:
			result = Vector2(0.7071, -0.7071)

	return result

	var right_index = center_index + 1 if cell_x < grid_width - 1 else -1
	var left_index = center_index - 1 if cell_x > 0 else -1
	var up_index = center_index + grid_width if cell_y < grid_height - 1 else -1
	var down_index = center_index - grid_width if cell_y > 0 else -1

	var right_value = get_index_distance(flow_field, right_index)
	if right_value == INF:
		right_value = center_value

	var left_value = get_index_distance(flow_field, left_index)
	if left_value == INF:
		left_value = center_value

	var up_value = get_index_distance(flow_field, up_index)
	if up_value == INF:
		up_value = center_value

	var down_value = get_index_distance(flow_field, down_index)
	if down_value == INF:
		down_value = center_value

	var gradient = Vector2(right_value - left_value, up_value - down_value)
	if gradient == Vector2.ZERO:
		return Vector2.ZERO

	return gradient.normalized()

func world_position_to_index(world_position: Vector2) -> int:
	if grid_rect == Rect2i():
		push_error("DataGrid2D: Empty grid_rect, cannot convert world position to index")
		return -1

	var local_position = world_position / cell_size
	var cell_position = Vector2i(floor(local_position.x), floor(local_position.y)) - grid_rect.position
	var grid_width = grid_rect.size.x
	var grid_height = grid_rect.size.y

	if cell_position.x < 0 or cell_position.x >= grid_width:
		push_error("DataGrid2D: World position ", world_position, " is out of grid bounds")
		return -1
	if cell_position.y < 0 or cell_position.y >= grid_height:
		push_error("DataGrid2D: World position ", world_position, " is out of grid bounds")
		return -1

	return cell_position.y * grid_width + cell_position.x