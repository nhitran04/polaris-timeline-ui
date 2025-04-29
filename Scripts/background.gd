extends Panel


# Called when the node enters the scene tree for the first time.
func _ready():
	SignalBus.exit_drawing_board.connect(_hide_background)
	SignalBus.exit_map.connect(_show_background)

func _hide_background() -> void:
	hide()
	
func _show_background() -> void:
	show()	
