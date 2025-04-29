extends Predicate

class_name InRegionPredicate

func _init() -> void:
	super("in_region", ["entity", "region"])
	
func copy() -> InRegionPredicate:
	return InRegionPredicate.new()
	
func ground(new_args: Array[WorldEntity]) -> InRegionPredicate:
	self.args = new_args
	return self
	
func update_world_to_satisfy_predicate() -> Array[WorldEntity]:
	'''
	Changes the world to satisfy the given predicate.
	Subclasses should override this.
	'''
	var entity: WorldEntity = args[0]
	var region: WorldEntity = args[1]
	var target_pos: Vector3 = region.get_location()
	entity.set_location(target_pos)
	return [entity]
	
func test() -> bool:
	'''
	Tests if the predicate is true given the world.
	Subclasses should override this.
	'''
	var entity_class: String = self.args[0].entity_class
	match entity_class:
		"item":
			var entity = self.args[0].get_node("item")
			return test_helper(entity)
		"robot":
			var entity = self.args[0].get_node("robot/Robot")
			return test_helper(entity)
		"person":
			# TODO: this logic needs checked, currently copied from robot
			var entity = self.args[0].get_node("person")
			return test_helper(entity)
		"surface":
			var entities = self.args[0].get_node("surface/nodes").get_children()
			var to_return: bool = true
			for entity in entities:
				if not test_helper(entity):
					to_return = false
					break
				return to_return
	return false
	
func test_helper(entity: Node3D) -> bool:
	var region: Area = self.args[1].get_node("region")
	var nodes: Node3D = region.get_node("nodes")
	var polygon: Array[Vector2] = []
	for node in nodes.get_children():
		polygon.append(Vector2(node.position.x, node.position.y))
	return region._is_point_in_polygon(Vector2(entity.position.x, entity.position.y), polygon)
