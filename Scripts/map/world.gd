extends Node

class_name World

# map
var default_map_file = "res://Resources/maps/default_map.json"

# mesh
# @onready var mesh3d := $Window/Map/Map/MapMesh
# @onready var map := $Window/Map/Map
# @onready var camera := $Window/Camera3D
# @onready var user_drawer := $Window/Map/UILayerMapEditor/UserDrawer

# UI
# @onready var add_menu := $Window/Map/UILayerMapEditor/EditMenu
# @onready var editor_ui := $Window/Map/UILayerMapEditor
# @onready var planvis_ui := $Window/Map/UILayerPlanViz

@export var mesh3d: MeshInstance3D# := $Window/Map/Map/MapMesh
@export var map: Node3D# := $Window/Map/Map
@export var camera: Camera3D# := $Window/Camera3D
@export var user_drawer: Line2D# := $Window/Map/UILayerMapEditor/UserDrawer

# UI
@export var add_menu: Control# := $Window/Map/UILayerMapEditor/EditMenu
@export var editor_ui: CanvasLayer# := $Window/Map/UILayerMapEditor
@export var planvis_ui: CanvasLayer# := $Window/Map/UILayerPlanViz
@export var view_control_ui: Panel
@export var uncert_controls_ui: VBoxContainer
@export var key_ui: Panel

# helpful nodes
@export var world_db: WorldDatabase

# world entities
var world_entity := load("res://Scenes/map/world_entity.tscn")

# interaction mode
enum MAP_MODE {IDLE,
			   REGION_DRAW,
			   SURFACE_DRAW,
			   DRAGGING}
var mode := MAP_MODE.IDLE

# mouse
var _pressed := false
var _mouse_button := MOUSE_BUTTON_LEFT
var _last_pressed_pos: Vector3

# region/surface drawing
var in_progress_area: PackedVector3Array

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# signals
	SignalBus.save_map.connect(_save_map)
	SignalBus.load_map.connect(_load_map)
	SignalBus.exit_map.connect(_exit_map)
	SignalBus.enter_map.connect(_enter_map)
	SignalBus.enter_plan_vis.connect(_enter_plan_vis)
	SignalBus.delete_region.connect(_delete_region)
	SignalBus.delete_surface.connect(_delete_surface)
	SignalBus.delete_item.connect(_delete_item)
	SignalBus.delete_person.connect(_delete_person)
	SignalBus.translate_map.connect(_shift_map)
	SignalBus.rotate_map.connect(_rotate_map)
	SignalBus.reset_map_in_space.connect(_reset_map_in_space)
	SignalBus.tilt_map.connect(_tilt_map)
	SignalBus.release_click.connect(_release_click)
	SignalBus.activate_uncert_mode.connect(_activate_uncert_mode)
	SignalBus.activate_nav_mesh_mode.connect(_deactivate_uncert_mode)
	SignalBus.activate_param_mode.connect(_deactivate_uncert_mode)
	SignalBus.activate_build_mode.connect(_deactivate_uncert_mode)
	
	# load default map
	call_deferred("_load_slam_map")
	
	# add the robot
	# this cannot be called until everything is init because requesting the domain relies on 
	# Options which are configured in controller.gd _ready()
	call_deferred("_add_new_robot")
	
	# load food assembly map
	call_deferred("_load_map")
	
func _load_slam_map() -> void:
	var json_text = FileAccess.get_file_as_string("res://Resources/maps/" + Options.opts.map + ".json")
	var map_info = JSON.parse_string(json_text)
	var width = map_info["width"]
	var height = map_info["height"]
	var data_arr = map_info["data"]
	var resolution = map_info["resolution"]
	var dim = max(width, height)
	
	var min_width = width
	var max_width = -1
	var min_height = height
	var max_height = -1
	for j in height:
		for i in width:
			var data = data_arr[(j * width) + i]
			if data > -1:
				if i > max_width: 
					max_width = i
				if j > max_height:
					max_height = j
				if i < min_width:
					min_width = i
				if j < min_height:
					min_height = j
	var adj_width = max_width - min_width
	var adj_height = max_height - min_height
	
	var img = Image.create(adj_width, adj_height, false, Image.FORMAT_RGBA8)
	img.fill(Color.BLACK)
	for j in height:
		for i in width:
			var data = data_arr[(j * width) + i]
			if data == 0:
				if Options.opts.map == "caregiving_map":
					img.set_pixel(i - min_width, max_height - (j - min_height), Color.WHITE)
				else:
					img.set_pixel(i - min_width, j - min_height, Color.WHITE)
		
	# adjust the size of the plane as necessary
	var plane_width = adj_width * resolution
	var plane_height = adj_height * resolution
	mesh3d.mesh.size = Vector2(plane_width, plane_height)
	var s = mesh3d.mesh.size
	#img.set_pixel(1, 1, Color.WHITE)
	var tex = ImageTexture.create_from_image(img)
	mesh3d.mesh.surface_get_material(0).albedo_texture = tex
	mesh3d.mesh.surface_get_material(0).texture_filter = 0
	
