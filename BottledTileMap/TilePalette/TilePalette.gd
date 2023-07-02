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
const BG_COLOR_RIGHT_TILE:Color = Color.DARK_ORANGE
const BG_COLOR_SELECTED:Color = Color.YELLOW_GREEN
const BG_COLOR_ICON:Color = Color.REBECCA_PURPLE

const GROUPCHAR_HIDDEN:String = "*"
const GROUPCHAR_TILEMAP:String = "$"
const GROUPCHAR_TILESET:String = "€"
const GROUPCHAR_TEXTURE:String = "£"
const GROUPCHAR_CUSTOM:String = "#"
const GROUPNAME_ALLTILES:String = "ALL TILES"
const GROUPNAME_NOGROUP:String = "NO GROUP"

@onready var _panel:ScrollContainer = $"%Panel"
@onready var _group_tree = $"%GroupTree"
@onready var _preview:ScrollContainer = $"%Preview"
@onready var _preview_list:VBoxContainer = $"%PreviewList"

var bottom_button:Button
var _tile_map_editor: Control
var tilemap:BottledTileMap
var tileset:TileSet : set = _set_tileset
var tile_event_panel:ScrollContainer
var curr_preview_type:String

var tile_list:Dictionary
var group_list:Dictionary
var fav_groups:Array[String]
var hidden_groups:Array[String]
var curr_group:String

var can_multi_check:bool = false
var can_show_subview:bool = true

var selected_left:int = -1
var selected_right:int = -1
var selected_tile_items:Array[int] = []
var lock_dock:bool = false


func _set_tileset(value):
	if value == null or tileset == value:
		return
	tileset = value
#	if tileset: _fill()

func set_lists(tile_list: ItemList, subtile_list: ItemList):
	pass

func set_tools(tile_map_editor: Control, interface_display_scale: float = 1):
	_tile_map_editor = tile_map_editor
	
# Bottled TileMap
func go_to_tile(inc:int):
	var max_tiles = 0

# Bottled TileMap
func count_tiles_in_texture():
	pass

func trigger_preview(type:String):
#	if curr_preview_type in ["", type] and not show_preview_list():
#		curr_preview_type = ""
#		return
	match type:
		"Cursors": cursor_list()
		"DM": show_drawing_modes()
		"Brush": brush_preview()
	show_side_panel()
#	curr_preview_type = type

func show_drawing_modes():
	var meta:Dictionary = tileset.get_meta("Terrains_data")
	if not meta.has(curr_group) or not meta[curr_group].has("drawing_modes"): return
	
	clear_preview_list($%DrawingModes.get_node("PreviewList"))
	var mode_button:CheckBox
	for mode in meta[curr_group]["drawing_modes"]:
		mode_button = $%DrawingModes.get_node("PreviewList/Template").duplicate()
		mode_button.text = mode
		mode_button.toggled.connect(select_drawing_mode.bind(mode))
	
	$%DrawingModes.visible = !$%DrawingModes.visible
	show_side_panel()

func show_side_panel():
	$%SideTools.visible = (_preview.visible or $%DrawingModes.visible)
	return $%SideTools.visible

func select_drawing_mode(pressed:bool, id:String):
	if pressed:
		if id in BTM.drawing_modes: return
		BTM.drawing_modes.append(id)
	else: BTM.drawing_modes.erase(id)

func brush_preview():
	_preview.draw_type = _preview.DrawType.Brush
	_preview.brush_pos = tilemap.get_tiles_with_brush(Vector2.ZERO)
	_preview.queue_redraw()

func cursor_list():
	_preview.visible = !_preview.visible
	clear_preview_list()
	var new_cursor:CheckBox; var value:Vector2;
	for c in tilemap.multi_cursor_list.size():
		value = tilemap.multi_cursor_list[c]
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
	
	
func clear_preview_list(list=_preview_list):
	for n in list.get_children():
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
	$PatternEditor.dock = self
	$"%GroupTree".get_child(0).connect("pressed", select_group.bind(GROUPNAME_ALLTILES))
	$"%GroupTree".get_child(1).connect("pressed", select_group.bind(GROUPNAME_NOGROUP))
	$"%TileRuling".get_node("%RuleView").can_run = true

