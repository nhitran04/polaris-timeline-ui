extends Node

# references to children
@onready var simrobot := $Robot
@onready var simcaregiver := $caregiver

# instance vars
var plan_data: Array
var curr_state: Dictionary
var step_id: int
var init_world: Dictionary
var world_state: Array = []

var _robot_name = "nursebot"

var wait_for_replan = false
var has_replanned = false
var pred_id_lookup: Dictionary
var raw_plan_data: Dictionary

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.current_action_finished.connect(_on_current_action_finished)
	SignalBus.approach_tray_finished.connect(_on_approach_tray_finished)
	SignalBus.check_tray_finished.connect(_on_check_tray_finished)
	SignalBus.set_replan.connect(_set_new_plan)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# SETUP FUNCTIONS
func set_pred_id_lookup(_dict: Dictionary) -> void:
	pred_id_lookup = _dict

func set_initial_world(_init_world: Dictionary) -> void:
	init_world = _init_world
	world_state = _init_world["predicates"]

func set_initial_plan(_init_plan: Dictionary) -> void:
	print("Setting initial plan")
	raw_plan_data = _init_plan
	plan_data = build_simulator_steps(_init_plan)
	if plan_data.size() > 0:
		step_id = 0
		print("Simulation set successfully!\n > Press p to start.")
	else:
		print("No valid plan to simulate!")

func _set_new_plan(_new_plan_data: Dictionary) -> void:
	print("setting new plan")
	raw_plan_data = _new_plan_data
	plan_data = build_simulator_steps(_new_plan_data)
	wait_for_replan = false
	has_replanned = true
	step_id = 0
	step_simulation()

# ASSEMBLE THE SIMULATION STEPS		
func build_simulator_steps(_new_plan_data: Dictionary) -> Array:
	var new_plan: Array = []
	
	# some initialization
	var init_state = _new_plan_data["serInit"]
	var curr_trans: Dictionary = _get_outgoing_trans(init_state, _new_plan_data)

	# add checkpoint to plan
	var next_state = _get_state_by_id(init_state, _new_plan_data)
	next_state["out_trans"] = [_get_outgoing_trans(next_state["_id"], _new_plan_data)]
	new_plan.append(next_state)

	while curr_trans != {}:
		next_state = _get_state_by_id(curr_trans["targetID"], _new_plan_data)
		if next_state["is_action"]:
			print("ADDING ACTION:" + next_state["name"])
			new_plan.append(next_state)
		else:
			print("ADDING CHECKPOINT: " + next_state["name"])
			next_state["out_trans"] = [_get_outgoing_trans(next_state["_id"], _new_plan_data)]
			new_plan.append(next_state)

		curr_trans = _get_outgoing_trans(next_state["_id"], _new_plan_data)

	return new_plan


# MISC HELPER FUNCTIONS
func _get_entity_location(entity: String, children: Array, to_return: Vector2) -> Vector2:
	for n in children:
		if n.name != "TileMap" && n.name != "Navigation": # always skip tilemap and navigation!!
			if n.name == entity:
				# look if it has nav point
				for child in n.get_children():
					if child.name == "NavPoint":
						return child.global_position
				# otherwise use global location
				return n.global_position
			to_return = _get_entity_location(entity, n.get_children(), to_return)
	return to_return

func _get_node_by_name(entity: String, children: Array, to_return: Node) -> Node:
	for n in children:
		if n.name != "TileMap" && n.name != "Navigation": # always skip tilemap and navigation!!
			if n.name == entity:
				return n
			to_return = _get_node_by_name(entity, n.get_children(), to_return)
	return to_return

func _get_outgoing_trans(chkpt_id: int, _data: Dictionary) -> Dictionary:
	for trans in _data["serTrans"]:
		if trans["sourceID"] == chkpt_id:
			return trans
	return {}

func _get_state_by_id(chkpt_id: int, _data: Dictionary) -> Dictionary:
	for state in _data["serStates"]:
		if state["_id"] == chkpt_id:
			return state
	return {}

