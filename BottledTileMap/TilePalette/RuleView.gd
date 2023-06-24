@tool
extends Control

@export var can_run = false

var data
var prob_gradient:Gradient = Gradient.new()

const CENTER_INDEX:Vector2i = Vector2i(5,4)
const CELL_SIZE:int = 56
const CELL_SIZE_V:Vector2i = Vector2i(CELL_SIZE, CELL_SIZE)
const SELECT_OFFSET:Vector2i = Vector2i(3,3)
const SELECT_SIZE:Vector2i = Vector2i(62, 62)
const RULE_SIZE:Vector2i = Vector2i(50, 50)
const RULE_OFFSET:Vector2i = Vector2i(3,3)
const OUTLINE_RULE:int = 10
const OUTLINE_SELECT:int = 5

@onready var parent_rect:Rect2i

var selected_cell:Vector2i



func _process(delta):
	if not can_run: return

func _ready():
	prob_gradient.add_point(0.999, Color.GREEN)
	prob_gradient.add_point(0, Color.RED)
	
func _input(event):
	if not can_run: return
	if not (event is InputEventMouseMotion or event is InputEventMouseButton): return
	
	var mouse_pos:Vector2i = get_local_mouse_position()
#	if event is InputEventMouseButton:
#		print(parent_rect, mouse_pos, data.p.bottom_button.button_pressed)
	if not (parent_rect.has_point(mouse_pos) and data.p.bottom_button.button_pressed and data.visible): return
	mouse_pos = Vector2i(mouse_pos/CELL_SIZE)-CENTER_INDEX
	
	if event is InputEventMouseMotion:
		if data.rule_tool != 0: return
		data._set_pos_setting(mouse_pos)
		if selected_cell != mouse_pos:
			selected_cell = mouse_pos
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): data.action_on_cell(mouse_pos, MOUSE_BUTTON_LEFT)
			elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT): data.action_on_cell(mouse_pos, MOUSE_BUTTON_RIGHT)
	elif event is InputEventMouseButton and event.is_pressed():
		if selected_cell != mouse_pos:
			selected_cell = mouse_pos
		data.action_on_cell(mouse_pos, event.button_index)
	

func _draw():
	if not can_run: return
	# draw origin
	draw_rect(Rect2i(CENTER_INDEX*CELL_SIZE_V, CELL_SIZE_V), Color.DARK_BLUE)
	
	# draw selected
	if data.current_rule != {}:
		draw_rect(Rect2i(((data.current_rule.cell+CENTER_INDEX)*CELL_SIZE)-SELECT_OFFSET, SELECT_SIZE), Color.BLACK, false, OUTLINE_SELECT)
	
	# draw rules
	var color:Color
	for rule in data.current_group[data.current_tile].rules:
		color = prob_gradient.sample(rule.prob/100)
		draw_rect(Rect2i(((rule.cell+CENTER_INDEX)*CELL_SIZE)+RULE_OFFSET, RULE_SIZE), color, false, OUTLINE_RULE)
