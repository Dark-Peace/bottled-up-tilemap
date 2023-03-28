@tool
extends VBoxContainer

signal _tab_tileset

var active:bool = false

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
const GROUPNAME_ALLTILES:String = "ALL TILES"
const GROUPNAME_NOGROUP:String = "NO GROUP"

#var _tile_list: ItemList
@onready var _panel:ScrollContainer = $"%Panel"
@onready var _group_tree = $"%GroupTree"
@onready var _preview:ScrollContainer = $"%Preview"
@onready var _preview_list:VBoxContainer = $"%PreviewList"

var _tile_map_editor: Control
var tilemap:BottledTileMap
var curr_preview_type:String
#var can_see_tile_hint = false

var tile_list:Dictionary
var group_list:Dictionary
var fav_groups:Array[String]
var hidden_groups:Array[String]
var curr_group:String

var can_multi_check:bool = false
var can_show_subview:bool = true

var selected_left:int = -1
var selected_right:int = -1
var lock_dock:bool = false

var tileset:TileSet : set = _set_tileset
func _set_tileset(value):
	if value == null or tileset == value:
		return
	tileset = value
	if tileset: _fill()

func set_lists(tile_list: ItemList, subtile_list: ItemList):
	pass

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
	
	var new_pattern:CheckBox; var value:Dictionary;
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
	_on_tab_changed(TAB.TileMap)
	BTM.palette = self
	$PatternEditor.dock = self
	$"%GroupTree".get_child(0).connect("pressed", select_group.bind(GROUPNAME_ALLTILES))
	$"%GroupTree".get_child(1).connect("pressed", select_group.bind(GROUPNAME_NOGROUP))
	

func _process(delta):
	if not active: return
	size = get_parent().size





func _fill():
	_clear_group_view()
#	tilemap.tilecell = get_tilecell()
	if not tileset.has_meta("TileList"):
		tileset.set_meta("TileList", BTM.get_tiles_ids(tileset))
	_fill_group_view()
	_group_tree.show()

func _on_togglefav_pressed(fav=null):
	if fav == null: fav = $"%ToggleFav".button_pressed
	for g in _group_tree.get_children():
		if fav: g.visible = (g.text in fav_groups or g.text in [GROUPNAME_NOGROUP, GROUPNAME_ALLTILES])
		else: g.visible = not g.text in hidden_groups

func _fill_group_view():
	if not tileset: return
	var groups:Dictionary = tileset.get_meta("groups_by_groups", {})
	
	$"%ALL TILES".set_meta("TILES", tileset.get_meta("TileList"))
	update_no_group()
	group_list[GROUPNAME_ALLTILES] = $"%ALL TILES"
	group_list[GROUPNAME_NOGROUP] = $"%NO GROUP"
	
	var tilelist:Array[BTM.TILEID]
	for g in groups.keys():
		tilelist = tilemap.EMPTY_TILE_ARRAY as Array
		create_group(g, groups.get(g, tilelist))
	
	if curr_group == "":
		$"%ALL TILES".button_pressed = true
		select_group(GROUPNAME_ALLTILES)

func update_no_group():
	$"%NO GROUP".set_meta("TILES", get_tiles_without_groups())
	print($"%NO GROUP".get_meta("TILES"))

func get_tiles_without_groups():
	var no_group:Array[BTM.TILEID]
	for id in tileset.get_meta("TileList"):
		if tilemap.tile_has_any_group(id.v): continue
		no_group.append(id)
	return no_group
	
func create_group(g:String, group_content:Array, tree=_group_tree):
	var group:Button = _group_tree.get_child(0).duplicate()
	
	group.text = g
	group.name = g
	group.set_meta("TILES", group_content)
	group_list[g] = group
	if g == tilemap.dock_group_selected:
		group.button_pressed = true
		select_group(g)
		return true
	if group.pressed.is_connected(select_group.bind(GROUPNAME_ALLTILES)): group.pressed.disconnect(select_group.bind(GROUPNAME_ALLTILES))
	group.pressed.connect(select_group.bind(g))
	_group_tree.add_child(group)
	return false

