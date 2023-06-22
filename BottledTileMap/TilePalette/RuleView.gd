@tool
extends Control

var data
var prob_gradient:Gradient = Gradient.new()

const CENTER_INDEX_X:int = 6
const CENTER_INDEX_Y:int = 4
const CELL_SIZE:int = 56
const CELL_OFFSET:Vector2i = Vector2i(16,16)
const CELL_SIZE_V:Vector2i = Vector2i(CELL_SIZE, CELL_SIZE)-CELL_OFFSET
const SELECT_OFFSET:Vector2i = Vector2i(3,3)
const SELECT_SIZE:int = 62
const SELECT_SIZE_V:Vector2i = Vector2i(SELECT_SIZE, SELECT_SIZE)
const OUTLINE_RULE:int = 10
const OUTLINE_SELECT:int = 5

var selected_cell:Vector2i



func _process(delta):
	queue_redraw()

func _ready():
	prob_gradient.add_point(0, Color.RED)
	prob_gradient.add_point(1, Color.GREEN)
	
func _input(event):
	if event != InputEventMouse: return
#	if data == null: data = get_node("../../../")
	
	var mouse_pos:Vector2i = get_local_mouse_position()/CELL_SIZE
	if event is InputEventMouseMotion:
		data._set_pos_setting(mouse_pos)
	if event is InputEventMouseButton:
		data.action_on_cell(mouse_pos)
	

func _draw():
#	return
	# draw origin
	draw_rect(Rect2i(CENTER_INDEX_X*CELL_SIZE,CENTER_INDEX_Y*CELL_SIZE,CELL_SIZE,CELL_SIZE), Color.DARK_BLUE)
	
	# draw selected
	draw_rect(Rect2i((selected_cell*CELL_SIZE)-SELECT_OFFSET, Vector2i(SELECT_SIZE,SELECT_SIZE)), Color.BLACK, false, OUTLINE_SELECT)
	
	# draw rules
	var color:Color
	for rule in data.current_group[data.current_tile].rules:
		color = prob_gradient.sample(rule.prob/100)
		draw_rect(Rect2i((rule.pos*CELL_SIZE)+CELL_OFFSET, CELL_SIZE_V), color, false, OUTLINE_RULE)
