extends Node

class_name WorldDatabase

# store the map
@export var map: Node3D
@export var uncert_param_panel: Panel 

# Array[worldentity]
var world_entities: Array[WorldEntity]

# Dictionary[worldentity] = type
var entities: Dictionary
var regions: Dictionary
var surfaces: Dictionary

# Dictionary[worldentity] = Array[object]
var typed_objects: Dictionary

# if an object of a particular type changes in some way,
# that change will trigger an evaluation of all possible predicates that can
# involve that type
# if a region is added or the bounds of region "home" change and 
#   agent_in(agent, region) and object_in(object, region) are predicates:
# 1) remove all current instances of agent/object_in(?, "home")
# 2) re-evaluate:
#   agent_in(agent ?a, "home")? agent_in(agent ?b, "home")?
#   object_in(item ?a, "home")? object_in(item ?b, "home")?
var predicates: Array[Predicate]

# Called when the node enters the scene tree for the first time.
func _ready():
	entities = Dictionary()
	regions = Dictionary()
	surfaces = Dictionary() 
	typed_objects = Dictionary()
	predicates = []
	
	SignalBus.reset_world.connect(_reset_world)
	SignalBus.reset_predicates.connect(_reset_predicates)
	SignalBus.deactivate_uncert_mode.connect(_get_uncertainty)
	SignalBus.participant_is_done.connect(_dump_results)
	
func add_robot(robot: WorldEntity, type: String):
	entities[robot] = type
	if type not in typed_objects:
		typed_objects[type] = Array()
	typed_objects[type].append(robot)
	_create_robot_predicates(robot)
	world_entities.append(robot)
	robot.get_node("robot/gripper").add_end_effector()
	_add_end_effector(robot.get_node("robot/gripper"), "end_effector")
	broadcast_world()
	
func _add_end_effector(end_effector: WorldEntity, type: String):
	entities[end_effector] = type
	if type not in typed_objects:
		typed_objects[type] = Array()
	typed_objects[type].append(end_effector)
	_create_end_effector_predicates(end_effector)
	broadcast_world()
	
func add_item(item: WorldEntity, type: String):
	entities[item] = type
	if type not in typed_objects:
		typed_objects[type] = Array()
	typed_objects[type].append(item)
	_create_item_predicates(item)
	world_entities.append(item)
	broadcast_world()

func add_person(person: WorldEntity, type: String):
	entities[person] = type
	if type not in typed_objects:
		typed_objects[type] = Array()
	typed_objects[type].append(person)
	_create_person_predicates(person)
	world_entities.append(person)

func add_surface(surface: WorldEntity, type: String):
	surfaces[surface] = type
	if type not in typed_objects:
		typed_objects[type] = Array()
	typed_objects[type].append(surface)
	_create_surface_predicates(surface)
	world_entities.append(surface)
	broadcast_world()
	
func add_region(region: WorldEntity, type: String):
	regions[region] = type
	if type not in typed_objects:
		typed_objects[type] = Array()
	typed_objects[type].append(region)
	_create_region_predicates(region)
	world_entities.append(region)
	broadcast_world()
	
func delete_region(region: WorldEntity) -> void:
	regions.erase(region)
	typed_objects["region"].erase(region)
	world_entities.erase(region)
	_reset_predicates()
	
func delete_surface(surface: WorldEntity) -> void:
	regions.erase(surface)
	typed_objects["surface"].erase(surface)
	world_entities.erase(surface)
	_reset_predicates()
	
func delete_item(item: WorldEntity) -> void:
	regions.erase(item)
	typed_objects["item"].erase(item)
	world_entities.erase(item)
	_reset_predicates()

func delete_person(person: WorldEntity) -> void:
	regions.erase(person)
	typed_objects["person"].erase(person)
	world_entities.erase(person)
	_reset_predicates()
	
func _create_robot_predicates(robot: WorldEntity) -> void:
	_wipe_predicates(robot)

	# DOMAIN-SPECIFIC PREDICATES

	# Predicates from caregiving domain
	if Options.opts.domain == "caregiving":
		_fill_predicate(InRegionPredicate.new(), robot, 0)
		_fill_predicate(AgentNearPredicate.new(), robot, 0)
		_fill_predicate(AgentHasPredicate.new(), robot, 0)
		_fill_predicate(AvailableToPredicate.new(), robot, 0)
		_fill_predicate(AvailableToPredicate.new(), robot, 2) #duplicated because it's possible for the robot to offer or be offered
		_fill_predicate(OwnsGripperPredicate.new(), robot, 0)

	# Predicates from food assembly domain
	if Options.opts.domain == "food_assembly":
		_fill_predicate(EntityInPredicate.new(), robot, 0)
		_fill_predicate(AgentNearPredicate.new(), robot, 0)
		_fill_predicate(AgentHasPredicate.new(), robot, 0)
		_fill_predicate(AvailableToPredicate.new(), robot, 0)
		_fill_predicate(AvailableToPredicate.new(), robot, 2) #duplicated because it's possible for the robot to offer or be offered
		_fill_predicate(OwnsGripperPredicate.new(), robot, 0)

