@tool
extends ScrollContainer

enum DrawType {No, Pattern, Brush}
var draw_type = DrawType.No

var tileset:TileSet
var pattern_list = []
var brush_pos = []

const START_X = 50
const START_Y = 25
const SPACE_Y = 25
const SIZE_Y = 75
const LABEL_OFFSET_X = 5
const SIZE_BRUSH = 100
const START_BRUSH = 50

var label = Label.new()
var font = label.get_theme_font("")
#var cell_size:float

#func _process(delta: float) -> void:
#	update()
	
func _draw() -> void:
	match draw_type:
		DrawType.Pattern:
			for p in pattern_list.size():
				draw_pattern(pattern_list[p], START_X, START_Y+(SIZE_Y+SPACE_Y)*p)
		DrawType.Brush:
			draw_brush()
#	clear_data()

func clear_data():
	draw_type = DrawType.No
	pattern_list.clear()
	brush_pos.clear()
	tileset = null

func draw_pattern(curr_pattern:Array, x:float, y:float):
	var size:float = 0
	for line in curr_pattern.size():
		size = [size, curr_pattern.size(), curr_pattern[line].size()].max()
	var _size = SIZE_Y/size
	
	var id; var texture:Texture2D; var region:Rect2;
	for line in curr_pattern.size():
		for col in curr_pattern[line].size():
			id = curr_pattern[line][col]
			if id == " ": continue
			if id in ["x", "-1"]:
				texture = theme.get_icon("KeyInvalid", 'EditorIcons')
				region = Rect2(Vector2(0,0), texture.get_size())
				draw_texture_rect_region(texture, Rect2(x+_size*col,y+_size*line, _size,_size), region)
				continue
			if "R" in id:
				draw_string(font, Vector2(x+_size*col+LABEL_OFFSET_X,y+_size*line+_size/2), id.right(1))
				continue
			id = int(id)
			texture = tileset.tile_get_texture(id)
			region = tileset.tile_get_region(id)
			draw_texture_rect_region(texture, Rect2(x+_size*col,y+_size*line, _size,_size), region)
			
func draw_brush():
	var size:float
	for pos in brush_pos: size = [size, pos.x, pos.y].max()
	size *= 2
	var _size = SIZE_BRUSH/size
	
	var color = Color.WHITE
	for pos in brush_pos:
		if pos == Vector2(0,0): color = Color.YELLOW
		else: color = Color.WHITE
		draw_rect(Rect2(100+pos.x*_size,100+pos.y*_size,_size,_size), color)