# REPLANNING HELPER FUNCTIONS
func replan() -> void:
	var problem_dict: Dictionary = {
		"world": {"object_groups": init_world["object_groups"], "predicates": world_state},
		"goal_automaton": get_ga_dict()
	}
	SignalBus.push_replan.emit(problem_dict)
	wait_for_replan = true

func get_ga_dict() -> Dictionary:
	var data = get_next_checkpoints_and_arcs()
	var checkpoints = data["checkpoints"]
	var arcs = data["arcs"]

	var ga_dict = {"serInit": 0,
				   "serStates": [],
				   "serTrans": [],
				   "options": []}
	for chkpt in checkpoints:
		if Options.opts.maintenance_goals:
			for mg in chkpt["maintenance_goals"]:
				var is_already_pred = false
				for pred in chkpt["predicates"]:
					if pred["_id"] == mg:
						is_already_pred = true
				
				if !is_already_pred:
					# check for unique ID
					var new_pred = pred_id_lookup[str(mg)].duplicate(true)
					new_pred["_id"] = PredicateIdGenerator.register_new_id()
					chkpt["predicates"].append(new_pred)
			ga_dict["serStates"].append(chkpt)
		else:
			ga_dict["serStates"].append(chkpt)
	for arc in arcs:
		ga_dict["serTrans"].append(arc)
	return ga_dict

func get_next_checkpoints_and_arcs() -> Dictionary:
	var to_return = {"checkpoints":[], "arcs":[]}

	# first add init checkpoint
	to_return["checkpoints"].append(plan_data[0])

	var tmp_step_id = step_id
	while tmp_step_id < plan_data.size():
		curr_state = plan_data[tmp_step_id]
		
		if curr_state["is_action"]:
			pass
		else:
			to_return["checkpoints"].append(curr_state)
			if len(to_return["checkpoints"]) == 2: # manually add the init transition for the first one
				to_return["arcs"].append({ "sourceID": 0, "targetID": curr_state["_id"], "condition": { "name": "" }, "triggeringEvent": { "triggerName": "" } })
			for trans in curr_state["out_trans"]:
				if trans.has("targetID"):
					var next_chkpt_id = get_next_checkpoint_id(curr_state["_id"])
					if next_chkpt_id != -1:
						to_return["arcs"].append({ "sourceID": curr_state["_id"], "targetID": next_chkpt_id, "condition": { "name": "" }, "triggeringEvent": { "triggerName": "" } })
		
		tmp_step_id = tmp_step_id + 1

	return to_return

func get_next_checkpoint_id(curr_id: int) -> int:
	# some initialization
	var init_state = _get_state_by_id(curr_id, raw_plan_data)
	var curr_trans: Dictionary = _get_outgoing_trans(init_state["_id"], raw_plan_data)

	# add checkpoint to plan
	var next_state = _get_state_by_id(init_state["_id"], raw_plan_data)
	next_state["out_trans"] = [_get_outgoing_trans(next_state["_id"], raw_plan_data)]

	while curr_trans != {}:
		next_state = _get_state_by_id(curr_trans["targetID"], raw_plan_data)
		if next_state["is_action"]:
			pass
		else:
			return next_state["_id"]

		curr_trans = _get_outgoing_trans(next_state["_id"], raw_plan_data)

	return -1

# CONTROL THE SIMULATOR
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_P:
			step_simulation()
		if event.keycode == KEY_R:
			reset_simulation()

func _on_current_action_finished() -> void:
	print("current action finished! " + str(step_id))
	if(!wait_for_replan):
		# increment to the next action
		step_id = step_id + 1
		# then call next step
		step_simulation()

