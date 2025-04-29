extends Panel

var _action_scene := load("res://Scenes/PlanVisualizer/action.tscn")
var _checkpoint_scene := load("res://Scenes/PlanVisualizer/checkpoint.tscn")

@onready var scrubber := $Scrubber
@onready var scroller := $PlanScroll
@onready var plan_scroll := $PlanScroll/ActionContainer

@export var world_db: WorldDatabase

# instance vars
var scrolling: bool
var pad_start: Panel
var pad_end: Panel
var map_to_pv: Dictionary
var pv_elements: Array[Control]

# Called when the node enters the scene tree for the first time.
func _ready():
	SignalBus.set_plan_vis_focus.connect(_focus_on_action)
	scrolling = false
	map_to_pv = {}
	get_viewport().connect("size_changed", _on_viewport_resize)
	_on_viewport_resize()
	
func _process(delta):
	if scrolling:
		_highlight_action()
	
func _pad_scroll() -> Panel:
	var padding = Panel.new()
	plan_scroll.add_child(padding)
	padding.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color =  Color.TRANSPARENT
	padding.add_theme_stylebox_override("panel", style)
	padding.custom_minimum_size.x = _calculate_padding_size()
	return padding
	
func _calculate_padding_size() -> float:
	return size.x/2.0 - plan_scroll.get_theme_constant("separation")
	
func set_plan(elements: Array[Control]) -> void:
	map_to_pv = {}
	pv_elements.clear()
	
	# clear existing plan actions
	for n in plan_scroll.get_children():
		remove_child(n)
		n.queue_free()
	
	# create timeline objects
	pad_start = _pad_scroll()
	for element in elements:
		var pv_element: PlanVisElement
		if element is InitCheckpoint:
			pv_element = _action_scene.instantiate()
			plan_scroll.add_child(pv_element)
			pv_element.set_action_name("Start")
			pv_element.set_action_desc("")
		elif element is Checkpoint:
			pv_element = _checkpoint_scene.instantiate()
			plan_scroll.add_child(pv_element)
			pv_element.get_node("Panel/Label").text = str(element.id)
		else:
			pv_element = _action_scene.instantiate()
			plan_scroll.add_child(pv_element)
			pv_element.set_action_name(element.action_name)
			pv_element.set_action_desc(element.action_desc)
			map_to_pv[element] = pv_element
		var element_final_state = world_db.get_predicates_from_json_array(element.final_state)
		pv_element.set_final_state(element_final_state)
		pv_elements.append(pv_element)
	pad_end = _pad_scroll()
	
	# populate timeline objects with final state world snapshot
	pv_elements[0].world_snapshot = world_db.get_entity_positions()
	for i in range(1, len(pv_elements)):
		pv_elements[i].world_snapshot = pv_elements[i-1].world_snapshot.duplicate()
		var diff = world_db.diff(pv_elements[i].final_state, pv_elements[i-1].final_state)
		pv_elements[i].update_world_snapshot(diff)

func _focus_on_action(focus: Control):
	var pv_el = map_to_pv[focus]
	var idx = pv_elements.find(pv_el)
	var sep = plan_scroll.get_theme_constant("separation")
	var offset = 0.0
	for el in pv_elements:
		if el == pv_el:
			break
		offset += el.size.x + sep
	scroller.set_deferred("scroll_horizontal", offset + pv_el.size.x/2.0)
	_highlight(pv_el)

func _highlight_action() -> void:
	# determine which action overlaps with the scrubber
	for child in plan_scroll.get_children():
		if child != pad_start and child != pad_end:
			child.unhighlight()
			var posx = child.position.x - scroller.scroll_horizontal
			if posx <= scrubber.position.x:
				if posx + child.size.x >= scrubber.position.x:
					_highlight(child)
					
func _highlight(element: PlanVisElement) -> void:
	element.highlight()
	element.load_world_snapshot()

func _on_viewport_resize():
	var vp = get_viewport()
	if vp != null:
		var vp_size = Vector2(vp.size)
		size.x = vp_size.x
		size.y = 200
		position.x = 0
		position.y = get_viewport().size.y - 200
		scroller.size.x = size.x
		scroller.size.y = 180
		scroller.position.x = 0
		scroller.position.y = 10
		scrubber.position.x = size.x/2.0
		scrubber.position.y = 0
		if pad_start != null and pad_end != null:
			pad_start.custom_minimum_size.x = _calculate_padding_size()
			pad_end.custom_minimum_size.x = _calculate_padding_size()

func _on_plan_scroll_started():
	scrolling = true

func _on_plan_scroll_ended():
	scrolling = false
