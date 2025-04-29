extends Node2D

# scenes
var _checkpointScene := load("res://Scenes/branching_GA/checkpoint.tscn")

# existing nodes
@onready var _lines := $Lines

# instance vars
var _pressed := false
var _released := false
var _current_line: Line2D

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_pressed = event.pressed
		_released = event.is_action_released("click")

		if _pressed:
			_current_line = Line2D.new()
			_current_line.width = 3
			_lines.add_child(_current_line)
			
		if _released:
			# 0) preconditions
			if len(_current_line.points) < 2:
				return
			# 1) replace the line
			var _straight_line = Line2D.new()
			_straight_line.add_point(_current_line.points[0])
			_straight_line.add_point(_current_line.points[-1])
			_lines.add_child(_straight_line)
			
			# 2) add the checkpoint
			var _checkpoint = _checkpointScene.instantiate()
			_checkpoint.position = _current_line.points[-1]
			add_child(_checkpoint)
			
			# 3) clear
			_current_line.clear_points()
	
	if event is InputEventMouseMotion && _pressed:
		_current_line.add_point(event.position)
