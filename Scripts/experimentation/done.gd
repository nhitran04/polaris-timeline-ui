extends Node

@onready var done_button := $DonePanel/Done as Button

# Called when the node enters the scene tree for the first time.
func _ready():
	
	done_button.pressed.connect(_on_done_selected)	
	
	# resize control
	get_viewport().connect("size_changed", _on_viewport_resize)
	_on_viewport_resize()
	
func _on_done_selected() -> void:
	Logger.log_event("button_done", {})
	SignalBus.participant_finished.emit()

func _on_viewport_resize() -> void:
	pass
	'''
	var vp = get_viewport()
	if vp != null:
		var vp_size = Vector2(vp.size)
		done_button.position.x = vp_size.x - (done_button.size.x + 60)
		done_button.position.y = 60
	'''
