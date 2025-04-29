extends Predicate

class_name OwnsGripperPredicate

func _init() -> void:
	super("owns_gripper", ["agent", "end_effector"])
	
func copy() -> OwnsGripperPredicate:
	return OwnsGripperPredicate.new()
	
func ground(new_args: Array[WorldEntity]) -> OwnsGripperPredicate:
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
	# TODO: not implemented
	return true
