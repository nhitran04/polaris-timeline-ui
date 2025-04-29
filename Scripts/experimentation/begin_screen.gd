extends CanvasLayer

@onready var background := $Background
@onready var button := $Background/Button
@onready var label := $Background/Label

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# button
	button.pressed.connect(_on_begin)
	
	SignalBus.press_begin.connect(_on_begin)
	
	# label
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.set_corner_radius_all(16)
	var sb_hover: StyleBoxFlat = sb.duplicate()
	var sb_background: StyleBoxFlat = StyleBoxFlat.new()
	sb_background.content_margin_top = 100
	label.text = "[center]Press BEGIN to specify where the "
	if Options.opts["curr_item"] == "umbrella":
		label.text += "[color=cyan]umbrella[/color] could be.[/center]"
		sb.bg_color = Color.DARK_CYAN
		sb_background.bg_color = Color(0.0, 0.1, 0.1, 1.0)
		button.add_theme_stylebox_override("normal", sb)
		background.add_theme_stylebox_override("panel", sb_background)
	else:
		label.text += "[color=gold]bag[/color] could be.[/center]"
		sb.bg_color = Color.DARK_GOLDENROD
		sb_hover.bg_color = Color.GOLD
		sb_background.bg_color = Color(0.1, 0.1, 0.0, 1.0)
		button.add_theme_stylebox_override("normal", sb)
		button.add_theme_stylebox_override("hover", sb_hover)
		background.add_theme_stylebox_override("panel", sb_background)
		
	# resize control
	get_viewport().connect("size_changed", _on_viewport_resize)
	_on_viewport_resize()
	
func _on_begin() -> void:
	Logger.log_event("button_begin", {})
	get_parent().remove_child(self)
	queue_free()

func _on_viewport_resize() -> void:
	pass
	'''
	var vp = get_viewport()
	if vp != null:
		var vp_size = Vector2(vp.size)
		background.size = vp_size
		background.position = Vector2(0, 0)
	'''
