@tool
extends BoxContainer

const DEFAULT_TILEDATA:Dictionary = {"weight": 1, "rules":[]}

var rule_tool:RULE_TOOL = RULE_TOOL.Add
@onready var p
var copied_rules:Dictionary

var current_group:Dictionary
var current_rule:Dictionary
var current_tile:String
var rule_pos:Vector2i

var mouse_pos:Vector2i


func init_group(group:String):
	if not p.tileset.get_meta("Terrains", {}).has(group): create_terrain(group, p.tileset.get_meta("Terrains", {}))
	current_group = p.tileset.get_meta("Terrains", {}).get(group)
	
	var new_list:ItemList = p.get_node("%ListView").duplicate()
	new_list.custom_minimum_size.x = $%ListTemplate.custom_minimum_size.x
	new_list.size_flags_horizontal = $%ListTemplate.size_flags_horizontal
	if $Main.get_child_count() > 1: $Main.remove_child($Main.get_child(0))
	$Main.add_child(new_list)
	$Main.move_child(new_list, 0)
	
	current_tile = current_group.keys()[0]
	$%TileWeigth.value = current_group[current_tile].weight
	for mode in p.tilemap.drawing_modes.size():
		$"%DrawingModes".get_popup().add_item(p.tilemap.drawing_modes[mode], mode)
	
	sync_settings()
	reset_rule_settings()
	
	# init panel with first tile
	# update layers
	# update drawing modes

func sync_settings():
	$%RuleLayers.clear()
	$%DrawingModes.get_popup().clear()
	for l in p.tilemap.get_layers_count():
		$%RuleLayers.add_item(p.tilemap.get_layer_name(l))
	for m in p.tilemap.drawing_modes:
		$%DrawingModes.get_popup().add_check_item(m)
	

func update_panel():
	$%RuleView.queue_redraw()

func create_terrain(group:String, meta:Dictionary):
	meta[group] = {}
	p.tileset.set_meta("Terrains", meta)

func remove_terrain(group:String):
	p.tileset.get_meta("Terrains", {}).erase(group)

func remove_empty_terrains():
	var can_remove:bool = true
	for group in p.tileset.get_meta("Terrains", {}).keys():
		can_remove = true
		for tile in p.tileset.get_meta("Terrains")[group].value():
			if tile != DEFAULT_TILEDATA:
				can_remove = false
				break
		if can_remove: remove_terrain(group)


func action_on_cell(pos):
	match rule_tool:
		RULE_TOOL.Add: create_rule()
		RULE_TOOL.Edit: set_current_rule(get_rule_on_cell(pos, $%RuleLayers.selected))
	
func delete_rule(rule:Dictionary=current_rule, tile:String=current_tile):
	current_group[tile].rules.erase(rule) # TODO improve
	update_panel()

func create_rule(tile:String=current_tile, rule:Dictionary=update_current_rule()):
	if not tile in current_group: current_group[tile] = DEFAULT_TILEDATA
	
	current_group[tile].rules.append(rule)
	update_panel()

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

func set_current_rule(res:Dictionary):
	current_rule = res
	$%RuleLayers.selected = res["layer"]
	$%RuleLayerSettings.selected = res["layer_type"]
	_set_pos_setting(res["cell"])
	$%RuleTileID.text = res["tile"]
	$%RuleProb.value = res["prob"]
	for mode in $%DrawingModes.get_popup().item_count:
		$%DrawingModes.get_popup().set_item_checked(mode, $%DrawingModes.get_popup().get_item_text(mode) in res["modes"])

func reset_rule_settings():
	$%RuleLayers.selected = 0
	$%RuleLayerSettings.selected = 0
	$%RulePos.text = ""
	$%RuleTileID.text = ""
	$%RuleProb.value = 100
	for mode in $%DrawingModes.get_popup().item_count:
		$%DrawingModes.get_popup().set_item_checked(mode, false)

func _on_next_rule_pressed():
	for rule in current_group[current_tile].rules:
		if not (rule.pos == current_rule.pos and rule.layer == current_rule.layer and rule.tile != current_rule.tile): continue
		set_current_rule(rule)

func get_rule_on_cell(pos:Vector2i=current_rule.pos, layer:int=current_rule.layer):
	for rule in current_group[current_tile].rules:
		if not (rule.pos == pos and rule.layer == layer): continue
		return rule

enum RULE_TOOL {Add, Edit, Move}
func _on_rule_tool_item_selected(index):
	rule_tool = index
	$%RulePos.editable = (index == RULE_TOOL.Edit)

func _on_rules_copy_pressed():
	copied_rules = current_rule


func _on_rules_paste_pressed():
	set_current_rule(copied_rules)


func _on_rules_export_pressed():
	var filepath:String
	# JSON
	print("Ruleset exported to file " + filepath)


func _on_rules_import_pressed():
	# JSON
	update_panel()


func _on_tile_weigth_value_changed(value):
	current_group[current_tile]["weight"] = value


func _on_alt_same_rules_pressed():
	pass # Replace with function body.


func _on_alt_miror_rules_pressed():
	pass # Replace with function body.


func _on_alt_no_rules_pressed():
	pass # Replace with function body.


func set_rule_settings(arg):
	update_current_rule()


func _on_rule_prob_value_changed(value):
	var hint:String = "can"
	match value:
		100: hint = "need"
		0: hint = "can't"
	$%ProbLabel.text = "Prob: "+$%RuleProb.value+" ("+hint+")"

func _on_rule_pos_text_submitted(new_text:String):
	if rule_tool != RULE_TOOL.Edit: return
	if new_text.count(",") != 1:
		$%RulePos.set_deferred("text", $%RulePos.text)
		return
	var pos:Array[String] = new_text.split(",", false, 1)
	for p in pos:
		if not p.is_valid_int():
			$%RulePos.set_deferred("text", $%RulePos.text)
			return
	set_rule_settings(new_text)

func _set_pos_setting(pos):
	$%RulePos.text = str(pos.x)+","+str(pos.y)

func _on_rule_layers_pressed():
	sync_settings()
