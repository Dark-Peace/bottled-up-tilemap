@tool
extends EditorPlugin

# ******************************************************************************

var plugin_dir = 'res://addons/BottledTileMap/'

var tile_cell_manager = null
var tile_palette_manager = null
var toolbar = preload("res://addons/BottledTileMap/ToolBar.tscn").instantiate()

# ******************************************************************************

func _enter_tree():
	# BOTTLED
	add_custom_type(
		'BottledTileMap',
		'TileMap',
		load(plugin_dir + 'BottledTilemap.gd'),
		load(plugin_dir + 'icon.png')
	)
	
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, toolbar)
	toolbar.visible = false
	
	# TILECELL
	tile_cell_manager = load(plugin_dir + 'TileCellManager/TileCellManager.gd').new()
	add_child(tile_cell_manager)

	# TILEPALETTE
	tile_palette_manager = load(plugin_dir + 'TilePalette/palette_manager.gd').new()
	tile_palette_manager.toolbar = toolbar
	add_child(tile_palette_manager)

func _exit_tree():
	# BOTTLED
	remove_custom_type('BottledTileMap')
	
	remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, toolbar)

#	# TILECELL
#	check_validation()
#	Nodeselected.disconnect("selection_changed",Callable(self,"on_node_selected"))

#	# TILEPALETTE
#	_remove_tile_palette()
#	remove_inspector_plugin(_tilemap_inspector_plugin)


func _handles(object):
	return object is BottledTileMap

func _forward_canvas_gui_input(event: InputEvent) -> bool:
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		BTM.bottled_set_cell(event)
		return true
	elif event is InputEventKey and event.keycode in [KEY_C, KEY_X]:
		BTM._on_key_pressed(event)
		return true
	return false

func _make_visible(visible):
	toolbar.visible = visible
#	tile_palette_manager.dock_button.visible = visible