func select_group(group:String):
	curr_group = group
	for n in _group_tree.get_children():
		if n.name == group:
			n.button_pressed = true
			continue
		n.button_pressed = false
	tilemap.dock_group_selected = group
	_fill_list_view(_group_tree.get_node(group).get_meta("TILES",tilemap.EMPTY_TILE_ARRAY))

func _fill_list_view(tilelist:Array=tileset.get_meta("TileList")):
	$"%ListView".clear()
	var tilelist_indexes:Dictionary; var index:int=0; var list_index:int; var unique_id:String
	for id in tilelist:
		if not id is Vector3i: tilelist_indexes[index] = id
		else:
			id = BTM.TILEID.new(id.z, Vector2i(id.x,id.y))
			tilelist_indexes[index] = id
		index += 1
		$"%ListView".add_item("", tileset.get_source(id.source).texture)
		list_index = $"%ListView".get_item_count()-1
		$"%ListView".set_item_icon_region(list_index,tileset.get_source(id.source).get_tile_texture_region(id.coords))
		$"%ListView".set_item_tooltip_enabled(list_index,true)
		unique_id = str(tilemap._get_id_in_map(id.v))
		$"%ListView".set_item_tooltip(list_index, unique_id)
		if unique_id == tilemap.dock_tile_selected:
			$"%ListView".select(index-1)
			_on_ListView_item_selected(index-1)
	if not $"%ListView".is_anything_selected(): $"%ListView".select(0)
	tileset.set_meta("TileListIndexes", tilelist_indexes)

func _on_sub_tab_tab_changed(tab):
	_fill_subview()

func _fill_subtile_view():
	pass

func _fill_alttile_view():
	var current_tile:BTM.TILEID = tilemap.current_tile
	var region:Rect2; var alt:TileData;
	for a in 8:
		alt = tileset.get_source(current_tile.source).get_tile_data(current_tile.coords, a)
		$"%Subtile".add_item("", tileset.get_source(current_tile.source).texture)
		region = tileset.get_source(current_tile.source).get_tile_texture_region(current_tile.coords)
		if alt.flip_h: region.size.x = -region.size.x
		if alt.flip_v: region.size.y = -region.size.y
		if alt.transpose: $"%Subtile".set_item_icon_transposed(a, true)
		$"%Subtile".set_item_icon_region(a,region)

func _fill_subview():
	$"%Subtile".clear()
	match $"%SubTab".current_tab:
		0: _fill_subtile_view()
		1: _fill_alttile_view()

func get_group_item(n:String, tree:Tree):
	var children:Array[TreeItem] = tree.get_root().get_children()
	var child:TreeItem
	while not children.is_empty():
		child = children.pop_front()
		if child.get_text(0) == n: return child
		children.append_array(child.get_children())

func _clear_list_view():
	$"%ListView".clear()

func _clear_group_view():
	for n in _group_tree.get_children():
		if n.name in [GROUPNAME_ALLTILES,GROUPNAME_NOGROUP]: continue
		n.queue_free()
	group_list.clear()
	_clear_list_view()

func _on_delete_group_pressed():
	if curr_group in [GROUPNAME_ALLTILES, GROUPNAME_NOGROUP]:
		push_warning("Not allowed to remove the group "+curr_group)
		return
	
	var list = tilemap.get_tiles_in_group(curr_group).duplicate()
	for id in list:
		tilemap.remove_group_from_tile(id, curr_group)
		tilemap.remove_tile_from_group(id, curr_group)
	
	_group_tree.get_node(curr_group).queue_free()
#	_clear_list_view()
	select_group(GROUPNAME_ALLTILES)
	update_no_group()

func _check_remove_fav_group(curr:String):
	if not curr in fav_groups: return
	if curr in [GROUPNAME_ALLTILES, GROUPNAME_NOGROUP]:
		push_warning("Not allowed to unfavorite the group "+curr)
		return
	fav_groups.erase(curr)

func _on_fav_group_pressed():
	if curr_group in hidden_groups:
		push_warning("Can't favorite the group "+curr_group+" because it is a hidden group. Unhide it first.")
		return
	if not curr_group in fav_groups: fav_groups.append(curr_group)
	else: _check_remove_fav_group(curr_group)

