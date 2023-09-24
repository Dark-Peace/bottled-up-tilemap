@tool
extends ScrollContainer


@export var dock:Control : set = set_dock
var tilemap:BottledTileMap
var tileset:TileSet
var theme_list:Dictionary

# pattern consts
const START_X = 50
const START_Y = 25
const SPACE_X = 25
const SIZE_X = 75
const PANEL_SIZE = 500
const LABEL_OFFSET_X = 5
# theme consts
const DEFAULT_THEME = "CUSTOM"
const From = 0
const To = 1

var current_theme:String = DEFAULT_THEME
var custom_theme:Dictionary

#func _ready():
##	$"%SwapTemplate".visible = false
#	print($%Convert.get_signal_connection_list($%Convert.pressed), "okok")

func set_dock(value):
	dock = value
	tilemap = dock.tilemap
	tileset = tilemap.tile_set
	$"%Preview".pattern_list = tilemap.pattern_list
	$"%Preview".tileset = tileset
	
#func _on_switch_editors_pressed():
#	$VBoxContainer.move_child($VBoxContainer.get_child(1),2)

func fill_pattern_list():
	update_preview()

func _on_convert_pressed():
	tilemap.save_brush_as_pattern()
	
	update_preview()

func select_pattern(id:int):
	tilemap.pattern_id = id
	if $"%PreviewPanel".visible: update_preview()

func _on_delete_pattern_pressed():
	if tilemap.pattern_id == -1: return
	$"%PreviewList".get_child(tilemap.pattern_id+1).queue_free()
	tilemap.pattern_list.remove_at(tilemap.pattern_id)
	update_preview()

func _on_dupli_pattern_pressed():
	if tilemap.pattern_id == -1: return
	var new_pattern = $"%PreviewList".get_child(tilemap.pattern_id+1).duplicate()
	$"%PreviewList".add_child(new_pattern)
	$"%PreviewList".move_child(new_pattern, tilemap.pattern_id+2)
	tilemap.pattern_list.insert(tilemap.pattern_id+1,tilemap.pattern_list[tilemap.pattern_id].duplicate())
	update_preview()

func _on_toggle_editor_toggled(button_pressed):
	$"%PreviewPanel".visible = button_pressed
	$"TileEditor".visible = button_pressed
	update_preview()

func _on_modify_pressed():
	if tilemap.pattern_id == -1: return
	tilemap.pattern_list.remove_at(tilemap.pattern_id)
	tilemap.pattern_list.insert(tilemap.pattern_id, tilemap.current_brush_tiles)
	update_preview()

func update_preview():
	$"%Preview".queue_redraw()

#func _draw() -> void:
#	if tilemap == null: return
#	for p in tilemap.pattern_list.size():
##		draw_pattern(tilemap.pattern_list[p], START_X, START_Y+(SIZE_X+SPACE_X)*p)
#		var curr_pattern:Dictionary = tilemap.pattern_list[p]
#		var _size = _get_pattern_rect_size(curr_pattern)
#		var id:Dictionary; var texture:Texture2D; var reg:Rect2; var transpose:bool;
#
#		for v in curr_pattern.keys():
#			id = curr_pattern[v]
#			texture = tileset.get_source(id.source).texture
#			reg = tileset.get_source(id.source).get_tile_texture_region(id.coords)
#			if id.alt in BTM.ALT_H: reg.size.x = -reg.size.x
#			if id.alt in BTM.ALT_V: reg.size.y = -reg.size.y
#			if id.alt in BTM.ALT_T: transpose = true
#			$"%Preview".draw_texture_rect_region(texture, Rect2(START_X+_size*v.x,START_Y+(SIZE_X+SPACE_X)*p+_size*v.y, _size,_size), \
#													reg, Color.WHITE, transpose)
		
#	if $"%PreviewPanel".visible:
#		draw_pattern(tilemap.pattern_list[tilemap.pattern_id], START_X, START_Y, PANEL_SIZE, $"%PreviewPanel")

func _get_pattern_rect_size(curr_pattern:Dictionary, max_size:int=SIZE_X):
	var s:float = 0
	var pattern_size:Vector2i = get_pattern_limits(curr_pattern)
	for line in pattern_size.y:
		s = [s, pattern_size.y, pattern_size.x].max()
	return max_size/s

func draw_pattern(curr_pattern:Dictionary, x:float, y:float, max_size:int=SIZE_X, node:Control=$"%Preview"):
	pass

func get_pattern_limits(curr_pattern:Dictionary):
	var min_x:int=INF; var max_x:int=-INF; var min_y:int=INF; var max_y:int=-INF;
	for t in curr_pattern.keys():
		if t.x < min_x: min_x = t.x
		if t.x > max_x: max_x = t.x
		if t.y < min_y: min_y = t.y
		if t.y > max_y: max_y = t.y
	return Vector2i(max_x-min_x,max_y-min_y)


