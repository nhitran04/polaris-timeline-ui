extends CanvasLayer

@onready var background := $Background

# Called when the node enters the scene tree for the first time.
func _ready():
	
	SignalBus.remove_end_screen.connect(_remove)
	
	# resize control
	get_viewport().connect("size_changed", _on_viewport_resize)
	_on_viewport_resize()
	
func _remove() -> void:
	get_parent().remove_child(self)
	queue_free()

func _on_viewport_resize() -> void:
	pass
	'''
	var vp = get_viewport()
	if vp != null:
		var vp_size = Vector2(vp.size)
		background.size = vp_size
		background.position = Vector2(0, 0)
	'''
