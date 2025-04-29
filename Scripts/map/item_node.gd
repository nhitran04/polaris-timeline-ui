extends EntityNode

class_name ItemNode

@export var item: Node3D

func _ready() -> void:
	position_did_change = false

func _on_node_area_input_event(camera, event, position, normal, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		drag_collider.set_disabled(false)
	elif event is InputEventMouseButton and event.is_action_released("click"):
		SignalBus.edit_menu_toggle.emit(event.position, item)
		drag_collider.set_disabled(true)
