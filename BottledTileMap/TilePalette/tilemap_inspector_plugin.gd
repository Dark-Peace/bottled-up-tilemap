@tool
extends EditorInspectorPlugin

signal tile_map_tile_set_changed

var _inspector: EditorInspector

func _init(inspector: EditorInspector):
	_inspector = inspector

func can_handle(object):
	return object is TileMap

func parse_begin(object):
	if _inspector.is_connected("property_edited",Callable(self,"_inspector_property_edited")): return
	_inspector.connect("property_edited",Callable(self,"_inspector_property_edited"))

func _inspector_property_edited(property):
	if property != "tile_set": return
	emit_signal("tile_map_tile_set_changed")
