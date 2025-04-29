'''
License: 
Others' Code used/adapted/modified:
	 1. URL(s): https://docs.godotengine.org/en/stable/classes/class_arraymesh.html
				https://github.com/godotengine/godot-docs/blob/master/classes/class_arraymesh.rst
		License: https://github.com/godotengine/godot-docs/blob/master/LICENSE.txt
				 (CC-BY-3.0 License)
		SHA (if found on git): 3d441150b13961da951e7c1a1aae812d1df3705b
'''

extends Node3D

class_name Area

var region := load("res://Scenes/map/region.tscn")
var surface := load("res://Scenes/map/surface.tscn")
var node := load("res://Scenes/map/node.tscn")
var waypoint := load("res://Scenes/map/nav_mesh/waypoint.tscn")
var uncert_label_scene := load("res://Scenes/map/uncert_item_selection/uncert_label.tscn")

# shader
#@onready var shad = preload("res://Scenes/demos/world.gdshader")
@onready var shad_monochrome = preload("res://Resources/shaders/uncert_monochrome.gdshader")
@onready var shad_point = preload("res://Resources/shaders/uncert_area.gdshader")
#@onready var shad_debug = preload("res://Resources/shaders/debug.gdshader")

# children in the tree
@onready var label_node := $label as MeshInstance3D
@onready var nodes_node := $nodes as Node3D
@onready var area_mesh := $MeshStaticBody/mesh as MeshInstance3D
@onready var waypoints := $waypoints

# MODE
enum AREA_MODE {NORMAL,
				NAVMESH,
				UNCERT}
var mode := AREA_MODE.NORMAL
enum UNCERT_MODE {PAINT,
				  ERASE}
var uncert_mode: UNCERT_MODE
enum PAINT_MODE {NONE,
				 REGION,
				 SURFACE}
var paint_mode: PAINT_MODE

# instance variables
var bounding_box_raw: PackedVector3Array
var bounding_box: PackedVector3Array
var bounding_box_markers: Array[AreaNode]
var root_entity: WorldEntity
var col: Color
var _normal_mat: StandardMaterial3D
var _nav_mesh_mat: StandardMaterial3D
var _shader_mat: ShaderMaterial
var _shader_mats: Dictionary
var _shader_texs: Dictionary
var _curr_item: String
var tex: ImageTexture
var curr_rot: float
var curr_tilt: float
var pix_size: float
var bounds: Vector4
var dim: Vector2
var center_cell: Vector2
var _drawing: bool
var _draw_coords: Vector3
var CHUNK_SIZE = 2400
var draw_areas: Array[Dictionary]
var vec2_bb: Array[Vector2]

# for drawing
var _draw_delta: float
var _interaction_disabled: bool
var _is_surface: bool

# for bookkeeping
var unique_label: String

# uncert label dictionary uid -> label object
var uncert_label_dict: Dictionary
var dragged_uncert_point: int

# for uncert rank or sliders
var _rank_or_slider_pressed: bool

# cache to speed up computation
var point_in_polygon_dict: Dictionary
var point_on_boundary_dict: Dictionary

# properties
var properties := {}

func _ready() -> void:
	draw_areas = []
	# SignalBus.terminate_area_draw.connect(_terminate_draw)
	# SignalBus.select_uncert_item.connect(_select_uncert_item)
	
func _initialize() -> void:
	draw_areas = []
	self._shader_mats = {}
	self._shader_texs = {}
	
	SignalBus.rotate_map.connect(self._rotate_map)
	SignalBus.tilt_map.connect(self._tilt_map)
	SignalBus.terminate_area_draw.connect(self._terminate_draw)
	SignalBus.select_uncert_item.connect(self.select_uncert_item)
	SignalBus.enter_uncert_paint_mode.connect(self._uncert_paint_mode)
	SignalBus.enter_uncert_erase_mode.connect(self._uncert_erase_mode)
	SignalBus.activate_region_paint_mode.connect(self._activate_region_paint_mode)
	SignalBus.activate_surface_paint_mode.connect(self._activate_surface_paint_mode)
	SignalBus.deactivate_paint_mode.connect(self._deactivate_paint_mode)
	SignalBus.view_control_activated.connect(_disable_interaction)
	self.dragged_uncert_point = -1
	self._rank_or_slider_pressed = false
	_interaction_disabled = false
	point_in_polygon_dict = {}
	point_on_boundary_dict = {}
	pix_size = 0.032
	if Options.opts.uncert_paint:
		pix_size = 0.16
	_draw_delta = 0.0
	unique_label = ""
	
func _disable_interaction(val: bool):
	_interaction_disabled = val
	
func _activate_region_paint_mode() -> void:
	paint_mode = PAINT_MODE.REGION

func _activate_surface_paint_mode() -> void:
	paint_mode = PAINT_MODE.SURFACE
	
func _deactivate_paint_mode() -> void:
	paint_mode = PAINT_MODE.NONE 

func _process(delta) -> void:
	if _drawing:
		_draw_delta += delta
		while _draw_delta > 0.015:
			_draw_delta -= 0.015
			_draw()
	
func add_root(ent: WorldEntity) -> void:
	root_entity = ent
	
