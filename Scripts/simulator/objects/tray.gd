extends StaticBody2D

var reset_pos_coords: Vector2
var reset_parent_name: String = "simulator"

var locations: Array = [Vector2(10,5), Vector2(-20, 5), Vector2(0, -10)] # entree, napkin, cup
var loc_index: int = 0
var entree_loc = Vector2(0, 0)
var napkin_loc = Vector2(-20, -5)
var drink_loc = Vector2(10, -5)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	reset_pos_coords = position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func reset() -> void:
	position = reset_pos_coords
	loc_index = 0

func get_put_loc(name: String) -> Vector2:
	if name == "napkin":
		return napkin_loc
	elif name == "entree":
		return entree_loc
	elif name == "cup1":
		return drink_loc
	else:
		var cur_inx = loc_index
		if loc_index == (len(locations)-1):
			loc_index = 0
		else:
			loc_index = loc_index + 1
		return locations[cur_inx]
		
