@tool
extends TileMap
class_name BottledTileMap

### Made by Dark Peace
# Wanna request a feature / report a bug / ask a question ?
# Then join my discord : https://discord.gg/aWWQbgQUEP
# Plugin documentation :
# https://docs.google.com/document/d/1y2aPsn72dOxQ-wBNGqLlQvrw9-SV_z12a1MradBglF4/edit?usp=sharing"
###

## Editor signals
signal cell_entered(_cell:Vector2i) # mouse enters cell in editor
signal cell_exited(_cell:Vector2i)
## Tile Event trigger signals
signal tile_drawn(_tile:Dictionary, _cell:Vector2i) # drawn in editor
signal tile_erased(_previous_tile:Dictionary, _cell:Vector2i) # erased in editor
signal tile_created(_tile:Dictionary, _cell:Vector2i) # created by code at game runtime
signal tile_destroyed(_previous_tile:Dictionary, _cell:Vector2i) # erased by code at game runtime
signal trigger_tile_event(_cell:Vector2i, event_index:String) # send a signal to trigger a specific tile event on a specific cell
signal trigger_global_event(event_index:String) # send a signal to trigger a specific tile event on the whole map

enum BrushType {CIRCLE, SQUARE, SQUARE_ROTATED, LINE_H, LINE_V}
enum TransfoActions {FLIP_H, FLIP_V, ROTATE_RIGHT, ROTATE_LEFT}

const PREVIEW_TILE_COLOR:Color = Color(1,1,1,.5)
const PREVIEW_CELL_SELECTED:Color = Color(0.392157, 0.584314, 0.929412, .3)
const MAX_BUCKET_RECURSION:int = 100
var EMPTY_TILE_ARRAY:Array[Dictionary] = [] : get = _EMPTY_TILE_ARRAY
const NO_THEME = "-1"
const DEFAULT_THEME = "CUSTOM"

const LINE_WIDTH = 3
const X_AXIS = 1
const Y_AXIS = 2
const BOTH_AXIS = 3
const EVERY_TILEMAP = -1
const ALL_LAYERS = -1

const ERASE_TILE = -1
const NO_TILE = -2
const ALL_TILES = -3
const ANY_TILE = -4
const WIPE_TILE = -5
const NO_TILE_V = Vector3i(-2,-2,-2)
const ALL_TILES_V = Vector3i(-3,-3,-3)
const ERASE_TILE_V = Vector3i(-1,-1,-1)
var NO_TILE_ID:Dictionary = BTM.new_TILEID(NO_TILE)
#var ALL_TILES_ID:BTM.TILEID = BTM.TILEID.new(ALL_TILES)
var ERASE_TILE_ID:Dictionary = BTM.new_TILEID(ERASE_TILE)

# CIRCLES
@export_group("Brushes")
@export var brush_shape:BrushType = BrushType.CIRCLE
@export_range(1,999999,0.001, "hide_slider", "suffix:tile(s)") var brush_size:float = 1
@export var shape_filled = true
@export_range(1,999999,0.001, "hide_slider", "suffix:tile(s)") var outline_width:float = 1
# SPRAY
@export_range(0,999999,1,"suffix:tile(s)") var spray_density:int = 0
@export_range(0,1) var scattering:float = 0
@export_subgroup("Randomness")
enum RandomAccross {Cursors=8, TileMaps=4, BrushShape=2, Symmetry=1}
@export_flags("Cursors","TileMaps","BrushShape","Symmetry") var allow_random:int = 15
#@export var no_random_accross:RandomAccross = RandomAccross.Nowhere
var use_tile_random:bool = false
var use_alt_random:bool = false

@export_subgroup("Drawing Rules")
@export var scatter_affects_erase = false
@export_range(-3,999999,1,"suffix:TileID") var no_draw_on:int = NO_TILE
@export_range(-3,999999,1,"suffix:TileID") var only_draw_on:int = NO_TILE


# REPLACING
@export_group("Replacing")
@export_range(-3,999999,1,"suffix:TileID") var replace_tile:int
@export_range(-3,999999,1,"suffix:TileID") var replace_by:int
var r_y_as_random_pattern = false #TODO
@export var REPLACE:bool = false : set = set_global_replacing


# PATTERN
@export_group("Patterns")
enum CENTER {origin, mouse}
enum BRUSH {whole_pattern, one_tile}
@export var center_pattern:CENTER = CENTER.origin
@export var apply_pattern:BRUSH = BRUSH.one_tile
@export var can_pattern_replace = true
#var patterns = "" : set = set_patterns
#@export_range(-1,INF) var pattern_id:int = -1
#@export_multiline var patterns = "" : set = set_patterns
#@export var turn_into_pattern:bool = false : set = set_turn_into_pattern
@export var allow_autotile:bool = false
var pattern_id:int = -1 : set = set_pattern_id
var pattern_list:Array[Dictionary]


# SYMMETRY
@export_group("Symmetry")
@export var axis_pos:Vector2i = Vector2i.ZERO : set = set_axis_pos
@export_flags("X","Y") var axis:int = 0 : set = set_axis
@export_subgroup("Customisation")
@export var limit_color = Color.AQUAMARINE : set = set_limit_color
@export_range(0,999999,0.001, "hide_slider","suffix:px") var display_length:float = 1000


# MULTI CURSOR
@export_group("Multi Cursors")
@export_placeholder("ex: 0;1;2") var use_those:String : set = read_used_cursors
var used_cursors:Array[Vector2i] = []
@export var multi_cursor_list:Array[Vector2i] : set = set_multi_cursor
var cursor_texture = load("res://addons/BottledTileMap/icon.png")
#var c_cursor_color = Color.AQUA : set = set_cursor_color


# MULTI TILEMAPS
@export_group("Multi TileMaps")
@export_placeholder("ex: 0;1;2") var use_these:String : set = read_used_tilemaps
@export var tilemap_list:Array[NodePath] = []
var used_tilemaps:Array[TileMap] = []
@export var SCAN:bool : set = scan_for_tilemaps
var curr_tilemap:TileMap : set = set_curr_tilemap

