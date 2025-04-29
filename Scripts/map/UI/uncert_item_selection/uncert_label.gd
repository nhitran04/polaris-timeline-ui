extends Node3D

@onready var mesh3d := $MeshInstance3D
@onready var label := $SubViewport/VBoxContainer/Label as Label
@onready var perc_label := $SubViewport/VBoxContainer/Percent as Label

# instance variables
var curr_rotation: float
var uid: int

# Called when the node enters the scene tree for the first time.
func _ready():
	SignalBus.rotate_map.connect(map_rotated)
	curr_rotation = 0
	
	if Options.opts.uncert_rank:
		_hide_percentage()
	elif Options.opts.uncert_sliders:
		_show_percentage()
	
func set_uid(uid: int) -> void:
	self.uid = uid

func set_label(text: String) -> void:
	label.text = text

func set_label_size(size: int) -> void:
	label.add_theme_font_size_override("font_size", size)
	
func _show_percentage() -> void:
	perc_label.show()
	
func _hide_percentage() -> void:
	perc_label.hide()
	
func set_percentage(percent: String) -> void:
	perc_label.text = percent
	
func delete() -> void:
	get_parent().remove_child(self)
	queue_free()
	
func map_rotated(map_angle: float) -> void:
	mesh3d.rotate_z(map_angle - curr_rotation)
	curr_rotation = map_angle

func _on_exit_button_pressed(camera, event, position, normal, shape_idx):
	if event is InputEventMouseButton and event.is_action_released("click"):
		SignalBus.delete_uncert_point.emit(uid)
