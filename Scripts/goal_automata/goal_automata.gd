extends Node2D

var init_scene := load("res://Scenes/DrawingBoard/init.tscn")
var arc_scene := load("res://Scenes/DrawingBoard/arc.tscn")
var add_checkpt_scene := load("res://Scenes/DrawingBoard/button_new_checkpoint.tscn")
var chkpt_scene := load("res://Scenes/DrawingBoard/checkpoint/checkpoint.tscn")
var mg_chkpt_scene := load("res://Scenes/DrawingBoard/checkpoint/mg_checkpoint.tscn")

# GA components
var init: InitCheckpoint
var arcs: Array[Arc]
var checkpoints: Array[Node]

# icons
var actions_visible_flag: bool

# ids
var curr_id: int = 1

# save the plan (to send to simulator)
var curr_plan: Dictionary

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# flags
	actions_visible_flag = true
	
	# add the init node
	init = init_scene.instantiate()
	add_child(init)
	init.set_position(Vector2(3000, 500))
	checkpoints.append(init)
	
	# add the checkpoint-add button
	_add_candidate_arc(init, init.position, 400)

	# signals
	SignalBus.set_plan.connect(_on_set_plan)
	SignalBus.delete_checkpoint.connect(_delete_checkpoint_and_send_update)
	SignalBus.split_arc.connect(_split_arc)
	SignalBus.expand_action_hint.connect(_on_action_clicked)
	SignalBus.toggle_hints.connect(_on_hints_toggled)
	SignalBus.set_input_goal_automata.connect(_replace)
	
func add_checkpoint_and_send_update(chkpt: Checkpoint, src_trans: Arc) -> void:
	_add_checkpoint(chkpt, src_trans)
	SignalBus.updated_ga.emit()

func _add_checkpoint(chkpt: Checkpoint, src_trans: Arc) -> void:
	# add the checkpoint
	src_trans.target = chkpt
	src_trans.source.out_trans.append(src_trans)
	src_trans.source.candidate_out_trans.erase(src_trans)
	src_trans.position_split_button()
	arcs.append(src_trans)
	add_child(chkpt)
	chkpt.set_id(curr_id)
	checkpoints.append(chkpt)
	curr_id += 1
	chkpt.in_trans.append(src_trans)
	
	# create a new arc and "add" button below the checkpoint
	var curr_chkpt_pos = Vector2(src_trans.points[-1].x, src_trans.points[-1].y)
	_add_candidate_arc(chkpt, curr_chkpt_pos, 200)
	
func _add_candidate_arc(src: Node, src_pos: Vector2, length: int) -> void:
	# create a new arc and "add" button below the checkpoint
	var add_checkpt = add_checkpt_scene.instantiate()
	add_checkpt.add_chkpt_signal.connect(add_checkpoint_and_send_update)
	add_checkpt.position = Vector2(src_pos.x, src_pos.y + src.height() + length)
	
	# add an arc
	var arc = arc_scene.instantiate()
	arc.source = src
	src.candidate_out_trans.append(arc)
	arc.width = 2
	arc.default_color = Color.BLACK
	arc.add_point(Vector2(src_pos.x, src_pos.y + src.height()))
	arc.add_point(add_checkpt.position)
	add_child(arc)
	arc.create_collision_bounds()
	add_checkpt.in_trans = arc
	arc.target = add_checkpt
	arc.add_child(add_checkpt)
	
func _delete_checkpoint_and_send_update(chkpt: Checkpoint) -> void:
	_delete_checkpoint(chkpt)
	SignalBus.updated_ga.emit()

