extends Control

class_name SetPlan

var plan_snippet_scene := load("res://Scenes/linear_GA/timeline_scenes/plan_output.tscn")
var checkpt := load("res://Scenes/linear_GA/inherited_checkpoint_scenes/not_init_checkpoint.tscn")
var top_plus_button := load("res://Scenes/linear_GA/button_scenes/top_plus_button.tscn")
var bottom_plus_button := load("res://Scenes/linear_GA/button_scenes/bottom_plus_button.tscn")

# ids
var init_id : int
var curr_id : int = 1
var tracker : int = 0
var separator_count = 0
var temp_scene = null
#
#func _ready():
	#SignalBus.set_plan.connect(on_set_plan_init_again)

func _on_add_helper(scene : PackedScene, index : int, button_type : PackedScene):
	# add node to timeline
	var new_scene = scene.instantiate()
	get_parent().add_child(new_scene)
	get_parent().move_child(new_scene, index)
	
	# create custom size for plus button
	if scene == button_type:
		new_scene.custom_minimum_size.x = 280
		new_scene.custom_minimum_size.y = 130
	
	update_checkpt_ids()

	# create custom size for new checkpoint and set plan
	if scene == checkpt:
		new_scene.custom_minimum_size.y = 385
		
		# temporary change color of checkpoint to indicate to user that it is the newly created one
		var color = Color.GRAY
		var chkpt_style = new_scene.get_node("UI/MainPanel").get_theme_stylebox("panel").duplicate()
		chkpt_style.bg_color = color
		new_scene.get_node("UI/MainPanel").add_theme_stylebox_override("panel", chkpt_style)
		
		var timer = Timer.new()
		get_parent().add_child(timer)
		timer.wait_time = 0.5
		timer.one_shot = true
		timer.paused = false
		timer.start()
		
		temp_scene = new_scene
		timer.connect("timeout", on_timer_timeout)
		
		if button_type == top_plus_button:			
			# set plan
			new_scene.set_top_checkpt_val(true)
			new_scene.set_plan_val(false)
			for i in get_parent().get_children():
				if i is Checkpoint and i.id >= new_scene.id - 1:
					i.set_plan_val(false)
					SignalBus.set_plan.connect(on_set_plan_top)
		elif button_type == bottom_plus_button:
			# moves scrollbar down when adding bottom checkpoints
			var scroll_container = get_parent().get_parent().get_parent()
			await scroll_container.get_v_scroll_bar().changed
			scroll_container.scroll_vertical += 525
			
			new_scene.set_bottom_checkpt_val(true)
			new_scene.set_plan_val(false)
			for i in get_parent().get_children():
				if i is Checkpoint and i.id >= new_scene.id - 1:
					i.set_plan_val(false)
					SignalBus.set_plan.connect(on_set_plan_bottom)
					
func on_timer_timeout():
	var original_color = Color(0.03, 0.13, 0.14, 1.00)
	var original_chkpt_style = temp_scene.get_node("UI/MainPanel").get_theme_stylebox("panel").duplicate()
	original_chkpt_style.bg_color = original_color
	temp_scene.get_node("UI/MainPanel").add_theme_stylebox_override("panel", original_chkpt_style)

func update_checkpt_ids():
	var id_count = 1
	if get_parent() != null:
		for i in get_parent().get_children():
			if i is Checkpoint:
				get_parent().get_child(i.get_index()).set_id(id_count)
				id_count += 1
				
func on_set_plan_init_again(plan_data : Dictionary) -> void:
	if get_parent() != null:
		for i in get_parent().get_children():
			if i is Checkpoint:
				if i.is_init_checkpt == true and i.id > 1:
					print("init checkpoint:", i.id)
					on_set_plan(plan_data, i, get_parent())
					#i.set_plan_val(true)

func on_set_plan_top(plan_data : Dictionary) -> void:
	if get_parent() != null:
		var chkpt_count = 0
		for i in get_parent().get_children():
			if i is Checkpoint:
				if i.is_top_checkpt == true and i.is_plan_set == false:
					print("top checkpoint: ", i.id)
					on_set_plan(plan_data, i, get_parent())
					#i.set_plan_val(true)
				elif i.is_init_checkpt == true:
					print("INIT CHECKPOINT: ", i.id)
					on_set_plan_helper(plan_data, init_id, i.id, i.get_index(), get_parent())
					
func on_set_plan_bottom(plan_data : Dictionary) -> void:
	if get_parent() != null:
		for i in get_parent().get_children():
			if i is Checkpoint:
				if i.is_bottom_checkpt == true and i.id == curr_id:
					i.set_plan_val(false)
				if i.is_bottom_checkpt == true and i.is_plan_set == false:
					print("bottom checkpoint: ", i.id)
					on_set_plan(plan_data, i, get_parent())
					#i.set_plan_val(true)
		
