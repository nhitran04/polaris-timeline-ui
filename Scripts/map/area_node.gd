extends EntityNode

class_name AreaNode

# instance variables
var area: Area

func _ready() -> void:
	position_did_change = false
	SignalBus.activate_build_mode.connect(_grow)
	SignalBus.activate_nav_mesh_mode.connect(_shrink)
	SignalBus.activate_param_mode.connect(_shrink)
	SignalBus.activate_uncert_mode.connect(_shrink)

func _on_node_area_input_event(_camera, event, _position, _normal, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		drag_collider.set_disabled(false)
	elif event is InputEventMouseButton and event.is_action_released("click"):
		SignalBus.edit_menu_toggle.emit(event.position, self)
		drag_collider.set_disabled(true)
		
func set_area(area: Area) -> void:
	self.area = area
		
func delete() -> void:
	area.delete_node(self)

func _shrink() -> void:
	self.radius = 0.1
	node_collider.set_disabled(true)
	
func _grow() -> void:
	self.radius = 0.2
	node_collider.set_disabled(false)
	
