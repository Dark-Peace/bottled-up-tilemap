@tool
extends Control

@export var can_run = false

var data
var prob_gradient:Gradient = load("res://addons/BottledTileMap/RuleProbGradient.tres")

const CENTER_INDEX:Vector2i = Vector2i(5,4)
const CELL_SIZE:int = 56
const CELL_SIZE_V:Vector2i = Vector2i(CELL_SIZE, CELL_SIZE)
const SELECT_OFFSET:Vector2i = Vector2i(3,3)
const SELECT_SIZE:Vector2i = Vector2i(62, 62)
const RULE_SIZE:Vector2i = Vector2i(50, 50)
const RULE_OFFSET:Vector2i = Vector2i(3,3)
const OUTLINE_RULE:int = 10
const OUTLINE_SELECT:int = 5
const GRID_OFFSET:Vector2i = Vector2i(12,15)

var scroll_offset:Vector2i = Vector2i(0,0)

@onready var limit_rect:Rect2i = Rect2i($Grid.position, $Grid.size*$Grid.scale)

var selected_cell:Vector2i


func _input(event):
	if not can_run: return
	if not (event is InputEventMouseMotion or event is InputEventMouseButton): return
	
	var mouse_pos:Vector2i = get_local_mouse_position()
#	if event is InputEventMouseButton:
#		print(parent_rect, mouse_pos, data.p.bottom_button.button_pressed)
	if not (limit_rect.has_point(mouse_pos) and data.p.bottom_button.button_pressed and data.visible): return
	mouse_pos = Vector2i(mouse_pos/CELL_SIZE)-CENTER_INDEX-scroll_offset
	
	if event is InputEventMouseMotion:
		# mouse moving
		# update position only when creating rules
		if data.rule_tool != 0: return
		data._set_pos_setting(mouse_pos)
		# if new cell entered -> allow creating when mouse button held
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
	print(scroll_offset)
	var origin = CENTER_INDEX+scroll_offset
	# draw origin
	draw_rect(Rect2i((origin*CELL_SIZE_V)+GRID_OFFSET, CELL_SIZE_V), Color.DARK_BLUE)
	
	# draw selected
	if data.current_rule != {}:
		draw_rect(Rect2i(((data.current_rule.cell+origin)*CELL_SIZE)-SELECT_OFFSET+GRID_OFFSET, SELECT_SIZE), Color.BLACK, false, OUTLINE_SELECT)
	
	# draw rules
	var color:Color
	for rule in data.current_group[data.current_tile].rules:
		color = prob_gradient.sample(rule.prob/100)
		draw_rect(Rect2i(((rule.cell+origin)*CELL_SIZE)+RULE_OFFSET+GRID_OFFSET, RULE_SIZE), color, false, OUTLINE_RULE)


func _on_v_scroll_bar_value_changed(value):
	scroll_offset.y = -value
	queue_redraw()

func _on_h_scroll_bar_value_changed(value):
	scroll_offset.x = value
	queue_redraw()

func set_limits(max_limits:Vector2i, min_limits:Vector2i):
	print(max_limits, min(0, max_limits.y))
	max_limits.x = max(0, max_limits.x)
	max_limits.y = min(0, max_limits.y)
	min_limits.x = min(0, max_limits.x)
	min_limits.y = max(0, max_limits.y)
	
	get_node("VScrollBar").max_value = min_limits.y
	get_node("VScrollBar").min_value = max_limits.y
	get_node("HScrollBar").max_value = max_limits.x
	get_node("HScrollBar").min_value = max_limits.x
	
	get_node("HScrollBar").value = 0
	get_node("VScrollBar").value = 0
	
	get_node("HScrollBar").visible = !(max_limits.x == 0 and min_limits.x == 0)
	get_node("VScrollBar").visible = !(max_limits.y == 0 and min_limits.y == 0)
	
	print(get_node("VScrollBar").max_value)
	print(get_node("HScrollBar").max_value)
	print(get_node("VScrollBar").min_value)
	print(get_node("HScrollBar").min_value)
