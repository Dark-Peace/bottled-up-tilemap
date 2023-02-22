@tool
extends TileMap

### Made by Dark Peace
# Wanna request a feature / report a bug / ask a question ?
# Then join my discord : https://discord.gg/aWWQbgQUEP
# Plugin documentation :
# https://docs.google.com/document/d/1y2aPsn72dOxQ-wBNGqLlQvrw9-SV_z12a1MradBglF4/edit?usp=sharing"
###

enum BrushType {CIRCLE, SQUARE, SQUARE_ROTATED, LINE_H, LINE_V }

const LINE_WIDTH = 3
const X_AXIS = 1
const Y_AXIS = 2
const BOTH_AXIS = 3
const EVERY_TILEMAP = -1
const NO_TILE = -2
const ALL_TILES = -3


# PATTERN
enum CENTER {origin, mouse}
var p_center = CENTER.origin
enum BRUSH {whole_pattern, one_tile}
var p_brush = BRUSH.one_tile
var p_replacing = true
var p_id = -1

var p_patterns = "" : set = set_patterns
var pattern_list:Array

var p_turn_into_pattern:bool : set = set_turn_into_pattern
var p_allow_autotile:bool = false

# CIRCLES
var c_brush_shape = BrushType.CIRCLE
var c_size:Vector2 = Vector2(1,1)
var c_filled = true
var c_outline_width = 1

# SPRAY
var c_spray_density = 0

# REPLACING
var r_replace_x_by_y = Vector2(-1,-1)
var r_y_as_random_pattern = false
var r_global_replacing = false : set = set_global_replacing
# to use like 2 vectors x,y and not a rect with w & h
var r_select_limits = Rect2() : set = set_select_limits
var r_limit_color = Color.AQUAMARINE : set = set_limit_color

# SYMMETRY
var s_position = Vector2(0,0) : set = set_axis_position
var s_axis = 0 : set = set_axis
var s_display_length = 1000

# MULTI CURSOR
#var c_active
var c_use = "" : set = read_used_cursors
var used_cursors = []
var c_multi_cursor_list = PackedVector2Array() : set = set_multi_cursor
var cursor_texture = load("res://addons/BottledTileMap/icon.png")
#var c_cursor_color = Color.AQUA : set = set_cursor_color

# MULTI TILEMAP
var t_tilemap_list = []
var used_tilemaps = []
var t_scan_for_tilemaps : set = scan_for_tilemaps
var t_use = "" : set = read_used_tilemaps
var curr_tilemap:TileMap : set = set_curr_tilemap

# INSTANCES
var instance_dict = {}

# RULES
var r_no_draw_on = NO_TILE
var r_only_draw_on = NO_TILE
var r_scattering = 0
var r_scatter_affects_erase = false

#var t_clone_id = 0
#var t_draw_on_self = false
#
## SEND DATA
#var send_target = NodePath()
#var send_send = false : set = set_send
#var send_erase_after_send = false

#--

var to_init = true
var can_trigger = true
var can_trigger_multi = true
var origin = Vector2(0,0)
var can_origin = true
var can_erase = true
# custom select
var is_selecting = false
var has_selected = false
var selecting_init_pos = Vector2()
var selecting_end_pos = Vector2()
var selected_tiles:Array

var label = Label.new()
var font = label.get_theme_font("")
var tm_hints:Array = []

var data = {"instances": instance_dict, "cursors": c_multi_cursor_list, "tilemaps": t_tilemap_list, "patterns": p_patterns}
#@onready var file = FileAccess.new()
var url = "res://addons/BottledTileMap/save"

@onready var tilecell

## Godot 4
var cell_size# = curr_tilemap.tile_size
var mode# = curr_tilemap.tile_shape



func init():
#	write_data()
	randomize()
	format_patterns()
	read_used_tilemaps(t_use)

func _process(delta: float) -> void:
	if to_init:
		to_init = false
		init()
#		set_process(false)
	if not Engine.is_editor_hint(): set_process(false)

func _ready() -> void:
	if not Engine.is_editor_hint():
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