func select_uncert_item(str: String) -> void:
	_curr_item = str
	self.dragged_uncert_point = -1
	if str not in _shader_mats:
		var img = Image.create(ceil(dim.x/pix_size), ceil(dim.y/pix_size), false, Image.FORMAT_RGBA8)
	
		# link center to img cell
		var center = calculate_bounding_box_center()
		center.x -= bounds.y
		center.y -= bounds.w
		center /= pix_size
		center_cell = Vector2(center.x, center.y)####Vector2(round(center.x), round(center.y))
		
		var _new_shader_mat = ShaderMaterial.new()
		if Options.opts.uncert_paint:
			img.fill(Color.TRANSPARENT)
			_shader_texs[str] = ImageTexture.create_from_image(img)
			_new_shader_mat.shader = shad_monochrome
		elif Options.opts.uncert_sliders:
			img.fill(Color(0, 0, 0, 0.8))
			_shader_texs[str] = ImageTexture.create_from_image(img)
			_new_shader_mat.shader = shad_point
		else:
			img.fill(Color(0, 0, 0, 0.8))
			_shader_texs[str] = ImageTexture.create_from_image(img)
			_new_shader_mat.shader = shad_point
		_shader_mats[str] = _new_shader_mat
	_shader_mat = _shader_mats[str]
	tex = _shader_texs[str]
	area_mesh.material_override = _shader_mat
	area_mesh.material_override.set_shader_parameter("sampler", tex)
	
func add_area(bounding_box: PackedVector3Array):
	# adding an extra point near the first vertex ensures
	# that the bounding box gets "closed"
	var deviation: Vector3 = bounding_box[0]
	deviation.x += 0.01
	bounding_box.append(deviation)
	
	# refine AKA convert to polygon
	self.bounding_box_raw = bounding_box
	self.bounding_box = _refine(bounding_box)
	bounds = _add_mesh()  # dim is right, left, bottom, top
	dim = Vector2(bounds.x - bounds.y, bounds.z - bounds.w)
	_add_outline()
	
	# set materials
	area_mesh.material_override = area_mesh.material_override.duplicate()
	_normal_mat = area_mesh.material_override
	_nav_mesh_mat = area_mesh.material_override.duplicate()
		
	# calculate nodes on vertices
	for vert in self.bounding_box:
		var node = node.instantiate()
		node.set_area(self)
		node.position = vert
		node.position.z = self.get_node("MeshStaticBody").position.z
		node.set_material(_normal_mat)
		node.position_changed.connect(_adjust_node_position)
		bounding_box_markers.append(node)
		get_node("nodes").add_child(node)
		
	# add a shader
	# make texture pixels constant size
	var img = Image.create(ceil(dim.x/pix_size), ceil(dim.y/pix_size), false, Image.FORMAT_RGBA8)
	
	# link center to img cell
	var center = calculate_bounding_box_center()
	center.x -= bounds.y
	center.y -= bounds.w
	center /= pix_size
	center_cell = Vector2(center.x, center.y)####Vector2(round(center.x), round(center.y))
	
	img.fill(Color.TRANSPARENT)
	tex = ImageTexture.create_from_image(img)
	
	_shader_mat = ShaderMaterial.new()
	if Options.opts.uncert_paint:
		_shader_mat.shader = shad_monochrome
	elif Options.opts.uncert_sliders:
		_shader_mat.shader = shad_point
	#area_mesh.material_override = mat
	#area_mesh.material_override.set_shader_parameter("sampler", tex)
	
	vec2_bb = []
	for node in self.nodes_node.get_children():
		vec2_bb.append(global_coord_to_pixel_coord(node.global_position))
		
func set_unique_label(label: String):
	unique_label = label

func load_uncert_save_data(data: Dictionary):		
	# loading save data
	if Options.opts.load_uncert:
		var temp_item = _curr_item
		for item in data:
			select_uncert_item(item)
			var img = tex.get_image()
			if Options.opts.uncert_paint:
				var area_data: Dictionary = data[item][unique_label]
				var dim: Vector2 = Vector2(area_data["dimensions"][0], area_data["dimensions"][1]) 
				var values: Array = area_data["values"]
				for i in range(dim.x):
					for j in range(dim.y):
						var val: float = values[(i*dim.y) + j]
						img.set_pixel(i,j,Color(0, 0, 0, val))
				_shader_texs[_curr_item] = ImageTexture.create_from_image(img)
				tex = _shader_texs[_curr_item]
				area_mesh.material_override.set_shader_parameter("sampler", tex)
		select_uncert_item(temp_item)
		
func _adjust_node_position(global_pos: Vector3, node: Node3D) -> void:
	# set node global position
	node.global_position.x = global_pos.x
	node.global_position.y = global_pos.y
	_recalculate_area()
	
func delete_node(node: AreaNode) -> void:
	bounding_box_markers.erase(node)
	_recalculate_area()
	get_node("nodes").remove_child(node)
	node.queue_free()
	
func _recalculate_area() -> void:
	# reset bounding boxes
	self.bounding_box_raw.clear()
	self.bounding_box.clear()
	for marker in self.bounding_box_markers:
		var pos = marker.position
		pos.z = 0.0
		self.bounding_box_raw.append(pos)
		self.bounding_box.append(pos)
	
	# remove lines
	for child in get_node("outline").get_children():
		remove_child(child)
		child.queue_free()
			
	_add_mesh()
	_add_outline()
	
	SignalBus.reset_predicates.emit()
			
