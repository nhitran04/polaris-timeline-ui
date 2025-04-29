extends Node

var push_replan_scene_file := load("res://Scenes/simulator/push_replan.tscn")

@export var ip: String
@export var status_indicators: Control

# instance variables
var domain_set := false

# Called when the node enters the scene tree for the first time.
func _ready():
	SignalBus.push_replan.connect(_push_replan)
	
func _push_replan(problem_dict: Dictionary) -> void:
	'''Add options then push.'''
	var opts: Dictionary = Options.opts
	var opts_to_push: Array[String] = []
	for opt in opts:
		if opts[opt]:
			opts_to_push.append(opt)
	problem_dict["goal_automaton"]["options"] = opts_to_push
	var ga_broadcaster = push_replan_scene_file.instantiate()
	ga_broadcaster.set_status_indicators(status_indicators)
	add_child(ga_broadcaster)
	ga_broadcaster.push_replan(problem_dict, ip)
