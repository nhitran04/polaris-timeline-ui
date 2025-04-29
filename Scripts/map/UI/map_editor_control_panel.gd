extends ControlPanel

@onready var save_map := $SaveMapButton as Button
@onready var load_map := $LoadMapButton as Button
@onready var exit_map := $ExitMapButton as Button

# Called when the node enters the scene tree for the first time.
func _ready():
	
	save_map.pressed.connect(_on_save_map)
	load_map.pressed.connect(_on_load_map)
	exit_map.pressed.connect(_on_map_exit)
	
	get_viewport().connect("size_changed", _on_viewport_resize)
	_on_viewport_resize()
	
func _on_map_exit() -> void:
	SignalBus.exit_map.emit()
	SignalBus.log_to_backend.emit(Time.get_ticks_msec(),
								  "button_to_drawingboard",
								  {})
	
func _on_save_map() -> void:
	SignalBus.save_map.emit()
	
func _on_load_map() -> void:
	SignalBus.load_map.emit()