func get_color() -> Color:
	return area_mesh.material_override.albedo_color
	
func get_label() -> String:
	return label_node.get_node("SubViewport").get_node("TextEdit").text
	
func set_label(label: String) -> void:
	label_node.get_node("SubViewport").get_node("TextEdit").text = label
	
func set_label_position(pos: Vector2) -> void:
	label_node.set_pos(pos)
	
func get_abbrv() -> String:
	var s: String = get_label()[0]
	var can_add_char: bool = false
	for char in get_label().substr(1, len(get_label())):
		if can_add_char:
			s += char
			can_add_char = false
		if char == "_":
			can_add_char = true
	return s
	
func get_properties() -> Dictionary:
	return properties

func set_properties(new_props: Dictionary) -> void:
	properties = new_props
	
func _activate_uncert_mode() -> void:
	mode = AREA_MODE.UNCERT
	area_mesh.material_override = _shader_mat
	area_mesh.material_override.set_shader_parameter("sampler", tex)
	var label_col: Color = Color(0.3, 0.3, 0.5, 1.0)
	label_node.set_font_color(label_col)
	for node in nodes_node.get_children():
		node.set_material(node.get_material().duplicate())
		node.get_material().albedo_color = Color(0.3, 0.3, 0.5, 1.0)
	
func calculate_bounding_box_center() -> Vector3:
	var sum_x = 0
	var sum_y = 0
	var sum_z = 0
	for vect in self.bounding_box:
		sum_x += vect.x
		sum_y += vect.y
		sum_z += vect.z
	return Vector3(sum_x / len(self.bounding_box),
				   sum_y / len(self.bounding_box),
				   sum_z / len(self.bounding_box))
				
func calculate_global_center() -> Vector3:
	var sum_x = 0
	var sum_y = 0
	var sum_z = 0
	for node in nodes_node.get_children():
		sum_x += node.global_position.x
		sum_y += node.global_position.y
		sum_z += node.global_position.z
	return Vector3(sum_x / len(nodes_node.get_children()),
				   sum_y / len(nodes_node.get_children()),
				   sum_z / len(nodes_node.get_children()))
				
func _refine(bounding_box: PackedVector3Array):
	var refined_bb: PackedVector3Array = []
	var edges: Array[PackedVector3Array] = []
	_refine_helper(edges, bounding_box.duplicate())
	for edge in edges:
		refined_bb.append(edge[0])
	return refined_bb

func _refine_helper(edges: Array[PackedVector3Array], curr_edge):
	
	# try to split at point of greatest deviation from the line
	var gdist = -1
	var idx = -1
	var start = curr_edge[0]
	var end = curr_edge[-1]
	for i in range(len(curr_edge) - 1):
		var dist = _distance_from_line(start, end, curr_edge[i])
		if dist > gdist:
			idx = i
			gdist = dist
	if gdist > 0.25:
		var edge1: PackedVector3Array = []
		var edge2: PackedVector3Array = []
		for i in range(idx):
			edge1.append(curr_edge[i])
		edge1.append(curr_edge[idx])
		for i in range(idx, len(curr_edge)):
			edge2.append(curr_edge[i])
		_refine_helper(edges, edge1)
		_refine_helper(edges, edge2)
	else:
		# edge is almost linear. Add it!
		edges.append(curr_edge)

func _distance_from_line(l1: Vector3, l2: Vector3, pt: Vector3):
	var num_left = (l2.x - l1.x) * (l1.y - pt.y)
	var num_right = (l1.x - pt.x) * (l2.y - l1.y)
	var den_sq = (l2.x - l1.x)**2 + (l2.y - l1.y)**2
	return abs(num_left - num_right)/sqrt(den_sq)
	
func _add_mesh() -> Vector4:
	var center = calculate_bounding_box_center()
	self.get_node("label").position.x = center.x
	self.get_node("label").position.y = center.y
	''' Code used/adapted/modified from 1 '''
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	var polygon = _tesselate(self.bounding_box)
	arrays[Mesh.ARRAY_VERTEX] = polygon
	# find the smallest rectangle that can encapsulate the polygon
	var top: float = self.bounding_box[0].y
	var bottom: float = self.bounding_box[0].y
	var left: float = self.bounding_box[0].x
	var right: float = self.bounding_box[0].x
	
	for vert in self.bounding_box:
		if vert.x < left:
			left = vert.x
		if vert.x > right:
			right = vert.x
		if vert.y < top:
			top = vert.y
		if vert.y > bottom:
			bottom = vert.y	
	var dim = Vector4(right, left, bottom, top)
	
	var mesh_uv: PackedVector2Array = []
	for vert in polygon:
		var x: float = (vert.x - left)/(right - left)
		var y: float = (vert.y - top)/(bottom - top)
		mesh_uv.append(Vector2(x, y))
	arrays[Mesh.ARRAY_TEX_UV] = mesh_uv
	
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	self.get_node("MeshStaticBody/mesh").mesh = arr_mesh
	var collision_poly: ConcavePolygonShape3D = ConcavePolygonShape3D.new()
	collision_poly.set_faces(polygon)
	self.get_node("MeshStaticBody/CollisionShape3D").shape = collision_poly
	'''End code used/adapted/modified from 1'''
	return dim

