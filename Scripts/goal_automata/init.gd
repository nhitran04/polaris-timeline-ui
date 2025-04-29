extends Control

class_name InitCheckpoint

var id: int = 0
var out_trans: Array[Arc]
var final_state: Array
var candidate_out_trans: Array[Arc]

func _ready() -> void:
	out_trans = []
	candidate_out_trans = []
	SignalBus.broadcast_world.connect(_set_final_state)

func height() -> float:
	return 0
	
func set_reachable(_val: bool) -> void:
	pass
	
func _set_final_state(world_data: Dictionary) -> void:
	final_state = world_data.predicates

func jsonify() -> Dictionary:
	var to_return = {
					"_id": 0,
					"name": "start",
					"nl": "",
					"hidden": false,
					"predicates": [],
					"actions": [],
					"final_state": []
					}
	if Options.opts.maintenance_goals:
		to_return["disabled_maintenance_goals"] = []  # TODO: fill this in
	return to_return
