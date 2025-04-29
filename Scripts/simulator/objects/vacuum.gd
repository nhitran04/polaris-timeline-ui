extends CharacterBody2D

var reset_pos_coords: Vector2
var reset_parent_name: String = "simulator"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	reset_pos_coords = position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func reset() -> void:
	position = reset_pos_coords