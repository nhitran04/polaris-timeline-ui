extends StaticBody2D

@onready var _center_table = $mid
var reset_pos_coords: Vector2
var reset_parent_name: String = "dining_room"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func reset() -> void:
	set_wiped(false)

func set_wiped(is_wiped: bool) -> void:
	if is_wiped:
		_center_table.texture = load("res://Assets/img/simulator/cafeteria/tablemid.png")
	else:
		_center_table.texture = load("res://Assets/img/simulator/cafeteria/dirty-tablemid.png")

func get_put_loc(name: String) -> Vector2:
	return Vector2(0,0)