func _create_end_effector_predicates(end_effector: WorldEntity) -> void:
	_wipe_predicates(end_effector)
 
	# Predicates from caregiving domain
	if Options.opts.domain == "caregiving":
		predicates.append(IsFreePredicate.new().ground([end_effector]))
		_fill_predicate(OwnsGripperPredicate.new(), end_effector, 1)

	# Predicates from food assembly domain
	if Options.opts.domain == "food_assembly":
		predicates.append(IsFreePredicate.new().ground([end_effector]))
		_fill_predicate(OwnsGripperPredicate.new(), end_effector, 1)
	
func _create_item_predicates(item: WorldEntity):
	_wipe_predicates(item)

	# Predicates from caregiving domain
	if Options.opts.domain == "caregiving":
		predicates.append(AccessiblePredicate.new().ground([item]))
		_fill_predicate(AgentNearPredicate.new(), item, 1)
		_fill_predicate(InRegionPredicate.new(), item, 0)
		_fill_predicate(ObjectAtPredicate.new(), item, 0)
		_fill_predicate(ObjectAtPredicate.new(), item, 1) #duplicated because item could be either arg

		# Set this for subtypes, e.g., only cup can have is_full
		if item.get_node("item").subtype == "cup":
			_fill_predicate(IsFullPredicate.new(), item, 0)

		if item.get_node("item").subtype == "meal_tray":
			_fill_predicate(IsCheckedPredicate.new(), item, 0)

	# Predicates from food assembly domain
	if Options.opts.domain == "food_assembly":
		predicates.append(AccessiblePredicate.new().ground([item]))
		_fill_predicate(AgentNearPredicate.new(), item, 1)
		_fill_predicate(EntityInPredicate.new(), item, 0)
		_fill_predicate(ObjectAtPredicate.new(), item, 0)
		_fill_predicate(ObjectAtPredicate.new(), item, 1) #duplicated because item could be either arg
	

func _create_person_predicates(person: WorldEntity):
	_wipe_predicates(person)
	

	# DOMAIN-SPECIFIC PREDICATES

	# Predicates from caregiving domain
	if Options.opts.domain == "caregiving":
		predicates.append(AccessiblePredicate.new().ground([person]))
		_fill_predicate(InRegionPredicate.new(), person, 0)
		_fill_predicate(AgentNearPredicate.new(), person, 0)
		_fill_predicate(AgentHasPredicate.new(), person, 0)
		_fill_predicate(AvailableToPredicate.new(), person, 0)
		_fill_predicate(AvailableToPredicate.new(), person, 2) #duplicated because it's possible for the person to offer or be offered

	# Predicates from food assembly domain
	if Options.opts.domain == "food_assembly":
		predicates.append(AccessiblePredicate.new().ground([person]))
		_fill_predicate(EntityInPredicate.new(), person, 0)
		_fill_predicate(AgentNearPredicate.new(), person, 0)
		_fill_predicate(AgentHasPredicate.new(), person, 0)
		_fill_predicate(AvailableToPredicate.new(), person, 0)
		_fill_predicate(AvailableToPredicate.new(), person, 2) #duplicated because it's possible for the person to offer or be offered
		
func _create_surface_predicates(surface: WorldEntity):
	_wipe_predicates(surface)
	
	# Predicates from caregiving domain
	if Options.opts.domain == "caregiving":
		predicates.append(AccessiblePredicate.new().ground([surface]))
		_fill_predicate(InRegionPredicate.new(), surface, 0)
		_fill_predicate(ObjectAtPredicate.new(), surface, 1)
		_fill_predicate(AgentNearPredicate.new(), surface, 1)
		_fill_predicate(IsWipedPredicate.new(), surface, 0)

	if Options.opts.domain == "food_assembly":
		predicates.append(AccessiblePredicate.new().ground([surface]))
		_fill_predicate(EntityInPredicate.new(), surface, 0)
		_fill_predicate(ObjectAtPredicate.new(), surface, 1)
		_fill_predicate(AgentNearPredicate.new(), surface, 1)
	
func _create_region_predicates(region: WorldEntity):
	_wipe_predicates(region)

	# Predicates from caregiving domain
	if Options.opts.domain == "caregiving":
		_fill_predicate(InRegionPredicate.new(), region, 1)
		_fill_predicate(IsVacuumedPredicate.new(), region, 0)

	# Predicates from foood assembly domain
	if Options.opts.domain == "food_assembly":
		_fill_predicate(EntityInPredicate.new(), region, 1)
	
