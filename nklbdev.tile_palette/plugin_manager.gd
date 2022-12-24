tool
extends EditorPlugin

#TileMapEditor structure:
#@@11844:[TileMapEditor:17202] name: @@11844, text: 
#  @@11814:[HBoxContainer:17209] name: @@11814, text: 
#    @@11839:[ToolButton:17246] name: @@11839, text: 
#    @@11840:[ToolButton:17249] name: @@11840, text: 
#    @@11841:[ToolButton:17252] name: @@11841, text: 
#    @@11842:[ToolButton:17255] name: @@11842, text: 
#    @@11843:[ToolButton:17258] name: @@11843, text: 
#  @@11815:[CheckBox:17210] name: @@11815, text: Disable Autotile
#  @@11816:[CheckBox:17211] name: @@11816, text: Enable Priority
#  @@11820:[LineEdit:17212] name: @@11820, text: 
#    @@11817:[Timer:17213] name: @@11817, text: 
#    @@11819:[PopupMenu:17214] name: @@11819, text: 
#      @@11818:[Timer:17215] name: @@11818, text: 
#  @@11821:[HSlider:17216] name: @@11821, text: 
#  @@11822:[VSplitContainer:17217] name: @@11822, text: 
#    @@11824:[ItemList:17218] name: @@11824, text: 
#      @@11823:[VScrollBar:17219] name: @@11823, text: 
#      @@11825:[Label:17220] name: @@11825, text: Give a TileSet resource to this TileMap to use its tiles.
#    @@11827:[ItemList:17221] name: @@11827, text: 
#      @@11826:[VScrollBar:17222] name: @@11826, text: 

const TileMapInspectorPlugin = preload("res://addons/nklbdev.tile_palette/tilemap_inspector-plugin.gd")

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
var _rotate_left_button: ToolButton
var _rotate_left_button_position: int
var _rotate_right_button: ToolButton
var _rotate_right_button_position: int
var _flip_horizontally_button: ToolButton
var _flip_horizontally_button_position: int
var _flip_vertically_button: ToolButton
var _flip_vertically_button_position: int
var _clear_transform_button: ToolButton
var _clear_transform_button_position: int

var _tilemap_inspector_plugin

func _enter_tree():
	_tilemap_inspector_plugin = TileMapInspectorPlugin.new(get_editor_interface().get_inspector())
	add_inspector_plugin(_tilemap_inspector_plugin)
	_add_tile_palette()
	_tilemap_inspector_plugin.connect("tile_map_tile_set_changed", self, "_on_selection_changed")

func _exit_tree():
	_remove_tile_palette()
	remove_inspector_plugin(_tilemap_inspector_plugin)

func _on_selection_changed():
	var selected_nodes = _selection.get_selected_nodes()
	if selected_nodes.size() == 1:
		var selected_node = selected_nodes[0]
		if selected_node is BottledTileMap:
			_tile_palette.tilemap = selected_node #BottledTileMap
			_tile_palette.tileset = selected_node.tile_set
			make_bottom_panel_item_visible(_tile_palette)
			return
	_tile_palette.tileset = null

func _print_tree(node: Node, indent = 0):
	var prefix = ""
	for i in range(indent):
		prefix += "  "
	print("%s%s name: %s, text: %s" % [prefix, node, node.name, node.text if "text" in node else ""])
	for child in node.get_children():
		_print_tree(child, indent + 1)

func _add_tile_palette():
	_tile_palette = load("res://addons/nklbdev.tile_palette/tile_palette.tscn").instance()
	_selection = get_editor_interface().get_selection()
	_selection.connect("selection_changed", self, "_on_selection_changed")
	add_control_to_bottom_panel(_tile_palette, "Tile Palette")
	_tilemap_editor = _find_tilemap_editor(get_tree().root)
#	var items = _tilemap_editor.get_node("@@11822/@@11824") as ItemList
	_tile_list = _tilemap_editor.get_child(5).get_child(0) as ItemList
#	var atlas_tile_items = _tilemap_editor.get_node("@@11822/@@11827") as ItemList
	_subtile_list = _tilemap_editor.get_child(5).get_child(1) as ItemList

	_tile_palette.set_lists(_tile_list, _subtile_list)

	_hang_canvas_item_visibility(_tilemap_editor, false)
	_checkboxes_parent = _tilemap_editor
#	_disable_autotile_check_box = _tilemap_editor.get_node("@@11815") as CheckBox
	_disable_autotile_check_box = _tilemap_editor.get_child(1) as CheckBox
	_disable_autotile_check_box_position = 1 # _disable_autotile_check_box.get_position_in_parent()
	_hang_canvas_item_visibility(_disable_autotile_check_box, true)
#	_enable_priority_check_box = _tilemap_editor.get_node("@@11816") as CheckBox
	_enable_priority_check_box = _tilemap_editor.get_child(2) as CheckBox
	_enable_priority_check_box_position = 2 # _enable_priority_check_box.get_position_in_parent()
	_hang_canvas_item_visibility(_enable_priority_check_box, true)

