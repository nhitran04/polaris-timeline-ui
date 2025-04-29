extends Predicate

class_name AgentNearPredicate

var CLOSE_DIST := 2.2

func _init() -> void:
	super("agent_near", ["agent", "entity"])
	
func copy() -> AgentNearPredicate:
	return AgentNearPredicate.new()
	
func ground(new_args: Array[WorldEntity]) -> AgentNearPredicate:
	self.args = new_args
	return self
	
func update_world_to_satisfy_predicate() -> Array[WorldEntity]:
	'''
	Changes the world to satisfy the given predicate.
	Subclasses should override this.
	'''
	var agent: WorldEntity = args[0]
	var entity: WorldEntity = args[1]
	var target_pos: Vector3 = entity.get_location()
	agent.set_location(target_pos)
	return [agent]
	
func test() -> bool:
	'''
	Tests if the predicate is true given the world.
	Subclasses should override this.
	'''
	var agent_class: String = self.args[0].entity_class
	var agent: Node3D
	match agent_class:
		"robot":
			agent = self.args[0].get_node("robot/Robot")
		"person":
			agent = self.args[0].get_node("person")

	var agent_pos = Vector2(agent.position.x, agent.position.y)

	var entity_class: String = self.args[1].entity_class
	match entity_class:
		"item":
			var entity = self.args[1].get_node("item")
			return CLOSE_DIST > _distance(Vector2(agent_pos),
										  Vector2(entity.position.x, entity.position.y))
		"person":
			# TODO: this logic needs to be checked, copied from item currently
			var person = self.args[1].get_node("person")
			return CLOSE_DIST > _distance(Vector2(agent_pos),
										  Vector2(person.position.x, person.position.y))
		"surface":
			var surface: Area = self.args[1].get_node("surface")
			var nodes: Node3D = surface.get_node("nodes")
			var polygon: Array[Vector2] = []
			for node in nodes.get_children():
				polygon.append(Vector2(node.position.x, node.position.y))
			var closest: int = 0
			var closest_dist: float = -1.0
			var is_close: bool = false
			for i in range(len(polygon)):
				var vert = polygon[i]
				var dist: float = _distance(agent_pos, vert)
				if closest_dist < 0 or dist < closest_dist:
					closest = i
					closest_dist = dist
				if closest_dist > 0 and closest_dist <= CLOSE_DIST:
					is_close = true
			if not is_close:
				# calculate distance to closest edges
				var vert: Node3D = nodes.get_children()[closest]
				var prev_vert: Node3D
				var next_vert: Node3D
				if closest == 0:
					prev_vert = nodes.get_children()[-1]
					next_vert = nodes.get_children()[closest+1]
				elif closest == len(nodes.get_children()) - 1:
					prev_vert = nodes.get_children()[closest-1]
					next_vert = nodes.get_children()[0]
				else:
					prev_vert = nodes.get_children()[closest-1]
					next_vert = nodes.get_children()[closest+1]
				var v1 = Vector2(prev_vert.position.x, prev_vert.position.y)
				var v2 = Vector2(vert.position.x, vert.position.y)
				var v3 = Vector2(next_vert.position.x, next_vert.position.y)
				if _distance(v2, v1) > _distance(agent_pos, v1):
					if _distance_from_line(v2, v1, agent_pos) <= CLOSE_DIST:
						is_close = true
				if _distance(v2, v3) > _distance(agent_pos, v3):
					if _distance_from_line(v2, v3, agent_pos) <= CLOSE_DIST:
						is_close = true
			return is_close
	return false

func _distance(a: Vector2, b: Vector2) -> float:
	return sqrt((b.x - a.x)**2 + (b.y - a.y)**2)

func _distance_from_line(l1: Vector2, l2: Vector2, pt: Vector2) -> float:
	var num_left = (l2.x - l1.x) * (l1.y - pt.y)
	var num_right = (l1.x - pt.x) * (l2.y - l1.y)
	var den_sq = (l2.x - l1.x)**2 + (l2.y - l1.y)**2
	return abs(num_left - num_right)/sqrt(den_sq)
