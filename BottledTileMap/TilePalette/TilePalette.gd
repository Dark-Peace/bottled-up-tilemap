@tool
extends Control

const single_tile_border_color: Color = Color("fce844")
const atlas_tile_border_color: Color = Color("c9cfd4")
const auto_tile_border_color: Color = Color("4490fc")
const subtile_border_color: Color = Color("4cb299")
const absent_subtile_border_color: Color = Color(1, 0, 0)
const absent_subtile_fill_color: Color = Color(1, 0, 0, 0.7)
const tile_selection_color: Color = Color(0, 0, 1, 0.7)
const tile_hint_label_font_color: Color = Color(0, 0, 0)

const GROUPCHAR_HIDDEN:String = "*"
const GROUPCHAR_TILEMAP:String = "$"
const GROUPCHAR_TILESET:String = "€"
const GROUPCHAR_TEXTURE:String = "£"
const GROUPCHAR_CUSTOM:String = "#"
const GROUPNAME_ALLTILES:String = "ALL_TILES"
const GROUPNAME_NOGROUP:String = "NO_GROUP"

#var _tile_list: ItemList
@onready var _panel:ScrollContainer = $"%Panel"
@onready var _group_tree:Tree = $"%GroupTree"
@onready var _preview:ScrollContainer = $"%Preview"
@onready var _preview_list:VBoxContainer = $"%PreviewList"

var _tile_map_editor: Control
var tilemap:BottledTileMap
var curr_preview_type:String
#var can_see_tile_hint = false
enum VIEW {Group, Tex, List}
var current_view = VIEW.Group

var tile_list:Dictionary
var group_list:Dictionary
var fav_groups:Array[String]
var hidden_groups:Array[String]

var can_multi_check:bool = false
var can_show_subview:bool = true

var selected_left:int = -1
var selected_right:int = -1

var tileset:TileSet : set = _set_tileset
func _set_tileset(value):
	if tileset == value:
		return
#	_clear()
	tileset = value
	if tileset: _fill()

func set_lists(tile_list: ItemList, subtile_list: ItemList):
	pass
#	_tile_list = tile_list
#	_subtile_list = subtile_list

func set_tools(tile_map_editor: Control, interface_display_scale: float = 1):
	_tile_map_editor = tile_map_editor
	$"%TileCells"/HBoxContainer4/Dupli.icon = get_theme_icon("Duplicate","EditorIcons")
	$"%TileCells"/HBoxContainer4/Erase.icon = get_theme_icon("ImportFail","EditorIcons")
	$"%TileCells"/ScrollContainer/VBoxContainer/HBoxContainer/Right/HBoxContainer/SaveGroups.icon = get_theme_icon("Save","EditorIcons")
	
	
# Bottled TileMap
func go_to_tile(inc:int):
	var max_tiles = 0

# Bottled TileMap
func count_tiles_in_texture():
	pass

func trigger_preview(type:String):
	clear_preview_list()
	if curr_preview_type in ["", type] and not show_preview_list():
		curr_preview_type = ""
		return
	match type:
		"Pattern": pattern_list()
		"Cursors": cursor_list()
		"TileMaps": tilemap_list()
		"Brush": brush_preview()
	curr_preview_type = type

func show_preview_list():
	_preview.visible = !_preview.visible
	return _preview.visible

func toggle_cell_manager():
	$"%TileCells".visible = $"%ToggleTileCell".pressed

func brush_preview():
	var preview = _preview
	preview.draw_type = preview.DrawType.Brush
	preview.brush_pos = tilemap.get_tiles_with_brush(Vector2.ZERO)
	preview.queue_redraw()

func pattern_list(): #TODO
	var preview = _preview
	preview.draw_type = preview.DrawType.Pattern
	preview.tileset = tileset
	preview.pattern_list = tilemap.pattern_list
	preview.queue_redraw()
	
	var new_pattern:CheckBox; var value:Array;
	for c in tilemap.pattern_list.size():
		value = tilemap.pattern_list[c]
		if value.is_empty(): continue
		new_pattern = _preview.get_node("List/Template").duplicate()
		new_pattern.visible = true
		new_pattern.text = str(c)
		new_pattern.set_meta("id", c)
		new_pattern.custom_minimum_size.y = preview.SIZE_Y+preview.SPACE_Y
		new_pattern.connect("pressed",Callable(self,"select").bind(c, "p_id"))
		_preview.get_node("List").add_child(new_pattern)