#		for tile in node.tile_set.get_meta_list():
#			for pos in node.get_used_cells(tile):
#				entry = node.tile_set.get_meta(tile)
#				if not entry.has("instance") and entry.has("parent"): continue
#				instance = load(entry["instance"]).instantiate()
#				get_tree().current_scene.get_node(entry["parent"]).add_child(instance)
#		if node.tile_set in instance_dict.keys():
#			for tile in instance_dict[node.tile_set].keys():
#				for pos in node.get_used_cells(tile):
#					instance = load(instance_dict[node.tile_set][tile]["instance"]).instantiate()
#					get_tree().current_scene.get_node(instance_dict[node.tile_set][tile]["parent"]).add_child(instance)
	for child in node.get_children(): scan_for_tileset(child)

func _draw() -> void:
	var angle_offset = 0
	if mode == tile_set.TILE_SHAPE_ISOMETRIC: angle_offset = PI/4
	if r_select_limits != Rect2(): # draw the limits of the selection
		var start_corner = r_select_limits.position*cell_size
		var end_corner = r_select_limits.size*cell_size
		var upright_corner = Vector2(r_select_limits.size.x,r_select_limits.position.y)*cell_size
		var downleft_corner = Vector2(r_select_limits.position.x,r_select_limits.size.y)*cell_size
		draw_line(start_corner,downleft_corner,r_limit_color,LINE_WIDTH)
		draw_line(start_corner,upright_corner,r_limit_color,LINE_WIDTH)
		draw_line(end_corner,downleft_corner,r_limit_color,LINE_WIDTH)
		draw_line(end_corner,upright_corner,r_limit_color,LINE_WIDTH)

	angle_offset = 0
	if mode == tile_set.TILE_SHAPE_ISOMETRIC: angle_offset = s_display_length
	if s_axis > 0:
		var display_vector; var start_point; var end_point
		match s_axis:
			X_AXIS: _draw_symmetry_axis(Vector2(s_display_length,angle_offset))
			Y_AXIS: _draw_symmetry_axis(Vector2(-angle_offset,s_display_length))
			BOTH_AXIS:
				_draw_symmetry_axis(Vector2(s_display_length,angle_offset))
				_draw_symmetry_axis(Vector2(-angle_offset,s_display_length))

	if not used_cursors.is_empty():
		for c in used_cursors:
			if c == Vector2.ZERO: continue
			draw_texture(cursor_texture, get_local_mouse_position()+cell_size*c, Color.WHITE)
	if not tm_hints.is_empty():
		for i in tm_hints.size():
			draw_string(font, get_local_mouse_position()+Vector2(10,15*i), tm_hints[i].name, 0,-1,16, Color.AQUA)

	if is_selecting:
		draw_rect(Rect2((selecting_init_pos/cell_size).round()*cell_size, \
						(get_local_mouse_position()/cell_size).round()*cell_size), Color.AQUA)
	elif has_selected:
		draw_rect(Rect2((selecting_init_pos/cell_size).round()*cell_size, \
						(selecting_end_pos/cell_size).round()*cell_size), Color.AQUA)


func _draw_symmetry_axis(display_vector:Vector2):
	var start_point = (s_position+display_vector)*cell_size
	var end_point = (s_position-display_vector)*cell_size
	draw_line(start_point,end_point,r_limit_color,LINE_WIDTH)

#func set_cell(x:int,y:int,id,fy=false,fx=false,_t=false,_a=Vector2()):
func set_cell(l:int, xy:Vector2i, id:int=-1, _a:Vector2i=Vector2i(-1,-1), alt:int=0):
	if is_selecting or has_selected: return
	# multi-cursor handler
	if not id == get_cell(xy) and used_cursors.size() > 0 and can_trigger_multi:
		can_trigger_multi = false
		for c in used_cursors:
