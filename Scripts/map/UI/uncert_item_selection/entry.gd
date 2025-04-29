extends Panel

class_name Entry

# stored nodes
@onready var entry := $Entry
@onready var hbox := $Entry/HBox as HBoxContainer
@onready var label := $Entry/HBox/Info/Label/AreaName as Label
# @onready var percent := $Entry/HBox/Info/Label/Percent as Label
@onready var slider_nodes := $Entry/HBox/Info/HBoxContainer as HBoxContainer
@onready var slider := $Entry/HBox/Info/HBoxContainer/slider as Slider
@onready var value := $Entry/HBox/Info/HBoxContainer/Label as Label
@onready var rank_label := $Entry/HBox/Panel/Panel/Label as Label
@onready var delete_button := $Entry/Delete as Button

# parent signals
var update_probabilities
var update_masks
var update_detached_position
var reset_entries
var update_detached_rank
var reattach

# instance variables
var slider_max: float
var ent: WorldEntity
var uid: int
var area_uid: int
var dragging_slider: bool

# visualization data
var mask: Dictionary

# for dragging
var detached: bool
var cv: CanvasLayer

# for highlighting
var pane_color: Color

# Called when the node enters the scene tree for the first time.
func _ready():
	mask = {}
	add_theme_stylebox_override("panel", get_theme_stylebox("panel").duplicate())
	dragging_slider = false
	delete_button.pressed.connect(delete)
	SignalBus.delete_uncert_point.connect(_on_delete_signal)
	call_deferred("_setopts")

func _process(delta: float) -> void:
	if pane_color.r == 0.2:
		return
	var sb = StyleBoxFlat.new()
	sb.bg_color = pane_color
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	entry.add_theme_stylebox_override("panel", sb)
	pane_color = Color(pane_color.r - delta, pane_color.g - delta, 0.2, 1.0)
	if pane_color.r < 0.2:
		pane_color = Color(0.2, 0.2, 0.2, 1.0)

func _setopts() -> void:
	if Options.opts.uncert_rank:
		slider_nodes.visible = false
		# hbox.add_theme_constant_override("separation", 32)
	else:
		# rank_label.visible = false
		rank_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
		rank_label.add_theme_font_size_override("font_size", 18)

func initialize(ent: WorldEntity,
				pos: Vector3,
				area_uid: int,
				update_probs: Signal,
				update_masks: Signal,
				update_detached_position: Signal,
				reset_entries: Signal,
				update_detached_rank: Signal,
				reattach: Signal) -> void:
	self.ent = ent
	self.area_uid = area_uid
	label.text = ent.get_label() + ", " + ent.get_entity().get_abbrv() + str(self.area_uid)
	self.update_probabilities = update_probs
	self.update_masks = update_masks
	self.update_detached_position = update_detached_position
	self.reset_entries = reset_entries
	self.update_detached_rank = update_detached_rank
	self.update_detached_rank.connect(_set_detached_rank)
	self.reattach = reattach
	uid = Time.get_ticks_msec()
	create_uncert_point(pos)
	mask["center"] = ent.get_entity().global_coord_to_pixel_coord(pos)
	var tester = ent.get_entity().pixel_coord_to_global_coord(mask["center"].x, mask["center"].y)
	# print(pos)
	# print(mask["center"])
	# print(tester)
	mask["status"] = 0
	mask["value"] = 0
	slider.value = 0.5
	detached = false
	#ent.get_entity().paint(slider.value)
	_create_mask(slider.value)
	_update_masks_wrapper()
	update_probabilities.emit()
	
func initialize_existing(ent: WorldEntity,
				pos: Vector2,
				uid: int,
				area_uid: int,
				text: String,
				value: String,
				slider: float,
				update_probs: Signal,
				update_masks: Signal,
				update_detached_position: Signal,
				reset_entries: Signal,
				update_detached_rank: Signal,
				reattach: Signal) -> void:
	self.ent = ent
	self.uid = uid
	self.area_uid = area_uid
	label.text = text
	self.update_probabilities = update_probs
	self.update_masks = update_masks
	self.update_detached_position = update_detached_position
	self.reset_entries = reset_entries
	self.update_detached_rank = update_detached_rank
	self.update_detached_rank.connect(_set_detached_rank)
	self.reattach = reattach
	mask["center"] = pos
	mask["status"] = 0
	if Options.opts.uncert_sliders or Options.opts.uncert_rank:
		mask["value"] = slider
	rank_label.text = value
	detached = false
	
func create_uncert_point(pos: Vector3) -> void:
	ent.get_entity().create_uncert_point(uid, pos, self)
	
func remove_uncert_point() -> void:
	ent.get_entity().delete_uncert_point(uid)

func get_slider_val() -> float:
	return slider.value
	
func set_entry_max(val: float) -> void:
	slider_max = val
	
