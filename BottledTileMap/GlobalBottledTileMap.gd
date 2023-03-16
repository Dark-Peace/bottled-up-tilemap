@tool
extends Node


###############################

class TILEID:
	var source:int
	var coords:Vector2i
	var v:Vector3i
	
	func _init(_source:int=-1, _coords:Vector2i=Vector2i(-1,-1)):
		source = _source
		coords = _coords
		
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
var bottledtilemap:BottledTileMap
var palette

var current_cell:Vector2i
var starter_cell:Vector2i
var current_alt:int = 0
var l:int = 0
# states
var button_held:int = INVALID
var cancel_action:bool = false
var is_shift:bool = false
var is_ctrl:bool = false
var is_alt:bool = false
var is_bucket:bool = false
var is_custom_brush:bool = false

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
		bottledtilemap.curr_cells_shift.clear()
		bottledtilemap.get_selected_cells()
		bottledtilemap.queue_redraw()
	# setup
	current_cell = bottledtilemap.local_to_map(bottledtilemap.get_local_mouse_position())
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
		bottledtilemap.draw_bucket(current_cell, match_button_action(button_held),l,current_alt)
	elif not cancel_action:
		if is_shift:
			if is_ctrl: bottledtilemap.draw_tile_rect(starter_cell, current_cell, match_button_action(button_held),l,current_alt)
			else: bottledtilemap.draw_tile_line(starter_cell, current_cell, match_button_action(button_held),l,current_alt)
		else: draw_tile(button_held)
	
	# end of action : reset
	button_held = INVALID
	is_ctrl = false
	is_shift = false
	is_alt = false
	cancel_action = false

func handle_motion():
	if is_bucket or current_cell == bottledtilemap.local_to_map(bottledtilemap.get_local_mouse_position()):
		return
	
	# update current cell
	bottledtilemap.cell_exited.emit(current_cell)
	current_cell = bottledtilemap.local_to_map(bottledtilemap.get_local_mouse_position())
	if is_shift:
		if is_ctrl: bottledtilemap.curr_cells_shift = bottledtilemap.get_rect_from(starter_cell, current_cell)
		else: bottledtilemap.curr_cells_shift = get_bresenham_line(starter_cell, current_cell)
	else:
		# button held and no line / rect
		draw_tile(button_held)
		# preview single cell
		var new_cells_shift:Array[Vector2i] = [current_cell]
		bottledtilemap.curr_cells_shift = new_cells_shift
	if is_alt:
		select_cell(button_held)
	# draw preview
	bottledtilemap.cell_entered.emit(current_cell)
	bottledtilemap.queue_redraw()


func match_button_action(button:int):
	match button:
		MOUSE_BUTTON_LEFT: return bottledtilemap.current_tile
		MOUSE_BUTTON_RIGHT: return bottledtilemap.ERASE_TILE_ID
		INVALID: return

func draw_tile(button:int):
	if is_alt or match_button_action(button) == null: return
	if is_custom_brush:
		bottledtilemap.draw_custom_brush(current_cell, bottledtilemap.current_layer, [null,null,bottledtilemap.ERASE_TILE_ID][button])
	else: bottledtilemap.draw_tile(current_cell, match_button_action(button),l,current_alt)

func select_cell(button:int):
	if is_bucket:
		var selected = bottledtilemap.get_bucket_tiles(current_cell)
		bottledtilemap.bucket_explored.clear()
		match button:
			MOUSE_BUTTON_LEFT:
				if not current_cell in bottledtilemap.selected_cells: bottledtilemap.selected_cells.append(current_cell)
				for cell in selected: if not cell in bottledtilemap.selected_cells: bottledtilemap.selected_cells.append(cell)
			MOUSE_BUTTON_RIGHT:
				if current_cell in bottledtilemap.selected_cells: bottledtilemap.selected_cells.erase(current_cell)
				for cell in selected: if cell in bottledtilemap.selected_cells: bottledtilemap.selected_cells.erase(cell)
	else:
		match button:
			MOUSE_BUTTON_LEFT: bottledtilemap.set_selected_cells()
			MOUSE_BUTTON_RIGHT: bottledtilemap.unset_selected_cells()
			INVALID: return

func _on_key_pressed(event:InputEventKey):
	if Input.is_key_pressed(KEY_CTRL) and event.keycode in [KEY_C, KEY_X] and not bottledtilemap.selected_cells.is_empty():
		# copy selection
		bottledtilemap.cells_to_brush(current_cell)
		if event.keycode == KEY_X:
			# cut selection
			for tile in bottledtilemap.selected_cells:
				bottledtilemap.draw_tile(tile, bottledtilemap.ERASE_TILE_ID,l,current_alt)
		bottledtilemap.selected_cells.clear()
		bottledtilemap.queue_redraw()
		is_custom_brush = !bottledtilemap.current_brush_tiles.is_empty()




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
