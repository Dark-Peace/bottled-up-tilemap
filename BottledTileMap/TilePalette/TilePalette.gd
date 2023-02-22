@tool
extends Control

@export var single_tile_border_color: Color = Color("fce844")
@export var atlas_tile_border_color: Color = Color("c9cfd4")
@export var auto_tile_border_color: Color = Color("4490fc")
@export var subtile_border_color: Color = Color("4cb299")
@export var absent_subtile_border_color: Color = Color(1, 0, 0)
@export var absent_subtile_fill_color: Color = Color(1, 0, 0, 0.7)
@export var tile_selection_color: Color = Color(0, 0, 1, 0.7)
@export var tile_hint_label_font_color: Color = Color(0, 0, 0)
var _tile_list: ItemList
var _subtile_list: ItemList
var _disable_autotile_check_box: CheckBox
var _enable_priority_check_box: CheckBox
var _rotate_left_button: Button
var _rotate_right_button: Button
var _flip_horizontally_button: Button
var _flip_vertically_button: Button
var _clear_transform_button: Button
@onready var _texture_item_list: ItemList = $HSplitContainer/TextureListVBoxContainer/TextureItemList
@onready var _sprite = $HSplitContainer/TextureVBoxContainer/Main/HSplitContainer/Panel/ScalingHelper/Sprite2D
@onready var _sprite_border = $HSplitContainer/TextureVBoxContainer/Main/HSplitContainer/Panel/ScalingHelper/Sprite2D/SpriteBorder
@onready var _scaling_helper = $HSplitContainer/TextureVBoxContainer/Main/HSplitContainer/Panel/ScalingHelper
@onready var _selection_rect: ColorRect = $HSplitContainer/TextureVBoxContainer/Main/HSplitContainer/Panel/ScalingHelper/Sprite2D/SelectionRect
@onready var _tools_container: HBoxContainer = $HSplitContainer/TextureVBoxContainer/HBoxContainer/ToolsHBoxContainer
@onready var _panel: Panel = $HSplitContainer/TextureVBoxContainer/Main/HSplitContainer/Panel
@onready var _texture_list_scaler: HSlider = $HSplitContainer/TextureListVBoxContainer/ScaleHSlider
@onready var _texture_scaler: HSlider = $HSplitContainer/TextureVBoxContainer/HBoxContainer/ScalingHBoxContainer/ScaleHSlider
@onready var _transform_indicator: Button = $HSplitContainer/TextureVBoxContainer/HBoxContainer/ToolsHBoxContainer/TransformationIndicatorPlaceholderMarginContainer/TransformationIndicatorPlaceholderToolButton
@onready var _reset_scaling_button: Button = $HSplitContainer/TextureVBoxContainer/HBoxContainer/ScalingHBoxContainer/ResetScalingToolButton
@onready var _show_tile_hints_check_box: CheckBox = $HSplitContainer/TextureVBoxContainer/HBoxContainer/ScalingHBoxContainer/ShowTileHintsCheckBox
@onready var _bg_holder: Control = $HSplitContainer/TextureVBoxContainer/Main/HSplitContainer/Panel/ScalingHelper/Sprite2D/BgHolder
var _dragging: bool = false
var _editor_item_indices_by_tile_ids = {}
var _previous_selected_texture_index: int = -1
var _mouse_entered = false
var _last_selected_tile = -1
var _last_selected_subtile = -1
var _tile_map_editor: Control
var _subtile_to_select: int = -1

# Bottled TileMap
var current_tile: int = -1
var max_tiles = 0
var tilemap:TileMap
var can_multi_check = false
var curr_preview_type:String
var can_see_tile_hint = false
var can_select = false
enum VIEW {Tex, Group, List}
var current_view = VIEW.Tex

var tileset:TileSet : set = _set_tileset
func _set_tileset(value):
	if tileset == value:
		return
	_clear()
	tileset = value
	if tileset: _fill()

func set_lists(tile_list: ItemList, subtile_list: ItemList):
	_tile_list = tile_list
	_subtile_list = subtile_list