func _reset_world() -> void:
	'''Erase everything except for the robot.'''
	var persistent_types = ["robot", "end_effector"]
	var to_remove: Array[WorldEntity] = []
	for entity in world_entities:
		if entity.entity_class not in persistent_types:
			entity.get_parent().remove_child(entity)
			entity.queue_free()
			to_remove.append(entity)
	for entity in to_remove:
		world_entities.erase(entity)
	_wipe_all_predicates()
	entities.clear()
	regions.clear()
	surfaces.clear()
	for obj in typed_objects:
		if obj not in persistent_types:
			typed_objects[obj].clear()
	
func _reset_predicates() -> void:
	_wipe_all_predicates()
	for type in self.typed_objects:
		var objs = self.typed_objects[type]
		for obj in objs:
			match type:
				"robot":
					_create_robot_predicates(obj)
				"end_effector":
					_create_end_effector_predicates(obj)
				"item":
					_create_item_predicates(obj)
				"person":
					_create_person_predicates(obj)
				"surface":
					_create_surface_predicates(obj)
				"region":
					_create_region_predicates(obj)
	broadcast_world()
	
func _wipe_all_predicates() -> void:
	predicates.clear()
	
func _wipe_predicates(we: WorldEntity) -> void:
	var predicates_dup = predicates.duplicate()
	for pred in predicates_dup:
		if pred.is_arg(we):
			predicates.erase(pred)
	
func _fill_predicate(pred: Predicate, we: WorldEntity, idx: int) -> void:
	_fill_predicate_helper(pred, we, idx, 0, [])
	
func _fill_predicate_helper(pred: Predicate,
							we: WorldEntity,
							idx: int,
							curr_idx: int,
							args: Array[WorldEntity]) -> void:
	if len(pred.arg_types) == curr_idx:
		var ground_pred = pred.copy().ground(args)
		if _test_predicate(ground_pred):
			predicates.append(ground_pred)
	elif curr_idx == idx:
		args.append(we)
		_fill_predicate_helper(pred, we, idx, curr_idx+1, args)
	else:
		var type = pred.arg_types[curr_idx]
		var types: Array[String] = Domain.get_type_and_subtypes(type)
		for t in types:
			if t in self.typed_objects:
				for ent in self.typed_objects[t]:
					var dup_args = args.duplicate()
					dup_args.append(ent)
					_fill_predicate_helper(pred, we, idx, curr_idx+1, dup_args)
					
func _test_predicate(pred: Predicate) -> bool:
	return pred.test()				

func get_objects_of_types(types: Array[String], is_child_of_item=false) -> Array:
	var to_return = []

	if is_child_of_item:
		for type in types:
			for obj in self.typed_objects["item"]:
				if type == obj.get_node("item").subtype:
					to_return.append(obj)
	else:
		for type in types:
			if type in self.typed_objects:
				for obj in self.typed_objects[type]:
					to_return.append(obj)
						
	return to_return	
	
func get_object_groups() -> Array[Dictionary]:
	var to_return: Array[Dictionary] = []
	for type in self.typed_objects:
		# if it has a subtype, we need to do something a bit different!
		if type == "item":
			# Handle items with no subtype
			var item_group = {"type": type,
						"objects": []}
			for world_entity in self.typed_objects[type]:
				if world_entity.get_node("item").subtype == "":
					var properties = world_entity.get_properties()
					var obj_data = {
						"entityName": world_entity.get_label(),
						"properties": properties
					}
					item_group.objects.append(obj_data)	
			to_return.append(item_group)

			# Handle the items with subtypes
			for subtype in Domain.get_subtypes("item"):
				var group = {"type": subtype,
						"objects": []}
				for world_entity in self.typed_objects[type]:
					# FIRST check if it's the right subtype
					# THEN add it
					if world_entity.get_node("item").subtype == subtype:
						var properties = world_entity.get_properties()
						var obj_data = {
							"entityName": world_entity.get_label(),
							"properties": properties,
						}
						group.objects.append(obj_data)	
				to_return.append(group)	
		else:
			var group = {"type": type,
						"objects": []}
			for world_entity in self.typed_objects[type]:
				var properties = world_entity.get_properties()
				var obj_data = {
					"entityName": world_entity.get_label(),
					"properties": properties
				}
				group.objects.append(obj_data)	
			to_return.append(group)			
	return to_return
	
func get_predicate_json_array() -> Array[Dictionary]:
	var to_return: Array[Dictionary] = []
	for pred in predicates:
		to_return.append({"symbol": pred.symbol,
						  "parameters": pred.get_str_parameters()})
	return to_return
	
