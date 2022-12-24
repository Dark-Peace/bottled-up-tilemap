tool
extends EditorPlugin

# ******************************************************************************

var plugin_dir = 'res://addons/BottledTileMap/'

var tile_cell_manager = null
var tile_palette_manager = null

# ******************************************************************************

func _enter_tree():
	# BOTTLED
	add_custom_type(
		'BottledTileMap',
		'TileMap',
		load(plugin_dir + 'BottledTilemap.gd'),
		load(plugin_dir + 'icon.png')
	)

	# TILECELL
	tile_cell_manager = load(plugin_dir + 'TileCellManager/TileCellManager.gd').new()
	add_child(tile_cell_manager)

	# TILEPALETTE
	tile_palette_manager = load(plugin_dir + 'TilePalette/palette_manager.gd').new()
	add_child(tile_palette_manager)

func _exit_tree():
	# BOTTLED
	remove_custom_type('BottledTileMap')

#	# TILECELL
#	check_validation()
#	Nodeselected.disconnect("selection_changed",self,"on_node_selected")

#	# TILEPALETTE
#	_remove_tile_palette()
#	remove_inspector_plugin(_tilemap_inspector_plugin)

#
