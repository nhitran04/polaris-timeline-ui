extends PanelContainer

class_name CheckpointPredicate

@onready var predicates_dropdown = $CheckpointPredicate/PredicateDropdown as OptionButton
@onready var nl_box = $CheckpointPredicate/PredicateNL/NLBox
@onready var delete_button = $DeleteButtonPanel/DeleteButton

var action_scene := load("res://Scenes/DrawingBoard/checkpoint/checkpoint_action.tscn")

signal delete_predicate(pred: CheckpointPredicate)
signal delete_action(action: CheckpointAction)
signal delete_both(both: CheckpointBoth)

# instance variables
var world_database: Node
var argRegex: RegEx
var numRegex: RegEx
var param_mapper: Dictionary
var id: int
var delete_signal: Signal
var selected_idx : int
var parent_checkpoint: Node
var apb: PanelContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	argRegex = RegEx.new()
	argRegex.compile("\\[[0-9]*\\]")
	numRegex = RegEx.new()
	numRegex.compile("\\d+")
	id = PredicateIdGenerator.register_new_id()

	update_dropdown_items({})	
	predicates_dropdown.item_selected.connect(_on_option_button_item_selected)
	
	SignalBus.broadcast_world.connect(update_dropdown_items)
	
	if Options.opts.goals_timeline or (Options.opts.goals_timeline and Options.opts.actions_timeline):
		delete_button.pressed.connect(_delete)	
	else:
		delete_button.visible = false
		
	_on_option_button_item_selected(0)

func add_world(world_database: WorldDatabase) -> void:
	self.world_database = world_database
	
func add_delete_callback(delete_cb: Signal):
	delete_signal = delete_cb

func set_parent_checkpoint(parent_chkpt: Node) -> void:
	parent_checkpoint = parent_chkpt

func update_dropdown_items(_world: Dictionary):
	var array: Array[String]
	var dropdown: OptionButton 

	# grab the list of predicates and the dropdown to populate
	if Options.opts.goals_timeline and Options.opts.actions_timeline:
		array = Domain.get_predicates() + Domain.get_actions()
		dropdown = predicates_dropdown
		assert(len(array) > 0,
				"No predicates or actions available to add to checkpoint.")
	elif Options.opts.goals_timeline:
		array = Domain.get_predicates()
		dropdown = predicates_dropdown
		assert(len(array) > 0,
				"No predicates available to add to checkpoint.")
	# grab the list of actions and the dropdown to populate
	elif Options.opts.actions_timeline:
		array = Domain.get_actions()
		dropdown = predicates_dropdown
		assert(len(array) > 0,
				"No actions available to add to checkpoint.")

	# grab the current selection
	var curr_selected_id: int = dropdown.get_selected_id()
	var curr_selected: String
	if curr_selected_id >= 0:
		curr_selected = dropdown.get_item_text(dropdown.get_item_index(curr_selected_id))
	
	# if nothing has been selected or the current selection exists in the new predicate list
	var count = 0
	if curr_selected_id == -1 or curr_selected in array:
		# clear the dropdown and re-populate
		dropdown.clear()
		var str_array: Array[String] = []
		for i in array:
			if Options.opts.goals_timeline and Options.opts.actions_timeline:
				if count < len(Domain.get_predicates()):
					if count == 0:
						dropdown.add_separator("GOALS")
					var pred_data: Dictionary = Domain.get_pred(i)
					update_dropdown_items_helper(pred_data, true, dropdown, str_array, i)
					count += 1
				else:
					if count == len(Domain.get_predicates()):
						dropdown.add_separator("ACTIONS")
					var action_data: Dictionary = Domain.get_action(i)
					update_dropdown_items_helper(action_data, false, dropdown, str_array, i)
					count += 1
			elif Options.opts.goals_timeline:
				var pred_data: Dictionary = Domain.get_pred(i)
				update_dropdown_items_helper(pred_data, true, dropdown, str_array, i)
			else:
				var action_data: Dictionary = Domain.get_action(i)
				update_dropdown_items_helper(action_data, false, dropdown, str_array, i)
				
		# if a current selection exists in the new predicate list
		if curr_selected_id > 0:
			var idx: int = str_array.find(curr_selected)
			if idx >= 0:
				dropdown.select(idx)
			else:
				delete_signal.emit(self)
				
	# if the current predicate does not exist in the updated array
	else:
		delete_signal.emit(self)
		
func update_dropdown_items_helper(data : Dictionary, is_goals_timeline : bool, 
									dropdown: OptionButton, str_array: Array[String], i) -> void:
	var contains_arguments: bool = true
	for param in data.parameters:
		var type = param.param_val
		var child_of_item = type in Domain.get_subtypes("item")
		var types = Domain.get_type_and_subtypes(type)
		var objs = self.world_database.get_objects_of_types(types, child_of_item)
		if is_goals_timeline == true:
			if len(objs) == 0:
				contains_arguments = false
				break
	if contains_arguments:
		dropdown.add_item(i)
		str_array.append(i)
		
