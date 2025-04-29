extends Camera3D

enum CAM_MODE {MAP,
			   PLAN_VIS}
var mode: CAM_MODE
var zoom_locked: bool

# Called when the node enters the scene tree for the first time.
func _ready():
	SignalBus.lock_3D_camera_zoom.connect(_lock_zoom)
	zoom_locked = false
	set_map_mode()
	
	# for replaying
	SignalBus.set_map_cam.connect(_set_map_cam)
	SignalBus.reset_map_in_space.connect(set_map_mode)
	SignalBus.zoom_map.connect(_set_map_zoom)
	
func set_mode(mode: int) -> void:
	if mode == CAM_MODE.MAP:
		set_map_mode()
	elif mode == CAM_MODE.PLAN_VIS:
		set_plan_vis_mode()
	
func set_map_mode() -> void:
	mode = CAM_MODE.MAP
	projection = 0
	size = 1
	position = Vector3(0, 0, 17)
	rotation = Vector3(0, 0, 0)
	_log_event()
	
func set_plan_vis_mode() -> void:
	mode = CAM_MODE.PLAN_VIS
	projection = 1
	size = 20
	position = Vector3(0, 0, 14)
	rotation = Vector3(0, 0, 0)
	_log_event()
	
func _set_map_zoom(value: float) -> void:
	position.z = value
	_log_event()
	
func _lock_zoom(val: bool) -> void:
	zoom_locked = val

func _input(event: InputEvent) -> void:
	if zoom_locked:
		return
	if mode == CAM_MODE.MAP:
		if Input.is_action_just_released("zoom_in") and position.z >= 5:
			self.position.z -= 1
			SignalBus.mouse_wheel_zoom.emit(self.position.z)
			_log_event()
		if Input.is_action_just_released("zoom_out") and position.z <= 30:
			self.position.z += 1
			SignalBus.mouse_wheel_zoom.emit(self.position.z)
			_log_event()
	elif mode == CAM_MODE.PLAN_VIS:
		if Input.is_action_just_released("zoom_in") and size >= 5:
			size -= 1
			_log_event()
		if Input.is_action_just_released("zoom_out") and size <= 35:
			size += 1
			_log_event()

func _log_event() -> void:
	# TODO: this is messy code
	if "log_to_backend" in Options.opts and Options.opts.log_to_backend:
		SignalBus.log_to_backend.emit(
			Time.get_ticks_msec(),
			"cam_map",
			{"z": position.z,
			 "size": size,
			 "mode": mode}
		)
		
func _set_map_cam(mode: int, size: int, z: int) -> void:
	set_mode(mode)
	self.size = size
	self.position.z = z
