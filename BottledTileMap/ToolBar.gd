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
	BTM.current_alt = _get_alt_string().bin_to_int()

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

func _on_rot_left_pressed():
	_on_rotation(0)

func _on_rot_right_pressed():
	_on_rotation(1)

func _on_rotation(dir:int):
	var alt:String = ROTATION[str(_get_alt_string().bin_to_int())][dir]
	bit_t = bool(int(alt[0]))
	bit_v = bool(int(alt[1]))
	bit_h = bool(int(alt[2]))
	
	transfo_icon.flip_h = bit_h
	transfo_icon.flip_v = bit_v
#	transfo_icon.texture
	change_alt_tile()

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
