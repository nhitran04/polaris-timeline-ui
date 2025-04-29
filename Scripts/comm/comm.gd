extends Node

var set_domain_scene_file := load("res://Scenes/comm/set_domain.tscn")
var set_world_scene_file := load("res://Scenes/comm/set_world.tscn")
var push_goal_automata_scene_file := load("res://Scenes/comm/push_goal_automaton.tscn")
var push_log_event_file := load("res://Scenes/comm/push_log_event.tscn")

@export var ip: String
@export var status_indicators: Control

# instance variables
var domain_set := false

# Called when the node enters the scene tree for the first time.
func _ready():
	SignalBus.push_goal_automaton.connect(_push_goal_automaton)
	SignalBus.domain_received.connect(_domain_received)
	SignalBus.log_to_backend.connect(_push_to_log)

	# this cannot be called until everything is init because requesting the domain relies on 
	# Options which are configured in controller.gd _ready()
	call_deferred("_request_domain")

func _request_domain() -> void:
	if Options.opts.uncert_experiment:
		return  # do nothing
	var domain_req = set_domain_scene_file.instantiate()
	add_child(domain_req)
	domain_req.request_domain(ip)
	
func _push_goal_automaton(problem_dict: Dictionary) -> void:
	'''Add options then push.'''
	print(problem_dict["goal_automaton"])
	var opts: Dictionary = Options.opts
	var opts_to_push: Array[String] = []
	for opt in opts:
		if opts[opt]:
			opts_to_push.append(opt)
	problem_dict["goal_automaton"]["options"] = opts_to_push
	var ga_broadcaster = push_goal_automata_scene_file.instantiate()
	ga_broadcaster.set_status_indicators(status_indicators)
	add_child(ga_broadcaster)
	ga_broadcaster.push_goal_automaton(problem_dict, ip)
	
func _push_to_log(timestamp: int, subject: String, args: Dictionary) -> void:
	'''
	Log an event.

	:subject: options | camera | button | other event.
			  Cameras: cam_drawingboard, cam_map, cam_sim
			  Buttons: button_to_map, button_to_drawingboard, button_to_play
	:args: array of args to pass (e.g., camera position)
	'''
	var log_broadcaster = push_log_event_file.instantiate()
	add_child(log_broadcaster)
	var log_item = {
		"instance_id": Options.opts.instance_id,
		"timestamp": timestamp,
		"subject": subject,
		"args": args
	}
	log_broadcaster.push_log_item(log_item, ip)

func _domain_received() -> void:
	domain_set = true
