extends Panel

# pre-loaded nodes
@onready var tex_control := $Key/PanelContainer/TextureRect as TextureRect
@onready var key_label := $Key/Label as Label
@onready var label_hbox := $Key/HBoxContainer as HBoxContainer
@onready var high_label := $Key/HBoxContainer/high as Label
@onready var low_label := $Key/HBoxContainer/low as Label

# shaders
#@onready var shad = preload("res://Scenes/demos/world.gdshader")
@onready var shad_monochrome = preload("res://Resources/shaders/uncert_monochrome.gdshader")

# Called when the node enters the scene tree for the first time.
func _ready():

	call_deferred("_set_key")
	 
	# resize control
	get_viewport().connect("size_changed", _on_viewport_resize)
	_on_viewport_resize()
	
func _set_key() -> void:
	if not Options.opts.uncert_paint:
		key_label.text = "Circle Color Key"
	else:
		key_label.text = "Likelihood Key"
	var img = Image.create(100, 1, false, Image.FORMAT_RGBA8)
	for i in range(100):
		var level: float = (i+1)/100.0
		if Options.opts.uncert_paint:
			if level < 0.25:
				img.set_pixel(i, 0, Color(0, 0, level*4.0, 1.0))
			elif (level < 0.50):
				img.set_pixel(i, 0, Color((level-0.25)*2.0, 0.0, 1.0, 1.0))
			elif level < 0.75:
				img.set_pixel(i, 0, Color(0.5 + (level - 0.5) * 2.0, (level - 0.5) * 4.0, 1.0 - (level - 0.5) * 4.0, 1.0))
			else:
				img.set_pixel(i, 0, Color(1.0, 1.0, (level - 0.75) * 4.0, 1.0))
		else:
			if level < 0.75:
				img.set_pixel(i, 0, Color(level*1.33, 0, 0, 1.0))
			else:
				img.set_pixel(i, 0, Color(1.0, (level - 0.75)*2.0, (level - 0.75)*2.0, 1.0))
	tex_control.texture = ImageTexture.create_from_image(img)
	if Options.opts.uncert_rank:
		high_label.text = "high rank"
		low_label.text = "low rank"
		label_hbox.size.x = 206
	if Options.opts.uncert_sliders:
		high_label.text = "high\nprobability"
		low_label.text = "low\nprobability"
		label_hbox.size.x = 206

func _on_viewport_resize():
	pass
	'''
	var vp = get_viewport()
	if vp != null:
		var vp_size = Vector2(vp.size)
		position.x = vp_size.x - 260
		position.y = vp_size.y - 140
	'''
