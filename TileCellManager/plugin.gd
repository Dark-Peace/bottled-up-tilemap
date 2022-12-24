tool
extends EditorPlugin


const sceneTileCells = preload("res://addons/TileCellManager/TileCells.gd")
var TileCells: Control
var TileNode: Node
var Nodeselected = get_editor_interface().get_selection()

onready var TileList = get_parent().get_node("@@592/@@593/@@601/@@603/@@607/@@611/@@612/@@613/@@629/@@630/@@639/@@640/@@6339/@@6178/@@6179/@@11159/@@11137/@@11139")
#onready var tileinfos = get_parent().get_node("@@592/@@593/@@601/@@603/@@607/@@611/@@614/@@615/@@616/Inspector/@@4029")


func _enter_tree():
	Nodeselected.connect("selection_changed",self,"on_node_selected")

func on_node_selected():
	check_validation()
	if Nodeselected.get_selected_nodes().size() != 0:
		if Nodeselected.get_selected_nodes()[0].get_class() == "TileMap":
			TileCells = sceneTileCells.instance()
			add_control_to_bottom_panel(TileCells,"TileCell")
			archive_node = Nodeselected.get_selected_nodes()[0]
		else:
			check_validation()


func check_validation():
	if is_instance_valid(TileCells):
		remove_control_from_bottom_panel(TileCells)
		archive_cell = -1

var archive_cell = -1
var archive_node
func _input(event):
	var cell = TileList.get_selected_items()
	if TileList.get_selected_items().size() == 0:
		archive_cell = -1
		return
	if archive_cell != cell[0]:
		var icon = TileList.get_item_icon(cell[0])
		var region = TileList.get_item_icon_region(cell[0])
		var cell_name = TileList.get_item_text(cell[0])
		var cell_id = archive_node.tile_set.find_tile_by_name(cell_name)
		var populate_array = [icon,region,cell_name,cell_id,archive_node]
		TileCells.populate_infos(populate_array)
		archive_cell = cell[0]

func _exit_tree():
	check_validation()
	Nodeselected.disconnect("selection_changed",self,"on_node_selected")
