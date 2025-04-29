extends VBoxContainer

# no initialization
@onready var item_list := $Top/UncertItemSelection/OptionButton as OptionButton
@onready var label := $Top/UncertItemSelection/HBoxContainer/Label as Label
@onready var viewport := $Top/UncertItemSelection/HBoxContainer/SubViewportContainer/SubViewport as SubViewport
@onready var paint_button := $Top/Mode/HBoxContainer/Paint as Button
@onready var erase_button := $Top/Mode/HBoxContainer/Erase as Button
@onready var param_panel := $ParamPanel as Panel

# 3D objects
# var cup_scene := load("res://Scenes/3D/cup.tscn")
# var plate_scene := load("res://Scenes/3D/plate.tscn")
# var bowl_scene := load("res://Scenes/3D/bowl.tscn")
var bag_scene := load("res://Scenes/3D/bag.tscn")
var umbrella_scene := load("res://Scenes/3D/umbrella_small.tscn")

# icons
var paint_icon := load("res://Assets/img/paint_icon-01.png")
var erase_icon := load("res://Assets/img/eraser_icon-01.png")
var paint_icon_toggled := load("res://Assets/img/paint_icon_toggled-01.png")
var erase_icon_toggled := load("res://Assets/img/eraser_icon_toggled-01.png")
var untoggled_theme := load("res://Resources/themes/uncert/paint_and_erase_untoggled.tres")

# textures for button items
var objs: Array[Node3D]
var texts: Array[String]

# instance variables
var selected_obj: Node3D

# experimentation
var paint_status: Dictionary

# Called when the node enters the scene tree for the first time.
func _ready():
	SignalBus.set_curr_item.connect(_set_curr_item)
	item_list.get_popup().transparent_bg = true
	var bag = bag_scene.instantiate()
	var umbrella = umbrella_scene.instantiate()
	objs = [umbrella, bag]
	texts = ["umbrella", "bag"]
	paint_status = {
		"umbrella": false,
		"bag": false
	}

	selected_obj = objs[0]
	viewport.add_child(selected_obj)
	label.text = texts[0]
	
	# mode
	paint_button.pressed.connect(_toggle_paint)
	erase_button.pressed.connect(_toggle_erase)
	SignalBus.just_painted.connect(_on_just_painted)
	paint_button.icon = paint_icon_toggled
	
	# untoggle erase
	erase_button.theme = untoggled_theme
	
	# activate/deactivate different subpanels based on options
	call_deferred("_setopt")

	# resize control
	_on_viewport_resize()
	
func _set_curr_item(item: String) -> void:
	viewport.remove_child(selected_obj)
	if item == "umbrella":
		var umbrella = umbrella_scene.instantiate()
		texts = ["umbrella"]
		paint_status = {
			"umbrella": false
		}
		selected_obj = umbrella
		viewport.add_child(selected_obj)
		label.text = "umbrella"
	else:
		var bag = bag_scene.instantiate()
		texts = ["bag"]
		paint_status = {
			"bag": false
		}
		selected_obj = bag
		viewport.add_child(selected_obj)
		label.text = "bag"
	select_and_show()
	SignalBus.send_to_parent_html_frame.emit("currItem", item)
	
func _setopt() -> void:
	if not Options.opts.uncert_paint:
		paint_button.visible = false
		erase_button.visible = false

func _toggle_paint() -> void:
	Logger.log_event("toggled_paint", {})
	SignalBus.enter_uncert_paint_mode.emit()
	paint_button.theme = null
	erase_button.theme = untoggled_theme
	paint_button.icon = paint_icon_toggled
	erase_button.icon = erase_icon

func _toggle_erase() -> void:
	Logger.log_event("toggled_erase", {})
	SignalBus.enter_uncert_erase_mode.emit()
	erase_button.theme = null
	paint_button.theme = untoggled_theme
	paint_button.icon = paint_icon
	erase_button.icon = erase_icon_toggled
	
func select_and_show() -> void:
	show()
	SignalBus.select_uncert_item.emit(texts[
		item_list.get_item_index(
			item_list.get_selected_id()
		)
	])
	
func _item_selected(idx: int) -> void:
	viewport.remove_child(selected_obj)
	selected_obj = objs[idx]
	viewport.add_child(selected_obj)
	label.text = texts[idx]
	_toggle_paint()
	select_and_show()
	
func _on_just_painted() -> void:
	paint_status[texts[item_list.get_item_index(item_list.get_selected_id())]] = true
	
func get_item_lists() -> Dictionary:
	var item_lists = param_panel.get_item_lists()
	# ensure all items are included
	for text in texts:
		if text not in item_lists:
			item_lists[text] = []
	return item_lists
	
func get_paint_status() -> Dictionary:
	return paint_status

func _on_viewport_resize():
	position.x = 60
	position.y = 60	

func _on_option_button_toggled(toggled_on):
	_toggle_paint()
