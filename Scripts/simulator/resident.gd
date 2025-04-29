extends StaticBody2D

@export var visual_path: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_node("Sprite2D").texture = load(visual_path)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func get_put_loc(name: String) -> Vector2:
	if visual_path.contains("front") || visual_path.contains("back"):
		return Vector2(-15, 30)
	else:
		return Vector2(0, 30)
