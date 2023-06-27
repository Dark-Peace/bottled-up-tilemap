@tool
extends BoxContainer

const DEFAULT_TILEDATA:Dictionary = {"weight": 1, "rules":[]}
const PANEL_SIZE:Vector2i = Vector2i(753,560)

var rule_tool:RULE_TOOL = RULE_TOOL.Add
enum IMPORT_TYPE {Rules, Col}
var import_type:IMPORT_TYPE = IMPORT_TYPE.Rules
@onready var p

var group_name:String
var current_group:Dictionary
var current_rule:Dictionary
var current_tile:String
var rule_pos:Vector2i
var edited_rule:Dictionary
var copied_rules:Array[Dictionary]

var mouse_pos:Vector2i


func init_group(group:String):
	if group in ["ALL_TILES","NO_GROUP"]:
		push_warning("Can't use group "+group+" as a Terrain. Use a group you created instead.")
		return
	
	group_name = group
	if not p.tileset.get_meta("Terrains", {}).has(group):
		create_terrain(group, p.tileset.get_meta("Terrains", {}), \
			str(p.tilemap._get_id_in_map(p.tileset.get_meta("groups_by_groups", {})[group][0])))
	current_group = p.tileset.get_meta("Terrains", {}).get(group)
	
	create_tile_list_view()
	
	$%TileWeigth.value = current_group[current_tile].weight
	for mode in p.tilemap.drawing_modes.size():
		$"%DrawingModes".get_popup().add_item(p.tilemap.drawing_modes[mode], mode)
	
	sync_settings()
	reset_rule_settings()
	
	_on_rule_tool_item_selected(RULE_TOOL.Add)

func create_tile_list_view():
	var new_list:ItemList = p.get_node("%ListView").duplicate()
	new_list.custom_minimum_size.x = $%ListTemplate.custom_minimum_size.x
	new_list.size_flags_horizontal = $%ListTemplate.size_flags_horizontal
	new_list.clip_contents = true
	new_list.max_columns = 2
	new_list.disconnect("empty_clicked", p._on_list_view_empty_clicked)
	new_list.disconnect("item_clicked", p._on_list_view_item_clicked)
	new_list.disconnect("item_selected", p._on_ListView_item_selected)
	new_list.disconnect("multi_selected", p._on_ListView_item_selected)
	new_list.connect("item_selected", select_tile)
	
	for i in p.get_node("%ListView").item_count:
		new_list.set_item_icon_region(i, p.get_node("%ListView").get_item_icon_region(i))
	
	if $Main.get_child_count() > 2: $Main.remove_child($Main.get_child(0))
	$Main.add_child(new_list)
	$Main.move_child(new_list, 0)
	new_list.select(0)
	select_tile(0)

func sync_settings():
	$%RuleLayers.clear()
	$%DrawingModes.get_popup().clear()
	for l in p.tilemap.get_layers_count():
		$%RuleLayers.add_item(p.tilemap.get_layer_name(l))
	for m in p.tilemap.drawing_modes:
		$%DrawingModes.get_popup().add_check_item(m)
	

func update_panel():
	$%RuleView.queue_redraw()

func create_terrain(group:String, meta:Dictionary, tile:String=current_tile):
	meta[group] = {}
	create_rule(tile, {}, meta[group])
	p.tileset.set_meta("Terrains", meta)

func remove_terrain(group:String):
	p.tileset.get_meta("Terrains", {}).erase(group)

func remove_empty_terrains():
	var can_remove:bool = true
	for group in p.tileset.get_meta("Terrains", {}).keys():
		if group not in p.tileset.get_meta("groups_by_groups").keys():
			remove_terrain(group)
			return
		can_remove = true
		for tile in p.tileset.get_meta("Terrains")[group].values():
			if tile == DEFAULT_TILEDATA: continue
			can_remove = false
			break
		if not can_remove: continue
		remove_terrain(group)

func select_tile(index:int):
	current_tile = str(p.tilemap._get_id_in_map(p.tileset.get_meta("groups_by_groups")[group_name][index]))
	create_rule(current_tile, {})
	set_panel_limits()
	update_panel()

