extends Area

class_name Surface

@onready var faces := $faces as Node3D

@export var label: MeshInstance3D

func _ready() -> void:
	'''Set label font and color'''
	label.set_font_size(280)
	label.set_font_outline(48, Color(0, 0, 0, 1))
	label.set_font_color(Color(0.68, 0.83, 0.86, 1.0))
	label.set_render_priority(3)
	SignalBus.activate_uncert_mode.connect(_activate_uncert_mode)
	SignalBus.activate_nav_mesh_mode.connect(_activate_nav_mesh_mode)
	SignalBus.activate_build_mode.connect(_deactivate_uncert_mode)
	SignalBus.activate_param_mode.connect(_deactivate_uncert_mode)
	self._is_surface = true
	self._initialize()
			
func add_surface_legs() -> void:
	
	# add the edges
	for vert in self.bounding_box_markers:
		var v1 = vert.position
		var v2 = vert.position
		v1.z = 0.0
		var line = CSGCylinder3D.new()
		line.transform.origin.z = -1.0
		line.height = v1.distance_to(v2)
		line.radius = 0.02
		line.rotate_x(deg_to_rad(90))
		var material = StandardMaterial3D.new()
		line.set_material(material)
		line.material.albedo_color = Color.BLACK
		vert.add_child(line)
		
	# add the faces
	for i in range(len(self.bounding_box_markers)):
		var vert1: Vector3
		var vert4: Vector3
		if i < len(self.bounding_box_markers) - 1:
			vert1 = self.bounding_box_markers[i].position
			vert4 = self.bounding_box_markers[i+1].position
		else:
			vert1 = self.bounding_box_markers[i].position
			vert4 = self.bounding_box_markers[0].position
		var vert2: Vector3 = Vector3(vert1.x, vert1.y, 0)
		var vert3: Vector3 = Vector3(vert4.x, vert4.y, 0)
		var face: MeshInstance3D = MeshInstance3D.new()
		var arr_mesh = ArrayMesh.new()
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		var pva: PackedVector3Array = [vert1, vert2, vert3, vert4]
		var polygon: PackedVector3Array = [vert3, vert2, vert1, vert4, vert3, vert1]
		arrays[Mesh.ARRAY_VERTEX] = polygon
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var mat: StandardMaterial3D = self.area_mesh.material_override.duplicate()
		face.material_override = mat
		face.mesh = arr_mesh
		face.name = "face"
		# create the static body and collisionshape
		var sb: StaticBody3D = StaticBody3D.new()
		var coll: CollisionShape3D = CollisionShape3D.new()
		var collision_poly: ConcavePolygonShape3D = ConcavePolygonShape3D.new()
		collision_poly.set_faces(polygon)
		coll.shape = collision_poly
		sb.add_child(coll)
		sb.add_child(face)
		faces.add_child(sb)

func _on_area_3d_input_event(camera, event, position, normal, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		pass
		
func _on_mesh_static_body_input_event(camera, event, position, normal, shape_idx):
	self._on_area_input_event(camera, event, position, normal, shape_idx)
			
func _on_mesh_static_body_mouse_entered():
	if Input.is_mouse_button_pressed(1):
		self._drawing = true		

func _on_mesh_static_body_mouse_exited():
	self._end_draw()

func _input(event: InputEvent):
	if event.is_action_released("click"):
		SignalBus.deactivate_paint_mode.emit()

func set_default_properties() -> void:
	# caregiving-specific properties
	if Options.opts.domain == "caregiving":
		self.properties["is_container"] = false

	# food assembly-specific properties
	if Options.opts.domain == "food_assembly":
		pass
		
func _activate_uncert_mode() -> void:
	mode = AREA_MODE.UNCERT
	area_mesh.material_override = _shader_mat
	area_mesh.material_override.set_shader_parameter("sampler", tex)
	var label_col: Color = Color("#a5a7d7")
	label_node.set_font_color(label_col)
	for node in nodes_node.get_children():
		node.set_material(node.get_material().duplicate())
		node.get_material().albedo_color = Color(0.3, 0.3, 0.5, 1.0)
	for face_nodes in faces.get_children():
		var face = face_nodes.get_node("face")
		face.material_override = face.material_override.duplicate()
		face.material_override.albedo_color = Color(0.3, 0.3, 0.5, 1.0)
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
			col.r + (1.0 - col.r)*0.75,
			col.g + (1.0 - col.g)*0.75,
			col.b + (1.0 - col.b)*0.75,
			1.0
		)
		label_node.set_font_color(label_col)
		for node in nodes_node.get_children():
			node.get_material().albedo_color = col
		for face in faces.get_children():
			face.get_node("face").material_override.albedo_color = col

func delete() -> void:
	SignalBus.delete_surface.emit(self)