func get_predicates_from_json_array(dict_arr: Array) -> Array[Predicate]:
	var predicates: Array[Predicate] = []
	for pred_dict in dict_arr:
		var symbol = pred_dict["symbol"]
		var params = pred_dict["parameters"]
		var pred: Predicate = predicate_factory(symbol)
		var world_entities: Array[WorldEntity] = []
		for i in range(len(pred.arg_types)):
			var t = pred.arg_types[i]
			var subts = Domain.get_type_and_subtypes(t)
			for subt in subts:
				var found = false
				if subt not in typed_objects:
					continue
				for we in typed_objects[subt]:
					if we.get_label() == params[i]:
						world_entities.append(we)
						found = true
				if found:
					break
		pred.ground(world_entities)
		predicates.append(pred)
	return predicates
	
func predicate_factory(symbol: String) -> Predicate:

	# Caregiving domain specific
	if Options.opts.domain == "caregiving":
		if symbol == "accessible":
			return AccessiblePredicate.new()
		if symbol == "agent_near":
			return AgentNearPredicate.new()
		if symbol == "entity_in":
			return InRegionPredicate.new()
		if symbol == "object_at":
			return ObjectAtPredicate.new()
		if symbol == "agent_has":
			return AgentHasPredicate.new()
		if symbol == "available_to":
			return AvailableToPredicate.new()
		if symbol == "is_checked":
			return IsCheckedPredicate.new()
		if symbol == "is_free":
			return IsFreePredicate.new()
		if symbol == "is_full":
			return IsFullPredicate.new()
		if symbol == "is_open":
			return IsOpenPredicate.new()
		if symbol == "is_swept":
			return IsVacuumedPredicate.new()	
		if symbol == "is_wiped":
			return IsWipedPredicate.new()	
		if symbol == "owns_gripper":
			return OwnsGripperPredicate.new()

	# Food assembly domain specific
	if Options.opts.domain == "food_assembly":
		if symbol == "accessible":
			return AccessiblePredicate.new()
		if symbol == "agent_near":
			return AgentNearPredicate.new()
		if symbol == "entity_in":
			return EntityInPredicate.new()
		if symbol == "object_at":
			return ObjectAtPredicate.new()
		if symbol == "agent_has":
			return AgentHasPredicate.new()
		if symbol == "available_to":
			return AvailableToPredicate.new()
		if symbol == "is_free":
			return IsFreePredicate.new()
		if symbol == "is_open":
			return IsOpenPredicate.new()
		if symbol == "owns_gripper":
			return OwnsGripperPredicate.new()

	return Predicate.new(symbol, [])
	
func diff(new_preds: Array[Predicate], old_preds: Array[Predicate]) -> Array[Predicate]:
	'''
	Subtracts the set of predictes old_preds from new_preds
	'''
	var to_return: Array[Predicate] = []
	for new_pred in new_preds:
		for old_pred in old_preds:
			if new_pred.is_conflicting(old_pred):
				to_return.append(new_pred)
				continue
	return to_return
	
func get_entity_positions() -> Dictionary:
	var to_return: Dictionary = {}
	for world_entity in world_entities:
		to_return[world_entity] = world_entity.get_location()
	return to_return

func get_world() -> Dictionary:
	var world_dict = {
		"object_groups": get_object_groups(),
		"predicates": get_predicate_json_array(),
	}
	return world_dict
	
func broadcast_world() -> void:
	var world_dict: Dictionary = get_world()
	SignalBus.broadcast_world.emit(world_dict)
	
func _dump_results() -> void:
	_dump_pixel_values()
	_get_uncertainty()
	SignalBus.analyze_next_user.emit()
	
func _dump_pixel_values() -> void:
	var pixel_values: Dictionary = {}
	if Options.opts.uncert_paint:
		for area in regions:
			_dump_pixel_values_helper(area.get_entity(), pixel_values)
		for area in surfaces:
			_dump_pixel_values_helper(area.get_entity(), pixel_values)
	else:
		var item_points: Dictionary = uncert_param_panel.get_item_lists()
		for item in item_points:
			if item not in pixel_values:
				pixel_values[item] = {}
			for entry in item_points[item]:
				if entry.ent.get_entity().unique_label not in pixel_values[item]:
					pixel_values[item][entry.ent.get_entity().unique_label] = []
				var entry_data = {
					"center": [entry.mask["center"].x, entry.mask["center"].y],
					"value": entry.rank_label.text,  # is probability if sliders, rank if rank
					"uid": entry.uid,
					"text": entry.label.text,
					"slider": entry.slider.value
				}
				pixel_values[item][entry.ent.get_entity().unique_label].append(entry_data)
	var s = JSON.stringify(pixel_values)
	# print(s)
	SignalBus.send_to_parent_html_frame.emit("resultsPixelValues", s)
				
