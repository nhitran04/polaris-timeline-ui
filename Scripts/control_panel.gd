extends HBoxContainer

class_name ControlPanel

# Called when the node enters the scene tree for the first time.
func _ready():
	get_viewport().connect("size_changed", _on_viewport_resize)
	_on_viewport_resize()

func _on_viewport_resize():
	var vp = get_viewport()
	if vp != null:
		var vp_size = Vector2(get_viewport().size)
		var new_panel_pos: Vector2 = vp_size - size
		new_panel_pos -= Vector2(40, 40)
		position = new_panel_pos