func cursor_list():
	var new_cursor:CheckBox; var value:Vector2;
	for c in tilemap.c_multi_cursor_list.size():
		value = tilemap.c_multi_cursor_list[c]
		if value == Vector2(0,0): continue
		new_cursor = _preview.get_node("List/Template").duplicate()
		new_cursor.visible = true
		match int(sign(value.x)):
			1: new_cursor.text = "Right: "+str(value.x)
			-1: new_cursor.text = "Left: "+str(value.x)
		new_cursor.text += "   "
		match int(sign(value.y)):
			1: new_cursor.text += "Down: "+str(value.y)
			-1: new_cursor.text += "Up: "+str(value.y)
		new_cursor.set_meta("id", c)
		new_cursor.connect("pressed",Callable(self,"select").bind(c, "c_use"))
		_preview_list.add_child(new_cursor)
	
func clear_preview_list():
	for n in _preview_list.get_children():
		if n.name != "Template": n.queue_free()

func tilemap_list():
	var new_map:CheckBox
	for c in tilemap.t_tilemap_list.size():
		if tilemap.t_tilemap_list[c] == NodePath(): continue
		new_map = _preview_list.get_node("Template").duplicate()
		new_map.visible = true
		new_map.button_pressed = str(c) in tilemap.t_use.split(" ")
		new_map.text = tilemap.get_node(tilemap.t_tilemap_list[c]).name
		new_map.set_meta("id", c)
		new_map.connect("pressed",Callable(self,"select").bind(c, "t_use"))
		_preview_list.add_child(new_map)

func select(id, type):
	var children = _preview_list.get_children()
	if type == "p_id":
		for n in children:
			if n.get_meta("id") != id: n.button_pressed = false
		tilemap.set(type, -1)
		for checkbox in children:
			if checkbox.pressed: tilemap.set(type, checkbox.get_meta("id"))
		tilemap.notify_property_list_changed()
		return
		
	if type == "t_use" and not can_multi_check: 
		for n in children:
			if n.get_meta("id") == id: continue
			n.button_pressed = false
	tilemap.set(type, "")
	
	for checkbox in children:
		if not checkbox.pressed: continue
		tilemap.set(type, tilemap.get(type)+" "+String(checkbox.get_meta("id")))
		_set_tileset(tilemap.tile_set)
	tilemap.notify_property_list_changed()

func can_multi_select():
	can_multi_check = !can_multi_check

func turn_into_pattern():
	tilemap.set_turn_into_pattern(true)

func scan():
	tilemap.scan_for_tilemaps(true)

func check_all():
	var uncheck = true
	for b in _preview_list.get_children():
		if not b.has_meta("id") or b.button_pressed == true: continue
		b.button_pressed = true
		select(b.get_meta("id"), "c_use")
		uncheck = false
	if uncheck:
		for b in _preview_list.get_children():
			if not b.has_meta("id"): continue
			b.button_pressed = false
			select(b.get_meta("id"), "c_use")

func display_tile_hints():
	tilemap.tm_hints.clear()
	for tm in tilemap.t_tilemap_list:
		if tilemap.get_node(tm).get_cell_source_id(tilemap.local_to_map(tilemap.get_local_mouse_position())) != -1:
			tilemap.tm_hints.append(tilemap.get_node(tm))
	tilemap.queue_redraw()

func _find_in_editor(target:String="TileMapEditor", node:Node=get_tree().root, _name:String="") -> Node:
	if node.get_class() == target and (_name == "" or node.name == _name):
		return node
	for child in node.get_children():
		var tilemap_editor = _find_in_editor(target, child)
		if tilemap_editor:
			return tilemap_editor
	return null

func _ready():
	BTM.palette = self
	fav_groups.append(GROUPNAME_NOGROUP)
	fav_groups.append(GROUPNAME_ALLTILES)