# TILESETS
@export_group("TileSet")
@export_subgroup("Alternative Tiles", "alt_")
@export_range(0,INF) var alt_create_range:int = 0
@export var alt_create_colors:Gradient

# store dock var
@export var dock_group_selected:String = "ALL_TILES"
@export var dock_save_selected_tiles:Dictionary
#@export var dock_tile_selected:String = "0"

# INSTANCES
#var instance_dict = {}

#-------------------------------------------------------------------------------------------

var to_init = true
var can_trigger = true
var can_trigger_multi = true
var origin = Vector2(0,0)
var can_origin:bool = true
var allow_painted_overwrite:bool = false

var label = Label.new()
var font = label.get_theme_font("")
var tm_hints:Array = []

var curr_tile_reg:Rect2
var curr_tile_texture:Texture2D
var current_tile:Dictionary : set = set_current_tile
var right_click_tile:Dictionary = ERASE_TILE_ID
var current_brush_tiles:Dictionary
var current_cells:Array[Vector2i]
var curr_cells_shift:Array[Vector2i]
var max_cells_preview = INF
var selected_cells:Array[Vector2i] : set = set_selected_cells
var bucket_explored:Array[Vector2i]
var current_layer:int = 0
var current_alt:int=0
var ID_map:Dictionary
var used_theme:String = NO_THEME

## Godot 4
var cell_size = tile_set.tile_size
var mode = tile_set.tile_shape


func init():
	randomize()
	read_used_tilemaps(use_these)
	BTM.tilemap = self
	cell_entered.connect(_on_cell_entered)
	self.changed.connect(_on_tileset_changed)
	
	if not tile_set.has_meta("ID_Map"): _on_tileset_changed()
	if not tile_set.has_meta("groups_by_icons"): tile_set.set_meta("groups_icons", {})
	if not tile_set.has_meta("groups_by_groups"): tile_set.set_meta("groups_by_groups", {})
	if not tile_set.has_meta("groups_by_ids"): tile_set.set_meta("groups_by_ids", {})
	if not tile_set.has_meta("TILE_EVENTS"): tile_set.set_meta("TILE_EVENTS", {})
	if not tile_set.has_meta("Terrains"): tile_set.set_meta("Terrains", {})
	if not tile_set.has_meta("Terrains_data"): tile_set.set_meta("Terrains_data", {})
	_update_id_map()

func _on_tileset_changed():
	var tiles:Array[Dictionary] = BTM.get_tiles_ids(tile_set)
	tile_set.set_meta("TileList", tiles)
	_update_id_map()
	ID_map[ALL_TILES] = ALL_TILES_V
	ID_map[NO_TILE] = NO_TILE_V

func _update_id_map():
	if not tile_set.has_meta("ID_Map"): tile_set.set_meta("ID_Map", {"__NEXT_ID__": 0})
	var id_map = tile_set.get_meta("ID_Map")
	for tile in tile_set.get_meta("TileList", EMPTY_TILE_ARRAY):
		if id_map.values().has(tile.v): continue
		id_map[id_map["__NEXT_ID__"]] = tile.v
		id_map["__NEXT_ID__"] = id_map["__NEXT_ID__"]+1
	ID_map = id_map

func _get_id_in_map(v:Vector3i):
	if not v in ID_map.values(): return -1
	return ID_map.keys()[ID_map.values().find(v,1)]

func _get_vect_in_map(id:int):
	if not id in ID_map.keys(): return Vector3(-1,-1,-1)
	return ID_map[id]

func _process(delta: float) -> void:
	if to_init:
		to_init = false
		init()
#		set_process(false)
	if not Engine.is_editor_hint(): set_process(false)

func _ready() -> void:
	if Engine.is_editor_hint(): return
	scan_for_tileset(get_tree().current_scene)

func scan_for_tileset(node):
	var instance; var parent; var entry_i; var entry_p;
	if node is TileMap and node.tile_set.has_meta("instances") and node.tile_set.has_meta("parents"):
		entry_i = node.tile_set.get_meta("instances")
		entry_p = node.tile_set.get_meta("parents")
		for tile in entry_i.keys():
			if entry_i[tile] == "" or entry_p[tile] == "": continue
			for pos in node.get_used_cells(tile):
				instance = load(entry_i[tile]).instantiate()
				get_tree().current_scene.get_node(entry_p[tile]).add_child(instance)
	for child in node.get_children(): scan_for_tileset(child)

