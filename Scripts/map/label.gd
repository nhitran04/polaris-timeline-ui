extends MeshInstance3D

@onready var static_body := $StaticBody3D as StaticBody3D
@onready var draw_area := $DrawArea as Area3D
@onready var static_body_collider := $StaticBody3D/CollisionShape3D as CollisionShape3D
@onready var drag_collider := $DrawArea/CollisionShape3D as CollisionShape3D
@export var textedit: TextEdit

# instance variables
var curr_rotation: float
var _locked: bool

# local signals
signal label_position_changed

# Called when the node enters the scene tree for the first time.
func _ready():
	material_override.albedo_texture = $SubViewport.get_texture()
	material_override.transparency = 1  # transparency enabled
	material_override.render_priority = 2
	get_node("StaticBody3D").input_event.connect(_on_clicked.bind(self))
	_adjust_size()
	
	SignalBus.disable_world_entity_raycasts.connect(_disable_hits)
	SignalBus.disable_world_entity_raycasts_with_exceptions.connect(_possibly_disable_hits)
	SignalBus.enable_world_entity_raycasts.connect(_enable_hits)
	SignalBus.rotate_map.connect(_map_rotated)
	SignalBus.activate_build_mode.connect(_unlock)
	SignalBus.activate_param_mode.connect(_unlock)
	SignalBus.activate_nav_mesh_mode.connect(_lock)
	SignalBus.activate_uncert_mode.connect(_lock)
	_locked = false
	curr_rotation = 0
			
func _disable_hits() -> void:
	static_body.input_ray_pickable = false
	
func _possibly_disable_hits(exceptions: Array[Node3D]) -> void:
	if self not in exceptions:
		static_body.input_ray_pickable = false
	
func _enable_hits() -> void:
	static_body.input_ray_pickable = true

func set_font_size(size: int) -> void:
	textedit.add_theme_font_size_override("font_size", size)
	
func set_font_outline(size: int, col: Color) -> void:
	textedit.add_theme_constant_override("outline_size", size)
	textedit.add_theme_color_override("font_outline_color", col)
	
func set_font_color(col: Color) -> void:
	textedit.add_theme_color_override("font_color", col)
	
func set_pos(pos: Vector2) -> void:
	position.x = pos.x
	position.y = pos.y
	label_position_changed.emit()
	
func set_global_pos(pos: Vector2) -> void:
	global_position.x = pos.x
	global_position.y = pos.y
	label_position_changed.emit()
	
func set_render_priority(priority: int) -> void:
	material_override.render_priority = priority

func _on_clicked(camera, event, position, normal, shape_idx, lab):
	if _locked:
		return
	if event is InputEventMouseButton and event.is_action_pressed("click"):
		SignalBus.edit_menu_hide.emit()
		lab.get_node("SubViewport/TextEdit").grab_focus()
		lab.get_node("SubViewport/TextEdit").select_all()
	elif event is InputEventScreenDrag:
		lab.get_node("SubViewport/TextEdit").release_focus()
		static_body_collider.disabled = true
		drag_collider.disabled = false

func _on_draw_area_input_event(_camera, event, position, _normal, _shape_idx) -> void:
	if event is InputEventScreenDrag and not drag_collider.disabled:
		set_global_pos(Vector2(position.x, position.y))
		var exceptions: Array[Node3D] = [static_body]
		SignalBus.disable_world_entity_raycasts_with_exceptions.emit(exceptions)
		SignalBus.edit_menu_hide.emit()
	if event is InputEventMouseButton and event.is_action_released("click"):
		drag_collider.disabled = true
		static_body_collider.disabled = false
		SignalBus.enable_world_entity_raycasts.emit()
		SignalBus.edit_menu_hide.emit()
		
func _lock() -> void:
	_locked = true
	static_body.input_ray_pickable = false
	static_body_collider.disabled = true
	draw_area.input_ray_pickable = false
	drag_collider.disabled = true
	
func _unlock() -> void:
	_locked = false
	static_body.input_ray_pickable = true
	static_body_collider.disabled = false
	draw_area.input_ray_pickable = true
	drag_collider.disabled = true

func _input(event):
	if event is InputEventKey:
		$SubViewport.push_input(event)
	
		
func _adjust_size() -> void:
	var t: String = textedit.text
	var v: Vector2
	v = textedit.get_theme_font("font").\
					get_string_size(textedit.text,
									HORIZONTAL_ALIGNMENT_LEFT,
									-1,
									textedit.get_theme_font_size("font_size"))
									
func _map_rotated(map_angle: float) -> void:
	rotate_z(map_angle - curr_rotation)
	curr_rotation = map_angle
