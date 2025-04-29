class_name Predicate

# instance variables
var symbol: String
var arg_types: Array[String]
var args: Array[WorldEntity]

func _init(new_symbol: String,
		   new_arg_types: Array[String]) -> void:
	self.symbol = new_symbol
	self.arg_types = new_arg_types

func copy() -> Predicate:
	return Predicate.new(self.symbol, self.arg_types)

func ground(new_args: Array[WorldEntity]) -> Predicate:
	self.args = new_args
	return self

func get_str_parameters() -> Array[String]:
	var to_return: Array[String] = [] 
	for arg in args:
		to_return.append(arg.get_label())
	return to_return

func is_arg(we: WorldEntity) -> bool:
	return we in self.args
	
func update_world_to_satisfy_predicate() -> Array[WorldEntity]:
	'''
	Changes the world to satisfy the given predicate.
	Subclasses should override this.
	'''
	return []

func test() -> bool:
	'''
	Tests if the predicate is true given the world.
	Subclasses should override this.
	'''
	return true

func is_conflicting(other: Predicate) -> bool:
	'''
	Simple test for conflict. Conflict is defined as:
		- pred1 and pred2 have the same symbol
		- pred 1 and pred2 do not have the same arguments
	'''
	if args == null:  # must be ground
		return false
	if symbol == other.symbol:
		var conflict = false
		for i in range(len(args)):
			if args[i] != other.args[i]:
				conflict = true
				break
		return conflict
	return false