func assign_tilemap(selected_node:BottledTileMap):
	active = true
	BTM.tilemap = selected_node
	BTM.palette = self
	tilemap = selected_node
	tileset = selected_node.tile_set
	$"%TileRuling".p = self
	$"%TileRuling".get_node("%RuleView").data = $"%TileRuling"
	$"%TileRuling".get_node("%RuleView").tileset = tileset
	_fill()

func _process(delta):
	if not active: return
	if not bottom_button.button_pressed: return
	size = get_parent().size





func _fill():
	_clear_group_view()
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
	
	var tilelist:Array[Dictionary]
	for g in groups.keys():
		tilelist = tilemap.EMPTY_TILE_ARRAY as Array
		create_group(g, groups.get(g, tilelist))
	
	if curr_group == "":
		$"%ALL TILES".button_pressed = true
		select_group(GROUPNAME_ALLTILES)

func update_no_group():
	$"%NO GROUP".set_meta("TILES", get_tiles_without_groups())

func get_tiles_without_groups():
	var no_group:Array[Dictionary]
	for id in tileset.get_meta("TileList"):
		if tilemap.tile_has_any_group(id.v): continue
		no_group.append(id)
	return no_group

func _make_group_icon(index:int):
	var atlas:AtlasTexture = AtlasTexture.new()
	atlas.atlas = $%ListView.get_item_icon(index)
	atlas.region = $%ListView.get_item_icon_region(index)
	tileset.get_meta("groups_icons")[curr_group] = atlas
	_update_group_icon()

func _update_group_icon():
	_group_tree.get_node(curr_group).icon = tileset.get_meta("groups_icons")[curr_group]

func create_group(g:String, group_content:Array, tree=_group_tree):
	var group:Button = _group_tree.get_child(0).duplicate()
	group.text = g
	group.name = g
	print(tilemap, tileset, tileset.get_meta_list())
	group.icon = tileset.get_meta("groups_icons").get(g, get_theme_icon("VisualShaderNodeTexture2DArrayUniform", "EditorIcons"))
	group.set_meta("TILES", group_content)
	group_list[g] = group
	if group.pressed.is_connected(select_group.bind(GROUPNAME_ALLTILES)): group.pressed.disconnect(select_group.bind(GROUPNAME_ALLTILES))
	group.pressed.connect(select_group.bind(g))
	_group_tree.add_child(group, true)
	group.name = group.text
	
	if g == tilemap.dock_group_selected:
		group.button_pressed = true
		select_group(g)
		return true
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
			id = BTM.new_TILEID(id.z, Vector2i(id.x,id.y))
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

func _fill_alttile_view():
	var current_tile:Dictionary = tilemap.current_tile
	if current_tile.source < 0: return
	var region:Rect2; var alt:TileData;
	for a in tileset.get_source(current_tile.source).get_alternative_tiles_count(current_tile.coords):
#		if not tileset.get_source(current_tile.source).has_alternative_tile(current_tile.coords, a): break
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
		0: _fill_alttile_view()#_fill_subtile_view()
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
		n.name = "deleted "+n.name
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
	var new_content:Array[Dictionary]
	
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
	_fill()

#enum REPLACE_PARAM {Auto, SelectionOnly, Global}
#enum SELECT {SelectionOnly, WholeLayer, Global, SelectionAllLayers}
func _on_EraseAll_pressed() -> void:
	tilemap.global_replacing(tilemap.ALL_TILES_V, tilemap.ERASE_TILE_V, $"%SelectionType".get_selected_id(), \
							[tilemap.current_layer,tilemap.ALL_LAYERS][$"%SelectionLayer".get_selected_id()])
	$"%SelectionType".select(0)
	$"%Selectionlayer".select(0)