func _tesselate(verts: PackedVector3Array) -> PackedVector3Array:
	var to_return = PackedVector3Array()
	var triangles: Array[Array] = []
	var edges: Array[Array] = []
	var start_edge = [verts[len(verts) - 1], verts[0]]
	edges.append(start_edge)
	for i in len(verts) - 1:
		var edge = [verts[i], verts[i+1]]
		edges.append(edge)
	_tesselate_helper(edges, triangles, verts)
	for tri in triangles:
		for vert in tri:
			to_return.append(vert)
	return to_return
	
func _tesselate_helper(edges: Array, triangles: Array, verts: PackedVector3Array) -> void:
	# TODO: add error cases (e.g., <3 edges left)
	# base case: there are 3 edges left
	if len(edges) == 3:
		var triangle = [edges[0][0], edges[1][0], edges[2][0]]
		if not _is_clockwise(triangle):
			triangle.reverse()
		triangles.append(triangle)
	else:
		var polygon: Array
		for i in len(edges):
			
			# TODO: fix this quick hack
			if i == len(edges) - 1:
				print("Error: could not complete tesselation")
				break
			# without the above if statement, the code will often fail
			
			# existing edges
			var edge1 = edges[i]
			var edge2 = edges[i+1]
			
			# candidate new edge
			var edge3 = [edge2[1], edge1[0]]
			
			# do tests
			var edge3midpoint = Vector2(edge3[0].x + (edge3[1].x - edge3[0].x)/2.0,
										edge3[0].y + (edge3[1].y - edge3[0].y)/2.0)
			var edgesVect2: Array[Vector2] = []
			for j in len(edges):
				edgesVect2.append(Vector2(edges[j][0].x, edges[j][0].y))
			
			if not _is_point_in_polygon(edge3midpoint, edgesVect2):
				polygon.append(edge1)
				continue
			
			# break and recurse
			var triangle = [edge1, edge2, edge3]
			var edge3reversed = [edge3[1], edge3[0]]
			polygon.append(edge3reversed)
			var j = i + 2
			while j < len(edges):
				polygon.append(edges[j])
				j += 1
				
			_tesselate_helper(triangle, triangles, verts)
			_tesselate_helper(polygon, triangles, verts)
			break

func _is_clockwise(verts: Array) -> bool:
	var sum = (verts[0].x - verts[len(verts) - 1].x)*(verts[0].y + verts[len(verts) - 1].y)
	var i = 1
	while i < len(verts):
		sum += (verts[i].x - verts[i-1].x)*(verts[i].y + verts[i-1].y)
		i += 1
	return sum > 0
	
func _is_point_in_cached_polygon(point: Vector2, polygon: Array[Vector2]) -> bool:
	if point in point_in_polygon_dict and point_in_polygon_dict[point]:
		return true
	point_in_polygon_dict[point] = _is_point_in_polygon(point, polygon)
	return point_in_polygon_dict[point]
	
func _is_point_in_polygon(point: Vector2, polygon: Array[Vector2]) -> bool:
	var polygon_length = len(polygon)
	var i = 0
	var inside = 0
	var pointX = point.x
	var pointY = point.y
	var startX: float
	var startY: float
	var endX: float
	var endY: float
	var endPoint = polygon[len(polygon) - 1]
	endX = endPoint.x
	endY = endPoint.y
	while i < len(polygon):
		startX = endX
		startY = endY
		endPoint = polygon[i]
		i += 1
		endX = endPoint.x
		endY = endPoint.y
		inside ^= int(( int(endY > pointY) ^ int(startY > pointY) ) and ( (pointX - endX) < (pointY - endY) * (startX - endX) / (startY - endY) ) )
	return bool(inside)
	
func _is_point_near_cached_boundary(point: Vector2, polygon: Array[Vector2]) -> bool:
	if point in point_on_boundary_dict:
		if point_on_boundary_dict[point]:
			return true
		return false
	point_on_boundary_dict[point] = _is_point_near_boundary(point, polygon)
	return point_on_boundary_dict[point]
	
func _is_point_near_boundary(point: Vector2, polygon: Array[Vector2]) -> bool:
	var to_return = false
	for i in range(len(polygon)):
		var j = i+1
		if i == len(polygon) - 1:
			j = 0
		var pv3 = Vector3(point.x, point.y, 0)
		var l1v3 = Vector3(polygon[i].x, polygon[i].y, 0)
		var l2v3 = Vector3(polygon[j].x, polygon[j].y, 0)
		if pv3.x >= min(l1v3.x, l2v3.x) - 1 and pv3.x <= max(l1v3.x, l2v3.x) + 1:
			if pv3.y >= min(l1v3.y, l2v3.y) - 1 and pv3.y <= max(l1v3.y, l2v3.y) + 1:
				var dist = _distance_from_line(l1v3, l2v3, pv3)
				if dist <= 2.0:
					to_return = true
					break
	return to_return
	