#	get_parent().resized.connect(resize)
#
#func resize():
#	print("ok")
#	size = get_parent().size

func _process(delta):
	size = get_parent().size

func _fill():
	_clear()
#	tilemap.tilecell = get_tilecell()
	if not tileset.has_meta("TileList"):
		tileset.set_meta("TileList", BTM.get_tiles_ids(tileset))
	_fill_group_view()
	_group_tree.show()

func _fill_list_view(tilelist:Array[BTM.TILEID]=tileset.get_meta("TileList")):
	$"%ListView".clear()
	var id_map = tileset.get_meta("ID_Map", {})
	var tilelist_indexes:Dictionary; var index:int=0; var list_index:int
	for id in tilelist:
		tilelist_indexes[index] = id
		index += 1
		$"%ListView".add_item("", tileset.get_source(id.source).texture)
		list_index = $"%ListView".get_item_count()-1
		$"%ListView".set_item_icon_region(list_index,tileset.get_source(id.source).get_tile_texture_region(id.coords))
		$"%ListView".set_item_tooltip_enabled(list_index,true)
		$"%ListView".set_item_tooltip(list_index, str(tilemap._get_id_in_map(id.v)))
	tileset.set_meta("TileListIndexes", tilelist_indexes)

func _on_sub_tab_tab_changed(tab):
	match tab:
		0: _fill_subtile_view()
		1: _fill_alttile_view()
		2: _fill_variant_view()

func _fill_subtile_view():
	pass

func _fill_variant_view():
	pass

func _fill_alttile_view():
	pass

func _fill_subview(tilelist:Array):
	$"%Subtile".clear()
#	var tilelist_indexes:Dictionary; var index:int=0
	for id in tilelist:
#		tilelist_indexes[index] = id
#		index += 1
		$"%Subtile".add_item("", tileset.get_source(id.source).texture)
		$"%Subtile".set_item_icon_region($"%Subtile".get_item_count()-1,tileset.get_source(id.source).get_tile_texture_region(id.coords))
#	tileset.set_meta("TileListIndexes", tilelist_indexes)

func _fill_group_view():
	if not tileset: return
	_group_tree.clear()
	_group_tree.create_item()
	var groups:Dictionary = tilemap.get_meta("groups_by_groups", {})
	
	var no_group:Array[BTM.TILEID] = get_tiles_without_groups()
	var tilelist:Array[BTM.TILEID] = tileset.get_meta("TileList")
	var all_tiles = create_group("ALL_TILES", tilelist)
#	_group_tree.set_selected(all_tiles, 0)
	create_group("NO_GROUP", no_group)
	
	for g in groups.keys():
		tilelist = tilemap.EMPTY_TILE_ARRAY as Array[BTM.TILEID]
		create_group(g, groups.get(g, tilelist))
	
	fill_fav_group()
	select_group()

func get_tiles_without_groups():
	var no_group:Array[BTM.TILEID]
	for id in tileset.get_meta("TileList"):
		if id in tilemap.get_meta("groups_by_ids", {}).keys(): continue
		no_group.append(id)
	return no_group

func fill_fav_group():
	$"%Favorites".clear()
	$"%Favorites".create_item()
	for g in fav_groups:
		print(g)
		create_group(g, tilemap.EMPTY_TILE_ARRAY, $"%Favorites")

func create_group(g:String, group_content:Array[BTM.TILEID], tree=_group_tree):
	var group:TreeItem = tree.create_item(tree.get_root())
	group.set_icon_max_width(0,16)
	group.set_text(0, g)
	group.set_meta("TILES", group_content)
	if not group_content.is_empty():
		group.set_icon(0, tileset.get_source(group_content[0].source).texture)
		group.set_icon_region(0, tileset.get_source(group_content[0].source).get_tile_texture_region(group_content[0].coords))
	if tree == _group_tree:
		group_list[g] = group
	return group

