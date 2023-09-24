@tool
extends HBoxContainer

enum TransfoActions {FLIP_h, FLIP_v, ROTATE_RIGHT, ROTATE_LEFT}
var total_rotations:int = 0

const V:String = "v"
const H:String = "h"
const ROTATION:Dictionary = {
	"0": ["110","101"],
	"1": ["100","111"],
	"2": ["111","100"],
	"3": ["101","110"],
	"4": ["010","001"],
	"5": ["000","011"],
	"6": ["011","000"],
	"7": ["001","010"]
}

@onready var transfo_icon = $Clear_Transfo/TextureRect

var bit_h = false
var bit_v = false
var bit_t = false

# Change alt tile --------

func change_alt_tile():
	if not $Transfo_alt.button_pressed: return
	BTM.current_alt = _get_alt_string().bin_to_int()
#	print(bit_t, bit_h, bit_v)

func _get_alt_string():
	return (str(int(bit_t)) + str(int(bit_v)) + str(int(bit_h)))

func _on_flip_h_pressed():
	flip(H, !transfo_icon.flip_h)

func _on_flip_v_pressed():
	flip(V, !transfo_icon.flip_v)

func flip(axis:String, value:bool):
	transfo_icon.set("flip_"+axis, value)
	set("bit_"+axis, value)
	change_alt_tile()
	if $Transfo_pattern.button_pressed: BTM._transform_pattern(TransfoActions.get("FLIP_"+axis))

func _on_rot_left_pressed():
	_on_rotation(0)
	if $Transfo_pattern.button_pressed: BTM._transform_pattern(TransfoActions.ROTATE_LEFT)
#	total_rotations += 1

func _on_rot_right_pressed():
	_on_rotation(1)
	if $Transfo_pattern.button_pressed: BTM._transform_pattern(TransfoActions.ROTATE_RIGHT)
#	total_rotations -= 1

func _on_rotation(dir:int):
	var alt:String = ROTATION[str(_get_alt_string().bin_to_int())][dir]
	bit_t = bool(int(alt[0]))
	bit_v = bool(int(alt[1]))
	bit_h = bool(int(alt[2]))
	
	transfo_icon.flip_h = bit_h
	transfo_icon.flip_v = bit_v
	change_alt_tile()

func _on_clear_transfo_pressed():
	if $Transfo_pattern.button_pressed: clear_pattern_transfo()
	transfo_icon.flip_h = false
	transfo_icon.flip_v = false
#	transfo_icon.rotation = 0
	bit_h = false
	bit_v = false
	bit_t = false
	change_alt_tile()

func clear_pattern_transfo():
	if transfo_icon.flip_h: BTM._transform_pattern(TransfoActions.FLIP_h)
	if transfo_icon.flip_v: BTM._transform_pattern(TransfoActions.FLIP_v)
#	print(total_rotations)
#	for r in total_rotations:
#		BTM._transform_pattern(TransfoActions.ROTATE_RIGHT)
#	total_rotations = 0

# change paint tool --------

func _on_paint_pressed():
	$Bucket.button_pressed = !$Paint.button_pressed
	BTM.is_bucket = $Bucket.button_pressed

func _on_bucket_pressed():
	$Paint.button_pressed = !$Bucket.button_pressed
	BTM.is_bucket = $Bucket.button_pressed

func _on_use_terrain_pressed():
	BTM.is_terrain = $UseTerrain.button_pressed
	if $SolveTerrain.button_pressed and $UseTerrain.button_pressed: $SolveTerrain.button_pressed = false

func _on_solve_terrain_pressed():
	BTM.is_solving = $SolveTerrain.button_pressed
	if $SolveTerrain.button_pressed and $UseTerrain.button_pressed: $UseTerrain.button_pressed = false

# drawing modes ---------

func update_drawing_modes(list:Array[String]):
	$DrawingModes.get_popup().clear()
	for m in BTM.palette.tilemap.drawing_modes:
		$DrawingModes.get_popup().add_check_item(m)

func get_drawing_modes():
	var res:Array[String]
	for m in $DrawingModes.get_popup().item_count:
		if not $DrawingModes.get_popup().is_item_checked(m): continue
		res.append($DrawingModes.get_popup().get_item_text(m))
	return res


var can_press:bool = true
func _on_pattern_transfo_alt_pressed():
	if can_press and not $Transfo_pattern.button_pressed:
		can_press = false
		$Transfo_pattern.button_pressed = true
		can_press = true
	

func _on_transfo_pattern_pressed():
	if can_press and not $Transfo_alt.button_pressed:
		can_press = false
		$Transfo_alt.button_pressed = true
		can_press = true
