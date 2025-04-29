extends Node

var domain: Dictionary
var type_tree: Dictionary


# Called when the node enters the scene tree for the first time.
func _ready():
	# create a temporary type tree
	self.type_tree = {"world": ["region", "nonregion"],
					  "nonregion": ["agent", "item", "surface"],
					  "agent": ["person", "robot"]}

func add_domain(domain: Dictionary):
	self.domain = domain
	print(self.domain)
	self.type_tree = {}
	self._assemble_type_tree("world")
	
func _assemble_type_tree(root: String) -> void:
	self.type_tree[root] = []
	for type_data in self.domain.types:
		if type_data._type == root:
			for subtype in type_data.subtypes:
				self.type_tree[root].append(subtype)
				_assemble_type_tree(subtype)

func get_predicates() -> Array[String]:
	var predicates: Array[String] = []
	for pred in self.domain.predicates:
		if pred.hidden:
			continue
		if pred.name == "no_change":
			predicates.insert(0, pred.name)
		else:
			predicates.append(pred.name)
	return predicates
	
func get_pred(pred_name: String) -> Dictionary:
	return get_data_helper(pred_name, self.domain.predicates)
	
func get_pred_nl(pred_name: String) -> String:
	return get_nl_helper(pred_name, self.domain.predicates)
	
func get_actions() -> Array[String]:
	var actions: Array[String] = []
	for action in self.domain.operators:
		actions.append(action.name)
	return actions
	
func get_action(action_name: String) -> Dictionary:
	return get_data_helper(action_name, self.domain.operators)
	
func get_action_nl(action_name: String) -> String:
	return get_nl_helper(action_name, self.domain.operators)
	
func get_data_helper(_name : String, domain_array : Array) -> Dictionary:
	var data: Dictionary
	for i in domain_array:
		if i.name == _name:
			data = i
			break
	return data
	
func get_nl_helper(_name : String, domain_array : Array) -> String:
	var nl = ""
	for i in domain_array:
		if i.name == _name:
			if "nl" in i:
				nl = i.nl
			else:
				for j in len(i.parameters):
					nl += "[arg%s]" % str(j+1)
				nl = nl.strip_edges()
	return nl
	
func get_type_and_subtypes(type: String) -> Array[String]:
	var to_return: Array[String] = []
	if type in self.type_tree:
		_get_type_and_subtypes_helper(type, to_return)
	return to_return
	
func _get_type_and_subtypes_helper(type: String, types: Array[String]) -> void: 
	types.append(type)
	if type not in self.type_tree:
		return
	for subtype in self.type_tree[type]:
		_get_type_and_subtypes_helper(subtype, types)

func get_subtypes(type: String) -> Array[String]:
	var to_return: Array[String] = []
	if type not in self.type_tree:
		return to_return
	for subtype in self.type_tree[type]:
		_get_type_and_subtypes_helper(subtype, to_return)
	return to_return
