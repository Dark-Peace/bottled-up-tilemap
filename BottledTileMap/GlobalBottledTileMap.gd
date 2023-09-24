@tool
extends Node


const ALT_H:Array = [1,3,5,7]
const ALT_V:Array = [2,3,6,7]
const ALT_T:Array = [4,5,6,7]

###############################

# TILE ID

#########

const TILEID:Dictionary = {"source": -1, "coords": Vector2i(-1,-1), "alt": 0, "v": Vector3i(-1,-1,-1)}

func new_TILEID(_source:int=-1, _coords:Vector2i=Vector2i(-1,-1), _alt:int=0):
	var new_tile = TILEID.duplicate()
	new_tile["source"] = _source
	new_tile["coords"] = _coords
	new_tile["alt"] = _alt
	new_tile["v"].z = _source
	new_tile["v"].x = _coords.x
	new_tile["v"].y = _coords.y
	return new_tile
	
func new_TILEID_v3(data:Vector3i, _alt:int=0):
	return new_TILEID(data.z, Vector2i(data.x,data.y), _alt)

func print(tile:Dictionary):
	return "TILEID< "+str(tile["source"])+" ; "+str(tile["coords"])+">"

func isEqual(tile:Dictionary, other:Dictionary):
	return tile["source"] == other["source"] and tile["coords"] == other["coords"]

func isEqualV3(tile:Dictionary, other:Vector3i):
	return tile["v"] == other


# canvas input handling ###############################

const INVALID:int = -1
const FARAWAY:Vector2i = Vector2i(-999999,-999999)

var tilemap:BottledTileMap
var toolbar
var palette

var current_cell:Vector2i
var starter_cell:Vector2i
var start_hold_cell:Vector2i = FARAWAY
var painted_cells:Array[Vector3i]
var painted_cellsV2:Array[Vector2i]
var current_alt:int = 0 : set = _set_current_alt
var l:int = 0
# states
var button_held:int = INVALID
var cancel_action:bool = false
var is_shift:bool = false
var is_ctrl:bool = false
var is_alt:bool = false
var is_bucket:bool = false
var is_terrain:bool = true
var is_solving:bool = false
#var is_custom_brush:bool = false
var drawing_modes:Array[String]
var update_settings:UPDATE_SETTINGS = UPDATE_SETTINGS.Painted


## input handling ##

func bottled_set_cell(event:InputEvent):
	# click
	if event is InputEventMouseButton:
		if event.pressed: handle_click_pressed(event.button_index)
		else: handle_click_release()
	# mouse hover over a cell
	elif event is InputEventMouseMotion:
		handle_motion()

func handle_click_pressed(button):
	# cancel line / rect by clicking with the other mouse button
	if button == (button_held%2)+1: _cancel_shape_draw()
	# SETUP
	_setup_var_on_click(button)

func handle_click_release():
	# draw
	_draw_on_release()
	# end of action : reset
	_reset_var_on_release()

func handle_motion():
	if is_bucket: return
	if current_cell == tilemap.local_to_map(tilemap.get_local_mouse_position()):
		if not _draw_first_tile_if_motion(): return
	
	# update current exited cell to newly entered cell
	tilemap.cell_exited.emit(current_cell)
	current_cell = tilemap.local_to_map(tilemap.get_local_mouse_position())
	
	_draw_on_motion()
	
	# draw preview on newly entered cell
	tilemap.cell_entered.emit(current_cell)
	tilemap.queue_redraw()



## actions on input ##

func _setup_var_on_click(button):
	current_cell = tilemap.local_to_map(tilemap.get_local_mouse_position())
	start_hold_cell = current_cell
	button_held = button
	is_shift = Input.is_key_pressed(KEY_SHIFT)
	is_ctrl = Input.is_key_pressed(KEY_CTRL)
	is_alt = Input.is_key_pressed(KEY_ALT)
	is_bucket = Input.is_key_pressed(KEY_SPACE)
	# remember starter cell if SHIFT for drawing rect / lines
	if is_shift: starter_cell = current_cell
	
	tilemap.draw_bezier(Vector2i(0,0), Vector2i(5,0), Vector2i(7,0), Vector2i(10,10))
	
	# pick tile in palette
	if is_ctrl and not is_shift and not is_alt:
		palette.pick_tile(tilemap.get_cell(current_cell))

