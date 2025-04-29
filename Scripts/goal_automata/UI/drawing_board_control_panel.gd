extends ControlPanel

@onready var to_map := $ToMapButton as Button
@onready var play := $PlayButton as Button

# Called when the node enters the scene tree for the first time.
func _ready():
	
	to_map.pressed.connect(_on_to_map)
	play.pressed.connect(_on_play)
	
	get_viewport().connect("size_changed", _on_viewport_resize)
	_on_viewport_resize()

func _on_to_map() -> void:
	SignalBus.enter_map.emit()
	SignalBus.log_to_backend.emit(Time.get_ticks_msec(),
								  "button_to_map",
								  {})
	
func _on_play() -> void:
	SignalBus.play.emit()
	SignalBus.log_to_backend.emit(Time.get_ticks_msec(),
								  "button_to_play",
								  {})

func _input(event: InputEvent) -> void:
	var vp = get_viewport()
	if vp != null:
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_ALT:
				play.visible = not play.visible
				call_deferred("_on_viewport_resize")