func _dump_pixel_values_helper(area: Area, pixel_values: Dictionary) -> void:
	for item in area._shader_texs:
		if item not in pixel_values:
			pixel_values[item] = {}
		pixel_values[item][area.unique_label] = {"dimensions": [], "values": []}
		var img = area._shader_texs[item].get_image()
		pixel_values[item][area.unique_label]["dimensions"] = [img.get_width(), img.get_height()]
		for i in range(img.get_width()):
			for j in range(img.get_height()):
				pixel_values[item][area.unique_label]["values"].append(img.get_pixel(i, j).a)
	
func _get_uncertainty() -> void:
	
	# probabilities
	var p: Dictionary = {}

	# COMMENT IN TO TREAT REGIONS AND SURFACES SEPARATELY
	# get a dictionary of region waypoints
	# var region_waypoints = _create_area_dict(regions, p)
	# var surface_waypoints = _create_area_dict(surfaces, p)
	
	# COMMENT IN TO LUMP REGIONS AND SURFACES TOGETHER
	var all_areas = regions.duplicate()
	for surf in surfaces:
		all_areas[surf] = surfaces[surf]
	var all_waypoints = _create_area_dict(all_areas, p)
	
	'''
	print("REGION UNCERTAINTY SCORES")
	for region_wp in region_waypoints["waypoints"]:
		print("{regID} - {val}".format({"regID": region_wp.get_wp_name(), "val": str(region_waypoints["waypoints"][region_wp])}))
	print("\nSURFACE UNCERTAINTY SCORES")
	for surface_wp in surface_waypoints["waypoints"]:
		print("{surfID} - {val}".format({"surfID": surface_wp.get_wp_name(), "val": str(surface_waypoints["waypoints"][surface_wp])}))
	'''
	
	if not Options.opts.uncert_rank:
		var total_score: Dictionary = {}
		for waypoint in all_waypoints["waypoints"]:
			for item in all_waypoints["waypoints"][waypoint]:
				if all_waypoints["waypoints"][waypoint][item] > 0:
					if item not in total_score:
						total_score[item] = 0
					total_score[item] += all_waypoints["waypoints"][waypoint][item] 
					p[item][waypoint] = all_waypoints["waypoints"][waypoint][item]
		'''
		for waypoint in region_waypoints["waypoints"]:
			for item in region_waypoints["waypoints"][waypoint]:
				if region_waypoints["waypoints"][waypoint][item] > 0:
					if item not in total_score:
						total_score[item] = 0
					total_score[item] += region_waypoints["waypoints"][waypoint][item] 
					p[item][waypoint] = region_waypoints["waypoints"][waypoint][item]
		for waypoint in surface_waypoints["waypoints"]:
			for item in surface_waypoints["waypoints"][waypoint]:
				if surface_waypoints["waypoints"][waypoint][item] > 0:
					if item not in total_score:
						total_score[item] = 0
					total_score[item] += surface_waypoints["waypoints"][waypoint][item] 
					p[item][waypoint] = surface_waypoints["waypoints"][waypoint][item]
		'''
		for item in p:
			for waypoint in p[item]:
				p[item][waypoint] /= total_score[item]
				
		print("- Probabilities -")
		var p_json: Dictionary = {}
		for item in p:
			p_json[item] = {}
			var s: String = "\t" + item + ": "
			var i: int = 0
			for waypoint in p[item]:
				if item == Options.opts.curr_item:
					SignalBus.activate_waypoint.emit(waypoint.get_full_name(), 50.0, Color.RED)
				p_json[item][waypoint.get_full_name()] = p[item][waypoint]
				if i > 0:
					s += " + "
				s += str(p[item][waypoint]) + ": " + waypoint.get_full_name() 
				i += 1
			#print(s)
		print(p_json)
		SignalBus.completed_analysis_results.emit(str(p_json))
		SignalBus.send_to_parent_html_frame.emit("results", JSON.stringify(p_json))
	else:
		var center_ranks: Dictionary = {}
		for waypoint in all_waypoints["waypoints"]:
			for item in all_waypoints["waypoints"][waypoint]:
				if item not in center_ranks:
					center_ranks[item] = {}
				if len(all_waypoints["waypoints"][waypoint][item]) > 0:
					p[item][waypoint] = all_waypoints["waypoints"][waypoint][item]
		for item in all_waypoints["ranks"]:
			for rank in all_waypoints["ranks"][item]:
				center_ranks[item][rank] = all_waypoints["ranks"][item][rank]
		'''
		for waypoint in region_waypoints["waypoints"]:
			for item in region_waypoints["waypoints"][waypoint]:
				if item not in center_ranks:
					center_ranks[item] = {}
				if len(region_waypoints["waypoints"][waypoint][item]) > 0:
					p[item][waypoint] = region_waypoints["waypoints"][waypoint][item]
		for item in region_waypoints["ranks"]:
			for rank in region_waypoints["ranks"][item]:
				center_ranks[item][rank] = region_waypoints["ranks"][item][rank]
		for waypoint in surface_waypoints["waypoints"]:
			for item in surface_waypoints["waypoints"][waypoint]:
				if item not in center_ranks:
					center_ranks[item] = {}
				if len(surface_waypoints["waypoints"][waypoint][item]) > 0:
					p[item][waypoint] = surface_waypoints["waypoints"][waypoint][item]
		for item in surface_waypoints["ranks"]:
			for rank in surface_waypoints["ranks"][item]:
				center_ranks[item][rank] = surface_waypoints["ranks"][item][rank]
		'''
		print("- Ranks -")
		var ranks_json: Dictionary = {}
		for item in center_ranks:
			var s: String = "\t" + item + ": "
			var i: int = 0
			var ranks: Dictionary = {}
			var sum_rank: Dictionary = {}
			ranks_json[item] = {}
			'''
			for waypoint in p[item]:
				for rank in p[item][waypoint]:
					if rank not in ranks:
						ranks[rank] = {}
						ranks_json[item][str(rank)] = {}
					if waypoint not in ranks[rank]:
						ranks[rank][waypoint] = 0
						ranks_json[item][str(rank)][waypoint.get_full_name()] = 0
					ranks[rank][waypoint] += p[item][waypoint][rank]
					# ranks_json[item][str(rank)][waypoint.get_full_name()] += p[item][waypoint][rank]
					if rank not in sum_rank:
						sum_rank[rank] = 0
					sum_rank[rank] += p[item][waypoint][rank]
			'''
			for rank in center_ranks[item]:
				ranks_json[item][str(rank)] = {}
				s += "\n\t\tRANK " + str(rank) + " - ("
				#for waypoint in ranks[rank]:
				s += center_ranks[item][rank].get_full_name() + ": " + str(rank) + "; "
					# ranks_json[item][str(rank)][waypoint.get_full_name()] /= sum_rank[rank]
				s += "); "
				s += "center=" + center_ranks[item][rank].get_full_name()
				if item == Options.opts.curr_item:
					SignalBus.activate_waypoint.emit(center_ranks[item][rank].get_full_name(), 50.0, Color.RED)
				ranks_json[item][str(rank)]["center"] = center_ranks[item][rank].get_full_name()
			print(s)
		SignalBus.completed_analysis_results.emit(str(ranks_json))
		SignalBus.send_to_parent_html_frame.emit("results", JSON.stringify(ranks_json))
	SignalBus.dump_frontend_log.emit()		
	SignalBus.send_to_parent_html_frame.emit("autoproceed", "")
	