func _delete_checkpoint(chkpt: Checkpoint) -> void:
	# collect sources and targets
	var source_chkpts: Array = []
	var target_chkpts: Array = []
	for arc in chkpt.in_trans:
		source_chkpts.append(arc.source)
	for arc in chkpt.out_trans:
		target_chkpts.append(arc.target)
	
	# delete existing arcs
	for arc in chkpt.in_trans:
		arc.source.out_trans.erase(arc)
		arc.get_parent().remove_child(arc)
		arc.queue_free()
		arcs.erase(arc)
	for arc in chkpt.out_trans:
		arc.target.in_trans.erase(arc)
		arc.get_parent().remove_child(arc)
		arc.queue_free()
		arcs.erase(arc)
	
	# remove any candidate arcs
	for arc in chkpt.candidate_out_trans:
		remove_child(arc)
		arc.queue_free()
		
	# link up source and target checkpoints
	for src in source_chkpts:
		for tar in target_chkpts:
			var arc = arc_scene.instantiate()
			arc.source = src
			arc.target = tar
			arc.source.out_trans.append(arc)
			arc.target.in_trans.append(arc)
			arc.width = 2
			arc.default_color = Color.BLACK
			arc.add_point(Vector2(src.position.x, src.position.y + src.height()))
			arc.add_point(tar.position)
			add_child(arc)
			arc.create_collision_bounds()
			arcs.append(arc)
			
	# re-add candidate arcs where necessary
	for other_chkpt in source_chkpts:
		if len(other_chkpt.out_trans) == 0:
			_add_candidate_arc(other_chkpt, other_chkpt.position, 200)
		
	# delete this checkpoint
	checkpoints.erase(chkpt)
	remove_child(chkpt)
	chkpt.queue_free()
	
func _split_arc(arc: Arc) -> void:
	# instantiate new checkpoint
	var new_chkpt
	# load the correct checkpoint based on the options
	if(Options.opts["maintenance_goals"]):
		new_chkpt = mg_chkpt_scene.instantiate()
	else:
		new_chkpt = chkpt_scene.instantiate()
	
	# lengthen arc by height of checkpoint
	var target_chkpt = arc.target
	target_chkpt.reposition(new_chkpt.height())
	
	# add and set position of new checkpoint
	add_child(new_chkpt)
	new_chkpt.position = arc.midpoint()
	new_chkpt.position.y -= new_chkpt.height()/2.0
	new_chkpt.set_id(curr_id)
	checkpoints.append(new_chkpt)
	curr_id += 1
	
	# make arc target the new checkpoint
	arc.target = new_chkpt
	new_chkpt.in_trans.append(arc)
	target_chkpt.in_trans.erase(arc)
	arc.reset()
	
	# create new arc between new checkpoint and existing target checkpoint
	var new_arc = arc_scene.instantiate()
	new_arc.source = new_chkpt
	new_chkpt.out_trans.append(new_arc)
	new_arc.target = target_chkpt
	target_chkpt.in_trans.append(new_arc)
	new_arc.width = 2
	new_arc.default_color = Color.BLACK
	new_arc.add_point(Vector2(new_chkpt.position.x, new_chkpt.position.y + new_chkpt.height()))
	new_arc.add_point(target_chkpt.position)
	add_child(new_arc)
	new_arc.create_collision_bounds()
	new_arc.position_split_button()
	arcs.append(new_arc)
	SignalBus.updated_ga.emit()

func get_checkpoint(id: int) -> Node:
	var to_return: Node = null
	for chkpt in checkpoints:
		if chkpt.id == id:
			to_return = chkpt
			break
	return to_return
	
func get_arc(source_id: int, target_id: int) -> Arc:
	var to_return = null
	for arc in arcs:
		if arc.source.id == source_id and arc.target.id == target_id:
			to_return = arc
			break
	return to_return
	
func _on_set_plan(plan_data: Dictionary) -> void:
	# update the plan here so we can send to simulator when activated
	curr_plan = plan_data

	# set everything as unreachable to start with
	for chkpt in checkpoints:
		chkpt.set_reachable(false)
	for arc in arcs:
		arc.set_traversable(false)
	# recursively run through checkpoints and arcs to see what is/isn't reachable
	_set_component_reachability(init, plan_data)
	# set the plan for each arc
	for arc in arcs:
		arc.on_set_plan(plan_data)

	if(Options.opts["maintenance_goals"]):
		#iterate through checkpoints and add/update maintenance goals
		for chkpt in checkpoints:
			if(chkpt.id != init.id): #skip the init because it will never have maintenance goals	
				chkpt.on_set_plan(plan_data)
		
func _on_action_clicked(act: Action) -> void:
	var trace: Array[Control] = []
	for arc in arcs:
		if act in arc.hints:
			trace = arc.get_predecessors_and_successors()
			break
			
	# bring up the plan visualizer
	# with the current action in-focus
	SignalBus.enter_plan_vis.emit(trace)
	SignalBus.set_plan_vis_focus.emit(act)
	