func step_simulation() -> void:
	# Get the appropriate state based on the transition
	if step_id < plan_data.size():
		curr_state = plan_data[step_id]
		
		if curr_state["is_action"]:
			print("DOING ACTION:" + curr_state["nl"])
			var action_params = curr_state["actions"][0]["parameters"]
			match curr_state["actions"][0]["name"]:
				"approach":
					if(Options.opts.maintenance_goals && !has_replanned && action_params[0] == _robot_name && action_params[1] == "sally" && _get_node_by_name("napkin",get_children(),null).get_parent().name == "tray" && _get_node_by_name("tray",get_children(),null).get_parent().name == "SimGripper"):
						print("WILL TRIGGER MAINTENANCE GOAL")
						approach_with_drop(action_params[0], action_params[1])
					else:
						approach(action_params[0], action_params[1])
				"move_to":
					move_to(action_params[0], action_params[1])
				"grab":
					grab(action_params[0], action_params[1], action_params[2])
				"put":
					put(action_params[0], action_params[1], action_params[2], action_params[3])
				"open":
					open(action_params[0], action_params[1], action_params[2], action_params[3])
				"vacuum_region":
					vacuum(action_params[0], action_params[1], action_params[2])
				"wipe":
					wipe(action_params[0], action_params[1], action_params[2])
				"offer":
					offer(action_params[0], action_params[1], action_params[2])
				"offer_back":
					offer_back(action_params[0], action_params[1], action_params[2])
				"take_from":
					if(Options.opts.maintenance_goals && !has_replanned && action_params[0] == "mike" && action_params[1] == "mike_cup" && action_params[2] == _robot_name):
						print("WILL TRIGGER MAINTENANCE GOAL")
						take_from_with_refill(action_params[0], action_params[1], action_params[2], action_params[3])
					else:
						take_from(action_params[0], action_params[1], action_params[2], action_params[3])
				"take_from_back":
					take_from_back(action_params[0], action_params[1], action_params[2], action_params[3])
				"fills_cup":
					fills_cup(action_params[0], action_params[1], action_params[2])
				"get_tray_checked":
					get_tray_checked(action_params[0], action_params[1])	
				_:
					print("Action not yet implemented, no movement to see")
		else:
			print("--CHECKPOINT " + str(curr_state["_id"]) + " REACHED--")
			SignalBus.current_action_finished.emit()
	else:
		print("PLAN COMPLETED!\n > Press 'r' to reset.")

func reset_simulation() -> void:
	# TODO: This is a bit buggy, need to figure it out
	# I think it's especially a problem when the caregiver is moving
	if plan_data.size() > 0:
		# Reset the step
		step_id = 0
		
		# Reset the robot
		simrobot.reset()
		simcaregiver.reset()
		
		# Reset necessary items in the world
		var list_to_reset: Array = ["vacuum", "sponge", "tray", "entree", "napkin", "sally_cup", "mike_cup", "dave_cup", "table1", "table2", "table3", "table4"]
		for obj in list_to_reset:
			var obj_node = _get_node_by_name(obj, get_children(), null)
			# first fix parenting
			if obj_node.get_parent().name != obj_node.reset_parent_name:
				obj_node.get_parent().remove_child(obj_node)
				if obj_node.reset_parent_name == "simulator":
					add_child(obj_node)
				else:
					_get_node_by_name(obj_node.reset_parent_name, get_children(), null).add_child(obj_node)
			# then reset visuals
			obj_node.reset()
		
		print("Simulation re-set successfully!\n > Press the space bar to start again.")

# ACTION FUNCTIONS
func move_to(agent: String, region: String) -> void:
	if agent == _robot_name:
		simrobot.set_destination(get_node(region).global_position, simcaregiver)

	# Update predicates
	# first, remove anything with ["entity_in", agent, *]
	# and, remove anything with ["agent_near", agent, *]
	# finally, add the new predicate: ["entity_in", agent, region]

	var to_delete = []
	for pred in world_state:
		if (pred["symbol"] == "entity_in" && pred["parameters"][0] == agent) || (pred["symbol"] == "agent_near" && pred["parameters"][0] == agent):
			to_delete.append(pred)

	for pred in to_delete:
		world_state.erase(pred)

	world_state.append({"symbol":"entity_in", "parameters":[agent, region]})

