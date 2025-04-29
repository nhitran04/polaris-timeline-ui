extends Panel

# stored objs
@onready var scroll := $VBoxContainer/ScrollContainer as ScrollContainer
@onready var entries := $VBoxContainer/ScrollContainer/Entries as VBoxContainer
@onready var status_icon := $VBoxContainer/Status/PanelContainer as PanelContainer
@onready var status_label := $VBoxContainer/Status/Label as Label
@onready var normalize_button := $VBoxContainer/Button as Button

# exported vars
@export var db: WorldDatabase

# scenes to be instantiated
var entry_scene := load("res://Scenes/map/uncert_item_selection/entry.tscn")

# instance variables
var _item_lists: Dictionary
var _curr_item: String

# local signals
signal update_probabilities
signal update_masks(ent: WorldEntity, changes: Array, include_changes: bool)
signal update_detached_position(pos: Vector2)
signal reset_entries
signal update_detached_rank(rank: int, total: int)
signal reattach(entry: Panel, pos: Vector2)

# Called when the node enters the scene tree for the first time.
func _ready():
	SignalBus.uncert_new_slider.connect(_drop_label)
	SignalBus.select_uncert_item.connect(_select_uncert_item)
	SignalBus.update_uncert_point_position.connect(_on_update_uncert_point_position)
	SignalBus.highlight_uncert_entry.connect(_on_highlight_uncert_entry)
	SignalBus.reset_param_panel.connect(_clear_all)
	# normalize_button.pressed.connect(_normalize)
	update_probabilities.connect(_on_update_probabilities)
	update_masks.connect(_on_update_masks)
	update_detached_position.connect(_on_update_detached_position)
	reset_entries.connect(_reset_entries)
	reattach.connect(_reattach_entry)
	
	call_deferred("_setopt")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _setopt() -> void:
	if Options.opts.uncert_paint:
		visible = false

func _add_button_pressed() -> void:
	pass
	
func _drop_label(area_ent: WorldEntity, pos: Vector3, wp_text: String) -> void:
	# check if pos is within bounds of param panel
	#if pos.x > global_position.x and pos.x < global_position.x + size.x:
	#	if pos.y > global_position.y and pos.y < global_position.y + size.y:
	#		_add_param(area_text)
	_add_param(area_ent, pos, wp_text)
			
func _add_param(area_ent: WorldEntity, pos: Vector3, wp_text: String) -> void:
	var ent: WorldEntity
	for candidate_ent in db.world_entities:
		if candidate_ent == area_ent:
			ent = candidate_ent
			break
	var entry = entry_scene.instantiate()
	entries.add_child(entry)
	_parameterize_entry(entry, ent, pos, wp_text)
	
func _parameterize_entry(entry: Control,
						 ent: WorldEntity,
						 pos: Vector3,
						 wp_text: String) -> void:
	'''
	Need to initialize entries with:
	- the relevant world entity
	- the name of the entry (it can't just be the entity label)
	- the position of the entry
	- the signal to update all entries' probabilities
	'''
	var area_uid: int = 1
	for i in range(len(entries.get_children())):
		var area_uid_exists: bool = false
		for existing_entry in entries.get_children():
			if existing_entry.ent == ent:
				if existing_entry.area_uid == area_uid:
					area_uid_exists = true
					area_uid += 1
			elif entry != existing_entry:
				if ent.get_entity().get_abbrv() + str(area_uid) == existing_entry.ent.get_entity().get_abbrv() + str(existing_entry.area_uid):
					area_uid_exists = true
					area_uid += 1
		if not area_uid_exists:
			break
	entry.initialize(ent, pos, area_uid,
					 update_probabilities,
					 update_masks,
					 update_detached_position,
					 reset_entries,
					 update_detached_rank,
					 reattach)
					
func add_existing(ent, pos, uid, area_uid, text, value_label, slider, item) -> void:
	var entry = entry_scene.instantiate()
	entries.add_child(entry)
	entry.initialize_existing(ent, pos, uid, area_uid, text, value_label, slider,
						update_probabilities,
						update_masks,
						update_detached_position,
						reset_entries,
						update_detached_rank,
						reattach
	)
	entry.create_uncert_point(entry.ent.get_entity().pixel_coord_to_global_coord(entry.mask["center"].x, entry.mask["center"].y))
	if item not in _item_lists:
		_item_lists[item] = []
	_item_lists[item].append(entry)
	#entries.remove_child(entry)
	#entry.remove_uncert_point()
	
