extends Control

class_name Action

@export var label: Label

# instance variables
var action_name: String
var action_desc: String
var final_state: Array
var curr_size: Vector2
var action_params: Array

func _ready() -> void:
	SignalBus.toggle_hints.connect(_toggle_visibility)

func set_name_val(new_action_name: String) -> void:
	action_name = new_action_name
	
func set_desc_val(new_action_desc: String) -> void:
	action_desc = new_action_desc
	
func set_final_state(new_final_state: Array) -> void:
	final_state = new_final_state
	
func set_action_params(new_action_params: Array) -> void:
	action_params = new_action_params
	
func _toggle_visibility() -> void:
	if visible:
		visible = false
	else:
		visible = true

func _on_label_gui_input(event):
	if event is InputEventMouseButton and event.is_action_pressed("click"):
		SignalBus.expand_action_hint.emit(self)

func _on_label_resized():
	var diff: int = label.size.x - curr_size.x
	label.position.x -= diff
	curr_size = label.size
