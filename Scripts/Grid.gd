extends TileMap

var grid = []
var grid_size = Vector2(4, 4)

onready var tile_scene = preload("res://Scenes/Tile.tscn")

# Game:
var game_over = false


func _ready():
	randomize()
	init_grid()
	
	# Start game:
	spawn_new_tile()


func _input(event):
	if event is InputEventKey:
		
		# Restart (for debugging):
		if event.pressed and event.scancode == KEY_R:
			get_tree().reload_current_scene()
		
		# Can't make a move if the game is over:
		if game_over:
			return
		# Else make move:
		if event.is_action_pressed("ui_left", true):
			prepare_grid()
			slide_grid(Vector2.LEFT)
		if event.is_action_pressed("ui_right", true):
			prepare_grid()
			slide_grid(Vector2.RIGHT)
		if event.is_action_pressed("ui_up", true):
			prepare_grid()
			slide_grid(Vector2.UP)
		if event.is_action_pressed("ui_down", true):
			prepare_grid()
			slide_grid(Vector2.DOWN)


func init_grid():
	for row in grid_size.y:
		grid.append([])
		grid[row].resize(grid_size.x)

func print_grid():
	print("-------------------------")
	for row in grid:
		print(row)

func spawn_new_tile():
	# Check for empty slots:
	var empty_slots = get_empty_slots()
	
	# Get random empty location and spawn tile there:
	var spawn_location = empty_slots[randi() % empty_slots.size()]
	create_tile(spawn_location)
	
	# If no possible moves left, the game is over:
	empty_slots = get_empty_slots()
	if !possible_moves_left(empty_slots):
		game_lost()


func get_empty_slots():
	var empty_slots = []
	for row in grid_size.y:
		for col in grid_size.x:
			if grid[row][col] == null:
				#print(str(row)+" "+str(col))
				empty_slots.append(Vector2(col, row))
	return empty_slots


func possible_moves_left(empty_slots):
	
	# There are still possible moves if the last empty slot isn't filled yet:
	if !empty_slots.empty():
		return true
	
	# Else, check if any adjacent tiles have matching values:
	# To do this efficiently, we can just check the value under and
	# to the right of each tile.
	for x in grid_size.x:
		for y in grid_size.y:
			var tile = grid[y][x]
			var value
			if tile == null:
				value = 2
			else:
				value = tile.value
			if within_grid(Vector2(x+1, y)): # check if tile exists to the right
				var next_tile = grid[y][x+1]
				if next_tile == null:
					return value == 2
				if next_tile.value == value:
					return true
			if within_grid(Vector2(x, y+1)): # check if tile exists under
				var next_tile = grid[y+1][x]
				if next_tile == null:
					return value == 2
				if next_tile.value == value:
					return true
	
	# No adjacent matches found, so no moves left:
	return false


func create_tile(grid_pos, value = 2):
	var tile = tile_scene.instance()
	add_child(tile)
	move_child(tile, get_child_count())
	tile.value = value
	tile.position = map_to_world(grid_pos)
	grid[grid_pos.y][grid_pos.x] = tile
	
	# Do creation animation:
	tile.appear()


func slide_grid(direction):
	var tiles_to_shift_positions = []
	
	# Get the correct order that the tiles should be shifted in:
	match direction:
		Vector2.LEFT: # start with left column, going right
			for col in grid_size.x:
				for row in grid_size.y:
					if grid[row][col] != null:
						tiles_to_shift_positions.append(Vector2(col, row))
		Vector2.RIGHT: # start with right column, going left
			for col in range(grid_size.x-1, -1, -1):
				for row in grid_size.y:
					if grid[row][col] != null:
						tiles_to_shift_positions.append(Vector2(col, row))
		Vector2.UP: # start with top row, going down
			for row in grid_size.y:
				for col in grid_size.x:
					if grid[row][col] != null:
						tiles_to_shift_positions.append(Vector2(col, row))
		Vector2.DOWN: # start with bottom row, going up
			for row in range(grid_size.y-1, -1, -1):
				for col in grid_size.x:
					if grid[row][col] != null:
						tiles_to_shift_positions.append(Vector2(col, row))
	
	# Now shift each tile as far as it can go:
	var tiles_moved = false
	for tile_pos in tiles_to_shift_positions:
		if attempt_tile_shift(tile_pos, direction):
			tiles_moved = true
	
	# If something moved, spawn new tile for next turn:
	if tiles_moved:
		spawn_new_tile()
		#print_grid()


func attempt_tile_shift(tile_pos, direction):
	var tile = grid[tile_pos.y][tile_pos.x]
	var value = tile.value
	
	# True if the tile can move:
	var tile_can_move = false
	var will_combine = false
	var tile_in_way = null
	var next_pos = tile_pos
	
	while true:
		next_pos += direction
		if not within_grid(next_pos):
			break
		tile_in_way = grid[next_pos.y][next_pos.x]
		if tile_in_way != null:
			if tile_in_way.value != value:
				break
			
			# Else they have the same value and should combine:
			next_pos += direction
			will_combine = true
			tile_can_move = true
			break
		tile_can_move = true
	
	if tile_can_move:
		next_pos -= direction
		grid[tile_pos.y][tile_pos.x] = null
		if will_combine:
			grid[next_pos.y][next_pos.x] = null
			tile.slide(map_to_world(next_pos), tile_in_way)
			create_tile(next_pos, value*2)
		else:
			grid[next_pos.y][next_pos.x] = tile
			tile.slide(map_to_world(next_pos))
	
	return tile_can_move


func within_grid(tile_pos):
	# Self-explanatory:
	return tile_pos.x >= 0 and tile_pos.x < grid_size.x and tile_pos.y >= 0 and tile_pos.y < grid_size.y

func prepare_grid():
	
	var relevant_tiles = []
	for row in grid:
		for tile in row:
			if tile != null:
				relevant_tiles.append(tile)
	
	for tile in get_children():
		tile.skip_animations()
		if !relevant_tiles.has(tile):
			tile.queue_free()

func game_lost():
	game_over = true
	print("lost")
	
	# Show game over text and fade screen:
	var label = get_parent().get_node("GameOverLabel")
	var foreground = get_parent().get_node("Foreground")
	var tween = get_parent().get_node("GameOverTween")
	var duration = 2
	tween.interpolate_property(label, "rect_position", Vector2(label.rect_position.x, label.rect_position.y-1000), 
		label.rect_position, duration, Tween.TRANS_BOUNCE, Tween.EASE_IN_OUT)
	tween.interpolate_property(foreground, "modulate:a", 0.0, 0.5, 
		duration, Tween.TRANS_QUAD, Tween.EASE_IN)
	tween.start()
	label.visible = true