func _create_area_dict(areas: Dictionary, p: Dictionary) -> Dictionary:
	var area_waypoints: Dictionary = {"waypoints": {}, "ranks": {}}
	for area_entity in areas:
		var area: Area = area_entity.get_entity()
		for waypoint in area.waypoints.get_children():
			area_waypoints["waypoints"][waypoint] = {}
			for item in area._shader_texs:
				if not Options.opts.uncert_rank:
					area_waypoints["waypoints"][waypoint][item] = 0.0
				else:
					area_waypoints["waypoints"][waypoint][item] = {}
					area_waypoints["ranks"][item] = {}
				if item not in p:
					p[item] = {}
	for area in areas:
		_get_uncertainty_per_pixel(area, area_waypoints)
	return area_waypoints
		
func _get_uncertainty_per_pixel(area_world_entity: WorldEntity, area_waypoint_dict: Dictionary) -> void:
	if Options.opts.uncert_paint:
		_get_uncertainty_per_painted_pixel(area_world_entity, area_waypoint_dict)
	elif Options.opts.uncert_sliders:
		_get_uncertainty_per_pixel_group(area_world_entity, area_waypoint_dict)
	elif Options.opts.uncert_rank:
		_get_rank_per_pixel_group(area_world_entity, area_waypoint_dict)
		
