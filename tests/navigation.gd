extends SceneTree

func _initialize():
	call_deferred("run")

func settle():
	for i in 6:
		await process_frame

func run():
	var global = root.get_node("Global")
	var touch_controls = root.get_node("TouchControls")
	touch_controls.touch_mode = true
	assert(not quit_on_go_back)
	# Find Settings in the lesson data instead of relying on its numeric index.
	for m in global.root.masterclasses.size():
		for p in global.root.masterclasses[m].practices.size():
			if global.root.masterclasses[m].practices[p].practiceType == "SETTINGS":
				global.set_masterclass_index(m)
				global.set_practice_index(p)
	assert(global.practice_index >= 0)
	change_scene_to_file("res://scenes/settings_instrument.tscn")
	await settle()
	for button in current_scene.instrument_buttons:
		assert(button.focus_mode == Control.FOCUS_NONE)
		assert(button.get_theme_stylebox("hover") == button.get_theme_stylebox("normal"))
		assert(button.get_theme_stylebox("hover_pressed") == button.get_theme_stylebox("pressed"))
		assert(button.get_theme_color("font_hover_color") == button.get_theme_color("font_color"))
		assert(button.get_theme_color("font_hover_pressed_color") == button.get_theme_color("font_pressed_color"))
		assert(button.toggle_mode)
	assert(current_scene.instrument_buttons[root.get_node("MidiPlayer").instrument_index].button_pressed)
	global.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await settle()
	assert(current_scene.scene_file_path == "res://scenes/practice_settings.tscn")
	assert(global.practice_index >= 0)
	global.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await settle()
	assert(current_scene.scene_file_path == "res://scenes/masterclass.tscn")
	assert(global.practice_index == -1)
	assert(global.masterclass_index >= 0)
	global.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await settle()
	assert(current_scene.scene_file_path == "res://scenes/root.tscn")
	assert(global.masterclass_index == -1)
	# Ordinary buttons are not toggles, even on touch-enabled screens.
	for button in current_scene.scroll_array.get_children():
		assert(not button.toggle_mode)
		assert(button.focus_mode == Control.FOCUS_NONE)
		assert(button.get_theme_stylebox("hover") == button.get_theme_stylebox("normal"))
	print("Navigation tests passed: Android Back hierarchy and touch button styling.")
	# At the main menu, Back must exit rather than selecting lesson -1.
	global.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
