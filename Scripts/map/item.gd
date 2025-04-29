extends Node3D

class_name Item

@onready var shape := $shape as MeshInstance3D
@onready var outline := $shape/outline as MeshInstance3D

# properties
var properties := {}

var subtype: String

# instance variables
var editing_text := false
var is_uncertain := false

# Called when the node enters the scene tree for the first time.
func _ready():
	# set position adjustment callback
	get_node("shape").position_changed.connect(_adjust_position)

func set_subtype(st: String) -> void:
	subtype = st

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _adjust_position(global_pos: Vector3, node: Node3D) -> void:
	global_position.x = global_pos.x
	global_position.y = global_pos.y
	SignalBus.reset_predicates.emit()
	
func get_color() -> Color:
	return shape.material_override.albedo_color
	
func set_color(col: Color) -> void:
	var material_dup: Material = shape.material_override.duplicate()
	material_dup.albedo_color = col
	shape.material_override = material_dup
	
func set_uncertainty(val: bool) -> void:
	is_uncertain = val
	if val:
		shape.material_override.transparency = 1  # alpha transparency enabled
		shape.material_override.albedo_color = Color(.30, .30, .9, .6)
		outline.visible = false
		shape.material_override.render_priority = 3
	else:
		shape.material_override.transparency = 0  # alpha transparency disabled
		shape.material_override.albedo_color = Color(.855, .216, .384, 1.0)
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
		properties["is_grabbable"] = false
		properties["is_openable"] = false
		properties["is_container"] = false

	# food assembly-specific properties
	if Options.opts.domain == "food_assembly":
		properties["is_grabbable"] = true
		properties["is_openable"] = false

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
	SignalBus.delete_item.emit(self)

func jsonify() -> Dictionary:
	var to_return: Dictionary = {
		"entity_class": "item",
		"label": get_label(),
		"position": [position.x, position.y],
		"properties": properties,
		"color": [get_color().r, get_color().g, get_color().b, get_color().a]
	}
	# only include the subtype if the item has a subtype!
	if subtype != "":
		to_return["subtype"] = subtype
	return to_return