func _on_static_body_3d_input_event(camera, event, position, normal, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		_pressed = event.is_action_pressed("click")
		_mouse_button = event.button_index
		_last_pressed_pos = position
		SignalBus.remove_labels_focus.emit()
	if _mouse_button == MOUSE_BUTTON_RIGHT:
		if not mode == MAP_MODE.REGION_DRAW and not mode == MAP_MODE.SURFACE_DRAW:
			_set_mode(MAP_MODE.DRAGGING)
			var change: Vector3 = position - _last_pressed_pos
			if change.distance_to(Vector3(0, 0, 0)) > 0.1:
				SignalBus.dragging_map.emit()
			var candidate_pos: Vector3 = map.position + change
			_last_pressed_pos = position
			SignalBus.edit_menu_hide.emit()
			if candidate_pos.x >= -40 and candidate_pos.x <= 40:
				map.position.x += change.x
				Logger.log_event("map_shift_by_mouse", {"x": map.position.x})
			if candidate_pos.y >= -40 and candidate_pos.y <= 40:
				map.position.y += change.y
				Logger.log_event("map_shift_by_mouse", {"y": map.position.y})
	if event is InputEventMouseMotion and _pressed:
		if mode == MAP_MODE.REGION_DRAW or mode == MAP_MODE.SURFACE_DRAW:
			# need to convert from global to local position here
			var draw_pos = Vector3(position.x - map.position.x, position.y - map.position.y, 0)
			in_progress_area.push_back(draw_pos)
	elif event.is_action_released("click"):
		_release_click()
		if mode == MAP_MODE.IDLE:
			SignalBus.edit_menu_toggle.emit(event.position, map)
		elif mode == MAP_MODE.REGION_DRAW or mode == MAP_MODE.SURFACE_DRAW:
			if len(in_progress_area) < 3:  # can't have polygons with <3 vertices
				return
			var label = ""
			if mode == MAP_MODE.REGION_DRAW:
				label = "unknown_region"
			else:
				label = "unknown_surface"
			_add_new_area(label, mode, in_progress_area, true)
			_set_mode(MAP_MODE.IDLE)
			SignalBus.enable_world_entity_raycasts.emit()
		else:
			_set_mode(MAP_MODE.IDLE)
			
func _release_click() -> void:
	_pressed = false
	_mouse_button = MOUSE_BUTTON_LEFT
			
func _shift_map(delta: Vector3) -> void:
	map.position += delta 
	Logger.log_event("map_shifted", {"x": map.position.x, "y": map.position.y, "z": map.position.z})
	
func _rotate_map(angle: float) -> void:
	map.rotation.z = -1 * angle

func _tilt_map(value: float) -> void:
	map.rotation.x = deg_to_rad(value)
	
func _reset_map_in_space() -> void:
	map.position = Vector3(0, 0, 0)
	map.rotation.z = 0
	map.rotation.x = 0

func _on_region_pressed():
	_set_mode(MAP_MODE.REGION_DRAW)
	in_progress_area = PackedVector3Array()
	SignalBus.edit_menu_hide.emit()
	SignalBus.disable_world_entity_raycasts.emit()
	user_drawer.set_color(Color.RED)
	user_drawer.allow_draw()
	
func _on_surface_pressed():
	_set_mode(MAP_MODE.SURFACE_DRAW)
	in_progress_area = PackedVector3Array()
	SignalBus.edit_menu_hide.emit()
	SignalBus.disable_world_entity_raycasts.emit()
	user_drawer.set_color(Color.CORAL)
	user_drawer.allow_draw()
	
func _on_entity_pressed():
	SignalBus.edit_menu_hide.emit()
	_add_new_item("unknown_item", Vector3(_last_pressed_pos.x, _last_pressed_pos.y, 0), true)

func _on_person_pressed():
	SignalBus.edit_menu_hide.emit()
	_add_new_person("unknown_person", Vector3(_last_pressed_pos.x, _last_pressed_pos.y, 0), true)
	
func _add_new_robot():
	var new_robot = world_entity.instantiate()
	map.add_child(new_robot)
	new_robot.create_robot()
	world_db.add_robot(new_robot, "robot")

func _update_robot_name(label: String) -> void:
	var robot_entity = world_db.get_objects_of_types(["robot"])[0]
	robot_entity.set_label(label)
	
func _update_robot_position(pos: Vector3) -> void:
	var robot_entity = world_db.get_objects_of_types(["robot"])[0]
	robot_entity.position = pos
	
func _add_new_item(label: String, position: Vector3, is_new: bool, props: Dictionary = {}, subtype: String="") -> Node3D:
	var new_world_item = world_entity.instantiate()
	map.add_child(new_world_item)
	new_world_item.create_item(position, subtype, props, is_new, label)
	world_db.add_item(new_world_item, "item")
	return new_world_item

func _add_new_person(label: String, position: Vector3, is_new: bool, props: Dictionary = {}):
	var new_world_person = world_entity.instantiate()
	map.add_child(new_world_person)
	new_world_person.create_person(position, props, is_new, label)
	world_db.add_person(new_world_person, "person")
	
func _add_new_area(label: String, type: MAP_MODE, in_progress_area: PackedVector3Array, is_new: bool, props: Dictionary = {}) -> Node3D:
	var new_world_entity = world_entity.instantiate()
	map.add_child(new_world_entity)
	if type == MAP_MODE.REGION_DRAW:
		new_world_entity.create_region(in_progress_area, props, is_new, label)
		world_db.add_region(new_world_entity, "region")
	else:
		new_world_entity.create_surface(in_progress_area, props, is_new, label)
		world_db.add_surface(new_world_entity, "surface")
	return new_world_entity
		
func _delete_region(obj: Region) -> void:
	for ent in world_db.world_entities:
		if ent.entity_class == "region" and ent.get_label() == obj.get_label():
			world_db.delete_region(ent)
			map.remove_child(ent)
			ent.queue_free()
			break
			
func _delete_surface(obj: Surface) -> void:
	for ent in world_db.world_entities:
		if ent.entity_class == "surface" and ent.get_label() == obj.get_label():
			world_db.delete_surface(ent)
			map.remove_child(ent)
			ent.queue_free()
			break 
			
func _delete_item(obj: Item) -> void:
	for ent in world_db.world_entities:
		if ent.entity_class == "item" and ent.get_label() == obj.get_label():
			world_db.delete_item(ent)
			map.remove_child(ent)
			ent.queue_free()
			break 

func _delete_person(obj: Person) -> void:
	for ent in world_db.world_entities:
		if ent.entity_class == "person" and ent.get_label() == obj.get_label():
			world_db.delete_person(ent)
			map.remove_child(ent)
			ent.queue_free()
			break 
	
func _save_map() -> void:
	world_db.save_world()
		
func _exit_map() -> void:
	SignalBus.edit_menu_hide.emit()
	mode = MAP_MODE.IDLE
	view_control_ui.visible = false
	$Map.visible = false
	
func _enter_map() -> void:
	$Map.visible = true
	editor_ui.visible = true
	planvis_ui.visible = false
	view_control_ui.visible = true
	view_control_ui.rotate_set(0.0)
	view_control_ui.tilt_set(0.0)
	view_control_ui.zoom_set(18.0)
	camera.set_map_mode()
	
func _activate_uncert_mode() -> void:
	uncert_controls_ui.visible = true
	key_ui.visible = true
	
func _deactivate_uncert_mode() -> void:
	uncert_controls_ui.visible = false
	key_ui.visible = false
	
func _enter_plan_vis(elements: Array[Control]) -> void:
	$Map.visible = true
	editor_ui.visible = false
	planvis_ui.visible = true
	camera.set_plan_vis_mode()
	planvis_ui.get_node("PlanPane").set_plan(elements)
	
func _set_mode(new_mode: MAP_MODE) -> void:
	self.mode = new_mode
	if self.mode != MAP_MODE.DRAGGING and self.mode != MAP_MODE.IDLE:
		SignalBus.lock_3D_camera_zoom.emit(true)
	else:
		SignalBus.lock_3D_camera_zoom.emit(false)
		
func _input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_A):
		map.position.x -= 0.15 
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_D):
		map.position.x += 0.15 
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		map.position.y -= 0.15
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		map.position.y += 0.15 
	
