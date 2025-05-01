extends SetPlan

# scenes
var add_pred_button_scene := load("res://Scenes/DrawingBoard/checkpoint/add_predicate_button.tscn")

# children
@onready var chkpt_container := $ScrollContainer/HBoxContainer/VBoxContainer
@onready var button := $ScrollContainer/HBoxContainer/VBoxContainer/InitButton
@onready var preview_container := $PreviewContainer
@onready var timer := $ScrollContainer/HBoxContainer/VBoxContainer/Timer

# Called when the node enters the scene tree for the first time.
func _ready():
	get_node("ScrollContainer/HBoxContainer/VBoxContainer/InitButton").pressed.connect(self._on_init_button_pressed)

	# signals
	SignalBus.set_plan.connect(on_set_plan_init)

func _on_init_button_pressed():
	# Initial button disappears
	button.visible = false

	var new_checkpt = checkpt.instantiate()
	new_checkpt.custom_minimum_size.y = 385
	chkpt_container.add_child(new_checkpt)
	new_checkpt.set_id(curr_id)
	new_checkpt.set_init_checkpt_val(true)
	new_checkpt.set_plan_val(false)
	init_id = curr_id - 1

	_instantiate_plus_button_helper(top_plus_button, new_checkpt.get_index(), chkpt_container)
	_instantiate_plus_button_helper(bottom_plus_button, new_checkpt.get_index() + 1, chkpt_container)
	
	var vbox = VBoxContainer.new()
	chkpt_container.add_child(vbox)
	chkpt_container.move_child(vbox, new_checkpt.get_index())                

func _instantiate_plus_button_helper(plus_button : PackedScene, index : int, container : Node):                                                                                             
	var new_plus_button = plus_button.instantiate()
	new_plus_button.custom_minimum_size.x = 280
	new_plus_button.custom_minimum_size.y = 130
	container.add_child(new_plus_button)
	container.move_child(new_plus_button, index) 
	
func on_set_plan_init(plan_data : Dictionary) -> void:
	if chkpt_container != null:
		for i in chkpt_container.get_children():
			if i is Checkpoint:
				if i.is_init_checkpt == true:
					if i.id == 1:
						print("init checkpoint: ", i.id)
						on_set_plan(plan_data, i, chkpt_container)
					
func _on_help_button_pressed():
	if Options.opts.goals_timeline and Options.opts.actions_timeline:
		get_node("GoalsActionsHelp").visible = true
	elif Options.opts.goals_timeline:
		get_node("GoalsHelp").visible = true
	else:
		get_node("ActionsHelp").visible = true
		
func _on_goals_actions_exit_button_pressed():
	get_node("GoalsActionsHelp").visible = false
	
func _on_goals_exit_button_pressed():
	get_node("GoalsHelp").visible = false
	
func _on_actions_exit_button_pressed():
	get_node("ActionsHelp").visible = false

func _on_done_button_pressed():
	get_node("NextPagePopup").visible = true
	
func get_ga_dict() -> Dictionary:
	var ga_dict = {"serInit": 0,
				   "serStates": [{
				   	"_id": 0,
				   	"name": "init",
				   	"nl": "",
				   	"hidden": false,
				   	"predicates": [],
				   	"actions": [],
				   	"final_state": []
				   }],
				   "serTrans": [],
				   "options": []}
	var chkpt_ids: Array[int] = [0]
	for chkpt in chkpt_container.get_children():
		if chkpt is Checkpoint:
			ga_dict["serStates"].append(chkpt.jsonify())
			chkpt_ids.append(chkpt.id)
	for i in range(len(chkpt_ids) - 1):
		var arc = {}
		arc["sourceID"] = chkpt_ids[i]
		arc["targetID"] = chkpt_ids[i+1]
		arc["condition"] = {"name": ""}
		arc["triggeringEvent"] = {"triggerName": ""}
		ga_dict["serTrans"].append(arc)
	print(ga_dict)
	return ga_dict