func _reset_var_on_release():
	button_held = INVALID
	if is_terrain and is_shift: _solve_autotile_shape()
	painted_cells.clear()
	painted_cellsV2.clear()
	is_ctrl = false
	is_shift = false
	is_alt = false
	cancel_action = false
	tilemap.curr_cells_shift = []
	tilemap.get_selected_cells()
	tilemap.queue_redraw()

func _cancel_shape_draw():
	cancel_action = true
	tilemap.curr_cells_shift.clear()
	tilemap.get_selected_cells()
	tilemap.queue_redraw()
	
func _draw_on_release():
	if is_alt: select_cell(button_held)
	elif is_bucket:
		tilemap.draw_bucket(current_cell, match_button_action(button_held),l,current_alt)
	elif is_solving: pass
	elif not cancel_action:
		if is_shift:
			if is_ctrl: tilemap.draw_tile_rect(starter_cell, current_cell, match_button_action(button_held),l,current_alt)
			else: tilemap.draw_tile_line(starter_cell, current_cell, match_button_action(button_held),l,current_alt)
		elif not is_ctrl:
			if is_terrain: draw_terrain_cell(button_held)
			else: draw_tile(button_held)

func _draw_on_motion():
	# draw
	if is_shift:
		if is_ctrl: tilemap.curr_cells_shift = tilemap.get_rect_from(starter_cell, current_cell)
		else: tilemap.curr_cells_shift = get_bresenham_line(starter_cell, current_cell)
	elif is_terrain: draw_terrain_cell(button_held)
	elif is_solving: update_terrain_cell()
	elif not is_alt and not is_ctrl:
		# button held and no line / rect
		draw_tile(button_held)
		# preview single cell
		tilemap.curr_cells_shift = [current_cell]
	# other actions
	if is_alt: select_cell(button_held)

func _draw_first_tile_if_motion() -> bool:
	if current_cell != start_hold_cell: return false
	start_hold_cell = FARAWAY
	if is_shift: return false
	if not is_terrain: draw_tile(button_held)
	return true

func _solve_autotile_shape():
	update_terrain_space(painted_cells, 0)
	painted_cells.reverse() # why doing that ? idk but it doesn't work without
	update_terrain_space(painted_cells, 0)

func add_painted_cell(cell:Vector3i):
	painted_cells.append(cell)
	painted_cellsV2.append(vector2(cell))



func match_button_action(button:int):
	match button:
		MOUSE_BUTTON_LEFT: return tilemap.current_tile
		MOUSE_BUTTON_RIGHT: return tilemap.right_click_tile
		INVALID: return

func draw_tile(button:int):
	if is_alt or match_button_action(button) == null: return
	if !tilemap.current_brush_tiles.is_empty():
		tilemap.draw_custom_brush(current_cell, l, [null,null,tilemap.ERASE_TILE_ID][button])
	else: tilemap.draw_tile(current_cell, match_button_action(button),l,current_alt)

func select_cell(button:int):
	if is_bucket:
		var selected = tilemap.get_bucket_tiles(current_cell)
		tilemap.bucket_explored.clear()
		match button:
			MOUSE_BUTTON_LEFT:
				if not current_cell in tilemap.selected_cells: tilemap.selected_cells.append(current_cell)
				for cell in selected: if not cell in tilemap.selected_cells: tilemap.selected_cells.append(cell)
			MOUSE_BUTTON_RIGHT:
				if current_cell in tilemap.selected_cells: tilemap.selected_cells.erase(current_cell)
				for cell in selected: if cell in tilemap.selected_cells: tilemap.selected_cells.erase(cell)
	else:
		match button:
			MOUSE_BUTTON_LEFT: tilemap.set_selected_cells(current_cell)
			MOUSE_BUTTON_RIGHT: tilemap.unset_selected_cells(current_cell)

