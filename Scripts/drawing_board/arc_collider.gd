'''
License: 
Others' Code used/adapted/modified:
	 1. URL(s): https://kidscancode.org/godot_recipes/3.x/2d/line_collision/index.html
				https://github.com/kidscancode/godot_recipes/blob/master/docs/3.x/2d/line_collision/index.html
		License: https://github.com/kidscancode/godot_recipes/blob/master/LICENSE
				 (MIT License)
		SHA (if found ogit): f9ee16593f6bc03f7d2ce2f0d761f27cc3cca2f6
'''

extends RigidBody2D

class_name ArcCollider 

# references to children
@onready var _collider := $ArcCollider
	
func add_bounds(pt1: Vector2, pt2: Vector2) -> void:
	''' Code used/adapted/modified from 1 '''
	var rect = RectangleShape2D.new()
	_collider.position = (pt1 + pt2) / 2
	_collider.rotation = pt1.direction_to(pt2).angle()
	var length = pt1.distance_to(pt2)
	rect.extents = Vector2(length / 2, 10)
	_collider.shape = rect
	''' Code used/adapted/modified from 1 '''

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.is_action_pressed("click"):
		SignalBus.enter_plan_vis.emit()
