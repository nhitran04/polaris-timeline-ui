'''
License: 
Others' Code used/adapted/modified:
	 1. URL(s): https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_introduction_2d.html
				https://github.com/godotengine/godot-docs/blob/4.2/tutorials/navigation/navigation_introduction_2d.rst
		License: https://github.com/godotengine/godot-docs/blob/4.2/LICENSE.txt
				 (CC-BY-3.0 License)
		SHA (if found on git): 313c3ed3db01cd7b49919c2be40af0c1eb87941f
'''

extends CharacterBody2D

class_name SimulatedCaregiver

@onready var _caregiverSprite = $CaregiverSprite
@onready var _approvalBubble = $approval
@export var tilemap: TileMap
@export var speed = 200

var movement_target_position: Vector2
var moving: bool
var path: PackedVector2Array

var reset_pos_coords: Vector2

func get_input():
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction * speed
	if input_direction[0] > 0:
		if input_direction[1] > 0:
			_caregiverSprite.texture = load("res://Assets/img/simulator/people/caregiver/caregiver-front.png")
		elif input_direction[1] < 0:
			_caregiverSprite.texture = load("res://Assets/img/simulator/people/caregiver/caregiver-back.png")
		else:
			_caregiverSprite.texture = load("res://Assets/img/simulator/people/caregiver/caregiver-right.png")
	elif input_direction[0] < 0:
		if input_direction[1] > 0:
			_caregiverSprite.texture = load("res://Assets/img/simulator/people/caregiver/caregiver-left.png")
		elif input_direction[1] < 0:
			_caregiverSprite.texture = load("res://Assets/img/simulator/people/caregiver/caregiver-left.png")
		else:
			_caregiverSprite.texture = load("res://Assets/img/simulator/people/caregiver/caregiver-left.png")
	else:
		if input_direction[1] > 0:
			_caregiverSprite.texture = load("res://Assets/img/simulator/people/caregiver/caregiver-front.png")
		elif input_direction[1] < 0:
			_caregiverSprite.texture = load("res://Assets/img/simulator/people/caregiver/caregiver-back.png")

#func _physics_process(delta):
#	get_input()
#	move_and_slide()

func _ready():
	# These values need to be adjusted for the actor's speed
	# and the navigation layout.
	#navigation_agent.path_desired_distance = 4.0
	#navigation_agent.target_desired_distance = 4.0
	#navigation_agent.connect("velocity_computed", _move)

	# Make sure to not await during _ready.
	#call_deferred("actor_setup")
	moving = false
	# call_deferred("set_destination")
	
	# set the robot collision margins
	var collision_box: CollisionShape2D = get_node("FloorBounds")
	var collision_margin: Dictionary = {
		"top": collision_box.shape.size.y/2 - collision_box.position.y,
		"bottom": collision_box.shape.size.y/2 + collision_box.position.y,
		"left": collision_box.shape.size.x/2,
		"right": collision_box.shape.size.x/2
	}
	tilemap.set_agent_margins(collision_margin)
	tilemap.instantiate_astar_grid()

	reset_pos_coords = position
	
func reset() -> void:
	position = reset_pos_coords
	moving = false
	
func demo() -> void:
	call_deferred("set_destination", null)

func check_tray() -> void:
	_approvalBubble.show()
	await get_tree().create_timer(1.0).timeout
	_approvalBubble.hide()
	SignalBus.check_tray_finished.emit()

func set_destination(dest: Vector2, robot: CharacterBody2D) -> void:
	tilemap.set_point_and_neighbors_solid(Vector2i(tilemap.pos_to_cell(robot.global_position)))
	path = tilemap.get_point_path(Vector2i(global_position), Vector2i(dest))
	tilemap.set_point_and_neighbors_free(Vector2i(tilemap.pos_to_cell(robot.global_position)))
	# tilemap.astar.update()
	movement_target_position = tilemap.cell_to_pos(path[-1])
	moving = true

func _physics_process(delta):
	if not moving:
		get_input()
		move_and_slide()
		return
		
	var current_agent_position: Vector2 = global_position
	var diff = movement_target_position - current_agent_position
	if diff.length() < 8.0:
		moving = false
		SignalBus.approach_tray_finished.emit()
		return

	var next_path_position: Vector2 = tilemap.cell_to_pos(path[0])
	diff = next_path_position - current_agent_position
	if diff.length() < 8.0:
		path.remove_at(0)
		next_path_position = tilemap.cell_to_pos(path[0])
	diff = next_path_position - current_agent_position
	var angle = atan(diff.x/diff.y)
	# make it 0-360 deg
	while angle > deg_to_rad(360):
		angle = angle - deg_to_rad(360)
	while angle < deg_to_rad(0):
		angle = angle + deg_to_rad(360)

	if(abs(diff.x) > abs(diff.y)): # moving left/right
		if diff.x > 0:
			_caregiverSprite.texture = load("res://Assets/img/simulator/people/caregiver/caregiver-right.png")
		else:
			_caregiverSprite.texture = load("res://Assets/img/simulator/people/caregiver/caregiver-left.png")
	else:
		if diff.y > 0:
			_caregiverSprite.texture = load("res://Assets/img/simulator/people/caregiver/caregiver-front.png")
		else:
			_caregiverSprite.texture = load("res://Assets/img/simulator/people/caregiver/caregiver-back.png")

	velocity = diff.normalized() * speed
	move_and_slide()