func _on_select_all_pressed():
	var tile:Dictionary = [tilemap.NO_TILE_ID,tilemap.current_tile][int($"%SelectTile".button_pressed)]
	if $"%SelectionType".get_selected_id() == 0: return
	tilemap.select_all_cells([tilemap.current_layer,tilemap.ALL_LAYERS][$"%SelectionLayer".get_selected_id()], tile, bool($"%SelectionType".get_selected_id()))
	$"%SelectionType".select(0)
	$"%Selectionlayer".select(0)

func _on_Search_text_changed(new_text: String) -> void:
	for g in _group_tree.get_children():
		if g.text in hidden_groups:
			g.visible = (new_text[0] == GROUPCHAR_HIDDEN and new_text.is_subsequence_ofn(GROUPCHAR_HIDDEN+g.text))
		else: g.visible = new_text.is_subsequence_ofn(g.text)

enum TAB {TileMap, TileSet, Patterns}
func _on_tab_changed(tab):
	if tab == TAB.TileSet:
		_tab_tileset.emit()
		tab = TAB.TileMap
	$TileMap.visible = (tab == TAB.TileMap)
	$PatternEditor.visible = (tab == TAB.Patterns)
	$"%Tabs_TM".current_tab = tab
	
	for c in $"%Tabs_TM".get_children():
		c.hide()
	
	for node in $BottledTools.get_children():
		if node in [$"%ToggleFav",$"%Search Group",$"%ClearInvalid",$"%EraseAll"]:
			node.visible = (tab == TAB.TileMap)
		elif node in [$"%SwitchEditors", $"%TabSeparator"]: node.visible = (tab == TAB.Patterns)
		
		if node.name == "RigthTools":
			for subtool in node.get_children():
				if node in [$"%Cursors",$"%All"]: node.visible = (tab == TAB.TileMap)

func _on_tile_size_value_changed(value):
	$"%ListView".fixed_icon_size = Vector2(value,value)

func _on_toggle_sub_pressed():
	can_show_subview = $"%ToggleSub".button_pressed

func _on_clear_invalid_pressed():
	tilemap.fix_invalid_tiles()

func _on_list_view_empty_clicked(at_position, mouse_button_index):
	if mouse_button_index != MOUSE_BUTTON_RIGHT: return
	$%ListView.set_item_custom_bg_color(selected_right, Color.TRANSPARENT)
	selected_right = -1
	tilemap.right_click_tile = tilemap.ERASE_TILE_ID

func _on_list_view_item_clicked(index, at_position, mouse_button_index):
	if mouse_button_index == MOUSE_BUTTON_RIGHT:
		$%ListView.set_item_custom_bg_color(selected_right, Color.TRANSPARENT)
		selected_right = index
		tilemap.right_click_tile = tileset.get_meta("TileListIndexes", {}).get(index, tilemap.ERASE_TILE_ID)
		$%ListView.set_item_custom_bg_color(index, BG_COLOR_RIGHT_TILE)
		$"%ListView".deselect(index)
		$"%ListView".select(selected_left)
	elif mouse_button_index == MOUSE_BUTTON_LEFT and Input.is_key_pressed(KEY_CTRL):
		if $%ListView.get_item_custom_bg_color(index) == BG_COLOR_SELECTED:
			$%ListView.set_item_custom_bg_color(index, Color.TRANSPARENT)
			selected_tile_items.erase(int($%ListView.get_item_tooltip(index)))
		else:
			$%ListView.set_item_custom_bg_color(index, BG_COLOR_SELECTED)
			selected_tile_items.append(int($%ListView.get_item_tooltip(index)))
			print(int($%ListView.get_item_tooltip(index)), selected_tile_items)
	elif mouse_button_index == MOUSE_BUTTON_LEFT and Input.is_key_pressed(KEY_SHIFT):
		if $%ListView.get_item_custom_bg_color(index) == BG_COLOR_ICON:
			$%ListView.set_item_custom_bg_color(index, Color.TRANSPARENT)
			selected_tile_items.erase(int($%ListView.get_item_tooltip(index)))
		else:
			$%ListView.set_item_custom_bg_color(index, BG_COLOR_ICON)
			selected_tile_items.append(int($%ListView.get_item_tooltip(index)))