func _on_option_button_item_selected(index: int) -> void:
	clear_dropdowns()
	
	# set the symbol and raw NL
	var pred_name: String = predicates_dropdown.get_item_text(index)
	if pred_name == "GOALS":
		pred_name = predicates_dropdown.get_item_text(index + 1)
	var pred_data: Dictionary
	var action_data: Dictionary
	var nl: String
	
	if Options.opts.goals_timeline and Options.opts.actions_timeline:
		# merge goals and actions for dropdown options
		pred_data = Domain.get_pred(pred_name)
		pred_data.merge(Domain.get_action(pred_name))
		if Domain.get_pred_nl(pred_name) != "":
			nl = Domain.get_pred_nl(pred_name)
		else:
			nl = Domain.get_action_nl(pred_name)
		
		# make adding multiple conditions available only if a goal is chosen from dropdown
		var chkpt_node = get_parent().get_parent().get_parent().get_parent().get_parent().get_parent()
		var add_pred_button = chkpt_node.get_node("UI/MainPanel/PanelItems/ImageAndPredicates/PredicateContainer/AddPredicateButton")
		var vbox_container = "Polaris/Problem/TwoWayTimeline/ScrollContainer/HBoxContainer/VBoxContainer"
		
		if index > len(Domain.get_predicates()):
			# turn off visibility for delete button and add predicate button if action option is selected
			for i in get_tree().root.get_node(vbox_container).get_children():
				if i is Checkpoint and i.id == chkpt_node.id:
					add_pred_button.visible = false
		else:
			# turn on visibility for add predicate button if goal option is selected
			for i in get_tree().root.get_node(vbox_container).get_children():
				if i is Checkpoint and i.id == chkpt_node.id:
					if add_pred_button != null:
						add_pred_button.visible = true					
	elif Options.opts.goals_timeline:
		pred_data = Domain.get_pred(pred_name)
		nl = Domain.get_pred_nl(pred_name)
	else:
		pred_data = Domain.get_action(pred_name)
		nl = Domain.get_action_nl(pred_name)
		
	# split the nl and determine how large to make the hbox
	var nl_temp_split: PackedStringArray = nl.split(" ")
	var nl_temp: String = ""
	for i in nl_temp_split.size():
		var nl_bit = nl_temp_split[i]
						
		if argRegex.search(nl_bit):
			# get the arg idx
			var idx = int(numRegex.search(nl_bit).get_string())
			
			# get the predicate data at that parameter idx
			var param = pred_data.parameters[idx]
			var type = param.param_val
			var child_of_item = type in Domain.get_subtypes("item")
			var types = Domain.get_type_and_subtypes(type)
			var objs = self.world_database.get_objects_of_types(types, child_of_item)
			nl_temp = nl_temp.strip_edges()
			
			# IF nl_temp is nonempty, create and add a label
			_add_nl_text_helper(nl_temp)
			param_mapper[idx] = len(nl_box.get_children())
			nl_temp = "" 
			
			# add the NL bit
			var opt = OptionButton.new()
			opt.item_selected.connect(_on_parameter_selected)
			for obj in objs:
				opt.add_item(obj.get_label())
			nl_box.add_child(opt)
		else:
			nl_temp += "%s " % nl_bit
			
	# IF nl_temp is nonempty, create and add a label
	_add_nl_text_helper(nl_temp)
	
	# send data to backend
	SignalBus.updated_ga.emit()
	
func clear_dropdowns() -> void:
	for temp in nl_box.get_children():
		nl_box.remove_child(temp)
		temp.queue_free()
		
	# the param mapper may store indices of previously selected predicates
	param_mapper.clear()
	
func set_symbol(pred_name: String) -> void:
	for i in predicates_dropdown.item_count:
		var text = predicates_dropdown.get_item_text(i)
		if text == pred_name:
			predicates_dropdown.select(i)
			_on_option_button_item_selected(i)
			break
	
func set_params(params: PackedStringArray) -> void:
	for i in len(param_mapper):
		var param_dropdown = nl_box.get_children()[param_mapper[i]]
		for j in param_dropdown.item_count:
			var text = param_dropdown.get_item_text(j)
			if params[i] == text:
				param_dropdown.select(j)
				break

func _on_parameter_selected(_index: int) -> void:
	# send data to backend
	SignalBus.updated_ga.emit()

func _add_nl_text_helper(text: String) -> void:
	if len(text) > 0:
		var lab = Label.new()
		lab.text = text
		nl_box.add_child(lab)
		
func _on_predicate_gui_input(event):
	if event is InputEventMouseButton and event.is_action_pressed("click"):
		SignalBus.lock_2D_camera_pan.emit(true)
	if event is InputEventMouseButton and event.is_action_released("click"):
		SignalBus.lock_2D_camera_pan.emit(false)
	if event is InputEventScreenDrag:
		print(event.position)
		
func _delete() -> void:
	# first remove it from any disabled maintenance goal lists if relevant
	if(Options.opts["maintenance_goals"]):
		_delete_mg_helper(parent_checkpoint)
		
	# send delete signal
	delete_signal.emit(self)

# use this to help recursively remove predicate ID from disabled maintenance goals of checkpoints
func _delete_mg_helper(chkpt: Node) -> void:
	# first remove the predicate ID from list of disabled maintenance goals
	chkpt.disabled_maintenance_goals.erase(id)

	# then do the same for each outgoing transition
	for trans in chkpt.out_trans:
		_delete_mg_helper(trans.target)

func jsonify() -> Dictionary:
	var pred_data = {"name": predicates_dropdown.text,
					 "_id": id,
					 "parameters": []
		}
	for i in len(param_mapper):
		pred_data["parameters"].append(nl_box.get_children()[param_mapper[i]].text)
	return pred_data