func select_group(fav_tree:bool=false):
	var curr_group
	if not fav_tree:
		curr_group = _group_tree.get_selected().get_text(0)
		if curr_group in fav_groups and $"%Favorites".get_root() != null:
			$"%Favorites".set_selected(get_group_item(curr_group, $"%Favorites"),0)
	else:
		curr_group = $"%Favorites".get_selected()
		_group_tree.set_selected(get_group_item(curr_group.get_text(0), _group_tree),0)
	_fill_list_view(_group_tree.get_selected().get_meta("TILES",tilemap.EMPTY_TILE_ARRAY))

func get_group_item(n:String, tree:Tree):
	var children:Array[TreeItem] = tree.get_root().get_children()
	var child:TreeItem
	while not children.is_empty():
		child = children.pop_front()
		if child.get_text(0) == n: return child
		children.append_array(child.get_children())

func _clear():
	_clear_group_view()

func _clear_list_view():
	$"%ListView".clear()

func _clear_group_view():
	_clear_list_view()

func _on_delete_group_pressed():
	var curr:TreeItem = _group_tree.get_selected()
	var curr_name:String = curr.get_text(0)
	if curr_name in [GROUPNAME_ALLTILES, GROUPNAME_NOGROUP]:
		push_warning("Not allowed to remove the group "+curr_name)
		return
	
	for id in tilemap.get_meta("groups_by_groups", {})[curr_name]:
		tilemap.get_meta("groups_by_ids", {})[id].erase(curr_name)
	tilemap.get_meta("groups_by_groups", {}).erase(curr_name)
	
	_group_tree.get_selected().free()
	_fill()

func _check_remove_fav_group(curr:String):
	if not curr in fav_groups: return
	if curr in [GROUPNAME_ALLTILES, GROUPNAME_NOGROUP]:
		push_warning("Not allowed to unfavorite the group "+curr)
		return
	fav_groups.erase(curr)
	$"%Favorites".get_selected().free()
	fill_fav_group()

func _on_dupli_group_pressed():
	var curr:TreeItem = _group_tree.get_selected()
	var old_name:String = curr.get_text(0)
	var new_name:String = old_name+"2"
	var new_content:Array[BTM.TILEID]
	
	if old_name == "ALL_TILES": new_content = tileset.get_meta("TileList").duplicate()
	elif old_name == "NO_GROUP": new_content = get_tiles_without_groups().duplicate()
	else: new_content = tilemap.get_meta("groups_by_groups", {})[old_name].duplicate()
	
	tilemap.get_meta("groups_by_groups", {})[new_name] = new_content
	for id in tilemap.get_meta("groups_by_groups", {})[new_name]:
		if not id.isIN(tilemap.get_meta("groups_by_ids", {}).keys()): tilemap.get_meta("groups_by_ids", {})[id] = []
		tilemap.get_meta("groups_by_ids", {})[id].append(new_name)
	_fill()

func _on_fav_group_pressed():
	var curr:String = _group_tree.get_selected().get_text(0)
	if not curr in fav_groups: fav_groups.append(curr)
	else: _check_remove_fav_group(curr)
	_fill()

func _on_hide_group_pressed():
	var curr:String = _group_tree.get_selected().get_text(0)
	_check_remove_fav_group(curr)
	if curr in hidden_groups: hidden_groups.erase(curr)
	elif curr in [GROUPNAME_ALLTILES, GROUPNAME_NOGROUP]:
		push_warning("Not allowed to hide the group "+curr)
	else:
		hidden_groups.append(curr)
		_group_tree.get_selected().free()
	_fill()

func _on_tileset_changed(new_tileset: TileSet):
	_fill()

func _on_ListView_item_selected(index: int) -> void:
	if index != selected_right:
		tilemap.current_tile = tileset.get_meta("TileListIndexes", {}).get(index, BTM.TILEID.new())
		selected_left = index
	for item in $"%ListView".get_selected_items():
		if item == selected_left or item == selected_right: continue
		$"%ListView".deselect(item)
#	current_tile = index
#	_tile_list.select(current_tile)
#	_tile_map_editor._palette_selected(int(current_tile))
	# TODO : display subtile view
#	init_tilecell()

# Cell Manager
func init_tilecell():
	var populate_array = {"tilemap":tilemap.curr_tilemap,"tile_id": tilemap.current_tile}#,"tileset":tileset}
	$"%TileCells".populate_infos(populate_array)