func set_tools(
	tile_map_editor: Control,
	disable_autotile_check_box: CheckBox,
	enable_priority_check_box: CheckBox,
	rotate_left_button: Button,
	rotate_right_button: Button,
	flip_horizontally_button: Button,
	flip_vertically_button: Button,
	clear_transform_button: Button,
	interface_display_scale: float = 1):
	
	_tile_map_editor = tile_map_editor
	
	_disable_autotile_check_box = disable_autotile_check_box
	_enable_priority_check_box = enable_priority_check_box
	_rotate_left_button = rotate_left_button
	_rotate_right_button = rotate_right_button
	_flip_horizontally_button = flip_horizontally_button
	_flip_vertically_button = flip_vertically_button
	_clear_transform_button = clear_transform_button
	
	var tools = [
		_rotate_left_button,
		_rotate_right_button,
		_flip_horizontally_button,
		_flip_vertically_button,
		_clear_transform_button,
		_disable_autotile_check_box,
		_enable_priority_check_box
	]
	for t in tools:
		t.get_parent().remove_child(t)
		_tools_container.add_child(t)
	
	_disable_autotile_check_box.connect("toggled",Callable(self,"_on_disable_autotile_check_box_toggled"))
	_enable_priority_check_box.connect("toggled",Callable(self,"_on_enable_priority_check_box_toggled"))
	
	_on_clear_transform()
	_tile_map_editor._clear_transform()
	
	_rotate_left_button.connect("pressed",Callable(self,"_on_rotate_counterclockwise"))
	_rotate_right_button.connect("pressed",Callable(self,"_on_rotate_clockwise"))
	_flip_horizontally_button.connect("pressed",Callable(self,"_on_flip_horizontally"))
	_flip_vertically_button.connect("pressed",Callable(self,"_on_flip_vertically"))
	_clear_transform_button.connect("pressed",Callable(self,"_on_clear_transform"))
	
	_reset_scaling_button.icon = _resize_button_texture(_reset_scaling_button.icon, interface_display_scale / 4)
	_transform_indicator.icon = _resize_button_texture(_transform_indicator.icon, interface_display_scale / 4)
	
	# Bottled TileMap
	var next_button = $HSplitContainer/TextureVBoxContainer/HBoxContainer/ScalingHBoxContainer/NextTile
	var previous_button = $HSplitContainer/TextureVBoxContainer/HBoxContainer/ScalingHBoxContainer/PreviousTile
	next_button.icon = theme.theme.get_icon('MoveRight', 'EditorIcons')
	previous_button.icon = theme.get_icon('MoveLeft', 'EditorIcons')
	next_button.connect("pressed",Callable(self,"go_to_tile").bind(1))
	previous_button.connect("pressed",Callable(self,"go_to_tile").bind(-1))
	$HSplitContainer/TextureVBoxContainer/BottledTools/Pattern.icon = theme.get_icon('PackedDataContainer', 'EditorIcons')
	$HSplitContainer/TextureVBoxContainer/BottledTools/Cursors.icon = theme.get_icon('ToolSelect', 'EditorIcons')
	$HSplitContainer/TextureVBoxContainer/BottledTools/All.icon = theme.get_icon('ListSelect', 'EditorIcons')
	$HSplitContainer/TextureVBoxContainer/BottledTools/Maps.icon = theme.get_icon('TileSet', 'EditorIcons')
	$HSplitContainer/TextureVBoxContainer/BottledTools/MultiSelect.icon = theme.get_icon('ThemeSelectAll', 'EditorIcons')
	$HSplitContainer/TextureVBoxContainer/BottledTools/CellManager.icon = theme.get_icon('ProxyTexture', 'EditorIcons')
	$HSplitContainer/TextureVBoxContainer/BottledTools/TurnIntoPattern.icon = theme.get_icon('ToolAddNode', 'EditorIcons')
	$HSplitContainer/TextureVBoxContainer/BottledTools/Brushes.icon = theme.get_icon('EditKey', 'EditorIcons')
	$HSplitContainer/TextureVBoxContainer/BottledTools/Scan.icon = theme.get_icon('AssetLib', 'EditorIcons')
	$HSplitContainer/TextureVBoxContainer/BottledTools/HBoxContainer/TileList.icon = theme.get_icon('Filesystem', 'EditorIcons')
	$HSplitContainer/TextureVBoxContainer/BottledTools/HBoxContainer/TmHints.icon = theme.get_icon('Search', 'EditorIcons')
	$HSplitContainer/TextureVBoxContainer/BottledTools/HBoxContainer/Old.icon = theme.get_icon('TileMap', 'EditorIcons')
	$"%Views".icon = theme.get_icon('GuiVisibilityVisible', 'EditorIcons')
	$HSplitContainer/TextureVBoxContainer/BottledTools/HBoxContainer/Selection.icon = theme.get_icon('RegionEdit', 'EditorIcons')
	$HSplitContainer/TextureVBoxContainer/BottledTools/HBoxContainer/EraseAll.icon = theme.get_icon('ImportFail', 'EditorIcons')
	$HSplitContainer/TextureVBoxContainer/Main/HSplitContainer/TileCells/HBoxContainer4/Dupli.icon = theme.get_icon("Duplicate","EditorIcons")
	$HSplitContainer/TextureVBoxContainer/Main/HSplitContainer/TileCells/HBoxContainer4/Erase.icon = theme.get_icon("ImportFail","EditorIcons")
	$HSplitContainer/TextureVBoxContainer/Main/HSplitContainer/TileCells/ScrollContainer/VBoxContainer/HBoxContainer/Right/HBoxContainer/SaveGroups.icon = theme.get_icon("Save","EditorIcons")
	
	