func _get_uncertainty_per_painted_pixel(area_world_entity: WorldEntity,
										area_waypoint_dict: Dictionary) -> void:
	var area: Area = area_world_entity.get_entity()
	for item in area._shader_texs:
		var tex = area._shader_texs[item]
		var img: Image = tex.get_image()
		for i in range(img.get_width()):
			for j in range(img.get_height()):
				var pix: Color = img.get_pixel(i, j)
				if pix.a == 0:
					continue
				var pix_world_pos = area.pixel_coord_to_global_coord(i, j)

				var closest_wp = _get_closest_waypoint_to_coord(pix_world_pos, area_waypoint_dict["waypoints"], area_world_entity.get_entity(), item)
				'''
				# UNCOMMENT IF THE ABOVE FUNCTION IS BUGGY
				# get the closest area waypoint to the location of the pixel
				var closest_wp: Node3D
				var closest_wp_dist: float = -1.0
				for wp in area_waypoint_dict["waypoints"]:
					#print(wp.wp_name + ": " + str(wp.global_position))
					var dist = wp.global_position.distance_to(pix_world_pos)
					if closest_wp_dist < 0.0 or dist < closest_wp_dist:
						closest_wp = wp
						closest_wp_dist = dist
				'''
				# increase the value of the closest waypoint by the value of the pixel
				if closest_wp != null:
					area_waypoint_dict["waypoints"][closest_wp][item] += pix.a
				else:
					print("no waypoint is closest to the pixel")
				
func _get_entries(area_world_entity: WorldEntity) -> Dictionary:
	'''
	Returns a dictionary:
		groups[item][entry] = {
			p: probability_per_pixel,
			pixels: list_of_pixels_converted_to_coordinates
		}
	'''
	var area: Area = area_world_entity.get_entity()
	var groups: Dictionary = {}
	for item in area._shader_texs:
		SignalBus.select_uncert_item.emit(item)
		# area.select_uncert_item(item)
		groups[item] = {}
		var entries: Array[Entry] = area.get_uncert_points()
		for entry in entries:
			if Options.opts.uncert_sliders:
				groups[item][entry] = {
					#"p": float(entry.rank_label.text.substr(0, len(entry.rank_label.text)-1))/100.0,
					"p": entry.slider.value/uncert_param_panel.sum_sliders_for_item(item),
					"coords": [],
					"center": area.pixel_coord_to_global_coord(entry.mask["center"].x, entry.mask["center"].y)
				}
			elif Options.opts.uncert_rank:
				groups[item][entry] = {
					"p": float(entry.rank_label.text),
					"coords": [],
					"center": area.pixel_coord_to_global_coord(entry.mask["center"].x, entry.mask["center"].y)
				}
		'''
		var tex = area._shader_texs[item]
		var img: Image = tex.get_image()
		for i in range(img.get_width()):
			for j in range(img.get_height()):
				# convert the pixel to its corresponding coordinate
				var pix_world_pos = area.pixel_coord_to_global_coord(i, j) # _convert_pixel_to_world_pos(i, j, img, area)
				# determine if (i, j) is close to any of the existing entries, and which is the closest
				var entry = area.get_closest_uncert_point(pix_world_pos)
				# if not in any entry, move on
				if entry == null:
					continue
				# else, if entry is not in the groups already, add it and set the probability
				if entry not in groups[item]:
					#var one = entry.rank_label.text
					#var two = one.substr(0, len(entry.rank_label.text)-1)
					#var three = two/100.0
					if Options.opts.uncert_sliders:
						groups[item][entry] = {
							#"p": float(entry.rank_label.text.substr(0, len(entry.rank_label.text)-1))/100.0,
							"p": entry.slider.value/uncert_param_panel.sum_sliders_for_item(item),
							"coords": [],
							"center": area.pixel_coord_to_global_coord(entry.mask["center"].x, entry.mask["center"].y)
						}
					elif Options.opts.uncert_rank:
						groups[item][entry] = {
							"p": float(entry.rank_label.text),
							"coords": [],
							"center": area.pixel_coord_to_global_coord(entry.mask["center"].x, entry.mask["center"].y)
						}
				# add the coordinate
				groups[item][entry]["coords"].append(pix_world_pos)
		'''
	return groups
	
func _get_uncertainty_per_pixel_group(area_world_entity: WorldEntity, area_waypoint_dict: Dictionary) -> void:
	var groups: Dictionary = _get_entries(area_world_entity)
	for item in groups:
		for entry in groups[item]:
			var p = groups[item][entry]["p"]
			if Options.opts.slider_accuracy_center_only:
				var closest_wp = _get_closest_waypoint_to_coord(groups[item][entry]["center"], area_waypoint_dict["waypoints"], area_world_entity.get_entity(), item)
				area_waypoint_dict["waypoints"][closest_wp][item] += p
			else:
				pass
				'''
				for coord in groups[item][entry]["coords"]:
					var closest_wp = _get_closest_waypoint_to_coord(coord, area_waypoint_dict["waypoints"], area_world_entity.get_entity(), item)
					# increase the value of the closest waypoint by the probability split across cells
					if closest_wp != null:
						area_waypoint_dict["waypoints"][closest_wp][item] += p/len(groups[item][entry]["coords"])
				'''
					
