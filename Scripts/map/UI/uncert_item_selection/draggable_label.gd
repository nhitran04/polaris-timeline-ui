extends CanvasLayer

# exported vars
@export var parent: MeshInstance3D
@export var vp_parent: SubViewport

# loaded nodes
@onready var draglabel := $DraggableLabel

# instance variables
var perma_pos: Vector2
var dragging: bool
var click_offset: Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	if Options.opts.uncert_sliders:
		visible = true
	parent.label_position_changed.connect(_on_position_changed)
	dragging = false
	
func _on_position_changed() -> void:
	draglabel.text = parent.textedit.text
	return
	draglabel.position = get_viewport().get_camera_3d().unproject_position(parent.global_position)# - Vector2(130, 30)
	perma_pos = draglabel.position
	
	# TODO: this is a very duct-taped solution for adjusting the size.
	#       Clean it up by putting the drag label under the subviewport.
	var z = get_viewport().get_camera_3d().global_position.z
	draglabel.add_theme_font_size_override("font_size", 40 - z)
	

func on_gui_input():
	draglabel.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	dragging = true
	layer = 2
	draglabel.add_theme_font_size_override("font_size", 42)

func _input(event: InputEvent) -> void:
	if dragging:
		draglabel.position = event.position - Vector2(40, 30)
		draglabel.visible = true
		if event is InputEventMouseButton and event.is_action_released("click"):
			draglabel.add_theme_color_override("font_color", Color(0, 0, 0, 0))
			dragging = false
			draglabel.position = perma_pos
			var gp = event.global_position
			SignalBus.uncert_new_slider.emit(draglabel.text, event.global_position)
			layer = 0
			draglabel.position = Vector2(0, 0)
			draglabel.visible = false
