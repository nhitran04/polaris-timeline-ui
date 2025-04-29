extends Panel

@onready var top_button := $top as Button
@onready var bottom_button := $bottom as Button
@onready var right_button := $right as Button
@onready var left_button := $left as Button
@onready var translate_icon := $translate_icon
@onready var rotate_button := $rotate_icon/rotate as Button
@onready var rotate_icon := $rotate_icon as Sprite2D
@onready var tilt_slider := $tilt_slider as VSlider
@onready var zoom_slider := $zoom_slider as HSlider
@onready var tutorial_arrow := $Highlighter as TextureRect

# instance vars
var _top_is_pressed: bool
var _bottom_is_pressed: bool
var _right_is_pressed: bool
var _left_is_pressed: bool
var _rotate_is_pressed: bool
var _tilt_sliding: bool
var _zoom_sliding: bool
var _slider_idle_img
var _slider_pressed_img

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# link buttons
	top_button.button_down.connect(_top_pressed)
	top_button.button_up.connect(_top_released)
	bottom_button.button_down.connect(_bottom_pressed)
	bottom_button.button_up.connect(_bottom_released)
	right_button.button_down.connect(_right_pressed)
	right_button.button_up.connect(_right_released)
	left_button.button_down.connect(_left_pressed)
	left_button.button_up.connect(_left_released)
	rotate_button.button_down.connect(_rotate_pressed)
	rotate_button.button_up.connect(_rotate_released)
	tilt_slider.drag_started.connect(_tilt_start)
	tilt_slider.drag_ended.connect(_tilt_end)
	zoom_slider.drag_started.connect(_zoom_start)
	zoom_slider.drag_ended.connect(_zoom_end)
	
	# auto-move buttons
	SignalBus.mouse_wheel_zoom.connect(zoom_set)
	
	# tutorial arrow
	SignalBus.show_arrow.connect(_show_tutorial_arrow)
	
	# set dragger icons
	_slider_idle_img = load("res://Assets/img/slide_bar_grabber-02.png")
	_slider_pressed_img = load("res://Assets/img/slide_bar_grabber_pressed-02.png")
	zoom_slider.add_theme_icon_override("grabber", _slider_idle_img)
	zoom_slider.add_theme_icon_override("grabber_highlight", _slider_idle_img)
	zoom_slider.add_theme_icon_override("grabber_disabled", _slider_idle_img)
	tilt_slider.add_theme_icon_override("grabber", _slider_idle_img)
	tilt_slider.add_theme_icon_override("grabber_highlight", _slider_idle_img)
	tilt_slider.add_theme_icon_override("grabber_disabled", _slider_idle_img)
	
	# resize control
	get_viewport().connect("size_changed", _on_viewport_resize)
	_on_viewport_resize()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if _top_is_pressed:
		SignalBus.translate_map.emit(Vector3(0, -0.1, 0))
	elif _bottom_is_pressed:
		SignalBus.translate_map.emit(Vector3(0, 0.1, 0))
	elif _left_is_pressed:
		SignalBus.translate_map.emit(Vector3(0.1, 0, 0))
	elif _right_is_pressed:
		SignalBus.translate_map.emit(Vector3(-0.1, 0, 0))
	elif _rotate_is_pressed:
		# get mouse position
		var mp: Vector2 = get_viewport().get_mouse_position()
		# get angle w.r.t. center of view control
		mp -= rotate_icon.global_position
		var angle = atan(mp.y/mp.x)
		if get_viewport().get_mouse_position().x < rotate_icon.global_position.x:
			angle = deg_to_rad(-90) - (deg_to_rad(90) - angle)
		# rotate view control accordingly
		rotate_set(angle)
	elif _tilt_sliding:
		SignalBus.tilt_map.emit(tilt_slider.value)
	elif _zoom_sliding:
		var value: float = zoom_slider.max_value - (zoom_slider.value - zoom_slider.min_value)
		SignalBus.zoom_map.emit(value)

func _on_viewport_resize():
	var vp = get_viewport()
	if vp != null:
		var vp_size = Vector2(vp.size)
		position.x = 80
		#position.y = vp_size.y + 80
		
func _top_pressed() -> void:
	Logger.log_event("shift_up_start", {})
	SignalBus.view_control_activated.emit(true)
	translate_icon.texture = load("res://Assets/img/view_control_translate_top-02.png")
	_top_is_pressed = true
	