func _add_outline() -> void:
	for i in range(len(self.bounding_box)):
		var v1 = self.bounding_box[i]
		var v2 = self.bounding_box[0]
		if i < len(self.bounding_box) - 1:
			v2 = self.bounding_box[i+1]
		var line = CSGCylinder3D.new()
		line.transform.origin = (v1 + v2) / 2.0
		line.height = v1.distance_to(v2)
		line.radius = 0.02
		var angle = -1 * atan((v2.x - v1.x) / (v2.y - v1.y))
		line.rotate_z(angle)
		line.position.z = self.get_node("MeshStaticBody").position.z
		var material = StandardMaterial3D.new()
		line.set_material(material)
		line.material.albedo_color = Color.BLACK
		self.get_node("outline").add_child(line)
		
func _rotate_map(angle: float) -> void:
	curr_rot = -1 * angle
	
func _tilt_map(value: float) -> void:
	curr_tilt = deg_to_rad(value)
	
func _uncert_paint_mode() -> void:
	uncert_mode = UNCERT_MODE.PAINT
	
func _uncert_erase_mode() -> void:
	uncert_mode = UNCERT_MODE.ERASE
	
func _initiate_draw(global_pos: Vector3) -> void:
	var area: Area = self
	SignalBus.terminate_area_draw.emit(area)
	_drawing = true
	_draw_coords = global_pos
	#_draw(1.0)
	
func _end_draw() -> void:
	'''Called if the mouse is no longer drawing on this area.'''
	_drawing = false
	
func _terminate_draw(area: Area) -> void:
	'''Called if another area is being drawn on.'''
	if area != self:
		_end_draw()
		
func global_coord_to_pixel_coord(glob_coord: Vector3) -> Vector2:
	'''
	var center = calculate_global_center()
	# determine offset from center
	var offset = glob_coord - center
	# adjust offset by rotation
	var rot = atan(offset.y/offset.x)
	if offset.x < 0:
		if offset.y < 0:
			rot -= PI
		elif offset.y > 0:
			rot += PI
	var curr_rot1 = self.curr_rot
	var dist = sqrt(pow(offset.x, 2) + pow(offset.y, 2))
	var angle = rot - curr_rot
	var x = cos(angle) * dist
	var y = sin(angle) * dist
	
	# convert to pixel coord
	var coord: Vector2 = center_cell + Vector2(x, y)/pix_size
	return coord
	'''
	var offset = glob_coord - calculate_global_center()
	var magnitude = offset.length()
	var offset_norm = offset.normalized()
	var offset_norm_rot = offset_norm.rotated(Vector3(1,0,0), -1.0 * curr_tilt)
	offset_norm_rot = offset_norm_rot.rotated(Vector3(0,0,1), -1.0 * curr_rot)
	offset = offset_norm_rot * magnitude
	var offset_pix: Vector3 = offset/pix_size #was previously floor(offset / pix_size)
	# not sure why x needs to be rounded while y is floored...
	var coord: Vector2 = Vector2(round(center_cell.x + offset_pix.x), floor(center_cell.y + offset_pix.y))
	#print("\n########")
	#print(glob_coord)
	#print(coord)
	#print(pixel_coord_to_global_coord(coord.x, coord.y))
	return coord
	
func pixel_coord_to_global_coord(i: float, j: float) -> Vector3:
	var bb_center: Vector3 = calculate_global_center()
	return pixel_coord_to_global_coord_helper(i, j, bb_center)
	
func pixel_coord_to_global_coord_helper(i: float, j: float, bb_center: Vector3) -> Vector3:
	var i_cart = i - center_cell.x  # i with cartesian coords centered
	var j_cart = j - center_cell.y  # j with cartesian coords centered
	var bb_coord = Vector3(i_cart,j_cart,0) * pix_size
	bb_coord.z = bb_center.z
	
	# 2 - get offset from bounding box center
	var offset = bb_coord
	var offset_temp = offset
	
	# 3 - store magnitude of offset
	var magnitude = offset.length()
	
	# 4 - normalize offset
	var offset_norm = offset.normalized()
	
	# 5 - rotate offset by map rotation
	var offset_norm_rot = offset_norm.rotated(Vector3(0,0,1), curr_rot)
	offset_norm_rot = offset_norm_rot.rotated(Vector3(1,0,0), curr_tilt)
	
	# 6 - denormalized rotated offset
	offset = offset_norm_rot * magnitude
	
	# 7 - add offset to GLOBAL center to get world pos of pixel
	var pix_world_pos = bb_center + offset
	pix_world_pos.y += pix_size/2.0  # because the y pix coord got converted to the floor
	return pix_world_pos
		
