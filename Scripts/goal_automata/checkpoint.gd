extends Control

class_name Checkpoint

# instance vars
@onready var main_panel = $UI/MainPanel as PanelContainer
@onready var init_predicates_container = $UI/MainPanel/PanelItems/ImageAndPredicates/PredicateContainer/InitPredicatesContainer
@onready var init_predicates_button = $UI/MainPanel/PanelItems/ImageAndPredicates/PredicateContainer/InitPredicatesContainer/InitPredicatesButton
@onready var predicate_container = $UI/MainPanel/PanelItems/ImageAndPredicates/PredicateContainer
@onready var id_label = $UI/MainPanel/PanelItems/ImageAndPredicates/MainImagePanel/MainImage/Label
@onready var cancel_button = $UI/MainPanel/PanelItems/Padding/CancelButton
@onready var world_database = get_tree().get_root().get_node("Polaris/Problem/World/world_database") 
var predicate_scene := load("res://Scenes/DrawingBoard/checkpoint/checkpoint_predicate.tscn")
var action_scene := load("res://Scenes/DrawingBoard/checkpoint/checkpoint_action.tscn")
var both_scene := load("res://Scenes/DrawingBoard/checkpoint/checkpoint_both.tscn")
var add_predicate_button_scene := load("res://Scenes/DrawingBoard/checkpoint/add_predicate_button.tscn")
var init_predicates_button_scene := load("res://Scenes/DrawingBoard/checkpoint/init_predicates_button.tscn")

# instance vars
var id: int
var in_trans: Array[Arc]
var out_trans: Array[Arc]
var final_state: Array
var candidate_out_trans: Array[Arc]
var param_mapper: Dictionary
var predicates: Array[CheckpointPredicate]
var actions: Array[CheckpointAction]
var apb: PanelContainer

# private signal
signal delete_predicate(pred: CheckpointPredicate)
signal delete_action(action: CheckpointAction)
signal delete_both(both: CheckpointBoth)

func _ready():
	if Options.opts.goals_timeline and Options.opts.actions_timeline:
		init_predicates_button.pressed.connect(_add_both)
		delete_both.connect(_delete_both)
	elif Options.opts.actions_timeline:
		init_predicates_button.pressed.connect(_add_action)
		delete_action.connect(_delete_action)
	elif Options.opts.goals_timeline:
		init_predicates_button.pressed.connect(_add_predicate)
		delete_predicate.connect(_delete_predicate)
	
	cancel_button.pressed.connect(_on_cancel_button_pressed)
	
	in_trans = []
	out_trans = []
	candidate_out_trans = []
	
func height() -> float:
	return get_node("UI/MainPanel").size.y

func set_checkpoint_position(pos: Vector2) -> void:
	set_position(pos)
	
func set_id(new_id: int) -> void:
	self.id = new_id
	id_label.text = str(self.id)
	
func _add_predicate() -> CheckpointPredicate:
	# reset buttons
	if init_predicates_container != null:
		predicate_container.remove_child(init_predicates_container)
		init_predicates_container.queue_free()
		init_predicates_container = null
	if apb != null:
		predicate_container.remove_child(apb)
		apb.queue_free()
	
	var pred: CheckpointPredicate = predicate_scene.instantiate()
	pred.add_world(world_database)
	pred.add_delete_callback(delete_predicate)
	pred.set_parent_checkpoint(self)
	predicate_container.add_child(pred)

	# re-add button
	apb = add_predicate_button_scene.instantiate()
	apb.get_node("Button").pressed.connect(_add_predicate)
	predicate_container.add_child(apb)
	
	return pred

func _add_action() -> CheckpointAction:
	if init_predicates_container != null:
		predicate_container.remove_child(init_predicates_container)
		init_predicates_container.queue_free()
		init_predicates_container = null
	if apb != null:
		predicate_container.remove_child(apb)
		apb.queue_free()
	
	var action: CheckpointAction = action_scene.instantiate()
	action.add_world(world_database)
	action.add_delete_callback(delete_action)
	action.set_parent_checkpoint(self)
	predicate_container.add_child(action)
	
	return action
	