func _draw() -> void:
	var angle_offset = 0
	if mode == tile_set.TILE_SHAPE_ISOMETRIC: angle_offset = PI/4

	angle_offset = 0
	if mode == tile_set.TILE_SHAPE_ISOMETRIC: angle_offset = display_length
	if axis > 0:
		var display_vector; var start_point; var end_point
		match axis:
			X_AXIS: _draw_symmetry_axis(Vector2(display_length,angle_offset))
			Y_AXIS: _draw_symmetry_axis(Vector2(-angle_offset,display_length))
			BOTH_AXIS:
				_draw_symmetry_axis(Vector2(display_length,angle_offset))
				_draw_symmetry_axis(Vector2(-angle_offset,display_length))

	if not used_cursors.is_empty():
		for c in used_cursors:
			if c == Vector2i.ZERO: continue
			draw_texture(cursor_texture, Vector2i(get_local_mouse_position())+cell_size*c, Color.WHITE)
	if not tm_hints.is_empty():
		for i in tm_hints.size():
			draw_string(font, get_local_mouse_position()+Vector2(10,15*i), tm_hints[i].name, 0,-1,16, Color.AQUA)
	
	# TODO match tools
	# preview custom brush
	if not current_brush_tiles.is_empty():
		var cell_rect:Rect2; var tile:TileSetAtlasSource
		var reg:Rect2; var transpose:bool = false
		for t in current_brush_tiles.keys():
			cell_rect = Rect2(Vector2i(local_to_map(get_local_mouse_position())+BTM.vector2(t))*cell_size,cell_size)
			tile = tile_set.get_source(current_brush_tiles[t].source)
			reg = tile.get_tile_texture_region(current_brush_tiles[t].coords)
			# handles alt tiles transfo
			if current_alt in BTM.ALT_H: reg.size.x = -reg.size.x
			if current_alt in BTM.ALT_V: reg.size.y = -reg.size.y
			if current_alt in BTM.ALT_T: transpose = true
			draw_texture_rect_region(tile.texture, cell_rect, reg, PREVIEW_TILE_COLOR, transpose)
	# Preview of the cell being painted
	elif curr_tile_reg != Rect2():
		var reg:Rect2 = curr_tile_reg
		var transpose:bool = false
		# handle alternate tiles
		if current_alt in BTM.ALT_H: reg.size.x = -reg.size.x
		if current_alt in BTM.ALT_V: reg.size.y = -reg.size.y
		if current_alt in BTM.ALT_T: transpose = true
		# preview cell at mouse pos
		var cell_rect:Rect2 = Rect2(local_to_map(get_local_mouse_position())*cell_size, cell_size)
		draw_texture_rect_region(curr_tile_texture, cell_rect, reg, PREVIEW_TILE_COLOR, transpose)
		# preview for multi cursors
		for c in used_cursors:
			var cursor_pos:Vector2i = Vector2i(get_local_mouse_position())+cell_size*c
			cell_rect = Rect2(local_to_map(cursor_pos)*cell_size, cell_size)
			draw_texture_rect_region(curr_tile_texture, cell_rect, reg, PREVIEW_TILE_COLOR, transpose)
			if current_cells.size() > max_cells_preview: continue
			# preview for big brushes
			for cell in current_cells:
				cell_rect = Rect2((c+cell)*cell_size, cell_size)
				draw_texture_rect_region(curr_tile_texture, cell_rect, reg, PREVIEW_TILE_COLOR, transpose)
		# preview for big brushes
		if current_cells.size() <= max_cells_preview:
			for cell in current_cells:
				cell_rect = Rect2(cell*cell_size, cell_size)
				draw_texture_rect_region(curr_tile_texture, cell_rect, reg, PREVIEW_TILE_COLOR, transpose)
	
	# preview of cell selection
	if not selected_cells.is_empty():
		for cell in selected_cells:
			draw_rect(Rect2(cell*cell_size, cell_size), PREVIEW_CELL_SELECTED)
	

func _draw_symmetry_axis(display_vector:Vector2i):
	var start_point = (axis_pos+display_vector)
	var end_point = (axis_pos-display_vector)
	draw_line(start_point,end_point,limit_color,LINE_WIDTH)


func draw_tile_line(start:Vector2i, end:Vector2i, tile:Dictionary=current_tile, l:int=current_layer, alt:int=current_alt):
	for cell in BTM.get_bresenham_line(start, end):
		draw_tile(cell, tile, l, alt)

func draw_tile_rect(start:Vector2i, end:Vector2i, tile:Dictionary=current_tile, l:int=current_layer, alt:int=current_alt):
	for cell in get_rect_from(start, end):
		draw_tile(cell, tile, l, alt)

func draw_bucket(xy:Vector2i, tile:Dictionary=current_tile, l:int=current_layer, alt:int=current_alt, replaced:Dictionary=get_cell(xy, l)):
	draw_tile(xy, tile, l, alt)
	var selected = get_bucket_tiles(xy, l, replaced)
	for cell in selected:
		draw_tile(cell, tile, l, alt)
	bucket_explored.clear()

func draw_custom_brush(xy:Vector2i, l:int=current_layer, tile=null):
	if tile != null:
		for t in current_brush_tiles.keys():
			draw_tile(xy+BTM.vector2(t), tile, l+t.z)
	else:
		for t in current_brush_tiles.keys():
			draw_tile(xy+BTM.vector2(t), current_brush_tiles[t], l+t.z)

func draw_bezier(start:Vector2i, ctrl1:Vector2i, ctrl2:Vector2i, end:Vector2i, tile:Dictionary=current_tile, l:int=current_layer, alt:int=current_alt):
	var xu:float = 0; var yu:float = 0; var u:float = 0; var dist:int = abs(end.x-start.x)
	const MULTI:float = 2
	for i in range(0,dist*MULTI):
		u = i/(dist*MULTI)
		xu = pow(1-u,3)*start.x+3*u*pow(1-u,2)*ctrl1.x+3*pow(u,2)*(1-u)*ctrl2.x+pow(u,3)*end.x
		yu = pow(1-u,3)*start.y+3*u*pow(1-u,2)*ctrl1.y+3*pow(u,2)*(1-u)*ctrl2.y+pow(u,3)*end.y
		print(Vector2i(xu,yu), u)
		draw_tile(Vector2i(xu,yu), tile, l, alt)
	
#void bezierCurve(int x[] , int y[])
#{
#    double xu = 0.0 , yu = 0.0 , u = 0.0 ;
#    int i = 0 ;
#    for(u = 0.0 ; u <= 1.0 ; u += 0.0001)
#    {
#        xu = pow(1-u,3)*x[0]+3*u*pow(1-u,2)*x[1]+3*pow(u,2)*(1-u)*x[2]
#             +pow(u,3)*x[3];
#        yu = pow(1-u,3)*y[0]+3*u*pow(1-u,2)*y[1]+3*pow(u,2)*(1-u)*y[2]
#            +pow(u,3)*y[3];
#        SDL_RenderDrawPoint(renderer , (int)xu , (int)yu) ;
#    }
#}

