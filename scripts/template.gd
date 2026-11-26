extends Node
@onready var scroll_container : ScrollContainer = $Display/MarginContainer/VBoxContainer/ScrollContainer
@onready var title : Label = $Display/MarginContainer/VBoxContainer/Header/Title
@onready var subtitle : Label = $Display/MarginContainer/VBoxContainer/Header/Subtitle
@onready var scroll_array : VBoxContainer = $Display/MarginContainer/VBoxContainer/ScrollContainer/ScrollArray
var multiple_array = load("res://components/multiple_array.tscn")
var button = preload("res://components/button.tscn")
var label = preload("res://components/label.tscn")
var rng = RandomNumberGenerator.new()
var back_navigation_pending := false

const SCROLL_SENSITIVITY = .03;
var mouse_button_down = false
var gui_init = false
var y_start = 0
var y_end = 0
var x_start = 0
var x_end = 0

func generate_label(index: int, text: String):
	var l = label.instantiate()
	l.name = "LABEL_" + str(index)
	l.text = text
	return l
	
func generate_button(index: int, text: String, callback: String):
	var b = button.instantiate()
	var btn
	if (text == "<-"):
		b.text = ""
		btn = load("res://assets/btn_back.tres")
		b.size_flags_horizontal = 0
		b.size_flags_vertical = 0
		b.custom_minimum_size = Vector2(150, 150)
	else:
		b.text = text
		btn = load("res://assets/btn_v%d.tres" % [rng.randi_range(1, 3)])
	b.set_theme(btn)
	b.connect("pressed", Callable(self, callback).bind(index))
	return b
	
func generate_hbox(elements: Array):
	var ma = multiple_array.instantiate()
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
		x_end = DisplayServer.screen_get_size().x
	if event is InputEventScreenDrag:
		if is_in_scroll_location(event.position):
			scroll_container.scroll_vertical -= event.velocity.y * SCROLL_SENSITIVITY
			scroll_container.queue_redraw()

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

func _exit_tree():
	MidiPlayer.allNotesOff()

func navigate_back():
	if back_navigation_pending:
		return
	back_navigation_pending = true
	# Every child screen uses -1 for its existing back button. Reuse that handler
	# so score saving and lesson selection resets behave identically.
	on_button_pressed(-1)

func on_button_pressed(_index: int):
	pass