func paint_all(item: String) -> void:
	_select_uncert_item(item)
	for entry in entries.get_children():
		if Options.opts.uncert_rank:
			var total = len(entries.get_children())
			var rank = float(entry.rank_label.text)
			var val = (total - (rank - 1))*1.0/total
			# ent.get_entity().paint(val)
			entry.mask["value"] = val
			entry._update_masks_wrapper()
			entry.set_uncert_label()
		else:
			entry.slider.value = entry.mask["value"]

func _show_status(val: bool) -> void:
	'''
	Use this method to display a status message at the bottom of the
	param pane.
	'''
	pass
	# status_icon.visible = val
	# status_label.visible = val

func _on_update_probabilities() -> void:
	# update the slider 'max'
	# (i.e., how much unspecified probability is left)
	if Options.opts.uncert_sliders:
		_normalize()
		for entry in entries.get_children():
			entry.set_uncert_label()
	elif Options.opts.uncert_rank:
		var rank: int = 1
		for entry in entries.get_children():
			entry.set_rank(rank, len(entries.get_children()))
			rank += 1
			
func _on_update_masks(ent: WorldEntity,
					  changes: Array,
					  include_changes: bool) -> void:
	var draw_list: Array = []
	for entry in entries.get_children():
		if entry.ent == ent:
			draw_list.append(entry.mask)
	if include_changes:
		for change in changes:
			draw_list.append(change)
	ent.get_entity().paint_masks(draw_list, changes)
	
func sum_sliders_for_item(item: String) -> float:
	if _curr_item != item:
		print("WARNING: computing slider values for a different item than intended!")
	var total: float = 0
	for entry in entries.get_children():
		total += entry.get_slider_val()
	return total
		
func _normalize() -> void:
	var total: float = 0
	for entry in entries.get_children():
		total += entry.get_slider_val()
	for entry in entries.get_children():
		if total <= 1.0:
			entry.set_percent_text(str(100 * entry.get_slider_val()) + "%")
		else:
			entry.set_percent_text(str(int(round(100 * (entry.get_slider_val()/total)))) + "%")
	_show_status(false)
	
func _select_uncert_item(str: String) -> void:
	# store old entries if applicable
	if _curr_item != null and _curr_item in _item_lists:
		_item_lists[_curr_item].clear()
		for entry in entries.get_children():
			_item_lists[_curr_item].append(entry)
	_curr_item = str
	
	# depopulate entries
	var to_remove: Array = []
	for entry in entries.get_children():
		to_remove.append(entry)
	for entry in to_remove:
		entries.remove_child(entry)
		entry.remove_uncert_point()
	
	if str not in _item_lists:
		_item_lists[str] = []
	else:
		# repopulate entries
		for entry in _item_lists[str]:
			entries.add_child(entry)
			entry.create_uncert_point(entry.ent.get_entity().pixel_coord_to_global_coord(entry.mask["center"].x, entry.mask["center"].y))
			entry.set_uncert_label()

func _on_update_detached_position(pos: Vector2) -> void:
	_reset_entry_borders()
	if len(entries.get_children()) == 0:
		return
	if _is_pos_outside_panel(pos):
		_reset_entries()
		return
	
	# determine which existing entries are above and below
	var surrounding_entries = _get_surrounding_entries(pos)
	var above_entry: Panel = surrounding_entries["above"]
	var below_entry: Panel = surrounding_entries["below"]
	
	# set the ranks
	if Options.opts.uncert_rank:
		var rank_inc = 1
		for i in range(len(entries.get_children())):
			var entry: Panel = entries.get_children()[i]
			if entry == below_entry:
				update_detached_rank.emit(i+1, len(entries.get_children()) + 1)
				rank_inc += 1
			entry.set_rank(i+rank_inc, len(entries.get_children()) + 1)
		if rank_inc == 1:
			update_detached_rank.emit(len(entries.get_children()) + 1, len(entries.get_children()) + 1)
	
	# set panel outlines
	if above_entry != null:
		above_entry.get_theme_stylebox("panel").border_width_bottom = 2
		if below_entry == null:
			above_entry.get_theme_stylebox("panel").border_width_bottom = 4
	if below_entry != null:
		below_entry.get_theme_stylebox("panel").border_width_top = 2
		if above_entry == null:
			below_entry.get_theme_stylebox("panel").border_width_top = 4

