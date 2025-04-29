extends PanelContainer

@onready var step_label := $CameraTutorialVBox/CurrentInstruction/VBoxContainer/StepLabel as Label
@onready var todo_desc := $CameraTutorialVBox/CurrentInstruction/VBoxContainer/InstructionLabel as Label
@onready var todo_items := $CameraTutorialVBox/CheckList/VBoxContainer/CheckboxItems as VBoxContainer
@onready var button := $CameraTutorialVBox/CurrentInstruction/VBoxContainer/Button as Button

# instance variables
var state: int
var introed_view_controls: bool
var introed_view_arrows: bool
var introed_view_zoom: bool
var curr_step: int

# todo items (not all initialized)
var arrow_todo: CheckboxItem
var zoom_slider_todo: CheckboxItem
var tilt_todo: CheckboxItem
var rotate_todo: CheckboxItem

var checkbox_scene := load("res://Scenes/map/camera_tutorial/checkbox.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	
	'''
	This tutorial is a transition system with the following states:
		- 1: attempt to teach map drag
		- 11: can't drag -- intro camera controls
		- 12: teach camera control arrows
		- 2: attempt to teach scroll wheel zoom
		- 21: can't zoom with scroll wheel - intro camera controls
		- 22: teach slider zoom
		- 3: intro camera controls
		- 4: teach camera control arrows
		- 5: teach camera control zoom
		- 6: teach tilt
		- 7: teach rotate
	'''
	state = 1
	introed_view_controls = false
	introed_view_arrows = false
	introed_view_zoom = false
	arrow_todo = todo_items.get_children()[0]
	curr_step = 1

	# tutorial checkpoint signals
	SignalBus.translate_map.connect(_on_arrows_pressed)
	SignalBus.zoom_map.connect(_on_zoom_slider_used)
	SignalBus.tilt_map.connect(_on_tilt_used)
	SignalBus.rotate_map.connect(_on_rotate_used)
	
	# resize control
	get_viewport().connect("size_changed", _on_viewport_resize)
	_on_viewport_resize()
	
func _transition() -> void:
	# 1-2 OR 1-11
	if state == 1:
		arrow_todo.complete()
		_increment_step()
		_set_to_state_2()
	elif state == 2:
		zoom_slider_todo.complete()
		_increment_step()
		_set_to_finished()
		#_set_to_state_3()
	elif state == 3:
		tilt_todo.complete()
		_increment_step()
		_set_to_state_4()
	elif state == 4:
		rotate_todo.complete()
		_set_to_finished()

func _on_next() -> void:
	_transition()
	
func _on_arrows_pressed(vec: Vector3) -> void:
	if state == 1:
		arrow_todo.complete()
		_transition()

func _on_zoom_slider_used(val: float) -> void:
	if state == 2:
		zoom_slider_todo.complete()
		_transition()
	
func _on_tilt_used(val: float) -> void:
	if state == 3:
		tilt_todo.complete()
		_transition()
		
func _on_rotate_used(val: float) -> void:
	if state == 4:
		rotate_todo.complete()
		_transition()
	
func _add_blank_todo_item(msg: String) -> CheckboxItem:
	var new_todo = checkbox_scene.instantiate()
	todo_items.add_child(new_todo)
	new_todo.set_text(msg)
	return new_todo
	
func _increment_step() -> void:
	curr_step += 1
	step_label.text = "Step " + str(curr_step)
	
func _set_to_finished() -> void:
	step_label.text = "Finished!"
	todo_desc.text = "BONUS: move the map by right-clicking and dragging, and zoom in and out by scrolling the mouse wheel."
	SignalBus.hide_arrow.emit()
	SignalBus.send_to_parent_html_frame.emit("allowproceed", "")
	
func _set_to_state_2() -> void:
	zoom_slider_todo = _add_blank_todo_item("use horizontal slider to zoom")
	todo_desc.text = "Use the horizontal slider below to zoom in and out."
	SignalBus.arrow_point_at_zoom_slider.emit()
	state = 2
	
func _set_to_state_3() -> void:
	tilt_todo = _add_blank_todo_item("use vertical slider to tilt")
	todo_desc.text = "Use the vertical slider below to tilt the angle of the map."
	SignalBus.arrow_point_at_tilt_slider.emit()
	state = 3
	
func _set_to_state_4() -> void:
	rotate_todo = _add_blank_todo_item("use compass to rotate")
	todo_desc.text = "Turn the compass below to rotate the map."
	SignalBus.arrow_point_at_compass.emit()
	state = 4

func _on_viewport_resize() -> void:
	position.x = 60
	position.y = 60	