enum REPLACE_PARAM {Auto, SelectionOnly, Global}
enum SELECT {SelectionOnly, WholeLayer, Global, SelectionAllLayers}
func _on_EraseAll_pressed() -> void:
	match $"%Selections".get_selected_id():
		SELECT.SelectionOnly: tilemap.global_replacing(tilemap.ALL_TILES_V, tilemap.ERASE_TILE_V, REPLACE_PARAM.SelectionOnly)
		SELECT.WholeLayer: tilemap.global_replacing(tilemap.ALL_TILES_V, tilemap.ERASE_TILE_V, REPLACE_PARAM.Global)
		SELECT.Global: tilemap.global_replacing(tilemap.ALL_TILES_V, tilemap.ERASE_TILE_V, REPLACE_PARAM.Global, tilemap.ALL_LAYERS)
		SELECT.SelectionAllLayers: tilemap.global_replacing(tilemap.ALL_TILES_V, tilemap.ERASE_TILE_V, REPLACE_PARAM.SelectionOnly, tilemap.ALL_LAYERS)
	$"%Selections".select(SELECT.SelectionOnly)

func _on_select_all_pressed():
	var tile:BTM.TILEID = [tilemap.NO_TILE_ID,tilemap.current_tile][int($"%SelectTile".button_pressed)]
	
	match $"%Selections".get_selected_id():
		SELECT.SelectionOnly: return
		SELECT.WholeLayer: tilemap.select_all_cells(tilemap.current_layer, tile)
		SELECT.Global: tilemap.select_all_cells(tilemap.ALL_LAYERS, tile)
		SELECT.SelectionAllLayers: tilemap.select_all_cells(tilemap.ALL_LAYERS, tile, true)
	$"%Selections".select(SELECT.SelectionOnly)
	

func _on_TilePalette_resized() -> void:
	$"%TileCells".get_node("ScrollContainer").custom_minimum_size.y = max(175, size.y-100)

func get_tilecell():
	return $"%TileCells"

#func _on_Views_item_selected(index: int) -> void:
#	current_view = index
##	$HSplitContainer/TextureVBoxContainer/Main/HSplitContainer/Panel/GroupView.visible = current_view == VIEW.Group
#	$HSplitContainer/TextureVBoxContainer/Main/HSplitContainer/Panel/ScalingHelper.visible = current_view in [VIEW.Tex, VIEW.List]
#	$"%ListView".visible = current_view in [VIEW.Group, VIEW.List]
#	_clear()
#	_fill()

func _on_Search_text_changed(new_text: String) -> void:
	for g in group_list.keys():
		if g in hidden_groups and not new_text[0] == GROUPCHAR_HIDDEN: continue
		group_list[g].visible = new_text.is_subsequence_ofn(g)

func _on_tab_changed(tab):
	$TileMap.visible = (tab == 0)
	$BetterTerrain.visible = (tab == 1)
	$PatternEditor.visible = (tab == 2)
	$"%Tabs_TM".current_tab = tab
	$BetterTerrain.get_node("%Tabs_BT").current_tab = tab
	$PatternEditor.get_node("%Tabs_P").current_tab = tab

func _on_tile_size_value_changed(value):
	$"%ListView".fixed_icon_size = Vector2(value,value)

func _on_toggle_sub_pressed():
	can_show_subview = $"%ToggleSub".button_pressed

func _on_random_sub_pressed():
	pass # Replace with function body.


func _on_clear_invalid_pressed():
	tilemap.fix_invalid_tiles()

func _on_list_view_empty_clicked(at_position, mouse_button_index):
	if mouse_button_index != MOUSE_BUTTON_RIGHT: return
	selected_right = -1
	tilemap.right_click_tile = tilemap.ERASE_TILE_ID


func _on_list_view_item_clicked(index, at_position, mouse_button_index):
	if mouse_button_index != MOUSE_BUTTON_RIGHT: return
	selected_right = index
	tilemap.right_click_tile = tileset.get_meta("TileListIndexes", {}).get(index, tilemap.ERASE_TILE_ID)
