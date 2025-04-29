extends Predicate

class_name AgentHasPredicate

func _init() -> void:
	super("agent_has", ["agent", "item"])
	
func copy() -> AgentHasPredicate:
	return AgentHasPredicate.new()
	
func ground(new_args: Array[WorldEntity]) -> AgentHasPredicate:
	self.args = new_args
	return self
	
func update_world_to_satisfy_predicate() -> Array[WorldEntity]:
	'''
	Changes the world to satisfy the given predicate.
	Subclasses should override this.
	'''
	# TODO: not impelemted
	return []

func test() -> bool:
	'''
	Tests if the predicate is true given the world.
	Subclasses should override this.
	'''
	# TODO: not impelemted
	return false