const BASE_LIMIT_X:int = 5
const BASE_LIMIT_Y:int = 4
func set_panel_limits():
	var max_limits:Vector2i = Vector2i(0, 0)
	var min_limits:Vector2i = Vector2i(0, 0)
	for rule in current_group[current_tile].rules:
		if rule.cell.x > max_limits.x and rule.cell.x > BASE_LIMIT_X: max_limits.x = rule.cell.x
		if rule.cell.y < max_limits.y and rule.cell.y < -BASE_LIMIT_Y: max_limits.y = rule.cell.y
		if rule.cell.x < min_limits.x and rule.cell.x < -BASE_LIMIT_X: min_limits.x = rule.cell.x
		if rule.cell.y > min_limits.y and rule.cell.y > BASE_LIMIT_Y: min_limits.y = rule.cell.y
	
	$%RuleView.set_limits(max_limits, min_limits)

func action_on_cell(pos, button:int):
	match rule_tool:
		RULE_TOOL.Add:
			if button == MOUSE_BUTTON_RIGHT: delete_rule()
			elif button == MOUSE_BUTTON_LEFT: create_rule()
		RULE_TOOL.Edit:
			set_current_rule(get_rule_on_cell(pos, $%RuleLayers.selected))

func delete_rule(rule:Dictionary=current_rule, tile:String=current_tile):
	current_group[tile]["rules"].erase(rule) # TODO improve
	update_panel()

func create_rule(tile:String=current_tile, rule:Dictionary=update_current_rule(), group:Dictionary=current_group):
	if not tile in group: group[tile] = get_default_tiledata()
	
	if rule == {}: return
	group[tile].rules.append(rule)
	set_panel_limits()
	update_panel()

func clear_rules(tile:String=current_tile):
	for rule in current_group[tile].rules.size():
		delete_rule(current_group[tile].rules.pop_back())

func update_current_rule():
	var res:Dictionary
	res["layer"] = $%RuleLayers.selected
	res["layer_type"] = $%RuleLayerSettings.selected
	res["cell"] = rule_pos
	res["tile"] = $%RuleTileID.text
	res["prob"] = $%RuleProb.value
	res["modes"] = []
	for mode in $%DrawingModes.get_popup().item_count:
		if not $%DrawingModes.get_popup().is_item_checked(mode): continue
		res["modes"].append($%DrawingModes.get_popup().get_item_text(mode))
	current_rule = res
	update_panel()
	return res

func edit_current_rule(cell:Vector2i=rule_pos):
	current_rule["layer"] = $%RuleLayers.selected
	current_rule["layer_type"] = $%RuleLayerSettings.selected
	current_rule["cell"] = cell
	current_rule["tile"] = $%RuleTileID.text
	current_rule["prob"] = $%RuleProb.value
	current_rule["modes"] = []
	for mode in $%DrawingModes.get_popup().item_count:
		if not $%DrawingModes.get_popup().is_item_checked(mode): continue
		current_rule["modes"].append($%DrawingModes.get_popup().get_item_text(mode))
	update_panel()
	return current_rule

func set_current_rule(res:Dictionary):
	if res == {}: return
	current_rule = res
	$%RuleLayers.selected = res["layer"]
	$%RuleLayerSettings.selected = res["layer_type"]
	_set_pos_setting(res["cell"])
	$%RuleTileID.text = res["tile"]
	$%RuleProb.value = res["prob"]
	_on_rule_prob_value_changed($%RuleProb.value)
	for mode in $%DrawingModes.get_popup().item_count:
		$%DrawingModes.get_popup().set_item_checked(mode, $%DrawingModes.get_popup().get_item_text(mode) in res["modes"])
	update_panel()

func reset_rule_settings():
	$%RuleLayers.selected = 0
	$%RuleLayerSettings.selected = 0
	$%RulePos.text = ""
	$%RuleTileID.text = ""
	$%RuleProb.value = 100
	_on_rule_prob_value_changed($%RuleProb.value)
	for mode in $%DrawingModes.get_popup().item_count:
		$%DrawingModes.get_popup().set_item_checked(mode, false)

func _on_next_rule_pressed():
	for rule in current_group[current_tile].rules:
		if not (rule.cell == current_rule.cell and rule.layer == current_rule.layer): continue
		set_current_rule(rule)
		return

func get_rule_on_cell(pos:Vector2i=current_rule.cell, layer:int=$%RuleLayers.selected):
	for rule in current_group[current_tile].rules:
		if not (rule.cell == pos and rule.layer == layer): continue
		return rule
	return {}