func _on_dupli_group_pressed():
	var new_name:String = curr_group+"2"
	var new_content:Array[BTM.TILEID]
	
	while tilemap.group_exists(new_name): new_name += "2"
	
	if curr_group == GROUPNAME_ALLTILES: new_content = tileset.get_meta("TileList")
	elif curr_group == GROUPNAME_NOGROUP: new_content = get_tiles_without_groups()
	else: new_content = tileset.get_meta("groups_by_groups", {})[curr_group]
	for id in new_content:
		tilemap.add_tile_to_group(id.v, new_name)
		tilemap.add_group_to_tile(id.v, new_name)
	curr_group = new_name
	create_group(new_name, new_content)
	select_group(new_name)
	update_no_group()
#	_fill()

func _on_hide_group_pressed():
	_check_remove_fav_group(curr_group)
	if curr_group in hidden_groups: hidden_groups.erase(curr_group)
	elif curr_group in [GROUPNAME_ALLTILES, GROUPNAME_NOGROUP]:
		push_warning("Not allowed to hide the group "+curr_group)
	else:
		hidden_groups.append(curr_group)
		_group_tree.get_node(curr_group).hide()
	select_group(GROUPNAME_ALLTILES)

func _on_tileset_changed(new_tileset: TileSet):
	print("tileset")
	_fill()

func _on_ListView_item_selected(index: int) -> void:
	if index != selected_right:
		tilemap.current_tile = tileset.get_meta("TileListIndexes", {}).get(index, BTM.TILEID.new())
		selected_left = index
		tilemap.dock_tile_selected = $"%ListView".get_item_tooltip(index)
	for item in $"%ListView".get_selected_items():
		if item == selected_left or item == selected_right: continue
		$"%ListView".deselect(item)
	_fill_subview()
	# TODO : display subtile view
#	init_tilecell()

# Cell Manager
func init_tilecell():
	var populate_array = {"tilemap":tilemap.curr_tilemap,"tile_id": tilemap.current_tile}#,"tileset":tileset}
	$"%TileCells".populate_infos(populate_array)


#enum REPLACE_PARAM {Auto, SelectionOnly, Global}
#enum SELECT {SelectionOnly, WholeLayer, Global, SelectionAllLayers}
func _on_EraseAll_pressed() -> void:
	tilemap.global_replacing(tilemap.ALL_TILES_V, tilemap.ERASE_TILE_V, $"%SelectionType".get_selected_id(), \
							[tilemap.current_layer,tilemap.ALL_LAYERS][$"%SelectionLayer".get_selected_id()])
	
#	match $"%Selections".get_selected_id():
#		SELECT.SelectionOnly: tilemap.global_replacing(tilemap.ALL_TILES_V, tilemap.ERASE_TILE_V, REPLACE_PARAM.SelectionOnly)
#		SELECT.WholeLayer: tilemap.global_replacing(tilemap.ALL_TILES_V, tilemap.ERASE_TILE_V, REPLACE_PARAM.Global)
#		SELECT.Global: tilemap.global_replacing(tilemap.ALL_TILES_V, tilemap.ERASE_TILE_V, REPLACE_PARAM.Global, tilemap.ALL_LAYERS)
#		SELECT.SelectionAllLayers: tilemap.global_replacing(tilemap.ALL_TILES_V, tilemap.ERASE_TILE_V, REPLACE_PARAM.SelectionOnly, tilemap.ALL_LAYERS)
	$"%SelectionType".select(0)
	$"%Selectionlayer".select(0)

func _on_select_all_pressed():
	var tile:BTM.TILEID = [tilemap.NO_TILE_ID,tilemap.current_tile][int($"%SelectTile".button_pressed)]
	if $"%SelectionType".get_selected_id() == 0: return
	tilemap.select_all_cells([tilemap.current_layer,tilemap.ALL_LAYERS][$"%SelectionLayer".get_selected_id()], tile, bool($"%SelectionType".get_selected_id()))
	