## Themes ---------------------------------------------------------------
#
#func select_theme(_theme:String):
#	current_theme = _theme
#	if $"%ActiveTheme".button_pressed: tilemap.used_theme = _theme
#	for node in $"%ThemeList".get_children():
#		if node.name == current_theme: continue
#		node.button_pressed = false
#	_fill_swaps()
#
#func _fill_swaps():
#	var swap_dif = theme_list[current_theme].size() - $"%Swaps".get_child_count()-2
#	if swap_dif == 0: pass
#	elif swap_dif < 0:
#		for i in abs(swap_dif): $"%Swaps".get_child(i+1).queue_free()
#	else:
#		for i in abs(swap_dif): _on_add_swap_pressed()
#
#	for index in theme_list[current_theme].size():
#		$"%Swaps".get_child(index+1).get_node("From").text = theme_list[current_theme][index][From]
#		$"%Swaps".get_child(index+1).get_node("To").text = theme_list[current_theme][index][To]
#
#func _on_active_theme_toggled(button_pressed):
#	tilemap.used_theme = [tilemap.NO_THEME, current_theme][int(button_pressed)]
#
#func _on_apply_theme_pressed():
#	var select_type:int = dock.get_node("%Selections").get_selected_id()
#	match select_type:
#		0: tilemap.apply_theme_global(1)
#		1: tilemap.apply_theme_global(2)
#		2: tilemap.apply_theme_global(2, tilemap.ALL_LAYERS)
#		3: tilemap.apply_theme_global(1, tilemap.ALL_LAYERS)
#
#func _on_add_theme_pressed():
#	if $"%ThemeName".text == "":
#		push_warning("Write a name for your new theme.")
#		return
#	_add_theme($"%ThemeName".text)
#
#func _add_theme(_name:String):
#	var new_theme:Button = $"%CUSTOM".duplicate()
#	new_theme.name = _name
#	new_theme.text = _name
#	new_theme.pressed.connect(select_theme.bind(_name))
#	$"%ThemeList".add_child(new_theme)
#	$"%ThemeName".text = ""
#	theme_list[_name] = []
#
#func _on_dupli_theme_pressed():
#	_add_theme(current_theme)
#
#func _on_rename_theme_pressed():
#	if $"%ThemeName".text == "" or current_theme == DEFAULT_THEME:
#		push_warning("Write a new name for your theme.")
#		return
#	$"%ThemeList".get_node(current_theme).name = $"%ThemeName".text
#	theme_list[$"%ThemeName".text] = theme_list[current_theme]
#	theme_list.erase(current_theme)
#	current_theme = $"%ThemeName".text
#
#func _on_delete_theme_pressed():
#	if current_theme == DEFAULT_THEME: return
#	theme_list.erase(current_theme)
#	$"%ThemeList".get_node(current_theme).queue_free()
#	select_theme(DEFAULT_THEME)
#
#func _on_add_swap_pressed():
#	var new_swap:VBoxContainer = $"%SwapTemplate".duplicate()
#	new_swap.visible = true
#	$"%Swaps".add_child(new_swap)
#	new_swap.get_node("Switch").pressed.connect(_on_switch_pressed.bind(new_swap.get_index()))
#	new_swap.get_node("Remove").pressed.connect(_on_remove_pressed.bind(new_swap.get_index()))
#	new_swap.get_node("From").pressed.connect(_on_swap_changed.bind(new_swap.get_index(), From))
#	new_swap.get_node("To").pressed.connect(_on_swap_changed.bind(new_swap.get_index(), To))
#	$"%Swaps".move_child(new_swap, new_swap.get_index()-1)
#
#func _on_remove_pressed(index:int):
#	$"%Swaps".get_child(index).queue_free()
#	theme_list[current_theme].remove(index)
#
#func _on_switch_pressed(index:int):
#	var swap = $"%Swaps".get_child(index)
#	var temp = swap.get_node("From").text
#	swap.get_node("From").text = swap.get_node("To").text
#	swap.get_node("To").text = temp
#	theme_list[current_theme][index][From] = swap.get_node("From").text
#	theme_list[current_theme][index][To] = swap.get_node("To").text
#
#func _on_swap_changed(index:int, type:int):
#	if index >= theme_list[current_theme].size(): theme_list[current_theme][index].append(["-1","-1"])
#	theme_list[current_theme][index][type] = $"%Swaps".get_child(index).get_node(str(type)).text


func _on_button_pressed():
	print("what")