func approach(agent: String, entity: String) -> void:
	if agent == _robot_name:
		simrobot.set_destination(_get_entity_location(entity, get_children(), Vector2(0,0)), simcaregiver)
	
	# Update predicates
	# first, remove anything with ["entity_in", agent, *]
	# then, remove anything with ["agent_near", agent, *]
	# finally, add the new predicate: ["entity_in", agent, region]

	var to_delete = []
	for pred in world_state:
		if (pred["symbol"] == "entity_in" && pred["parameters"][0] == agent) || (pred["symbol"] == "agent_near" && pred["parameters"][0] == agent):
			to_delete.append(pred)

	for pred in to_delete:
		world_state.erase(pred)

	world_state.append({"symbol":"agent_near", "parameters":[agent, entity]})

func approach_with_drop(agent: String, entity: String) -> void:
	wait_for_replan = true
	if agent == _robot_name:
		simrobot.set_destination(_get_entity_location(entity, get_children(), Vector2(0,0)), simcaregiver)
		await get_tree().create_timer(1.0).timeout
		var napkin = _get_node_by_name("napkin",get_children(),null)
		napkin.get_parent().remove_child(napkin)
		add_child(napkin)
		napkin.position = simrobot.position
		await get_tree().create_timer(1.0).timeout
		simrobot.set_destination(simrobot.position, simcaregiver)
		simrobot._alertBubble.show()
		await get_tree().create_timer(1.0).timeout
		simrobot._alertBubble.hide()
	
	# Update predicates
	# first, remove anything with ["entity_in", agent, *]
	# then, remove anything with ["agent_near", agent, *]
	# finally, erase/unset predicate: ["object_at", "napkin", "tray"] so that replanning is successful

	var to_delete = []
	for pred in world_state:
		if (pred["symbol"] == "entity_in" && pred["parameters"][0] == agent) || (pred["symbol"] == "agent_near" && pred["parameters"][0] == agent):
			to_delete.append(pred)

	for pred in to_delete:
		world_state.erase(pred)
		
	world_state.erase({"symbol":"object_at", "parameters":["napkin", "tray"]})

	replan()

func grab(agent: String, object: String, gripper: String):
	# Update visuals
	# first make obj child of agent (assuming robot only for now)
	# then set position to Vector2(-20,-30)
	# get_node(object).get_parent().remove_child(get_node(object))
	await get_tree().create_timer(0.5).timeout
	var obj_node = _get_node_by_name(object, get_children(), null)
	obj_node.get_parent().remove_child(obj_node)
	obj_node.position = Vector2(0, 0)
	get_node("Robot").get_node("SimGripper").add_child(obj_node)
	await get_tree().create_timer(0.5).timeout

	# Update predicates
	# first, remove anything with ["entity_in", object, *]
	# then, remove anything with ["object_at", object, *]
	# then, remove ["agent_near", agent, object]
	# then, remove ["is_free", gripper]
	# then, remove ["accessible", object]
	# finally, add the new predicate: ["agent_has", agent, object]

	var to_delete = []
	for pred in world_state:
		if (pred["symbol"] == "entity_in" && pred["parameters"][0] == object) || (pred["symbol"] == "object_at" && pred["parameters"][0] == object):
			to_delete.append(pred)

	for pred in to_delete:
		world_state.erase(pred)

	world_state.erase({"symbol":"agent_near", "parameters":[agent, object]})
	world_state.erase({"symbol":"is_free", "parameters":[gripper]})
	world_state.erase({"symbol":"accessible", "parameters":[object]})

	world_state.append({"symbol":"agent_has", "parameters":[agent, object]})

	SignalBus.current_action_finished.emit()
	

