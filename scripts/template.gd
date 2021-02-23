extends Node
onready var scroll_container : ScrollContainer = $Display/MarginContainer/VBoxContainer/ScrollContainer
onready var title : Label = $Display/MarginContainer/VBoxContainer/Header/Title
onready var subtitle : Label = $Display/MarginContainer/VBoxContainer/Header/Subtitle
onready var scroll_array : VBoxContainer = $Display/MarginContainer/VBoxContainer/ScrollContainer/ScrollArray
var multiple_array = load("res://components/multiple_array.tscn")
var button = preload("res://components/button.tscn")
var label = preload("res://components/label.tscn")
	
const SCROLL_SENSITIVITY = .03;
var mouse_button_down = false
var gui_init = false
var y_start = 0
var y_end = 0
var x_start = 0
var x_end = 0

func generate_label(index: int, text: String):
	var l = label.instance()
	l.name = "LABEL_" + str(index)
	l.text = text
	return l
	
func generate_button(index: int, text: String, callback: String):
	var b = button.instance()
	b.text = text
	b.connect("pressed", self, callback, [index])
	return b
	
func generate_hbox(elements: Array):
	var ma = multiple_array.instance()
	for element in elements:
		ma.add_child(element)
	return ma

func find_node_by_name(root, name):
	if(root.get_name() == name): return root
	for child in root.get_children():
		if(child.get_name() == name):
			return child
		var found = find_node_by_name(child, name)
		if(found): return found
	return null

func set_label(index: int, text: String):
	var node = find_node_by_name(get_tree().get_root(), "LABEL_" + str(index))
	node.text = text

func is_in_scroll_location(position):
	if (position.y > y_start and position.y < y_end and 
		position.x > x_start and position.x < x_end):
		return true
	return false

func _input (event):
	if not gui_init:
		gui_init = true
		y_start = scroll_container.get_global_position().y
		y_end = scroll_container.get_global_position().y + scroll_container.get_size().y
		x_start = scroll_container.get_global_position().x + scroll_container.get_size().x
		x_end = OS.get_screen_size().x
	if event is InputEventScreenDrag:
		if is_in_scroll_location(event.position):
			print(event.speed.y)
			scroll_container.scroll_vertical -= event.speed.y * SCROLL_SENSITIVITY
			scroll_container.update()

func init():
	pass

func init_header():
	pass

func init_scroll_array():
	pass

func _ready():
	init()
	init_header()
	init_scroll_array()
