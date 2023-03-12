@tool
extends EditorPlugin

# ******************************************************************************

var tile_cells_scene = null
var tile_list = null
var tile_cell: Control

func _find_in_editor(target:String="TileMapEditor", node:Node=get_tree().root) -> Node:
	if node.get_class() == target:
		return node
	for child in node.get_children():
		var tilemap_editor = _find_in_editor(target, child)
		if tilemap_editor:
			return tilemap_editor
	return null

# ******************************************************************************

func _enter_tree():
	tile_cells_scene = load("res://addons/BottledTileMap/TileCellManager/TileCells.tscn")

	var _tilemap_editor = _find_in_editor()
	tile_list = _tilemap_editor.get_child(2).get_child(1).get_child(0).get_child(0) as ItemList
	
	tile_list.connect('gui_input',Callable(self,'tile_list_gui_input'))

	get_editor_interface().get_selection().connect("selection_changed",Callable(self,"on_node_selected"))

func on_node_selected():
	check_validation()

	var selection = get_editor_interface().get_selection().get_selected_nodes()

	if selection.size() == 0:
		return

	if selection[0] is TileMap:
		archive_node = selection[0]

		tile_cell = tile_cells_scene.instantiate()
		add_control_to_bottom_panel(tile_cell, "TileCell")
	else:
		check_validation()

func check_validation():
	if is_instance_valid(tile_cell):
		remove_control_from_bottom_panel(tile_cell)
		archive_cell = -1

var archive_cell = -1
var archive_node

func tile_list_gui_input(event):
	if event is InputEventMouseButton:
		var cell = tile_list.get_selected_items()
		if tile_list.get_selected_items().size() == 0:
			archive_cell = -1
			return
		if archive_cell != cell[0]:
			var data = {
				icon = tile_list.get_item_icon(cell[0]),
				region = tile_list.get_item_icon_region(cell[0]),
				cell_name = tile_list.get_item_text(cell[0]),
				tilemap = archive_node
			}
			tile_cell.populate_infos(data)
			archive_cell = cell[0]

func _exit_tree():
	check_validation()
	get_editor_interface().get_selection().disconnect("selection_changed",Callable(self,"on_node_selected"))
