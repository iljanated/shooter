extends Node

class_name DataGrid2D

@export var tilemap_layers : Array[TileMapLayer] = []
@export var cell_size: Vector2i = Vector2i(32, 32)

var grid : Array
var grid_size : Vector2i
var top_left : Vector2 = Vector2(INF, INF)

func _ready():
    var rect : Rect2i = Rect2i()
    for layer in tilemap_layers:
        var layer_rect = layer.get_used_rect()
        top_left = top_left.min(layer_rect.position)
        rect = rect.merge(layer_rect)
    grid_size = Vector2i(int(rect.size.x / cell_size.x), int(rect.size.y / cell_size.y))

    for y in range(grid_size.y):
        for x in range(grid_size.x):
            for layer in tilemap_layers:
                var cell = layer.get_cell(x + int(top_left.x / cell_size.x), y + int(top_left.y / cell_size.y))
                layer.get_cell_tile_data()