func draw_tile(xy:Vector2i, tile:Dictionary=current_tile, l:int=current_layer, alt:int=current_alt):
	# handle random tile in group
	
	# multi-cursor handler
	if used_cursors.size() > 0 and can_trigger_multi:# and not tile.isEqual(get_cell(xy, l)):
		can_trigger_multi = false
		for c in used_cursors:
			if can_pattern_replace or get_cell(xy+c, l).source == ERASE_TILE:
				if use_tile_random and (allow_random & RandomAccross.Cursors): tile = pick_random_tile()
				if use_alt_random and (allow_random & RandomAccross.Cursors): alt = randi()%8
				draw_tile(xy+c,tile,l,alt)
				if allow_autotile: update_bitmask_area(xy+c)
		can_trigger_multi = true

	# no pattern selected
	if pattern_id == -1:
		if brush_size > 1 and can_trigger:
			can_trigger = false
			# use circle tool
			if spray_density == 0:
				current_cells = get_tiles_with_brush(xy)
				for t in current_cells:
					call_all_draw(t,tile,l,alt, CALLTYPE.Brush)
			# use spray tool
			else:
				current_cells = spray(xy)
				for t in current_cells:
					call_all_draw(t,tile,l,alt, CALLTYPE.Brush)
			can_trigger = true
		else:
			call_all_draw(xy,tile,l,alt, CALLTYPE.Single) # case that doesn't change from a normal tilemap
		if not can_origin: can_origin = true
		return

	get_origin(xy)

	# use pattern tool #TODO
#	if apply_pattern == BRUSH.one_tile:
#		# use spray or circle tool
#		if brush_size > 1 and can_trigger:
#			can_trigger = false
#			if spray_density == 0:
#				for t in get_tiles_with_brush(xy):
#					id = get_tileIDv(t-origin)
#					if id != NO_TILE: call_all_draw(xy,tile,l,get_random_subtile(id, tile.coords))
#			else:
#				for t in spray(xy):
#					id = get_tileIDv(t-origin)
#					if id != NO_TILE: call_all_draw(xy,tile,l,get_random_subtile(id, tile.coords))
#			can_trigger = true
#		# draw single tile
#		else:
#			id = get_tileIDv(xy-origin)
#			if id == NO_TILE: return # use transparancy tile
#			call_all_draw(xy,tile,l,get_random_subtile(id, tile.coords))
#	# draw with whole pattern
#	elif apply_pattern == BRUSH.whole_pattern:
#		if can_trigger:
#			can_trigger = false
#			place_pattern(l,xy,tile.coords,alt) #TODO
#			can_trigger = true
#		else: call_all_draw(xy,tile,l,get_random_subtile(id, tile.coords))

func get_v_from_ID(tile:int=-1):
	match tile:
		NO_TILE: return NO_TILE_V
		ALL_TILES: return ALL_TILES_V
	return ID_map[tile]

enum CALLTYPE {Single, Brush}
func call_all_draw(xy:Vector2i,tile:Dictionary,l:int=current_layer,alt:int=current_alt, call_type=0):
	if BTM.isEqualV3(get_cell(xy,l), get_v_from_ID(no_draw_on)) \
		or (only_draw_on != NO_TILE and not BTM.isEqualV3(get_cell(xy,l), get_v_from_ID(only_draw_on))) or tile.source < -1:
			return
	
	if use_tile_random and ((call_type == CALLTYPE.Brush and (allow_random & RandomAccross.BrushShape)) or call_type == CALLTYPE.Single):
		tile = pick_random_tile(true)
	if use_alt_random and ((call_type == CALLTYPE.Brush and (allow_random & RandomAccross.BrushShape)) or call_type == CALLTYPE.Single):
		alt = randi()%8
	
	if not BTM.isEqual(tile, get_cell(xy, l)):
		var test = randf_range(0,1)
		if scattering > 0 and test <= scattering and (tile.source != ERASE_TILE or scatter_affects_erase): return
		for tm in used_tilemaps:
			if use_tile_random and (allow_random & RandomAccross.TileMaps): tile = pick_random_tile(true)
			if use_alt_random and (allow_random & RandomAccross.TileMaps): alt = randi()%8
			tm.set_cell(l,xy,tile.source,tile.coords,alt)
#			draw_symmetry(xy,tile,l,alt) #TODO multi tilemap symmetry
		_call_draw(xy,tile,l,alt)
		draw_symmetry(xy,tile,l,alt)
	if allow_autotile: update_bitmask_area(xy)

func _call_draw(xy:Vector2i,tile:Dictionary,l:int=current_layer,alt:int=current_alt):
	if not allow_painted_overwrite and Vector3i(xy.x,xy.y,l) in BTM.painted_cells: return
	super.set_cell(l,xy,tile.source,tile.coords,alt)
	send_draw_signals(xy, tile, l)
	if tile.source == ERASE_TILE: return
	BTM.add_painted_cell(Vector3i(xy.x,xy.y,l))
#	BTM.painted_cells.append(Vector3i(xy.x,xy.y,l))

func match_themes(tile:Dictionary) -> Dictionary:
	if used_theme == NO_THEME: return tile
	var swap_list = tile_set.get_meta("THEMES")[used_theme]
	for s in swap_list:
		if ID_map[int(s[0])] == tile.v:
			# tile in theme
			var new_tile:Vector3i = ID_map[int(s[1])]
			return BTM.new_TILEID(new_tile.z, BTM.vector2(new_tile))
			break
	# tile not affected by theme
	return tile

func send_draw_signals(xy:Vector2i, tile:Dictionary, l:int=current_layer):
	var cell = get_cell(xy,l)
	if BTM.isEqual(cell, tile): return
	if BTM.isEqual(tile, ERASE_TILE_ID): tile_erased.emit(cell, xy)
	else: tile_drawn.emit(tile, xy)

func _on_cell_entered(cell:Vector2i):
	if max_cells_preview <= 0: return
	get_selected_cells()

func get_selected_cells():
	current_cells.clear()
	
	for c in curr_cells_shift:
		if brush_size > 1:
			if spray_density > 0: current_cells.append_array(spray(c))
			else: current_cells.append_array(get_tiles_with_brush(c))
		else: current_cells.append(c)
		
	if axis > 0:
		for _c in current_cells.size():
			current_cells.append_array(get_symmetry_tiles(current_cells[_c]))
		
	return current_cells

func select_all_cells(layer:int=current_layer, tile:Dictionary=NO_TILE_ID, keep_selection:bool=false):
	var res:Array[Vector2i]
	if BTM.isEqual(tile, NO_TILE_ID) and not keep_selection:
		if layer == ALL_LAYERS:
			for l in get_layers_count():
				res.append_array(get_used_cells(l))
		else: res = get_used_cells(layer)
	else:
		if layer == ALL_LAYERS:
			for l in get_layers_count():
				for t in get_used_cells(l):
					if not BTM.isEqual(get_cell(t,l), tile) and (not keep_selection or t in current_cells): continue
					res.append(t)
		else:
			for t in get_used_cells(layer):
				if not BTM.isEqual(get_cell(t,layer), tile) and (not keep_selection or t in current_cells): continue
				res.append(t)
	return res