func put(agent: String, object: String, location: String, gripper: String):
	# make object child of scene
	# and set position to wherever it's placed
	await get_tree().create_timer(0.5).timeout
	var obj_node = _get_node_by_name(object, get_children(), null)
	obj_node.get_parent().remove_child(obj_node)
	_get_node_by_name(location, get_children(), null).add_child(obj_node)
	obj_node.position = _get_node_by_name(location, get_children(), null).get_put_loc(object) #_get_entity_location(location, get_children(), Vector2(0,0))
	await get_tree().create_timer(0.5).timeout

	# Update predicates
	# first, remove ["agent_has", agent, object]
	# then, add ["is_free", gripper]
	# then, add ["accessible", object]
	# finally, add ["object_at", object, location]

	world_state.erase({"symbol":"agent_has", "parameters":[agent, object]})

	world_state.append({"symbol":"object_at", "parameters":[object, location]})
	world_state.append({"symbol":"is_free", "parameters":[gripper]})
	world_state.append({"symbol":"accessible", "parameters":[object]})
	
	SignalBus.current_action_finished.emit()

func open(agent: String, object: String, gripper: String, obj_inside: String):
	print("Action not fully implemented, no movement to see")

	# Update predicates
	# first, add ["is_open", object]
	# then, add ["accessible", obj_inside]

	world_state.append({"symbol":"is_open", "parameters":[object]})
	world_state.append({"symbol":"accessible", "parameters":[obj_inside]})

	
	SignalBus.current_action_finished.emit()

func vacuum(robot: String, tool: String, region: String):
	simrobot.set_destination(get_node(region).global_position, simcaregiver)

	# Update predicates
	# add ["is_vacuumed", region]

	world_state.append({"symbol":"is_vacuumed", "parameters":[region]})
	
	SignalBus.current_action_finished.emit()

func wipe(robot: String, tool: String, surface: String):
	var tool_node = get_node("Robot").get_node("SimGripper").get_node(tool)
	tool_node.wipe_surface(_get_node_by_name(surface, get_children(), null))

	_get_node_by_name(surface, get_children(), null).set_wiped(true)

	# Update predicates
	# add ["is_wiped", surface]
	world_state.append({"symbol":"is_wiped", "parameters":[surface]})

func offer(from: String, thing: String, to: String):
	# make sure robot is facing person
	if from == _robot_name:
		simrobot._prep_for_handoff()

	await get_tree().create_timer(0.5).timeout

	# Update predicates
	# add ["available_to", from, thing, to]
	world_state.append({"symbol":"available_to", "parameters":[from, thing, to]})
	world_state.append({"symbol":"offer_lock", "parameters":[]})
	
	SignalBus.current_action_finished.emit()

func offer_back(from: String, thing: String, to: String):
	# make sure robot is facing person
	if to == _robot_name:
		simrobot._prep_for_handoff()

	await get_tree().create_timer(0.5).timeout

	# Update predicates
	# add ["available_to", from, thing, to]
	world_state.append({"symbol":"available_to", "parameters":[from, thing, to]})
	world_state.append({"symbol":"offer_lock", "parameters":[]})
	
	SignalBus.current_action_finished.emit()

func take_from(to: String, thing: String, from: String, gripper: String):
	# make object child of scene
	# and set position to wherever it's placed

	var obj_node = _get_node_by_name(thing, get_children(), null)
	obj_node.get_parent().remove_child(obj_node)
	_get_node_by_name(to, get_children(), null).add_child(obj_node)
	obj_node.position = _get_node_by_name(to, get_children(), null).get_put_loc(thing) #_get_entity_location(location, get_children(), Vector2(0,0))
	await get_tree().create_timer(0.5).timeout

	# Update predicates
	# first, remove anything with ["agent_has", *, thing]
	# then, remove ["available_to", from, thing, to]
	# then, add ["is_free", gripper]
	# finally, add ["agent_has",to, thing]

	var to_delete = []
	for pred in world_state:
		if pred["symbol"] == "agent_has" && pred["parameters"][1] == thing:
			to_delete.append(pred)

	for pred in to_delete:
		world_state.erase(pred)

	world_state.erase({"symbol":"available_to", "parameters":[from, thing, to]})
	
	world_state.append({"symbol":"is_free", "parameters":[gripper]})
	world_state.append({"symbol":"agent_has", "parameters":[to, thing]})
	world_state.erase({"symbol":"offer_lock", "parameters":[]})
	
	
	SignalBus.current_action_finished.emit()