#			if c == Vector2.ZERO: continue
			if p_replacing or get_cell(xy+c) == -1:
				set_cell(l,xy+c,id,_a,alt)
				if p_allow_autotile: update_bitmask_area(xy+c)
		can_trigger_multi = true

	# case that doesn't change from a normal tilemap
	if id == get_cell(xy) or id == -1:
		setcell(l,xy,id,_a,alt)
		if not can_origin: can_origin = true
		return
	# no pattern selected
	if p_id == -1:
		if (c_size.x > 1 or c_size.y > 1) and can_trigger:
			can_trigger = false
			# use circle tool
			if c_spray_density == 0:
				for t in get_tiles_with_brush(xy):
					setcell(l,xy,id,_a,alt)
			# use spray tool
			else:
				for t in spray(xy):
					setcell(l,xy,id,_a,alt)
			can_trigger = true
		else: setcell(l,xy,id,_a,alt) # case that doesn't change from a normal tilemap
		if not can_origin: can_origin = true
		return

	get_origin(xy)

	# use pattern tool
	if p_brush == BRUSH.one_tile:
		# use spray or circle tool
		if (c_size.x > 1 or c_size.y > 1) and can_trigger:
			can_trigger = false
			if c_spray_density == 0:
				for t in get_tiles_with_brush(xy):
					id = get_tileIDv(t-origin)
					if id != NO_TILE: setcell(l,xy,id,get_random_subtile(id, _a))
			else:
				for t in spray(xy):
					id = get_tileIDv(t-origin)
					if id != NO_TILE: setcell(l,xy,id,get_random_subtile(id, _a))
			can_trigger = true
		# draw single tile
		else:
			id = get_tileIDv(xy-origin)
			if id == NO_TILE: return # use transparancy tile
			setcell(l,xy,id,get_random_subtile(id, _a))
	# draw with whole pattern
	elif p_brush == BRUSH.whole_pattern:
		if can_trigger:
			can_trigger = false
			place_pattern(l,xy,_a,alt)
			can_trigger = true
		else: setcell(l,xy,id,get_random_subtile(id, _a))


func setcell(l:int,xy:Vector2i,id,_a=Vector2i(),alt:int=0):
	if r_no_draw_on == get_cell(xy) or (r_only_draw_on != NO_TILE and get_cell(xy) != r_only_draw_on): return

	if not id == get_cell(xy):
		var test = randf_range(0,1)
		if r_scattering > 0 and test <= r_scattering and (id != -1 or r_scatter_affects_erase): return
		for tm in used_tilemaps:
			get_node(tm).set_cell(l,xy,id,_a,alt)
			super.set_cell(l,xy,id,_a,alt)
			draw_symmetry(l,xy,id,_a,alt)
	if p_allow_autotile: update_bitmask_area(xy)

#func setcellv(v:Vector2,id,fy=false,fx=false,_t=false,_a=Vector2()):
#	if r_no_draw_on == get_cellv(v) or (r_only_draw_on != NO_TILE and get_cellv(v) != r_only_draw_on): return
#	setcell(v.x,v.y,id,fy,fx,_t,_a)

func draw_symmetry(l:int,xy:Vector2i,id,_a=Vector2(),alt=0):
	if s_axis == 0: return
	if s_axis == X_AXIS:
		var new_vect:Vector2i = xy+Vector2i(0,-2*(xy.y-s_position.y)-1)
#		super.set_cell(x,y-2*(y-s_position.y)-1,id,fy,fx,_t,_a)
		super.set_cell(l,new_vect,id,_a,alt)
		if p_allow_autotile: update_bitmask_area(new_vect)
	elif s_axis == Y_AXIS:
		var new_vect:Vector2i = xy+Vector2i(-2*(xy.y-s_position.y)-1,0)
		super.set_cell(l,new_vect,id,_a,alt)
		if p_allow_autotile: update_bitmask_area(new_vect)
	elif s_axis == BOTH_AXIS:
		var part_vect:int = (-2*(xy.y-s_position.y)-1)
		super.set_cell(l,xy+Vector2i(part_vect,0),id,_a,alt)
		super.set_cell(l,xy+Vector2i(0,part_vect),id,_a,alt)
		super.set_cell(l,xy+Vector2i(part_vect,part_vect),id,_a,alt)
#		super.set_cell(x-2*(x-s_position.x)-1,y-2*(y-s_position.y)-1,id,fy,fx,_t,_a)
		if p_allow_autotile:
			update_bitmask_area(xy+Vector2i(part_vect,0))
			update_bitmask_area(xy+Vector2i(0,part_vect))
			update_bitmask_area(xy+Vector2i(part_vect,part_vect))

# draw pattern checked map
func place_pattern(l:int, xy:Vector2i,_a,alt):
	var matrix = pattern_list[p_id]
	var m_size = matrix.size()
	var id
	for line in m_size:
		for column in matrix[line].size():
			id = get_tileID(xy.x+column-origin.x,xy.y+line-origin.y)
			if id != NO_TILE and (p_replacing or get_cell(xy+Vector2i(column,line)) == -1):
				setcell(l,xy+Vector2i(column,line),id,get_random_subtile(id, _a))

