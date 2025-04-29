extends StaticBody3D

@onready var wp_name_label := $wp_name as Label3D
@onready var wp_mesh := $mesh as MeshInstance3D

# instance variables
var wp_name: String

# Called when the node enters the scene tree for the first time.
func _ready():
	wp_name = "unknown_wp"
	SignalBus.activate_waypoint.connect(_activate)
	SignalBus.deactivate_waypoints.connect(_deactivate)
	
func _activate(nam: String, size: int, color: Color):
	if nam == get_full_name():
		show()
		propagate_call("show")
		wp_mesh.set_surface_override_material(0, wp_mesh.get_active_material(0).duplicate())
		wp_mesh.get_surface_override_material(0).albedo_color = color
		wp_mesh.scale.x = size * 0.01
		wp_mesh.scale.y = size * 0.01

func _deactivate() -> void:
	wp_mesh.get_active_material(0).albedo_color = Color("f4d050")
	wp_mesh.scale = Vector3(0.5, 0.5, 0.25)
	visible = false

func get_wp_name() -> String:
	return wp_name
	
func get_area() -> Area:
	return get_parent().get_parent()
	
func get_full_name() -> String:
	'''Returns area name appended with waypoint'''
	var full_name: String = get_parent().get_parent().get_label() + "_" + wp_name
	full_name = full_name.replace(" ", "_")
	return full_name
	
func set_wp_name(wp_name: String) -> void:
	self.wp_name = wp_name
	wp_name_label.text = wp_name
