extends Node

@onready var cl := $CanvasLayer as CanvasLayer
@onready var pid_label := $CanvasLayer/Label as Label

# instance variables
var curr_procedure
var procedures: Dictionary
var user_files: Array
var _curr_file: String
var _space_key_mapping: String
var analysis_results: String

signal update_pid(pid: String)

func _ready() -> void:
	curr_procedure = null
	procedures = {
		"uncert": ["_randomize_item_order",
				   "_load_begin_screen",
				   "_load_map",
				   "_activate_uncert_mode",
				   "_hide_control_panel",
				   "_show_done_button"],
		"camera_tutorial": [
			"_load_map",
			"_activate_uncert_mode",
			"_hide_control_panel",
			"_hide_uncert_key",
			"_hide_uncert_controls",
			"_show_camera_tutorial"
		],
		"uncert_analysis": [
			"_hide_control_panel",
			"_perform_uncert_analysis"
		]
	}
	SignalBus.analyze_next_user.connect(_pre_process_next_user_file_callback)
	analysis_results = ""
	SignalBus.completed_analysis_results.connect(_add_analysis_results)
	user_files = []
	_space_key_mapping = "_do_nothing"
	update_pid.connect(_update_pid_label)

func _process(delta: float) -> void:
	if curr_procedure != null:
		if len(procedures[curr_procedure]) == 0:
			curr_procedure = null
			return
		var exec: String = procedures[curr_procedure][0]
		procedures[curr_procedure].remove_at(0)
		call_deferred(exec)

func initiate_uncert_experiment() -> void:
	curr_procedure = "uncert"
	
func initiate_camera_tutorial() -> void:
	curr_procedure = "camera_tutorial"
	
func initiate_uncert_analysis() -> void:
	curr_procedure = "uncert_analysis"
	update_pid.emit("pending pid")
	
func _update_pid_label(pid: String) -> void:
	cl.show()
	pid_label.position = Vector2(0, 0)
	pid_label.text = pid

func _perform_uncert_analysis() -> void:
	var dir = DirAccess.open("res://Resources/data/study")
	Options.add_option("umbrella_gt1", "")
	Options.add_option("umbrella_gt2", "")
	Options.add_option("umbrella_gt3", "")
	Options.add_option("bag_gt1", "")
	Options.add_option("bag_gt2", "")
	Options.add_option("bag_gt3", "")
	Options.opts.load_uncert = true
	Options.opts.uncert_experiment = true
	if dir:
		dir.list_dir_begin()
		var subdir_name = dir.get_next()
		while subdir_name != "":
			
			# check if to avoid for manual analysis
			var file = FileAccess.open("res://Resources/data/study/" + subdir_name + "/checked.txt", FileAccess.READ)
			if Options.opts.manual_analysis and file != null:
				subdir_name = dir.get_next()
				continue
			
			# check if is directory
			file = FileAccess.open("res://Resources/data/study/" + subdir_name + "/slider.txt", FileAccess.READ)
			if file == null:
				subdir_name = dir.get_next()
				continue
			
			# slider
			var slider_file = "study/" + subdir_name + "/slider.txt"
			user_files.append(slider_file)
			
			# paint
			var paint_file = "study/" + subdir_name + "/paint.txt"
			user_files.append(paint_file)
			
			# rank
			var rank_file = "study/" + subdir_name + "/rank.txt"
			user_files.append(rank_file)
			
			# next participant
			subdir_name = dir.get_next()
	_process_next_user_file_callback()
	
func _pre_process_next_user_file_callback() -> void:
	if Options.opts.manual_analysis:
		SignalBus.remove_end_screen.emit()
		_space_key_mapping = "_process_next_user_file_callback"
	else:
		_process_next_user_file_callback()
	
func _process_next_user_file_callback() -> void:
	# clear map (if map is loaded)
	SignalBus.reset_param_panel.emit()
	SignalBus.remove_end_screen.emit()
	SignalBus.reset_world.emit()
	SignalBus.reset_map_in_space.emit()
	# hide all waypoints
	# SignalBus.deactivate_waypoints.emit()
	await get_tree().create_timer(2.0).timeout
	
	# run the user file
	var thread = Thread.new()
	thread.start(_process_next_user_file)
			