func take_from_back(to: String, thing: String, from: String, gripper: String):
	# make object child of scene
	# and set position to wherever it's placed

	var obj_node = _get_node_by_name(thing, get_children(), null)
	obj_node.get_parent().remove_child(obj_node)
	if to == _robot_name:
		obj_node.position = Vector2(0, 0)
		get_node("Robot").get_node("SimGripper").add_child(obj_node)

	# Update predicates
	# first, remove anything with ["agent_has", *, thing]
	# then, remove ["available_to", from, thing, to]
	# then, add ["is_free", gripper]
	# finally, add ["agent_has",to, thing]

	var to_delete = []
	for pred in world_state:
		if pred["symbol"] == "agent_has" && pred["parameters"][1] == thing:
			to_delete.append(pred)

	for pred in to_delete:
		world_state.erase(pred)

	world_state.erase({"symbol":"available_to", "parameters":[from, thing, to]})
	world_state.erase({"symbol":"offer_lock", "parameters":[]})
	
	world_state.append({"symbol":"is_free", "parameters":[gripper]})
	world_state.append({"symbol":"agent_has", "parameters":[to, thing]})
	
	
	SignalBus.current_action_finished.emit()

func take_from_with_refill(to: String, thing: String, from: String, gripper: String):
	wait_for_replan = true

	# make object child of scene
	# and set position to wherever it's placed
	var obj_node = _get_node_by_name(thing, get_children(), null)
	obj_node.get_parent().remove_child(obj_node)
	_get_node_by_name(to, get_children(), null).add_child(obj_node)
	obj_node.position = _get_node_by_name(to, get_children(), null).get_put_loc(thing) #_get_entity_location(location, get_children(), Vector2(0,0))
	await get_tree().create_timer(0.5).timeout

	# Update predicates
	# first, remove anything with ["agent_has", *, thing]
	# then, remove ["available_to", from, thing, to]
	# then, add ["is_free", gripper]
	# finally, add ["agent_has",to, thing]

	var to_delete = []
	for pred in world_state:
		if pred["symbol"] == "agent_has" && pred["parameters"][1] == thing:
			to_delete.append(pred)

	for pred in to_delete:
		world_state.erase(pred)

	world_state.erase({"symbol":"available_to", "parameters":[from, thing, to]})
	world_state.erase({"symbol":"offer_lock", "parameters":[]})
	
	world_state.append({"symbol":"is_free", "parameters":[gripper]})
	world_state.append({"symbol":"agent_has", "parameters":[to, thing]})

	# Now make the other cup empty and trigger maintenance goal
	var dave_cup = _get_node_by_name("dave_cup",get_children(),null)
	dave_cup.set_empty()
	simrobot._alertBubble.show()
	await get_tree().create_timer(1.0).timeout
	simrobot._alertBubble.hide()

	world_state.erase({"symbol":"is_full", "parameters":["dave_cup"]})
	
	replan()

func fills_cup(robot: String, dispenser: String, cup: String):
	_get_node_by_name(dispenser, get_children(), null).fill()
	_get_node_by_name(cup, get_children(), null).set_full(true)

	# Update predicates
	# add ["is_full", cup]
	world_state.append({"symbol":"is_full", "parameters":[cup]})

func get_tray_checked(robot: String, meal_tray: String):
	# _get_node_by_name(meal_tray, get_children(), null).set_checked(true)

	simcaregiver.set_destination(_get_entity_location(meal_tray, get_children(), Vector2(0,0)), simrobot)

	world_state.append({"symbol":"is_checked", "parameters":[meal_tray]})

func _on_approach_tray_finished() -> void:
	simcaregiver.check_tray()

func _on_check_tray_finished() -> void:
	simcaregiver.set_destination(_get_entity_location("nurse_station", get_children(), Vector2(0,0)), simrobot)
	SignalBus.current_action_finished.emit()
