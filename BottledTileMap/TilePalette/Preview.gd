@tool
extends ScrollContainer


var tileset:TileSet
var pattern_list = []

const START_X = 50
const START_Y = 25
const SPACE_X = 25
const SIZE_X = 75
const LABEL_OFFSET_X = 5

var label = Label.new()
var font = label.get_theme_font("")

	
func _draw() -> void:
	for p in pattern_list.size():
		draw_pattern(pattern_list[p], START_X, START_Y+(SIZE_X+SPACE_X)*p)

func clear_data():
	pattern_list.clear()
	tileset = null

func draw_pattern(curr_pattern:Dictionary, x:float, y:float):
	var s:float = 0
	var pattern_size:Vector2i = get_pattern_limits(curr_pattern)
	for line in pattern_size.y:
		s = [s, pattern_size.y, pattern_size.x].max()
	var _size = SIZE_X/s
	
	var id:Dictionary; var texture:Texture2D; var reg:Rect2; var transpose:bool;
	for v in curr_pattern.keys():
		id = curr_pattern[v]
		texture = tileset.get_source(id.source).texture
		reg = tileset.get_source(id.source).get_tile_texture_region(id.coords)
		if id.alt in BTM.ALT_H: reg.size.x = -reg.size.x
		if id.alt in BTM.ALT_V: reg.size.y = -reg.size.y
		if id.alt in BTM.ALT_T: transpose = true
		draw_texture_rect_region(texture, Rect2(x+_size*v.x,y+_size*v.y, _size,_size), reg, Color.WHITE, transpose)
#	for line in pattern_size.y:
#		for col in pattern_size.x:
#			id = curr_pattern[line][col]
#			if id == " ": continue
#			if id in ["x", "-1"]:
#				texture = theme.get_icon("KeyInvalid", 'EditorIcons')
#				region = Rect2(Vector2(0,0), texture.get_size())
#				draw_texture_rect_region(texture, Rect2(x+_size*col,y+_size*line, _size,_size), region)
#				continue
#			if "R" in id:
#				draw_string(font, Vector2(x+_size*col+LABEL_OFFSET_X,y+_size*line+_size/2), id.right(1))
#				continue
#			id = int(id)
#			texture = tileset.tile_get_texture(id)
#			region = tileset.tile_get_region(id)
#			draw_texture_rect_region(texture, Rect2(x+_size*col,y+_size*line, _size,_size), region)

func get_pattern_limits(curr_pattern:Dictionary):
	var min_x:int=INF; var max_x:int=-INF; var min_y:int=INF; var max_y:int=-INF;
	for t in curr_pattern.keys():
		if t.x < min_x: min_x = t.x
		if t.x > max_x: max_x = t.x
		if t.y < min_y: min_y = t.y
		if t.y > max_y: max_y = t.y
	return Vector2i(max_x-min_x,max_y-min_y)
