tool
extends Control

# ******************************************************************************

onready var icon = $"%Icon"
onready var Name = $"%Name"
onready var Id = $"%ID"
onready var z_index = $"%Z"
onready var Modulation = $"%Modulate"
onready var shape = $"%Shape"
onready var tex = $"%Tex"

var active := false
var tileset: TileSet
var tilemap: TileMap
var id: int

# ******************************************************************************

func populate_infos(info):
	active = true
	icon.clear()
	tilemap = info['tilemap']
	tileset = info['tilemap'].tile_set
	id = tileset.find_tile_by_name(info['cell_name'])
	icon.add_item("", tileset.tile_get_texture(id), false)
	icon.set_item_icon_region(0, tileset.tile_get_region(id))
	Name.text = tileset.tile_get_name(id)
	Id.text = str(id)
	z_index.value = tileset.tile_get_z_index(id)
	Modulation.color = tileset.tile_get_modulate(id)
	shape.get_node("x").text = String(tileset.tile_get_shape_offset(id, 0).x)
	shape.get_node("y").text = String(tileset.tile_get_shape_offset(id, 0).y)
	tex.get_node("x").text = String(tileset.tile_get_texture_offset(id).x)
	tex.get_node("y").text = String(tileset.tile_get_texture_offset(id).y)

	$"%Instance".text = tilemap.get_meta("instances", {}).get(id, "")
	$"%Parent".text = tilemap.get_meta("parents", {}).get(id, "")
	$"%Groups".text = ""
	for g in tilemap.get_meta("groups_by_IDs", {}).get(id, []):
		$"%Groups".text += g + "\n"

# ******************************************************************************

func _on_LineEdit_text_changed(new_text):
	if not active or tileset.tile_get_name(id) == new_text:
		return

	tileset.tile_set_name(id, new_text)

func _on_SpinBox_value_changed(value):
	if not active or z_index.value == tileset.tile_get_z_index(id):
		return

	tileset.tile_set_z_index(id, value)

func _on_ColorPickerButton_color_changed(color):
	if not active or Modulation.color == tileset.tile_get_modulate(id):
		return

	tileset.tile_set_modulate(id, color)

func _on_Shape_text_changed(new_text) -> void:
	if not active: return

	var vec = Vector2(float(shape.get_node("x").text), float(shape.get_node("y").text))
	tileset.tile_set_shape_offset(id, 0, vec)

func _on_Tex_text_changed(new_text) -> void:
	if not active:
		return

	var vec = Vector2(float(tex.get_node("x").text), float(tex.get_node("y").text))
	tileset.tile_set_texture_offset(id, vec)

func _on_Instance_text_changed() -> void:
	if not active:
		return

	var dict = tilemap.get_meta("instances", {})
	dict[id] = $"%Instance".text
	tilemap.set_meta("instances", dict)
	print(tilemap.get_meta("groups_by_IDs"))

func _on_Parent_text_changed() -> void:
	if not active:
		return

	var dict = tilemap.get_meta("parents", {})
	dict[id] = $"%Parent".text
	tilemap.set_meta("parents", dict)

func _on_Dupli_pressed() -> void:
	if not active:
		return

	var new_id = tileset.get_last_unused_tile_id()
	tileset.create_tile(new_id)
	tileset.tile_set_tile_mode(new_id, tileset.tile_get_tile_mode(id))
	tileset.tile_set_texture(new_id, tileset.tile_get_texture(id))
	tileset.tile_set_texture_offset(new_id, tileset.tile_get_texture_offset(id))
	tileset.tile_set_region(new_id, tileset.tile_get_region(id))
	tileset.tile_set_light_occluder(new_id, tileset.tile_get_light_occluder(id))
	tileset.tile_set_occluder_offset(new_id, tileset.tile_get_occluder_offset(id))
	tileset.tile_set_modulate(new_id, tileset.tile_get_modulate(id))
	tileset.tile_set_navigation_polygon(new_id, tileset.tile_get_navigation_polygon(id))
	tileset.tile_set_navigation_polygon_offset(new_id, tileset.tile_get_navigation_polygon_offset(id))
	tileset.tile_set_normal_map(new_id, tileset.tile_get_normal_map(id))
	tileset.tile_set_z_index(new_id, tileset.tile_get_z_index(id))
	tileset.tile_set_shapes(new_id, tileset.tile_get_shapes(id))
	tileset.tile_set_shape_offset(new_id, 0, tileset.tile_get_shape_offset(id, 0))
	
	populate_infos([null, null, null, new_id, tileset])

func _on_Erase_pressed() -> void:
	if not active:
		return

	tileset.remove_tile(id)
	visible = false

func _on_SaveGroups_pressed() -> void:
	if not active:
		return

	var dict_g:Dictionary = tilemap.get_meta("groups_by_groups", {})
	var dict_id:Dictionary = tilemap.get_meta("groups_by_IDs", {})
	var tile_groups = $"%Groups".text.split("\n", false)
	var g_list = []
	var list:Array
	
	for g in dict_g.keys():
		if not g in tile_groups and id in dict_g[g]: # delete if needed (by group)
			dict_g[g].erase(id)
			if dict_g[g].empty(): 
				dict_g.erase(g)
	for g in tile_groups:
		if not dict_g.has(g): 
			dict_g[g] = []
		if not id in dict_g[g]: 
			dict_g[g].append(id) # by group
		if not g in g_list: 
			g_list.append(g) # by id
	dict_id[id] = g_list
	
	tilemap.set_meta("groups_by_groups", dict_g)
	tilemap.set_meta("groups_by_IDs", dict_id)