func _load_map() -> void:
	SignalBus.reset_world.emit()
	# first attempt to load the save file from the user's local filesystem
	var save_map = FileAccess.open("user://" + Options.opts.save, FileAccess.READ)
	if save_map:
		var json = JSON.new()
		var status = json.parse(save_map.get_line())
		var data = json.get_data() 
		for json_string in data["map"]:
			_load_map_helper(json_string)
	# if that doesn't work, load preloaded save
	else:
		var save_to_load = Saves.saves[Options.opts.save]
		for json_string in save_to_load["map"]:
			_load_map_helper(json_string)

	SignalBus.reset_predicates.emit()
	
	# load any uncert save data
	if Options.opts.load_uncert:
		var file = FileAccess.open("res://Resources/data/" + Options.opts.load_uncert_file, FileAccess.READ)
		var uncert_json = JSON.new()
		var uncert_status = uncert_json.parse(file.get_as_text())
		var uncert_data = uncert_json.get_data()
		if Options.opts.uncert_paint:
			for reg in world_db.regions:
				reg.get_entity().load_uncert_save_data(uncert_data)
			for sur in world_db.surfaces:
				sur.get_entity().load_uncert_save_data(uncert_data)
		else:
			for item in uncert_data:
				$Map/UILayerMapEditor/UncertControls/ParamPanel._select_uncert_item(item)
				for ulabel in uncert_data[item]:
					var area: Area
					for reg in world_db.regions:
						if reg.get_entity().unique_label == ulabel:
							area = reg.get_entity()
					for sur in world_db.surfaces:
						if sur.get_entity().unique_label == ulabel:
							area = sur.get_entity()
					area.select_uncert_item(item)
					for pt in uncert_data[item][ulabel]:
						var center = pt["center"]
						var value = pt["value"]
						var uid = pt["uid"]
						var text: String = pt["text"]
						var slider: float = pt["slider"]
						var area_uid_str: String = text.substr(text.find(",") + 2)
						var area_uid: int = int(area_uid_str.substr(len(area.get_abbrv())))
						$Map/UILayerMapEditor/UncertControls/ParamPanel.add_existing(area.root_entity, Vector2(center[0], center[1]), uid, area_uid, text, value, slider, item)
				$Map/UILayerMapEditor/UncertControls/ParamPanel.paint_all(item)
	
	# Comment out to edit maps; otherwise, the map will be shown when entering
	get_tree().root.get_node("Polaris/Problem/TwoWayTimeline").visible = true
	get_tree().root.get_node("Polaris/Background").visible = true
	for i in get_tree().root.get_node("Polaris/UILayerDrawingBoard").get_children():
		if i.get_index() > 0:
			i.visible = false
	_exit_map()

