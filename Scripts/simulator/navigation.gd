extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	get_node("NavRegion").bake_navigation_polygon(true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
