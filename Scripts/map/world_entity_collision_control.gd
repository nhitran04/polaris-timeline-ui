extends CollisionObject3D


# Called when the node enters the scene tree for the first time.
func _ready():
	SignalBus.disable_world_entity_raycasts.connect(_disable_hits)
	SignalBus.disable_world_entity_raycasts_with_exceptions.connect(_possibly_disable_hits)
	SignalBus.enable_world_entity_raycasts.connect(_enable_hits)
	
func _disable_hits() -> void:
	input_ray_pickable = false
	
func _possibly_disable_hits(exceptions: Array[Node3D]) -> void:
	if self not in exceptions:
		input_ray_pickable = false
	
func _enable_hits() -> void:
	self.input_ray_pickable = true
