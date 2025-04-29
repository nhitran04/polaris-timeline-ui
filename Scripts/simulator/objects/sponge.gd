extends CharacterBody2D

var reset_pos_coords: Vector2
var reset_parent_name: String = "simulator"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	reset_pos_coords = position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func wipe_surface(surface: Node) -> void:
	print("doing some wiping now!!!")
	var old_pos = position
	position = get_parent().to_local(surface.global_position)
	await get_tree().create_timer(1.0).timeout
	position = old_pos
	
	SignalBus.current_action_finished.emit()


func reset() -> void:
	position = reset_pos_coords
