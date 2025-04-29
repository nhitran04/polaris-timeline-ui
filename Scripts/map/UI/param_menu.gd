extends ColorPicker

# instance variables
var obj_in_focus: Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	color_changed.connect(_color_changed)


func _show_menu(pos: Vector2, obj: Node3D) -> void:
	
	# set visibility and position
	visible = true
	position = pos
	
	# set current color
	var col: Color = obj.get_color()
	color = col
	
	# store obj in focus
	obj_in_focus = obj
	
func _hide_menu() -> void:
	visible = false
	
func _color_changed(col: Color) -> void:
	obj_in_focus.set_color(col)