func _on_key_pressed(event:InputEventKey):
	if Input.is_key_pressed(KEY_CTRL) and event.keycode in [KEY_C, KEY_X] and not tilemap.selected_cells.is_empty():
		# copy selection
		tilemap.cells_to_brush(current_cell, [l, tilemap.ALL_LAYERS][int(palette.get_node("%Selections").get_selected_id() > 1)])
		if event.keycode == KEY_X:
			# cut selection
			for tile in tilemap.selected_cells:
				tilemap.draw_tile(tile, tilemap.ERASE_TILE_ID,l,current_alt)
		tilemap.selected_cells.clear()
		tilemap.queue_redraw()
#		is_custom_brush = !tilemap.current_brush_tiles.is_empty()

func _set_current_alt(value):
	current_alt = value
	tilemap.current_alt = value

func _transform_pattern(action:int):
	tilemap.transform_brush(action)


#### Terrain Manager ------

func _init():
	randomize()

func is_tile_in_drawing_mode(tile_modes, _drawing_modes:Array[String]=drawing_modes):
	if tile_modes.is_empty(): return true
	var ok_modes:Array[String] = _drawing_modes.duplicate()
	for mode in tile_modes:
		if not mode in _drawing_modes: return false
		ok_modes.erase(mode)
	for mode in ok_modes:
		if not mode in tile_modes: return false
	return true

func get_possible_terrain_tiles(cell:Vector2i, layer:int, terrain, _drawing_modes:Array[String]=drawing_modes, allow_random:bool=true):
	var possible_tiles:Array
	var tile_fulfill:bool = true
	
	for tile in terrain.keys():
		# check if we're in a valid drawing mode
		if not is_tile_in_drawing_mode(terrain[tile].get("drawing_modes", []), _drawing_modes): continue
		tile_fulfill = true
		for rule in terrain[tile].rules:
			if not check_rule_for_tile(cell, layer, rule):
				tile_fulfill = false
				break
		if tile_fulfill: possible_tiles.append(tile)
	return possible_tiles

enum RULE_LAYERS {Additive, Absolute, Global}
func check_rule_for_tile(cell:Vector2i, layer:int, rule:Dictionary):
	# check if the cell contains the tile described in the rule
	var rule_fulfilled:bool
	match int(rule.layer_type):
		RULE_LAYERS.Additive: rule_fulfilled = _match_tile_or_group(rule, cell, layer+rule.layer)
		RULE_LAYERS.Absolute: rule_fulfilled = _match_tile_or_group(rule, cell, rule.layer)
		RULE_LAYERS.Global:
			rule_fulfilled = false
			for l in tilemap.get_layers_count():
				if _match_tile_or_group(rule, cell, layer+rule.layer):
					rule_fulfilled = true
					break
	# check if this rule want this tile or not
	
	if (rule.prob == 0 and rule_fulfilled) or (rule.prob == 100 and not rule_fulfilled): return false
	if (rule.prob == 0 and not rule_fulfilled) or (rule.prob == 100 and rule_fulfilled): return true
	elif (rule_fulfilled and randi_range(0,100) < rule.prob): return true
	else: return false

func _match_tile_or_group(rule:Dictionary, cell:Vector2i, layer:int):
	var tile_vect = tilemap.get_cell(cell+rule.cell, layer).v
	if rule.tile.is_valid_int():
		return (tilemap._get_id_in_map(tile_vect) == rule.tile)
	else:
		return tilemap.is_tile_in_group(tile_vect, rule.tile)

