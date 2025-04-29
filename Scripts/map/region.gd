extends Area

class_name Region

@export var label: MeshInstance3D

func _ready() -> void:
	'''Set label font and color'''
	label.set_font_size(280)
	label.set_font_outline(24, Color(0, 0, 0, 1))
	label.set_font_color(Color(1.0, 0.247, 0.267, 1.0))
	label.set_render_priority(1)
	
	SignalBus.activate_uncert_mode.connect(_activate_uncert_mode)
	SignalBus.activate_nav_mesh_mode.connect(_activate_nav_mesh_mode)
	SignalBus.activate_build_mode.connect(_deactivate_uncert_mode)
	SignalBus.activate_param_mode.connect(_deactivate_uncert_mode)
	self._is_surface = false
	self._initialize()
	
func _activate_uncert_mode() -> void:
	self.mode = self.AREA_MODE.UNCERT
	area_mesh.material_override = self._shader_mat
	area_mesh.material_override.set_shader_parameter("sampler", self.tex)
	#area_mesh.material_override = StandardMaterial3D.new()####self._shader_mat
	#area_mesh.material_override.albedo_texture = ImageTexture.new()#### get rid of this
	#area_mesh.material_override.albedo_texture.set_image(Image.create(ceil(dim.x/pix_size), ceil(dim.y/pix_size), false, Image.FORMAT_RGBA8))####area_mesh.material_override.set_shader_parameter("sampler", self.tex)
	#area_mesh.material_override.texture_filter = 0
	'''
	area_mesh.transparency = 0.02
	var material_dup: Material = area_mesh.material_override.duplicate()
	material_dup.albedo_color = Color(0.02, 0.02, 0.15, 1.0)
	area_mesh.material_override = material_dup
	'''
	var label_col: Color = Color(0.3, 0.3, 0.5, 1.0)
	label_node.set_font_color(label_col)
	for node in nodes_node.get_children():
		node.get_material().albedo_color = Color(0.3, 0.3, 0.5, 1.0)
	hide_waypoints()
		
func _activate_nav_mesh_mode() -> void:
	mode = AREA_MODE.NAVMESH
	area_mesh.material_override = _nav_mesh_mat
	change_color(Color(0.1, 0.1, 0.1, 1.0))
	show_waypoints()
		
func _deactivate_uncert_mode() -> void:
	mode = AREA_MODE.NORMAL
	area_mesh.material_override = _normal_mat
	change_color(self.col)
	hide_waypoints()
	
func set_color(col: Color) -> void:
	self.col = col
	change_color(self.col)
		
func change_color(col: Color) -> void:
	if area_mesh.material_override is StandardMaterial3D:
		area_mesh.material_override.albedo_color = col
		var label_col: Color = Color(
			col.r*0.5,
			col.g*0.5,
			col.b*0.5,
			1.0
		)
		label_node.set_font_color(label_col)
		for node in nodes_node.get_children():
			node.get_material().albedo_color = col

func _on_area_3d_input_event(_camera, event, _position, normal, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		pass
		
func _on_mesh_static_body_input_event(camera, event, position, normal, shape_idx):
	self._on_area_input_event(camera, event, position, normal, shape_idx)
			
func _on_mesh_static_body_mouse_entered():
	if self.mode == self.AREA_MODE.UNCERT and self.paint_mode != self.PAINT_MODE.SURFACE:
		if Input.is_mouse_button_pressed(1):
			self._drawing = true		

func _on_mesh_static_body_mouse_exited():
	if self.mode == self.AREA_MODE.UNCERT:
		self._end_draw()

func set_default_properties() -> void:
	# caregiving-specific properties
	if Options.opts.domain == "caregiving":
		# (currently none for region)
		pass

	# food assemnbly-specific properties
	if Options.opts.domain == "food_assembly":
		# (currently none for region)
		pass

func delete() -> void:
	SignalBus.delete_region.emit(self)
