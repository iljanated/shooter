extends State
class_name  EnemyGoToExitState

@export var character_body: CharacterBody2D
@export var max_speed: float = 50.0

var datagrid: DataGrid2D

func _ready() -> void:
    datagrid = get_tree().root.find_child("DataGrid2D", true, false)
    if datagrid == null:
        push_error("EnemyGoToExitState: Could not find DataGrid2D in node tree")
    
    if not character_body:
        push_error("EnemyGoToExitState: character_body is not assigned")

func enter():
    pass

func update(delta):
    pass

func physics_update(delta):
    var gradient = datagrid.get_gradient("exits", character_body.global_position)
    character_body.velocity = -gradient * max_speed