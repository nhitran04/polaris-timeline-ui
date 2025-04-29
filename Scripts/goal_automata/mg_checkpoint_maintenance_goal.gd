extends CheckButton

class_name MG_Maintenance_Goal

# instance vars
var argRegex: RegEx
var numRegex: RegEx
var _id: int

var parent_checkpoint: Node

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func populate(mg_id: int, state_data: Array, active: bool) -> void:
	# set pred id
	_id = mg_id
	
	# set up REGEX
	argRegex = RegEx.new()
	argRegex.compile("\\[[0-9]*\\]")
	numRegex = RegEx.new()
	numRegex.compile("\\d+")
	
	# find predicate and populate nl string with params
	for state in state_data:
		for pred in state["predicates"]:
			if pred["_id"] == _id:
				# get base nl string
				var nl_temp: String = Domain.get_pred_nl(pred["name"])

				var pred_data: Dictionary = Domain.get_pred(pred["name"])
				
				# split the nl and determine how large to make the hbox
				var nl_temp_split: PackedStringArray = nl_temp.split(" ")
				var nl: String = ""
				for i in nl_temp_split.size():
					var nl_bit = nl_temp_split[i]
					if argRegex.search(nl_bit):
						
						# get the arg idx
						var idx = int(numRegex.search(nl_bit).get_string())
						
						# get the predicate data at that parameter idx
						var param = pred["parameters"][idx]

						nl += "%s " % param

					else:
						nl += "%s " % nl_bit

				# update checkbutton label text
				text = nl

	# set the button active (enabling the maintenance goal)
	if active:
		button_pressed = true
	else:
		button_pressed = false

func set_parent_checkpoint(parent_chkpt: Node) -> void:
	parent_checkpoint = parent_chkpt

# controls behavior when the toggle is pressed
# since the checkpoint shows the maintenance goals from the previous checkpoint, then we need to mark them as disabled within the previous checkpoint
func _pressed():
	if(button_pressed):
		# remove from list of disabled maintenance goals
		parent_checkpoint.disabled_maintenance_goals.erase(_id)
	else:
		# add to list of disabled maintenance goals
		parent_checkpoint.disabled_maintenance_goals.append(_id)

	# send the update
	SignalBus.updated_ga.emit()