enum RULE_TOOL {Add, Edit, Move}
func _on_rule_tool_item_selected(index):
	rule_tool = index
	$%RulePos.editable = (index == RULE_TOOL.Edit)

func _on_rules_copy_pressed():
	copied_rules = current_group[current_tile].rules

func _on_rules_paste_pressed():
	current_group[current_tile].rules = copied_rules.duplicate(true)
#	set_current_rule(copied_rules)

func _write_to_json(content, filepath):
	var file = FileAccess.open(filepath, 2)
	var json = JSON.new()
	json.parse(json.stringify(content))
	file.store_string(json.to_string())
	file.close()

func _on_rules_export_pressed():
	_write_to_json(current_group, "save_rules_"+group_name+".json")
	print("Ruleset exported to file " + "save_rules_"+group_name+".json")

func _on_rules_import_pressed():
	import_type = IMPORT_TYPE.Rules
	$%GetFile.show()

func _on_export_col_pressed():
	var cols:Dictionary; var tiledata:TileData;
	for tile in p.tileset.get_meta("groups_by_groups")[group_name]:
		cols[tile] = {}
		tiledata = p.tileset.get_source(tile.z).get_tile_data(Vector2i(tile.x, tile.y))
		for l in p.tileset.get_physics_layers_count():
			cols[tile][l] = [] 
			for c in tiledata.get_collision_polygons_count(l):
				cols[tile][l].append(tiledata.get_collision_polygon_points(l, c))
	
	_write_to_json(cols, "collision_set_"+group_name+".json")
	print("Collision set exported to file " + "collision_set_"+group_name+".json")

func _on_import_col_pressed():
	import_type = IMPORT_TYPE.Col
	$%GetFile.show()

func _on_get_file_file_selected(path):
	var file = FileAccess.open(path, FileAccess.READ)
	var json_as_dict:Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	if json_as_dict:
		match import_type:
			IMPORT_TYPE.Rules: _import_rules(json_as_dict)
			IMPORT_TYPE.Col: _import_rules(json_as_dict)
	update_panel()

func _import_cols(cols:Dictionary):
	var tiledata:TileData; var i:int = 0; var tile_cols:Dictionary
	for tile in p.tileset.get_meta("groups_by_groups")[group_name]:
		tiledata = p.tileset.get_source(tile.z).get_tile_data(Vector2i(tile.x, tile.y))
		tile_cols = cols.keys()[i]
		for l in tile_cols.keys():
			for c in tile_cols[l].size():
				tiledata.set_collision_polygon_points(l, c, tile_cols[l][c])
		i += 1

func _import_rules(json_as_dict:Dictionary):
	var i:int = 0; var json_array:Array = json_as_dict.keys()
	for tile in current_group.keys():
		current_group[tile].rules = json_as_dict.get(json_array[i]).rules
		i += 1

func _on_tile_weigth_value_changed(value):
	current_group[current_tile]["weight"] = value


func _on_alt_same_rules_pressed():
	pass # Replace with function body.


func _on_alt_miror_rules_pressed():
	pass # Replace with function body.


func _on_alt_no_rules_pressed():
	pass # Replace with function body.


func set_rule_settings(arg):
	edit_current_rule()


func _on_rule_prob_value_changed(value):
	var hint:String = "can"
	match int(value):
		100: hint = "need"
		0: hint = "can't"
	$%ProbLabel.text = "Prob: "+str($%RuleProb.value)+" ("+hint+")"

func _on_rule_pos_text_submitted(new_text:String):
	if rule_tool != RULE_TOOL.Edit: return
	if new_text.count(",") != 1:
		$%RulePos.set_deferred("text", $%RulePos.text)
		return
	var pos:PackedStringArray = new_text.split(",", false, 1)
	for p in pos:
		if not p.is_valid_int():
			$%RulePos.set_deferred("text", $%RulePos.text)
			return
	rule_pos = Vector2i(int(pos[0]),int(pos[1]))
	set_rule_settings(new_text)
	set_panel_limits()

func _set_pos_setting(pos):
	rule_pos = pos
	current_rule = get_rule_on_cell(pos)
	$%RulePos.text = str(pos.x)+","+str(pos.y)

func _on_rule_layers_pressed():
	sync_settings()

func get_default_tiledata():
	return DEFAULT_TILEDATA.duplicate(true)