func _draw() -> void:
	if not Options.opts.uncert_paint:
		return
	# convert the global position to the texture pixel
	# compute center of area
	var center = calculate_global_center()
	# determine offset from center
	var offset = _draw_coords - center
	# adjust offset by rotation
	var rot = atan(offset.y/offset.x)
	if offset.x < 0:
		if offset.y < 0:
			rot -= PI
		elif offset.y > 0:
			rot += PI
	var curr_rot1 = self.curr_rot
	var dist = sqrt(pow(offset.x, 2) + pow(offset.y, 2))
	var angle = rot - curr_rot
	var x = cos(angle) * dist
	var y = sin(angle) * dist
	
	# convert to pixel coord
	var coord: Vector2 = global_coord_to_pixel_coord(_draw_coords) #center_cell + Vector2(x, y)/pix_size
	
	'''
	var new_draw_area = {
		"coord" = coord,
		"start" = Vector2(-40, -40),
		"end" = Vector2(40, 40) 
	}
	draw_areas.append(new_draw_area)
	'''
	
	# draw the texture pixel
	var img = tex.get_image()
	# var img = area_mesh.material_override.albedo_texture.get_image()#### get rid of this
	for i in range(-10, 10):
		for j in range(-10, 10):
			if not _is_point_in_cached_polygon(Vector2(int(coord.x)+i, int(coord.y)+j), vec2_bb):
				continue
			var col = img.get_pixel(int(coord.x)+i, int(coord.y)+j)
			var i_reduce = i#/2.0
			var j_reduce = j#/2.0
			if uncert_mode == UNCERT_MODE.PAINT:
				if i == 0 and j == 0:
					col.a += 0.02
				else:
					col.a += 0.02/sqrt(pow(i_reduce, 2) + pow(j_reduce, 2))
			else:
				var alpha: float = col.a
				if i == 0 and j == 0:
					alpha -= 0.02
				else:
					alpha -= 0.02/sqrt(pow(i_reduce, 2) + pow(j_reduce, 2))
				col.a = max(alpha, 0.0)
			#col.a += max(0, 0.05 * (-1 * pow((sqrt(pow(i, 2) + pow(j, 2)))/15, 2) + 2.0)/2.0)
			img.set_pixel(int(coord.x)+i, int(coord.y)+j, col)
	_shader_texs[_curr_item] = ImageTexture.create_from_image(img)
	tex = _shader_texs[_curr_item]
	area_mesh.material_override.set_shader_parameter("sampler", tex)
	#### area_mesh.material_override.albedo_texture.set_image(img)

func paint(val: float) -> void:
	# acts like the paint bucket feature of drawing software
	var img = tex.get_image()
	for i in range(img.get_width()):
		for j in range(img.get_height()):
			img.set_pixel(i, j, Color(0, 0, 0, val))
	_shader_texs[_curr_item] = ImageTexture.create_from_image(img)
	tex = _shader_texs[_curr_item]
	area_mesh.material_override.set_shader_parameter("sampler", tex)
	
func paint_masks(masks: Array, changes: Array) -> void:
	# pre-compute the boundary of the polygon
	#var vec2_bb: Array[Vector2] = []
	#for node in self.nodes_node.get_children():
	#	vec2_bb.append(global_coord_to_pixel_coord(node.global_position))
	
	# uncomment below for voronoi painting
	var img = tex.get_image()
	for change in changes:
		var center = change["center"]
		var selected = change["status"]
		for i in range(center.x - 40, center.x + 41):
			for j in range(center.y - 40, center.y + 41):
				
				var _on_boundary = false
				
				# only consider the points inside of the circle
				# this is already a bit redundant.
				if center.distance_to(Vector2(i,j)) > 40:
					continue
					
				# test if the pixel is out of bounds
				# var glob_pt = pixel_coord_to_global_coord_helper(i, j, bb_center)
				if not _is_point_in_cached_polygon(Vector2(i, j), vec2_bb):
					continue
					
				if _is_point_near_cached_boundary(Vector2(i, j), vec2_bb):
					_on_boundary = true
				
				# get nearby points as well
				var distances: Array[Dictionary] = []
				for mask_data in masks:
					var coord: Vector2 = mask_data["center"]
					var dist = coord.distance_to(Vector2(i, j))
					if dist > 40 * 2:
						continue
					distances.append({
						"distance": dist,
						"value": mask_data["value"]
						})
				distances.sort_custom(func(a, b): return a["distance"] < b["distance"])
				
				# if there are no masks (this could happen if the only point was just deleteed)
				if len(distances) == 0:
					_set_pixel(i, j, Color(0, 0, 0, 0.8), img) # img.set_pixel(i, j, Color(0, 0, 0, 0))
				
				# if the pixel is equidistant from the top two points
				elif len(distances) > 1 and\
				   	distances[0]["distance"] <= 40 and\
				   	abs(distances[0]["distance"] - distances[1]["distance"]) < 4:
					_set_pixel(i, j, Color(distances[0]["value"], 0, 0, 1.0), img) # img.set_pixel(i, j, Color(0, 0, 0, 1.0))
				
				# if the pixel is closest to just one mask
				elif distances[0]["distance"] <= 40:
					var dist_to_center: float = center.distance_to(Vector2(i,j)) 
					
					# outline
					if distances[0]["distance"] > 38 and distances[0]["distance"] <= 40:
						_set_pixel(i, j, Color(distances[0]["value"], 0, 0, 1.0), img) # img.set_pixel(i, j, Color(0, 0, 0, 1.0))
					
					# inside the point
					elif dist_to_center <= 40 and dist_to_center <= distances[0]["distance"]:
						if _on_boundary:
							_set_pixel(i, j, Color(distances[0]["value"], 0, 0, 1.0), img)
						elif selected > 0:
							_set_pixel(i, j, Color(0.1, 0.0, 0, 0.8), img) # img.set_pixel(i, j, Color(selected, 0, 0, .5))
						else:
							_set_pixel(i, j, Color(0.1, 0.1, 0.1, 0.8), img)
					
					# ?
					else:
						_set_pixel(i, j, Color(0.1, 0.1, 0.1, 0.8), img) # img.set_pixel(i, j, Color(0, 0, 0, .5))
				
				# ?
				else:
					_set_pixel(i, j, Color(0, 0, 0, 0.8), img) # img.set_pixel(i, j, Color(0, 0, 0, 0))
	_shader_texs[_curr_item] = ImageTexture.create_from_image(img)
	tex = _shader_texs[_curr_item]
	area_mesh.material_override.set_shader_parameter("sampler", tex)
			
	# uncomment below for mask painting
	'''
	# wipe the texture
	var img = tex.get_image()
	for i in range(img.get_width()):
		for j in range(img.get_height()):
			img.set_pixel(i, j, Color(0, 0, 0, 0))
			
	# apply the mask data
	for mask_data in masks:
		var coord: Vector2 = mask_data["center"]
		var mask: Array = mask_data["mask"]
		
		for i in range(-10, 10):
			for j in range(-10, 10):
				var col = img.get_pixel(int(coord.x)+i, int(coord.y)+j)
				col.a += mask[i+10][j+10]/sqrt(pow(i, 2) + pow(j, 2))
				if col.a > 1.0:
					col.a = 1.0
				img.set_pixel(int(coord.x)+i, int(coord.y)+j, col)
	_shader_texs[_curr_item] = ImageTexture.create_from_image(img)
	tex = _shader_texs[_curr_item]
	area_mesh.material_override.set_shader_parameter("sampler", tex)
	'''
	
