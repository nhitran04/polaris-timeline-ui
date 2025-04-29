extends Node3D

class_name EntityNode

@onready var drag_collider := $DrawArea/CollisionShape3D
@onready var node_collision_object := $NodeArea
@onready var node_collider := $NodeArea/CollisionShape3D

signal position_changed(global_pos: Vector3, node: Node3D)
var position_did_change: bool

func _ready() -> void:
	position_did_change = false
	drag_collider.input_event.connect(_on_draw_area_input_event)

func _on_draw_area_input_event(_camera, event, position, _normal, _shape_idx):
	if event is InputEventScreenDrag and not drag_collider.disabled:
		node_collider.set_disabled(true)
		position_changed.emit(position, self)
		position_did_change = true
		var exceptions: Array[Node3D] = [node_collision_object]
		SignalBus.disable_world_entity_raycasts_with_exceptions.emit(exceptions)
		SignalBus.edit_menu_hide.emit()
	if event is InputEventMouseButton and event.is_action_released("click"):
		drag_collider.set_disabled(true)
		node_collider.set_disabled(false)
		SignalBus.enable_world_entity_raycasts.emit()
		if position_did_change:
			position_did_change = false
		SignalBus.edit_menu_hide.emit()
