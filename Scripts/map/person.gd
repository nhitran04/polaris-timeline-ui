extends Node3D

class_name Person

@onready var shape := $shape as MeshInstance3D
@onready var outline := $shape/outline as MeshInstance3D

# properties
var properties := {}

# instance variables
var editing_text := false
var is_uncertain := false

# Called when the node enters the scene tree for the first time.
func _ready():
	# set position adjustment callback
	get_node("shape").position_changed.connect(_adjust_position)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _adjust_position(global_pos: Vector3, node: Node3D) -> void:
	global_position.x = global_pos.x
	global_position.y = global_pos.y
	SignalBus.reset_predicates.emit()
	
func set_uncertainty(val: bool) -> void:
	is_uncertain = val
	if val:
		shape.material_override.transparency = 1  # alpha transparency enabled
		shape.material_override.albedo_color = Color(.30, .30, .9, .6)
		outline.visible = false
		shape.material_override.render_priority = 3
	else:
		shape.material_override.transparency = 0  # alpha transparency disabled
		shape.material_override.albedo_color = Color(1.0, .83, .15, 1.0)
		outline.visible = true
		shape.material_override.render_priority = 2

func get_label() -> String:
	#return get_node("label").text
	return get_node("label").get_node("SubViewport").get_node("TextEdit").text
	
func set_label(label: String) -> void:
	#get_node("label").text = label
	get_node("label").get_node("SubViewport").get_node("TextEdit").text = label
	
func get_properties() -> Dictionary:
	return properties

func set_properties(new_props: Dictionary) -> void:
	properties = new_props

func set_default_properties() -> void:
	# caregiving-specific properties
	if Options.opts.domain == "caregiving":
		# (currently none for person)
		pass

	# food assembly-specific properties
	if Options.opts.domain == "food_assembly":
		# (currently none for person)
		pass

func _on_area_3d_input_event(camera, event, position, normal, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		get_node("label").text = ""
		editing_text = true
	
func _input(event: InputEvent) -> void:
	if editing_text:
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_ENTER:
				editing_text = false
			else:
				get_node("label").text += event.as_text_keycode()
	#$label/SubViewport.push_input(event)
	
func delete() -> void:
	SignalBus.delete_person.emit(self)

func jsonify() -> Dictionary:
	var to_return: Dictionary
	to_return = {
		"entity_class": "person",
		"label": get_label(),
		"position": [position.x, position.y],
		"properties": properties
	}
	return to_return
