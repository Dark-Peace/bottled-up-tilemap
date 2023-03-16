@tool
extends HBoxContainer

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
#	transfo_icon.texture = BTM.bottledtilemap.curr_tile_texture
#	transfo_icon.region
	BTM.current_alt = _get_alt_string().bin_to_int()

func _get_alt_string():
	return (str(int(bit_t)) + str(int(bit_v)) + str(int(bit_h)))

func _on_flip_h_pressed():
#	transfo_icon.flip_h = !transfo_icon.flip_h
#	bit_h = transfo_icon.flip_h
	flip(H, !transfo_icon.flip_h)

func _on_flip_v_pressed():
#	transfo_icon.flip_v = !transfo_icon.flip_v
#	bit_v = transfo_icon.flip_v
	flip(V, !transfo_icon.flip_v)

func flip(axis:String, value:bool):
	transfo_icon.set("flip_"+axis, value)
	set("bit_"+axis, value)
	change_alt_tile()

func _on_rot_left_pressed():
#	if not bit_t: flip(V, !bit_v)
#	else: flip(H, !bit_h)
	_on_rotation(1)

func _on_rot_right_pressed():
#	if bit_t: flip(V, !bit_v)
#	else: flip(H, !bit_h)
	_on_rotation(0)

func _on_rotation(dir:int):
#	if bit_v: flip(H, !bit_h)
#	if bit_t: flip(V, !bit_v)
	
	var alt:String = ROTATION[str(_get_alt_string().bin_to_int())][dir]
	bit_t = bool(int(alt[0]))
	bit_v = bool(int(alt[1]))
	bit_h = bool(int(alt[2]))
#	if bit_t:
#		transfo_icon.flip_h = bit_h
#		transfo_icon.flip_v = int(alt[1]) ^ int(alt[0])
#	else: 
#		transfo_icon.flip_v = bit_h
#		transfo_icon.flip_h = int(alt[1]) ^ int(alt[0])
#	bit_t = !bit_t
#	transfo_icon.rotation = [0, PI/2][int(bit_t)]
##	match alt.bin_to_int():
##		1:
##		2:
##		3:
##		4:
##		5:
##		6: pass
##		7:
##		0:
#	print(alt.bin_to_int())
##	transfo_icon.set("flip_v", alt.bin_to_int() in [2,3,4,6])
#	transfo_icon.set("flip_v", alt.bin_to_int() in [3,5])
#	transfo_icon.set("flip_h", alt.bin_to_int() in [3,5])
	
	
#	transfo_icon.rotation += (PI/2)*dir
#	if abs(transfo_icon.rotation) >= 2*PI:
#		print(abs(int(transfo_icon.rotation)))
#		transfo_icon.rotation = 0
#	bit_t = abs(int(transfo_icon.rotation)) in [1,4]
#	match int(transfo_icon.rotation):
#		1,-4: pass # left quart
#		-1,4: pass # right quart
#		3,-3: pass # down
#		0: pass # up
	
#	bit_h = (transfo_icon.rotation > 0)
	
	change_alt_tile()
#	print(_get_alt_string())
#	print(BTM.current_alt)

func _on_clear_transfo_pressed():
	transfo_icon.flip_h = false
	transfo_icon.flip_v = false
	transfo_icon.rotation = 0
	bit_h = false
	bit_v = false
	bit_t = false
	change_alt_tile()

# change paint tool --------

func _on_paint_pressed():
	$Bucket.button_pressed = !$Paint.button_pressed
	BTM.is_bucket = $Bucket.button_pressed

func _on_bucket_pressed():
	$Paint.button_pressed = !$Bucket.button_pressed
	BTM.is_bucket = $Bucket.button_pressed
