@tool
extends EditorPlugin

var TileMapInspectorPlugin = load("res://addons/BottledTileMap/TilePalette/tilemap_inspector_plugin.gd")

var _selection: EditorSelection
var _tile_palette: Control
var _tilemap_editor: Control

var _tile_list: ItemList
var _subtile_list: ItemList

var _checkboxes_parent: Control
var _disable_autotile_check_box: CheckBox
var _disable_autotile_check_box_position: int
var _enable_priority_check_box: CheckBox
var _enable_priority_check_box_position: int

var _tools_parent: Control
var _rotate_left_button: Button
var _rotate_left_button_position: int
var _rotate_right_button: Button
var _rotate_right_button_position: int
var _flip_horizontally_button: Button
var _flip_horizontally_button_position: int
var _flip_vertically_button: Button
var _flip_vertically_button_position: int
var _clear_transform_button: Button
var _clear_transform_button_position: int

var _tilemap_inspector_plugin

var dock_button
var toolbar:Control
var grid_button:Button
var layer_select:OptionButton
var layer_vis:Button
var toolbar_theme:StyleBoxFlat
var my_toolbar_theme:StyleBoxFlat = preload("res://addons/BottledTileMap/ToolBarTheme.tres")
var editor_script_screen:Button


func _enter_tree():
	_tilemap_inspector_plugin = TileMapInspectorPlugin.new(get_editor_interface().get_inspector())
	add_inspector_plugin(_tilemap_inspector_plugin)
	_add_tile_palette()
	_tilemap_inspector_plugin.connect("tile_map_tile_set_changed",Callable(self,"_on_selection_changed"))

func _exit_tree():
	_remove_tile_palette()
	remove_inspector_plugin(_tilemap_inspector_plugin)

func _on_selection_changed():
	var selected_nodes = _selection.get_selected_nodes()
	if _tile_palette.lock_dock and _tilemap_editor.visible: lock_palette_dock()
	if selected_nodes.size() == 1:
		var selected_node = selected_nodes[0]
		if selected_node is BottledTileMap:
			_tile_palette.tilemap = selected_node #BottledTileMap
			_tile_palette.tileset = selected_node.tile_set
			if not layer_select.item_selected.is_connected(selected_node.set_current_layer.bind(layer_select)):
				layer_select.item_selected.connect(selected_node.set_current_layer.bind(layer_select))
#			_tilemap_editor.set_deferred("visible", true)
			make_bottom_panel_item_visible(_tilemap_editor)
			my_toolbar_theme = load("res://addons/BottledTileMap/ToolBarTheme.tres")
			toolbar.get_node("../../").set("theme_override_styles/panel", my_toolbar_theme)
#			make_bottom_panel_item_visible(_tile_palette)
			if editor_script_screen.button_pressed:
				call_deferred("close_bottom_panel", 0.005)
			return
		else:
			if editor_script_screen.button_pressed: call_deferred("close_bottom_panel", 0.16)
			toolbar.get_node("../../").set("theme_override_styles/panel", toolbar_theme)
	_tile_palette.tileset = null
#	_tilemap_editor.set_deferred("custom_minimum_size", Vector2(262,0))
#	set_min_size(_tilemap_editor)
#	_tilemap_editor.get_child(2).get_child(1).get_child(0).get_child(0).get_child(1).get_child(0).get_child(0).get_child(1).custom_minimum_size.y = 0
#	_tilemap_editor.get_child(2).get_child(1).get_child(0).get_child(0).get_child(1).get_child(0).get_child(1).get_child(1).custom_minimum_size.y = 0

func close_bottom_panel(timer:float=0.16):
	await get_tree().create_timer(timer).timeout
	hide_bottom_panel()

func lock_palette_dock(timer:float=0.16):
	await get_tree().create_timer(timer).timeout
	make_bottom_panel_item_visible(_tilemap_editor)