func _set_pixel(i: float, j: float, col: Color, img: Image) -> void:
	if img.get_pixel(i, j) == col:
		return
	img.set_pixel(i, j, col)
	
func create_uncert_point(uid: int, global_pos: Vector3, entry: Entry) -> void:
	var uncert_label: Node3D = uncert_label_scene.instantiate()
	add_child(uncert_label)
	uncert_label.set_uid(uid)
	uncert_label.set_label("?")
	uncert_label.global_position = global_pos
	uncert_label.position.z = label_node.position.z + 0.15
	uncert_label.map_rotated(-1.0 * curr_rot)
	if uncert_label_dict == null:
		uncert_label_dict = {}
	uncert_label_dict[uid] = {
		"label": uncert_label,
		"position": global_pos,
		"pixel": global_coord_to_pixel_coord(global_pos),
		"entry": entry
	}
	
func set_uncert_label(uid: int, text: String) -> void:
	uncert_label_dict[uid]["label"].set_label(text)
	
func set_uncert_percent_label(uid: int, percent: String) -> void:
	uncert_label_dict[uid]["label"].set_percentage(percent)
	
func set_uncert_label_size(uid: int, size: int) -> void:
	uncert_label_dict[uid]["label"].set_label_size(size)
	
func move_uncert_point(uid: int, new_pos: Vector3) -> void:
	uncert_label_dict[uid]["position"] = new_pos
	uncert_label_dict[uid]["pixel"] = global_coord_to_pixel_coord(new_pos)
	uncert_label_dict[uid]["label"].global_position = new_pos
	uncert_label_dict[uid]["label"].global_position.z += 0.15
	
func delete_uncert_point(uid: int) -> void:
	uncert_label_dict[uid]["label"].delete()
	uncert_label_dict.erase(uid)
	
func get_closest_uncert_point(pos: Vector3) -> Entry:
	var closest: Entry = null
	var closest_dist: float = -1
	for uid in uncert_label_dict:
		var point = pixel_coord_to_global_coord(uncert_label_dict[uid]["pixel"].x, uncert_label_dict[uid]["pixel"].y)
		#uncert_label_dict[uid]["position"]
		var posV2 = Vector2(pos.x, pos.y)
		var pointV2 = Vector2(point.x, point.y) 
		var dist: float = posV2.distance_to(pointV2)
		if (closest_dist < 0 or dist < closest_dist) and dist <= 40 * pix_size:
			closest = uncert_label_dict[uid]["entry"]
			closest_dist = dist 
	return closest
	
func get_uncert_points() -> Array[Entry]:
	var entries: Array[Entry] = []
	for uid in uncert_label_dict:
		entries.append(uncert_label_dict[uid]["entry"])
	return entries

func _process_chunks() -> void:
	if len(draw_areas) == 0:
		return
	var idx: int = 0
	var curr_draw_area = draw_areas[0]
	var coord = curr_draw_area["coord"]
	var start_i = curr_draw_area["start"].x
	var end_i = curr_draw_area["end"].x
	var start_j = curr_draw_area["start"].y
	var end_j = curr_draw_area["end"].y
	var img = tex.get_image()
	while idx < CHUNK_SIZE:
		for i in range(start_i, end_i):
			if idx >= CHUNK_SIZE:
				curr_draw_area["start"].x = i
			for j in range(start_j, end_j):
				if idx >= CHUNK_SIZE:
					curr_draw_area["start"].y = j
				var col = img.get_pixel(int(coord.x)+i, int(coord.y)+j)
				col.a += max(0, 0.05 * (-1 * pow((sqrt(pow(i, 2) + pow(j, 2)))/40, 2) + 2.0)/2.0)
				img.set_pixel(int(coord.x)+i, int(coord.y)+j, col)
				idx += 1
		draw_areas.pop_front()
		if len(draw_areas) == 0:
			break
		curr_draw_area = draw_areas[0]
		coord = curr_draw_area["coord"]
		start_i = curr_draw_area["start"].x
		end_i = curr_draw_area["end"].x
		start_j = curr_draw_area["start"].y
		end_j = curr_draw_area["end"].y
	tex = ImageTexture.create_from_image(img)
	area_mesh.material_override.set_shader_parameter("sampler", tex)
	