func draw_terrain_cell(button:int, cell:Vector2i=current_cell, layer:int=l, group:String=palette.curr_group, _drawing_modes:Array[String]=drawing_modes, \
						allow_random:bool=true, update_neighbors:bool=true, neighbors:Array[Vector2i]=[], allow_create:bool=true):
	if match_button_action(button) == null: return
	if button == MOUSE_BUTTON_RIGHT:
		draw_tile(MOUSE_BUTTON_RIGHT)
		return
	var terrain:Dictionary = tilemap.tile_set.get_meta("Terrains", {}).get(group, {})
	if terrain == {}:
		draw_tile(MOUSE_BUTTON_LEFT)
		return
	if not allow_create and not str(tilemap._get_id_in_map(tilemap.get_cell(cell, layer).v)) in terrain: return
	
	var sum_weights:int = 0
	var possible:Array = get_possible_terrain_tiles(cell, layer, terrain, _drawing_modes, allow_random)
	if possible.size() == 1:
		tilemap.draw_tile(cell, new_TILEID_v3(tilemap._get_vect_in_map(int(possible[0]))), layer)
	elif possible.is_empty(): # disable some random features :(
#		tilemap.draw_tile(cell, new_TILEID_v3(tilemap.tile_set.get_meta("groups_by_groups")[group][0]), layer)
		tilemap.draw_tile(cell, tilemap.current_tile, layer)
	else:
		for tile in possible:
			sum_weights += terrain[tile].weight
			# TODO : alt tiles
		var res:int = randi_range(0, sum_weights)
		sum_weights = 0
		possible.shuffle()
		for tile in possible:
			sum_weights += terrain[tile].weight
			if not sum_weights >= res: continue
			tilemap.draw_tile(cell, new_TILEID_v3(tilemap._get_vect_in_map(int(tile))), layer)
			break
	
	if update_neighbors: update_terrain_drawn(cell, 1, group, allow_random, _drawing_modes)

func update_terrain_drawn(cell:Vector2i, ignore:int=1, group:String=palette.curr_group, allow_random:bool=false, _drawing_modes:Array[String]=drawing_modes, res:Array[Vector2i]=[]):
	if not update_settings == UPDATE_SETTINGS.Custom:
		var inferred = tilemap.tile_set.get_meta("Terrains_data")[group]["inferred_updates"]
		for c in inferred:
			if update_settings >= UPDATE_SETTINGS.King and not c in NEIGHBORS_KING: continue
			elif update_settings >= UPDATE_SETTINGS.Cardinal and not c in NEIGHBORS_CARDINAL: continue
			if update_settings >= UPDATE_SETTINGS.Painted and not cell+c in painted_cellsV2: continue
			res.append(cell+c)
	
	tilemap.allow_painted_overwrite = true
	for c in res:
		update_terrain_cell(c, l, group, _drawing_modes, allow_random)
	tilemap.allow_painted_overwrite = false

func update_terrain_space(area:Array[Vector3i], ignore:int=1, group:String=palette.curr_group, allow_random:bool=false, _drawing_modes:Array[String]=drawing_modes):
	if area.size() <= 1: return
	tilemap.allow_painted_overwrite = true
	for c in area.size()-ignore:
		update_terrain_cell(vector2(area[-1-ignore-c]), area[-1-ignore-c].z, group, _drawing_modes, allow_random, false)
	tilemap.allow_painted_overwrite = false

func update_terrain_area(area:Array[Vector2i], ignore:int=1, group:String=palette.curr_group, allow_random:bool=false, _drawing_modes:Array[String]=drawing_modes):
	if area.size() <= 1: return
	tilemap.allow_painted_overwrite = true
	for c in area.size()-ignore:
		update_terrain_cell(area[-1-ignore-c], l, group, _drawing_modes, allow_random, false)
	tilemap.allow_painted_overwrite = false

const NEIGHBORS_CARDINAL = [Vector2i(1,0),Vector2i(0,1),Vector2i(-1,0),Vector2i(0,-1)]
const NEIGHBORS_KING = [Vector2i(1,0),Vector2i(0,1),Vector2i(-1,0),Vector2i(0,-1),Vector2i(1,1),Vector2i(-1,-1),Vector2i(-1,1),Vector2i(1,-1)]
enum UPDATE_SETTINGS {Custom, Inferred, Cardinal, King, Painted}
func update_terrain_cell(cell:Vector2i=current_cell, layer:int=l, terrain:String=palette.curr_group, _drawing_modes:Array[String]=drawing_modes, allow_random:bool=true, update_neighbors:bool=false, neighbors:Array[Vector2i]=[]):
	draw_terrain_cell(MOUSE_BUTTON_LEFT, cell, layer, terrain, _drawing_modes, allow_random, update_neighbors, neighbors, false)