# Bottled TileMap
func go_to_tile(inc:int):
	match current_view:
		VIEW.Tex:
			max_tiles = count_tiles_in_texture()
			var new_tile = current_tile+inc
			if new_tile < 0: new_tile = max_tiles
			if new_tile > max_tiles: new_tile = 0
			while not new_tile in tileset.get_tiles_ids():
				current_tile+inc
			for child in _sprite_border.get_children():
				if child is ReferenceRect and child.has_meta("tile_id") and child.get_meta("tile_id") == new_tile:
					_on_pressed_tile_button(child)
		VIEW.List:
			max_tiles = $"%ListView".get_item_count()
			var new_tile = current_tile+inc
			if new_tile < 0: new_tile = max_tiles-1
			if new_tile >= max_tiles: new_tile = 0
			current_tile = new_tile
			_on_ListView_item_selected(current_tile%max_tiles)
			$"%ListView".select(current_tile)
		VIEW.Group:
			pass

# Bottled TileMap
func count_tiles_in_texture():
	var curr_tile_counted = -1
	for child in _sprite_border.get_children():
		if child is ReferenceRect and child.has_meta("tile_id") and child.get_meta("tile_id") != curr_tile_counted:
			curr_tile_counted = child.get_meta("tile_id")
	return curr_tile_counted

func hide_tile_list():
	$HSplitContainer/TextureListVBoxContainer.visible = $HSplitContainer/TextureVBoxContainer/BottledTools/HBoxContainer/TileList.pressed

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
	$HSplitContainer/TextureVBoxContainer/Main/Preview.visible = !$HSplitContainer/TextureVBoxContainer/Main/Preview.visible
	return $HSplitContainer/TextureVBoxContainer/Main/Preview.visible

func toggle_cell_manager():
	$HSplitContainer/TextureVBoxContainer/Main/HSplitContainer/TileCells.visible = $HSplitContainer/TextureVBoxContainer/BottledTools/CellManager.pressed

func brush_preview():
	var preview = $HSplitContainer/TextureVBoxContainer/Main/Preview
	preview.draw_type = preview.DrawType.Brush
	preview.brush_pos = tilemap.get_tiles_with_brush(Vector2.ZERO)
	preview.update()

func pattern_list():
	var preview = $HSplitContainer/TextureVBoxContainer/Main/Preview
	preview.draw_type = preview.DrawType.Pattern
	preview.tileset = tileset
	preview.pattern_list = tilemap.pattern_list
	preview.update()
	
	var new_pattern:CheckBox; var value:Array;
	for c in tilemap.pattern_list.size():
		value = tilemap.pattern_list[c]
		if value.is_empty(): continue
		new_pattern = $HSplitContainer/TextureVBoxContainer/Main/Preview/List/Template.duplicate()
		new_pattern.visible = true
		new_pattern.text = String(c)
		new_pattern.set_meta("id", c)
		new_pattern.custom_minimum_size.y = preview.SIZE_Y+preview.SPACE_Y
		new_pattern.connect("pressed",Callable(self,"select").bind(c, "p_id"))
		$HSplitContainer/TextureVBoxContainer/Main/Preview/List.add_child(new_pattern)

func cursor_list():
	var new_cursor:CheckBox; var value:Vector2;
	for c in tilemap.c_multi_cursor_list.size():
		value = tilemap.c_multi_cursor_list[c]
		if value == Vector2(0,0): continue
		new_cursor = $HSplitContainer/TextureVBoxContainer/Main/Preview/List/Template.duplicate()
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
		$HSplitContainer/TextureVBoxContainer/Main/Preview/List.add_child(new_cursor)
	
func clear_preview_list():
	for n in $HSplitContainer/TextureVBoxContainer/Main/Preview/List.get_children():
		if n.name != "Template": n.queue_free()

func tilemap_list():
	var new_map:CheckBox
	for c in tilemap.t_tilemap_list.size():
		if tilemap.t_tilemap_list[c] == NodePath(): continue
		new_map = $HSplitContainer/TextureVBoxContainer/Main/Preview/List/Template.duplicate()
		new_map.visible = true
		new_map.button_pressed = String(c) in tilemap.t_use.split(" ")
		new_map.text = tilemap.get_node(tilemap.t_tilemap_list[c]).name
		new_map.set_meta("id", c)
		new_map.connect("pressed",Callable(self,"select").bind(c, "t_use"))
		$HSplitContainer/TextureVBoxContainer/Main/Preview/List.add_child(new_map)

func select(id, type):
	var children = $HSplitContainer/TextureVBoxContainer/Main/Preview/List.get_children()
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
	for b in $HSplitContainer/TextureVBoxContainer/Main/Preview/List.get_children():
		if not b.has_meta("id") or b.button_pressed == true: continue
		b.button_pressed = true
		select(b.get_meta("id"), "c_use")
		uncheck = false
	if uncheck:
		for b in $HSplitContainer/TextureVBoxContainer/Main/Preview/List.get_children():
			if not b.has_meta("id"): continue
			b.button_pressed = false
			select(b.get_meta("id"), "c_use")