func get_origin(xy:Vector2i):
	if not can_origin: return
	if p_center == CENTER.origin: origin = Vector2i.ZERO
	elif p_center == CENTER.mouse: origin = xy

func get_tileIDv(xy:Vector2i):
	return get_tileID(xy.x,xy.y)

func get_tileID(x:int, y:int):
	var matrix = pattern_list[p_id]
	var line = matrix[y%matrix.size()]
	var id = line[x%line.size()]

	match id:
		" ": return NO_TILE # tile won't be drawn there / will be ignored
		"x": return -1 # tile will be replaced by empty tile
	if "R" in id: id = get_random_tile(int(id.right(1))) # random tile from other pattern
	return int(id)

func format_patterns():
	pattern_list = p_patterns.split("\n\n",false)
	var p:Array; var t:Array;
	for m in pattern_list:
		p = m.split("\n",false)
		pattern_list.push_front(p)
		pattern_list.erase(m)
		for l in p:
			t = l.split(";",false)
			p.push_front(t)
			p.erase(l)
		p.reverse()
	pattern_list.reverse()

func get_tiles_with_brush(_center_in_tiles:Vector2):
	match c_brush_shape:
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

func drawSquare(pos):
	var bound = c_size.x/2; var res = []
	for x in range(pos.x - floor(bound), pos.x + round(bound)):
		for y in range(pos.y - floor(bound), pos.y + round(bound)):
			res.append(Vector2(x,y))
	return res

func drawSquareRotated(pos):
	var bound = round(sqrt(pow(c_size.x, 2) * 2) / 2)

	var topLeft = Vector2(pos.x - bound, pos.y)
	var topRight = Vector2(pos.x, pos.y - bound)
	var bottomLeft = Vector2(pos.x, pos.y + bound)
	var bottomRight = Vector2(pos.x + bound, pos.y)
	var res = []
	for x in range(pos.x - bound, pos.x + bound):
		for y in range(pos.y - bound, pos.y + bound):
			if (1 == sign((topRight.x - topLeft.x) * (y - topLeft.y) - (topRight.y - topLeft.y) * (x - topLeft.x))
					and -1 == sign((bottomLeft.x - topLeft.x) * (y - topLeft.y) - (bottomLeft.y - topLeft.y) * (x - topLeft.x))
					and -1 == sign((bottomRight.x - bottomLeft.x) * (y - bottomLeft.y) - (bottomRight.y - bottomLeft.y) * (x - bottomLeft.x))
					and -1 == sign((topRight.x - bottomRight.x) * (y - bottomRight.y) - (topRight.y - bottomRight.y) * (x - bottomRight.x))):
				res.append(Vector2(x,y))
	return res

func drawLineH(pos):
	var res = []
	for x in range(pos.x - (c_size.x / 2), round(pos.x as float + (c_size.x as float / 2))):
		res.append(Vector2(x,pos.y))
	return res

func drawLineV(pos):
	var res = []
	for y in range(pos.y - (c_size.x / 2), round(pos.y as float + (c_size.x as float / 2))):
		res.append(Vector2(pos.x,y))
	return res

# the functions below was found as an answer to a question checked the godot engine Q&A forum
# author : Zylann https://godotengine.org/qa/64496/how-to-get-a-random-tile-in-a-radious
# I improved it to allow to make ovals and contour-only and use it in editor
func get_tile_positions_in_circle(_center_in_tiles:Vector2):
	# Get the rectangle bounding the circle
	var min_pos = (_center_in_tiles - Vector2(c_size.x, c_size.x)).floor()
	var max_pos = (_center_in_tiles + Vector2(c_size.x, c_size.x)).ceil()
	var positions = []
	var tile_pos
	var dist
	var max_size = max(c_size.x, c_size.y)
	# Gather all points that are within the radius
	for y in range(int(min_pos.y), int(max_pos.y)):
		for x in range(int(min_pos.x), int(max_pos.x)):
			tile_pos = Vector2(x, y)
			dist = tile_pos.distance_to(_center_in_tiles)
			if c_filled and dist < max_size:
				positions.append(tile_pos)
			elif not c_filled and dist < max_size and dist > max_size-c_outline_width-0.05:
				positions.append(tile_pos)
	return positions

