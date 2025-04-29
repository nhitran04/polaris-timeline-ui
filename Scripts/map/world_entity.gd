extends Node3D

class_name WorldEntity

var region# := load("res://Scenes/map/region.tscn")
var surface# := load("res://Scenes/map/surface.tscn")
var item# := load("res://Scenes/map/item.tscn")
var person# := load("res://Scenes/map/person.tscn")
var robot# := load("res://Scenes/map/robot.tscn")

# instance vars
var entity_class: String

func _ready() -> void:
	region = load("res://Scenes/map/region.tscn")
	surface = load("res://Scenes/map/surface.tscn")
	item = load("res://Scenes/map/item.tscn")
	person = load("res://Scenes/map/person.tscn")
	robot = load("res://Scenes/map/robot.tscn")

func create_region(bounding_box: PackedVector3Array, props: Dictionary, is_new: bool, label="unknown_region") -> void:
	# scenes
	entity_class = "region"
	var new_area = region.instantiate()
	if is_new:
		new_area.set_default_properties()
	else:
		new_area.set_properties(props)
	self.add_child(new_area)
	new_area.add_root(self)
	new_area.add_area(bounding_box)
	set_label(label)
	
func create_surface(bounding_box: PackedVector3Array, props: Dictionary, is_new: bool, label="unknown_surface") -> void:
	entity_class = "surface"
	var new_area = surface.instantiate()
	if is_new:
		new_area.set_default_properties()
	else:
		new_area.set_properties(props)
	self.add_child(new_area)
	new_area.add_root(self)
	new_area.add_area(bounding_box)
	new_area.add_surface_legs()
	set_label(label)

func create_item(pos: Vector3, subtype: String, props: Dictionary, is_new: bool, label="unknown_item") -> void:
	entity_class = "item"
	var new_item = item.instantiate()
	new_item.set_subtype(subtype)
	if is_new:
		new_item.set_default_properties()
	else:
		new_item.set_properties(props)
	add_child(new_item)
	new_item.global_position.x = pos.x
	new_item.global_position.y = pos.y
	set_label(label)
	new_item.set_uncertainty(false)

func create_person(pos: Vector3, props: Dictionary, is_new: bool, label="unknown_person") -> void:
	entity_class = "person"
	var new_person = person.instantiate()
	if is_new:
		new_person.set_default_properties()
	else:
		new_person.set_properties(props)
	add_child(new_person)
	new_person.global_position.x = pos.x
	new_person.global_position.y = pos.y
	set_label(label)
	new_person.set_uncertainty(false)
	
func create_robot() -> void:
	entity_class = "robot"
	var new_robot = robot.instantiate()
	new_robot.set_default_properties()
	add_child(new_robot)
	set_label("gandalf")
	
func add_end_effector() -> void:
	entity_class = "end_effector"
	
func get_entity_class() -> String:
	return entity_class

func get_label() -> String:
	var to_return = "entity"
	match entity_class:
		"region":
			to_return = get_node("region").get_label()
		"surface":
			to_return = get_node("surface").get_label()
		"item":
			to_return = get_node("item").get_label()
		"person":
			to_return = get_node("person").get_label()
		"robot":
			to_return = get_node("robot").get_label()
		"end_effector":
			to_return = "gripper"
	return to_return
	
func set_label(label: String) -> void:
	match entity_class:
		"region":
			get_node("region").set_label(label)
		"surface":
			get_node("surface").set_label(label)
		"item":
			get_node("item").set_label(label)
		"person":
			get_node("person").set_label(label)
		"robot":
			get_node("robot").set_label(label)
	
func get_properties() -> Dictionary:
	var to_return = {}
	match entity_class:
		"region":
			to_return = get_node("region").get_properties()
		"surface":
			to_return = get_node("surface").get_properties()
		"item":
			to_return = get_node("item").get_properties()
		"person":
			to_return = get_node("person").get_properties()
		"robot":
			to_return = get_node("robot").get_properties()
		"end_effector":
			to_return = {"is_grabbable": false}
	return to_return
	
func get_entity() -> Node3D:
	var to_return: Node3D
	match entity_class:
		"region":
			to_return = get_node("region")
		"surface":
			to_return = get_node("surface")
		"item":
			to_return = get_node("item")
		"person":
			to_return = get_node("person")
		"robot":
			to_return = get_node("robot")
	return to_return
	
func get_location() -> Vector3:
	if entity_class == "item":
		return get_node("item").position
	elif entity_class == "person":
		return get_node("person").position
	elif entity_class == "robot":
		return get_node("robot").position
	elif entity_class == "surface":
		return get_node("surface").calculate_bounding_box_center()
	elif entity_class == "region":
		return get_node("region").calculate_bounding_box_center()
	else:
		return Vector3(0, 0, 0)
		
func set_location(loc: Vector3) -> void:
	if entity_class == "item":
		get_node("item").position = loc
	elif entity_class == "person":
		get_node("person").position = loc
	elif entity_class == "robot":
		get_node("robot").position = loc
	else:
		# TODO: regions, surfaces, and end_effectors should have positions
		position = Vector3(0, 0, 0) 
	
func jsonify() -> Dictionary:
	var to_return = {}
	match entity_class:
		"region":
			to_return = get_node("region").jsonify()
		"surface":
			to_return = get_node("surface").jsonify()
		"item":
			to_return = get_node("item").jsonify()
		"person":
			to_return = get_node("person").jsonify()
		"robot":
			to_return = get_node("robot").jsonify()
	return to_return