func display_tile_hints():
	tilemap.tm_hints.clear()
	for tm in tilemap.t_tilemap_list:
		if tilemap.get_node(tm).get_cellv(tilemap.local_to_map(tilemap.get_local_mouse_position())) != -1:
			tilemap.tm_hints.append(tilemap.get_node(tm))
	tilemap.update()

func show_hints():
	can_see_tile_hint = $HSplitContainer/TextureVBoxContainer/BottledTools/HBoxContainer/TmHints.pressed

func show_old_dock():
	_find_tilemap_editor(get_tree().root).visible = $HSplitContainer/TextureVBoxContainer/BottledTools/HBoxContainer/Old.pressed

func _find_tilemap_editor(node: Node) -> Node:
	if node.get_class() == "TileMapEditor":
		return node
	for child in node.get_children():
		var tilemap_editor = _find_tilemap_editor(child)
		if tilemap_editor:
			return tilemap_editor
	return null










func _resize_button_texture(texture: Texture2D, scale: float):
	var image = texture.get_data() as Image
	var new_size = image.get_size() * scale
	image.resize(round(new_size.x), round(new_size.y))
	var new_texture = ImageTexture.new()
	new_texture.create_from_image(image)
	return new_texture

func _on_rotate_counterclockwise():
	_transform_indicator.pivot_offset = _transform_indicator.size / 2
	_transform_indicator.rotation -= 90
	if _transform_indicator.rotation < 0:
		_transform_indicator.rotation += 360

func _on_rotate_clockwise():
	_transform_indicator.pivot_offset = _transform_indicator.size / 2
	_transform_indicator.rotation += 90
	if _transform_indicator.rotation >= 360:
		_transform_indicator.rotation -= 360

func _on_flip_horizontally():
	_transform_indicator.pivot_offset = _transform_indicator.size / 2
	if _transform_indicator.rotation == 0 or _transform_indicator.rotation == 180:
		_transform_indicator.scale.x *= -1
	else:
		_transform_indicator.scale.y *= -1

func _on_flip_vertically():
	_transform_indicator.pivot_offset = _transform_indicator.size / 2
	if _transform_indicator.rotation == 0 or _transform_indicator.rotation == 180:
		_transform_indicator.scale.y *= -1
	else:
		_transform_indicator.scale.x *= -1

func _on_clear_transform():
	_transform_indicator.pivot_offset = _transform_indicator.size / 2
	_transform_indicator.rotation = 0
	_transform_indicator.scale = Vector2.ONE

func _on_disable_autotile_check_box_toggled(pressed: bool):
	var selected_items = _texture_item_list.get_selected_items()
	if selected_items.size() > 0:
		_on_TextureItemList_item_selected(selected_items[0])

func _on_enable_priority_check_box_toggled(pressed: bool):
	var selected_items = _texture_item_list.get_selected_items()
	if selected_items.size() > 0:
		_on_TextureItemList_item_selected(selected_items[0])

func _update_buttons_mouse_filter():
	if _panel:
		var rect = _panel.get_global_rect()
		var mouse_position = _panel.get_global_mouse_position()
		if rect.has_point(mouse_position):
			_on_mouse_entered()
		else: _on_mouse_exited()

func _ready():
	_update_buttons_mouse_filter()
	_texture_list_scaler.value = 0.2
	_texture_scaler.value = 1.5
	_on_TextureListScaleHSlider_value_changed(.2)
	_on_TextureScaleHSlider_value_changed(1.5)
	
	$"%Views".clear()
	$HSplitContainer/TextureVBoxContainer/Main/HSplitContainer/Panel/GroupView/GroupList/GroupTemplate.visible = false
	for v in VIEW.keys(): $"%Views".add_item(v, VIEW[v])
#	$HSplitContainer/TextureVBoxContainer/Main/HSplitContainer/Panel/GroupView.get_v_scroll_bar().pivot_offset = \
#		Vector2(-$HSplitContainer/TextureVBoxContainer/Main/HSplitContainer/Panel/GroupView.size.x,0)

func _fill():
	tilemap.tilecell = get_tilecell()
	match current_view:
		VIEW.Group: _fill_group_view()
		VIEW.Tex: _fill_texture_view()
		VIEW.List: _fill_list_view()

func _fill_list_view():
#	_texture_item_list.clear()
	for id in tileset.get_tiles_ids():
		$"%ListView".add_item("", tileset.tile_get_texture(id))
		$"%ListView".set_item_icon_region($"%ListView".get_item_count()-1,tileset.tile_get_region(id))
#		$"%ListView".set_item_tooltip_enabled($"%ListView".get_item_count()-1,true)
		$"%ListView".set_item_tooltip($"%ListView".get_item_count()-1,String(id)+" : "+tileset.tile_get_name(id))