func _top_released() -> void:
	Logger.log_event("shift_up_end", {})
	SignalBus.view_control_activated.emit(false)
	translate_icon.texture = load("res://Assets/img/view_control_translate-01.png")
	_top_is_pressed = false
	
func _bottom_pressed() -> void:
	Logger.log_event("shift_down_start", {})
	SignalBus.view_control_activated.emit(true)
	translate_icon.texture = load("res://Assets/img/view_control_translate_bottom-02.png")
	_bottom_is_pressed = true
	
func _bottom_released() -> void:
	Logger.log_event("shift_down_end", {})
	SignalBus.view_control_activated.emit(false)
	translate_icon.texture = load("res://Assets/img/view_control_translate-01.png")
	_bottom_is_pressed = false
	
func _right_pressed() -> void:
	Logger.log_event("shift_right_start", {})
	SignalBus.view_control_activated.emit(true)
	translate_icon.texture = load("res://Assets/img/view_control_translate_right-02.png")
	_right_is_pressed = true
	
func _right_released() -> void:
	Logger.log_event("shift_right_end", {})
	SignalBus.view_control_activated.emit(false)
	translate_icon.texture = load("res://Assets/img/view_control_translate-01.png")
	_right_is_pressed = false
	
func _left_pressed() -> void:
	Logger.log_event("shift_left_start", {})
	SignalBus.view_control_activated.emit(true)
	translate_icon.texture = load("res://Assets/img/view_control_translate_left-02.png")
	_left_is_pressed = true
	
func _left_released() -> void:
	Logger.log_event("shift_left_end", {})
	SignalBus.view_control_activated.emit(false)
	translate_icon.texture = load("res://Assets/img/view_control_translate-01.png")
	_left_is_pressed = false
	
func _rotate_pressed() -> void:
	SignalBus.view_control_activated.emit(true)
	rotate_icon.texture = load("res://Assets/img/view_control_rotate_pressed-01.png")
	_rotate_is_pressed = true
	
func _rotate_released() -> void:
	SignalBus.view_control_activated.emit(false)
	rotate_icon.texture = load("res://Assets/img/view_control_rotate-01.png")
	_rotate_is_pressed = false
	
func rotate_set(angle) -> void:
	rotate_icon.rotation = angle
	SignalBus.rotate_map.emit(rotate_icon.rotation)
	
func _tilt_start() -> void:
	SignalBus.view_control_activated.emit(true)
	tilt_slider.add_theme_icon_override("grabber", _slider_pressed_img)
	tilt_slider.add_theme_icon_override("grabber_highlight", _slider_pressed_img)
	tilt_slider.add_theme_icon_override("grabber_disabled", _slider_pressed_img)
	_tilt_sliding = true
	
func _tilt_end(_value_changed: bool) -> void:
	SignalBus.view_control_activated.emit(false)
	tilt_slider.add_theme_icon_override("grabber", _slider_idle_img)
	tilt_slider.add_theme_icon_override("grabber_highlight", _slider_idle_img)
	tilt_slider.add_theme_icon_override("grabber_disabled", _slider_idle_img)
	_tilt_sliding = false
	
func tilt_set(value: float) -> void:
	tilt_slider.value = value
	SignalBus.tilt_map.emit(tilt_slider.value)

func _zoom_start() -> void:
	Logger.log_event("zoom_start", {"val": zoom_slider.value})
	SignalBus.view_control_activated.emit(true)
	zoom_slider.add_theme_icon_override("grabber", _slider_pressed_img)
	zoom_slider.add_theme_icon_override("grabber_highlight", _slider_pressed_img)
	zoom_slider.add_theme_icon_override("grabber_disabled", _slider_pressed_img)
	_zoom_sliding = true
	
func _zoom_end(_value_changed: bool) -> void:
	Logger.log_event("zoom_end", {"val": zoom_slider.value})
	SignalBus.view_control_activated.emit(false)
	zoom_slider.add_theme_icon_override("grabber", _slider_idle_img)
	zoom_slider.add_theme_icon_override("grabber_highlight", _slider_idle_img)
	zoom_slider.add_theme_icon_override("grabber_disabled", _slider_idle_img)
	_zoom_sliding = false
	
func zoom_set(value: float) -> void:
	zoom_slider.value = zoom_slider.max_value - (value - zoom_slider.min_value)
	Logger.log_event("zoom_mouse", {"val": zoom_slider.value})

func _show_tutorial_arrow() -> void:
	tutorial_arrow.show()