func _create_mask(val: float) -> void:
	return
	# uncomment below for mask painting (not needed for voronoi
	'''
	mask["mask"] = []
	for i in range(-10, 10):
		mask["mask"].append([])
		for j in range(-10, 10):
			mask["mask"][i+10].append(0.0)
			var i_reduce = i#/2.0
			var j_reduce = j#/2.0
			if i == 0 and j == 0:#abs(i) <= 1 and abs(j) <= 1:
				mask["mask"][i+10][j+10] = val
			elif Vector2(i, j).distance_to(Vector2(0, 0)) > 10:
				mask["mask"][i+10][j+10] = 0
			else:
				mask["mask"][i+10][j+10] = val/Vector2(i, j).distance_to(Vector2(0, 0))#sqrt(pow(i_reduce, 2) + pow(j_reduce, 2))
	'''

func _on_slider_value_changed(val):
	
	Logger.log_event("entry_slider_changed", {"uid": uid, "value": val})
	
	# change the slider label
	value.text = str(val)
	
	# create the mask
	_create_mask(slider.value)
	
	# update the entity based on all masks
	# _update_masks_wrapper()
	mask["value"] = val
	_update_masks_wrapper()
	
	# change color of entity
	#ent.get_entity().paint(slider.value)
	
	# update all other probabilities
	update_probabilities.emit()
	
func set_rank(rank: int, total: int) -> void:
	
	Logger.log_event("entry_rank_changed", {"uid": uid, "rank": rank, "total": total})
	
	# This method is costly. Don't do anything
	# if we don't have to.
	if rank_label.text == str(rank):
		return
	rank_label.text = str(rank)
	var val: float = 0.0
	# use the ranking system below if using different colors
	'''
	if total > 0:
		val = 1.0
	if total > 1:
		val = (total - rank)*1.0/(total - 1)
		if val == 0:
			val = 0.01
	'''
	# use the ranking system below if using mono-colors
	val = (total - (rank - 1))*1.0/total
	# ent.get_entity().paint(val)
	mask["value"] = val
	if detached:
		_update_detached_mask_wrapper()
	else:
		_update_masks_wrapper()
	set_uncert_label()
	
func _set_detached_rank(rank: int, total: int) -> void:
	if not detached:
		return
	set_rank(rank, total)
	
func set_uncert_label() -> void:
	if Options.opts.uncert_sliders:
		ent.get_entity().set_uncert_label(uid, ent.get_entity().get_abbrv() + str(area_uid))
		ent.get_entity().set_uncert_label_size(uid, 128)
	else:
		ent.get_entity().set_uncert_label(uid, rank_label.text)
	
func set_percent_text(percent: String) -> void:
	self.rank_label.text = percent
	ent.get_entity().set_uncert_percent_label(uid, percent)

'''	
func show_percent() -> void:
	percent.show()
	
func hide_percent() -> void:
	percent.hide()
'''
	
func _on_delete_signal(uid: int) -> void:
	if self.uid == uid:
		delete()
	
func delete() -> void:
	Logger.log_event("entry_delete", {"uid": uid})
	if detached:
		_delete_by_dragging_away()
	else:
		_delete_from_param_list()
	ent.get_entity().delete_uncert_point(uid)
	update_probabilities.emit()
	_update_masks_wrapper()
	reset_entries.emit()
	
func _delete_from_param_list() -> void:
	'''First method of deletion is to simply delete from the list'''
	get_parent().remove_child(self)
	queue_free()
	
func _delete_by_dragging_away() -> void:
	'''Second method of deletion is by dragging outside of param panel'''
	cv.get_parent().remove_child(cv)
	cv.queue_free()
	
func update_mask_location(new_pos: Vector3) -> void:
	ent.get_entity().move_uncert_point(uid, new_pos)
	mask["center"] = ent.get_entity().global_coord_to_pixel_coord(new_pos)
	_update_masks_wrapper()
	
func _update_masks_wrapper() -> void:
	var changes: Array = []
	changes.append(mask)
	update_masks.emit(ent, changes, false)
	
func _update_detached_mask_wrapper() -> void:
	var changes: Array = []
	changes.append(mask)
	update_masks.emit(ent, changes, true)
	
func highlight() -> void:
	pane_color = Color(1.0, 1.0, 0.2, 1.0)

func _on_gui_input(event):
	if event is InputEventScreenDrag and not dragging_slider:# InputEventMouseButton and event.is_action_pressed("click"):
		var gp: Vector2 = global_position
		cv = CanvasLayer.new()
		cv.layer = 2
		var root: Viewport = get_tree().root
		get_parent().remove_child(self)
		cv.add_child(self)
		self.mouse_filter = Control.MOUSE_FILTER_STOP
		root.get_child(0).add_child(cv)
		global_position = gp
		detached = true

func _input(event: InputEvent) -> void:
	if detached:
		# set position
		position = event.position - Vector2(25, 25)
		
		# send signal to parent with position
		update_detached_position.emit(event.position)
		
		# handle click release -- possible reposition or deletion
		if event is InputEventMouseButton and event.is_action_released("click"):
			detached = false
			reattach.emit(self, event.position)
		
func _on_slider_drag_started():
	dragging_slider = true
	mask["status"] = 1
	_update_masks_wrapper()

func _on_slider_drag_ended(value_changed):
	dragging_slider = false
	mask["status"] = 0
	_update_masks_wrapper()