func _reattach_entry(entry: Panel, pos: Vector2) -> void:
	if _is_pos_outside_panel(pos):
		entry.delete()
		return
	entry.mouse_filter = Control.MOUSE_FILTER_PASS
	entry.get_parent().remove_child(entry)
	var surrounding_entries = _get_surrounding_entries(pos)
	var above_entry: Panel = surrounding_entries["above"]
	var below_entry: Panel = surrounding_entries["below"]
	var entry_list: Array[Panel] = []
	for existing_entry in entries.get_children():
		entry_list.append(existing_entry)
	for existing_entry in entry_list:
		entries.remove_child(existing_entry)
	var added_entry: bool = false
	for existing_entry in entry_list:
		if existing_entry == below_entry:
			entries.add_child(entry)
			added_entry = true
		entries.add_child(existing_entry)
	if not added_entry:
		entries.add_child(entry)
	_reset_entries()
	
func _is_pos_outside_panel(pos: Vector2) -> bool:
	if pos.x < global_position.x or pos.x > global_position.x + size.x:
		return true
	if pos.y < global_position.y or pos.y > global_position.y + size.y:
		return true
	return false
	
func _get_surrounding_entries(pos: Vector2) -> Dictionary:
	var above_entry: Panel
	var below_entry: Panel = entries.get_children()[0]
	if pos.y > below_entry.global_position.y + below_entry.size.y/2.0:
		var found_position: bool
		for i in range(len(entries.get_children()) - 1):
			var entry: Panel = entries.get_children()[i]
			var next_entry: Panel = entries.get_children()[i+1]
			var mp: float = entry.global_position.y + entry.size.y/2.0
			var next_mp: float = next_entry.global_position.y + next_entry.size.y/2.0
			if pos.y > mp and pos.y <= next_mp:
				above_entry = entry
				below_entry = next_entry
				found_position = true
		if not found_position:
			above_entry = entries.get_children()[len(entries.get_children()) - 1]
			below_entry = null
	var surrounding = {
		"above": above_entry,
		"below": below_entry
	}
	return surrounding

func _reset_entries() -> void:
	for i in range(len(entries.get_children())):
		var entry: Panel = entries.get_children()[i]
		if Options.opts.uncert_rank:
			entry.set_rank(i+1, len(entries.get_children()))
			update_detached_rank.emit(0, len(entries.get_children()) + 1)
		entry.get_theme_stylebox("panel").border_width_top = 0
		entry.get_theme_stylebox("panel").border_width_bottom = 0

func _reset_entry_borders() -> void:
	for i in range(len(entries.get_children())):
		var entry: Panel = entries.get_children()[i]
		entry.get_theme_stylebox("panel").border_width_top = 0
		entry.get_theme_stylebox("panel").border_width_bottom = 0
		
func _on_update_uncert_point_position(uid: int, pos: Vector3) -> void:
	'''Update if not too close to other entries'''
	var entry: Entry
	var masks: Array = []
	for existing_entry in entries.get_children():
		if existing_entry.uid == uid:
			entry = existing_entry
			break
	var pix_coord: Vector2 = entry.ent.get_entity().global_coord_to_pixel_coord(pos)
	var crossing_entry_bounds: bool = false
	for existing_entry in entries.get_children():
		if existing_entry != entry:
			if existing_entry.ent == entry.ent:
				masks.append(existing_entry.mask)
				if pix_coord.distance_to(existing_entry.mask["center"]) <= 40:
					crossing_entry_bounds = true
					break
	if crossing_entry_bounds:
		return
	entry.ent.get_entity().paint_masks(masks, [entry.mask])
	entry.update_mask_location(pos)
	
func _on_highlight_uncert_entry(uid: int) -> void:
	var entry: Entry
	for existing_entry in entries.get_children():
		if existing_entry.uid == uid:
			entry = existing_entry
			break
	entry.highlight()
	scroll.scroll_vertical = entry.position.y
	
func get_item_lists() -> Dictionary:
	# ensure that the item lists are up-to-date
	_item_lists[_curr_item].clear()
	for entry in entries.get_children():
		_item_lists[_curr_item].append(entry)
	
	# then return
	return _item_lists
	
func _clear_all() -> void:
	var to_remove: Array = []
	for entry in entries.get_children():
		to_remove.append(entry)
	for entry in to_remove:
		entries.remove_child(entry)
		entry.remove_uncert_point()
	_item_lists = {}

func _on_scroll_container_mouse_entered():
	SignalBus.lock_3D_camera_zoom.emit(true)

func _on_scroll_container_mouse_exited():
	SignalBus.lock_3D_camera_zoom.emit(false)
	scroll.scroll_vertical = scroll.scroll_vertical