func _load_map_helper(json_string: String) -> void:
	var json = JSON.new()
	var status = json.parse(json_string)
	var data = json.get_data()
	if data["entity_class"] == "item":
		var entity: Node3D
		if data.has("subtype"):
			entity = _add_new_item(data["label"], Vector3(data["position"][0], data["position"][1], 0), false, data["properties"], data["subtype"])
		else:
			entity = _add_new_item(data["label"], Vector3(data["position"][0], data["position"][1], 0), false, data["properties"])
		if "color" in data:
			var col = Color(data["color"][0], data["color"][1], data["color"][2], data["color"][3])
			entity.get_entity().set_color(col)
		if "label_position" in data:
			var pos: Vector2 = Vector2(data["label_position"][0], data["label_position"][1])
			entity.get_entity().set_label_position(pos)
	elif data["entity_class"] == "person":
		_add_new_person(data["label"], Vector3(data["position"][0], data["position"][1], 0), false, data["properties"])
	elif data["entity_class"] == "robot":
		_update_robot_name(data["label"])
		_update_robot_position(Vector3(data["position"][0], data["position"][1], data["position"][2]))
	else:
		var arr: PackedVector3Array = []
		for tup in data["bounding_box"]:
			arr.append(Vector3(tup[0], tup[1], 0))
		var draw_mode = MAP_MODE.REGION_DRAW
		if data["entity_class"] == "surface":
			draw_mode = MAP_MODE.SURFACE_DRAW
		var entity: Node3D = _add_new_area(
								data["label"],
								draw_mode,
								arr,
								false,
								data["properties"]
							)
		# add waypoints
		var area: Area = entity.get_entity()
		for dict in data["waypoints"]:
			var wp_name = dict["wp_name"]
			var tup = dict["wp_position"]
			area.add_waypoint(wp_name, Vector3(tup[0], tup[1], tup[2]))
		area.hide_waypoints()
		if "color" in data:
			var col = Color(data["color"][0], data["color"][1], data["color"][2], data["color"][3])
			entity.get_entity().set_color(col)
		if "label_position" in data:
			var pos: Vector2 = Vector2(data["label_position"][0], data["label_position"][1])
			entity.get_entity().set_label_position(pos)
		if "uniquelabel" in data:
			entity.get_entity().set_unique_label(data["uniquelabel"])
