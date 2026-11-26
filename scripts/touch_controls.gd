extends Node

var touch_mode := false

func _ready():
	touch_mode = OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
	get_tree().node_added.connect(on_node_added)

func on_node_added(node: Node):
	if touch_mode and node is Button:
		# Wait for the button's parent/theme to be available (including keyboards
		# and instrument buttons created while building the scene).
		call_deferred("style_touch_button", node)

func style_touch_button(button: Button):
	if not is_instance_valid(button) or not button.is_inside_tree():
		return
	# Godot emulates mouse input from a touch. Its pointer remains at the last
	# tap position, so hover/focus visuals must not look like a stuck selection.
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("hover", button.get_theme_stylebox("normal"))
	button.add_theme_stylebox_override("hover_pressed", button.get_theme_stylebox("pressed"))
	button.add_theme_color_override("font_hover_color", button.get_theme_color("font_color"))
	button.add_theme_color_override("font_hover_pressed_color", button.get_theme_color("font_pressed_color"))
	button.add_theme_color_override("icon_hover_color", button.get_theme_color("icon_normal_color"))
	button.add_theme_color_override("icon_hover_pressed_color", button.get_theme_color("icon_pressed_color"))
