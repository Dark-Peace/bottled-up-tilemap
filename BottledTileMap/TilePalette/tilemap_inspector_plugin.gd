tool
extends EditorInspectorPlugin

signal tile_map_tile_set_changed

var _inspector: EditorInspector

func _init(inspector: EditorInspector):
	_inspector = inspector

func can_handle(object):
	return object is TileMap

func parse_begin(object):
	if not _inspector.is_connected("property_edited", self, "_inspector_property_edited"):
		_inspector.connect("property_edited", self, "_inspector_property_edited")

func _inspector_property_edited(property):
#	print("TilemapInspectorPlugin._on_tile_set_changed")
	if property == "tile_set":
		emit_signal("tile_map_tile_set_changed")
