extends Node3D

class_name Robot

@onready var robot_model := $Robot as Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func get_label() -> String:
	return get_node("label").get_node("SubViewport").get_node("TextEdit").text
	
func set_label(label: String) -> void:
	get_node("label").get_node("SubViewport").get_node("TextEdit").text = label
	
func get_properties() -> Dictionary:
	# currently none for robot
	return {}

func set_default_properties() -> void:
	# caregiving-specific properties
	if Options.opts.domain == "caregiving":
		# (currently none for robot)
		pass

	# food assembly-specific properties
	if Options.opts.domain == "food_assembly":
		# (currently none for robot)
		pass

func jsonify() -> Dictionary:
	var to_return: Dictionary
	to_return = {
		"entity_class": "robot",
		"label": get_label(),
		"position": [position.x, position.y, position.z]
	}
	return to_return
