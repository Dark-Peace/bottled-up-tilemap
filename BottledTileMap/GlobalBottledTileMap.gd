@tool
extends Node


const ALT_H:Array = [1,3,5,7]
const ALT_V:Array = [2,3,6,7]
const ALT_T:Array = [4,5,6,7]

###############################

class TILEID:
	var source:int
	var coords:Vector2i
	var v:Vector3i
	var alt:int
	
	func _init(_source:int=-1, _coords:Vector2i=Vector2i(-1,-1), _alt:int=0):
		source = _source
		coords = _coords
		alt = _alt
		
		if _source < 0:
			coords.x = _source
			coords.y = _source
			
		v.z = source
		v.x = coords.x
		v.y = coords.y
	
	func _to_string():
		return "TILEID< "+str(source)+" ; "+str(coords)+">"
	
	func isEqual(other:TILEID):
		return source == other.source and coords == other.coords
	
	func isEqualV3(vect:Vector3i):
		return v == vect
		
	func isIn(list:Array[TILEID]):
		var res:bool = false
		for t in list:
			if isEqual(t): res = true
		return res


# canvas input handling ###############################

const INVALID:int = -1
var tilemap:BottledTileMap
var palette

var current_cell:Vector2i
var starter_cell:Vector2i
var current_alt:int = 0 : set = _set_current_alt
var l:int = 0
# states
var button_held:int = INVALID
var cancel_action:bool = false
var is_shift:bool = false
var is_ctrl:bool = false
var is_alt:bool = false
var is_bucket:bool = false
#var is_custom_brush:bool = false

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
	if button == (button_held%2)+1:
		cancel_action = true
		tilemap.curr_cells_shift.clear()
		tilemap.get_selected_cells()
		tilemap.queue_redraw()
	# setup
	current_cell = tilemap.local_to_map(tilemap.get_local_mouse_position())
	button_held = button
	# remember starter cell if SHIFT
	is_shift = Input.is_key_pressed(KEY_SHIFT)
	is_ctrl = Input.is_key_pressed(KEY_CTRL)
	is_alt = Input.is_key_pressed(KEY_ALT)
	is_bucket = Input.is_key_pressed(KEY_SPACE)
	if is_shift:
		starter_cell = current_cell

func handle_click_release():
	# draw
	if is_alt: select_cell(button_held)
	elif is_bucket:
		tilemap.draw_bucket(current_cell, match_button_action(button_held),l,current_alt)
	elif not cancel_action:
		if is_shift:
			if is_ctrl: tilemap.draw_tile_rect(starter_cell, current_cell, match_button_action(button_held),l,current_alt)
			else: tilemap.draw_tile_line(starter_cell, current_cell, match_button_action(button_held),l,current_alt)
		elif is_ctrl: palette.pick_tile(tilemap.get_cell(current_cell))
		else: draw_tile(button_held)
	
	# end of action : reset
	button_held = INVALID
	is_ctrl = false
	is_shift = false
	is_alt = false
	cancel_action = false

func handle_motion():
	if is_bucket or current_cell == tilemap.local_to_map(tilemap.get_local_mouse_position()):
		return
	
	# update current cell
	tilemap.cell_exited.emit(current_cell)
	current_cell = tilemap.local_to_map(tilemap.get_local_mouse_position())
	if is_shift:
		if is_ctrl: tilemap.curr_cells_shift = tilemap.get_rect_from(starter_cell, current_cell)
		else: tilemap.curr_cells_shift = get_bresenham_line(starter_cell, current_cell)
	else:
		# button held and no line / rect
		draw_tile(button_held)
		# preview single cell
		var new_cells_shift:Array[Vector2i] = [current_cell]
		tilemap.curr_cells_shift = new_cells_shift
	if is_alt:
		select_cell(button_held)
	# draw preview
	tilemap.cell_entered.emit(current_cell)
	tilemap.queue_redraw()


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
			MOUSE_BUTTON_LEFT: tilemap.set_selected_cells()
			MOUSE_BUTTON_RIGHT: tilemap.unset_selected_cells()
			INVALID: return

func _on_key_pressed(event:InputEventKey):
	if Input.is_key_pressed(KEY_CTRL) and event.keycode in [KEY_C, KEY_X] and not tilemap.selected_cells.is_empty():
		# copy selection
		tilemap.cells_to_brush(current_cell, [l, tilemap.ALL_LAYERS][palette.get_node("%Selections").get_selected_id() > 1])
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

################################

func get_tiles_ids(tileset:TileSet) -> Array[TILEID]:
	var res:Array[TILEID]; var curr_source; var tile:TILEID
	for source_id in tileset.get_next_source_id():
		if not tileset.has_source(source_id): continue
		curr_source = tileset.get_source(source_id)
		for index in curr_source.get_tiles_count():
			tile = TILEID.new(source_id, curr_source.get_tile_id(index))
			res.append(tile)
	return res

func duplicate_tile(tile:TILEID):
	pass

func duplicate_tiledata(tile:TileData):
	var new_data:TileData

# this function was made by Miziziziz at https://github.com/Miziziziz/ThineCometh/blob/master/objects/Enemy.gd
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