func _fill_group_view():
	if not tileset: return
	var groups:Dictionary = tilemap.curr_tilemap.get_meta("groups_by_groups", {})
	var no_group:Array
	for id in tileset.get_tiles_ids():
		if id in tilemap.get_meta("groups_by_ids", {}).keys(): continue
		no_group.append(id)
	create_group("NO_GROUP", no_group)
	for g in groups.keys():
		create_group(g, groups.get(g, []))

func create_group(g:String, group_content:Array):
	var new_g:HBoxContainer
	_texture_item_list.add_item(g)
	new_g = $"%GroupList".get_node("GroupTemplate").duplicate()
	new_g.visible = true
	new_g.name = g
	new_g.get_node("Label").text = g
	var list = new_g.get_node("List")
	for id in group_content:
		list.add_item(String(id), tileset.tile_get_texture(id))
		list.set_item_icon_region(list.get_item_count()-1,tileset.tile_get_region(id))
		list.set_item_tooltip(list.get_item_count()-1,String(id)+" : "+tileset.tile_get_name(id))
	list.connect("item_selected",Callable(self,"_on_tile_selected_from_group").bind(g))
	$"%GroupList".call_deferred("add_child", new_g)

func _fill_texture_view():
	if tileset:
		_previous_selected_texture_index = -1
		var textures = []
		_texture_item_list.clear()
		var texture_index = 0
		var tile_index = 0
		for tile_id in tileset.get_tiles_ids():
			var tile_texture = tileset.tile_get_texture(tile_id)
			if tile_texture:
				if tile_texture in textures:
					var ti = textures.find(tile_texture)
					var meta = _texture_item_list.get_item_metadata(ti)
					meta.tiles.append({"index": tile_index, "id": tile_id})
				else:
					textures.append(tile_texture)
					var text = tile_texture.resource_path.get_file() if tile_texture.resource_path else ""
					_texture_item_list.add_item(text, tile_texture)
					_texture_item_list.set_item_metadata(texture_index, {"texture": tile_texture, "tiles": [{"index": tile_index, "id": tile_id}]})
					texture_index += 1
			tile_index += 1
		
		for child in _sprite_border.get_children():
			_sprite_border.remove_child(child)
			child.queue_free()
		for child in _bg_holder.get_children():
			_bg_holder.remove_child(child)
			child.queue_free()
		if not tileset.is_connected("changed",Callable(self,"_on_tileset_changed")):
			tileset.connect("changed",Callable(self,"_on_tileset_changed").bind(tileset))
	if _texture_item_list.get_item_count() > 0:
		_texture_item_list.select(0)
		_on_TextureItemList_item_selected(0)
		for child in _sprite_border.get_children():
			if child is ReferenceRect:
				if child.has_meta("tile_id"):
					_on_pressed_tile_button(child)
					break

func _clear():
	_clear_list_view()
	_clear_texture_view()
	_clear_group_view()

func _clear_list_view():
	$"%ListView".clear()

func _clear_group_view():
	for g in $"%GroupList".get_children():
		if g.name == "GroupTemplate": continue
		g.queue_free()
	_texture_item_list.clear()

func _clear_texture_view():
	_subtile_to_select = -1
	_previous_selected_texture_index = -1
	_texture_item_list.clear()
	_sprite.texture = null
	_sprite_border.size = Vector2.ZERO
	for child in _sprite_border.get_children():
		_sprite_border.remove_child(child)
		child.queue_free()
	for child in _bg_holder.get_children():
		_bg_holder.remove_child(child)
		child.queue_free()
	_selection_rect.size = Vector2.ZERO
	_selection_rect.position = Vector2.ZERO
	_last_selected_tile = -1
	_last_selected_subtile = -1
	for connection in get_incoming_connections():
		if connection["signal"].source is TileSet and connection["signal"].name == "changed" and connection.method_name == "_on_tileset_changed":
			connection["signal"].source.disconnect("changed",Callable(self,"_on_tileset_changed"))

func _on_tileset_changed(new_tileset: TileSet):
	_clear()
	_fill()

func _create_tile_button(tile_id: int, tile_region: Rect2, subtile_index = -1, subtile_coord: Vector2 = Vector2.ZERO, inactive = false):
	var tile_button = ReferenceRect.new()
	_sprite_border.add_child(tile_button)
	tile_button.size = tile_region.size
	tile_button.position = tile_region.position
	if subtile_index == null:
		tile_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile_button.border_color = absent_subtile_border_color
		var color_rect = ColorRect.new()
		color_rect.size = tile_region.size
		color_rect.position = tile_region.position
		color_rect.color = absent_subtile_fill_color
	else:
#		match tileset.tile_get_tile_mode(tile_id):
#			TileSet.SINGLE_TILE:
#				tile_button.border_color = single_tile_border_color
#			TileSet.AUTO_TILE:
#				tile_button.border_color = auto_tile_border_color if subtile_index < 0 else subtile_border_color
#			TileSet.ATLAS_TILE:
#				tile_button.border_color = atlas_tile_border_color if subtile_index < 0 else subtile_border_color
		tile_button.mouse_filter = Control.MOUSE_FILTER_IGNORE if inactive else Control.MOUSE_FILTER_PASS
		tile_button.set_meta("inactive", inactive)
		tile_button.set_meta("tile_id", tile_id)
		tile_button.set_meta("subtile_index", subtile_index)
		tile_button.connect("gui_input",Callable(self,"_on_ReferenceRect_gui_input").bind(tile_button))
		if not inactive and subtile_index != null:
			var tile_bg = TextureRect.new()
			var tex = AtlasTexture.new()
			tex.atlas = tileset.tile_get_texture(tile_id)
			tex.region = tile_region
			tex.flags = tex.atlas.flags
			tile_bg.texture = tex
			tile_bg.position = tile_button.position
			tile_bg.show_behind_parent = true
			tile_bg.mouse_filter = MOUSE_FILTER_IGNORE
			_bg_holder.add_child(tile_bg)
		if not inactive and _last_selected_tile == tile_id:
			if (_last_selected_subtile == subtile_index) or \
				(_last_selected_subtile == -1 and subtile_index == 0) or \
				(_last_selected_subtile >= 0 and subtile_index == -1):
				_selection_rect.size = tile_button.size
				_selection_rect.position = tile_button.position
				if subtile_index < 0:
					_last_selected_subtile = -1

func _create_single_tile_button(tile_id: int):
	_create_tile_button(tile_id, tileset.tile_get_region(tile_id))

func _create_multiple_tile_button(tile_id: int, with_bitmask: bool = false):
	var tile_region = tileset.tile_get_region(tile_id)
	var subtile_size = tileset.autotile_get_size(tile_id)
	var subtile_spacing = tileset.autotile_get_spacing(tile_id)
	var subtile_index = 0
	var x_coord = 0
	var y_coord = 0
	for y in range(0, tile_region.size.y, subtile_size.y + subtile_spacing):
		for x in range(0, tile_region.size.x, subtile_size.x + subtile_spacing):
			var subtile_coord = Vector2(x_coord, y_coord)
			x_coord += 1
			var subtile_position = Vector2(x, y)
			if with_bitmask:
				if tileset.autotile_get_bitmask(tile_id, subtile_coord) <= 0:
					continue
			var subtile_region = Rect2(tile_region.position + subtile_position, subtile_size)
			_create_tile_button(tile_id, subtile_region, subtile_index, subtile_coord)
			subtile_index += 1
		y_coord += 1
		x_coord = 0
	_create_tile_button(tile_id, tile_region, -1, Vector2.ZERO, true)

func _reset_scale(new_scale: float = 1):
	_sprite_border.size = _sprite.texture.get_size() if _sprite.texture else Vector2.ZERO
	_scaling_helper.position = Vector2.ZERO
	_scaling_helper.scale = Vector2.ONE * new_scale
	_sprite.position = Vector2.ZERO
	_texture_scaler.value = new_scale

func _create_tile_hint(tile_index: int, tile_id: int):
	var tile_region = tileset.tile_get_region(tile_id)
	var tile_name = tileset.tile_get_name(tile_id)
	var tile_hint_label = Label.new()
	tile_hint_label.add_theme_color_override("font_color", tile_hint_label_font_color)
	tile_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tile_hint_label_bg = ColorRect.new()
	tile_hint_label_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile_hint_label.add_child(tile_hint_label_bg)
	tile_hint_label_bg.show_behind_parent = true
#	match tileset.tile_get_tile_mode(tile_id):
#		TileSet.SINGLE_TILE:
#			tile_hint_label.text = "%s:%s SINGLE %s" % [tile_index, tile_id, tile_name]
#			tile_hint_label_bg.color = single_tile_border_color
#		TileSet.AUTO_TILE:
#			tile_hint_label.text = "%s:%s AUTO %s" % [tile_index, tile_id, tile_name]
#			tile_hint_label_bg.color = auto_tile_border_color
#		TileSet.ATLAS_TILE:
#			tile_hint_label.text = "%s:%s ATLAS %s" % [tile_index, tile_id, tile_name]
#			tile_hint_label_bg.color = atlas_tile_border_color
	_sprite_border.add_child(tile_hint_label)
	tile_hint_label.position = tile_region.position
	tile_hint_label_bg.size = tile_hint_label.size
	tile_hint_label.tooltip_text = "{tile index}:{tile id} {MODE} {name}"