func on_set_plan(plan_data : Dictionary, checkpt : Checkpoint, chkpt_container : VBoxContainer) -> void:
	var checkpt_idx = checkpt.get_index()
	if checkpt.id == 1:
		on_set_plan_helper(plan_data, init_id, curr_id, checkpt_idx, chkpt_container)
	else:
		var count = 0
		if count == 0:
			init_id = chkpt_container.get_child(checkpt.get_index()).id - 2
			curr_id = chkpt_container.get_child(checkpt.get_index()).id
			on_set_plan_helper(plan_data, init_id, curr_id, checkpt_idx, chkpt_container)
			count += 1

func on_set_plan_helper(plan_data : Dictionary, init_id : int, curr_id : int, 
							checkpt_idx : int, chkpt_container : VBoxContainer) -> void:	
	# retrieve vbox container for plan visualizer
	var vbox = chkpt_container.get_child(checkpt_idx - 1)
	
	# reset vbox container
	if vbox.get_child_count() != 0:
		for child in vbox.get_children():
			vbox.remove_child(child)
	 #
	# search for the transition with the source id
	var curr_trans = null
	for trans_data in plan_data["serTrans"]:
		if trans_data["sourceID"] == init_id:
			curr_trans = trans_data
			break
	
	if curr_trans == null:
		return
		
	# walk through transitions until final target id is reached
	var temp_arr = []
	var prev_vbox = null
	var duplicate = null
	while curr_trans["targetID"] != curr_id:
		var target_data = null
		for states_data in plan_data["serStates"]:
			if states_data["_id"] == curr_trans["targetID"]:
				target_data = states_data
				break
		
		# returns if no there is no plan created between checkpoints
		var count = 0
		for trans_data in plan_data["serTrans"]:
			if trans_data["sourceID"] == target_data["_id"]:
				curr_trans = trans_data
				break
			else:
				count += 1
				
		if count == plan_data["serTrans"].size():
			if vbox.get_child_count() != 0:
				for child in vbox.get_children():
					#await get_tree().create_timer(0.25).timeout
					if child != null and is_instance_valid(child):
						child.queue_free()
						child = null
			return
			
		# sets action name and description to plan snippet	
		var target_data_nl: String = target_data.nl
		var action_name: String = target_data_nl.substr(0, target_data_nl.find(":"))
		var action_description: String = target_data_nl.substr(target_data_nl.find(":") + 2)
		var plan_snippet = plan_snippet_scene.instantiate()
		plan_snippet.set_name_val(action_name)
		plan_snippet.set_desc_val(action_description)
		plan_snippet.get_node("Panel/Label").text = action_description.to_lower()
		plan_snippet.custom_minimum_size.y = 130
		
		# populate temporary array with plan snippets
		if target_data["name"].findn("checkpoint") == -1:
			temp_arr.append(plan_snippet)
	
	print("=====TEST TEMP ARRAY=====")
	for i in temp_arr:
		print("Current id: ", curr_id, ", Plan: ", i.get_node("Panel/Label").text)
	
	# check whether or not there is a split. if so, find the location of the split
	var split_found = false
	var split_idx = -1
	for i in temp_arr:
		if i.get_node("Panel/Label").text == "":
			split_found = true
			split_idx = temp_arr.find(i)
			break
		
	# if split found, retrieve the previous checkpoint's container holding the plan snippets
	if split_found == true:	
		# retrieve previous vbox container
		for i in chkpt_container.get_children():
			if i is Checkpoint and i.id == curr_id - 1:
				prev_vbox = chkpt_container.get_child(i.get_index() - 1)
				break
		
		# remove plan from previous vbox container
		if prev_vbox != null:
			for i in prev_vbox.get_children():
				prev_vbox.remove_child(i)
			
		# check which checkpoint plan should be added to
		for i in temp_arr:
			if i.get_node("Panel/Label").text != "":
				if temp_arr.find(i) < split_idx:
					if prev_vbox != null:
						prev_vbox.add_child(i)
				if temp_arr.find(i) > split_idx:
					vbox.add_child(i)
		
		# add plan back to checkpoint when deleting a checkpoint
		if vbox.get_child_count() == 0:
			for i in temp_arr:
				if i.get_node("Panel/Label").text != "":
					vbox.add_child(i)
	
	# add plan snippets just for the current checkpoint if no split was found
	if split_idx == -1:		
		# retrieve previous vbox container
		for i in chkpt_container.get_children():
			if i is Checkpoint and i.id == curr_id - 1:
				prev_vbox = chkpt_container.get_child(i.get_index() - 1)
				break
		
		# store previous plan snippets into an array
		#print("=====PREVIOUS PLAN=====")
		var prev_vbox_arr = []
		if prev_vbox != null and prev_vbox.get_child_count() != 0:
			for i in prev_vbox.get_children():
				#print(i.get_node("Panel/Label").text)
				prev_vbox_arr.append(i.get_node("Panel/Label").text)
		
		# add plan snippets to current checkpoint
		#print("=====CURRENT PLAN=====")
		for i in temp_arr:
			if i.get_node("Panel/Label").text not in prev_vbox_arr:
				vbox.add_child(i)
				#print(i.get_node("Panel/Label").text)
			
func on_timeout():
	var timer = Timer.new()
	timer.wait_time = 0.25
	timer.start()