#	_tools_parent = _tilemap_editor.get_node("@@11814") as HBoxContainer
	_tools_parent = _tilemap_editor.get_child(0) as HBoxContainer

#	_rotate_left_button = _tilemap_editor.get_node("@@11814/@@11839") as ToolButton
	_rotate_left_button = _tools_parent.get_child(0) as ToolButton
	_rotate_left_button_position = 0 # _rotate_left_button.get_position_in_parent()

#	_rotate_right_button = _tilemap_editor.get_node("@@11814/@@11840") as ToolButton
	_rotate_right_button = _tools_parent.get_child(1) as ToolButton
	_rotate_right_button_position = 1 # _rotate_right_button.get_position_in_parent()

#	_flip_horizontally_button = _tilemap_editor.get_node("@@11814/@@11841") as ToolButton
	_flip_horizontally_button = _tools_parent.get_child(2) as ToolButton
	_flip_horizontally_button_position = 2 # _flip_horizontally_button.get_position_in_parent()

#	_flip_vertically_button = _tilemap_editor.get_node("@@11814/@@11842") as ToolButton
	_flip_vertically_button = _tools_parent.get_child(3) as ToolButton
	_flip_vertically_button_position = 3 # _flip_vertically_button.get_position_in_parent()

#	_clear_transform_button = _tilemap_editor.get_node("@@11814/@@11843") as ToolButton
	_clear_transform_button = _tools_parent.get_child(4) as ToolButton
	_clear_transform_button_position = 4 # _clear_transform_button.get_position_in_parent()

	_tile_palette.set_tools(
		_tilemap_editor,
		_disable_autotile_check_box,
		_enable_priority_check_box,
		_rotate_left_button,
		_rotate_right_button,
		_flip_horizontally_button,
		_flip_vertically_button,
		_clear_transform_button,
		get_editor_interface().get_editor_scale())

	_on_selection_changed()


func _find_tilemap_editor(node: Node) -> Node:
	if node.get_class() == "TileMapEditor":
		return node
	for child in node.get_children():
		var tilemap_editor = _find_tilemap_editor(child)
		if tilemap_editor:
			return tilemap_editor
	return null

func _remove_tile_palette():
	remove_control_from_bottom_panel(_tile_palette)
	_disable_autotile_check_box.get_parent().remove_child(_disable_autotile_check_box)
	_checkboxes_parent.add_child(_disable_autotile_check_box)
	_checkboxes_parent.move_child(_disable_autotile_check_box, _disable_autotile_check_box_position)
	_release_canvas_item_visibility(_disable_autotile_check_box)
	_enable_priority_check_box.get_parent().remove_child(_enable_priority_check_box)
	_checkboxes_parent.add_child(_enable_priority_check_box)
	_checkboxes_parent.move_child(_enable_priority_check_box, _enable_priority_check_box_position)
	_release_canvas_item_visibility(_enable_priority_check_box)

	_rotate_left_button.get_parent().remove_child(_rotate_left_button)
	_tools_parent.add_child(_rotate_left_button)
	_tools_parent.move_child(_rotate_left_button, _rotate_left_button_position)
	_rotate_right_button.get_parent().remove_child(_rotate_right_button)
	_tools_parent.add_child(_rotate_right_button)
	_tools_parent.move_child(_rotate_right_button, _rotate_right_button_position)
	_flip_horizontally_button.get_parent().remove_child(_flip_horizontally_button)
	_tools_parent.add_child(_flip_horizontally_button)
	_tools_parent.move_child(_flip_horizontally_button, _flip_horizontally_button_position)
	_flip_vertically_button.get_parent().remove_child(_flip_vertically_button)
	_tools_parent.add_child(_flip_vertically_button)
	_tools_parent.move_child(_flip_vertically_button, _flip_vertically_button_position)
	_clear_transform_button.get_parent().remove_child(_clear_transform_button)
	_tools_parent.add_child(_clear_transform_button)
	_tools_parent.move_child(_clear_transform_button, _clear_transform_button_position)

	_tile_palette.queue_free()
	_selection.disconnect("selection_changed", self, "_on_selection_changed")

	_release_canvas_item_visibility(_tilemap_editor)
	var selected_nodes = _selection.get_selected_nodes()
	if selected_nodes.size() == 1:
		var selected_node = selected_nodes[0]
		if selected_node is BottledTileMap:
			_tilemap_editor.visible = true
			if _tile_list.is_anything_selected():
				_tilemap_editor._palette_selected(_tile_list.get_selected_items()[0])


func _hang_canvas_item_visibility(canvas_item: CanvasItem, value: bool):
	canvas_item.visible = value
	canvas_item.connect("visibility_changed", self, "_on_canvas_item_visibility_changed", [canvas_item, value])

func _release_canvas_item_visibility(canvas_item: CanvasItem):
	canvas_item.disconnect("visibility_changed", self, "_on_canvas_item_visibility_changed")

func _on_canvas_item_visibility_changed(canvas_item: CanvasItem, value: bool):
	if not canvas_item.visible == value:
		canvas_item.visible = value
