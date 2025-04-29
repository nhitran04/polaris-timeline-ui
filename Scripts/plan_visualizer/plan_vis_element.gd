extends HBoxContainer

class_name PlanVisElement

@onready var action_container := $Panel

# instance variables
var final_state: Array[Predicate]
var world_snapshot: Dictionary  # Dictionary[Vector3]
var highlighted: bool

func _ready() -> void:
	highlighted = false

func set_final_state(final_state: Array[Predicate]) -> void:
	self.final_state = final_state
	
func update_world_snapshot(predicates: Array[Predicate]) -> void:
	for pred in predicates:
		var adjusted_entities: Array[WorldEntity] = pred.update_world_to_satisfy_predicate()
		for entity in adjusted_entities:
			world_snapshot[entity] = entity.get_location()
			
func load_world_snapshot() -> void:
	for entity in world_snapshot:
		entity.set_location(world_snapshot[entity])
		# TODO: also set the parent of the entity
		
func highlight() -> void:
	if not highlighted:
		var style: StyleBoxFlat = action_container.get_theme_stylebox("panel").duplicate()
		style.bg_color =  Color.YELLOW
		action_container.add_theme_stylebox_override("panel", style)
		highlighted = true
	
func unhighlight() -> void:
	if highlighted:
		var style: StyleBoxFlat = action_container.get_theme_stylebox("panel").duplicate()
		style.bg_color =  Color(47/255.0, 118/255.0, 120/255.0, 1.0)
		action_container.add_theme_stylebox_override("panel", style)
		highlighted = false
