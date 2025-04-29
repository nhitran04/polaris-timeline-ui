extends Predicate

class_name IsFullPredicate

func _init() -> void:
	super("is_full", ["cup"])
	
func copy() -> IsFullPredicate:
	return IsFullPredicate.new()
	
func ground(new_args: Array[WorldEntity]) -> IsFullPredicate:
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
