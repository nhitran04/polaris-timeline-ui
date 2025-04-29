extends Node

var register: Array[int]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	register = []

func register_new_id() -> int:
	register.sort()
	var i = 0
	for id in register:
		if i != id:
			break
		i += 1
	register.append(i)
	return i
	
func deregister_old_id(id: int) -> void:
	register.erase(id)