func show_waypoints() -> void:
	for waypoint_tree in waypoints.get_children():
		waypoint_tree.propagate_call("show")
		
func hide_waypoints() -> void:
	for waypoint_tree in waypoints.get_children():
		waypoint_tree.propagate_call("hide")
	
func get_uncertainty() -> float:
	var val: float = 0
	var img: Image = tex.get_image()
	for i in range(img.get_width()):
		for j in range(img.get_height()):
			val += img.get_pixel(i, j).a
	return val
	
func _on_area_input_event(camera, event, position, normal, shape_idx) -> void:
	if _interaction_disabled:
		return
	if self.mode == self.AREA_MODE.NORMAL:
		if event is InputEventMouseButton and event.is_action_released("click"):
			SignalBus.edit_menu_toggle.emit(event.position, self)
	elif self.mode == self.AREA_MODE.UNCERT and\
		 ((not self._is_surface and self.paint_mode != self.PAINT_MODE.SURFACE) or\
		  (self._is_surface and self.paint_mode != self.PAINT_MODE.REGION)):
		if Options.opts.uncert_paint:
			if event.is_action_pressed("click"):
				Logger.log_event("mouse_down_on_area", {"area": unique_label})
			if Input.is_mouse_button_pressed(1):
				if not self._is_surface:
					SignalBus.activate_region_paint_mode.emit()
				else:
					SignalBus.activate_surface_paint_mode.emit()
				self._initiate_draw(position)
			elif event is InputEventMouseMotion and self._drawing:
				self._initiate_draw(position)
			elif event.is_action_released("click"):
				Logger.log_event("mouse_up_on_area", {"area": unique_label})
				SignalBus.deactivate_paint_mode.emit()
				SignalBus.just_painted.emit()
				self._end_draw()
		elif Options.opts.uncert_rank or Options.opts.uncert_sliders:
			# Add new point
			if event is InputEventMouseButton and event.is_action_pressed("click"):
				_rank_or_slider_pressed = true
				# determine if an existing point was clicked
				var entry = self.get_closest_uncert_point(position)
				if entry != null:
					# highlight the entry in the parameter pane
					Logger.log_event("entry_highlighted", {"area": unique_label, "entry": entry.uid})
					SignalBus.highlight_uncert_entry.emit(entry.uid)
					return
				# send the position, the region label, and the unique ID label
				var waypoint: Node3D
				var closest_distance: float = -1.0
				for wp in waypoints.get_children():
					var dist: float = wp.global_position.distance_to(position)
					if closest_distance < 0 or dist < closest_distance:
						closest_distance = dist
						waypoint = wp
				Logger.log_event("entry_create", {"area": unique_label})
				SignalBus.uncert_new_slider.emit(root_entity, position, waypoint.get_wp_name())
			# drag existing point
			if _rank_or_slider_pressed and event is InputEventMouseMotion: # if event is InputEventScreenDrag:
				var uid = self.dragged_uncert_point
				if uid == null or uid < 0:
					var entry = self.get_closest_uncert_point(position)
					if entry != null:
						uid = entry.uid
				if uid > -1:
					self.dragged_uncert_point = uid
					Logger.log_event("entry_move", {"entry": uid, "position_x": position.x, "position_y": position.y})
					SignalBus.update_uncert_point_position.emit(uid, position)
			if event is InputEventMouseButton and event.is_action_released("click"):
				self.dragged_uncert_point = -1
				_rank_or_slider_pressed = false
	elif self.mode == self.AREA_MODE.NAVMESH:
		if event is InputEventMouseButton and event.is_action_pressed("click"):
			add_waypoint("unknown", position)
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_action_released("click"):
		self.dragged_uncert_point = -1
		_rank_or_slider_pressed = false
			
func add_waypoint(wp_name: String, pos: Vector3) -> void:
	var new_waypoint = waypoint.instantiate()
	waypoints.add_child(new_waypoint)
	new_waypoint.position = pos
	new_waypoint.set_wp_name(wp_name)
	
func jsonify() -> Dictionary:
	var bb: Array = []
	for item in self.bounding_box_raw:
		bb.append([item.x, item.y, item.z])
	var waypoints: Array[Dictionary] = []
	for waypoint in get_node("waypoints").get_children():
		waypoints.append({
			"wp_name": waypoint.get_wp_name(),
			"wp_position": [waypoint.position.x, waypoint.position.y, waypoint.position.z]
		})
	var to_return = {
		"entity_class": root_entity.get_entity_class(),
		"label": get_label(),
		"bounding_box": bb,
		"properties":properties,
		"color": [get_color().r, get_color().g, get_color().b, get_color().a],
		"label_position": [label_node.position.x, label_node.position.y],
		"waypoints": waypoints
	}
	return to_return
