extends TileMap

var astar: AStarGrid2D
var divideby: int = 4
var agent_margins: Dictionary

func set_agent_margins(margins: Dictionary) -> void:
	agent_margins = {}
	agent_margins["top"] = int(margins["top"] / astar.cell_size.y) + 1
	agent_margins["bottom"] = int(margins["bottom"] / astar.cell_size.y) + 1
	agent_margins["left"] = int(margins["left"] / astar.cell_size.x) + 1
	agent_margins["right"] = int(margins["right"] / astar.cell_size.x) + 1
	pass

# Called when the node enters the scene tree for the first time.
func _ready():
	astar = AStarGrid2D.new()
	astar.size = get_used_rect().size * divideby
	astar.cell_size = Vector2i(
		48/divideby,
		48/divideby
	)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ALWAYS
	astar.update()

func instantiate_astar_grid() -> void:
	
	var region_size = Vector2i(
		get_used_rect().size.x * divideby,
		get_used_rect().size.y * divideby
	)
	var region_position: Vector2i = get_used_rect().position
	
	for x in region_size.x:
		for y in region_size.y:
			# get the current tile
			# see if the tile is "wall behind"
			var tilex: int = x / divideby
			var tiley: int = y / divideby
			var tile_position = Vector2i(
				tilex + region_position.x,
				tiley + region_position.y
			)
			var tile_data: TileData
			for layer in get_layers_count():
				tile_data = get_cell_tile_data(layer, tile_position)
				if tile_data != null:
					break
			if tile_data == null:
				set_point_and_neighbors_solid(Vector2i(x, y))
			elif tile_data.get_collision_polygons_count(0) > 0:
				set_point_and_neighbors_solid(Vector2i(x, y))
			else:
				# get the current coordinates
				# see if the CENTER of (x,y) is in a collision space
				var center_pos = Vector2i(astar.cell_size) * (Vector2i(x, y) + region_position*divideby) + Vector2i(astar.cell_size/2)
				var space_rid = get_world_2d().space
				var space_state = PhysicsServer2D.space_get_direct_state(space_rid)
				var query = PhysicsRayQueryParameters2D.create(center_pos, center_pos)
				query.hit_from_inside = true
				var result = space_state.intersect_ray(query)
				if len(result) > 0:
					# check that it is not the robot
					var col = result["collider"]
					var n = col.name
					if col is CharacterCollider or col is SimulatedRobot or col is SimulatedCaregiver:
						pass
					else:
						set_point_and_neighbors_solid(Vector2i(x, y))
				else:
					pass
					
	for x in region_size.x:
		for y in region_size.y:
			# get the current tile
			# see if the tile is "wall behind"
			var tilex: int = x / divideby
			var tiley: int = y / divideby
			var tile_position = Vector2i(
				tilex + region_position.x,
				tiley + region_position.y
			)
			var center_pos = Vector2i(astar.cell_size) * (Vector2i(x, y) + region_position*divideby) + Vector2i(astar.cell_size/2)
			if not astar.is_point_solid(Vector2(x, y)):
				var line = Line2D.new()
				line.width = 48/divideby
				line.z_index = 5
				if Options.opts["debug_path_plan"]:
					line.default_color = Color(255, 0, 0, 0.3)
				else:
					line.default_color = Color(255, 0, 0, 0.0)
				var start = center_pos
				var end = center_pos
				start.x -= astar.cell_size.x/2
				end.x += astar.cell_size.y/2
				line.add_point(start)
				line.add_point(end)
				add_child(line)

func set_point_and_neighbors_solid(cell: Vector2i) -> void:
	for x in range(cell.x - agent_margins["left"], cell.x + agent_margins["right"] + 1):
		if x < 0 or x >= astar.size.x:
			continue
		for y in range(cell.y - agent_margins["bottom"], cell.y + agent_margins["top"] + 1):
			if y < 0 or y >= astar.size.y:
				continue
			astar.set_point_solid(Vector2i(x, y))

func set_point_and_neighbors_free(cell: Vector2i) -> void:
	for x in range(cell.x - agent_margins["left"], cell.x + agent_margins["right"] + 1):
		if x < 0 or x >= astar.size.x:
			continue
		for y in range(cell.y - agent_margins["bottom"], cell.y + agent_margins["top"] + 1):
			if y < 0 or y >= astar.size.y:
				continue
			astar.set_point_solid(Vector2i(x, y), false)

func cell_to_pos(cell: Vector2i) -> Vector2i:
	var cellpos = Vector2i(astar.get_point_position(cell))
	var offset = (get_used_rect().position * divideby) * Vector2i(astar.cell_size)
	var pos = cellpos + offset
	return pos
	
func pos_to_cell(pos: Vector2i) -> Vector2i:
	var offset = (get_used_rect().position * divideby) * Vector2i(astar.cell_size)
	pos -= offset
	var cell = Vector2i(pos) / Vector2i(astar.cell_size)
	#var cellpos = astar.get_point_position(cell)
	return cell

func get_point_path(startpos: Vector2i, endpos: Vector2i) -> PackedVector2Array:
	# convert start and end to grid cells
	var start = pos_to_cell(startpos)
	var end = pos_to_cell(endpos)
		
	if astar.is_point_solid(end):		
		# try other angles to approach the point
		var flag: bool = true
		var n: int = 1
		while flag:
			if !astar.is_point_solid(Vector2i(end.x+n, end.y)):
				end = Vector2i(end.x+n, end.y)
				break
			if !astar.is_point_solid(Vector2i(end.x, end.y+n)):
				end = Vector2i(end.x, end.y+n)
				break
			if !astar.is_point_solid(Vector2i(end.x+n, end.y+n)):
				end = Vector2i(end.x+n, end.y+n)
				break
			if !astar.is_point_solid(Vector2i(end.x-n, end.y)):
				end = Vector2i(end.x-n, end.y)
				break
			if !astar.is_point_solid(Vector2i(end.x, end.y-n)):
				end = Vector2i(end.x, end.y-n)
				break
			if !astar.is_point_solid(Vector2i(end.x-n, end.y-n)):
				end = Vector2i(end.x-n, end.y-n)
				break
			
			n = n+1
			
	return astar.get_id_path(start, end)		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