func _process_next_user_file() -> void:
	# reset options
	Options.opts.uncert_sliders = false
	Options.opts.uncert_paint = false
	Options.opts.uncert_rank = false
	if len(user_files) == 0:
		print(analysis_results)
		var file = FileAccess.open("res://Resources/data/study/results.txt", FileAccess.WRITE)
		file.store_string(analysis_results)
		return
	_curr_file = user_files[0]
	var pid = _curr_file.substr(_curr_file.find("/") + 1)
	pid = pid.substr(0, pid.find("/"))
	(func(): update_pid.emit(pid)).call_deferred()
	var cond = ""
	user_files.remove_at(0)
	if "slider" in _curr_file:
		Options.opts.uncert_sliders = true
		cond = "slider"
	elif "paint" in _curr_file:
		Options.opts.uncert_paint = true
		cond = "paint"
	else:
		Options.opts.uncert_rank = true
		cond = "rank"
	var dirstr = "C:/Users/David/Documents/papers/HRI2025/analysis/accuracy/" + pid
	var dir = DirAccess.open(dirstr)
	var paint_order = -1
	var slider_order = -1
	var rank_order = -1
	if dir:
		dir.list_dir_begin()
		var subdir_name = dir.get_next()
		while subdir_name != "":
			if subdir_name.substr(0, 7) == "results" and subdir_name.substr(7, 10) != "_same_room":
				if "paint" in subdir_name:
					paint_order = int(subdir_name.substr(7, 1))
				elif "sliders" in subdir_name:
					slider_order = int(subdir_name.substr(7, 1))
			subdir_name = dir.get_next()
		rank_order = 1
		if paint_order == 1 or slider_order == 1:
			rank_order = 2
			if paint_order == 2 or slider_order == 2:
				rank_order = 3
	Options.opts.load_uncert_file = _curr_file
	await get_tree().create_timer(1.0).timeout
	_randomize_item_order()
	await get_tree().create_timer(1.0).timeout
	_load_begin_screen()
	SignalBus.reset_map_in_space.emit()
	await get_tree().create_timer(2.0).timeout
	_load_map()
	await get_tree().create_timer(2.0).timeout
	_activate_uncert_mode()
	await get_tree().create_timer(2.0).timeout
	# get the ground truth
	if cond == "slider":
		_activate_waypoints(dirstr + "/ground_truth" + str(slider_order) + ".txt")
	elif cond == "paint":
		_activate_waypoints(dirstr + "/ground_truth" + str(paint_order) + ".txt")
	else:
		_activate_waypoints(dirstr + "/ground_truth" + str(rank_order) + ".txt")
	SignalBus.press_begin.emit()
	if Options.opts.manual_analysis:
		_space_key_mapping = "_process_next_user_file_helper1"
	else:
		await get_tree().create_timer(2.0).timeout
		_process_next_user_file_helper1()
	
func _process_next_user_file_helper1() -> void:
	_space_key_mapping = "_do_nothing"
	# press done
	SignalBus.participant_finished.emit()
	SignalBus.reset_map_in_space.emit()
	await get_tree().create_timer(1.0).timeout
	SignalBus.be_done.emit()
	await get_tree().create_timer(2.0).timeout
	SignalBus.press_begin.emit()
	await get_tree().create_timer(2.0).timeout
	# press done
	if Options.opts.manual_analysis:
		_space_key_mapping = "_process_next_user_file_helper2"
	else:
		await get_tree().create_timer(1.0).timeout
		_process_next_user_file_helper2()
	
func _process_next_user_file_helper2() -> void:
	_space_key_mapping = "_do_nothing"
	SignalBus.participant_finished.emit()
	await get_tree().create_timer(1.0).timeout
	SignalBus.be_done.emit()
	
func _do_nothing() -> void:
	pass
	
func _activate_waypoints(dirstr: String) -> void:
	print("activating waypoints from " + dirstr)
	var ground_truth = FileAccess.open(dirstr, FileAccess.READ)
	var json = JSON.new()
	var status = json.parse(ground_truth.get_line())
	var data = json.get_data()
	var prev_pt: int = -1
	var intervals: Array[int] = []
	for pt in data["orderedUmbrellaIntervals"]:
		intervals.append(int(pt) - int(prev_pt))
		prev_pt = pt
	var i: int = 0
	for umb_loc in data["orderedUmbrellaLocations"]:
		Options.opts["umbrella_gt" + str(i+1)] = umb_loc
		SignalBus.activate_waypoint.emit(umb_loc, intervals[i], Color.CYAN)
		i += 1
	prev_pt = -1
	intervals = []
	for pt in data["orderedBagIntervals"]:
		intervals.append(int(pt) - int(prev_pt))
		prev_pt = pt
	i = 0
	for bag_loc in data["orderedBagLocations"]:
		Options.opts["bag_gt" + str(i+1)] = bag_loc
		SignalBus.activate_waypoint.emit(bag_loc, intervals[i], Color.GOLDENROD)
		i += 1
		
func _add_analysis_results(results: String) -> void:
	analysis_results += _curr_file + "\n"
	analysis_results += results + "\n\n"
	
func _randomize_item_order() -> void:
	var items: Array[String] = ["umbrella", "bag"]
	var starter: String = items[randi() % items.size()]
	Options.add_option("curr_item", starter)
	Options.add_option("items_specified", "1")
	SignalBus.send_to_parent_html_frame.emit("itemOrder", starter + " first")
	SignalBus.set_curr_item.emit(starter)
	
func _load_begin_screen() -> void:
	SignalBus.load_begin_screen.emit()

func _load_map() -> void:
	SignalBus.load_map.emit()
	
func _activate_uncert_mode() -> void:
	SignalBus.activate_uncert_mode.emit()
	
func _hide_control_panel() -> void:
	SignalBus.hide_control_panel.emit()
	
func _show_done_button() -> void:
	SignalBus.add_done_button.emit()

func _hide_uncert_key() -> void:
	SignalBus.show_uncert_key.emit(false)
	
func _hide_uncert_controls() -> void:
	SignalBus.show_uncert_controls.emit(false)

func _show_camera_tutorial() -> void:
	SignalBus.show_tutorial_menu.emit(true)
	# show tutorial arrow
	SignalBus.show_arrow.emit()
	SignalBus.arrow_point_at_arrows.emit()
	
func _input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_SPACE):
		call(_space_key_mapping)