func _add_both() -> CheckpointBoth:
	if init_predicates_container != null:
		predicate_container.remove_child(init_predicates_container)
		init_predicates_container.queue_free()
		init_predicates_container = null
	if apb != null:
		predicate_container.remove_child(apb)
		apb.queue_free()
	
	var both: CheckpointBoth = both_scene.instantiate()
	both.add_world(world_database)
	both.add_delete_callback(delete_both)
	both.set_parent_checkpoint(self)
	predicate_container.add_child(both)
	
	# re-add button
	apb = add_predicate_button_scene.instantiate()
	apb.get_node("Button").pressed.connect(_add_both)
	predicate_container.add_child(apb)

	return both

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
	
func _delete_action(action: CheckpointAction) -> void:
	predicate_container.remove_child(action)
	PredicateIdGenerator.deregister_old_id(action.id)
	action.queue_free()
	if len(predicate_container.get_children()) == 1:
		print(apb)
		var children = predicate_container.get_children()
		predicate_container.remove_child(apb)
		apb.queue_free()
		apb = null
		init_predicates_container = init_predicates_button_scene.instantiate()
		predicate_container.add_child(init_predicates_container)
		init_predicates_container.get_node("InitPredicatesButton").pressed.connect(_add_action)
	SignalBus.updated_ga.emit()
	
func _delete_both(both: CheckpointBoth) -> void:
	predicate_container.remove_child(both)
	PredicateIdGenerator.deregister_old_id(both.id)
	both.queue_free()
	if len(predicate_container.get_children()) == 1:
		print(apb)
		var children = predicate_container.get_children()
		predicate_container.remove_child(apb)
		apb.queue_free()
		apb = null
		init_predicates_container = init_predicates_button_scene.instantiate()
		predicate_container.add_child(init_predicates_container)
		init_predicates_container.get_node("InitPredicatesButton").pressed.connect(_add_both)
	SignalBus.updated_ga.emit()

func _on_cancel_button_pressed():
	# TODO: shift things up
	SignalBus.delete_checkpoint.emit(self)
	
func set_final_state(final_state: Array) -> void:
	self.final_state = final_state

func set_reachable(val: bool) -> void:
	var stylebox: StyleBoxFlat = main_panel.get_theme_stylebox('panel').duplicate()
	if val:
		stylebox.border_color.a = 1.0
		stylebox.bg_color.a = 1.0
	else:
		stylebox.border_color.a = 0.25
		stylebox.bg_color.a = 0.25
	main_panel.add_theme_stylebox_override("panel", stylebox)
	for arc in candidate_out_trans:
		arc.set_traversable(val)
	
func _reposition_arcs():
	'''
	Repositioning checkpoints entails:
		0) upstream checkpoints are NOT affected.
		1) input arcs are NOT moved, but their end points are adjusted such that
		   they match the checkpoint position
		2) every other arc (out_trans and candidate_out_trans) IS moved.
		3) as a result of (2), downstream checkpoints ARE also moved.
	'''
	for arc in in_trans:
		arc.reset()
	for arc in out_trans:
		arc.reposition()
	for arc in candidate_out_trans:
		arc.reposition()
		
func reposition(diff: int) -> void:
	position.y += diff
	_reposition_arcs()
	
func _on_main_panel_gui_input(event):
	if event is InputEventMouseButton and event.is_action_pressed("click"):
		SignalBus.lock_2D_camera_pan.emit(true)
	if event is InputEventMouseButton and event.is_action_released("click"):
		SignalBus.lock_2D_camera_pan.emit(false)
	if event is InputEventScreenDrag:
		reposition(event.relative.y)
		
func jsonify() -> Dictionary:
	var to_return = {}
	to_return["_id"] = id
	to_return["name"] = "checkpoint " + str(id)
	to_return["predicates"] = []
	to_return["actions"] = []
	for child in predicate_container.get_children():
		if child is CheckpointBoth:
			if child.get_parent().get_child_count() == 2:
				if child.get_parent().get_child(1).visible:
					to_return["predicates"].append(child.jsonify())
				else:
					to_return["actions"].append(child.jsonify())
		elif child is CheckpointAction:
			to_return["actions"].append(child.jsonify())
		elif child is CheckpointPredicate:
			to_return["predicates"].append(child.jsonify())
	
	if Options.opts.log_to_backend:
		to_return["position"] = {"x": position.x,
								 "y": position.y}

	return to_return
