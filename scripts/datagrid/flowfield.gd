extends RefCounted

class_name FlowField

static func calculate_field(field: PackedFloat32Array, grid_size: Vector2i, data_grid: Array[DataGrid2DCell], target_indices: Array[int]):
    field.fill(INF)
    for target_index in target_indices:
        field[target_index] = 0.0

    var sweeps = [
        {"x_start": 0, "x_end": grid_size.x, "x_step": 1, "y_start": 0, "y_end": grid_size.y, "y_step": 1},
        {"x_start": grid_size.x - 1, "x_end": - 1, "x_step": - 1, "y_start": 0, "y_end": grid_size.y, "y_step": 1},
        {"x_start": 0, "x_end": grid_size.x, "x_step": 1, "y_start": grid_size.y - 1, "y_end": - 1, "y_step": - 1},
        {"x_start": grid_size.x - 1, "x_end": - 1, "x_step": - 1, "y_start": grid_size.y - 1, "y_end": - 1, "y_step": - 1}
    ]

    var grid_width = grid_size.x
    var grid_height = grid_size.y

    for sweep in sweeps:
        for x in range(sweep["x_start"], sweep["x_end"], sweep["x_step"]):
            for y in range(sweep["y_start"], sweep["y_end"], sweep["y_step"]):
                var index = x + y * grid_width
                
                if not data_grid[index].walkable:
                    continue
                
                if target_indices.has(index):
                    continue

                var x_left = field[index - 1] if x > 0 else INF
                var x_right = field[index + 1] if x < grid_width - 1 else INF
                var y_up = field[index - grid_width] if y > 0 else INF
                var y_down = field[index + grid_width] if y < grid_height - 1 else INF

                var u_xmin = min(x_left, x_right)
                var u_ymin = min(y_up, y_down)

                var f_val = 1.0 # speed?
                var f_inv = 1.0 / f_val

                var u_new = FlowField.solve_eikonal(u_xmin, u_ymin, f_inv)

                if u_new < field[index]:
                    field[index] = u_new
                
static func solve_eikonal(u_x: float, u_y: float, f_inv: float) -> float:
    var u_min = min(u_x, u_y)
    var u_max = max(u_x, u_y)

    if u_max == INF:
        return u_min + f_inv

    var discriminant = 2.0 * f_inv * f_inv - (u_x - u_y) * (u_x - u_y)

    if discriminant < 0.0:
        return u_min + f_inv

    return 0.5 * ((u_x + u_y) + sqrt(discriminant))
