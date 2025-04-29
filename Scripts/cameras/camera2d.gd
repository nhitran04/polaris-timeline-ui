extends Camera2D

@export var pan_speed : float = 1.0

var touch_pts_dict : Dictionary = {}

# instance variables
var _draggable: bool

# camera controls
var pan_locked := false

# interaction mode
enum CAMERA_MODE {DRAWING_BOARD,
			   TIMELINE,
			   MAP,
			   SIMULATOR}
var mode := CAMERA_MODE.MAP
var robot: Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	set_to_map()
	SignalBus.lock_2D_camera_pan.connect(_lock_pan)
	SignalBus.set_camera_simulator_mode.connect(_set_to_simulator_mode)
	SignalBus.set_drawing_board_cam.connect(_set_db_cam)
	
func set_to_branching_drawing_board() -> void:
	set_zoom(Vector2(1, 1))
	set_position(Vector2(3000, 1000))
	_draggable = true
	
func set_to_timeline() -> void:
	set_zoom(Vector2(1, 1))
	set_position(Vector2(1200, 780))
	_draggable = false
	
func set_to_map() -> void:
	set_zoom(Vector2(1, 1))
	set_position(Vector2(1200, 780))
	_draggable = false
	
func _set_to_simulator_mode(robot: SimulatedRobot) -> void:
	mode = CAMERA_MODE.SIMULATOR
	set_zoom(Vector2(2, 2))
	self.robot = robot
	_draggable = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if mode == CAMERA_MODE.SIMULATOR:
		position = robot.position
		
func _lock_pan(val: bool) -> void:
	pan_locked = val
	
func _input(event: InputEvent):
	if not _draggable:
		return
	if event is InputEventScreenDrag:
		touch_pts_dict[event.index] = event.position
		if touch_pts_dict.size() == 1 and !pan_locked:
			position -= event.relative/self.zoom
			position.x = max(position.x, -4000)
			position.x = min(position.x, 4000)
			position.y = max(position.y, -4000)
			position.y = min(position.y, 4000)
			log_event()
	if not _draggable:
		return
	if Input.is_action_just_released("zoom_in") and self.zoom < Vector2(2.0, 2.0):
		self.zoom *= Vector2(1.1, 1.1)
		log_event()
	if Input.is_action_just_released("zoom_out") and self.zoom > Vector2(0.25, 0.25):
		self.zoom *= Vector2(0.9, 0.9)
		log_event()

func log_event() -> void:
	if Options.opts.log_to_backend:
		var args: Dictionary = {
			"x": position.x,
			"y": position.y,
			"zoom_x": self.zoom.x,
			"zoom_y": self.zoom.y
		}
		SignalBus.log_to_backend.emit(
			Time.get_ticks_msec(),
			"cam_drawingboard",
			args
		)
		print("LOGGING")
		
func _set_db_cam(x: int, y: int, zoomx: int, zoomy: int) -> void:
	position = Vector2(x, y)
	zoom = Vector2(zoomx, zoomy)
