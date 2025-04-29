extends Panel

@onready var predicate_printer := $VBoxContainer/Predicates

# Called when the node enters the scene tree for the first time.
func _ready():
	SignalBus.broadcast_world.connect(_broadcast_world_cb)
	SignalBus.broadcast_predicates.connect(_broadcast_predicates_cb)

	# resize control
	get_viewport().connect("size_changed", _on_viewport_resize)
	_on_viewport_resize()

func _broadcast_world_cb(data: Dictionary) -> void:
	predicate_printer.text = ""
	var str_predicates: Array[String] = []
	for predicate in data["predicates"]:
		str_predicates.append(_stringify_predicate(predicate["symbol"], predicate["parameters"]))
	str_predicates.sort()
	for predicate_str in str_predicates:
		predicate_printer.text += predicate_str
		
func _broadcast_predicates_cb(data: Array) -> void:
	predicate_printer.text = ""
	var str_predicates: Array[String] = []
	for pred_group in data:
		for pred_data in pred_group["parameters"]:
			str_predicates.append(_stringify_predicate(pred_group["name"], pred_data["param_tup"]))
	str_predicates.sort()
	for predicate_str in str_predicates:
		predicate_printer.text += predicate_str
			
func _stringify_predicate(name: String, params: Array):
	var predicate_str: String = name + "("
	for i in range(len(params)):
		predicate_str += str(params[i])
		if i < len(params) - 1:
			predicate_str += ", "
		else:
			predicate_str += ")\n"
	return predicate_str
			
func _input(event: InputEvent) -> void:
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_TAB:
				self.visible = not self.visible

func _on_viewport_resize() -> void:
	var vp = get_viewport()
	if vp != null:
		var vp_size = Vector2(vp.size)
		position.x = 300
		position.y = 300