func draw_symmetry(xy:Vector2i,tile:Dictionary,l:int=current_layer,alt=current_alt):
	if axis == 0: return
	if use_tile_random and (allow_random & RandomAccross.Symmetry): tile = pick_random_tile(true)
	if use_alt_random and (allow_random & RandomAccross.Symmetry): alt = randi()%8
	
	var id=tile.source; var _a = tile.coords;
	if axis == X_AXIS:
		var new_vect:Vector2i = xy+Vector2i(0,-2*(xy.x-axis_pos.x)-1)
		_call_draw(new_vect,tile,l,alt)
#		super.set_cell(l,new_vect,id,_a,alt)
#		send_draw_signals(new_vect, tile, l)
	elif axis == Y_AXIS:
		var new_vect:Vector2i = xy+Vector2i(-2*(xy.y-axis_pos.y)-1,0)
		_call_draw(new_vect,tile,l,alt)
#		super.set_cell(l,new_vect,id,_a,alt)
#		send_draw_signals(new_vect, tile, l)
	elif axis == BOTH_AXIS:
		var part_vect:Vector2i = Vector2i((-2*(xy.x-axis_pos.x)-1),(-2*(xy.y-axis_pos.y)-1))
		_call_draw(xy+Vector2i(part_vect.x,0),tile,l,alt)
		_call_draw(xy+Vector2i(0,part_vect.y),tile,l,alt)
		_call_draw(xy+Vector2i(part_vect.x,part_vect.y),tile,l,alt)
#		super.set_cell(l,xy+Vector2i(part_vect.x,0),id,_a,alt)
#		super.set_cell(l,xy+Vector2i(0,part_vect.y),id,_a,alt)
#		super.set_cell(l,xy+Vector2i(part_vect.x,part_vect.y),id,_a,alt)
#		send_draw_signals(xy+Vector2i(part_vect.x,0), tile, l)
#		send_draw_signals(xy+Vector2i(0,part_vect.y), tile, l)
#		send_draw_signals(xy+Vector2i(part_vect.x,part_vect.y), tile, l)

func get_symmetry_tiles(xy:Vector2i):
	if axis == 0: return
	var res:Array[Vector2i]
	
	if axis == X_AXIS: res.append(xy+Vector2i(0,-2*(xy.x-axis_pos.x)-1))
	elif axis == Y_AXIS: res.append(xy+Vector2i(-2*(xy.y-axis_pos.y)-1,0))
	elif axis == BOTH_AXIS:
		var part_vect:Vector2i = Vector2i((-2*(xy.x-axis_pos.x)-1),(-2*(xy.y-axis_pos.y)-1))
		res.append(xy+Vector2i(part_vect.x,0))
		res.append(xy+Vector2i(0,part_vect.y))
		res.append(xy+Vector2i(part_vect.x,part_vect.y))
	
	return res

# draw pattern checked map
#func place_pattern(l:int, xy:Vector2i,_a,alt): #TODO
#	var matrix = pattern_list[pattern_id]
#	var m_size = matrix.size()
#	var id
#	for line in m_size:
#		for column in matrix[line].size():
#			id = get_tileID(xy.x+column-origin.x,xy.y+line-origin.y)
#			if id != NO_TILE and (can_pattern_replace or get_cell(xy+Vector2i(column,line), l) == ERASE_TILE):
#				call_all_draw(xy+Vector2i(column,line),tile,l,get_random_subtile(id, _a))

func set_current_layer(value, button:OptionButton):
	current_layer = value
	BTM.l = current_layer
	button.select(value)

func get_origin(xy:Vector2i):
	if not can_origin: return
	if center_pattern == CENTER.origin: origin = Vector2i.ZERO
	elif center_pattern == CENTER.mouse: origin = xy

#func format_patterns(): #TODO
#	pattern_list = patterns.split("\n\n",false)
#	var p:Array; var t:Array;
#	for m in pattern_list:
#		p = m.split("\n",false)
#		pattern_list.push_front(p)
#		pattern_list.erase(m)
#		for l in p:
#			t = l.split(";",false)
#			p.push_front(t)
#			p.erase(l)
#		p.reverse()
#	pattern_list.reverse()

func get_tiles_with_brush(_center_in_tiles:Vector2i):
	match brush_shape:
		BrushType.SQUARE:
			return drawSquare(_center_in_tiles)
		BrushType.SQUARE_ROTATED:
			return drawSquareRotated(_center_in_tiles)
		BrushType.CIRCLE:
			return get_tile_positions_in_circle(_center_in_tiles)
		BrushType.LINE_H:
			return drawLineH(_center_in_tiles)
		BrushType.LINE_V:
			return drawLineV(_center_in_tiles)

func get_rect_from(start:Vector2i, end:Vector2i):
	var res:Array[Vector2i]
	var step = Vector2i(sign(end.x-start.x), sign(end.y-start.y))
	# rect is an horizontal / vertical line
	if step.x == 0: for y in range(start.y, end.y+sign(step.y), step.y): res.append(Vector2i(start.x,y))
	elif step.y == 0: for x in range(start.x, end.x+sign(step.x), step.x): res.append(Vector2i(x,start.y))
	# rect is an area
	else:
		for x in range(start.x, end.x+sign(step.x), step.x):
			for y in range(start.y, end.y+sign(step.y), step.y):
				res.append(Vector2i(x,y))
	return res

func get_bucket_tiles(xy:Vector2i, l:int=current_layer, replaced:Dictionary=get_cell(xy, l), rec_index=0):
	var res:Array[Vector2i]
	if rec_index > MAX_BUCKET_RECURSION or xy in bucket_explored: return res
	bucket_explored.append(xy)
	
	for cell in get_neighbor_cells(xy):
		if cell not in bucket_explored and BTM.isEqual(get_cell(cell, l), replaced):
			res.append(cell)
			res.append_array(get_bucket_tiles(cell, l, replaced, rec_index+1))
	return res

