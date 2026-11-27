extends SceneTree

func _initialize():
	call_deferred("run")

func settle():
	for i in 8:
		await process_frame

func run():
	var global = root.get_node("Global")
	var midi = root.get_node("MidiPlayer")
	var original_progress = global.file_data.duplicate(true)
	# Use a naming exercise with instructions to check partial keyboard state too.
	var selected = false
	for m in global.root.masterclasses.size():
		for p in global.root.masterclasses[m].practices.size():
			var practice = global.root.masterclasses[m].practices[p]
			if practice.practiceType == "PITCH_NAMING_DRILL" and practice.has("info"):
				global.set_masterclass_index(m)
				global.set_practice_index(p)
				selected = true
				break
		if selected:
			break
	assert(selected)
	var practice_index = global.practice_index
	var scene = load("res://scenes/practice_pitch_naming_drill.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await settle()
	scene.score = 3
	scene.keyboard.pitchList.append("c")
	scene.scroll_container.scroll_vertical = int(scene.scroll_container.get_v_scroll_bar().max_value)
	await settle()
	var old_scroll = scene.scroll_container.scroll_vertical
	var old_batch = scene.batch.duplicate(true)
	var old_process_mode = scene.process_mode
	var info_button = scene.scroll_array.get_node("PracticeInfo")
	assert(info_button.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART)
	for style_name in ["normal", "hover", "pressed"]:
		var style = info_button.get_theme_stylebox(style_name)
		assert(style is StyleBoxTexture)
		assert(style.get_content_margin(SIDE_BOTTOM) >= 64)
		assert(style.get_texture_margin(SIDE_BOTTOM) >= 64)
	info_button.pressed.emit()
	await settle()
	var screen = scene.practice_info_screen
	scene.show_practice_info()
	assert(scene.practice_info_screen == screen, "Do not open duplicate Info screens")
	assert(screen.scene_file_path == "res://scenes/practice_info.tscn")
	assert(screen.title.text == "Practice info")
	assert(not scene.get_node("Display").visible)
	assert(screen.get_node("Display").is_visible_in_tree())
	assert(scene.process_mode == Node.PROCESS_MODE_DISABLED)
	assert(screen.can_process())
	assert(screen.scroll_container.size.is_equal_approx(root.get_visible_rect().size))
	var body = screen.scroll_array.get_node("SourceInfoText")
	assert(body.fit_content and not body.scroll_active)
	assert(body.text == scene.get_practice_info_text())
	assert(screen.find_child("PracticeInfo", true, false) == null)
	assert(midi.noteActionQueue.is_empty())
	# System Back must close Info, not leave or save the underlying exercise.
	global.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await settle()
	assert(scene.practice_info_screen == null)
	assert(current_scene == scene)
	assert(scene.get_node("Display").visible)
	assert(scene.process_mode == old_process_mode)
	assert(scene.score == 3 and scene.batch == old_batch)
	assert(scene.keyboard.pitchList == ["c"])
	assert(scene.scroll_container.scroll_vertical == old_scroll)
	assert(global.practice_index == practice_index)
	assert(global.file_data == original_progress)
	# Opening again and using the original-design arrow also returns correctly.
	scene.show_practice_info()
	await settle()
	scene.practice_info_screen.scroll_array.get_child(0).pressed.emit()
	await settle()
	assert(scene.practice_info_screen == null and scene.score == 3)
	scene.queue_free()
	await process_frame
	midi.synth.queue_free()
	await create_timer(0.25).timeout
	print("Practice info passed: original button styling, full page, Back, preserved exercise and scroll position.")
	quit()