func _get_rank_per_pixel_group(area_world_entity: WorldEntity, area_waypoint_dict: Dictionary) -> void:
	var groups: Dictionary = _get_entries(area_world_entity)
	for item in groups:
		for entry in groups[item]:
			var p = groups[item][entry]["p"]
			var closest_wp = _get_closest_waypoint_to_coord(groups[item][entry]["center"], area_waypoint_dict["waypoints"], area_world_entity.get_entity(), item)
			area_waypoint_dict["ranks"][item][float(entry.rank_label.text)] = closest_wp
		
			for coord in groups[item][entry]["coords"]:
				pass
				'''
				closest_wp = _get_closest_waypoint_to_coord(coord, area_waypoint_dict["waypoints"], area_world_entity.get_entity(), item)
				# increase the value of the closest waypoint by the probability split across cells
				if closest_wp != null:
					if p not in area_waypoint_dict["waypoints"][closest_wp][item]:
						area_waypoint_dict["waypoints"][closest_wp][item][p] = 0.0
					area_waypoint_dict["waypoints"][closest_wp][item][p] += 1.0
				'''
			# var closest_wp_to_center = _get_closest_waypoint_to_coord(groups[item][entry]["center"], area_waypoint_dict["waypoints"], area_world_entity.get_entity(), item)
			# area_waypoint_dict["ranks"][item][float(entry.rank_label.text)] = closest_wp_to_center
		
	
func _get_closest_waypoint_to_coord(coord: Vector3,
									area_waypoint_dict: Dictionary,
									coord_area: Area,
									item: String) -> Node3D:
	# get the closest area waypoint to the location of the pixel
	var closest_wp: Node3D
	var closest_wp_dist: float = -1.0
	
	# COMMENT IN FOR mapping to closest ground truth waypoint
	var closest_gt_wp: Node3D
	var closest_gt_wp_dist: float = -1.0
	
	for wp in area_waypoint_dict:
		#print(wp.wp_name + ": " + str(wp.global_position))
		if Options.opts.accuracy_analysis_curr_room_only:
			if wp.get_area() != coord_area:
				continue
		# COMMENT IN to only consider x and y coordinates
		var wp_global_pos: Vector2 = Vector2(wp.global_position.x, wp.global_position.y)
		var coord_pos: Vector2 = Vector2(coord.x, coord.y)
		var dist = wp_global_pos.distance_to(coord_pos)
		
		# COMMENT IN if want to consider z position
		# var dist = wp.global_position.distance_to(coord)
		
		# COMMENT IN if you want to map to closest ground truth wp
		var candidate_gt_wp = null
		if item == "umbrella":
			if wp.get_full_name() == Options.opts["umbrella_gt1"]:
				candidate_gt_wp = wp
			if wp.get_full_name() == Options.opts["umbrella_gt2"]:
				candidate_gt_wp = wp
			if wp.get_full_name() == Options.opts["umbrella_gt3"]:
				candidate_gt_wp = wp
		elif item == "bag":
			if wp.get_full_name() == Options.opts["bag_gt1"]:
				candidate_gt_wp = wp
			if wp.get_full_name() == Options.opts["bag_gt2"]:
				candidate_gt_wp = wp
			if wp.get_full_name() == Options.opts["bag_gt3"]:
				candidate_gt_wp = wp
		if candidate_gt_wp != null:
			if dist < 2.0:
				if closest_gt_wp_dist < 0.0 or dist < closest_gt_wp_dist:
					closest_gt_wp = candidate_gt_wp
		
		if closest_wp_dist < 0.0 or dist < closest_wp_dist:
			closest_wp = wp
			closest_wp_dist = dist
	
	# COMMENT IN IF wanting closest ground truth wp
	#if closest_gt_wp != null:
	#	return closest_gt_wp
	# OTHERWISE the following should be the only return st.
	return closest_wp

func save_world() -> void:
	var save_string = []
	var save_map = FileAccess.open("user://" + Options.opts.save, FileAccess.WRITE)
	for entity in world_entities:
		#if entity.entity_class != "robot":
		var data = entity.jsonify()
		var data_str = JSON.stringify(data)
		# save_map.store_line(data_str)
		save_string.append(data_str)

	# write as a string to easily copy/paste into controller.gd for loading saves in web!
	var save_dict: Dictionary = {"map":save_string}
	var save_string_file = FileAccess.open("user://string_" + Options.opts.save, FileAccess.WRITE)
	save_string_file.store_line(JSON.stringify(save_dict))
