extends RefCounted

class_name FlowField

const DEFAULT_DISTANCE: float = INF


static func create_default_field(cell_count: int) -> PackedFloat32Array:
	var flow_field := PackedFloat32Array()
	flow_field.resize(cell_count)
	for cell_index in range(cell_count):
		flow_field[cell_index] = DEFAULT_DISTANCE
	return flow_field


static func calculate_field_on_buffer(
		buffer_field: PackedFloat32Array,
		grid: Array[DataGrid2DCell],
		source_indices: Array[int]
	) -> PackedFloat32Array:
	for cell_index in range(grid.size()):
		buffer_field[cell_index] = DEFAULT_DISTANCE

	for source_index in source_indices:
		if source_index >= 0 and source_index < buffer_field.size():
			buffer_field[source_index] = 0.0

	# Fast sweep method and eikonal solver will be implemented here later.
	return buffer_field