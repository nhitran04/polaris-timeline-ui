extends VBoxContainer

# scenes to instantiate
var exception_scene := load("res://Scenes/DrawingBoard/exceptions/exception.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	SignalBus.set_plan.connect(_load_exceptions)
	
	# resizing window
	# get_viewport().connect("size_changed", _on_viewport_resize)
	# _on_viewport_resize()

func _load_exceptions(data: Dictionary) -> void:
	for temp in get_children():
		remove_child(temp)
		temp.queue_free()
	var exceptions: Array = data["exceptions"]
	if len(exceptions) == 0:
		var exception = exception_scene.instantiate()
		exception.set_as_nothing()
		add_child(exception)
		call_deferred("_on_viewport_resize")
		return
	for exception_data in exceptions:
		var exception = exception_scene.instantiate()
		exception.set_as_error()
		exception.get_node("message").text = exception_data["msg"].replace("checkpoint", "step")
		add_child(exception)
	call_deferred("_on_viewport_resize")
	
# func _on_viewport_resize() -> void:
#	var vp_size = Vector2(get_viewport().size)
#	position.x = vp_size.x - (size.x + 50)
