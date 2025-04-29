'''
License: 
Others' Code used/adapted/modified:
	 1. URL(s): https://kidscancode.org/godot_recipes/3.x/2d/line_collision/index.html
				https://github.com/kidscancode/godot_recipes/blob/master/docs/3.x/2d/line_collision/index.html
		License: https://github.com/kidscancode/godot_recipes/blob/master/LICENSE
				 (MIT License)
		SHA (if found on git): f9ee16593f6bc03f7d2ce2f0d761f27cc3cca2f6
'''

extends Line2D

class_name Arc

# other scenes
var collider_scene := load("res://Scenes/DrawingBoard/arc_collider.tscn")
var hint_scene := load("res://Scenes/DrawingBoard/action.tscn")
var buttons_scene := load("res://Scenes/DrawingBoard/arc_buttons.tscn")

# instance variables
var buttons: HBoxContainer
var split_arc_button: Button
var toggle_hints_button: Button
var source: Node
var target: Node
var hints: Array[Action]

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func create_collision_bounds() -> void:
	# remove any existing collision bounds
	for n in get_children():
		if n is ArcCollider:
			remove_child(n)
			n.queue_free()
	
	# add new collision bounds
	''' Code used/adapted/modified from 1 '''
	for i in points.size() - 1:
		var collider = collider_scene.instantiate()
		add_child(collider)
		var pt1: Vector2 = points[i]
		var pt2: Vector2 = points[i+1]
		collider.add_bounds(pt1, pt2)
	'''End code used/adapted/modified from 1'''
	
func _on_split_arc() -> void:
	SignalBus.split_arc.emit(self)
	
func _on_toggle_hints() -> void:
	SignalBus.toggle_hints.emit()

func toggle_hints(toggled_status) -> void:
	var image
	if toggled_status:
		image = Image.load_from_file("res://Assets/img/shown-01.png")
	else:
		image = Image.load_from_file("res://Assets/img/hidden-01.png")
	var tex = ImageTexture.create_from_image(image)
	toggle_hints_button.icon = tex
	
func on_set_plan(plan_data: Dictionary) -> void:
	# see if a checkpoint target exists
	if target is not Checkpoint:
		return
	
	# clear any action hints on the arc
	for n in get_node("hints").get_children():
		remove_child(n)
		n.queue_free()
		
	# reset the hints array
	hints.clear()
		
	# search for the transition with the source id
	var curr_trans = null
	for trans_data in plan_data["serTrans"]:
		if trans_data["sourceID"] == source.id:
			curr_trans = trans_data
			break
				
	if curr_trans == null:
		return
	
	# walk through transitions until target id is reached
	var final_state = source.final_state
	while curr_trans["targetID"] != target.id:
		var target_data = null
		for st_data in plan_data["serStates"]:
			if st_data["_id"] == curr_trans["targetID"]:
				target_data = st_data
				break
		for trans_data in plan_data["serTrans"]:
			if trans_data["sourceID"] == target_data["_id"]:
				curr_trans = trans_data
				break
		var nl: String = target_data.nl
		var act_name: String = nl.substr(0, nl.find(":"))
		var act_desc: String = nl.substr(nl.find(":")+2)
		var hint = hint_scene.instantiate()
		hint.set_name_val(act_name)
		hint.set_desc_val(act_desc)
		hint.set_final_state(_parse_action_final_state(target_data.final_state))
		hint.get_node("Label").text = act_desc.to_lower()
		hint.set_action_params(target_data["actions"][0]["parameters"])
		get_node("hints").add_child(hint)
		hints.append(hint)
		final_state = hint.final_state
	target.set_final_state(final_state)
	position_hints()
	position_split_button()
	
func _parse_action_final_state(raw_fs: Array) -> Array:
	var final_state: Array = []
	for pred_data in raw_fs:
		if len(pred_data.parameters) == 0:
			final_state.append({"symbol": pred_data.name, "parameters": []})
		else:
			for param_data in pred_data.parameters:
				var pred = {"symbol": pred_data.name, "parameters": param_data.param_tup}
				final_state.append(pred)
	return final_state
	
func position_hints():	
	var length = (points[-1].y - points[0].y) / (len(hints) + 1)
	var curr_pos = points[0].y + length
	for hint in hints:
		hint.position = source.position
		hint.position.y = curr_pos
		curr_pos += length
		
func position_split_button():
	if buttons == null:
		buttons = buttons_scene.instantiate()
		add_child(buttons)
		split_arc_button = buttons.get_node("split_arc_button")
		toggle_hints_button = buttons.get_node("toggle_hints")
		split_arc_button.pressed.connect(_on_split_arc)
		toggle_hints_button.pressed.connect(_on_toggle_hints)
	buttons.position = midpoint()
	buttons.position.x += 10

func reposition() -> void:
	var mp: PanelContainer = source.get_node("UI/MainPanel")
	var diff: int = (source.position.y + mp.size.y) - points[0].y
	points[-1].y += diff
	points[0].y += diff
	target.reposition(diff)
	
func set_traversable(val: bool) -> void:
	if val:
		default_color.a = 1.0
	else:
		default_color.a = 0.25
	
func reset() -> void:
	points[-1] = target.position
	position_hints()
	position_split_button()
	
func midpoint() -> Vector2:
	return points[0] + ((points[-1] - points[0])/2.0)
	
func get_predecessors_and_successors() -> Array[Control]:

	# populate the plan visualizer
	var elements: Array[Control] = []
	
	# first get the parents of act
	var start = source
	elements.append(start)
	while start is not InitCheckpoint:
		for in_trans in start.in_trans:
			var hints: Array[Action] = in_trans.hints.duplicate()
			hints.reverse()
			elements.append_array(hints)
			elements.append(in_trans.source)
			start = in_trans.source
			break    # only traverse 1 parent if there are > 1
	
	# then get the actions on the current arc
	elements.reverse()
	elements.append_array(hints)
	elements.append(target)
	# then get the future actions UNTIL a branch occurs
	var end = target
	while end is Checkpoint and len(end.out_trans) > 0:
		if len(end.out_trans) > 1:
			break  # branch. Break.
		var arc = end.out_trans[0]
		elements.append_array(arc.hints)
		elements.append(arc.target)
		end = arc.target
		
	return elements

func build_simulator_steps() -> Array[Control]:

	# populate the plan visualizer
	var elements: Array[Control] = []
	
	# first get the parents of act
	var start = source
	elements.append(start)

	# then get the actions on the current arc
	elements.reverse()
	elements.append_array(hints)
	elements.append(target)
	# then get the future actions UNTIL a branch occurs
	var end = target
	while end is Checkpoint and len(end.out_trans) > 0:
		if len(end.out_trans) > 1:
			break  # branch. Break.
		var arc = end.out_trans[0]
		elements.append_array(arc.hints)
		elements.append(arc.target)
		end = arc.target
		
	return elements

func jsonify() -> Dictionary:
	var to_return = {}
	to_return["sourceID"] = source.id
	to_return["targetID"] = target.id
	to_return["condition"] = {"name": ""}
	to_return["triggeringEvent"] = {"triggerName": ""}
	if Options.opts.log_to_backend:
		to_return["actions"] = []
		for hint in hints:
			to_return["actions"].append({
				"name": hint.action_name,
				"desc": hint.action_desc,
				"final_state": hint.final_state
			})
	return to_return
