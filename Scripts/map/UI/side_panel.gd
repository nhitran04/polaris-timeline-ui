extends Panel

@onready var toggle_drawing_board := $Buttons/ToggleDrawingBoard/Button as Button
@onready var toggle_play := $Buttons/TogglePlay/Button as Button
@onready var toggle_map := $Buttons/ToggleMap/Button as Button
@onready var expansion_panel := $Buttons/ExpansionPanel as Panel
@onready var toggle_build_mode := $Buttons/ExpansionPanel/MapOptions/Build/Button as Button
@onready var toggle_param_mode := $Buttons/ExpansionPanel/MapOptions/Parameterize/Button as Button
@onready var toggle_nav_mesh_mode := $Buttons/ExpansionPanel/MapOptions/MakeNavMesh/Button as Button
@onready var toggle_uncertainty_mode := $Buttons/ExpansionPanel/MapOptions/SetUncertainty/Button as Button
@onready var save_map := $Buttons/ExpansionPanel/MapOptions/Save/Button as Button
@onready var load_map := $Buttons/ExpansionPanel/MapOptions/Load/Button as Button

var drawing_board_tex: ImageTexture
var drawing_board_tex_toggled: ImageTexture
var play_tex: ImageTexture
var play_tex_toggled: ImageTexture
var map_tex: ImageTexture
var map_tex_toggled: ImageTexture
var build_tex: ImageTexture
var build_tex_toggled: ImageTexture
var param_tex: ImageTexture
var param_tex_toggled: ImageTexture
var nav_mesh_tex: ImageTexture
var nav_mesh_tex_toggled: ImageTexture
var uncertainty_tex: ImageTexture
var uncertainty_tex_toggled: ImageTexture 

var in_uncert_mode: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	
	get_viewport().connect("size_changed", _on_viewport_resize)
	_on_viewport_resize()

	toggle_drawing_board.pressed.connect(_toggle_drawing_board)
	toggle_play.pressed.connect(_toggle_play)
	toggle_map.pressed.connect(_toggle_map)
	toggle_build_mode.pressed.connect(_toggle_map_build_mode)
	toggle_param_mode.pressed.connect(_toggle_map_param_mode)
	toggle_nav_mesh_mode.pressed.connect(_toggle_map_nav_mesh_mode)
	toggle_uncertainty_mode.pressed.connect(_toggle_map_uncertainty_mode)
	save_map.pressed.connect(_on_save_map)
	load_map.pressed.connect(_on_load_map)
	
	var image: Image
	var img_texture_path := "res://Assets/img/drawing_board_icon-01.png"
	var img_texture: CompressedTexture2D = load(img_texture_path)
	image = img_texture.get_image()
	drawing_board_tex = ImageTexture.create_from_image(image)
	img_texture_path = "res://Assets/img/drawing_board_icon_toggled-01.png"
	img_texture = load(img_texture_path)
	image = img_texture.get_image()
	drawing_board_tex_toggled = ImageTexture.create_from_image(image)
	img_texture_path = "res://Assets/img/play_icon-01.png"
	img_texture = load(img_texture_path)
	image = img_texture.get_image()
	play_tex = ImageTexture.create_from_image(image)
	img_texture_path = "res://Assets/img/play_icon_toggled-01.png"
	img_texture = load(img_texture_path)
	image = img_texture.get_image()
	play_tex_toggled = ImageTexture.create_from_image(image)
	img_texture_path = "res://Assets/img/map_icon-01.png"
	img_texture = load(img_texture_path)
	image = img_texture.get_image()
	map_tex = ImageTexture.create_from_image(image)
	img_texture_path = "res://Assets/img/map_icon_toggled-01.png"
	img_texture = load(img_texture_path)
	image = img_texture.get_image()
	map_tex_toggled = ImageTexture.create_from_image(image)
	img_texture_path = "res://Assets/img/param_icon-01.png"
	img_texture = load(img_texture_path)
	image = img_texture.get_image()
	param_tex = ImageTexture.create_from_image(image)
	img_texture_path = "res://Assets/img/param_icon_toggled-01.png"
	img_texture = load(img_texture_path)
	image = img_texture.get_image()
	param_tex_toggled = ImageTexture.create_from_image(image)
	img_texture_path = "res://Assets/img/build_icon-01.png"
	img_texture = load(img_texture_path)
	image = img_texture.get_image()
	build_tex = ImageTexture.create_from_image(image)
	img_texture_path = "res://Assets/img/build_icon_toggled-01.png"
	img_texture = load(img_texture_path)
	image = img_texture.get_image()
	build_tex_toggled = ImageTexture.create_from_image(image)
	img_texture_path = "res://Assets/img/nav_mesh_icon-01.png"
	img_texture = load(img_texture_path)
	image = img_texture.get_image()
	nav_mesh_tex = ImageTexture.create_from_image(image)
	img_texture_path = "res://Assets/img/nav_mesh_icon_toggled-01.png"
	img_texture = load(img_texture_path)
	image = img_texture.get_image()
	nav_mesh_tex_toggled = ImageTexture.create_from_image(image)
	img_texture_path = "res://Assets/img/uncertainty_icon-01.png"
	img_texture = load(img_texture_path)
	image = img_texture.get_image()
	uncertainty_tex = ImageTexture.create_from_image(image)
	img_texture_path = "res://Assets/img/uncertainty_icon_toggled-01.png"
	img_texture = load(img_texture_path)
	image = img_texture.get_image()
	uncertainty_tex_toggled = ImageTexture.create_from_image(image)
	
	SignalBus.toggle_drawing_board.connect(_toggle_drawing_board)
	SignalBus.toggle_play.connect(_toggle_play)
	SignalBus.toggle_map.connect(_toggle_map)
	SignalBus.toggle_map_build_mode.connect(_toggle_map_build_mode)
	SignalBus.toggle_map_param_mode.connect(_toggle_map_param_mode)
	SignalBus.toggle_map_uncertainty_mode.connect(_toggle_map_uncertainty_mode)
	SignalBus.on_save_map.connect(_on_save_map)
	SignalBus.on_load_map.connect(_on_load_map)
	SignalBus.hide_control_panel.connect(hide)
	