#	match $"%Selections".get_selected_id():
#		SELECT.SelectionOnly: return
#		SELECT.WholeLayer: tilemap.select_all_cells(tilemap.current_layer, tile)
#		SELECT.Global: tilemap.select_all_cells(tilemap.ALL_LAYERS, tile)
#		SELECT.SelectionAllLayers: tilemap.select_all_cells(tilemap.ALL_LAYERS, tile, true)
	$"%SelectionType".select(0)
	$"%Selectionlayer".select(0)

func _on_TilePalette_resized() -> void:
	$"%TileCells".get_node("ScrollContainer").custom_minimum_size.y = max(175, size.y-100)

func get_tilecell():
	return $"%TileCells"

func _on_Search_text_changed(new_text: String) -> void:
	for g in _group_tree.get_children():
		if g.text in hidden_groups:
			g.visible = (new_text[0] == GROUPCHAR_HIDDEN and new_text.is_subsequence_ofn(GROUPCHAR_HIDDEN+g.text))
		else: g.visible = new_text.is_subsequence_ofn(g.text)

enum TAB {TileMap, TileSet, Terrains, Patterns}
func _on_tab_changed(tab):
	if tab == TAB.TileSet:
		_tab_tileset.emit()
		tab = TAB.TileMap
	$TileMap.visible = (tab == TAB.TileMap)
	$BetterTerrain.visible = (tab == TAB.Terrains)
	$PatternEditor.visible = (tab == TAB.Patterns)
#	$TileSet.visible = (tab == TAB.TileSet)
	$"%Tabs_TM".current_tab = tab
#	$BetterTerrain.get_node("%Tabs_BT").current_tab = tab
#	$PatternEditor.get_node("%Tabs_P").current_tab = tab
	
#	for t in [$"%Tabs_TM",$BetterTerrain.get_node("%Tabs_BT"), $PatternEditor.get_node("%Tabs_P")]:
	for c in $"%Tabs_TM".get_children():
		c.hide()
	
	for node in $BottledTools.get_children():
		if node in [$"%ToggleFav",$"%Search Group",$"%MoveTileLeft",$"%MoveTileRight",$"%Clean",$"%ClearInvalid",$"%EraseAll"]:
			node.visible = $TileMap.visible
		elif node in [$"%PaintType",$"%PaintTerrain",$"%BitmaskCopy",$"%BitmaskPaste", $"%AutoAlt",$"%CreateAlt",
						$"%SelectAlt",$"%DeleteAlt"]: node.visible = $BetterTerrain.visible
#		elif node in [$"%SelectionType",$"%SelectionLayer",$"%SelectAll",$"%SelectTile"]: node.visible = 
		elif node.name == "RigthTools":
			for subtool in node.get_children(): if node in [$"%Cursors",$"%All"]: node.visible = $TileMap.visible
		elif node in [$"%SwitchEditors"]: node.visible = $PatternEditor.visible

func _on_tile_size_value_changed(value):
	$"%ListView".fixed_icon_size = Vector2(value,value)

func _on_toggle_sub_pressed():
	can_show_subview = $"%ToggleSub".button_pressed

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

func _on_lock_dock_pressed():
	lock_dock = $"%LockDock".button_pressed

func _on_random_tile_pressed():
	tilemap.use_tile_random = $"%RandomTile".button_pressed

func _on_random_sub_pressed():
	match $"%SubTab".current_tab:
		0: pass
		1: tilemap.use_alt_random = $"%RandomSub".button_pressed

func _on_subtile_item_selected(index):
	match $"%SubTab".current_tab:
		0: pass
		1: BTM.current_alt = index

func pick_tile(tile:BTM.TILEID):
	if $"%Tabs_TM".current_tab == 2:
		pick_tile_id(tile)
		return
	var list = tileset.get_meta("TileListIndexes", {})
	for t in list.keys():
		if tile.isEqual(list[t]):
			_on_ListView_item_selected(t)
			return
	select_group(GROUPNAME_ALLTILES)
	tileset.get_meta("TileListIndexes", {})
	for t in list.keys():
		if tile.isEqual(list[t]):
			_on_ListView_item_selected(t)
			return

func pick_tile_id(tile:BTM.TILEID):
	DisplayServer.clipboard_set(tilemap._get_id_in_map(tile.v))