func pick_spray1(_center_in_tiles:Vector2):
	var angle = randf_range(-PI, PI)
	var direction = Vector2(cos(angle), sin(angle))
	return _center_in_tiles + direction * max(c_size.x, c_size.y)

func pick_spray2(_center_in_tiles:Vector2):
	var angle = randf_range(-PI, PI)
	var direction = Vector2(cos(angle), sin(angle))
	var distance = max(c_size.x, c_size.y) * sqrt(randf_range(0.0, 1.0))
	return (_center_in_tiles + direction * distance).floor()

func spray(center:Vector2):
	var res = []
	var all = get_tiles_with_brush(center)
	for t in c_spray_density:
		res.append(all[randi()%all.size()])
	return res
#----

# this function was made by GammaGames
# https://godotengine.org/qa/48904/set-tileset-atlas-subtile-from-code
func get_random_subtile(id, _a=Vector2(0,0)):
	if not tile_set.tile_get_tile_mode(id) == 2: return _a
	var rect = tile_set.tile_get_region(id)
	var x = randi() % int(rect.size.x/tile_set.autotile_get_size(id).x)
	var y = randi() % int(rect.size.y/tile_set.autotile_get_size(id).y)
	return Vector2(x,y)

func get_random_tile(id) -> int:
	var random_pattern = pattern_list[id][0]
	return int(random_pattern[randi()%random_pattern.size()])

func set_global_replacing(value):
	if not value: return
	var to_replace = []
	if r_replace_x_by_y.x == ALL_TILES: to_replace = get_used_cells(0) # replace all tiles
	else: to_replace = get_used_cells(r_replace_x_by_y.x) # replace tiles with corresponding id
	for tile in to_replace:
		# replace everywhere or in the selection
		if r_select_limits == Rect2() or tile_in_rect(tile):
			if r_y_as_random_pattern:
				setcell(0,tile, get_random_tile(r_replace_x_by_y.y))
			else: setcell(0,tile, r_replace_x_by_y.y)
			if p_allow_autotile: update_bitmask_area(tile)

func tile_in_rect(tile:Vector2):
	if (tile.x > r_select_limits.position.x-1 and tile.y > r_select_limits.position.y-1 \
		and tile.x < r_select_limits.size.x and tile.y < r_select_limits.size.y):
		return true

func select_tiles():
	var rect = Rect2((selecting_init_pos)/cell_size, selecting_end_pos/cell_size)
	for x in rect.size.x:
		for y in rect.size.y:
			selected_tiles.append(Vector2(x,y))

func set_turn_into_pattern(value):
	if r_select_limits == Rect2() or not value: return
	var line_res:String; var t_id:String
	for y in range(r_select_limits.position.y,r_select_limits.size.y):
		line_res += "/n"
		for x in range(r_select_limits.position.x,r_select_limits.size.x):
			t_id = String(get_cell(Vector2i(x,y)))
			if t_id == "-1": t_id = " "
			line_res += t_id
			if x != r_select_limits.size.x-1: line_res += ";"
	p_patterns += "/n"+line_res
	notify_property_list_changed()

#		print(line_res)
#		line_res = ""

#func set_send(value):
#	if send_target == NodePath(): return
#	for tile in self.get_used_cells():
#		if r_select_limits == Rect2() or tile_in_rect(tile):
#			get_node(send_target).set_cellv(tile, self.get_cellv(tile))
#			if send_erase_after_send: set_cellv(tile, -1)

func scan_for_tilemaps(node):
	if not node is Node:
		node = get_tree().edited_scene_root
	if not node == self and node is TileMap and not t_tilemap_list.has(node.get_path()):
		t_tilemap_list.append(node.get_path())
	for child in node.get_children(): scan_for_tilemaps(child)
	read_used_tilemaps(null)
	notify_property_list_changed()

func read_used_tilemaps(value):
	if value != null: t_use = value
	if t_tilemap_list.is_empty(): return
	used_tilemaps.clear()
	curr_tilemap = null
	for x in t_use.split(" ",false,t_tilemap_list.size()):
		if curr_tilemap == null: set_curr_tilemap(get_node(t_tilemap_list[int(x)]))
		used_tilemaps.append(t_tilemap_list[int(x)])