func _toggle_drawing_board() -> void:
	_toggle_map_build_mode()
	toggle_play.button_pressed = false
	toggle_map.button_pressed = false
	expansion_panel.visible = false
	toggle_drawing_board.icon = drawing_board_tex_toggled
	toggle_play.icon = play_tex
	toggle_map.icon = map_tex
	SignalBus.enter_drawing_board.emit()
	SignalBus.exit_map.emit()
	Logger.log_event("control_panel_toggle_drawing_board", {})

func _toggle_play() -> void:
	toggle_drawing_board.button_pressed = false
	toggle_map.button_pressed = false
	expansion_panel.visible = false
	toggle_drawing_board.icon = drawing_board_tex
	toggle_play.icon = play_tex_toggled
	toggle_map.icon = map_tex					
	SignalBus.play.emit()
	Logger.log_event("control_panel_toggle_play", {})
								
func _toggle_map() -> void:
	toggle_drawing_board.button_pressed = false
	toggle_play.button_pressed = false
	expansion_panel.visible = true
	toggle_drawing_board.icon = drawing_board_tex
	toggle_play.icon = play_tex
	toggle_map.icon = map_tex_toggled
	SignalBus.exit_drawing_board.emit()
	SignalBus.enter_map.emit()
	Logger.log_event("control_panel_toggle_map", {})
								
func _toggle_map_build_mode() -> void:
	toggle_param_mode.button_pressed = false
	toggle_nav_mesh_mode.button_pressed = false
	if in_uncert_mode:
		SignalBus.deactivate_uncert_mode.emit()
	toggle_uncertainty_mode.button_pressed = false
	toggle_build_mode.icon = build_tex_toggled
	toggle_param_mode.icon = param_tex
	toggle_nav_mesh_mode.icon = nav_mesh_tex
	toggle_uncertainty_mode.icon = uncertainty_tex
	SignalBus.activate_build_mode.emit()
	Logger.log_event("control_panel_toggle_map_build_mode", {})
	in_uncert_mode = false

func _toggle_map_param_mode() -> void:
	toggle_build_mode.button_pressed = false
	toggle_nav_mesh_mode.button_pressed = false
	if in_uncert_mode:
		SignalBus.deactivate_uncert_mode.emit()
	toggle_uncertainty_mode.button_pressed = false
	toggle_build_mode.icon = build_tex
	toggle_param_mode.icon = param_tex_toggled
	toggle_nav_mesh_mode.icon = nav_mesh_tex
	toggle_uncertainty_mode.icon = uncertainty_tex
	SignalBus.activate_param_mode.emit()
	Logger.log_event("control_panel_toggle_map_param_mode", {})
	in_uncert_mode = false
	
func _toggle_map_nav_mesh_mode() -> void:
	toggle_build_mode.button_pressed = false
	toggle_param_mode.button_pressed = false
	if in_uncert_mode:
		SignalBus.deactivate_uncert_mode.emit()
	toggle_uncertainty_mode.button_pressed = false
	toggle_build_mode.icon = build_tex
	toggle_param_mode.icon = param_tex
	toggle_nav_mesh_mode.icon = nav_mesh_tex_toggled
	toggle_uncertainty_mode.icon = uncertainty_tex
	SignalBus.activate_nav_mesh_mode.emit()
	Logger.log_event("control_panel_toggle_map_nav_mesh_mode", {})
	in_uncert_mode = false
	
func _toggle_map_uncertainty_mode() -> void:
	toggle_build_mode.button_pressed = false
	toggle_nav_mesh_mode.button_pressed = false
	toggle_param_mode.button_pressed = false
	toggle_build_mode.icon = build_tex
	toggle_param_mode.icon = param_tex
	toggle_nav_mesh_mode.icon = nav_mesh_tex
	toggle_uncertainty_mode.icon = uncertainty_tex_toggled
	SignalBus.activate_uncert_mode.emit()
	Logger.log_event("control_panel_toggle_map_uncertainty_mode", {})
	in_uncert_mode = true
	
func _on_save_map() -> void:
	SignalBus.save_map.emit()
	Logger.log_event("control_panel_save", {})
	
func _on_load_map() -> void:
	SignalBus.load_map.emit()
	Logger.log_event("control_panel_load", {})

func _on_viewport_resize() -> void:
	var vp = get_viewport()
	if vp != null:
		var vp_size = Vector2(get_viewport().size)
		#position.x = vp_size.x - size.x
		#position.y = 100
		size.y = vp_size.y
