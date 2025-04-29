'''
License: 
Others' Code used/adapted/modified:
	 1. URL(s): https://gdscript.com/solutions/regular-expressions/
				https://docs.godotengine.org/en/stable/classes/class_regex.html
		License: https://docs.godotengine.org/en/stable/classes/class_regex.html
		SHA (if found ogit): N/A
'''

extends Checkpoint

class_name TimeLineCheckpoint

var is_top_checkpt : bool = false
var is_bottom_checkpt : bool = false
var is_init_checkpt : bool = false
var is_plan_set : bool = false
var pred_count = 0

func set_init_checkpt_val(init_checkpt : bool) -> void:
	self.is_init_checkpt = init_checkpt

func set_top_checkpt_val(top_checkpt : bool) -> void:
	self.is_top_checkpt = top_checkpt

func set_bottom_checkpt_val(bottom_checkpt : bool) -> void:
	self.is_bottom_checkpt = bottom_checkpt
	
func set_plan_val(plan_set : bool) -> void:
	self.is_plan_set = plan_set

func _on_cancel_button_pressed() -> void:
	var vbox = get_tree().root.get_node("Polaris/Problem/TwoWayTimeline/ScrollContainer/HBoxContainer/VBoxContainer")
	for child in vbox.get_children():
		if child.get_index() == self.get_index() + 1:
			if _on_regex_helper(child, "BottomPlusButton") != null:
				_on_cancel_button_pressed_helper(child, vbox)
				break
		if child.get_index() == self.get_index() - 2:
			if 	_on_regex_helper(child, "TopPlusButton") != null:
				_on_cancel_button_pressed_helper(child, vbox)
				break

func _on_cancel_button_pressed_helper(child : Node, vbox : VBoxContainer) -> void:
	# remove children after clicking the delete button
	child.queue_free()
	vbox.get_child(self.get_index()).queue_free()
	var vbox_plan_output = vbox.get_child(self.get_index() - 1)
	vbox_plan_output.queue_free()
	SignalBus.updated_ga.emit()
	
# Resource: https://gdscript.com/solutions/regular-expressions/
func _on_regex_helper(child : Node, compile_txt : String):
	''' Code used/adapted/modified from 1 '''
	var child_txt = str(child.get_child(0))
	var regex = RegEx.new()
	regex.compile(compile_txt)
	var result = regex.search(child_txt)
	return result
	'''End code used/adapted/modified from 1'''

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
	if Options.opts.goals_timeline and Options.opts.actions_timeline:
		apb = add_predicate_button_scene.instantiate()
		apb.get_node("Button").pressed.connect(_add_predicate)
		predicate_container.add_child(apb)
		
		# shift children
		pred_count += 1
		if pred_count >= 2:
			self.custom_minimum_size.y += 200
		
		# disable actions from being chosen if goal option is chosen for first predicate
		var pred_container = get_node("UI/MainPanel/PanelItems/ImageAndPredicates/PredicateContainer")
		if pred_container.get_child_count() > 2:
			for i in pred_container.get_children():
				if i is PanelContainer and i.get_index() < pred_container.get_child_count() - 1:
					var pred_dropdown = i.get_node("CheckpointPredicate/PredicateDropdown")
					for j in pred_dropdown.get_item_count():
						if j > len(Domain.get_predicates()):
							pred_dropdown.set_item_disabled(j, true)
	elif Options.opts.goals_timeline:
		apb = add_predicate_button_scene.instantiate()
		apb.get_node("Button").pressed.connect(_add_predicate)
		predicate_container.add_child(apb)
		
		# shift children
		pred_count += 1
		if pred_count >= 2:
			self.custom_minimum_size.y += 200
	elif Options.opts.actions_timeline:
		pass
			
	return pred
	
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
	
	# shift children
	pred_count -= 1
	if pred_count >= 1:
		self.custom_minimum_size.y -= 200
		
	# re-enable actions to be chosen if there is only one predicate left
	if Options.opts.goals_timeline and Options.opts.actions_timeline:
		var pred_container = get_node("UI/MainPanel/PanelItems/ImageAndPredicates/PredicateContainer")
		if pred_container.get_child_count() == 2:
			for i in pred_container.get_children():
				if i is PanelContainer and i.get_index() < pred_container.get_child_count() - 1:
					var pred_dropdown = i.get_node("CheckpointPredicate/PredicateDropdown")
					for j in pred_dropdown.get_item_count():
						if j > len(Domain.get_predicates()):
							pred_dropdown.set_item_disabled(j, false)
							
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
	if Options.opts.goals_timeline and Options.opts.actions_timeline:
		apb = add_predicate_button_scene.instantiate()
		apb.get_node("Button").pressed.connect(_add_both)
		predicate_container.add_child(apb)
		
		# shift children
		pred_count += 1
		if pred_count >= 2:
			self.custom_minimum_size.y += 200
		
		# disable actions from being chosen if goal option is chosen for first predicate
		var pred_container = get_node("UI/MainPanel/PanelItems/ImageAndPredicates/PredicateContainer")
		if pred_container.get_child_count() > 2:
			for i in pred_container.get_children():
				if i is PanelContainer and i.get_index() < pred_container.get_child_count() - 1:
					var pred_dropdown = i.get_node("CheckpointPredicate/PredicateDropdown")
					for j in pred_dropdown.get_item_count():
						if j > len(Domain.get_predicates()):
							pred_dropdown.set_item_disabled(j, true)
	elif Options.opts.goals_timeline:
		apb = add_predicate_button_scene.instantiate()
		apb.get_node("Button").pressed.connect(_add_predicate)
		predicate_container.add_child(apb)
		
		# shift children
		pred_count += 1
		if pred_count >= 2:
			self.custom_minimum_size.y += 200
	elif Options.opts.actions_timeline:
		pass

	return both

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
	
	# shift children
	pred_count -= 1
	if pred_count >= 1:
		self.custom_minimum_size.y -= 200
		
	# re-enable actions to be chosen if there is only one predicate left
	if Options.opts.goals_timeline and Options.opts.actions_timeline:
		var pred_container = get_node("UI/MainPanel/PanelItems/ImageAndPredicates/PredicateContainer")
		if pred_container.get_child_count() == 2:
			for i in pred_container.get_children():
				if i is PanelContainer and i.get_index() < pred_container.get_child_count() - 1:
					var pred_dropdown = i.get_node("CheckpointPredicate/PredicateDropdown")
					for j in pred_dropdown.get_item_count():
						if j > len(Domain.get_predicates()):
							pred_dropdown.set_item_disabled(j, false)
