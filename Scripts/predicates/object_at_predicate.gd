extends Predicate

class_name ObjectAtPredicate

func _init() -> void:
	super("object_at", ["item", "surface"])
	
func copy() -> ObjectAtPredicate:
	return ObjectAtPredicate.new()
	
func ground(new_args: Array[WorldEntity]) -> ObjectAtPredicate:
	self.args = new_args
	return self
	
func update_world_to_satisfy_predicate() -> Array[WorldEntity]:
	'''
	Changes the world to satisfy the given predicate.
	Subclasses should override this.
	'''
	var item: WorldEntity = args[0]
	var inanimate: WorldEntity = args[1]
	var target_pos: Vector3 = inanimate.get_location()
	item.set_location(target_pos)
	return [item]
	
func test() -> bool:
	'''
	Tests if the predicate is true given the world.
	Subclasses should override this.
	'''
	# TODO: Updated to accommodate both items and surfaces for inanimate arg
	#		Need to verify it's correct for the item
	var item = self.args[0].get_node("item")
	
	var entity_class: String = self.args[1].entity_class
	match entity_class:
		"item":
			var inanimate = self.args[0].get_node("item")
			return Vector2(item.position.x, item.position.y) == Vector2(inanimate.position.x, inanimate.position.y)
		"surface":
			var inanimate: Area = self.args[1].get_node("surface")
			var nodes: Node3D = inanimate.get_node("nodes")
			var polygon: Array[Vector2] = []
			for node in nodes.get_children():
				polygon.append(Vector2(node.position.x, node.position.y))
			return inanimate._is_point_in_polygon(Vector2(item.position.x, item.position.y), polygon)

	return true