func drawSquare(pos):
	var bound = (brush_size+0.5)/2; var res:Array[Vector2i]
	for x in range(pos.x - floor(bound), pos.x + round(bound)):
		for y in range(pos.y - floor(bound), pos.y + round(bound)):
			if not shape_filled and not (x <= pos.x-floor(bound)+outline_width-1 or x >= pos.x+round(bound)-outline_width \
								or y <= pos.y-floor(bound)+outline_width-1 or y >= pos.y+round(bound)-outline_width):
				continue
			res.append(Vector2i(x,y))
	return res

func drawSquareRotated(pos):
	var bound = round(sqrt(pow(brush_size, 2) * 2) / 2)

	var topLeft = Vector2(pos.x - bound, pos.y)
	var topRight = Vector2(pos.x, pos.y - bound)
	var bottomLeft = Vector2(pos.x, pos.y + bound)
	var bottomRight = Vector2(pos.x + bound, pos.y)
	var res:Array[Vector2i]
	for x in range(pos.x - bound, pos.x + bound):
		for y in range(pos.y - bound, pos.y + bound):
			if (1 == sign((topRight.x - topLeft.x) * (y - topLeft.y) - (topRight.y - topLeft.y) * (x - topLeft.x))
					and -1 == sign((bottomLeft.x - topLeft.x) * (y - topLeft.y) - (bottomLeft.y - topLeft.y) * (x - topLeft.x))
					and -1 == sign((bottomRight.x - bottomLeft.x) * (y - bottomLeft.y) - (bottomRight.y - bottomLeft.y) * (x - bottomLeft.x))
					and -1 == sign((topRight.x - bottomRight.x) * (y - bottomRight.y) - (topRight.y - bottomRight.y) * (x - bottomRight.x))):
				res.append(Vector2i(x,y))
	return res

func drawLineH(pos):
	var res:Array[Vector2i]
	for x in range(pos.x - (brush_size / 2), round(pos.x as float + (brush_size as float / 2))):
		res.append(Vector2i(x,pos.y))
	return res

func drawLineV(pos):
	var res:Array[Vector2i]
	for y in range(pos.y - (brush_size / 2), round(pos.y as float + (brush_size as float / 2))):
		res.append(Vector2i(pos.x,y))
	return res

# the functions below was found as an answer to a question checked the godot engine Q&A forum
# author : Zylann https://godotengine.org/qa/64496/how-to-get-a-random-tile-in-a-radious
# I improved it to allow to make ovals and contour-only and use it in editor
func get_tile_positions_in_circle(_center_in_tiles:Vector2):
	# Get the rectangle bounding the circle
	var min_pos = (_center_in_tiles - Vector2(brush_size, brush_size)).floor()
	var max_pos = (_center_in_tiles + Vector2(brush_size, brush_size)).ceil()
	var positions:Array[Vector2i]
	var tile_pos
	var dist
	var max_size = max(brush_size, brush_size)
	# Gather all points that are within the radius
	for y in range(int(min_pos.y), int(max_pos.y)):
		for x in range(int(min_pos.x), int(max_pos.x)):
			tile_pos = Vector2(x, y)
			dist = tile_pos.distance_to(_center_in_tiles)
			if shape_filled and dist < max_size:
				positions.append(Vector2i(tile_pos))
			elif not shape_filled and dist < max_size and dist > max_size-outline_width-0.05:
				positions.append(Vector2i(tile_pos))
	return positions

func pick_spray1(_center_in_tiles:Vector2i):
	var angle = randf_range(-PI, PI)
	var direction = Vector2(cos(angle), sin(angle))
	return _center_in_tiles + direction * max(brush_size, brush_size)

func pick_spray2(_center_in_tiles:Vector2i):
	var angle = randf_range(-PI, PI)
	var direction = Vector2(cos(angle), sin(angle))
	var distance = max(brush_size, brush_size) * sqrt(randf_range(0.0, 1.0))
	return (_center_in_tiles + direction * distance).floor()

func spray(center:Vector2i):
	var res:Array[Vector2i]
	var all = get_tiles_with_brush(center)
	for t in spray_density:
		res.append(all[randi()%all.size()])
	return res

#----

# this function was made by GammaGames
# https://godotengine.org/qa/48904/set-tileset-atlas-subtile-from-code
#func get_random_subtile(id, _a=Vector2(0,0)): #TODO
#	if not tile_set.tile_get_tile_mode(id) == 2: return _a
#	var rect = tile_set.tile_get_region(id)
#	var x = randi() % int(rect.size.x/tile_set.autotile_get_size(id).x)
#	var y = randi() % int(rect.size.y/tile_set.autotile_get_size(id).y)
#	return Vector2(x,y)

#func get_random_tile(id) -> int: #TODO
#	var random_pattern = pattern_list[id][0]
#	return int(random_pattern[randi()%random_pattern.size()])

enum REPLACE_PARAM {SelectionOnly=0, Global=1}
func global_replacing(old, new, replace:int=REPLACE_PARAM.SelectionOnly, l=current_layer):
	var to_replace = []; var tilev; var replacing_tile:Dictionary
	if old == ALL_TILES:
		to_replace = get_used_cells(current_layer) # replace all tiles
	elif old is int:
		tilev = ID_map[new];
		replacing_tile = match_themes(BTM.new_TILEID(tilev.z, BTM.vector2(tilev)))
		tilev = ID_map[old]
		to_replace = get_used_cells_by_id(current_layer, tilev.z, BTM.vector2(tilev))
	elif old is Dictionary:
		tilev = old.v
		replacing_tile = match_themes(new)
		to_replace = get_used_cells_by_id(current_layer, tilev.z, BTM.vector2(tilev))
	
	match replace:
#		REPLACE_PARAM.Auto:
#			for tile in to_replace:
#				if selected_cells.is_empty() or tile in selected_cells:
#					call_all_draw(tile, replacing_tile,l)
		REPLACE_PARAM.SelectionOnly:
			for tile in to_replace:
				if tile in selected_cells:
					call_all_draw(tile, replacing_tile,l)
		REPLACE_PARAM.Global:
			for tile in to_replace:
				call_all_draw(tile, replacing_tile,l)
#				if allow_autotile: update_bitmask_area(tile)
	#			if r_y_as_random_pattern:
	#				call_all_draw(tile, get_random_tile(replacing_tile),l)
	#			else: call_all_draw(tile, replacing_tile,l)

func set_global_replacing(value):
	if not value: return
	global_replacing(replace_tile, replace_by)

func merge_tilemaps(other:TileMap, override:bool=false):
	for layer in other.get_layers_count():
		for cell in other.get_used_cells(layer):
			if override or get_cell_source_id(layer,cell) == -1:
				set_cell(layer, cell, other.get_cell_source_id(layer, cell),
						other.get_cell_atlas_coords(layer, cell), other.get_cell_alternative_tile(layer, cell))

#func create_polygon():
#	var all_poly:Array[PackedVector2Array]; var poly:PackedVector2Array; var res:Array[PackedVector2Array]
#	for cell in selected_cells:
#		poly.clear()
#		poly.append(cell*cell_size)
#		poly.append(cell+Vector2i(0,1)*cell_size)
#		poly.append(cell+Vector2i(1,0)*cell_size)
#		poly.append(cell+Vector2i(1,1)*cell_size)
#		all_poly.append(poly)
#
#	for p in all_poly.size()-1:
#		res
#	$Polygon2D.polygon = 

func apply_theme_global(replace:int, layer:int=current_layer):
	var tile:Dictionary
	if layer == ALL_LAYERS:
		for l in get_layers_count():
			for cell in get_used_cells(l):
				tile = get_cell(cell,l)
				global_replacing(tile, tile, replace, l)
	else:
		for cell in get_used_cells(layer):
			tile = get_cell(cell,layer)
			global_replacing(tile, tile, replace, layer)

func scan_for_tilemaps(node):
	if not node is Node:
		if not get_tree(): return
		node = get_tree().edited_scene_root
	if not node == self and node is TileMap and not tilemap_list.has(node.get_path()):
		tilemap_list.append(node.get_path())
	for child in node.get_children(): scan_for_tilemaps(child)
	read_used_tilemaps(null)
	notify_property_list_changed()

func read_used_tilemaps(value):
	if value != null: use_these = value
	if tilemap_list.is_empty(): return
	used_tilemaps.clear()
	curr_tilemap = null
	for x in use_these.split(" ",false,tilemap_list.size()):
		if curr_tilemap == null: set_curr_tilemap(get_node(tilemap_list[int(x)]))
		used_tilemaps.append(tilemap_list[int(x)])

func read_used_cursors(value):
	use_those = value
	if multi_cursor_list.is_empty(): return
	used_cursors.clear()
	for x in use_those.split(" ",false,multi_cursor_list.size()):
		used_cursors.append(multi_cursor_list[int(x)])

func update_bitmask_area(pos:Vector2): #TODO
	pass
#	super.update_bitmask_area(pos)



func is_tile_in_group(id:Vector3i, group:String, tilemap=self):
	return group in tile_set.get_meta("groups_by_ids", {}).get(id, [])

func group_has_tile(group:String, id:Vector3i, tilemap=self):
	return id in tile_set.get_meta("groups_by_groups", {}).get(group, [])

func tile_has_any_group(id:Vector3i):
	return id in tile_set.get_meta("groups_by_ids", {}).keys()

func get_tiles_in_group(group:String):
	return tile_set.get_meta("groups_by_groups", {})[group]

func add_tile_to_group(id:Vector3i, group:String):
	if not tile_set.get_meta("groups_by_groups", {}).has(group): tile_set.get_meta("groups_by_groups", {})[group] = []
	tile_set.get_meta("groups_by_groups", {})[group].append(id)

func add_group_to_tile(id:Vector3i, group:String):
	if not tile_set.get_meta("groups_by_ids", {}).has(id): tile_set.get_meta("groups_by_ids", {})[id] = []
	tile_set.get_meta("groups_by_ids", {})[id].append(group)

func group_exists(group:String):
	return tile_set.get_meta("groups_by_groups", {}).has(group)

func remove_group_from_tile(id:Vector3i, group:String):
#	if not is_tile_in_group(id, group): return
	tile_set.get_meta("groups_by_ids", {})[id].erase(group)
	if tile_set.get_meta("groups_by_ids", {})[id].is_empty(): tile_set.get_meta("groups_by_ids", {}).erase(id)

func remove_tile_from_group(id:Vector3i, group:String):
#	if not group_has_tile(group, id): return
	tile_set.get_meta("groups_by_groups", {})[group].erase(id)
	if tile_set.get_meta("groups_by_groups", {})[group].is_empty(): tile_set.get_meta("groups_by_groups", {}).erase(group)




func cells_to_brush(center:Vector2i, l:int=current_layer):
	current_brush_tiles.clear()
	var cell:Dictionary
	if l == ALL_LAYERS:
		for tile in selected_cells:
			for layer in get_layers_count():
				cell = get_cell(tile, layer)
				if cell.source == ERASE_TILE: continue
				current_brush_tiles[Vector3i((tile-center).x,(tile-center).y,layer-l)] = cell
	else:
		for tile in selected_cells:
			cell = get_cell(tile, l)
			if cell.source == ERASE_TILE: continue
			current_brush_tiles[Vector3i((tile-center).x,(tile-center).y,0)] = cell

func transform_brush(action:int):
	if current_brush_tiles.is_empty(): return
	
	var modified:Dictionary
	match action:
		TransfoActions.FLIP_H:
			print("ok")
			for t in current_brush_tiles.keys():
				modified[Vector3i(-t.x,t.y,t.z)] = current_brush_tiles[t]
		TransfoActions.FLIP_V:
			for t in current_brush_tiles.keys():
				modified[Vector3i(t.x,-t.y,t.z)] = current_brush_tiles[t]
		TransfoActions.ROTATE_LEFT:
			for t in current_brush_tiles.keys():
				modified[Vector3i(t.y,-t.x,t.z)] = current_brush_tiles[t]
		TransfoActions.ROTATE_RIGHT:
			for t in current_brush_tiles.keys():
				modified[Vector3i(-t.y,t.x,t.z)] = current_brush_tiles[t]
	current_brush_tiles = modified