func set_min_size(parent):
#	parent.visible = false
#	for p in parent.get_property_list():
#		if p["name"] == "custom_minimum_size":
#			parent.custom_minimum_size.y = 0
#			break
	for child in parent.get_children():
		child.visible = false
		set_min_size(child)


func _print_tree(node: Node, indent = 0):
	var prefix = ""
	for i in range(indent):
		prefix += "  "
	print("%s%s name: %s, text: %s" % [prefix, node, node.name, node.text if "text" in node else ""])
	for child in node.get_children():
		_print_tree(child, indent + 1)

func _add_tile_palette():
	_tile_palette = load("res://addons/BottledTileMap/TilePalette/TilePalette.tscn").instantiate()
	_tile_palette.active = true
	_selection = get_editor_interface().get_selection()
	_selection.connect("selection_changed",Callable(self,"_on_selection_changed"))
#	dock_button = add_control_to_bottom_panel(_tile_palette, "Tile Palette")
	_tilemap_editor = _find_in_editor()
	_tile_list = _tilemap_editor.get_child(2).get_child(1).get_child(0).get_child(0) as ItemList
#	_tile_list = _tilemap_editor.get_child(5).get_child(0) as ItemList
	_subtile_list = null#_tilemap_editor.get_child(5).get_child(1) as ItemList

	_tile_palette.set_lists(_tile_list, _subtile_list)
	
	layer_select = _tilemap_editor.get_child(0).get_child(4)
	layer_vis = _tilemap_editor.get_child(0).get_child(5)
	grid_button = _tilemap_editor.get_child(0).get_child(7)
	
	_tile_palette.set_tools(_tilemap_editor, get_editor_interface().get_editor_scale())

	_on_selection_changed()
	_tilemap_editor.get_child(0).remove_child(layer_select)
	_tilemap_editor.get_child(0).remove_child(layer_vis)
	_tilemap_editor.get_child(0).remove_child(grid_button)
	toolbar.add_child(layer_select)
	toolbar.add_child(layer_vis)
	toolbar.add_child(grid_button)
#	print(toolbar.get_node("../../").get_stylebox_type_list())
	toolbar_theme = toolbar.get_node("../../").get("theme_override_styles/panel").duplicate()
#	print(toolbar_theme)
	
	_tilemap_editor.add_child(_tile_palette)
	var tilemap_child
	for i in 5:
		tilemap_child = _tilemap_editor.get_child(0)
		_tilemap_editor.remove_child(tilemap_child)
#		_tile_palette.get_node("Old").add_child(tilemap_child)
#		tilemap_child.visible = false
	
	editor_script_screen = _find_in_editor("EditorTitleBar").get_child(2).get_child(2)

func _find_in_editor(target:String="TileMapEditor", node:Node=get_tree().root) -> Node:
	if node.get_class() == target:
		return node
	for child in node.get_children():
		var tilemap_editor = _find_in_editor(target, child)
		if tilemap_editor:
			return tilemap_editor
	return null

func _remove_tile_palette():
	remove_control_from_bottom_panel(_tile_palette)

	_tile_palette.queue_free()
	_selection.disconnect("selection_changed",Callable(self,"_on_selection_changed"))

	_release_canvas_item_visibility(_tilemap_editor)
	var selected_nodes = _selection.get_selected_nodes()
	if selected_nodes.size() == 1:
		var selected_node = selected_nodes[0]
		if selected_node is BottledTileMap:
			_tilemap_editor.visible = true

func _hang_canvas_item_visibility(canvas_item: CanvasItem, value: bool):
	canvas_item.visible = value
	canvas_item.connect("visibility_changed",Callable(self,"_on_canvas_item_visibility_changed").bind(canvas_item, value))

func _release_canvas_item_visibility(canvas_item: CanvasItem):
	canvas_item.disconnect("visibility_changed",Callable(self,"_on_canvas_item_visibility_changed"))

func _on_canvas_item_visibility_changed(canvas_item: CanvasItem, value: bool):
	if not canvas_item.visible == value:
		canvas_item.visible = value