func _on_TextureItemList_item_selected(index):
	if current_view == VIEW.Tex:
		_subtile_to_select = -1
		var meta = _texture_item_list.get_item_metadata(index)
		
		if _previous_selected_texture_index != index:
			_sprite.texture = meta.texture
			_reset_scale(_texture_scaler.value)
			_previous_selected_texture_index = index
		
		for child in _sprite_border.get_children():
			_sprite_border.remove_child(child)
			child.queue_free()
		for child in _bg_holder.get_children():
			_bg_holder.remove_child(child)
			child.queue_free()
		_selection_rect.position = Vector2.ZERO
		_selection_rect.size = Vector2.ZERO
		for tile in meta.tiles:
#			match tileset.tile_get_tile_mode(tile.id):
#				TileSet.SINGLE_TILE:
#					_create_single_tile_button(tile.id)
#				TileSet.ATLAS_TILE:
#					_create_single_tile_button(tile.id) \
#					if _enable_priority_check_box.pressed else \
#					_create_multiple_tile_button(tile.id)
#				TileSet.AUTO_TILE:
#					_create_multiple_tile_button(tile.id, true) \
#					if _disable_autotile_check_box.pressed else \
#					_create_single_tile_button(tile.id)
			_create_tile_hint(tile.index, tile.id)
		_update_tile_hints()
		_refresh_buttons_availibility()

func _on_tile_selected_from_group(index, group):
	current_tile = tilemap.curr_tilemap.get_meta("groups_by_groups")[group][index]
	_tile_list.select(current_tile)
	_tile_map_editor._palette_selected(int(current_tile))
	init_tilecell()
	for g in $"%GroupList".get_children():
		if g.name == group: continue
		g.get_node("List").deselect_all()

func _on_ListView_item_selected(index: int) -> void:
	current_tile = index
	_tile_list.select(current_tile)
	_tile_map_editor._palette_selected(int(current_tile))
	init_tilecell()

func _on_pressed_tile_button(tile_button: ReferenceRect):
	_subtile_to_select = -1
	current_tile = tile_button.get_meta("tile_id")
	var tile_index = -1
	for tile_item_index in range(_tile_list.get_item_count()):
		if current_tile == _tile_list.get_item_metadata(tile_item_index):
			tile_index = tile_item_index
	if tile_index >= 0:
		_tile_list.select(tile_index)
		_tile_map_editor._palette_selected(tile_index)
		_last_selected_subtile = -1
#		match tileset.tile_get_tile_mode(current_tile):
#			TileSet.SINGLE_TILE:
#				_enable_priority_check_box.visible = false
#				_disable_autotile_check_box.visible = false
#			TileSet.ATLAS_TILE:
#				if not _enable_priority_check_box.pressed:
#					var subtile_index = tile_button.get_meta("subtile_index")
#					if subtile_index >= 0:
#						_last_selected_subtile = subtile_index
#						_subtile_to_select = subtile_index
#				_enable_priority_check_box.visible = true
#				_disable_autotile_check_box.visible = false
#			TileSet.AUTO_TILE:
#				if _disable_autotile_check_box.pressed:
#					var subtile_index = tile_button.get_meta("subtile_index")
#					if subtile_index >= 0:
#						_last_selected_subtile = subtile_index
#						_subtile_to_select = subtile_index
#				_enable_priority_check_box.visible = false
#				_disable_autotile_check_box.visible = true
		_selection_rect.position = tile_button.position
		_selection_rect.size = tile_button.size
		_last_selected_tile = current_tile
	
	init_tilecell()

# Cell Manager
func init_tilecell():
	var populate_array = [null,null,tilemap.curr_tilemap,current_tile,tileset]
	$HSplitContainer/TextureVBoxContainer/Main/HSplitContainer/TileCells.populate_infos(populate_array)

func _process(_delta: float):
	if _subtile_to_select >= 0 and _subtile_list.get_item_count() > _subtile_to_select:
		_subtile_list.select(_subtile_to_select)
		_subtile_to_select = -1
	if not (can_select and tilemap.is_selecting): return
	tilemap.update()

func _on_ReferenceRect_gui_input(event: InputEvent, tile_button: ReferenceRect):
	if tile_button.get_meta("inactive") or not (event is InputEventMouseButton and event.pressed) \
		or event.button_index != MOUSE_BUTTON_LEFT:
			return
	_on_pressed_tile_button(tile_button)

