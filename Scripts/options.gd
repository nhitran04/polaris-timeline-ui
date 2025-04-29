extends Node

var opts: Dictionary

func set_options(options: Dictionary) -> void:
	opts = options
	
func add_option(key: String, val: String) -> void:
	opts[key] = val