func _set_component_reachability(st, plan_data: Dictionary) -> void:
	var unreachable_out_trans: Array = []
	# iterate through each out_trans
	for arc in st.out_trans:
		for nontraverse_arc in plan_data["unsat_trans"]:
			var nt_src: int = nontraverse_arc["pair"][0]
			var nt_tar: int = nontraverse_arc["pair"][1]
			# if the out_trans is unreachable, flag it
			if nt_src == st.id and nt_tar == arc.target.id:
				unreachable_out_trans.append(arc)
				
	# recurse for any out_trans not flagged
	for arc in st.out_trans:
		if arc not in unreachable_out_trans:
			if float(arc.target.id) not in plan_data["unsat_branch_points"]:
				arc.set_traversable(true)
				arc.target.set_reachable(true)
				_set_component_reachability(arc.target, plan_data)
			
func _on_hints_toggled() -> void:
	if actions_visible_flag:
		actions_visible_flag = false
	else:
		actions_visible_flag = true
	for arc in arcs:
		arc.toggle_hints(actions_visible_flag)
		
func _replace(ga: Dictionary) -> void:
	"""Replaces current goal automata with pre-specified one."""
	# TODO: checkpoint IDs should ultimately be private, not user-facing
	# reset ID
	curr_id = 1

	# delete everything
	var checkpoints_dup: Array[Node] = checkpoints.duplicate()
	for chkpt in checkpoints_dup:
		if chkpt != init:
			_delete_checkpoint(chkpt)

	# build the goal automaton recursively
	# TODO: this code should not need to be repeated
	for arc in init.candidate_out_trans:
		# find corresponding transitions in the ga dictionary
		for arc_dict in ga["serTrans"]:
			if arc_dict["sourceID"] == arc.source.id:
				# load the correct checkpoint based on the options
				arc.target.replace_button_with_checkpoint()
				var new_checkpt: Checkpoint = arc.target
				# find checkpoint data
				for chkpt_data in ga["serStates"]:
					if chkpt_data["_id"] == arc_dict["targetID"]:
						new_checkpt.id = arc_dict["targetID"]
						if curr_id <= new_checkpt.id:
							curr_id = new_checkpt.id + 1
						for pred_data in chkpt_data["predicates"]:
							var pred: CheckpointPredicate = new_checkpt._add_predicate()
							var pred_name = pred_data["name"]
							var pred_id = pred_data["_id"]
							pred.clear_dropdowns()
							pred.set_symbol(pred_name)
							pred.id = pred_id
							var pred_params = pred_data["parameters"]
							pred.set_params(pred_params)
						break
				_replace_helper(new_checkpt, ga)
	
	SignalBus.updated_ga.emit()

func _replace_helper(chkpt: Checkpoint, ga: Dictionary) -> void:
	for arc in chkpt.candidate_out_trans:
		# find corresponding transitions in the ga dictionary
		for arc_dict in ga["serTrans"]:
			if arc_dict["sourceID"] == arc.source.id:
				# load the correct checkpoint based on the options
				arc.target.replace_button_with_checkpoint()
				var new_checkpt: Checkpoint = arc.target
				# find checkpoint data
				for chkpt_data in ga["serStates"]:
					if chkpt_data["_id"] == arc_dict["targetID"]:
						new_checkpt.id = arc_dict["targetID"]
						if curr_id <= new_checkpt.id:
							curr_id = new_checkpt.id + 1
						for pred_data in chkpt_data["predicates"]:
							var pred: CheckpointPredicate = new_checkpt._add_predicate()
							var pred_name = pred_data["name"]
							var pred_id = pred_data["_id"]
							pred.clear_dropdowns()
							pred.set_symbol(pred_name)
							pred.id = pred_id
							var pred_params = pred_data["parameters"]
							pred.set_params(pred_params)
						break
				_replace_helper(new_checkpt, ga)
	
func get_ga_dict() -> Dictionary:
	var ga_dict = {"serInit": 0,
				   "serStates": [],
				   "serTrans": [],
				   "options": []}
	for chkpt in checkpoints:
		ga_dict["serStates"].append(chkpt.jsonify())
	for arc in arcs:
		ga_dict["serTrans"].append(arc.jsonify())
	return ga_dict

func get_pred_id_dict() -> Dictionary:
	var all_preds: Dictionary = {}

	for chkpt in checkpoints:
		if chkpt is Checkpoint:
			for child in chkpt.predicate_container.get_children():
				if child is CheckpointPredicate:
					all_preds[str(child.id)] = child.jsonify()

	return all_preds
