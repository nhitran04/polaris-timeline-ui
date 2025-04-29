extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	SignalBus.updated_ga.connect(_problem_update_listener)


func _problem_update_listener() -> void:
	var ga_dict: Dictionary
	if Options.opts.goals_timeline or Options.opts.actions_timeline:
		ga_dict = get_node("TwoWayTimeline").get_ga_dict()
	else:
		ga_dict = get_node("GoalAutomata").get_ga_dict()
	var world_dict: Dictionary = get_node("World/world_database").get_world()
	var problem_dict: Dictionary = {
		"world": world_dict,
		"goal_automaton": ga_dict
	}
		
	# if logging to the backend, also include a timestamp
	if Options.opts.log_to_backend:
		problem_dict["timestamp"] = Time.get_ticks_msec()
		problem_dict["instance_id"] = Options.opts.instance_id
	
	SignalBus.push_goal_automaton.emit(problem_dict)