func read_used_cursors(value):
	c_use = value
	if c_multi_cursor_list.is_empty(): return
	used_cursors.clear()
	for x in c_use.split(" ",false,c_multi_cursor_list.size()):
		used_cursors.append(c_multi_cursor_list[int(x)])


func update_bitmask_area(pos:Vector2):
	pass
#	super.update_bitmask_area(pos)

func is_tile_in_group(id, group, tileset=curr_tilemap):
	return group in tileset.tile_set.get_meta("groups_by_IDs", {}).get(String(id), [])

func group_has_tile(group, id, tileset=curr_tilemap):
	return id in tileset.tile_set.get_meta("groups_by_groups", {}).get(group, [])




# SETGETS

func set_curr_tilemap(value):
	curr_tilemap = value
	cell_size = curr_tilemap.tile_size
	mode = curr_tilemap.tile_shape
	for prop in ["mode","tile_set","centered_textures","cell_size","cell_custom_transform","cell_half_offset",\
					"cell_tile_origin","cell_y_sort","z_index","z_as_relative"]:
		set(prop, curr_tilemap.get(prop))
	for tile in curr_tilemap.get_used_cells(0):
		super.set_cell(0,tile, curr_tilemap.get_cell_source_id(0,tile), \
			curr_tilemap.get_cell_atlas_coords(0,tile), curr_tilemap.get_cell_alternative_tile(0,tile))
#		super.set_cell(0,tile, curr_tilemap.get_cellv(tile), curr_tilemap.is_cell_x_flipped(tile.x, tile.y),\
#			curr_tilemap.is_cell_x_flipped(tile.x, tile.y), curr_tilemap.is_cell_transposed(tile.x, tile.y),\
#			curr_tilemap.get_cell_autotile_coord(tile.x,tile.y))
	notify_property_list_changed()

func set_patterns(value):
	p_patterns = value
	format_patterns()

func set_select_limits(value):
	r_select_limits = value
	queue_redraw()

func set_limit_color(value):
	r_limit_color = value
	queue_redraw()

func set_multi_cursor(value):
	c_multi_cursor_list = value
	read_used_cursors(c_use)
#	queue_redraw()

func set_axis(value):
	s_axis = value
	queue_redraw()

func set_axis_position(value):
	s_position = value
	queue_redraw()
#func set_cursor_color(value):
#	c_cursor_color = value
#	queue_redraw()

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

func get_cell(xy:Vector2i):
	return get_cell_source_id(0, xy)

func getcell(x,y):
	return get_cell(Vector2i(x,y))