func _on_ListView_item_selected(index: int) -> void:
	if Input.is_key_pressed(KEY_CTRL):
		$"%ListView".call_deferred("deselect", index)
		$"%ListView".call_deferred("select", selected_left)
		return
	if index != selected_right:
		tilemap.current_tile = tileset.get_meta("TileListIndexes", {}).get(index, BTM.new_TILEID())
		selected_left = index
		tilemap.dock_tile_selected = $"%ListView".get_item_tooltip(index)
	for item in $"%ListView".get_selected_items():
		if item == selected_left or item == selected_right: continue
		$"%ListView".deselect(item)
	_fill_subview()
	# TODO : display subtile view

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

func pick_tile(tile:Dictionary):
	if $"%Tabs_TM".current_tab == 2:
		pick_tile_id(tile)
		return
	var list = tileset.get_meta("TileListIndexes", {})
	for t in list.keys():
		if BTM.isEqual(tile, list[t]):
			_on_ListView_item_selected(t)
			return
	select_group(GROUPNAME_ALLTILES)
	tileset.get_meta("TileListIndexes", {})
	for t in list.keys():
		if BTM.isEqual(tile, list[t]):
			_on_ListView_item_selected(t)
			return

func pick_tile_id(tile:Dictionary):
	DisplayServer.clipboard_set(tilemap._get_id_in_map(tile.v))

func _on_open_rule_editor_toggled(button_pressed):
	$TileMap/Spacing.visible = button_pressed
	$"%TileRuling".visible = button_pressed
	if button_pressed: $"%TileRuling".init_group(curr_group)
	else:  $"%TileRuling".remove_empty_terrains()

func _on_solve_terrains_pressed():
	for cell in tilemap.get_selected_cells():
		BTM.update_terrain_cell(cell, BTM.l, curr_group)

func sync_rule_settings():
	$"%TileRuling".sync_settings()




# tileset


func show_tile_event(id:String):
	var tile = _parse_tileset_id(id)
	
	if tileset.get_meta("TILE_EVENTS").has(tile):
		tile_event_panel.event_list = tileset.get_meta("TILE_EVENTS")[tile]
	else: tile_event_panel.event_list = tile_event_panel.get_empty_list()
	tile_event_panel.current_tile = tile

func _parse_tileset_id(id:String):
	var units = id.split(",")
	var coordx = units[1].split("(")
	var coordy = units[1].split(")")
	return Vector3i(int(coordx[1]),int(coordy[0]),int(units[0]))

func _on_tileset_any_button(label:Label, button:Button):
	match button.name:
		"DupliTile": duplicate_tile(_parse_tileset_id(label.text))
		"CreateAlt": BTM.create_alt_tiles(BTM.new_TILEID(_parse_tileset_id(label.text)))
		"DeleteAlt": BTM.erase_alt_tiles(BTM.new_TILEID(_parse_tileset_id(label.text)))
	

func duplicate_tile(id:String):
	pass


func _on_add_to_group_pressed():
	var vect:Vector3i
	for t in selected_tile_items:
		if t == -1: continue
		vect = tilemap._get_vect_in_map(t)
		tilemap.add_group_to_tile(vect, $%GroupToAdd.text)
		tilemap.add_tile_to_group(vect, $%GroupToAdd.text)

func move_tile_index(offset:int):
	var group:Array[Vector3i] = tileset.get_meta("groups_by_groups", {}).get(curr_group, [])
	var tile:Vector3i = tilemap._get_vect_in_map(int($%ListView.get_item_tooltip($%ListView.get_selected_items()[-1])))
	var index:int = group.find(tile)
	group.remove_at(index)
	group.insert(index+offset, tile)
	
func _on_move_tile_left_pressed():
	move_tile_index(-1)

func _on_move_tile_right_pressed():
	move_tile_index(1)
