extends ScrollContainer

const EMPTY:Array[Dictionary] = []
enum EVENT {ID, Trigger, Prob, AltList, Call, After}
var event_list:Array[Dictionary] # list of events of a single tile
var current_tile:Vector3i


func _ready():
	$EventList/EventTemplate.hide()

func set_event_list(value):
	event_list = value
	_fill()

func _fill():
	_clear()
	for index in event_list.size():
		add_event(event_list[index], index)
	$EventList/ID.text = str(current_tile)

func _clear():
	for node in $EventList.get_children():
		if node in [$EventList/Add, $EventList/EventTemplate, $EventList/ID]: continue
		node.queue_free()

func add_event(event:Dictionary, index:int):
	var new_event = $EventList/EventTemplate.duplicate()
	new_event.get_node("Trigger").selected = event[EVENT.Trigger]
	new_event.get_node("Prob").value = event[EVENT.Prob]
	new_event.get_node("AltList").text = event[EVENT.AltList]
	new_event.get_node("ID").text = event[EVENT.ID]
	new_event.get_node("Call").text = event[EVENT.Call]
	new_event.get_node("After").selected = event[EVENT.After]
	new_event.get_node("Remove").pressed.connect(remove_event.bind(new_event, index))
	new_event.get_node("Trigger").item_changed.connect(update_event.bind(new_event, index))
	new_event.get_node("Prob").value_changed.connect(update_event.bind(new_event, index))
	new_event.get_node("After").item_changed.connect(update_event.bind(new_event, index))
	new_event.get_node("AltList").text_changed.connect(update_event.bind(new_event, index))
	new_event.get_node("ID").text_changed.connect(update_event.bind(new_event, index))
	new_event.get_node("Call").text_changed.connect(update_event.bind(new_event, index))
	$EventList/Add.add_sibling(new_event)

func update_event(value, event:FlowContainer, index:int):
	event_list[index][EVENT.Trigger] = event.get_node("Trigger").selected
	event_list[index][EVENT.ID] = event.get_node("ID").text
	event_list[index][EVENT.Prob] = event.get_node("Prob").value
	event_list[index][EVENT.AltList] = event.get_node("AltList").text
	event_list[index][EVENT.After] = event.get_node("After").selected
	event_list[index][EVENT.Call] = event.get_node("Call").text

func remove_event(event:FlowContainer, index:int):
	event.queue_free()
	event_list.remove_at(index)

func get_emtpy_list() -> Array[Dictionary]:
	return EMPTY.duplicate()