func _get_property_list() -> Array:
	return [
		{
			name = "Tilemaps to draw checked",
			type = TYPE_NIL,
			hint_string = "t_",
			usage = PROPERTY_USAGE_GROUP
		},{
			name = "t_scan_for_tilemaps",
			type = TYPE_BOOL,
			usage = PROPERTY_USAGE_DEFAULT
		},{
			name = "t_use",
			type = TYPE_STRING,
			usage = PROPERTY_USAGE_DEFAULT
		},{
			name = "t_tilemap_list",
			type = TYPE_ARRAY,
			hint = PROPERTY_HINT_RESOURCE_TYPE,
			hint_string = TYPE_NODE_PATH,
			usage = PROPERTY_USAGE_DEFAULT
		},{
			name = "Pattern",
			type = TYPE_NIL,
			hint_string = "p_",
			usage = PROPERTY_USAGE_GROUP
		},{
			name = "p_center",
			type = TYPE_INT,
			hint = PROPERTY_HINT_ENUM,
			hint_string = CENTER,
			usage = PROPERTY_USAGE_DEFAULT
		},{
			name = "p_brush",
			type = TYPE_INT,
			hint = PROPERTY_HINT_ENUM,
			hint_string = BRUSH,
			usage = PROPERTY_USAGE_DEFAULT
		},{
			name = "p_replacing",
			type = TYPE_BOOL,
			usage = PROPERTY_USAGE_DEFAULT
		},{
			name = "p_id",
			type = TYPE_INT,
			hint = PROPERTY_HINT_RANGE,
			hint_string = "-1, 9999",
			usage = PROPERTY_USAGE_DEFAULT
		},{
			name = "p_patterns",
			type = TYPE_STRING,
			hint = PROPERTY_HINT_MULTILINE_TEXT,
			usage = PROPERTY_USAGE_DEFAULT
		},{
			name = "p_turn_into_pattern",
			type = TYPE_BOOL,
			usage = PROPERTY_USAGE_DEFAULT
		},{
			name = "p_allow_autotile",
			type = TYPE_BOOL,
			usage = PROPERTY_USAGE_DEFAULT
		},{
			name = "Special Brushes",
			type = TYPE_NIL,
			hint_string = "c_",
			usage = PROPERTY_USAGE_GROUP
		},{
			name = "c_brush_shape",
			type = TYPE_INT,
			hint = PROPERTY_HINT_ENUM,
			hint_string = BrushType,
			usage = PROPERTY_USAGE_DEFAULT
		},{
			name = "c_size",
			type = TYPE_VECTOR2,
			usage = PROPERTY_USAGE_DEFAULT
		},{
			name = "c_filled",
			type = TYPE_BOOL,
			usage = PROPERTY_USAGE_DEFAULT
		},{
			name = "c_outline_width",
			type = TYPE_FLOAT,
			usage = PROPERTY_USAGE_DEFAULT
		},{
			name = "c_spray_density",
			type = TYPE_INT,
			hint = PROPERTY_HINT_RANGE,
			hint_string = "0, 999999",
			usage = PROPERTY_USAGE_DEFAULT
		},{
			name = "Replacing",
			type = TYPE_NIL,
			hint_string = "r_",
			usage = PROPERTY_USAGE_GROUP
		},{
			name = "r_replace_x_by_y",
			type = TYPE_VECTOR2,
			usage = PROPERTY_USAGE_DEFAULT
		},{
			name = "r_y_as_random_pattern",
			type = TYPE_BOOL,
			usage = PROPERTY_USAGE_DEFAULT
		},{
			name = "r_global_replacing",
			type = TYPE_BOOL,
			usage = PROPERTY_USAGE_DEFAULT
		},{
			name = "Selection",
			type = TYPE_NIL,
			hint_string = "r_",
			usage = PROPERTY_USAGE_GROUP
		},{
			name = "r_select_limits",
			type = TYPE_RECT2,
			usage = PROPERTY_USAGE_DEFAULT
		},{
			name = "r_limit_color",
			type = TYPE_COLOR,
			usage = PROPERTY_USAGE_DEFAULT
		},{
			name = "Symmetry",
			type = TYPE_NIL,
			hint_string = "s_",
			usage = PROPERTY_USAGE_GROUP
		},{
			name = "s_position",
			type = TYPE_VECTOR2,
			usage = PROPERTY_USAGE_DEFAULT
		},{
			name = "s_axis",
			type = TYPE_INT,
			hint = PROPERTY_HINT_FLAGS,
			hint_string = "X, Y",
			usage = PROPERTY_USAGE_DEFAULT
		},{
			name = "s_display_length",
			type = TYPE_INT,
			usage = PROPERTY_USAGE_DEFAULT
		},{
			name = "Multi Cursors",
			type = TYPE_NIL,
			hint_string = "c_",
			usage = PROPERTY_USAGE_GROUP
		},{
			name = "c_use",
			type = TYPE_STRING,
			usage = PROPERTY_USAGE_DEFAULT
		},{
			name = "c_multi_cursor_list",
			type = TYPE_PACKED_VECTOR2_ARRAY,
			usage = PROPERTY_USAGE_DEFAULT
		},{
			name = "Rules",
			type = TYPE_NIL,
			hint_string = "r_",
			usage = PROPERTY_USAGE_GROUP
		},{
			name = "r_only_draw_on",
			type = TYPE_INT,
			usage = PROPERTY_USAGE_DEFAULT
		},{
			name = "r_no_draw_on",
			type = TYPE_INT,
			usage = PROPERTY_USAGE_DEFAULT
		},{
			name = "r_scattering",
			type = TYPE_FLOAT,
			hint = PROPERTY_HINT_RANGE,
			hint_string = "0, 1",
			usage = PROPERTY_USAGE_DEFAULT
		},{
			name = "r_scatter_affects_erase",
			type = TYPE_BOOL,
			usage = PROPERTY_USAGE_DEFAULT
		}
		]




