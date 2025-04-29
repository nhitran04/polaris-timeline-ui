extends Line2D

var _pressed := false
var _current_line: Line2D
var _can_draw := false 

# Called when the node enters the scene tree for the first time.
func _ready():
	# instantiate user interaction
	_current_line = Line2D.new()
	_current_line.width = 8
	add_child(_current_line)

func _input(event: InputEvent):
	if not _can_draw:
		return
	if Input.is_action_just_pressed("zoom_in") or Input.is_action_just_pressed("zoom_out"):
		return
	if event is InputEventMouseButton:
		_pressed = event.pressed
	elif event is InputEventMouseMotion and _pressed:
		_current_line.add_point(event.position)
	if event is InputEventMouseButton and event.is_action_released("click"):
		_pressed = false
		_current_line.clear_points()
		_can_draw = false

func allow_draw() -> void:
	_can_draw = true
	
func set_color(color: Color) -> void:
	_current_line.default_color = color
	
