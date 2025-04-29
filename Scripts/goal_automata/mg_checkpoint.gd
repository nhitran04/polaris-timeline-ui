extends Checkpoint

class_name MG_Checkpoint

# instance vars
@onready var mg_maintenance_goals_container = $UI/MainPanel/PanelItems/MaintenanceGoals/MaintenanceGoalContainer
@onready var init_mg_predicate = $UI/MainPanel/PanelItems/MaintenanceGoals/MaintenanceGoalContainer/InitMaintenanceGoals
var mg_maintenance_goal_scene := load("res://Scenes/DrawingBoard/checkpoint/mg_checkpoint_maintenance_goal.tscn")
var disabled_maintenance_goals: Array[int]
var enabled_maintenance_goals: Array



func _delete_predicate(pred: CheckpointPredicate) -> void:
	#var numchildren = len(predicate_container.get_children())
	predicate_container.remove_child(pred)
	PredicateIdGenerator.deregister_old_id(pred.id)
	pred.queue_free()
	if len(predicate_container.get_children()) == 1:
		print(apb)
		var children = predicate_container.get_children()
		predicate_container.remove_child(apb)
		apb.queue_free()
		apb = null
		init_predicates_container = init_predicates_button_scene.instantiate()
		predicate_container.add_child(init_predicates_container)
		init_predicates_container.get_node("InitPredicatesButton").pressed.connect(_add_predicate)
	SignalBus.updated_ga.emit()

# This function is called when a new plan is sent from the planner
# and it is only called when maintenance goals option is enabled.
# Maintenance goals are displayed in the state after they are 
func on_set_plan(plan_data: Dictionary) -> void:
	# search plan_data for the state with the same checkpoint id
	var curr_state = null
	for state_data in plan_data["serStates"]:
		if state_data["_id"] == self.id:
			curr_state = state_data
			break
	if curr_state == null:
		return
		
	# set enabled maintenance goals within the state
	enabled_maintenance_goals = curr_state["maintenance_goals"]
	for mg in curr_state["disabled_maintenance_goals"]:
		if enabled_maintenance_goals.has(mg):
			enabled_maintenance_goals.erase(mg)

	# we only expect one transition per state, but this setup will handle all of them
	for trans in out_trans:
		var next_state: Checkpoint = trans.target
		# first clear all maintenance goals
		for itm in next_state.mg_maintenance_goals_container.get_children():
			if itm.name != "InitMaintenanceGoals":
				itm.queue_free()
				
		# get list of enabled/disabled maintenance goals in the next checkpoint for use later
		# if the maintenance goal is active, it has to also be in the next state or else we don't show it
		# if the mg is inactive, it won't be in the next state, so we don't need to check anything
		var next_state_mgs: Array = []
		var next_state_disabled_mgs: Array = []
		for state_data in plan_data["serStates"]:
			if state_data["_id"] == next_state.id:
				next_state_mgs = state_data["maintenance_goals"]
				next_state_disabled_mgs = state_data["disabled_maintenance_goals"]
				break

		# then populate all maintenance goals
		# we will use the no_mgs as a flag to track whether or not any maintenance goals are in the checkpoint (to update the text)
		var no_mgs: bool = true # use this to control maintenance goal panel text (other ways to track are complicated)
		
		# since we want to preserve the ordering of the maintenance goals across all checkpoints, we use the mg_order to track
		# so, we first load anything that's in that list already, then we add anything that's new
		for mg_id in MaintenanceGoalOrdering.mg_order:
			print(curr_state["_id"])
			var x = curr_state["disabled_maintenance_goals"].any(func(number): return number == mg_id)
			var y = next_state_mgs.any(func(number): return number == mg_id)
			var z = next_state_disabled_mgs.any(func(number): return number == mg_id)
			if (curr_state["disabled_maintenance_goals"].any(func(number): return number == mg_id) || next_state_mgs.any(func(number): return number == mg_id)) && !(_state_has_pred(next_state, mg_id)):
				no_mgs = false
				var mg_pred = next_state.mg_maintenance_goal_scene.instantiate()
				mg_pred.populate(mg_id, plan_data["serStates"], !curr_state["disabled_maintenance_goals"].any(func(number): return number == mg_id))
				mg_pred.set_parent_checkpoint(self)
				next_state.mg_maintenance_goals_container.add_child(mg_pred)

		# display maintenance goals (exclude any disabled maintenance goals)
		for mg_id in curr_state["maintenance_goals"]:
			if !MaintenanceGoalOrdering.mg_order.any(func(number): return number == mg_id): 
				MaintenanceGoalOrdering.mg_order.append(mg_id)
				if !curr_state["disabled_maintenance_goals"].any(func(number): return number == mg_id) && (next_state_mgs.any(func(number): return number == mg_id) || next_state_disabled_mgs.any(func(number): return number == mg_id)):
					no_mgs = false
					var mg_pred = next_state.mg_maintenance_goal_scene.instantiate()
					mg_pred.populate(mg_id, plan_data["serStates"], !curr_state["disabled_maintenance_goals"].any(func(number): return number == mg_id))
					mg_pred.set_parent_checkpoint(self)
					next_state.mg_maintenance_goals_container.add_child(mg_pred)

		# finally update maintenance goal panel text
		if no_mgs:
			next_state.mg_maintenance_goals_container.get_children()[0].get_children()[0].text = "None"
		else:
			next_state.mg_maintenance_goals_container.get_children()[0].get_children()[0].text = ""
		
func _state_has_pred(state: Checkpoint, pred_id: int) -> bool:
	for child in state.predicate_container.get_children():
		if child is CheckpointPredicate:
			if child.id == pred_id:
				return true
	return false

func jsonify() -> Dictionary:
	var to_return = {}
	to_return["_id"] = id
	to_return["name"] = "checkpoint " + str(id)
	to_return["predicates"] = []
	to_return["actions"] = []
	for child in predicate_container.get_children():
		if child is CheckpointPredicate:
			to_return["predicates"].append(child.jsonify())
	if Options.opts.maintenance_goals:
		to_return["disabled_maintenance_goals"] = disabled_maintenance_goals
		# cannot do this using children in mg_containter because of the way mg's are visualized in different checkpoints than they belong 
		to_return["enabled_maintenance_goals"] = enabled_maintenance_goals 
	return to_return