var _mouse_wrapped: bool = false
func _input(event: InputEvent):
	if tilemap and event is InputEventMouseMotion and tilemap.c_multi_cursor_list.size() > 0:
		tilemap.update()
	if can_see_tile_hint:
		display_tile_hints()
	if can_select and event is InputEventMouseButton:
		if event.is_pressed():
			tilemap.is_selecting = true
			tilemap.has_selected = false
			tilemap.selecting_init_pos = tilemap.get_local_mouse_position()
			tilemap.selected_tiles.clear()
		else:
			tilemap.is_selecting = false
			tilemap.has_selected = true
			tilemap.selecting_end_pos = tilemap.get_local_mouse_position()
			tilemap.select_tiles()
			tilemap.update()

	if _dragging:
		if event is InputEventMouseButton:
			if (not event.pressed) and event.button_index == MOUSE_BUTTON_MIDDLE:
				_dragging = false
		if event is InputEventMouseMotion:
			if _mouse_wrapped:
				_mouse_wrapped = false
			else: _scaling_helper.position += event.relative
			var mouse_position = get_global_mouse_position()
			var new_mouse_position = mouse_position
			var rect = _panel.get_global_rect() as Rect2
			if new_mouse_position.x < rect.position.x:
				new_mouse_position.x = rect.end.x
			elif new_mouse_position.x > rect.end.x:
				new_mouse_position.x = rect.position.x
			if new_mouse_position.y < rect.position.y:
				new_mouse_position.y = rect.end.y
			elif new_mouse_position.y > rect.end.y:
				new_mouse_position.y = rect.position.y
			if new_mouse_position != mouse_position:
				_mouse_wrapped = true
				get_viewport().warp_mouse(new_mouse_position)

func _update_tile_hints():
	for child in _sprite_border.get_children():
		if not child is Label: continue
		child.visible = _show_tile_hints_check_box.pressed
		child.scale = Vector2.ONE / (_scaling_helper.scale)

func _scale(factor: float):
	match current_view:
		VIEW.Tex:
			var to_scale:Control = _sprite
		#	match current_view:
		#		VIEW.Tex: to_scale = _sprite
		#		VIEW.Group: to_scale = $HSplitContainer/TextureVBoxContainer/Main/HSplitContainer/Panel/ScalingHelper/GroupView
			var sprite_global_position = to_scale.global_position
			_scaling_helper.global_position = get_global_mouse_position()
			to_scale.global_position = sprite_global_position
			_scaling_helper.scale *= factor
			_texture_scaler.value = _scaling_helper.scale.x
			_update_tile_hints()
		VIEW.Group:
			pass

func _set_scale(value: float):
	if current_view == VIEW.Group: return
	var sprite_global_position = _sprite.global_position
	_scaling_helper.position = _panel.size / 2
	_sprite.global_position = sprite_global_position
	_scaling_helper.scale = Vector2.ONE * value
	_update_tile_hints()

func _refresh_buttons_availibility():
	for button in _sprite_border.get_children():
		if not button is ReferenceRect: continue
		if _mouse_entered:
			if button.get_meta("inactive"): continue
			button.mouse_filter = Control.MOUSE_FILTER_PASS
		else: button.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_mouse_entered():
	if _mouse_entered: return
	_mouse_entered = true
	_refresh_buttons_availibility()

func _on_mouse_exited():
	if not _mouse_entered: return
	_mouse_entered = false
	_refresh_buttons_availibility()

func _on_Panel_gui_input(event):
	if not event is InputEventMouse: return
	_update_buttons_mouse_filter()
	if not (event is InputEventMouseButton and event.pressed): return
	match event.button_index:
		MOUSE_BUTTON_MIDDLE: _dragging = true
		MOUSE_BUTTON_WHEEL_UP: _scale(1.5)
		MOUSE_BUTTON_WHEEL_DOWN: _scale(1/1.5)

func _on_TextureListScaleHSlider_value_changed(value):
	_texture_item_list.icon_scale = value
	var _texture_item_list_rect_size = _texture_item_list.size
	_texture_item_list.size = Vector2.ZERO
	_texture_item_list.size = _texture_item_list_rect_size

func _on_TextureScaleHSlider_value_changed(value):
	_set_scale(value)

func _on_ResetScalingToolButton_pressed():
	_reset_scale()

func _on_ShowTileHintsCheckBox_toggled(button_pressed):
	_update_tile_hints()

func _on_Selection_pressed() -> void:
	can_select = $HSplitContainer/TextureVBoxContainer/BottledTools/HBoxContainer/Selection.pressed
	if can_select: return
	tilemap.is_selecting = false
	tilemap.has_selected = false

func _on_EraseAll_pressed() -> void:
	tilemap.set_global_replacing(true, tilemap.ALL_TILES, -1)

func _on_TilePalette_resized() -> void:
	$"%TileCells".get_node("ScrollContainer").custom_minimum_size.y = max(175, size.y-100)

func get_tilecell():
	return $"%TileCells"

func _on_Views_item_selected(index: int) -> void:
	current_view = index
	$HSplitContainer/TextureVBoxContainer/Main/HSplitContainer/Panel/GroupView.visible = current_view == VIEW.Group
	$HSplitContainer/TextureVBoxContainer/Main/HSplitContainer/Panel/ScalingHelper.visible = current_view in [VIEW.Tex, VIEW.List]
	$"%ListView".visible = current_view == VIEW.List
	_clear()
	_fill()

func _on_Search_text_changed(new_text: String) -> void:
	pass # Replace with function body.