func update_drawing_modes():
	palette.sync_rule_settings()

#func current_drawing_modes():
#	return toolbar.get_drawing_modes()

################################

func get_tiles_ids(tileset:TileSet) -> Array[Dictionary]:
	var res:Array[Dictionary]; var curr_source; var tile:Dictionary
	for source_id in tileset.get_source_count():
#		if not tileset.has_source(source_id): continue
		curr_source = tileset.get_source(tileset.get_source_id(source_id))
		for index in curr_source.get_tiles_count():
			tile = new_TILEID(tileset.get_source_id(source_id), curr_source.get_tile_id(index))
			res.append(tile)
	return res

func duplicate_tiledata(tile:TileData):
	var new_data:TileData

# This function was made by Miziziziz at https://github.com/Miziziziz/ThineCometh/blob/master/objects/Enemy.gd
# It's an implementation of the bresenham algo : http://www.roguebasin.com/index.php?title=Bresenham%27s_Line_Algorithm
func get_bresenham_line(start:Vector2i, end:Vector2i):
	var dx = end.x - start.x
	var dy = end.y - start.y
	# Determine how steep the line is
	var is_steep = abs(dy) > abs(dx)
	var tmp = 0
	# Rotate line
	if is_steep:
		tmp = start.x
		start.x = start.y
		start.y = tmp
		tmp = end.x
		end.x = end.y
		end.y = tmp
	# Swap start and end points if necessary and store swap state
	var swapped = false
	if start.x > end.x:
		tmp = start.x
		start.x = end.x
		end.x = tmp
		tmp = start.y
		start.y = end.y
		end.y = tmp
		swapped = true
	# Recalculate differentials
	dx = end.x - start.x
	dy = end.y - start.y
	
	# Calculate error
	var error = int(dx / 2.0)
	var ystep = 1 if start.y < end.y else -1

	# Iterate over bounding box generating points between start and end
	var y = start.y
	var points:Array[Vector2i]
	for x in range(start.x, end.x + 1):
		var coord = Vector2i(y,x) if is_steep else Vector2i(x,y)
		points.append(coord)
		error -= abs(dy)
		if error < 0:
			y += ystep
			error += dx
	# handles negative coordinates
	if swapped:
		points.reverse()
	
	return points

func vector2(vect:Vector3i, start:int=0):
	return Vector2i(vect.x,vect.y)





#### API ----------------------------------

func create_alt_tiles(tile:Dictionary):
	var source:TileSetAtlasSource = tilemap.tile_set.get_source(tile.source)
	for i in 7:
		i += 1
		source.create_alternative_tile(tile.coords)
		if i%2 == 1: source.get_tile_data(tile.coords, i).flip_h = true
		if i in [2,3,6,7]: source.get_tile_data(tile.coords, i).flip_v = true
		if i > 3: source.get_tile_data(tile.coords, i).transpose = true

func erase_alt_tiles(tile:Dictionary):
	var source:TileSetAtlasSource = tilemap.tile_set.get_source(tile.source)
	for alt in source.get_alternative_tiles_count(tile.source):
		source.remove_alternative_tile(tile.source, alt)

func duplicate_tile(tile:Dictionary):
	tilemap.tile_set.add_source(tilemap.tile_set.get_source(tile.source).duplicate())
	

#### Tile Event Functions --------------------------------------------

# Built in #

func spawn(instance:StringName):
	pass

func add_tile(cell:Vector2i, tile:Dictionary, layer:int=tilemap.current_layer, alt:int=current_alt):
	tilemap.draw_tile(cell, tile, layer, alt)
