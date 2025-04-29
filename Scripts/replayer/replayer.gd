extends Node

class_name Replayer

# instance vars
var loaded: bool
var running: bool
var time_passed: int
var recording: PackedStringArray
var curr_recording_idx: int
var timestamp_on_deck: int 
var event_on_deck: Dictionary


# Called when the node enters the scene tree for the first time.
func _ready():
	loaded = false
	running = false

func load_recording(recording: PackedStringArray) -> void:
	if len(recording) == 0:
		return
	self.recording = recording
	time_passed = 0
	curr_recording_idx = 0
	timestamp_on_deck = _get_next_event_timestamp()
	event_on_deck = _get_next_event_content()

func start() -> void:
	running = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if running:
		var delta_msec = round(int(delta * 1000))
		time_passed += delta_msec
		if time_passed > timestamp_on_deck:
			_execute_next_event()
			if curr_recording_idx >= len(recording) - 2:
				running = false
				return
			_tick_event()
			
func _execute_next_event() -> void:
	var event = event_on_deck
	var subject = event["subject"]
	var data = event["data"]
	if subject == "options":
		pass
	if subject == "control_panel_toggle_drawing_board":
		SignalBus.toggle_drawing_board.emit()
	if subject == "control_panel_toggle_play":
		SignalBus.toggle_play.emit()
	if subject == "control_panel_toggle_map":
		SignalBus.toggle_map.emit()
	if subject == "control_panel_toggle_map_build_mode":
		SignalBus.toggle_map_build_mode.emit()
	if subject == "control_panel_toggle_map_param_mode":
		SignalBus.toggle_map_param_mode.emit()
	if subject == "control_panel_toggle_map_uncertainty_mode":
		SignalBus.toggle_map_uncertainty_mode.emit()
	if subject == "control_panel_save":
		SignalBus.on_save_map.emit()
	if subject == "control_panel_load":
		SignalBus.on_load_map.emit()
	if subject == "cam_map":
		SignalBus.set_map_cam.emit(int(data["mode"]), int(data["size"]), int(data["z"]))
	if subject == "cam_drawingboard":
		SignalBus.set_drawing_board_cam.emit(int(data["x"]), int(data["y"]), int(data["zoom_x"]), int(data["zoom_y"]))
	if subject == "input_goal_automaton":
		SignalBus.set_input_goal_automata.emit(data)
	
func _tick_event() -> void:
	curr_recording_idx += 1
	timestamp_on_deck = _get_next_event_timestamp()
	event_on_deck = _get_next_event_content()
			
func _get_next_event_timestamp() -> int:
	var event: String = recording[curr_recording_idx]
	var end_idx = event.find("-") - 1
	return int(event.substr(0, end_idx))
	
func _get_next_event_content() -> Dictionary:
	var event: String = recording[curr_recording_idx]
	var start_idx = event.find("-") + 2
	var json = JSON.new()
	var event_content = event.substr(start_idx, len(event))
	var status = json.parse(event_content)
	if status == OK:
		var data_received = json.data
		if typeof(data_received) == TYPE_ARRAY:
			print(data_received) # Prints array
		else:
			print("Unexpected data")
	else:
		print("JSON Parse Error: ", json.get_error_message(), " at line ", json.get_error_line())
	var data = json.get_data()
	return data
	
