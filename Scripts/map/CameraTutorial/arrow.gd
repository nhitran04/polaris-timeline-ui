extends TextureRect

var img: Image
var delt: float

# instance variables
var _pointed_at_arrows: bool
var _pointed_at_zoom_slider: bool
var _pointed_at_tilt_slider: bool
var _pointed_at_compass: bool

# Called when the node enters the scene tree for the first time.
func _ready():
	var img_texture_path := "res://Assets/img/tutorial_arrow.png"
	var img_texture: CompressedTexture2D = load(img_texture_path)
	var img: Image = img_texture.get_image()
	#img = Image.load_from_file("res://Assets/img/tutorial_arrow.png")
	img.resize(200, 60)
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	texture = tex
	delt = 0
	
	SignalBus.arrow_point_at_arrows.connect(_point_at_arrows)
	SignalBus.arrow_point_at_zoom_slider.connect(_point_at_zoom_slider)
	SignalBus.arrow_point_at_tilt_slider.connect(_point_at_tilt_slider)
	SignalBus.arrow_point_at_compass.connect(_point_at_compass)
	SignalBus.hide_arrow.connect(_hide)
	_pointed_at_arrows = false
	_pointed_at_zoom_slider = false
	_pointed_at_tilt_slider = false
	_pointed_at_compass = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	delt += delta*8
	size.x = 200 + sin(delt)*10
	size.y = 100 + sin(delt)*4

func _point_at_arrows() -> void:
	position.x = 200
	position.y = 80
	rotation_degrees = 0
	
func _point_at_zoom_slider() -> void:
	position.x = 200
	position.y = 200
	rotation_degrees = -41.6
	
func _point_at_tilt_slider() -> void:
	position.x = -10
	position.y = 0
	rotation_degrees = -41.6
	
func _point_at_compass() -> void:
	position.x = 280
	position.y = 120
	rotation_degrees = 41.6
	
func _hide() -> void:
	visible = false