func save_brush_as_pattern():
	if current_brush_tiles.is_empty(): return
	pattern_list.append(current_brush_tiles)

#func get_brush_as_pattern

func pick_random_tile(use_theme:bool=false):
	if use_theme:
		return match_themes(tile_set.get_meta("TileListIndexes",{}).values()[randi()%(tile_set.get_meta("TileListIndexes",{}).size())])
	else: return tile_set.get_meta("TileListIndexes", {}).values()[randi()%(tile_set.get_meta("TileListIndexes", {}).size())]


# SETGETS ########################################################

func get_cell(xy:Vector2i, l:int=current_layer) -> Dictionary:
	return BTM.new_TILEID(get_cell_source_id(l, xy), get_cell_atlas_coords(l, xy), get_cell_alternative_tile(l, xy))
#	return get_cell_source_id(0, xy)

func set_selected_cells(value=null):
#	selected_cells.clear()
	var new_value:Array[Vector2i]
	if not value is Array or value == null: new_value = get_selected_cells()
	if not new_value.is_empty():
		for cell in new_value:
			if not cell in selected_cells: selected_cells.append(cell)
	elif value is Vector2i: if not value in selected_cells: selected_cells.append(value)
	
#	selected_cells.append_array(value)

func unset_selected_cells(value=null):
	var new_value:Array[Vector2i]
	if not value is Array or value == null: new_value = get_selected_cells()
	if not new_value.is_empty():
		for cell in new_value:
			if cell in selected_cells: selected_cells.erase(cell)
	elif value is Vector2i: if value in selected_cells: selected_cells.erase(value)

func set_current_tile(value:Dictionary):
	current_tile = value
	if value.source == -1: return
	curr_tile_texture = tile_set.get_source(value.source).texture
	curr_tile_reg = tile_set.get_source(value.source).get_tile_texture_region(value.coords)

func set_curr_tilemap(value):
	curr_tilemap = value
#	cell_size = curr_tilemap.tile_size
#	mode = curr_tilemap.tile_shape
	for prop in ["mode","tile_set","centered_textures","cell_size","cell_custom_transform","cell_half_offset",\
					"cell_tile_origin","cell_y_sort","z_index","z_as_relative"]:
		set(prop, curr_tilemap.get(prop))
	
	self.clear()
	
	for layer in curr_tilemap.get_layers_count():
		for cell in curr_tilemap.get_used_cells(layer):
			super.set_cell(layer,cell, curr_tilemap.get_cell_source_id(layer,cell), \
				curr_tilemap.get_cell_atlas_coords(layer,cell), curr_tilemap.get_cell_alternative_tile(layer,cell))
	notify_property_list_changed()

func get_neighbor_cells(xy:Vector2i):
	var res:Array[Vector2i]
	res.append(Vector2i(xy.x-1,xy.y))
	res.append(Vector2i(xy.x+1,xy.y))
	res.append(Vector2i(xy.x,xy.y+1))
	res.append(Vector2i(xy.x,xy.y-1))
	return res

func set_no_draw_on(value):
	no_draw_on = value
	
func set_pattern_id(value):
	pattern_id = value
	if value == -1: current_brush_tiles.clear()
	else: current_brush_tiles = pattern_list[value]

func set_limit_color(value):
	limit_color = value
	queue_redraw()

func set_multi_cursor(value):
	multi_cursor_list = value
	read_used_cursors(use_those)

func set_axis(value):
	axis = value
	queue_redraw()

func set_axis_pos(value):
	axis_pos = value
	queue_redraw()

#func set_drawing_modes(value):
#	drawing_modes = value
#	BTM.update_drawing_modes()
	
	
	
#func load_data():
#	if !file.file_exists(url): return
#	file.open(url, File.READ)
#	var test_json_conv = JSON.new()
#	test_json_conv.parse(file.get_as_text())
#	var _data = test_json_conv.get_data()
#	file.close()
#	data = _data.result
#
#func write_data():
#	if url == null: return
#	file.open(url, File.WRITE)
#	file.store_line(JSON.new().stringify(data))
#	file.close()
#	return

func import_tilesets():
	scan_for_tilemaps(get_tree().edited_scene_root)
	
	var t:TileSet; var imported_tiles:Array[Dictionary];
	var new_source:TileSetAtlasSource; var imp_source:TileSetAtlasSource;
	var new_alt:TileData; var imp_alt:TileData;
	for tm in used_tilemaps:
		t = tm.tile_set
		imported_tiles = BTM.get_tiles_ids(t)
		for id in imported_tiles:
			imp_source = t.get_source(id.source)
			new_source = imp_source.duplicate()
			for tile in imp_source.get_tiles_count():
				new_source.create_tile(id.coords, imp_source.get_tile_size_in_atlas(id.coords))
				for alt in imp_source.get_alternative_tiles_count(id.coords):
					if alt == 0: continue
					imp_alt = imp_source.get_tile_data(id.coords, alt)
					new_source.create_alternative_tile(id.coords)
					new_alt = new_source.get_tile_data(id.coords, alt)
					duplicate_alt_tile(imp_alt, new_alt)
#					new_alt = imp_alt#.duplicate()
			tile_set.add_source(new_source)

func duplicate_alt_tile(imported:TileData, res:TileData):
	for prop in ["flip_h","flip_v","transpose","material","modulate","propbability","terrain_set","terrain","texture_origin","z_index"]:
		res.set(prop, imported.get(prop))
#	for prop in ["collision_polygon_one_way_margin","collision_polygon_points","","","","","","",""]: #TODO
#		res.call("set_"+prop, imported.call("get_"+prop))


func _EMPTY_TILE_ARRAY() -> Array[Dictionary]:
	return EMPTY_TILE_ARRAY.duplicate()





